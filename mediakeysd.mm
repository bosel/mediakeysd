#import <AppKit/AppKit.h>
#import <IOKit/hidsystem/ev_keymap.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <spawn.h>
#include <string.h>
#include <signal.h>
#include <Swifty.h>

void die(const char *fmt, ...) {
	va_list va;
	va_start(va, fmt);

	fputs("Fatal: ", stderr);
	vfprintf(stderr, fmt, va);
	putc('\n', stderr);

	va_end(va);
	exit(1);
}

#define NX_KEYSTATE_UP      11
#define NX_KEYSTATE_DOWN    10

struct EventTap {
private:
	CFMachPortRef eventPort;
	CFRunLoopSourceRef runLoopSource;
	const char *handlerPath;

public:
	EventTap(const char *handlerPath);
	
	static CGEventRef callback(
		CGEventTapProxy proxy,
		CGEventType type,
		CGEventRef event,
		void *ctx);
};

EventTap::EventTap(const char *handlerPath) {
	this->handlerPath = handlerPath;
	
	this->eventPort = CGEventTapCreate(
		kCGSessionEventTap,
		kCGHeadInsertEventTap,
		kCGEventTapOptionDefault,
		CGEventMaskBit(NX_SYSDEFINED),
		EventTap::callback,
		this);

	if (this->eventPort == nil) {
		die("eventPort == nil");
	}

	this->runLoopSource = CFMachPortCreateRunLoopSource(
		kCFAllocatorSystemDefault,
		this->eventPort, 0);

	if (this->runLoopSource == nil) {
		die("runLoopSource == nil");
	}

	CFRunLoopAddSource(
		CFRunLoopGetCurrent(),
		this->runLoopSource,
		kCFRunLoopCommonModes);
}

CGEventRef EventTap::callback(
	CGEventTapProxy proxy,
	CGEventType type,
	CGEventRef event,
	void *ctx) {

	let et = (EventTap *)ctx;

	if (type == kCGEventTapDisabledByTimeout) {
		CGEventTapEnable(et->eventPort, true);
	}

	if (type != NX_SYSDEFINED) {
		return event;
	}

	let nsEvent = [NSEvent eventWithCGEvent:event];

	if (nsEvent.subtype != 8) {
		return event;
	}

	int data = [nsEvent data1];
	int keyCode = (data & 0xFFFF0000) >> 16;
	int keyFlags = (data & 0xFFFF);
	int keyState = (keyFlags & 0xFF00) >> 8;
	bool keyIsRepeat = (keyFlags & 0x1) > 0;

	if (keyIsRepeat) {
		return event;
	}

	const char *keyStr = nil;
	
	switch (keyCode) {
	case NX_KEYTYPE_PLAY:
		keyStr = "toggle";
		break;
	case NX_KEYTYPE_FAST:
		keyStr = "next";
		break;
	case NX_KEYTYPE_REWIND:
		keyStr = "prev";
		break;
	}

	if (keyStr && keyState == NX_KEYSTATE_DOWN) {
		char *argv[] = {
			(char *)et->handlerPath,
			(char *)keyStr,
			nil
		};
		
		char *env[] = {nil};

		let errc = posix_spawn(
			nil,
			et->handlerPath,
			nil, nil,
			argv, env);

		if (errc) {
			fprintf(
				stderr,
				"posix_spawn failed: %s\n",
				strerror(errc));
		}
		
		return nil;
	}

	return event;
}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fputs("usage: mediakeysd <path/to/handler>\n", stderr);
		return 1;
	}

	struct sigaction sa = {
		.sa_handler = SIG_IGN,
		.sa_flags = SA_NOCLDWAIT
	};

	sigaction(SIGCHLD, &sa, nil);

	EventTap et(argv[1]);
	[NSApplication.sharedApplication run];
}
