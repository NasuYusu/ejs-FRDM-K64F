/*
   makeclosure dst subscr
     dst : destination register
     subscr : subscript of the function table
   $dst = new closure
 */
{
  /*
     `subscr' is the subscript of the function table EXCEPT the
     main function.  Since the main function comes first in the
     function table, the subecript should be added by 1.
   */
  Subscript ss = s1 + 1;
  save_context();
  regbase[r0] = new_function_object(context, DEBUG_NAME("insn:makeclosure"),
                                    gshapes.g_shape_Function, ss);
  update_context();
}

