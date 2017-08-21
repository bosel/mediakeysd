all: mediakeysd

mediakeysd: mediakeysd.mm
	clang++ \
		-I. -Ofast -std=gnu++14 -fno-rtti -fno-exceptions \
		-framework AppKit mediakeysd.mm -o mediakeysd
	strip mediakeysd
