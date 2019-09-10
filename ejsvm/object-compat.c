static void remove_array_props(JSValue a, cint from, cint to);
  
/**
 * Obtain property of the object. It converts type of ``name'' if necessary.
 *   obj:  any type
 *   name: any type
 */
#ifdef INLINE_CACHE
JSValue get_object_prop(Context *ctx, JSValue obj, JSValue name,
			InlineCache *ic)
#else /* INLINE_CACHE */
JSValue get_object_prop(Context *ctx, JSValue obj, JSValue name)
#endif /* INLINE_CACHE */
{
  if (!is_string(name)) {
    GC_PUSH(obj);
    name = to_string(ctx, name);
    GC_POP(obj);
  }
#ifdef INLINE_CACHE
  return get_prop_prototype_chain_with_ic(obj, name, ic);
#else /* INLINE_CACHE */
  return get_prop_prototype_chain(obj, name);
#endif /* INLINE_CACHE */
}

/*
 *  obtains array's property
 *    a: array
 *    p: property (number / string / other type)
 *  It is not necessary to check the type of `a'.
 */
JSValue get_array_prop(Context *ctx, JSValue a, JSValue p)
{
  /*
   * if (p is a number) {
   *   if (p is within the range of an subscript of an array)
   *     returns the p-th element of a
   *   else {
   *     p = number_to_string(idx);
   *     returns the value regsitered under the property p
   *   }
   * } else {
   *   if (p is not a string) p = to_string(p);
   *   s = string_to_number(p);
   *   if (s is within the range of an subscript of an array)
   *     returns the s-th element of a
   *   else
   *     returns the value regsitered under the property p
   * }
   *
   * I am afraid that the above definition is incorrect.
   *
   * } else if (p is a string) {
   *   s = string_to_number(p);
   *   if (s is within the range of an subscript of an array)
   *     returns the s-th element of a
   *   else
   *     returns the value regsitered under the property p
   * } else {
   *   p = to_string(p);
   *   returns the value regsitered under the property p
   * }
   *
   */

  if (is_fixnum(p)) {
    cint n;
    n = fixnum_to_cint(p);
    if (0 <= n && n < array_size(a)) {
      return (n < array_length(a))? array_body(a)[n]: JS_UNDEFINED;
    }
    p = fixnum_to_string(p);
    return get_prop_prototype_chain(a, p);
  }

  if (!is_string(p)) {
    GC_PUSH(a);
    p = to_string(ctx, p);
    GC_POP(a);
  }
  assert(is_string(p));
  {
    JSValue num;
    cint n;
    num = string_to_number(p);
    if (is_fixnum(num)) {
      n = fixnum_to_cint(num);
      if (0 <= n && n < array_size(a)) {
        return (n < array_length(a))? array_body(a)[n]: JS_UNDEFINED;
      }
    }
    return get_prop_prototype_chain(a, p);
  }
}

/*
 * determines whether a[n] exists or not
 * if a[n] is not an element of body (a C array) of a, search properties of a
 *  a: array
 *  n: subscript
 */
int has_array_element(JSValue a, cint n)
{
  if (!is_array(a))
    return FALSE;
  if (n < 0 || array_length(a) <= n)
    return FALSE;
  /* in body of 'a' */
  if (n < array_size(a))
    return TRUE;
  /* in property of 'a' */
  return get_prop_prototype_chain(a, cint_to_string(n)) != JS_EMPTY;
}

/*
 * sets object's property
 *   o: object (but not an array)
 *   p: property (number / string / other type)
 *   v: value to be set
 * It is not necessary to check the type of `o'.
 */
int set_object_prop(Context *ctx, JSValue o, JSValue p, JSValue v)
{
  if (!is_string(p)) {
    GC_PUSH2(o, v);
    p = to_string(ctx, p);
    GC_POP2(v, o);
  }
  set_prop(ctx, o, p, v, ATTR_NONE);
  return SUCCESS;
}

/*
 *  set_array_index_value
 *  a is an array and n is a subscript where n >= 0.
 *  This function is called when
 *    a[n] <- v (in this case, setlength is False)
 *    or
 *    a.length <- n + 1 (in this case, setlength is True)
 *
 *  In the latter case, it is not necessary to do a[n] <- v, but
 *  it may be necessary to shrink the array.
 *
 *  returns
 *    SUCCESS: the above assignment is performed
 *    FAIL   : the above assignment has not been done yet because n is
 *             outside, but expanding array has been done if necessary
 */
int set_array_index_value(Context *ctx, JSValue a, cint n, JSValue v,
                          int setlength)
{
  cint len, size, adatamax;
  int i;

  len = array_length(a);
  size = array_size(a);
  adatamax = (size <= ASIZE_LIMIT)? ASIZE_LIMIT: size;
  /* printf("set_array_index_value: n = %d\n", n); */
  if (n < adatamax) {
    if (size <= n) {
      /*
       * It is necessary to expand the array, but since n is less than
       *  ASIZE_LIMIT, it is possible to expand the array data.
       */
      cint newsize;
      while ((newsize = increase_asize(size)) <= n) size = newsize;
      GC_PUSH2(a, v);
      reallocate_array_data(ctx, a, newsize);
      GC_POP2(v, a);
    }
    /*
     * If len <= n, expands the array.  It should be noted that
     * if len >= n, this for loop does nothing
     */
    for (i = len; i <= n; i++) /* i < n? */
      array_body(a)[i] = JS_UNDEFINED;
  } else {
    /*
     * Since n is outside of the range of array data, stores the
     * value into the hash table of the array.
     */
    if (size < ASIZE_LIMIT) {
      /* The array data is not fully expanded, so we expand it */
      GC_PUSH2(a, v);
      reallocate_array_data(ctx, a, ASIZE_LIMIT);
      GC_POP2(v, a);
      for (i = len; i < ASIZE_LIMIT; i++)
        array_body(a)[i] = JS_UNDEFINED;
      adatamax = ASIZE_LIMIT;
    }
  }
  if (len <= n || setlength == TRUE) {
    array_length(a) = n + 1;
    GC_PUSH2(a, v);
    set_prop(ctx, a, gconsts.g_string_length, cint_to_fixnum(n + 1), ATTR_NONE);
    GC_POP2(v, a);
  }
  if (setlength == TRUE && n < len && adatamax <= len) {
    remove_array_props(a, adatamax, len);
  }
  if (n < adatamax && setlength == FALSE) {
    array_body(a)[n] = v;
    return SUCCESS;
  }
  return FAIL;
}

/*
 * sets array's property
 *   a: array
 *   p: property (number / string / other type)
 *   v: value to be set
 * It is not necessary to check the type of `a'.
 */
int set_array_prop(Context *ctx, JSValue a, JSValue p, JSValue v)
{
  if (is_fixnum(p)) {
    cint n;

    n = fixnum_to_cint(p);
    if (0 <= n && n < MAX_ARRAY_LENGTH) {
      GC_PUSH3(a, p, v);
      if (set_array_index_value(ctx, a, n, v, FALSE) == SUCCESS) {
        GC_POP3(v, p, a);
        return SUCCESS;
      }
      GC_POP3(v, p, a);
    }
    p = fixnum_to_string(p);
    return set_object_prop(ctx, a, p, v);
  }

  if (!is_string(p)) {
    GC_PUSH2(a, v);
    p = to_string(ctx, p);
    GC_POP2(v, a);
  }

  {  /* assert: p == string */
    JSValue num;
    cint n;

    num = string_to_number(p);
    if (is_fixnum(num)) {
      n = fixnum_to_cint(num);
      if (0 <= n && n < MAX_ARRAY_LENGTH) {
        GC_PUSH3(a, p, v);
        if (set_array_index_value(ctx, a, n, v, FALSE) == SUCCESS) {
          GC_POP3(v, p, a);
          return SUCCESS;
        }
        GC_POP3(v, p, a);
      }
      return set_object_prop(ctx, a, p, v);
    }
    if (p == gconsts.g_string_length && is_fixnum(v)) {
      cint n;
      n = fixnum_to_cint(v);
      if (0 <= n && n < MAX_ARRAY_LENGTH) {
        /*
         * The property name is "length" and the given value is a fixnum.
         * Thus, expands / shrinks the array.
         */
        GC_PUSH3(a, p, v);
        if (set_array_index_value(ctx, a, n - 1, JS_UNDEFINED, TRUE)
            == SUCCESS) {
          GC_POP3(v, p, a);
          return SUCCESS;
        }
        GC_POP3(v, p, a);
      }
    }
    return set_object_prop(ctx, a, p, v);
  }
}


/*
 * removes array data whose subscript is between `from' and `to'
 * that are stored in the property table.
 * implemented tentatively
 */
static void remove_array_props(JSValue a, cint from, cint to)
{
  /* printf("%d-%d\n",from,to); */
  for (; from < to ; from++)
    delete_array_element(a, from);
}

/*
 * delete the hash cell with key and the property of the object
 * NOTE:
 *   The function does not reallocate (shorten) the prop array of the object.
 *   It must be improved.
 * NOTE:
 *   When using hidden class, this function does not delete a property
 *   of an object but merely sets the corresponding property as JS_UNDEFINED,
 */
int delete_object_prop(JSValue obj, HashKey key)
{
  int index;
  Attribute attr;

  if (!is_object(obj))
    return FAIL;

  /* Set corresponding property as JS_UNDEFINED */
  index = prop_index(remove_jsobject_tag(obj), key, &attr, NULL);
  if (index == - 1)
    return FAIL;
  object_set_prop(obj, index, JS_UNDEFINED);

  /* Delete map */
  LOG_EXIT("delete is not implemented");
  return SUCCESS;
}

/*
 * delete a[n]
 * Note that this function does not change a.length
 */
int delete_array_element(JSValue a, cint n)
{
  if (n < array_size(a)) {
    array_body(a)[n] = JS_UNDEFINED;
    return SUCCESS;
  }
  return delete_object_prop(a, cint_to_string(n));
}

/*
 * obtains the next property name in an iterator
 * iter:Iterator
 */
int iterator_get_next_propname(JSValue iter, JSValue *name)
{
  int size = iterator_size(iter);
  int index = iterator_index(iter);
  if(index < size) {
    *name = iterator_body_index(iter,index++);
    iterator_index(iter) = index;
    return SUCCESS;
  }else{
    *name = JS_UNDEFINED;
    return FAIL;
  }
}

#ifdef USE_REGEXP
/*
 * sets a regexp's members and makes an Oniguruma's regexp object
 */
int set_regexp_members(Context *ctx, JSValue re, char *pat, int flag)
{
  OnigOptionType opt;
  OnigErrorInfo err;
  char *e;

  /*
   * The original code in SSJSVM_codeloader.c used ststrdup function,
   * which is defined in hash.c.  But I don't know the reason why
   * ststrdup is used instead of the standard strdup function.
   *
   * regexp_pattern(re) = ststrdup(str);
   */
  regexp_pattern(re) = strdup(pat);

  opt = ONIG_OPTION_NONE;

  if (flag & F_REGEXP_GLOBAL) {
    regexp_global(re) = true;
    set_obj_cstr_prop(ctx, re, "global", JS_TRUE, ATTR_ALL);
  } else
    set_obj_cstr_prop(ctx, re, "global", JS_FALSE, ATTR_ALL);

  if (flag & F_REGEXP_IGNORE) {
    opt |= ONIG_OPTION_IGNORECASE;
    regexp_ignorecase(re) =  true;
    set_obj_cstr_prop(ctx, re, "ignoreCase", JS_TRUE, ATTR_ALL);
  } else
    set_obj_cstr_prop(ctx, re, "ignoreCase", JS_FALSE, ATTR_ALL);

  if (flag & F_REGEXP_MULTILINE) {
    opt |= ONIG_OPTION_MULTILINE;
    regexp_multiline(re) = true;
    set_obj_cstr_prop(ctx, re, "multiline", JS_TRUE, ATTR_ALL);
  } else
    set_obj_cstr_prop(ctx, re, "multiline", JS_FALSE, ATTR_ALL);

  e = pat + strlen(pat);
  if (onig_new(&(regexp_reg(re)), (OnigUChar *)pat, (OnigUChar *)e, opt,
               ONIG_ENCODING_ASCII, ONIG_SYNTAX_DEFAULT, &err) == ONIG_NORMAL)
    return SUCCESS;
  else
    return FAIL;
}

/*
 * returns a flag value from a ragexp objext
 */
int regexp_flag(JSValue re)
{
  int flag;

  flag = 0;
  if (regexp_global(re)) flag |= F_REGEXP_GLOBAL;
  if (regexp_ignorecase(re)) flag |= F_REGEXP_IGNORE;
  if (regexp_multiline(re)) flag |= F_REGEXP_MULTILINE;
  return flag;
}
#endif

/*
 * makes a simple iterator object
 */
JSValue new_iterator(Context *ctx, JSValue obj) {
  JSValue iter;
  int index = 0;
  int size = 0;
  JSValue tmpobj;

  GC_PUSH(obj);
  iter = make_iterator(ctx);

  /* allocate an itearator */
  tmpobj = obj;
  do {
    PropertyMap *pm = object_get_shape(tmpobj)->pm;
    size += pm->n_props - pm->n_special_props;
    tmpobj = get_prop(tmpobj, gconsts.g_string___proto__);
  } while (tmpobj != JS_NULL);
  GC_PUSH(iter);
  allocate_iterator_data(ctx, iter, size);

  /* fill the iterator with object properties */
  do {
    HashTable *ht;
    HashIterator hi;
    HashCell *p;

    ht = object_get_shape(obj)->pm->map;
    init_hash_iterator(ht, &hi);

    while (nextHashCell(ht, &hi, &p) == SUCCESS) {
      if ((JSValue)p->entry.attr & (ATTR_DE | ATTR_TRANSITION))
        continue;
      iterator_body_index(iter, index++) = (JSValue)p->entry.key;
    }
    obj = get_prop(obj, gconsts.g_string___proto__);
  } while (obj != JS_NULL);
  GC_POP2(iter, obj);
  return iter;
}

/*  data conversion functions */
char *space_chomp(char *str)
{
  while (isspace(*str)) str++;
  return str;
}

double cstr_to_double(char* cstr)
{
  char* endPtr;
  double ret;
  ret = strtod(cstr, &endPtr);
  while (isspace(*endPtr)) endPtr++;
  if (*endPtr == '\0') return ret;
  else return NAN;
}