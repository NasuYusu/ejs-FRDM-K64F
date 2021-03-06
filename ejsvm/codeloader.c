/*
 * eJS Project
 * Kochi University of Technology
 * The University of Electro-communications
 *
 * The eJS Project is the successor of the SSJS Project at The University of
 * Electro-communications.
 */

#include "prefix.h"
#define EXTERN extern
#include "header.h"

#define CPU_LITTLE_ENDIAN

#define OBC_FILE_MAGIC 0xec

#if !defined(USE_SBC) && !defined(USE_OBC)
#error Either USE_SBC or USE_OBC should be defined.
#endif

#if !defined(USE_SBC) && defined(PROFILE)
#error PROFILE can be defined only when USE_SBC is defined.
#endif

static inline InstructionDisplacement
calc_displacement(int ninsns, int pc, int index)
{
  return (ninsns - pc) * (sizeof(Instruction) / sizeof(JSValue)) + index;
}

/*
 * Assign `var = val' with range check.
 */
#define load_value(var, val, min, max, type, msg)       \
  do {                                                  \
    int _val_tmp;                                       \
    _val_tmp = (val);                                   \
    if (_val_tmp < (min))                               \
      LOG_EXIT("%s : %d IS LESS THAN MIN VALUE %d.",    \
               msg, _val_tmp, (min));                   \
    if ((max) < _val_tmp)                               \
      LOG_EXIT("%s : %d IS GREATER THAN MAX VALUE %d.", \
               msg, _val_tmp, (max));                   \
    var = (type) _val_tmp;                              \
  } while(0)

#define load_small_primitive(var, val, msg)     \
  load_value(var, val,                          \
             minval_small_primitive(),          \
             maxval_small_primitive(),          \
             SmallPrimitive, msg)

#define load_register(var, val, msg)            \
  load_value(var, val,                          \
             minval_register(),                 \
             maxval_register(),                 \
             Register, msg)

#define load_instruction_displacement(var, val, msg)    \
  load_value(var, val,                                  \
             minval_instruction_displacement(),         \
             maxval_instruction_displacement(),         \
             InstructionDisplacement, msg)

#define load_constant_displacement(var, val, msg)       \
  load_value(var, val,                                  \
             minval_constant_displacement(),            \
             maxval_constant_displacement(),            \
             ConstantDisplacement, msg)

#define load_subscript(var, val, msg)           \
  load_value(var, val,                          \
             minval_subscript(),                \
             maxval_subscript(),                \
             Subscript, msg)



/*
 * OBC file header (magic + fingerprint).
 * The second byte is shared with SBC file.
 */
union obc_file_header {
  struct {
    unsigned char magic;
    unsigned char fingerprint;
  } s;
  unsigned short x;
};
union obc_file_header obc_file_header = {
  .s = {
    .magic = OBC_FILE_MAGIC,
    .fingerprint =
#include "specfile-fingerprint.h"
  }
};
#define FINGERPRINT_WILDCARD 0xff
#define OBC_FILE_HEADER_WILDCARD                        \
((union obc_file_header)                                \
 {.s = {.magic = OBC_FILE_MAGIC,                        \
         .fingerprint = FINGERPRINT_WILDCARD}})

/*
 * information of instructions
 */
InsnInfo insn_info_table[] = {
#include "instructions-table.h"
};

/*
 * number of instructions
 */
int numinsts = sizeof(insn_info_table) / sizeof(InsnInfo);

char *insn_nemonic(int opcode) {
  return insn_info_table[opcode].insn_name;
}

typedef struct {
  Opcode oc;
  int size;
  InsnOperandType type;
} ConstInfo;

typedef struct {
#ifdef DEBUG
  size_t n_consts;
#endif /* DEBUG */
  ConstInfo *const_info;
} CItable;

/*
 * instruction table
 */

#define LOADBUFLEN 1024

#ifdef USE_SBC
extern int insn_load_sbc(Context *, Instruction *, int, int, int, int, const char *);
#endif

#ifdef USE_OBC
extern void init_constant_info(CItable *citable, int nconsts, int i);
extern void add_constant_info(CItable *ci, Opcode oc, unsigned int index,
                              InsnOperandType type);
extern void const_load(Context *, int, JSValue *, CItable *, const char *);
extern int insn_load_obc(Context *, Instruction *, int, int, CItable *, int, const char *);
#endif

extern uint32_t decode_escape_char(char *);
extern int print_function_table(FunctionTable *, int);
extern void print_bytecode(Instruction *, int);

extern void set_function_table(FunctionTable *, int, Instruction *,
                               int, int, int, int, int);

FILE *file_pointer;
int ary_idx = 0;

#ifdef USE_OBC
inline int load_obc_file(unsigned char *buf, const char *obc, int n) {
  int i;
  if (sizeof(obc) < n) {
    printf("array not length\n\r");
    return -1;
  }
  for (i = 0; i < n; i++, ary_idx++) {
    buf[i] = obc[ary_idx];
  }
  return n;
}
#endif

#ifdef USE_SBC
/*
 * reads the next line from the input stream
 */
/*inline char *step_load_code(char *buf, int buflen) {
  return fgets(buf, buflen, file_pointer == NULL? stdin: file_pointer);
}*/
inline char *step_load_code(char *buf, const char *sbc) {
  strcpy(buf, &sbc[ary_idx++]);
  return buf;
}

#define DELIM " \n"
#define DELIM2 "\n"
#define first_token(b) strtok(b, DELIM)
#define next_token()   strtok(NULL, DELIM)
#define next_token2()  strtok(NULL, DELIM2)

inline int check_read_token(char *buf, const char *tok) {
  char *p;
  p = first_token(buf);
  if (strcmp(p, tok) != 0)
    LOG_EXIT("Error: %s is not defined", tok);
  return atoi(next_token());
}
#endif /* USE_SBC */

/*
 * codeloader
 */
int code_loader(Context *ctx, FunctionTable *ftable, int ftbase, const char *ary) {
  Instruction *insns;
  JSValue *consttop;
  int nfuncs, callentry, sendentry, nlocals, ninsns, nconsts;
  int i, j, ret;

#ifdef USE_SBC
  char buf[LOADBUFLEN];
#endif
#ifdef USE_OBC
  CItable citable;
  unsigned char b[2];
#endif

#ifdef USE_SBC
//#define next_buf_sbc() (step_load_code(buf, LOADBUFLEN) != NULL)
#define next_buf_sbc() (step_load_code(buf, ary) != NULL)
#define buf_to_int_sbc(s)   check_read_token(buf, s)
#endif

#ifdef USE_OBC
// #define next_buf_obc() (fread(b, sizeof(unsigned char), 2, file_pointer) > 0)
//#define next_buf_obc() (b[0] = ary[ary_idx++], b[1] = ary[ary_idx++], 2)
#define next_buf_obc() (load_obc_file(b, ary, 2))
#ifdef CPU_LITTLE_ENDIAN
#define buf_to_int_obc(s)   (b[0] * 256 + b[1])
#else
#define buf_to_int_obc(s)   (b[1] * 256 + b[0])
#endif
#endif

#if defined(USE_OBC) && defined(USE_SBC)

#define next_buf()                                                   \
  if ((obcsbc == FILE_OBC? next_buf_obc(): next_buf_sbc()) == 0) return 0
#define buf_to_int(s)                                                \
  (obcsbc == FILE_OBC? buf_to_int_obc(s): buf_to_int_sbc(s))

#else

#ifdef USE_OBC
#define next_buf()      if (next_buf_obc() == 0) return 0
#define buf_to_int(s)   buf_to_int_obc(s)
#endif

#ifdef USE_SBC
#define next_buf()      if (next_buf_sbc() == 0) return 0
#define buf_to_int(s)   buf_to_int_sbc(s)
#endif

#endif

  /*
   * check file header
   */
  {
    union obc_file_header hdr;
    next_buf();
#if defined(USE_SBC) && defined(USE_OBC)
    if (obcsbc == FILE_SBC) {
#endif /* defined(USE_SBC) && defined(USE_OBC) */
#ifdef USE_SBC
      int fingerprint = buf_to_int("fingerprint");
      if (fingerprint != obc_file_header.s.fingerprint &&
          fingerprint != FINGERPRINT_WILDCARD)
        LOG_EXIT("SBC file header mismatch. 0x%x is expected but saw 0x%x.\n",
                 obc_file_header.s.fingerprint, fingerprint);
#endif /* USE_SBC */
#if defined(USE_SBC) && defined(USE_OBC)
    }
    if (obcsbc == FILE_OBC) {
#endif /* defined(USE_SBC) && defined(USE_OBC) */
#ifdef USE_OBC
      hdr.s.magic = b[0];
      hdr.s.fingerprint = b[1];
      if (hdr.x != obc_file_header.x &&
          hdr.x != OBC_FILE_HEADER_WILDCARD.x)
        LOG_EXIT("OBC file header mismatch. 0x%x is expected but saw 0x%x.\n",
                 obc_file_header.s.fingerprint, hdr.s.fingerprint);
#endif /* USE_OBC */
#if defined(USE_SBC) && defined(USE_OBC)
    }
#endif /* defined(USE_SBC) && defined(USE_OBC) */
  }

  /*
   * checks the funclength and obtain the number of functions
   */
  next_buf();
  nfuncs = buf_to_int("funcLength");

  /*
   * reads each function
   */
  for (i = 0; i < nfuncs; i++) {
    /* callentry */
    next_buf();
    callentry = buf_to_int("callentry");

    /* sendentry */
    next_buf();
    sendentry = buf_to_int("sendentry");

    /* numberOfLocals */
    next_buf();
    nlocals = buf_to_int("numberOfLocals");

    /* numberOfInstructions */
    next_buf();
    ninsns = buf_to_int("numberOfInstructions");

    /* numberOfConstants */
    next_buf();
    nconsts = buf_to_int("numberOfConstants");

#if defined(USE_OBC) && defined(USE_SBC)
    if (obcsbc == FILE_OBC)
      init_constant_info(&citable, nconsts, i);
#else
#ifdef USE_OBC
    init_constant_info(&citable, nconsts, i);
#endif
#endif

    insns = ((Instruction *)
             malloc(sizeof(Instruction) * ninsns + sizeof(JSValue) * nconsts));
    if (insns == NULL) {
      printf("Out of memory : instruction\n");
      LOG_EXIT("Allocating instruction array failed.");
    }
    consttop = (JSValue *)(&insns[ninsns]);
    for (j = 0; j < nconsts; j++) consttop[j] = JS_UNDEFINED;

    /*
     * Registers various information into the function table.
     * It is necessary to do this here because gc might occur during
     * loading constants.
     */
    set_function_table(ftable, i + ftbase, insns,
                       callentry, sendentry, nlocals, ninsns, nconsts);
    
    /* loads instructions for each function */
    for (j = 0; j < ninsns; j++) {
#if defined(USE_OBC) && defined(USE_SBC)
      ret = (obcsbc == FILE_OBC?
             insn_load_obc(ctx, insns, ninsns, j, &citable, ftbase, ary):
             insn_load_sbc(ctx, insns, ninsns, nconsts, j, ftbase, ary));
#else
#ifdef USE_OBC
      ret = insn_load_obc(ctx, insns, ninsns, j, &citable, ftbase, ary);
#endif
#ifdef USE_SBC
      ret = insn_load_sbc(ctx, insns, ninsns, nconsts, j, ftbase, ary);
#endif
#endif
      if (ret == LOAD_FAIL)
        LOG_EXIT("Function #%d, instruction #%d: load failed", i, j);
    }

#if defined(USE_OBC) && defined(USE_SBC)
    if (obcsbc == FILE_OBC)
      const_load(ctx, nconsts, consttop, &citable, ary);
#else
#ifdef USE_OBC
    const_load(ctx, nconsts, consttop, &citable, ary);
#endif
#endif

#if defined(USE_OBC) && defined(USE_SBC)
    if (obcsbc == FILE_OBC)
      free(citable.const_info);
#else
#ifdef USE_OBC
    free(citable.const_info);
#endif
#endif
  }
#ifdef DEBUG
  if (ftable_flag == TRUE)
    print_function_table(ftable, i + ftbase);
#endif /* DEBUG */
  return nfuncs;

#undef next_buf
#undef buf_to_int
}

#ifdef USE_OBC
JSValue string_load(Context *ctx, int size, const char *obc_s) {
  char *str;
  JSValue v;
  int i;

  str = (char*) malloc(sizeof(char) * size);
  if (str == NULL) 
    printf("Out of memory : string literal\n");
  /*if (fread(str, sizeof(char), size, file_pointer) < size)
    LOG_ERR("string literal too short.");*/
    for (i = 0; i < size; i++, ary_idx++) {
		  str[i] = obc_s[ary_idx];
	  }
  decode_escape_char(str);
  v = cstr_to_string(NULL, str);
  free(str);
  return v;
}

JSValue double_load(Context *ctx, const char *obc_d) {
  union {
    double d;
    unsigned char b[8];
  } u;
   int i;

  for (i = 0; i < 8; i++) {
	  u.b[i] = obc_d[ary_idx++];
  }
  
  //fread(&u.b, sizeof(unsigned char), 8, file_pointer);

#ifdef CPU_LITTLE_ENDIAN
  {
    int i;
    for (i = 0; i < 4; i++) {
      unsigned char c;
      c = u.b[i]; u.b[i] = u.b[7 - i]; u.b[7 - i] = c;
    }
  }
#endif
  /* printf("double loaded, value = %lf\n", u.d); */
  return double_to_number(ctx, u.d);
}

void const_load(Context *ctx, int nconsts, JSValue *ctop, CItable *citable, const char *obc) {
  int i;
  unsigned char b[2];

//#define next_buf()      fread(b, sizeof(unsigned char), 2, file_pointer)
#define next_buf() (load_obc_file(b, obc, 2))
#define buf_to_int(s)   (b[0] * 256 + b[1])
  
  for (i = 0; i < nconsts; i++) {
    int size;
    JSValue v = JS_UNDEFINED;

    next_buf();
    citable->const_info[i].size = size = buf_to_int();
    if (size > 0) {
      Opcode oc = citable->const_info[i].oc;
      switch (insn_info_table[oc].otype) {
      case BIGPRIMITIVE:
        switch (oc) {
        case ERROR:
        case STRING:
          v = string_load(ctx, size, obc);
          break;
        case NUMBER:
          v = double_load(ctx, obc);
          break;
#ifdef USE_REGEXP
        case REGEXP:
          LOG_ERR("sorry, loading regexp is not implemented yet.");
          break;
#endif /* USE_REGEXP */
        default:
          LOG_ERR("Error: unexpected instruction in loading constants");
          v = JS_UNDEFINED;
          break;
        }
        break;
      case THREEOP:
        {
          InsnOperandType type = citable->const_info[i].type;
          switch (type) {
          case STR:
            v = string_load(ctx, size, obc);
            break;
          case NUM:
            v = double_load(ctx, obc);
            break;
          default:
            LOG_ERR("Error: unexpected operand type in loading constants");
            break;
          }
          break;
        }
      default:
        LOG_ERR("Error: unexpected operand type in loading constants");
        break;
      }
      ctop[i] = v;
    }
  }
#undef next_buf
#undef buf_to_int
}
#endif

/*
 * initializes the code loader
 */
void init_code_loader(FILE *fp) {
  file_pointer = fp;
}

/*
 * finalizes the code loader
 */
void end_code_loader() {
  if (repl_flag == TRUE)
    return;
  if (file_pointer != NULL)
    fclose(file_pointer);
}

#ifdef USE_SBC
#define NOT_OPCODE ((Opcode)(-1))

Opcode find_insn(char* s) {
  int i;
  for (i = 0; i < numinsts; i++)
    if (strcmp(insn_info_table[i].insn_name, s) == 0)
      return i;
  /* not found in the instruction table */
  return NOT_OPCODE;
}
#endif /* USE_SBC */

#ifdef USE_OBC
Bytecode convertToBc(unsigned char buf[sizeof(Bytecode)]) {
  int i;
  Bytecode ret;

  ret = 0;
  for (i = 0; i < (sizeof(Bytecode)); i++)
    ret = ret * 256 + buf[i];
  return ret;
} /* USE_OBC */

#define OPTYPE_ERROR ((InsnOperandType)(-1))

InsnOperandType si_optype(Opcode oc, int i) {
  switch (i) {
  case 0:
    return insn_info_table[oc].op0;
  case 1:
    return insn_info_table[oc].op1;
  case 2:
    return insn_info_table[oc].op2;
  default:
    return OPTYPE_ERROR;
  }
}
#endif

#ifdef USE_SBC
#define load_op(op_type, op)                                    \
  do {                                                          \
    op = 0;                                                     \
    switch (op_type) {                                          \
    case NONE:                                                  \
      break;                                                    \
    case LIT:                                                   \
      { op = atoi(next_token()); }                              \
      break;                                                    \
    case STR:                                                   \
      {                                                         \
        char *src;                                              \
        int index;                                              \
        src = next_token();                                     \
        index = load_string_sbc(src, ctop, ninsns, nconsts);    \
        op = calc_displacement(ninsns, pc, index);              \
      }                                                         \
      break;                                                    \
    case NUM:                                                   \
      {                                                         \
        char *src;                                              \
        int index;                                              \
        src = next_token();                                     \
        index = load_number_sbc(src, ctop, ninsns, nconsts);    \
        op = calc_displacement(ninsns, pc, index);              \
      }                                                         \
      break;                                                    \
    case SPEC:                                                  \
      { op = specstr_to_jsvalue(next_token()); }                \
      break;                                                    \
    default:                                                    \
      return LOAD_FAIL;                                         \
    }                                                           \
  } while(0)
#endif /* USE_SBC */

/*
 * loads an instruction
 */
#ifdef USE_SBC

/*
 * Reads the constant at the operand field of an instruction in a sbc file
 * and stores the constant into *d (for double) or *str (for char *)..
 * Format of constant is ``#<n>:constant'', where <n> is the
 * zero-origined index within the constant table.
 * Return value is the index (<n>) or -1 (in an error case).
 */
int load_const_sbc(char *start, int nconsts, double *d, char **str) {
  char *s, *p;
  int index;

  s = start;
  if (s == NULL || *s++ != '#') {
    LOG_ERR("%s: constant format error", start);
    return -1;
  }
  for (p = s; *p != '=' && *p != '\0'; p++);
  if (*p == '\0') {
    LOG_ERR("%s: constant format error", start);
    return -1;
  }
  *p++ = '\0';
  index = atoi(s);
  if (index < 0 || nconsts <= index) {
    LOG_ERR("%s: invalid index of the constant", start);
    return -1;
  }
  if (d != NULL) {
    *d = atof(p);
    return index;
  } else if (str != NULL) {
    *str = p;
    return index;
  } else {
    LOG_ERR("invalid argument to read_const_sbc");
    return -1;
  }
}

int load_number_sbc(char *src, JSValue *ctop, int ninsns, int nconsts) {
  double d;
  int index;
  JSValue v0;

  index = load_const_sbc(src, nconsts, &d, NULL);
  if (index < 0) return -1;
  v0 = ctop[index];
  if (v0 == JS_UNDEFINED)
    ctop[index] = double_to_number(NULL, d);  /* TODO: context */
  else {
    if (!is_number(v0)) {
      LOG_ERR("inconsistent constants at index %d", index);
      return -1;
    }
    if (d != number_to_double(v0)) {
      LOG_ERR("inconsistent number constants at index %d", index);
      return -1;
    }
  }
  return index;
}

int load_string_sbc(char *src, JSValue *ctop, int ninsns, int nconsts) {
  char *str;
  int index;
  JSValue v0, v1;

  index = load_const_sbc(src, nconsts, NULL, &str);
  if (index < 0) return -1;
  decode_escape_char(str);
  v0 = ctop[index];
  v1 = cstr_to_string(NULL, str);
  if (v0 == JS_UNDEFINED)
    ctop[index] = v1;
  else if (v0 != v1) {
    LOG_ERR("inconsistent string constants at index %d", index);
    return -1;
  } /* else, v0 == v1.  do nothing */
  return index;
}

#ifdef USE_REGEXP
int load_regexp_sbc(Context *ctx, char *src, JSValue *ctop,
                    int ninsns, int nconsts, int flag) {
  char *str;
  int index;
  JSValue v0, v1;

  index = load_const_sbc(src, nconsts, NULL, &str);
  if (index < 0) return -1;
  decode_escape_char(str);
  v0 = ctop[index];
  if (v0 == JS_UNDEFINED)
    ctop[index] = new_regexp(ctx, str, flag);
  /*
   * else, it is necessary to check the consistency of v0 and str
   * but this check in not implemented yet.
   */
  return index;
}
#endif /* USE_REGEXP */

int insn_load_sbc(Context *ctx, Instruction *insns, int ninsns,
                  int nconsts, int pc, int ftbase, const char *sbc) {
  char buf[LOADBUFLEN];
  char *tokp;
  Opcode oc;
  JSValue *ctop;

  ctop = (JSValue *)(&insns[ninsns]);
  step_load_code(buf, sbc);
  tokp = first_token(buf);
#ifdef ALLOC_SITE_CACHE
  init_alloc_site(&insns[pc].alloc_site);
#endif /* ALLOC_SITE_CACHE */
#ifdef INLINE_CACHE
  init_inline_cache(&insns[pc].inl_cache);
#endif /* INLINE_CACHE */

#ifdef PROFILE
  {
    int nlen = strlen(tokp);
    /* tests whether the instruction name ends with "_log" */
    if (nlen > 4 && tokp[nlen - 4] == '_' && tokp[nlen - 3] == 'l' && 
        tokp[nlen - 2] == 'o' && tokp[nlen - 1] == 'g' ) {
      tokp[nlen - 4] = '\0';
      insns[pc].logflag = TRUE;
    } else
      insns[pc].logflag = forcelog_flag;
  }
#endif /* PROFILE */

  oc = find_insn(tokp);
  if (oc == NOT_OPCODE) {
    /* instruction is not found in the instruction info table */
#ifdef PROFILE
    LOG_ERR("Illegal instruction: %s%s", tokp,
            (insns[pc].logflag == TRUE? "_log": ""));
#else
    LOG_ERR("Illegal instruction: %s", tokp);
#endif /* PROFILE */
    insns[pc].code = (Bytecode)(-1);
    return LOAD_FAIL;
  }
  switch (insn_info_table[oc].otype) {
  case SMALLPRIMITIVE:
    {
      Register dst;
      load_register(dst, atoi(next_token()), "SMALLPRIMITIVE DST");
      switch (oc) {
      case FIXNUM:
        {
          SmallPrimitive imm;
          load_small_primitive(imm, atoi(next_token()), "FIXNUM IMM");
          insns[pc].code = makecode_fixnum(dst, imm);
        }
        break;
      case SPECCONST:
        insns[pc].code =
          makecode_specconst(dst, specstr_to_jsvalue(next_token()));
        break;
      default:
        return LOAD_FAIL;
      }
      return LOAD_OK;
    }

  case BIGPRIMITIVE:
    {
      Register dst;
      char *src;
      int index;
      ConstantDisplacement disp;

      dst = atoi(next_token());   /* destination register */
      switch (oc) {
      case NUMBER:
        {
          src = next_token();
          index = load_number_sbc(src, ctop, ninsns, nconsts);
          if (index < 0) return LOAD_FAIL;
          load_constant_displacement(disp,
                                     calc_displacement(ninsns, pc, index),
                                     "NUMBER DISP");
          insns[pc].code = makecode_number(dst, disp);
        }
        break;
      case STRING:
      case ERROR:
        {
          src = next_token();
          index = load_string_sbc(src, ctop, ninsns, nconsts);
          if (index < 0) return LOAD_FAIL;
          load_constant_displacement(disp,
                                     calc_displacement(ninsns, pc, index),
                                     "STRING/ERROR DISP");
          insns[pc].code = (oc == STRING ?
                            makecode_string(dst, disp):
                            makecode_error(dst, disp));
        }
        break;
#ifdef USE_REGEXP
      case REGEXP:
        {
          int flag = atoi(next_token());
          src = next_token();
          index = load_regexp_sbc(ctx, src, ctop, ninsns, nconsts, flag);
          if (index < 0) return LOAD_FAIL;
          load_constant_displacement(disp,
                                     calc_displacement(ninsns, pc, index),
                                     "REGEXP DISP");
          insns[pc].code = makecode_regexp(dst, disp);
        }
        break;
#endif /* USE_REGEXP */
      default:
        return LOAD_FAIL;
      }
      return LOAD_OK;
    }

  case THREEOP:
    {
      Register op0, op1, op2;
      load_op(insn_info_table[oc].op0, op0);
      load_op(insn_info_table[oc].op1, op1);
      load_op(insn_info_table[oc].op2, op2);
      insns[pc].code = makecode_three_operands(oc, op0, op1, op2);
      return LOAD_OK;
    }

  case TWOOP:
    {
      Register op0, op1;
      load_constant_displacement(op0, atoi(next_token()), "TWO OP0");
      load_constant_displacement(op1, atoi(next_token()), "TWO OP1");
      insns[pc].code = makecode_two_operands(oc, op0, op1);
      return LOAD_OK;
    }

  case ONEOP:
    {
      Register op;
      load_constant_displacement(op, atoi(next_token()), "ONE OP");
      insns[pc].code = makecode_one_operand(oc, op);
      return LOAD_OK;
    }

  case ZEROOP:
    {
      insns[pc].code = makecode_no_operand(oc);
      return LOAD_OK;
    }

  case UNCONDJUMP:
    {
      InstructionDisplacement disp;
      load_instruction_displacement(disp, atoi(next_token()),
                                    "UNCONDJUMP DISP");
      insns[pc].code = makecode_jump(oc, disp);
      return LOAD_OK;
    }

  case CONDJUMP:
    {
      InstructionDisplacement disp;
      Register src;
      load_register(src, atoi(next_token()), "CONDJUMP SRC");
      load_instruction_displacement(disp, atoi(next_token()), "CONDJUMP DISP");
      insns[pc].code = makecode_condjump(oc, src, disp);
      return LOAD_OK;
    }

  case GETVAR:
    {
      Subscript link, offset;
      Register reg;
      load_subscript(link, atoi(next_token()), "GETVAR LINK");
      load_subscript(offset, atoi(next_token()), "GETVAR OFFSET");
      load_register(reg, atoi(next_token()), "GETVAR REG");
      insns[pc].code = makecode_getvar(oc, link, offset, reg);
      return LOAD_OK;
    }

  case SETVAR:
    {
      Subscript link, offset;
      Register reg;
      load_subscript(link, atoi(next_token()), "SETVAR LINK");
      load_subscript(offset, atoi(next_token()), "SETVAR OFFSET");
      load_register(reg, atoi(next_token()), "SETVAR REG");
      insns[pc].code = makecode_setvar(oc, link, offset, reg);
      return LOAD_OK;
    }

  case MAKECLOSUREOP:
    {
      Register dst;
      Subscript index;
      load_register(dst, atoi(next_token()), "MAKECLOSUREOP DST");
      load_subscript(index, atoi(next_token()), "MAKECLOSUREOP INDEX");
      insns[pc].code = makecode_makeclosure(oc, dst, index + ftbase);
      return LOAD_OK;
    }

  case CALLOP:
    {
      /* TODO: argc is not a Register */
      Register closure, argc;
      load_register(closure, atoi(next_token()), "CALLOP CLOSURE");
      load_register(argc, atoi(next_token()), "CALLOP ARGC");
      insns[pc].code = makecode_call(oc, closure, argc);
      return LOAD_OK;
    }

  default:
    {
      LOG_EXIT("Illegal instruction: %s", tokp);
      return LOAD_FAIL;
    }
  }
}
#endif /* USE_SBC */

#ifdef USE_OBC
int insn_load_obc(Context *ctx, Instruction *insns, int ninsns, int pc,
                  CItable *citable, int ftbase, const char *obc) {
  unsigned char buf[sizeof(Bytecode)];
  Opcode oc;
  Bytecode bc;
  int i;

  /*if (fread(buf, sizeof(unsigned char), sizeof(Bytecode), file_pointer)
      != sizeof(Bytecode))
    LOG_ERR("Error: cannot read %dth bytecode", pc);*/
    for (i = 0; i < (sizeof(Bytecode)); i++, ary_idx++) {
		  buf[i] = obc[ary_idx];
	  }
  bc = convertToBc(buf);
  oc = get_opcode(bc);
#ifdef ALLOC_SITE_CACHE
  init_alloc_site(&insns[pc].alloc_site);
#endif /* ALLOC_SITE_CACHE */
#ifdef INLINE_CACHE
  init_inline_cache(&insns[pc].inl_cache);
#endif /* INLINE_CACHE */

  switch (insn_info_table[oc].otype) {
  case BIGPRIMITIVE:
    switch (oc) {
    case ERROR:
    case STRING:
    case NUMBER:
#ifdef USE_REGEXP
    case REGEXP:
#endif /* USE_REGEXP */
      {
        BigPrimitiveIndex id = get_big_subscr(bc);
        ConstantDisplacement disp = calc_displacement(ninsns, pc, id);
        add_constant_info(citable, oc, id, NONE);
        insns[pc].code = update_displacement(bc, disp);
      }
      return LOAD_OK;
    default:
      return LOAD_FAIL;
    }
    break;

  case MAKECLOSUREOP:
    if (ftbase > 0) {
      Subscript index = get_second_operand_subscr(bc) + ftbase;
      bc = makecode_makeclosure(oc, get_first_operand_reg(bc), index);
    }
    insns[pc].code = bc;
    return LOAD_OK;

  case THREEOP:
    for (i = 0; i < 3; i++) {
      InsnOperandType type = si_optype(oc, i);
      if (type == OPTYPE_ERROR) return LOAD_FAIL;
      if (type == STR || type == NUM ) {
        BigPrimitiveIndex index =
          ((i == 0) ? get_first_operand_subscr(bc) :
           (i == 1) ? get_second_operand_subscr(bc) :
           get_third_operand_subscr(bc));
        ConstantDisplacement disp = calc_displacement(ninsns, pc, index);
        add_constant_info(citable, oc, index, type);
        bc = ((i == 0)? update_first_operand_disp(bc, disp):
              (i == 1)? update_second_operand_disp(bc, disp):
              update_third_operand_disp(bc, disp));
      }
    }
    /* fall through */
  default:
    insns[pc].code = bc;
    return LOAD_OK;
  }
}
#endif

/*
 * converts a special JS string (for a constant) into a JSValue
 */
JSValue specstr_to_jsvalue(const char *str) {
  if (strcmp(str, "true") == 0)
    return JS_TRUE;
  else if (strcmp(str, "false") == 0)
    return JS_FALSE;
  else if (strcmp(str, "null") == 0)
    return JS_NULL;
  else if (strcmp(str, "undefined") == 0)
    return JS_UNDEFINED;
  else
    /* undefined name */
    LOG_EXIT("%s is an undefined symbol.", str);
}

char *jsvalue_to_specstr(JSValue v) {
  char *s;
  if (v == JS_TRUE) s = "true";
  else if (v == JS_FALSE) s = "false";
  else if (v == JS_NULL) s = "null";
  else if (v == JS_UNDEFINED) s = "undefined";
  else s = "unknown_specstr";
  return s;
}

#ifdef USE_OBC
void init_constant_info(CItable *citable, int nconsts, int i) {
  ConstInfo* p;
#ifdef DEBUG
  citable->n_consts = nconsts;
#endif /* DEBUG */
  p = (ConstInfo*)malloc(sizeof(ConstInfo) * nconsts);
  if (p == NULL) {
    printf("Out of memory : init_constant_info\n");
    LOG_EXIT("%dth func: cannot malloc constant_info", i);
  }
  citable->const_info = p;
}

void add_constant_info(CItable *ci, Opcode c, unsigned int index,
                       InsnOperandType t) {
#ifdef DEBUG
  if (index >= ci->n_consts)
    LOG_ERR("Error: index %d is out of range of constant info table", index);
#endif /* DEBUG */
  ci->const_info[index].oc = c;
  ci->const_info[index].type = t;
}
#endif

void set_function_table(FunctionTable *ftable, int index, Instruction *insns,
                        int callentry, int sendentry, int nlocals,
                        int ninsns, int nconsts) {
  if (index >= FUNCTION_TABLE_LIMIT)
    LOG_EXIT("too many functions (consider increasing FUNCTION_TABLE_LIMIT)");

  ftable[index].ilabel_created = false;
  ftable[index].insns = insns;
  ftable[index].call_entry = callentry;
  ftable[index].send_entry = sendentry;
  ftable[index].n_locals = nlocals;
  ftable[index].body_size =
    ninsns * (sizeof(Instruction) / sizeof(JSValue)) + nconsts;
  ftable[index].n_insns = ninsns;
  ftable[index].n_constants = nconsts;
}

#ifdef DEBUG
int print_function_table(FunctionTable *ftable, int nfuncs) {
  int i, j;
  JSValue *lit;

  printf("number of functions = %d\n", nfuncs);
  for (i = 0; i < nfuncs; i++) {
    printf("function #%d\n", i);
    printf("call_entry: %d\n", ftable[i].call_entry);
    printf("send_entry: %d\n", ftable[i].send_entry);
    printf("n_locals: %d\n" ,ftable[i].n_locals);
    printf("n_insns: %d\n", ftable[i].n_insns);
    printf("n_constants: %d\n", ftable[i].n_constants);
    printf("body_size: %d\n", ftable[i].body_size);
    for (j = 0; j < ftable[i].n_insns; j++) {
      printf("%03d: %"PRIByteCode" --- ", j, ftable[i].insns[j].code);
      print_bytecode(ftable[i].insns, j);
    }
    lit = (JSValue *)&(ftable[i].insns[ftable[i].n_insns]);
    for (j = 0; j < ftable[i].n_constants; j++) {
      JSValue o;
      o = lit[j];
      printf("%03d: %016"PRIJSValue" --- ", j, o);
      if (is_flonum(o))
        printf("FLONUM %lf\n", flonum_value(o));
      else if (is_string(o))
        printf("STRING \"%s\"\n", string_value(o));
#ifdef USE_REGEXP
      else if (is_regexp(o))
        printf("REGEXP \"%s\"\n", regexp_pattern(o));
#endif /* USE_REGEXP */
      else
        printf("Unexpected JSValue\n");
    }
  }
  return 0;
}

/*
 * prints a bytecode instruction
 */
void print_constant(Instruction *insns, int pc, ConstantDisplacement disp) {
  JSValue o;
  o = get_literal((&insns[pc]), disp);
  if (is_flonum(o))
    printf(" %f", flonum_value(o));
  else if (is_string(o))
    printf(" \"%s\"", string_value(o));
#ifdef USE_REGEXP
  else if (is_regexp(o))
    printf(" %d:\"%s\"", regexp_flag(o), regexp_pattern(o));
#endif /* USE_REGEXP */
  else
    printf(" ???");
}

void print_bytecode(Instruction *insns, int pc) {
  Bytecode code;
  Opcode oc;
  OperandType t;

  code = insns[pc].code;
  oc = get_opcode(code);
  t = insn_info_table[oc].otype;
  printf("%" PRIByteCode " ", code);
#ifdef PROFILE
  printf("%s%s", insn_info_table[oc].insn_name,
         insns[pc].logflag == TRUE? "_log": "");
#else
  printf("%s", insn_info_table[oc].insn_name);
#endif
  switch (t) {
  case SMALLPRIMITIVE:
    {
      SmallPrimitive imm;
      printf(" %d", get_first_operand_reg(code));
      switch (oc) {
      case FIXNUM:
        imm = get_small_immediate(code);
        printf(" %d", imm);
        break;
      case SPECCONST:
        imm = get_small_immediate(code);
        printf(" %s", jsvalue_to_specstr(imm));
        break;
      default:
        printf(" ???");
        break;
      }
    }
    break;
  case BIGPRIMITIVE:
    {
      printf(" %d", get_first_operand_reg(code));
      print_constant(insns, pc, get_big_constant_disp(code));
    }
    break;
  case THREEOP:
    {
      InsnOperandType type;
      int i;
      for (i = 0; i < 3; i++) {
        type = si_optype(oc, i);
        if (type == STR || type == NUM) {
          ConstantDisplacement disp =
            ((i == 0)? get_first_operand_constant_disp(code):
             (i == 1)? get_second_operand_constant_disp(code):
             get_third_operand_constant_disp(code));
          print_constant(insns, pc, disp);
        } else if (type == SPEC) {
          int k = ((i == 0)? get_first_operand_int(code):
                   (i == 1)? get_second_operand_int(code):
                   get_third_operand_int(code));
          SmallPrimitive imm = get_small_immediate(k);
          printf(" %s", jsvalue_to_specstr(imm));
        } else {   /* LIT NONE */
          Register r;
          r = ((i == 0)? get_first_operand_reg(code):
               (i == 1)? get_second_operand_reg(code):
               get_third_operand_reg(code));
          printf(" %d", r);
        }
      }
    }
    break;
  case TWOOP:
    {
      Register dst, r1;
      dst = get_first_operand_reg(code);
      r1 = get_second_operand_reg(code);
      printf(" %d %d", dst, r1);
    }
    break;
  case ONEOP:
    {
      Register dst;
      dst = get_first_operand_reg(code);
      printf(" %d", dst);
    }
    break;
  case ZEROOP:
    break;
  case UNCONDJUMP:
  case TRYOP:
    {
      InstructionDisplacement disp = get_operand_instruction_disp(code);
      printf(" %d", pc + disp);
    }
    break;
  case CONDJUMP:          
    {
      Register r = get_first_operand_reg(code);
      InstructionDisplacement disp = get_operand_instruction_disp(code);
      printf(" %d %d", r, pc + disp);
    }
    break;
  case GETVAR:
    {
      Register dst;
      Subscript link, ss;
      link = get_first_operand_subscr(code);
      ss = get_second_operand_subscr(code);
      dst = get_third_operand_reg(code);
      printf(" %d %d %d", link, ss, dst);
    }
    break;
  case SETVAR:
    {
      Register src;
      Subscript link, ss;
      link = get_first_operand_subscr(code);
      ss = get_second_operand_subscr(code);
      src = get_third_operand_reg(code);
      printf(" %d %d %d", link, ss, src);
    }
    break;
  case MAKECLOSUREOP:
    {
      Register dst;
      Subscript ss;
      dst = get_first_operand_reg(code);
      ss = get_second_operand_subscr(code);
      printf(" %d %d", dst, ss);
    }
    break;
  case CALLOP:
    {
      Register f;
      int na;
      f = get_first_operand_reg(code);
      na = get_second_operand_int(code);
      printf(" %d %d", f, na);
    }
    break;
  case UNKNOWNOP:
    break;
  }
  putchar('\n');
}
#endif /* DEBUG */

uint32_t decode_escape_char(char *str) {
  char *src, *dst;
  int dq;
  char c;

  src = dst = str;
  dq = 0;
  if ((c = *src++) == '\"') {
    dq = 1;
    c = *src++;
  }
  while (1) {
    if (dq == 1 && c == '\"') break;
    if (dq == 0 && c == '\0') break;
    if (c != '\\') {
      *dst++ = c;
      c = *src++;
      continue;
    }
    switch (c = *src++) {
    case '0': *dst++ = '\0'; break;
    case 'a': *dst++ = '\a'; break;
    case 'b': *dst++ = '\b'; break;
    case 'f': *dst++ = '\f'; break;
    case 'n': *dst++ = '\n'; break;
    case 'r': *dst++ = '\r'; break;
    case 't': *dst++ = '\t'; break;
    case 'v': *dst++ = '\v'; break;
    case 's': *dst++ = ' '; break;
    case '\\': *dst++ = '\\'; break;
    case '\'': *dst++ = '\''; break;
    case '\"': *dst++ = '\"'; break;
    case 'x':
      {
        int k = 0, i;
        for (i = 0; i <= 1; i++) {
          c = *src++;
          if (c == ' ') c = '0';
          k <<= 4;
          if ('0' <= c && c <= '9') k += c - '0';
          else if ('a' <= c && c <= 'f') k += c + 10 - 'a';
          else if ('A' <= c && c <= 'F') k += c + 10 - 'A';
        }
        *dst++ = (char)k;
      }
      break;
    default: *dst++ = c; break;
    }
    c = *src++;
  }
  *dst = '\0';
  return (uint32_t)(dst - str);
}

/* Local Variables:      */
/* mode: c               */
/* c-basic-offset: 2     */
/* indent-tabs-mode: nil */
/* End:                  */
