#define dst regbase[r0]
#define s v1

DEFLABEL(HEAD):
INSN_COUNT1(getglobal,s);Lgetglobal0:
TLgetglobal_any:
switch((unsigned int) get_ptag(s).v){ // vmgen.newsynth.DecisionDiagram$PTNode@550(2)
case TV_FLONUM:
case TV_SPECIAL:
case TV_FIXNUM:
default:
case TV_GENERIC:
Lgetglobal1:
TLgetglobal_builtin:
TLgetglobal_flonum:
TLgetglobal_array:
TLgetglobal_special:
TLgetglobal_string_object:
TLgetglobal_boolean_object:
TLgetglobal_simple_object:
TLgetglobal_iterator:
TLgetglobal_regexp:
TLgetglobal_fixnum:
TLgetglobal_number_object:
TLgetglobal_function:
{ // normal_special vmgen.newsynth.DecisionDiagram$Leaf@54

  LOG_EXIT("GETGLOBAL with non-stirng variable name\n");
/* Local Variables:      */
/* mode: c               */
/* c-basic-offset: 2     */
/* indent-tabs-mode: nil */
/* End:                  */
}
break;
case TV_STRING:
case 3:
case 2:
case 1:
Lgetglobal2:
TLgetglobal_string:
{ // normal_string vmgen.newsynth.DecisionDiagram$Leaf@1c49

/*
   getglobal dst reg
     dst : destination register
     reg : register that has a pointer to a string object
   $dst = property value for the string in the global object
 */
  JSValue ret;
#ifdef DEBUG_GETPROP_VALUE
  StringCell *str = jsv_to_normal_string(s);
  if (trace_flag)
    printf("getglobal: %s\n", str->value);
#endif /* DEBUG_GETPROP_VALUE */
  ret = get_prop(context->global, s);
  if (ret == JS_EMPTY)
    LOG_EXIT("GETGLOBAL: %s not found\n", string_to_cstr(s));
  dst = ret;
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@550
#undef dst
#undef s

