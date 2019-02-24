.PHONY: check clean

######################################################

ifeq ($(EJSVM_DIR),)
    EJSVM_DIR=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
endif

######################################################
# default values

ifeq ($(CC),cc)
    CC = clang
endif
ifeq ($(SED),)
    SED = gsed
endif
ifeq ($(RUBY),)
    RUBY = ruby
endif
ifeq ($(PYTHON),)
    PYTHON = python
endif
ifeq ($(COCCINELLE),)
    COCCINELLE = spatch
endif
ifeq ($(OPT_GC),)
# GC=native|boehmgc|none
    OPT_GC=native
endif
ifeq ($(OPT_REGEXP),)
# REGEXP=oniguruma|none
    OPT_REGEXP=none
endif

######################################################
# commands and paths

INSNGEN=java -cp $(EJSVM_DIR)/vmgen/vmgen.jar vmgen.InsnGen
TYPESGEN=java -cp $(EJSVM_DIR)/vmgen/vmgen.jar vmgen.TypesGen
CPP=$(CC) -E

CFLAGS += -std=gnu89 -Wall -Wno-unused-label -DUSER_DEF $(INCLUDES)
LIBS   += -lm

######################################################

GENERATED_HFILES = \
    instructions-opcode.h \
    instructions-table.h \
    instructions-label.h \
    cell-header.h

HFILES = $(GENERATED_HFILES) \
    prefix.h \
    context.h \
    header.h \
    builtin.h \
    hash.h \
    instructions.h \
    types.h \
    globals.h \
    extern.h \
    log.h \
    gc.h

OFILES = \
    allocate.o \
    builtin-array.o \
    builtin-boolean.o \
    builtin-global.o \
    builtin-math.o \
    builtin-number.o \
    builtin-object.o \
    builtin-regexp.o \
    builtin-string.o \
    call.o \
    codeloader.o \
    context.o \
    conversion.o \
    hash.o \
    init.o \
    string.o \
    object.o \
    operations.o \
    vmloop.o \
    gc.o \
    main.o

INSN_GENERATED = \
    insns/add.inc \
    insns/bitand.inc \
    insns/bitor.inc \
    insns/call.inc \
    insns/div.inc \
    insns/eq.inc \
    insns/equal.inc \
    insns/getprop.inc \
    insns/leftshift.inc \
    insns/lessthan.inc \
    insns/lessthanequal.inc \
    insns/mod.inc \
    insns/mul.inc \
    insns/new.inc \
    insns/rightshift.inc \
    insns/setprop.inc \
    insns/sub.inc \
    insns/tailcall.inc \
    insns/unsignedrightshift.inc

INSN_HANDCRAFT = \
    insns/end.inc \
    insns/error.inc \
    insns/fixnum.inc \
    insns/geta.inc \
    insns/getarg.inc \
    insns/geterr.inc \
    insns/getglobal.inc \
    insns/getglobalobj.inc \
    insns/getlocal.inc \
    insns/instanceof.inc \
    insns/isobject.inc \
    insns/isundef.inc \
    insns/jump.inc \
    insns/jumpfalse.inc \
    insns/jumptrue.inc \
    insns/localcall.inc \
    insns/localret.inc \
    insns/makeclosure.inc \
    insns/makesimpleiterator.inc \
    insns/move.inc \
    insns/newframe.inc \
    insns/nextpropnameidx.inc \
    insns/nop.inc \
    insns/not.inc \
    insns/number.inc \
    insns/pophandler.inc \
    insns/poplocal.inc \
    insns/pushhandler.inc \
    insns/ret.inc \
    insns/seta.inc \
    insns/setarg.inc \
    insns/setarray.inc \
    insns/setfl.inc \
    insns/setglobal.inc \
    insns/setlocal.inc \
    insns/specconst.inc \
    insns/throw.inc \
    insns/typeof.inc \
    insns/unknown.inc

CFILES = $(patsubst %.o,%.c,$(OFILES))
CHECKFILES = $(patsubst %.c,$(CHECKFILES_DIR)/%.c,$(CFILES))
INSN_FILES = $(INSN_GENERATED) $(INSN_HANDCRAFT)

######################################################

ifeq ($(OPT_GC),native)
    CFLAGS+=-DUSE_NATIVEGC=1
endif
ifeq ($(OPT_GC),boehmgc)
    CFLAGS+=-DUSE_BOEHMGC=1
    LIBS+=-lgc
endif
ifeq ($(OPT_REGEXP),oniguruma)
    CFLAGS+=-DUSE_REGEXP=1
    LIBS+=-lonig
endif

ifeq ($(DATATYPES),)
else
    CFLAGS += -DUSE_TYPES_GENERATED=1
    GENERATED_HFILES += types-generated.h
endif

SEDCOM_GEN_INSN_OPCODE = \
  -e 's/^\([a-z][a-z]*\).*/\U\1,/' -e '/^\/\/.*/d'
SEDCOM_GEN_INSN_TABLE = \
  -e 's/^\([a-z][a-z]*\)  *\([A-Z][A-Z]*\).*/  { "\1", \2 },/' -e '/^\/\/.*/d'
SEDCOM_GEN_INSN_LABEL = \
  -e 's/^\([a-z][a-z]*\).*/\&\&I_\U\1,/' -e '/^\/\/.*/d'

CHECKFILES_DIR = checkfiles
GCCHECK_PATTERN = ../gccheck.cocci

######################################################

ejsvm :: $(OFILES)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

instructions-opcode.h: $(EJSVM_DIR)/instructions.def
	$(SED) $(SEDCOM_GEN_INSN_OPCODE) $< > $@

instructions-table.h: $(EJSVM_DIR)/instructions.def
	$(SED) $(SEDCOM_GEN_INSN_TABLE) $< > $@

instructions-label.h: $(EJSVM_DIR)/instructions.def
	$(SED) $(SEDCOM_GEN_INSN_LABEL) $< > $@

instructions.h: instructions-opcode.h instructions-table.h

cell-header.h: $(EJSVM_DIR)/cell-header.def
	$(RUBY) $< > $@

vmloop-cases.inc: $(EJSVM_DIR)/instructions.def $(EJSVM_DIR)/gen-vmloop-cases.rb
	$(RUBY) $(EJSVM_DIR)/gen-vmloop-cases.rb < $(EJSVM_DIR)/instructions.def > $@

ifeq ($(DATATYPES),)
insns/%.inc: $(EJSVM_DIR)/insns-handcraft/%.inc
	mkdir -p insns
	cp $< $@
else
$(INSN_GENERATED):insns/%.inc: $(EJSVM_DIR)/insns-def/%.idef
	mkdir -p insns
	$(INSNGEN) $(INSNGEN_FLAGS) $(DATATYPES) $< $(OPERANDSPEC) insns

$(INSN_HANDCRAFT):insns/%.inc: $(EJSVM_DIR)/insns-handcraft/%.inc
	mkdir -p insns
	cp $< $@
endif

%.c: $(EJSVM_DIR)/%.c
	echo DEFUALT_C_RULE: $@
	cp $< $@

%.h: $(EJSVM_DIR)/%.h
	cp $< $@

vmloop.o: vmloop.c vmloop-cases.inc $(INSN_FILES) $(HFILES)
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.c $(HFILES)
	$(CC) -c $(CFLAGS) -o $@ $<

#### check

CHECKFILES   = $(patsubst %.c,$(CHECKFILES_DIR)/%.c,$(CFILES))
CHECKRESULTS = $(patsubst %.c,$(CHECKFILES_DIR)/%.c.checkresult,$(CFILES))
CHECKTARGETS = $(patsubst %.c,%.c.check,$(CFILES))

types-generated.h: $(DATATYPES)
	$(TYPESGEN) $< > $@

$(CHECKFILES):$(CHECKFILES_DIR)/%.c: %.c $(HFILES)
	mkdir -p $(CHECKFILES_DIR)
	$(CPP) $(CFLAGS) $< > $@

$(CHECKFILES_DIR)/vmloop.c: vmloop-cases.inc $(INSN_FILES)

.PHONY: %.check
$(CHECKTARGETS):%.c.check: $(CHECKFILES_DIR)/%.c
	$(COCCINELLE) --sp-file $(GCCHECK_PATTERN) $<

$(CHECKRESULTS):$(CHECKFILES_DIR)/%.c.checkresult: $(CHECKFILES_DIR)/%.c
	$(COCCINELLE) --sp-file $(GCCHECK_PATTERN) $< > $@

check: $(CHECKRESULTS)
	cat $^

#### clean

clean:
	rm -f *.o $(GENERATED_HFILES) vmloop-cases.inc *.c *.h
	rm -rf insns
	rm -f *.checkresult
	rm -rf $(CHECKFILES_DIR)


