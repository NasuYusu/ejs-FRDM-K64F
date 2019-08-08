/*
 * eJS Project
 * Kochi University of Technology
 * the University of Electro-communications
 *
 * The eJS Project is the successor of the SSJS Project at the University of
 * Electro-communications, which was contributed by the following members.
 */

#include "prefix.h"
#define EXTERN extern
#include "header.h"

/*
 * constructor of a boolean
 */
BUILTIN_FUNCTION(boolean_constr)
{
  JSValue rsv;

  builtin_prologue();  
  rsv = new_boolean_object(context, JS_TRUE);
  if (na > 0)
    boolean_object_value(rsv) = to_boolean(args[1]);
  set_a(context, rsv);
}

BUILTIN_FUNCTION(boolean_valueOf)
{
  JSValue arg;

  builtin_prologue();  
  arg = args[0];
  if (is_boolean_object(arg))
    arg = boolean_object_value(arg);
  set_a(context, arg);
}

ObjBuiltinProp boolean_funcs[] = {
  { "valueOf",        boolean_valueOf,    0, ATTR_DE },
  { NULL,             NULL,               0, ATTR_DE }
};

void init_builtin_boolean(Context *ctx)
{
  JSValue b, proto;

  gconsts.g_boolean_proto = proto = new_boolean_object(ctx, JS_FALSE);
  GC_PUSH(proto);
  set___proto___all(ctx, proto, gconsts.g_object_proto);
  hidden_proto(gobjects.g_hidden_class_boxed_boolean) = proto;

  gconsts.g_boolean = b =
    new_builtin_with_constr(ctx, boolean_constr, boolean_constr, 1);
  GC_PUSH(b);
  set_prototype_de(ctx, b, proto);
  {
    ObjBuiltinProp *p = boolean_funcs;
    while (p->name != NULL) {
      set_obj_cstr_prop(ctx, proto, p->name,
                        new_builtin(ctx, p->fn, p->na), p->attr);
      p++;
    }
  }
  GC_POP2(b, proto);
}

/* Local Variables:      */
/* mode: c               */
/* c-basic-offset: 2     */
/* indent-tabs-mode: nil */
/* End:                  */
