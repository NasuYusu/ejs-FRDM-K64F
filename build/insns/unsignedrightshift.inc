#define dst regbase[r0]

DEFLABEL(HEAD):
INSN_COUNT2(unsignedrightshift,v1,v2);Lunsignedrightshift0:
TLunsignedrightshift_any_any:
TLunsignedrightshift_builtin_any:
TLunsignedrightshift_flonum_any:
TLunsignedrightshift_string_any:
TLunsignedrightshift_special_any:
TLunsignedrightshift_number_object_any:
TLunsignedrightshift_simple_object_any:
TLunsignedrightshift_fixnum_any:
TLunsignedrightshift_array_any:
TLunsignedrightshift_function_any:
TLunsignedrightshift_boolean_object_any:
TLunsignedrightshift_string_object_any:
TLunsignedrightshift_iterator_any:
TLunsignedrightshift_regexp_any:
switch((unsigned int) get_ptag(v2).v){ // vmgen.newsynth.DecisionDiagram$PTNode@550(3)
case TV_STRING:
case 3:
case 2:
case 1:
case TV_SPECIAL:
case TV_GENERIC:
Lunsignedrightshift1:
TLunsignedrightshift_any_builtin:
TLunsignedrightshift_any_string_object:
TLunsignedrightshift_any_boolean_object:
TLunsignedrightshift_any_iterator:
TLunsignedrightshift_any_regexp:
TLunsignedrightshift_any_simple_object:
TLunsignedrightshift_any_function:
TLunsignedrightshift_any_string:
TLunsignedrightshift_any_array:
TLunsignedrightshift_any_number_object:
TLunsignedrightshift_any_special:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@5f3(2)
case TV_STRING:
case 3:
case 2:
case 1:
case TV_SPECIAL:
case TV_GENERIC:
Lunsignedrightshift2:
TLunsignedrightshift_string_function:
TLunsignedrightshift_number_object_string:
TLunsignedrightshift_iterator_special:
TLunsignedrightshift_regexp_special:
TLunsignedrightshift_function_string_object:
TLunsignedrightshift_regexp_regexp:
TLunsignedrightshift_regexp_builtin:
TLunsignedrightshift_regexp_boolean_object:
TLunsignedrightshift_builtin_string:
TLunsignedrightshift_simple_object_simple_object:
TLunsignedrightshift_iterator_string_object:
TLunsignedrightshift_builtin_special:
TLunsignedrightshift_iterator_string:
TLunsignedrightshift_array_special:
TLunsignedrightshift_simple_object_iterator:
TLunsignedrightshift_simple_object_regexp:
TLunsignedrightshift_boolean_object_string:
TLunsignedrightshift_string_object_boolean_object:
TLunsignedrightshift_function_regexp:
TLunsignedrightshift_builtin_array:
TLunsignedrightshift_array_builtin:
TLunsignedrightshift_simple_object_boolean_object:
TLunsignedrightshift_builtin_string_object:
TLunsignedrightshift_builtin_builtin:
TLunsignedrightshift_iterator_array:
TLunsignedrightshift_iterator_function:
TLunsignedrightshift_array_iterator:
TLunsignedrightshift_regexp_function:
TLunsignedrightshift_builtin_boolean_object:
TLunsignedrightshift_string_object_array:
TLunsignedrightshift_iterator_number_object:
TLunsignedrightshift_string_string_object:
TLunsignedrightshift_boolean_object_string_object:
TLunsignedrightshift_regexp_iterator:
TLunsignedrightshift_builtin_simple_object:
TLunsignedrightshift_special_array:
TLunsignedrightshift_regexp_string_object:
TLunsignedrightshift_special_simple_object:
TLunsignedrightshift_builtin_function:
TLunsignedrightshift_function_iterator:
TLunsignedrightshift_special_builtin:
TLunsignedrightshift_simple_object_string:
TLunsignedrightshift_number_object_iterator:
TLunsignedrightshift_function_function:
TLunsignedrightshift_array_array:
TLunsignedrightshift_string_simple_object:
TLunsignedrightshift_array_string:
TLunsignedrightshift_boolean_object_regexp:
TLunsignedrightshift_array_string_object:
TLunsignedrightshift_simple_object_string_object:
TLunsignedrightshift_special_string:
TLunsignedrightshift_string_string:
TLunsignedrightshift_special_function:
TLunsignedrightshift_builtin_number_object:
TLunsignedrightshift_simple_object_array:
TLunsignedrightshift_special_string_object:
TLunsignedrightshift_string_object_special:
TLunsignedrightshift_regexp_string:
TLunsignedrightshift_iterator_simple_object:
TLunsignedrightshift_array_simple_object:
TLunsignedrightshift_string_builtin:
TLunsignedrightshift_function_array:
TLunsignedrightshift_array_boolean_object:
TLunsignedrightshift_simple_object_builtin:
TLunsignedrightshift_number_object_regexp:
TLunsignedrightshift_string_object_builtin:
TLunsignedrightshift_simple_object_function:
TLunsignedrightshift_special_number_object:
TLunsignedrightshift_string_object_number_object:
TLunsignedrightshift_boolean_object_builtin:
TLunsignedrightshift_string_object_regexp:
TLunsignedrightshift_boolean_object_simple_object:
TLunsignedrightshift_number_object_builtin:
TLunsignedrightshift_function_simple_object:
TLunsignedrightshift_special_special:
TLunsignedrightshift_function_string:
TLunsignedrightshift_number_object_boolean_object:
TLunsignedrightshift_regexp_simple_object:
TLunsignedrightshift_string_number_object:
TLunsignedrightshift_boolean_object_iterator:
TLunsignedrightshift_string_object_function:
TLunsignedrightshift_iterator_iterator:
TLunsignedrightshift_string_special:
TLunsignedrightshift_string_array:
TLunsignedrightshift_iterator_boolean_object:
TLunsignedrightshift_special_iterator:
TLunsignedrightshift_builtin_iterator:
TLunsignedrightshift_number_object_array:
TLunsignedrightshift_string_object_string_object:
TLunsignedrightshift_number_object_string_object:
TLunsignedrightshift_special_boolean_object:
TLunsignedrightshift_boolean_object_function:
TLunsignedrightshift_simple_object_number_object:
TLunsignedrightshift_string_object_iterator:
TLunsignedrightshift_regexp_array:
TLunsignedrightshift_number_object_special:
TLunsignedrightshift_array_number_object:
TLunsignedrightshift_number_object_function:
TLunsignedrightshift_regexp_number_object:
TLunsignedrightshift_number_object_number_object:
TLunsignedrightshift_boolean_object_boolean_object:
TLunsignedrightshift_boolean_object_number_object:
TLunsignedrightshift_function_number_object:
TLunsignedrightshift_number_object_simple_object:
TLunsignedrightshift_string_object_string:
TLunsignedrightshift_function_special:
TLunsignedrightshift_iterator_regexp:
TLunsignedrightshift_boolean_object_special:
TLunsignedrightshift_string_boolean_object:
TLunsignedrightshift_iterator_builtin:
TLunsignedrightshift_string_regexp:
TLunsignedrightshift_function_builtin:
TLunsignedrightshift_special_regexp:
TLunsignedrightshift_array_function:
TLunsignedrightshift_string_iterator:
TLunsignedrightshift_array_regexp:
TLunsignedrightshift_boolean_object_array:
TLunsignedrightshift_string_object_simple_object:
TLunsignedrightshift_simple_object_special:
TLunsignedrightshift_builtin_regexp:
TLunsignedrightshift_function_boolean_object:
{ // normal_number_object normal_array vmgen.newsynth.DecisionDiagram$Leaf@16

  v1 = to_number(context, v1);
  v2 = to_number(context, v2);
  goto USELABEL(HEAD);
}
break;
case TV_FLONUM:
case TV_FIXNUM:
default:
Lunsignedrightshift3:
TLunsignedrightshift_fixnum_boolean_object:
TLunsignedrightshift_flonum_function:
TLunsignedrightshift_fixnum_string_object:
TLunsignedrightshift_fixnum_number_object:
TLunsignedrightshift_flonum_special:
TLunsignedrightshift_flonum_array:
TLunsignedrightshift_fixnum_string:
TLunsignedrightshift_flonum_string:
TLunsignedrightshift_flonum_iterator:
TLunsignedrightshift_flonum_string_object:
TLunsignedrightshift_flonum_simple_object:
TLunsignedrightshift_flonum_regexp:
TLunsignedrightshift_fixnum_array:
TLunsignedrightshift_fixnum_builtin:
TLunsignedrightshift_flonum_number_object:
TLunsignedrightshift_fixnum_regexp:
TLunsignedrightshift_fixnum_function:
TLunsignedrightshift_flonum_boolean_object:
TLunsignedrightshift_fixnum_special:
TLunsignedrightshift_fixnum_simple_object:
TLunsignedrightshift_flonum_builtin:
TLunsignedrightshift_fixnum_iterator:
{ // normal_fixnum normal_boolean_object vmgen.newsynth.DecisionDiagram$Leaf@df

  v2 = to_number(context, v2);
  goto USELABEL(HEAD);
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@5f3
break;
case TV_FIXNUM:
default:
Lunsignedrightshift4:
TLunsignedrightshift_any_fixnum:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@11cb(3)
case TV_STRING:
case 3:
case 2:
case 1:
case TV_SPECIAL:
case TV_GENERIC:
Lunsignedrightshift5:
TLunsignedrightshift_iterator_fixnum:
TLunsignedrightshift_string_object_fixnum:
TLunsignedrightshift_string_flonum:
TLunsignedrightshift_boolean_object_flonum:
TLunsignedrightshift_special_flonum:
TLunsignedrightshift_builtin_fixnum:
TLunsignedrightshift_simple_object_fixnum:
TLunsignedrightshift_number_object_fixnum:
TLunsignedrightshift_iterator_flonum:
TLunsignedrightshift_regexp_flonum:
TLunsignedrightshift_function_flonum:
TLunsignedrightshift_number_object_flonum:
TLunsignedrightshift_boolean_object_fixnum:
TLunsignedrightshift_array_flonum:
TLunsignedrightshift_array_fixnum:
TLunsignedrightshift_string_object_flonum:
TLunsignedrightshift_regexp_fixnum:
TLunsignedrightshift_special_fixnum:
TLunsignedrightshift_string_fixnum:
TLunsignedrightshift_simple_object_flonum:
TLunsignedrightshift_builtin_flonum:
TLunsignedrightshift_function_fixnum:
{ // normal_special normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@f3

  v1 = to_number(context, v1);
  goto USELABEL(HEAD);
}
break;
case TV_FLONUM:
Lunsignedrightshift6:
TLunsignedrightshift_flonum_fixnum:
{ // normal_flonum normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@61d

  int32_t x1 = (uint32_t) flonum_to_cint(v1);
  cint x2 = fixnum_to_cint(v2) & 31;
  dst = uint32_to_number(context, x1 >> x2);
}
break;
case TV_FIXNUM:
default:
Lunsignedrightshift7:
TLunsignedrightshift_fixnum_fixnum:
{ // normal_fixnum normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@11fd

  uint32_t x1 = (uint32_t) fixnum_to_cint(v1);
  cint x2 = fixnum_to_cint(v2) & 31;
  dst = uint32_to_number(context, x1 >> x2);
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@11cb
break;
case TV_FLONUM:
Lunsignedrightshift8:
TLunsignedrightshift_any_flonum:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@173c(3)
case TV_STRING:
case 3:
case 2:
case 1:
case TV_SPECIAL:
case TV_GENERIC:
goto Lunsignedrightshift5;
break;
case TV_FLONUM:
Lunsignedrightshift9:
TLunsignedrightshift_flonum_flonum:
{ // normal_flonum normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@2d3

  int32_t x1 = (uint32_t) flonum_to_cint(v1);
  cint x2 = flonum_to_cint(v2) & 31;
  dst = uint32_to_number(context, x1 >> x2);
}
break;
case TV_FIXNUM:
default:
Lunsignedrightshift10:
TLunsignedrightshift_fixnum_flonum:
{ // normal_fixnum normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@dbb

  int32_t x1 = (uint32_t) fixnum_to_cint(v1);
  cint x2 = flonum_to_cint(v2) & 31;
  dst = uint32_to_number(context, x1 >> x2);
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@173c
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@550
#undef dst

