#ifndef SWIFTY_H
#define SWIFTY_H


//
// misc utils
//

#define MERGE_TOKENS(a, b) a##b


//
// let and var
//

#ifdef __cplusplus
#define var auto
#else
#define var __auto_type
#endif

#define let const var


//
// defer
//

static inline void defer_call_block(void (^*b)(void)) {(*b)();}
#define _DEFER_VAR_NAME(a) MERGE_TOKENS(_defer_, a)
#define defer \
  __attribute__((cleanup(defer_call_block))) \
  void (^_DEFER_VAR_NAME(__COUNTER__))(void) =


#endif
