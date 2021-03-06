/*
   lessthan dst r1 r2
     dst : destination register
     r1, r2 : source registers
   $dst = $r1 < $r2
   Note that `greaterthan' instruction is not supported.
 */
{
  Register dst = r0;
  double x1, x2;

  switch (TAG_PAIR_VARS(v1, v2)) {
  case TP_FIXFIX:
    regbase[dst] = true_false(((intjsv_t) v1) < ((intjsv_t) v2));
    break;
  case TP_FIXFLO:
    x1 = fixnum_to_double(v1);
    x2 = flonum_to_double(v2);
    regbase[dst] = true_false(x1 < x2);
    break;
  case TP_FLOFIX:
    x1 = flonum_to_double(v1);
    x2 = fixnum_to_double(v2);
    regbase[dst] = true_false(x1 < x2);
    break;
  case TP_FLOFLO:
    x1 = flonum_to_double(v1);
    x2 = flonum_to_double(v2);
    regbase[dst] = true_false(x1 < x2);
    break;
  case TP_STRSTR:
    regbase[dst] =
      true_false(strcmp(string_to_cstr(v1), string_to_cstr(v2)) < 0);
    break;
  default:
    regbase[dst] = slow_lessthan(context, v1, v2);
    break;
  }
}
