/*
 * eJS Project
 * Kochi University of Technology
 * The University of Electro-communications
 *
 * The eJS Project is the successor of the SSJS Project at The University of
 * Electro-communications.
 */

#include <stdlib.h>
#include <stdio.h>
#include "prefix.h"
#define EXTERN extern
#include "header.h"
#include "log.h"

#include <type_traits>

/* Objects allocated in the heap
 *                       has   stored as  visible   know
 *                      (ptag) (JSValue) (to user) (size) (type)
 *   CELLT_STRING         yes    yes       yes       fixed StringCell
 *   CELLT_FLONUM         yes    yes       yes       fixed FlonumCell
 *   CELLT_SIMPLE_OBJECT  yes    yes       yes       yes   JSObject
 *   CELLT_ARRAY          yes    yes       yes       yes   JSObject
 *   CELLT_FUNCTION       yes    yes       yes       yes   JSObject
 *   CELLT_BUILTIN        yes    yes       yes       yes   JSObject
 *   CELLT_BOXED_NUMBER   yes    yes       yes       yes   JSObject
 *   CELLT_BOXED_BOOLEAN  yes    yes       yes       yes   JSObject
 *   CELLT_BOXED_STRING   yes    yes       yes       yes   JSObject
 *   CELLT_REGEXP         yes    yes       yes       yes   JSObject
 *   CELLT_ITERATOR       yes    yes       no        yes   Iterator
 *   CELLT_PROP           no     yes       no        no    JSValue*
 *   CELLT_ARRAY_DATA     no     no        no        no    JSValue*
 *   CELLT_BYTE_ARRAY     no     no        no        no    non pointer
 *   CELLT_FUNCTION_FRAME no     no        no        yes   FunctionFrame
 *   CELLT_STR_CONS       no     no        no        fixed StrCons
 *   CELLT_CONTEXT        no     no        no        fixed Context
 *   CELLT_STACK          no     no        no        no    JSValue*
 *   CELLT_HASHTABLE      no     no        no        fixed HashTable
 *   CELLT_HASH_BODY      no     no        no        no    HashCell**
 *   CELLT_HASH_CELL      no     no        no        fixed HashCell
 *   CELLT_PROPERTY_MAP   no     yes       no        fixed PropertyMap
 *   CELLT_SHAPE          no     no        no        fixed Shape
 *   CELLT_UNWIND         no     no        no        fixed UnwindProtect
 *   CELLT_PROPERTY_MAP_LIST no  no        no        fixed PropertyMapList
 *
 * Objects that do not know their size (PROP, ARRAY_DATA, STACK, HASH_BODY)
 * are stored in a dedicated slot and scand together with their owners.
 *
 * CELLT_PROP is stored in the last embedded slot.
 * CELLT_PROPERTY_MAP is stored as the value of property __property_map__
 * of a prototype object.
 *
 * Static data structures
 *   FunctionTable[] function_table (global.h)
 *   StrTable string_table (global.h)
 */

#if 0
#define GCLOG(...) LOG(__VA_ARGS__)
#define GCLOG_TRIGGER(...) LOG(__VA_ARGS__)
#define GCLOG_ALLOC(...) LOG(__VA_ARGS__)
#define GCLOG_SWEEP(...) LOG(__VA_ARGS__)
#else /* 0 */
#define GCLOG(...)
#define GCLOG_TRIGGER(...)
#define GCLOG_ALLOC(...)
#define GCLOG_SWEEP(...)
#endif /* 0 */

/*
 * Constants
 */

enum gc_phase {
  PHASE_INACTIVE,
  PHASE_INITIALISE,
  PHASE_MARK,
  PHASE_WEAK,
  PHASE_SWEEP,
  PHASE_FINALISE,
};

/*
 * Variables
 */
static enum gc_phase gc_phase = PHASE_INACTIVE;
static Context *the_context;

/* gc root stack */
#define MAX_ROOTS 1000
JSValue *gc_root_stack[MAX_ROOTS];
int gc_root_stack_ptr = 0;

STATIC int gc_disabled = 1;

#ifdef MARK_STACK
#define MARK_STACK_SIZE 1000 * 1000
static uintptr_t mark_stack[MARK_STACK_SIZE];
static int mark_stack_ptr;
#endif /* MARK_STACK */

int generation = 0;
int gc_sec;
int gc_usec;
#ifdef GC_PROF
uint64_t total_alloc_bytes;
uint64_t total_alloc_count;
uint64_t pertype_alloc_bytes[256];
uint64_t pertype_alloc_count[256];
uint64_t pertype_live_bytes[256];
uint64_t pertype_live_count[256];

const char *cell_type_name[NUM_DEFINED_CELL_TYPES + 1] = {
    /* 00 */ "free",
    /* 01 */ "",
    /* 02 */ "",
    /* 03 */ "",
    /* 04 */ "STRING",
    /* 05 */ "FLONUM",
    /* 06 */ "SIMPLE_OBJECT",
    /* 07 */ "ARRAY",
    /* 08 */ "FUNCTION",
    /* 09 */ "BUILTIN",
    /* 0A */ "ITERATOR",
    /* 0B */ "REGEXP",
    /* 0C */ "BOXED_STRING",
    /* 0D */ "BOXED_NUMBER",
    /* 0E */ "BOXED_BOOLEAN",
    /* 0F */ "",
    /* 10 */ "",
    /* 11 */ "PROP",
    /* 12 */ "ARRAY_DATA",
    /* 13 */ "BYTE_ARRAY",
    /* 14 */ "FUNCTION_FRAME",
    /* 15 */ "STR_CONS",
    /* 16 */ "CONTEXT",
    /* 17 */ "STACK",
    /* 18 */ "" /* was HIDDEN_CLASS */,
    /* 19 */ "HASHTABLE",
    /* 1a */ "HASH_BODY",
    /* 1b */ "HASH_CELL",
    /* 1c */ "PROPERTY_MAP",
    /* 1d */ "SHAPE",
    /* 1e */ "UNWIND",
    /* 1f */ "PROPERTY_MAP_LIST",
};
#endif /* GC_PROF */

/*
 * prototype
 */
/* GC */
STATIC_INLINE int check_gc_request(Context *, int);
STATIC void garbage_collection(Context *ctx);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_roots(Context *ctx);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void weak_clear_StrTable(StrTable *table);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void weak_clear(void);
#ifdef MARK_STACK
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC_INLINE void process_node(uintptr_t ptr);
#endif /* MARK_STACK */
#ifdef ALLOC_SITE_CACHE
STATIC void alloc_site_update_info(JSObject *p);
#endif /* ALLOC_SITE_CACHE */

void init_memory(size_t bytes)
{
  space_init(bytes);
  gc_root_stack_ptr = 0;
  gc_disabled = 1;
  generation = 1;
  gc_sec = 0;
  gc_usec = 0;
}

void* gc_malloc(Context *ctx, uintptr_t request_bytes, cell_type_t type)
{
  void *addr;
#ifdef DEBUG
  static int count;
  count++;
#endif /* DEBUG */
  
  if (check_gc_request(ctx, 0))
    garbage_collection(ctx);
  addr = space_alloc(request_bytes, type);
  GCLOG_ALLOC("gc_malloc: req %x bytes type %d => %p\n",
              request_bytes, type, addr);
  if (addr == NULL) {
    if (check_gc_request(ctx, 1)) {
#ifdef GC_DEBUG
      printf("emergency GC\n");
#endif /* GC_DEBUG */
      garbage_collection(ctx);
      addr = space_alloc(request_bytes, type);
    }
    if (addr == NULL) {
      printf("Out of memory\n");
#ifdef GC_DEBUG
      printf("#GC = %d\n", generation);
      space_print_memory_status();
#endif /* GC_DEBUG */
      abort();
    }
  }
#ifdef GC_PROF
  if (addr != NULL) {
    size_t bytes = request_bytes;
    total_alloc_bytes += bytes;
    total_alloc_count++;
    pertype_alloc_bytes[type] += bytes;
    pertype_alloc_count[type]++;
  }
#endif /* GC_PROF */
  return addr;
}

#ifdef FLONUM_SPACE
FlonumCell *gc_try_alloc_flonum(double x)
{
  return space_try_alloc_flonum(x);
}
#endif /* FLONUM_SPACE */

void disable_gc(void)
{
  gc_disabled++;
}

void enable_gc(Context *ctx)
{
  if (--gc_disabled == 0) {
    if (check_gc_request(ctx, 0))
      garbage_collection(ctx);
  }
}

void try_gc(Context *ctx)
{
  if (check_gc_request(ctx, 0))
    garbage_collection(ctx);
}


/*
 * GC
 */
#ifdef CXX_TRACER
#ifdef CXX_TRACER_RV
class DefaultTracer {
 public:

  template<typename T>
  static T *process_edge(T *p);
  static JSValue process_edge(JSValue v);
  static void process_edge_function_frame(JSValue *vp) {
    //process_edge(reinterpret_cast<void **>(static_cast<void *>(vp)));
    *vp = (JSValue) (uintjsv_t) (uintptr_t)
      process_edge(jsv_to_function_frame(*vp));
  }
  static void mark_cell(void **p) {
    ::mark_cell(*p);
  }
  static bool test_and_mark_cell(void **p) {
    return ::test_and_mark_cell(*p);
  }

  // define regardless of is_arg_reference()
  static bool is_marked_cell(void *p) { return ::is_marked_cell(p); }
};

#define PROCESS_EDGE(x) do {                                    \
    x = Tracer::process_edge((x));                             \
  } while(0)

#define PROCESS_EDGE_FUNCTION_FRAME(x) do {                     \
    Tracer::process_edge_function_frame(&(x));                   \
  } while(0)

#define MARK_CELL(x) do {                                       \
    Tracer::mark_cell((void**) &(x));                           \
  } while(0)

#define TEST_AND_MARK_CELL(x) ({                                \
  int retval;                                                   \
  retval = Tracer::test_and_mark_cell((void**) &(x));           \
  retval;                                                       \
})

#else /* CXX_TRACER_RV */
class DefaultTracer {
 public:

  static constexpr bool is_arg_reference() {
#ifdef CXX_TRACER_CBV
    return false;
#else /* CXX_TRACER_CBV */
    return true;
#endif /* CXX_TRACER_CBV */
  }

  // define if is_arg_referenec() => false
  static void process_edge(void *p);
  static void process_edge(JSValue v);
#ifdef CXX_TRACER_CBV
  static void process_edge_function_frame(JSValue v) {
    void *p = jsv_to_function_frame(v);
    process_edge(p);
  }
  static void mark_cell(void *p) {
    ::mark_cell(p);
  }
  static bool test_and_mark_cell(void *p) {
    return ::test_and_mark_cell(p);
  }
#else /* CXX_TRACER_CBV */
  static void process_edge_function_frame(JSValue v);
  static void mark_cell(void *p);
  static bool test_and_mark_cell(void *p);
#endif /* CXX_TRACER_CBV */

  // define if is_arg_referenec() => true
  static void process_edge(void **pp);
  static void process_edge(JSValue *vp);
#ifndef CXX_TRACER_CBV
  static void process_edge_function_frame(JSValue *vp) {
    //process_edge(reinterpret_cast<void **>(static_cast<void *>(vp)));
    process_edge(reinterpret_cast<void**>(vp));
  }
  static void mark_cell(void **p) {
    ::mark_cell(*p);
  }
  static bool test_and_mark_cell(void **p) {
    return ::test_and_mark_cell(*p);
  }
#else /* CXX_TRACER_CBV */
  static void process_edge_function_frame(JSValue *vp);
  static void mark_cell(void **ptr);
  static bool test_and_mark_cell(void **p);
#endif /* CXX_TRACER_CBV */

  // define regardless of is_arg_reference()
  static bool is_marked_cell(void *p) { return ::is_marked_cell(p); }
};

template<typename T>
static inline void **to_voidpp(T** p) { return (void**) p; }
static inline JSValue *to_voidpp(JSValue *p) { return p; }

#define PROCESS_EDGE(x) do {                                    \
    if (Tracer::is_arg_reference())                             \
      Tracer::process_edge(to_voidpp(&(x)));                    \
    else                                                        \
      Tracer::process_edge((x));                                \
  } while(0)

#define PROCESS_EDGE_FUNCTION_FRAME(x) do {                     \
    if (Tracer::is_arg_reference())                             \
      Tracer::process_edge_function_frame(&(x));                \
    else                                                        \
      Tracer::process_edge_function_frame((x));                 \
  } while(0)

#define MARK_CELL(x) do {                                       \
    if (Tracer::is_arg_reference())                             \
      Tracer::mark_cell((void**) &(x));                         \
    else                                                        \
      Tracer::mark_cell((x));                                   \
  } while(0)

#define TEST_AND_MARK_CELL(x) ({                                \
  bool retval;                                                  \
  if (Tracer::is_arg_reference())                               \
    retval = Tracer::test_and_mark_cell((void**) &(x));          \
  else                                                          \
    retval = Tracer::test_and_mark_cell((x));                   \
  retval;                                                       \
  })
#endif /* CXX_TRACER_RV */
#endif /* CXX_TRACER */

#ifdef MARK_STACK
STATIC_INLINE void mark_stack_push(uintptr_t ptr)
{
  assert(mark_stack_ptr < MARK_STACK_SIZE);
  mark_stack[mark_stack_ptr++] = ptr;
}

STATIC_INLINE uintptr_t mark_stack_pop()
{
  return mark_stack[--mark_stack_ptr];
}

STATIC_INLINE int mark_stack_is_empty()
{
  return mark_stack_ptr == 0;
}

#ifdef CXX_TRACER
template <typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_mark_stack()
{
  while (!mark_stack_is_empty()) {
    uintptr_t ptr = mark_stack_pop();
#ifdef CXX_TRACER
    process_node<Tracer>(ptr);
#else /* CXX_TRACER */
    process_node(ptr);
#endif /* CXX_TRACER */
  }
}
#endif /* MARK_STACK */

STATIC_INLINE int check_gc_request(Context *ctx, int force)
{
  if (force || space_check_gc_request()) {
    if (ctx == NULL) {
      GCLOG_TRIGGER("Needed gc for js_space -- cancelled: ctx == NULL\n");
      return 0;
    }
    if (gc_disabled) {
      GCLOG_TRIGGER("Needed gc for js_space -- cancelled: GC disabled\n");
      return 0;
    }
    return 1;
  }
  GCLOG_TRIGGER("no GC needed (%d bytes free)\n", js_space.free_bytes);
  return 0;
}

STATIC void garbage_collection(Context *ctx)
{
  struct rusage ru0, ru1;

  /* initialise */
  gc_phase = PHASE_INITIALISE;
  GCLOG("Before Garbage Collection\n");
  if (cputime_flag == TRUE)
    getrusage(RUSAGE_SELF, &ru0);
  the_context = ctx;

  /* mark */
  gc_phase = PHASE_MARK;
#ifdef CXX_TRACER
  scan_roots<DefaultTracer>(ctx);
#else /* CXX_TRACER */
  scan_roots(ctx);
#endif /* CXX_TRACER */

#ifdef MARK_STACK
#ifdef CXX_TRACER
  process_mark_stack<DefaultTracer>();
#else /* CXX_TRACER */
  process_mark_stack();
#endif /* CXX_TRACER */
#endif /* MARK_STACK */

  /* profile */
#ifdef CHECK_MATURED
  check_matured();
#endif /* CHECK_MATURED */

  /* weak */
  gc_phase = PHASE_WEAK;
#ifdef CXX_TRACER
  weak_clear<DefaultTracer>();
#else /* CXX_TRACER */
  weak_clear();
#endif /* CXX_TRACER */

  /* sweep */
  gc_phase = PHASE_SWEEP;
  sweep();

  /* finalise */
  gc_phase = PHASE_FINALISE;
  GCLOG("After Garbage Collection\n");
  if (cputime_flag == TRUE) {
    time_t sec;
    suseconds_t usec;

    getrusage(RUSAGE_SELF, &ru1);
    sec = ru1.ru_utime.tv_sec - ru0.ru_utime.tv_sec;
    usec = ru1.ru_utime.tv_usec - ru0.ru_utime.tv_usec;
    if (usec < 0) {
      sec--;
      usec += 1000000;
    }
    gc_sec += sec;
    gc_usec += usec;
  }

  generation++;
  /*  printf("Exit gc, generation = %d\n", generation); */

  gc_phase = PHASE_INACTIVE;
}

/*
 * Tracer
 *
 *  process_edge, process_edge_XXX
 *    If the destination node is not marked, mark it and process the
 *    destination node. XXX is specialised version for type XXX.
 *  scan_XXX
 *    Scan static structure XXX.
 *  process_node_XXX
 *    Scan object of type XXX in the heap.  Move it if nencessary.
 */

#ifdef CXX_TRACER
/*
class DefaultTracer {
public:
    static void process_edge(uintptr_t ptr);
    static void mark_cell(void *ptr) { ::mark_cell(ptr); }
    static bool test_and_mark_cell(void *ptr) { return ::test_and_mark_cell(ptr); }
};
*/
#else /* CXX_TRACER */
STATIC void process_edge(uintptr_t ptr);
#endif /* CXX_TRACER */
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_node_FunctionFrame(FunctionFrame *p);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_node_Context(Context *p);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_function_table_entry(FunctionTable *p);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_stack(JSValue* stack, int sp, int fp);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_edge_JSValue_array(JSValue *p, size_t start, size_t length);
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_edge_HashBody(HashCell **p, size_t length);

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC_INLINE void process_node(uintptr_t ptr)
{
  /* part of code for processing the node is inlined */
  switch (space_get_cell_type(ptr)) {
  case CELLT_STRING:
  case CELLT_FLONUM:
    return;
  case CELLT_SIMPLE_OBJECT:
    break;
  case CELLT_ARRAY:
    {
      JSObject *p = (JSObject *) ptr;
      JSValue *a_body = get_array_ptr_body(p);
      if (a_body != NULL) {
        /* a_body may be NULL during initialization */
        uint64_t a_size = get_array_ptr_size(p);
        uint64_t a_length =
          (uint64_t) number_to_double(get_array_ptr_length(p));
        size_t len = a_length < a_size ? a_length : a_size;
#ifdef CXX_TRACER
        PROCESS_EDGE(p->eprop[array_length_index]);
#else /* CXX_TRACER */
        process_edge((uintptr_t) get_array_ptr_length(p));
#endif /* CXX_TRACER */
#ifdef CXX_TRACER
        process_edge_JSValue_array<Tracer>(a_body, 0, len);
#else /* CXX_TRACER */
        process_edge_JSValue_array(a_body, 0, len);
#endif /* CXX_TRACER */
      }
      break;
    }
  case CELLT_FUNCTION:
    {
      JSObject *p = (JSObject *) ptr;
#ifndef CXX_TRACER
      FunctionFrame *frame = get_function_ptr_environment(p);
#endif /* CXX_TRACER */
      /* FunctionTable *ftentry = function_ptr_table_entry(p);
       * scan_function_table_entry(ftentry);
       *    All function table entries are scanned through Context
       */
#ifdef CXX_TRACER
      PROCESS_EDGE(p->eprop[function_environment_index]);
#else /* CXX_TRACER */
      process_edge((uintptr_t) frame);
#endif /* CXX_TRACER */
      break;
    }
  case CELLT_BUILTIN:
    break;
  case CELLT_BOXED_NUMBER:
    {
      JSObject *p = (JSObject *) ptr;
#ifdef CXX_TRACER
      PROCESS_EDGE(p->eprop[number_object_value_index]);
#else /* CXX_TRACER */
      JSValue value = get_number_object_ptr_value(p);
      process_edge((uintptr_t) value);
#endif /* CXX_TRACER */
      break;
    }
  case CELLT_BOXED_STRING:
    {
      JSObject *p = (JSObject *) ptr;
#ifdef CXX_TRACER
      PROCESS_EDGE(p->eprop[string_object_value_index]);
#else /* CXX_TRACER */
      JSValue value = get_string_object_ptr_value(p);
      process_edge((uintptr_t) value);
#endif /* CXX_TRACER */
      break;
    }
  case CELLT_BOXED_BOOLEAN:
    {
#ifdef DEBUG
      JSObject *p = (JSObject *) ptr;
      JSValue value = get_number_object_ptr_value(p);
      assert(is_boolean(value));
#endif /* DEBUG */
      break;
    }
#ifdef USE_REGEXP
  case CELLT_REGEXP:
    break;
#endif /* USE_REGEXP */
  case CELLT_ITERATOR:
    {
      Iterator *p = (Iterator *) ptr;
      if (p->size > 0) {
#ifdef CXX_TRACER
        process_edge_JSValue_array<Tracer>(p->body, 0, p->size);
#else /* CXX_TRACER */
        process_edge_JSValue_array(p->body, 0, p->size);
#endif /* CXX_TRACER */
      }
      return;
    }
  case CELLT_PROP:
  case CELLT_ARRAY_DATA:
    abort();
  case CELLT_BYTE_ARRAY:
    return;
  case CELLT_FUNCTION_FRAME:
#ifdef CXX_TRACER
    process_node_FunctionFrame<Tracer>((FunctionFrame *) ptr);
#else /* CXX_TRACER */
    process_node_FunctionFrame((FunctionFrame *) ptr);
#endif /* CXX_TRACER */
    return;
  case CELLT_STR_CONS:
    {
      StrCons *p = (StrCons *) ptr;
      /* WEAK: p->str */
      if (p->next != NULL) {
#ifdef CXX_TRACER
        PROCESS_EDGE(p->next);
#else /* CXX_TRACER */
        process_edge((uintptr_t) p->next); /* StrCons */
#endif /* CXX_TRACER */
      }
      return;
    }
  case CELLT_CONTEXT:
#ifdef CXX_TRACER
    process_node_Context<Tracer>((Context *) ptr);
#else /* CXX_TRACER */
    process_node_Context((Context *) ptr);
#endif /* CXX_TRACER */
    return;
  case CELLT_STACK:
    abort();
  case CELLT_HASHTABLE:
    {
      HashTable *p = (HashTable *) ptr;
      if (p->body != NULL) {
#ifdef CXX_TRACER
        process_edge_HashBody<Tracer>(p->body, p->size);
#else /* CXX_TRACER */
        process_edge_HashBody(p->body, p->size);
#endif /* CXX_TRACER */
      }
      return;
    }
  case CELLT_HASH_BODY:
    abort();
  case CELLT_HASH_CELL:
    {
      HashCell *p = (HashCell *) ptr;
#ifdef CXX_TRACER
      PROCESS_EDGE(p->entry.key);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p->entry.key);
#endif /* CXX_TRACER */
#ifndef HC_SKIP_INTERNAL
      /* transition link is weak if HC_SKIP_INTERNAL */
      if (is_transition(p->entry.attr)) {
#ifdef CXX_TRACER
        PROCESS_EDGE(p->entry.data.u.pm);
#else /* CXX_TRACER */
        process_edge((uintptr_t) p->entry.data.u.pm);  /* PropertyMap */
#endif /* CXX_TRACER */
      }
#endif /* HC_SKIP_INTERNAL */
      if (p->next != NULL) {
#ifdef CXX_TRACER
        PROCESS_EDGE(p->next);
#else /* CXX_TRACER */
        process_edge((uintptr_t) p->next);  /* HashCell */
#endif /* CXX_TRACER */
      }
      return;
    }
  case CELLT_PROPERTY_MAP:
    {
      PropertyMap *p = (PropertyMap *) ptr;
#ifdef CXX_TRACER
      PROCESS_EDGE(p->map);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p->map); /* HashTable */
#endif /* CXX_TRACER */
#ifndef HC_SKIP_INTERNAL
      if (p->prev != NULL) {
        /* weak if HC_SKIP_INTERNAL */
#ifdef CXX_TRACER
        PROCESS_EDGE(p->prev);
#else /* CXX_TRACER */
        process_edge((uintptr_t) p->prev); /* PropertyMap */
#endif /* CXX_TRACER */
      }
#endif /* HC_SKIP_INTERNAL */
      if (p->shapes != NULL) {
#ifdef CXX_TRACER
        PROCESS_EDGE(p->shapes);
#else /* CXX_TRACER */
        process_edge((uintptr_t) p->shapes); /* Shape
                                              * (always keep the largest one) */
#endif /* CXX_TRACER */
      }
#ifdef CXX_TRACER
      PROCESS_EDGE(p->__proto__);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p->__proto__);
#endif /* CXX_TRACER */
      return;
    }
  case CELLT_SHAPE:
    {
      Shape *p = (Shape *) ptr;
#ifdef CXX_TRACER
      PROCESS_EDGE(p->pm);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p->pm);
#endif /* CXX_TRACER */
#ifndef NO_SHAPE_CACHE
#ifdef WEAK_SHAPE_LIST
      /* p->next is weak */
#else /* WEAK_SHAPE_LIST */
      if (p->next != NULL)
#ifdef CXX_TRACER
        PROCESS_EDGE(p->next);
#else /* CXX_TRACER */
        process_edge((uintptr_t) p->next);
#endif /* CXX_TRACER */
#endif /* WEAK_SHAPE_LIST */
#endif /* NO_SHAPE_CACHE */
      return;
    }
  case CELLT_UNWIND:
    {
      UnwindProtect *p = (UnwindProtect *) ptr;
#ifdef CXX_TRACER
      PROCESS_EDGE(p->prev);
      PROCESS_EDGE(p->lp);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p->prev);
      process_edge((uintptr_t) p->lp);
#endif /* CXX_TRACER */
    }
#if defined(HC_SKIP_INTERNAL) || defined(WEAK_SHAPE_LIST)
  case CELLT_PROPERTY_MAP_LIST:
    abort();
    break;
#endif /* HC_SKIP_INTERNAL || WEAK_SHAPE_LIST */
  default:
    abort();
  }

  /* common fields and payload of JSObject */
  {
    JSObject *p = (JSObject *) ptr;
    /* 1. shape */
#ifdef CXX_TRACER
    PROCESS_EDGE(p->shape);
#else /* CXX_TRACER */
    process_edge((uintptr_t) p->shape);
#endif /* CXX_TRACER */

    /* 2. embedded propertyes */
    Shape *os = p->shape;
    int n_extension = os->n_extension_slots;
    size_t actual_embedded = os->n_embedded_slots - (n_extension == 0 ? 0 : 1);
    size_t i;
    for (i = os->pm->n_special_props; i < actual_embedded; i++)
#ifdef CXX_TRACER
      PROCESS_EDGE(p->eprop[i]);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p->eprop[i]);
#endif /* CXX_TRACER */
    if (n_extension != 0) {
      /* 3. extension */
      JSValue *extension = jsv_to_extension_prop(p->eprop[actual_embedded]);
#ifdef CXX_TRACER
      process_edge_JSValue_array<Tracer>(extension, 0,
                                 os->pm->n_props - actual_embedded);
#else /* CXX_TRACER */
      process_edge_JSValue_array(extension, 0,
                                 os->pm->n_props - actual_embedded);
#endif /* CXX_TRACER */
    }
#ifdef ALLOC_SITE_CACHE
    /* 4. allocation site cache */
    if (p->alloc_site != NULL)
      alloc_site_update_info(p);
#endif /* ALLOC_SITE_CACHE */
  }
}

#ifdef CXX_TRACER
#ifdef CXX_TRACER_RV

template<typename T>
T *DefaultTracer::process_edge(T *p)
{
  if (in_js_space(p) && ::test_and_mark_cell(p))
    return p;
#ifdef MARK_STACK
  mark_stack_push((uintptr_t) p);
#else /* MARK_STACK */
  process_node<DefaultTracer>(p);
#endif /* MARK_STACK */
  return p;
}

JSValue DefaultTracer::process_edge(JSValue v)
{
  if (is_fixnum(v) || is_special(v))
    return v;
  uintptr_t ptr = (uintptr_t) clear_ptag(v);
  void *p = (void *) ptr;

  if (in_js_space(p) && ::test_and_mark_cell(p))
    return v;

#ifdef MARK_STACK
  mark_stack_push((uintptr_t) p);
#else /* MARK_STACK */
  process_node<DefaultTracer>(p);
#endif /* MARK_STACK */

  return v;
}

#else /* CXX_TRACER_RV */
#ifdef CXX_TRACER_CBV
void DefaultTracer::process_edge(void *p)
{
  if (in_js_space(p) && ::test_and_mark_cell(p))
    return;
#ifdef MARK_STACK
  mark_stack_push((uintptr_t) p);
#else /* MARK_STACK */
  process_node<DefaultTracer>(p);
#endif /* MARK_STACK */
}

void DefaultTracer::process_edge(JSValue v)
{
  if (is_fixnum(v) || is_special(v))
    return;
  uintptr_t ptr = (uintptr_t) clear_ptag(v);
  process_edge((void *) ptr);
}
#else /* CXX_TRACER_CBV */
void DefaultTracer::process_edge(void **pp)
{
  void *p = *pp;
  if (in_js_space(p) && ::test_and_mark_cell(p))
    return;
#ifdef MARK_STACK
  mark_stack_push((uintptr_t) p);
#else /* MARK_STACK */
  process_node<DefaultTracer>(p);
#endif /* MARK_STACK */
}

void DefaultTracer::process_edge(JSValue *vp)
{
  JSValue v = *vp;
  if (is_fixnum(v) || is_special(v))
    return;
  void *p = (void *)(uintptr_t) clear_ptag(v);
  if (in_js_space(p) && ::test_and_mark_cell(p))
    return;
#ifdef MARK_STACK
  mark_stack_push((uintptr_t) p);
#else /* MARK_STACK */
  process_node<DefaultTracer>(p);
#endif /* MARK_STACK */
}
#endif /* CXX_TRACER_CBV */
#endif /* CXX_TRACER_RV */
#else /* CXX_TRACER */
STATIC void process_edge(uintptr_t ptr)
{
  if (is_fixnum(ptr) || is_special(ptr))
    return;

  ptr = ptr & ~TAGMASK;
  if (in_js_space((void *) ptr) && test_and_mark_cell((void *) ptr))
    return;

#ifdef MARK_STACK
  mark_stack_push(ptr);
#else /* MARK_STACK */
  process_node(ptr);
#endif /* MARK_STACK */
}
#endif /* CXX_TRACER */

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_edge_JSValue_array(JSValue *p, size_t start, size_t length)
{
  size_t i;
  assert(in_js_space(p));
#ifdef CXX_TRACER
  if (TEST_AND_MARK_CELL(p))
#else /* CXX_TRACER */
  if (test_and_mark_cell(p))
#endif /* CXX_TRACER */
    return;
  for (i = start; i < length; i++) {
#ifdef CXX_TRACER
    PROCESS_EDGE(p[i]);
#else /* CXX_TRACER */
    process_edge((uintptr_t) p[i]);
#endif /* CXX_TRACER */
  }
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_edge_HashBody(HashCell **p, size_t length)
{
  size_t i;
  assert(in_js_space(p));
#ifdef CXX_TRACER
  if (TEST_AND_MARK_CELL(p))
#else /* CXX_TRACER */
  if (test_and_mark_cell(p))
#endif /* CXX_TRACER */
    return;
  for (i = 0; i < length; i++)
    if (p[i] != NULL) {
#ifdef CXX_TRACER
      PROCESS_EDGE(p[i]);
#else /* CXX_TRACER */
      process_edge((uintptr_t) p[i]);  /* HashCell */
#endif /* CXX_TRACER */
    }
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_node_FunctionFrame(FunctionFrame *p)
{
  int i;

  if (p->prev_frame != NULL) {
#ifdef CXX_TRACER
    PROCESS_EDGE(p->prev_frame);
#else /* CXX_TRACER */
    process_edge((uintptr_t) p->prev_frame); /* FunctionFrame */
#endif /* CXX_TRACER */
  }
#ifdef CXX_TRACER
  PROCESS_EDGE(p->arguments);
#else /* CXX_TRACER */
  process_edge((uintptr_t) p->arguments);
#endif /* CXX_TRACER */
  for (i = 0; i < p->nlocals; i++) {
#ifdef CXX_TRACER
    PROCESS_EDGE(p->locals[i]);
#else /* CXX_TRACER */
    process_edge((uintptr_t) p->locals[i]);
#endif /* CXX_TRACER */
  }
#ifdef DEBUG
  assert(p->locals[p->nlocals - 1] == JS_UNDEFINED);
#endif /* DEBUG */
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void process_node_Context(Context *context)
{
  int i;

#ifdef CXX_TRACER
  PROCESS_EDGE(context->global);
#else /* CXX_TRACER */
  process_edge((uintptr_t) context->global);
#endif /* CXX_TRACER */
  /* function table is a static data structure
   *   Note: spreg.cf points to internal address of the function table.
   */
  for (i = 0; i < FUNCTION_TABLE_LIMIT; i++) {
#ifdef CXX_TRACER
    scan_function_table_entry<Tracer>(&context->function_table[i]);
#else /* CXX_TRACER */
    scan_function_table_entry(&context->function_table[i]);
#endif /* CXX_TRACER */
  }
#ifdef CXX_TRACER
  PROCESS_EDGE(context->spreg.lp);
  PROCESS_EDGE(context->spreg.a);
  PROCESS_EDGE(context->spreg.err);
#else /* CXX_TRACER */
  process_edge((uintptr_t) context->spreg.lp);  /* FunctionFrame */
  process_edge((uintptr_t) context->spreg.a);
  process_edge((uintptr_t) context->spreg.err);
#endif /* CXX_TRACER */
  if (context->exhandler_stack_top != NULL) {
#ifdef CXX_TRACER
    PROCESS_EDGE(context->exhandler_stack_top);
#else /* CXX_TRACER */
    process_edge((uintptr_t) context->exhandler_stack_top);
#endif /* CXX_TRACER */
  }
#ifdef CXX_TRACER
  PROCESS_EDGE(context->lcall_stack);
#else /* CXX_TRACER */
  process_edge((uintptr_t) context->lcall_stack);
#endif /* CXX_TRACER */

  /* process stack */
#ifdef CXX_TRACER
  assert(!Tracer::is_marked_cell(context->stack));
#else /* CXX_TRACER */
  assert(!is_marked_cell(context->stack));
#endif /* CXX_TRACER */
#ifdef CXX_TRACER
  MARK_CELL(context->stack);
#else /* CXX_TRACER */
  mark_cell(context->stack);
#endif /* CXX_TRACER */
#ifdef CXX_TRACER
  scan_stack<Tracer>(context->stack, context->spreg.sp, context->spreg.fp);
#else /* CXX_TRACER */
  scan_stack(context->stack, context->spreg.sp, context->spreg.fp);
#endif /* CXX_TRACER */
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_function_table_entry(FunctionTable *p)
{
  /* trace constant pool */
  {
    JSValue *constant_pool = (JSValue *) &p->insns[p->n_insns];
    size_t n_constants = p->n_constants;
    size_t i;
    for (i = 0; i < n_constants; i++) {
#ifdef CXX_TRACER
      PROCESS_EDGE(constant_pool[i]);
#else /* CXX_TRACER */
      process_edge((uintptr_t) constant_pool[i]);
#endif /* CXX_TRACER */
    }
  }

#ifdef ALLOC_SITE_CACHE
  /* scan Allocation Sites */
  {
    int i;
    for (i = 0; i < p->n_insns; i++) {
      Instruction *insn = &p->insns[i];
      AllocSite *alloc_site = &insn->alloc_site;
      if (alloc_site->shape != NULL) {
#ifdef CXX_TRACER
        PROCESS_EDGE(alloc_site->shape);
#else /* CXX_TRACER */
        process_edge((uintptr_t) alloc_site->shape);
#endif /* CXX_TRACER */
      }
      /* TODO: too eary PM sacnning. scan after updating alloc site info */
      if (alloc_site->pm != NULL) {
#ifdef CXX_TRACER
        PROCESS_EDGE(alloc_site->pm);
#else /* CXX_TRACER */
        process_edge((uintptr_t) alloc_site->pm);
#endif /* CXX_TRACER */
      }
    }
  }
#endif /* ALLOC_SITE_CACHE */

#ifdef INLINE_CACHE
  /* scan Inline Cache */
  {
    int i;
    for (i = 0; i < p->n_insns; i++) {
      Instruction *insn = &p->insns[i];
      InlineCache *ic = &insn->inl_cache;
      if (ic->shape != NULL) {
#ifdef CXX_TRACER
        PROCESS_EDGE(ic->shape);
        PROCESS_EDGE(ic->prop_name);
#else /* CXX_TRACER */
        process_edge((uintptr_t) ic->shape);
        process_edge((uintptr_t) ic->prop_name);
#endif /* CXX_TRACER */
      }
    }
  }
#endif /* INLINE_CACHE */
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_stack(JSValue* stack, int sp, int fp)
{
  while (1) {
    while (sp >= fp) {
#ifdef CXX_TRACER
      PROCESS_EDGE(stack[sp]);
#else /* CXX_TRACER */
      process_edge((uintptr_t) stack[sp]);
#endif /* CXX_TRACER */
      sp--;
    }
    if (sp < 0)
      return;
    fp = stack[sp--]; /* FP */
#ifdef CXX_TRACER
    PROCESS_EDGE_FUNCTION_FRAME(stack[sp--]); /* LP */
#else /* CXX_TRACER */
    process_edge((uintptr_t) jsv_to_function_frame(stack[sp--])); /* LP */
#endif /* CXX_TRACER */
    sp--; /* PC */
    sp--; /* CF (function table entries are scanned as a part of context) */
  }
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_string_table(StrTable *p)
{
  StrCons **vec = p->obvector;
  size_t length = p->size;
  size_t i;

  for (i = 0; i < length; i++)
    if (vec[i] != NULL) {
#ifdef CXX_TRACER
      PROCESS_EDGE(vec[i]);
#else /* CXX_TRACER */
      process_edge((uintptr_t) vec[i]); /* StrCons */
#endif /* CXX_TRACER */
    }
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void scan_roots(Context *ctx)
{
  int i;

  /*
   * global variables
   */
  {
    struct global_constant_objects *gconstsp = &gconsts;
    JSValue *p;
    for (p = (JSValue *) gconstsp; p < (JSValue *) (gconstsp + 1); p++) {
#ifdef CXX_TRACER
      PROCESS_EDGE(*p);
#else /* CXX_TRACER */
      process_edge((uintptr_t) *p);
#endif /* CXX_TRACER */
    }
  }
  {
    struct global_property_maps *gpmsp = &gpms;
    PropertyMap **p;
    for (p = (PropertyMap **) gpmsp; p < (PropertyMap **) (gpmsp + 1); p++) {
#ifdef CXX_TRACER
      PROCESS_EDGE(*p);
#else /* CXX_TRACER */
      process_edge((uintptr_t) *p);
#endif /* CXX_TRACER */
    }
  }
  {
    struct global_object_shapes *gshapesp = &gshapes;
    Shape** p;
    for (p = (Shape **) gshapesp; p < (Shape **) (gshapesp + 1); p++) {
#ifdef CXX_TRACER
      PROCESS_EDGE(*p);
#else /* CXX_TRACER */
      process_edge((uintptr_t) *p);
#endif /* CXX_TRACER */
    }
  }

  /* function table: do not trace.
   *                 Used slots should be traced through Function objects
   */

  /* string table */
#ifdef CXX_TRACER
  scan_string_table<Tracer>(&string_table);
#else /* CXX_TRACER */
  scan_string_table(&string_table);
#endif /* CXX_TRACER */

  /*
   * Context
   */
#ifdef CXX_TRACER
  PROCESS_EDGE(ctx);
#else /* CXX_TRACER */
  process_edge((uintptr_t) ctx); /* Context */
#endif /* CXX_TRACER */

  /*
   * GC_PUSH'ed
   */
  for (i = 0; i < gc_root_stack_ptr; i++) {
#ifdef CXX_TRACER
    PROCESS_EDGE(*(gc_root_stack[i]));
#else /* CXX_TRACER */
    process_edge(*(uintptr_t*) gc_root_stack[i]);
#endif /* CXX_TRACER */
  }
}

/*
 * Clear pointer field to StringCell whose mark bit is not set.
 * Unlink the StrCons from the string table.  These StrCons's
 * are collected in the next collection cycle.
 */
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void weak_clear_StrTable(StrTable *table)
{
  size_t i;
  for (i = 0; i < table->size; i++) {
    StrCons ** p = table->obvector + i;
    while (*p != NULL) {
      StringCell *cell = jsv_to_normal_string((*p)->str);
#ifdef CXX_TRACER
      if (!Tracer::is_marked_cell(cell)) {
#else /* CXX_TRACER */
      if (!is_marked_cell(cell)) {
#endif /* CXX_TRACER */
        (*p)->str = JS_UNDEFINED;
        *p = (*p)->next;
      } else
        p = &(*p)->next;
    }
  }
}

#ifdef WEAK_SHAPE_LIST
#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
void weak_clear_shape_recursive(PropertyMap *pm)
{
  HashIterator iter;
  HashCell *cell;

#ifdef VERBOSE_GC_SHAPE
#defien PRINT(x...) printf(x)
#else /* VERBOSE_GC_SHAPE */
#define PRINT(x...)
#endif /* VERBOSE_GC_SHAPE */

#ifndef NO_SHAPE_CACHE
  {
    Shape **p;
    for (p = &pm->shapes; *p != NULL; ) {
      Shape *os = *p;
#ifdef CXX_TRACER
      if (Tracer::is_marked_cell(os))
#else /* CXX_TRACER */
      if (is_marked_cell(os))
#endif /* CXX_TRACER */
        p = &(*p)->next;
      else {
        Shape *skip = *p;
        *p = skip->next;
#ifdef DEBUG
        PRINT("skip %p emp: %d ext: %d\n",
              skip, skip->n_embedded_slots, skip->n_extension_slots);
        skip->next = NULL;  /* avoid Black->While check failer */
#endif /* DEBUG */
      }
    }
  }
#endif /* NO_SHAPE_CACHE */

  iter = createHashIterator(pm->map);
  while (nextHashCell(pm->map, &iter, &cell) != FAIL)
    if (is_transition(cell->entry.attr))
#ifdef CXX_TRACER
      weak_clear_shape_recursive<Tracer>(cell->entry.data.u.pm);
#else /* CXX_TRACER */
      weak_clear_shape_recursive(cell->entry.data.u.pm);
#endif /* CXX_TRACER */

#undef PRINT /* VERBOSE_GC_SHAPE */
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void weak_clear_shapes()
{
  PropertyMapList **pp;
  for (pp = &the_context->property_map_roots; *pp != NULL;) {
    PropertyMapList *e = *pp;
#ifdef CXX_TRACER
    if (Tracer::is_marked_cell(e->pm)) {
      MARK_CELL(e);
      weak_clear_shape_recursive<Tracer>(e->pm);
#else /* CXX_TRACER */
    if (is_marked_cell(e->pm)) {
      mark_cell(e);
      weak_clear_shape_recursive(e->pm);
#endif /* CXX_TRACER */
      pp = &(*pp)->next;
    } else
      *pp = (*pp)->next;
  }
}
#endif /* WEAK_SHAPE_LIST */

#ifdef HC_SKIP_INTERNAL
/*
 * Get the only transision from internal node.
 */
static PropertyMap* get_transition_dest(PropertyMap *pm)
{
  HashIterator iter;
  HashCell *p;

  iter = createHashIterator(pm->map);
  while(nextHashCell(pm->map, &iter, &p) != FAIL)
    if (is_transition(p->entry.attr)) {
      PropertyMap *ret = p->entry.data.u.pm;
#ifdef GC_DEBUG
      while(nextHashCell(pm->map, &iter, &p) != FAIL)
        assert(!is_transition(p->entry.attr));
#endif /* GC_DEBUG */
      return ret;
    }
  abort();
  return NULL;
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
static void weak_clear_property_map_recursive(PropertyMap *pm)
{
  HashIterator iter;
  HashCell *p;
  int n_transitions = 0;

#ifdef CXX_TRACER
  assert(Tracer::is_marked_cell(pm));
#else /* CXX_TRACER */
  assert(is_marked_cell(pm));
#endif /* CXX_TRACER */

  iter = createHashIterator(pm->map);
  while(nextHashCell(pm->map, &iter, &p) != FAIL)
    if (is_transition(p->entry.attr)) {
      PropertyMap *next = p->entry.data.u.pm;
      /*
       * If the next node is both
       *   1. not pointed to through strong pointers and
       *   2. outgoing edge is exactly 1,
       * then, the node is an internal node to be eliminated.
       */
#ifdef CXX_TRACER
      while (!Tracer::is_marked_cell(next) && next->n_transitions == 1) {
#else /* CXX_TRACER */
      while (!is_marked_cell(next) && next->n_transitions == 1) {
#endif /* CXX_TRACER */
#ifdef VERBOSE_WEAK
        printf("skip PropertyMap %p\n", next);
#endif /* VERBOSE_WEAK */
        next = get_transition_dest(next);
      }
#ifdef CXX_TRACER
      if (!Tracer::is_marked_cell(next) && next->n_transitions == 0) {
#else /* CXX_TRACER */
      if (!is_marked_cell(next) && next->n_transitions == 0) {
#endif /* CXX_TRACER */
        p->deleted = 1;             /* TODO: use hash_delete */
        p->entry.data.u.pm = NULL;  /* make invariant check success */
        continue;
      }
      n_transitions++;
#ifdef VERBOSE_WEAK
#ifdef CXX_TRACER
      if (Tracer::is_marked_cell(next))
#else /* CXX_TRACER */
      if (is_marked_cell(next))
#endif /* CXX_TRACER */
        printf("preserve PropertyMap %p because it has been marked\n", next);
      else
        printf("preserve PropertyMap %p because it is a branch (P=%d T=%d)\n",
               next, next->n_props, next->n_transitions);
#endif /* VERBOSE_WEAK */
      /* Resurrect if it is branching node or terminal node */
#ifdef CXX_TRACER
      PROCESS_EDGE(next);
#else /* CXX_TRACER */
      process_edge((uintptr_t) next);
#endif /* CXX_TRACER */
#ifdef MARK_STACK
#ifdef CXX_TRACER
      process_mark_stack<Tracer>();
#else /* CXX_TRACER */
      process_mark_stack();
#endif /* CXX_TRACER */
#endif /* MARK_STACK */
      p->entry.data.u.pm = next;
      next->prev = pm;
#ifdef CXX_TRACER
      weak_clear_property_map_recursive<Tracer>(next);
#else /* CXX_TRACER */
      weak_clear_property_map_recursive(next);
#endif /* CXX_TRACER */
    }
  pm->n_transitions = n_transitions;
}

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void weak_clear_property_maps()
{
  PropertyMapList **pp;
  for (pp = &the_context->property_map_roots; *pp != NULL; ) {
    PropertyMap *pm = (*pp)->pm;
#ifdef CXX_TRACER
    while(!Tracer::is_marked_cell(pm) && pm->n_transitions == 1)
#else /* CXX_TRACER */
    while(!is_marked_cell(pm) && pm->n_transitions == 1)
#endif /* CXX_TRACER */
      pm = get_transition_dest(pm);
#ifdef CXX_TRACER
    if (!Tracer::is_marked_cell(pm) && pm->n_transitions == 0)
#else /* CXX_TRACER */
    if (!is_marked_cell(pm) && pm->n_transitions == 0)
#endif /* CXX_TRACER */
      *pp = (*pp)->next;
    else {
      pm = (*pp)->pm;
#ifdef CXX_TRACER
      MARK_CELL(*pp);
#else /* CXX_TRACER */
      mark_cell(*pp);
#endif /* CXX_TRACER */
#ifdef CXX_TRACER
      if (!Tracer::is_marked_cell(pm)) {
        PROCESS_EDGE(pm);
        (*pp)->pm = pm;
#else /* CXX_TRACER */
      if (!is_marked_cell(pm)) {
        process_edge((uintptr_t) pm);
#endif /* CXX_TRACER */
#ifdef MARK_STACK
#ifdef CXX_TRACER
        process_mark_stack<Tracer>();
#else /* CXX_TRACER */
        process_mark_stack();
#endif /* CXX_TRACER */
#endif /* MARK_STACK */
      }
#ifdef CXX_TRACER
      weak_clear_property_map_recursive<Tracer>(pm);
#else /* CXX_TRACER */
      weak_clear_property_map_recursive(pm);
#endif /* CXX_TRACER */
      pp = &(*pp)->next;
    }
  }
}
#endif /* HC_SKIP_INTERNAL */

#ifdef HC_PROF

#endif /* HC_PROF */

#ifdef CXX_TRACER
template<typename Tracer>
#endif /* CXX_TRACER */
STATIC void weak_clear(void)
{
#ifdef HC_SKIP_INTERNAL
  /* !!! Do weak_clear_property_map first. This may resurrect some objects. */
#ifdef CXX_TRACER
  weak_clear_property_maps<Tracer>();
#else /* CXX_TRACER */
  weak_clear_property_maps();
#endif /* CXX_TRACER */
#endif /* HC_SKIP_INTERNAL */
#ifdef WEAK_SHAPE_LIST
#ifdef CXX_TRACER
  weak_clear_shapes<Tracer>();
#else /* CXX_TRACER */
  weak_clear_shapes();
#endif /* CXX_TRACER */
#endif /* WEAK_SHAPE_LIST */
#ifdef CXX_TRACER
  weak_clear_StrTable<Tracer>(&string_table);
#else /* CXX_TRACER */
  weak_clear_StrTable(&string_table);
#endif /* CXX_TRACER */

  /* clear cache in the context */
  the_context->exhandler_pool = NULL;
}

#ifdef ALLOC_SITE_CACHE
STATIC PropertyMap *find_lub(PropertyMap *a, PropertyMap *b)
{
  while(a != b && a->prev != NULL) {
    /* If both a->n_props and b->n_props are 0, rewind `a', so that we can
     * do NULL check only for `a'.
     */
    if (a->n_props < b->n_props)
      b = b->prev;
    else
      a = a->prev;
  }
  return a;
}

STATIC void alloc_site_update_info(JSObject *p)
{
  AllocSite *as = p->alloc_site;
  PropertyMap *pm = p->shape->pm;

  assert(as != NULL);

  /* likely case */
  if (as->pm == pm)
    return;

  if (as->pm == NULL) {
    /* 1. If the site is empty, cache this. */
    as->pm = pm;
    assert(as->shape == NULL);
  } else {
    /* 2. Otherwise, compute LUB.
     *
     *   LUB       monomorphic   polymorphic
     *   pm        mono:as->pm   poly:as->pm
     *   as->pm    mono:pm       poly:as->pm
     *   less      poly:LUB      poly:LUB
     */
    PropertyMap *lub = find_lub(pm, as->pm);
    if (lub == as->pm) {
      if (as->polymorphic)
        /* keep current as->pm */ ;
      else {
        as->pm = pm;
        as->shape = NULL;
      }
    } else if (lub == pm)
      /* keep current as->pm */  ;
    else {
      as->polymorphic = 1;
      as->pm = lub;
      as->shape = NULL;
    }
  }
}
#endif /* ALLOC_SITE_CACHE */

#ifdef GC_DEBUG
STATIC void print_memory_status(void)
{
  GCLOG("gc_disabled = %d\n", gc_disabled);
  space_print_memory_status();
}
#endif /* GC_DEBUG */

/* Local Variables:      */
/* mode: c               */
/* c-basic-offset: 2     */
/* indent-tabs-mode: nil */
/* End:                  */
