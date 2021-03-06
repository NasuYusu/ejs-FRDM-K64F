#define dst regbase[r0]

DEFLABEL(HEAD):
INSN_COUNT2(equal,v1,v2);Lequal0:
TLequal_array_any:
TLequal_any_any:
TLequal_string_object_any:
TLequal_function_any:
TLequal_flonum_any:
TLequal_special_any:
TLequal_simple_object_any:
TLequal_number_object_any:
TLequal_fixnum_any:
TLequal_string_any:
TLequal_boolean_object_any:
TLequal_builtin_any:
TLequal_regexp_any:
TLequal_iterator_any:
switch((unsigned int) get_ptag(v2).v){ // vmgen.newsynth.DecisionDiagram$PTNode@550(5)
case TV_SPECIAL:
Lequal1:
TLequal_any_special:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@41d(5)
case TV_FIXNUM:
default:
Lequal2:
TLequal_fixnum_special:
{ // normal_fixnum normal_special vmgen.newsynth.DecisionDiagram$Leaf@11ac

  if (v2 == JS_UNDEFINED) dst = JS_FALSE;
  else if (v2 == JS_NULL) dst = JS_FALSE;
  else {
    if (v2 == JS_TRUE) v2 = FIXNUM_ONE;
    else if (v2 == JS_FALSE) v2 = FIXNUM_ZERO;
    dst = true_false(v1 == v2);
  }
}
break;
case TV_FLONUM:
Lequal3:
TLequal_fixnum_flonum:
TLequal_special_flonum:
TLequal_flonum_special:
TLequal_flonum_fixnum:
{ // normal_fixnum normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@13fd

  dst = JS_FALSE;
}
break;
case TV_STRING:
case 3:
case 2:
case 1:
Lequal4:
TLequal_string_special:
{ // normal_string normal_special vmgen.newsynth.DecisionDiagram$Leaf@1928

  if (v2 == JS_UNDEFINED) dst = JS_FALSE;
  else if (v2 == JS_NULL) dst = JS_FALSE;
  else {
    if (v2 == JS_TRUE) v2 = FIXNUM_ONE;
    else if (v2 == JS_FALSE) v2 = FIXNUM_ZERO;
    goto USELABEL(STRFIX);
  }
}
break;
case TV_GENERIC:
Lequal5:switch((unsigned int) get_htag(v1).v){ // vmgen.newsynth.DecisionDiagram$HTNode@1e1f(2)
case HTAGV_ITERATOR:
Lequal6:
TLequal_iterator_iterator:
TLequal_simple_object_boolean_object:
TLequal_boolean_object_iterator:
TLequal_regexp_boolean_object:
TLequal_function_boolean_object:
TLequal_simple_object_function:
TLequal_iterator_special:
TLequal_array_simple_object:
TLequal_regexp_function:
TLequal_builtin_array:
TLequal_regexp_string_object:
TLequal_array_builtin:
TLequal_string_object_simple_object:
TLequal_iterator_string_object:
TLequal_builtin_regexp:
TLequal_string_object_builtin:
TLequal_simple_object_iterator:
TLequal_simple_object_builtin:
TLequal_boolean_object_function:
TLequal_regexp_array:
TLequal_fixnum_iterator:
TLequal_iterator_function:
TLequal_function_string_object:
TLequal_boolean_object_array:
TLequal_iterator_boolean_object:
TLequal_number_object_simple_object:
TLequal_function_regexp:
TLequal_builtin_number_object:
TLequal_string_object_function:
TLequal_regexp_iterator:
TLequal_boolean_object_boolean_object:
TLequal_special_iterator:
TLequal_regexp_regexp:
TLequal_array_regexp:
TLequal_regexp_simple_object:
TLequal_boolean_object_string_object:
TLequal_regexp_builtin:
TLequal_number_object_regexp:
TLequal_number_object_string_object:
TLequal_string_object_string_object:
TLequal_simple_object_number_object:
TLequal_array_iterator:
TLequal_function_iterator:
TLequal_simple_object_regexp:
TLequal_function_simple_object:
TLequal_function_array:
TLequal_number_object_array:
TLequal_builtin_builtin:
TLequal_boolean_object_regexp:
TLequal_string_object_iterator:
TLequal_builtin_boolean_object:
TLequal_string_object_regexp:
TLequal_string_object_number_object:
TLequal_number_object_boolean_object:
TLequal_iterator_array:
TLequal_iterator_number_object:
TLequal_string_object_array:
TLequal_array_number_object:
TLequal_builtin_iterator:
TLequal_builtin_simple_object:
TLequal_builtin_function:
TLequal_iterator_fixnum:
TLequal_string_object_boolean_object:
TLequal_simple_object_array:
TLequal_boolean_object_number_object:
TLequal_boolean_object_builtin:
TLequal_simple_object_simple_object:
TLequal_number_object_iterator:
TLequal_iterator_string:
TLequal_array_string_object:
TLequal_number_object_function:
TLequal_string_iterator:
TLequal_flonum_iterator:
TLequal_function_number_object:
TLequal_array_array:
TLequal_iterator_flonum:
TLequal_iterator_builtin:
TLequal_boolean_object_simple_object:
TLequal_function_function:
TLequal_array_boolean_object:
TLequal_iterator_simple_object:
TLequal_iterator_regexp:
TLequal_array_function:
TLequal_regexp_number_object:
TLequal_function_builtin:
TLequal_number_object_number_object:
TLequal_simple_object_string_object:
TLequal_number_object_builtin:
TLequal_builtin_string_object:
{ // normal_iterator normal_string_object vmgen.newsynth.DecisionDiagram$Leaf@16

  if (v1 == v2) dst = JS_TRUE;
  else dst = JS_FALSE;
}
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
Lequal7:
TLequal_regexp_special:
TLequal_string_object_string:
TLequal_simple_object_string:
TLequal_regexp_flonum:
TLequal_string_object_special:
TLequal_array_string:
TLequal_boolean_object_string:
TLequal_array_special:
TLequal_builtin_flonum:
TLequal_simple_object_special:
TLequal_array_flonum:
TLequal_function_flonum:
TLequal_number_object_flonum:
TLequal_simple_object_flonum:
TLequal_regexp_string:
TLequal_string_object_flonum:
TLequal_builtin_string:
TLequal_builtin_special:
TLequal_function_string:
TLequal_function_special:
TLequal_number_object_string:
TLequal_number_object_special:
TLequal_boolean_object_flonum:
TLequal_boolean_object_special:
{ // normal_simple_object normal_string vmgen.newsynth.DecisionDiagram$Leaf@97

  v1 = object_to_primitive(context, v1, HINT_NUMBER);
  goto USELABEL(HEAD);
}
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@1e1f
break;
case TV_SPECIAL:
Lequal8:
TLequal_special_special:
{ // normal_special normal_special vmgen.newsynth.DecisionDiagram$Leaf@220f

  if (v1 == v2) dst = JS_TRUE;
  else dst = true_false((is_undefined(v1) && is_null(v2)) || (is_undefined(v2) && is_null(v1)));
}
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@41d
break;
case TV_GENERIC:
Lequal9:
TLequal_any_function:
TLequal_any_number_object:
TLequal_any_array:
TLequal_any_string_object:
TLequal_any_simple_object:
TLequal_any_builtin:
TLequal_any_regexp:
TLequal_any_boolean_object:
TLequal_any_iterator:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@81a(3)
case TV_GENERIC:
goto Lequal6;
break;
case TV_FIXNUM:
default:
Lequal10:switch((unsigned int) get_htag(v2).v){ // vmgen.newsynth.DecisionDiagram$HTNode@1aff(2)
case HTAGV_ITERATOR:
goto Lequal6;
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
Lequal11:
TLequal_fixnum_number_object:
TLequal_fixnum_boolean_object:
TLequal_fixnum_function:
TLequal_fixnum_simple_object:
TLequal_fixnum_string_object:
TLequal_fixnum_regexp:
TLequal_fixnum_builtin:
TLequal_fixnum_array:
{ // normal_fixnum normal_simple_object vmgen.newsynth.DecisionDiagram$Leaf@241

  v2 = object_to_primitive(context, v2, HINT_NUMBER);
  dst = true_false(v1 == v2);
}
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@1aff
break;
case TV_STRING:
case 3:
case 2:
case 1:
case TV_FLONUM:
case TV_SPECIAL:
Lequal12:switch((unsigned int) get_htag(v2).v){ // vmgen.newsynth.DecisionDiagram$HTNode@23e4(2)
case HTAGV_ITERATOR:
goto Lequal6;
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
Lequal13:
TLequal_special_boolean_object:
TLequal_flonum_regexp:
TLequal_flonum_array:
TLequal_string_builtin:
TLequal_string_regexp:
TLequal_string_simple_object:
TLequal_string_string_object:
TLequal_special_string_object:
TLequal_flonum_boolean_object:
TLequal_flonum_simple_object:
TLequal_flonum_builtin:
TLequal_special_number_object:
TLequal_special_simple_object:
TLequal_special_function:
TLequal_special_array:
TLequal_string_number_object:
TLequal_string_array:
TLequal_flonum_number_object:
TLequal_special_regexp:
TLequal_flonum_function:
TLequal_string_boolean_object:
TLequal_flonum_string_object:
TLequal_special_builtin:
TLequal_string_function:
{ // normal_string normal_boolean_object vmgen.newsynth.DecisionDiagram$Leaf@69

  v2 = object_to_primitive(context, v2, HINT_NUMBER);
  goto USELABEL(HEAD);
}
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@23e4
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@81a
break;
case TV_STRING:
case 3:
case 2:
case 1:
Lequal14:
TLequal_any_string:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@b26(5)
case TV_STRING:
case 3:
case 2:
case 1:
Lequal15:
TLequal_fixnum_fixnum:
TLequal_string_string:
{ // normal_fixnum normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@54

  if (v1 == v2) dst = JS_TRUE;
  else dst = JS_FALSE;
}
break;
case TV_FLONUM:
Lequal16:
TLequal_flonum_string:
{ // normal_flonum normal_string vmgen.newsynth.DecisionDiagram$Leaf@9ae

  v2 = string_to_number(context, v2);
  goto USELABEL(HEAD);
}
break;
case TV_FIXNUM:
default:
Lequal17:
TLequal_fixnum_string:
{ // normal_fixnum normal_string vmgen.newsynth.DecisionDiagram$Leaf@e6b

DEFLABEL(FIXSTR):
  v2 = string_to_number(context, v2);
  dst = true_false(v1 == v2);
}
break;
case TV_SPECIAL:
Lequal18:
TLequal_special_string:
{ // normal_special normal_string vmgen.newsynth.DecisionDiagram$Leaf@1d31

  if (v1 == JS_UNDEFINED) dst = JS_FALSE;
  else if (v1 == JS_NULL) dst = JS_FALSE;
  else {
    if (v1 == JS_TRUE) v1 = FIXNUM_ONE;
    else if (v1 == JS_FALSE) v1 = FIXNUM_ZERO;
    goto USELABEL(FIXSTR);
  }
}
break;
case TV_GENERIC:
goto Lequal5;
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@b26
break;
case TV_FIXNUM:
default:
Lequal19:
TLequal_any_fixnum:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@10a6(5)
case TV_FIXNUM:
default:
goto Lequal15;
break;
case TV_SPECIAL:
Lequal20:
TLequal_special_fixnum:
{ // normal_special normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@285

  if (v1 == JS_UNDEFINED) dst = JS_FALSE;
  else if (v1 == JS_NULL) dst = JS_FALSE;
  else {
    if (v1 == JS_TRUE) v1 = FIXNUM_ONE;
    else if (v1 == JS_FALSE) v1 = FIXNUM_ZERO;
    dst = true_false(v1 == v2);
  }
}
break;
case TV_GENERIC:
Lequal21:switch((unsigned int) get_htag(v1).v){ // vmgen.newsynth.DecisionDiagram$HTNode@79b(2)
case HTAGV_ITERATOR:
goto Lequal6;
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
Lequal22:
TLequal_boolean_object_fixnum:
TLequal_number_object_fixnum:
TLequal_function_fixnum:
TLequal_string_object_fixnum:
TLequal_simple_object_fixnum:
TLequal_regexp_fixnum:
TLequal_array_fixnum:
TLequal_builtin_fixnum:
{ // normal_boolean_object normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@df

  v1 = object_to_primitive(context, v1, HINT_NUMBER);
  dst = true_false(v1 == v2);
}
break;
}// vmgen.newsynth.DecisionDiagram$HTNode@79b
break;
case TV_STRING:
case 3:
case 2:
case 1:
Lequal23:
TLequal_string_fixnum:
{ // normal_string normal_fixnum vmgen.newsynth.DecisionDiagram$Leaf@11cb

DEFLABEL(STRFIX):
  v1 = string_to_number(context, v1);
  dst = true_false(v1 == v2);
}
break;
case TV_FLONUM:
goto Lequal3;
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@10a6
break;
case TV_FLONUM:
Lequal24:
TLequal_any_flonum:
switch((unsigned int) get_ptag(v1).v){ // vmgen.newsynth.DecisionDiagram$PTNode@173c(4)
case TV_STRING:
case 3:
case 2:
case 1:
Lequal25:
TLequal_string_flonum:
{ // normal_string normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@b61

  v1 = string_to_number(context, v1);
  goto USELABEL(HEAD);
}
break;
case TV_FLONUM:
Lequal26:
TLequal_flonum_flonum:
{ // normal_flonum normal_flonum vmgen.newsynth.DecisionDiagram$Leaf@dbb

  double x1, x2;
  if (v1 == v2) {
    dst = false_true(is_nan(v1));
  } else {
    x1 = flonum_to_double(v1);
    x2 = flonum_to_double(v2);
    dst = true_false(x1 == x2);
  }
}
break;
case TV_SPECIAL:
case TV_FIXNUM:
default:
goto Lequal3;
break;
case TV_GENERIC:
goto Lequal5;
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@173c
break;
} // vmgen.newsynth.DecisionDiagram$PTNode@550
#undef dst

