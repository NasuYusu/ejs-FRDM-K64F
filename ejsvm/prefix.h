/*
 * eJS Project
 * Kochi University of Technology
 * The University of Electro-communications
 *
 * The eJS Project is the successor of the SSJS Project at The University of
 * Electro-communications.
 */

#ifndef PREFIX_H_
#define PREFIX_H_

/*
  compilation options
*/

#ifndef NDEBUG
#define DEBUG 1
#define DEBUG_PRINT
#endif

#ifndef NDEBUG
#define GC_DEBUG 1
#define STATIC        /* make symbols global for debugger */
#define STATIC_INLINE /* make symbols global for debugger */
#else
#undef GC_DEBUG
#define STATIC static
#define STATIC_INLINE static inline
#endif

#define STROBJ_HAS_HASH

/* #define CALC_TIME */
/* #define USE_PAPI */
/* #define USE_FASTGLOBAL */
/* #define USE_ASM2 */
/* #define CALC_CALL */

#define HIDDEN_CLASS

#define USE_OBC

#ifdef CALC_CALL
#define CALLCOUNT_UP() callcount++
#else
#define CALLCOUNT_UP()
#endif

#define PRELOAD
//#define TIME_MBED
//#define GC_TIME_MBED
//#define ORDER_HASH
//#define PRINT_HASH

#endif /* PREFIX_H_ */

/* Local Variables:      */
/* mode: c               */
/* c-basic-offset: 2     */
/* indent-tabs-mode: nil */
/* End:                  */
