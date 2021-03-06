#define dst regbase[r0]

DEFLABEL(HEAD):
INSN_COUNT2(add,v1,v2);Ladd0:
TLadd_string_any:
TLadd_fixnum_any:
TLadd_boolean_object_any:
TLadd_number_object_any:
TLadd_flonum_any:
TLadd_function_any:
TLadd_special_any:
TLadd_regexp_any:
TLadd_string_object_any:
TLadd_simple_object_any:
TLadd_any_any:
TLadd_iterator_any:
TLadd_builtin_any:
TLadd_array_any:
switch((unsigned int) get_ptag(v2).v){ // vmgen.newsynth.DecisionDiagram$PTNode@550(4)
case TV_FIXNUM:
default:
Ladd1:
TLadd_any_fixnum:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@447(4)
case TV_GENERIC:
Ladd2:switch((unsigned int) get_htag(v1).v){ // vmgen.newsynth.DecisionDiagram$HTNode@33(2)
case HTAGV_SIMPLE_OBJECT:
case 5:
case 4:
case 3:
case 2:
case 1:
case 0:
case HTAGV_ARRAY:
case HTAGV_FUNCTION:
case HTAGV_BUILTIN:
case HTAGV_REGEXP:
case HTAGV_BOXED_STRING:
case HTAGV_BOXED_NUMBER:
case HTAGV_BOXED_BOOLEAN:
default:
Ladd3:
TLadd_builtin_string:
TLadd_string_object_string:
TLadd_function_flonum:
TLadd_function_fixnum:
TLadd_boolean_object_flonum:
TLadd_simple_object_string:
TLadd_regexp_special:
TLadd_string_object_flonum:
TLadd_builtin_fixnum:
TLadd_array_special:
TLadd_regexp_string:
TLadd_simple_object_flonum:
TLadd_number_object_special:
TLadd_number_object_flonum:
TLadd_regexp_flonum:
TLadd_simple_object_special:
TLadd_function_special:
TLadd_array_flonum:
TLadd_builtin_flonum:
TLadd_boolean_object_special:
TLadd_array_fixnum:
TLadd_string_object_special:
TLadd_number_object_string:
TLadd_builtin_special:
TLadd_array_string:
TLadd_boolean_object_string:
TLadd_regexp_fixnum:
TLadd_boolean_object_fixnum:
TLadd_number_object_fixnum:
TLadd_function_string:
TLadd_simple_object_fixnum:
TLadd_string_object_fixnum:
{ // normal_string_object normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@df

  v1 = object_to_string(context, v1);
  goto USELABEL(HEAD);
}
break;
case HTAGV_ITERATOR:
Ladd4:
TLadd_string_iterator:
TLadd_boolean_object_iterator:
TLadd_iterator_function:
TLadd_iterator_simple_object:
TLadd_regexp_iterator:
TLadd_flonum_iterator:
TLadd_iterator_flonum:
TLadd_special_special:
TLadd_iterator_number_object:
TLadd_function_iterator:
TLadd_flonum_special:
TLadd_iterator_array:
TLadd_fixnum_special:
TLadd_special_flonum:
TLadd_iterator_fixnum:
TLadd_builtin_iterator:
TLadd_simple_object_iterator:
TLadd_iterator_string_object:
TLadd_iterator_iterator:
TLadd_iterator_special:
TLadd_iterator_string:
TLadd_number_object_iterator:
TLadd_iterator_boolean_object:
TLadd_iterator_builtin:
TLadd_flonum_flonum:
TLadd_fixnum_iterator:
TLadd_special_iterator:
TLadd_flonum_fixnum:
TLadd_string_object_iterator:
TLadd_fixnum_flonum:
TLadd_array_iterator:
TLadd_iterator_regexp:
TLadd_special_fixnum:
{ // normal_function normal_iterator vmgen.newsynth.DecisionDiagram$Leaf@285

  double x1 = to_double(context, v1);
  double x2 = to_double(context, v2);
  dst = double_to_number(context, x1 + x2);
}
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@33
break;
case TV_FLONUM:
case TV_SPECIAL:
goto Ladd4;
break;
case TV_FIXNUM:
default:
Ladd5:
TLadd_fixnum_fixnum:
{ // normal_fixnum normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@92e

  cint s = fixnum_to_cint(v1) + fixnum_to_cint(v2);
  dst = cint_to_number(context, s);
}
break;
case TV_STRING:
case 3:
case 2:
case 1:
Ladd6:
TLadd_string_fixnum:
TLadd_string_special:
TLadd_string_flonum:
{ // normal_string normal_special vmgen.newsynth.DecisionDiagram$Leaf@a53

  v2 = to_string(context, v2);
  goto USELABEL(STRSTR);
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@447
break;
case TV_FLONUM:
case TV_SPECIAL:
Ladd7:
TLadd_any_special:
TLadd_any_flonum:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@568(3)
case TV_GENERIC:
goto Ladd2;
break;
case TV_FLONUM:
case TV_SPECIAL:
case TV_FIXNUM:
default:
goto Ladd4;
break;
case TV_STRING:
case 3:
case 2:
case 1:
goto Ladd6;
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@568
break;
case TV_GENERIC:
Ladd8:
TLadd_any_simple_object:
TLadd_any_builtin:
TLadd_any_string_object:
TLadd_any_array:
TLadd_any_function:
TLadd_any_boolean_object:
TLadd_any_regexp:
TLadd_any_iterator:
TLadd_any_number_object:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@13fd(2)
case TV_GENERIC:
Ladd9:switch((unsigned int) get_htag(v1).v){ // vmgen.newsynth.DecisionDiagram$HTNode@685(2)
case HTAGV_ITERATOR:
goto Ladd4;
break;
case HTAGV_SIMPLE_OBJECT:
case 5:
case 4:
case 3:
case 2:
case 1:
case 0:
case HTAGV_ARRAY:
case HTAGV_FUNCTION:
case HTAGV_BUILTIN:
case HTAGV_REGEXP:
case HTAGV_BOXED_STRING:
case HTAGV_BOXED_NUMBER:
case HTAGV_BOXED_BOOLEAN:
default:
Ladd10:switch((unsigned int) get_htag(v2).v){ // vmgen.newsynth.DecisionDiagram$HTNode@ee7(2)
case HTAGV_SIMPLE_OBJECT:
case 5:
case 4:
case 3:
case 2:
case 1:
case 0:
case HTAGV_ARRAY:
case HTAGV_FUNCTION:
case HTAGV_BUILTIN:
case HTAGV_REGEXP:
case HTAGV_BOXED_STRING:
case HTAGV_BOXED_NUMBER:
case HTAGV_BOXED_BOOLEAN:
default:
Ladd11:
TLadd_builtin_function:
TLadd_function_boolean_object:
TLadd_function_regexp:
TLadd_number_object_builtin:
TLadd_function_number_object:
TLadd_string_object_array:
TLadd_array_number_object:
TLadd_simple_object_regexp:
TLadd_boolean_object_simple_object:
TLadd_string_object_function:
TLadd_regexp_array:
TLadd_regexp_simple_object:
TLadd_string_object_simple_object:
TLadd_number_object_array:
TLadd_simple_object_number_object:
TLadd_array_boolean_object:
TLadd_simple_object_string_object:
TLadd_number_object_function:
TLadd_number_object_string_object:
TLadd_array_regexp:
TLadd_simple_object_boolean_object:
TLadd_regexp_function:
TLadd_array_string_object:
TLadd_regexp_boolean_object:
TLadd_regexp_builtin:
TLadd_boolean_object_function:
TLadd_function_function:
TLadd_builtin_simple_object:
TLadd_boolean_object_string_object:
TLadd_function_array:
TLadd_regexp_string_object:
TLadd_boolean_object_array:
TLadd_boolean_object_regexp:
TLadd_number_object_regexp:
TLadd_simple_object_simple_object:
TLadd_string_object_number_object:
TLadd_function_builtin:
TLadd_simple_object_array:
TLadd_string_object_regexp:
TLadd_array_simple_object:
TLadd_array_function:
TLadd_regexp_number_object:
TLadd_number_object_number_object:
TLadd_boolean_object_builtin:
TLadd_function_string_object:
TLadd_builtin_number_object:
TLadd_simple_object_function:
TLadd_array_array:
TLadd_string_object_boolean_object:
TLadd_boolean_object_number_object:
TLadd_boolean_object_boolean_object:
TLadd_builtin_builtin:
TLadd_simple_object_builtin:
TLadd_array_builtin:
TLadd_string_object_string_object:
TLadd_builtin_array:
TLadd_number_object_boolean_object:
TLadd_string_object_builtin:
TLadd_number_object_simple_object:
TLadd_builtin_string_object:
TLadd_regexp_regexp:
TLadd_function_simple_object:
TLadd_builtin_boolean_object:
TLadd_builtin_regexp:
{ // normal_boolean_object normal_array vmgen.newsynth.DecisionDiagram$Leaf@97

  v1 = object_to_string(context, v1);
  v2 = object_to_string(context, v2);
  goto USELABEL(HEAD);
}
break;
case HTAGV_ITERATOR:
goto Ladd4;
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@ee7
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@685
break;
case TV_STRING:
case 3:
case 2:
case 1:
case TV_FLONUM:
case TV_SPECIAL:
case TV_FIXNUM:
default:
Ladd12:switch((unsigned int) get_htag(v2).v){ // vmgen.newsynth.DecisionDiagram$HTNode@1894(2)
case HTAGV_SIMPLE_OBJECT:
case 5:
case 4:
case 3:
case 2:
case 1:
case 0:
case HTAGV_ARRAY:
case HTAGV_FUNCTION:
case HTAGV_BUILTIN:
case HTAGV_REGEXP:
case HTAGV_BOXED_STRING:
case HTAGV_BOXED_NUMBER:
case HTAGV_BOXED_BOOLEAN:
default:
Ladd13:
TLadd_special_number_object:
TLadd_fixnum_boolean_object:
TLadd_fixnum_function:
TLadd_fixnum_string_object:
TLadd_special_simple_object:
TLadd_fixnum_array:
TLadd_special_array:
TLadd_string_builtin:
TLadd_string_boolean_object:
TLadd_string_number_object:
TLadd_fixnum_regexp:
TLadd_flonum_function:
TLadd_string_string_object:
TLadd_flonum_simple_object:
TLadd_fixnum_simple_object:
TLadd_fixnum_builtin:
TLadd_special_regexp:
TLadd_special_builtin:
TLadd_special_string_object:
TLadd_special_boolean_object:
TLadd_flonum_array:
TLadd_fixnum_number_object:
TLadd_flonum_string_object:
TLadd_special_function:
TLadd_string_array:
TLadd_flonum_regexp:
TLadd_flonum_number_object:
TLadd_flonum_boolean_object:
TLadd_string_simple_object:
TLadd_string_function:
TLadd_string_regexp:
TLadd_flonum_builtin:
{ // normal_string normal_regexp vmgen.newsynth.DecisionDiagram$Leaf@222

  v2 = object_to_string(context, v2);
  goto USELABEL(HEAD);
}
break;
case HTAGV_ITERATOR:
goto Ladd4;
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@1894
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@13fd
break;
case TV_STRING:
case 3:
case 2:
case 1:
Ladd14:
TLadd_any_string:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@173c(3)
case TV_GENERIC:
goto Ladd2;
break;
case TV_FLONUM:
case TV_SPECIAL:
case TV_FIXNUM:
default:
Ladd15:
TLadd_flonum_string:
TLadd_special_string:
TLadd_fixnum_string:
{ // normal_fixnum normal_string vmgen.newsynth.DecisionDiagram$Leaf@435

  v1 = to_string(context, v1);
  goto USELABEL(STRSTR);
}
break;
case TV_STRING:
case 3:
case 2:
case 1:
Ladd16:
TLadd_string_string:
{ // normal_string normal_string vmgen.newsynth.DecisionDiagram$Leaf@d41

DEFLABEL(STRSTR):
  dst = ejs_string_concat(context, v1, v2);
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@173c
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@550
#undef dst

