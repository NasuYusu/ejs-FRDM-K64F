EJSVM_DIR = ../ejsvm

.PRECIOUS: %.c %.h %.o

##
## configuration files
##

#DATATYPES = $(EJSVM_DIR)/datatypes/default_32.def
DATATYPES = $(EJSVM_DIR)/datatypes/default.def
OPERANDSPEC = $(EJSVM_DIR)/operand-spec/any.spec
# OPERANDSPEC = $(EJSVM_DIR)/operand-spec/fixnum-unspec.spec
SUPERINSNSPEC = $(EJSVM_DIR)/superinsn-spec/all.si
SUPERINSNTYPE = 4
#VMDLC_FLAGS=-no-match-opt

##
## compile flags
##

# CFLAGS for C compiler and preprocessor
# CXXFLAGS for C++ compiler
# CPPFLAGS for C and  C++ compilers and preprocessor

CPPFLAGS = -O2 -g -DNDEBUG -UDEBUG $(HEAPSIZE)
# CPPFLAGS = -Os -DNDEBUG -UDEBUG $(HEAPSIZE)
# CPPFLAGS = -O0 -g $(HEAPSIZE)
CFLAGS =
CXXFLAGS =
INSNGEN_FLAGS = -Xgen:pad_cases true -Xcmp:opt_pass MR:S -Xcmp:rand_seed 0

##
## C++
##
GC_CXX = true

##
## VMDL
##
USE_VMDL = false

##
## MBED
##
#MBED = true
MBED = false

##
## commands
##

## Use Mbed
ifeq ($(MBED), true)
	CC = arm-none-eabi-gcc
	CXX = arm-none-eabi-g++
else
	CC = gcc
	CXX = gcc
endif
#CC = gcc
#CC = arm-none-eabi-gcc
#CXX = gcc
#CXX = arm-none-eabi-g++
SED = gsed
# SED = sed
#PYTHON = python
 PYTHON = python3
# CPP_VMDL = $(CPP) -E -x c -P
COCCINELLE = spatch
# COCCINELLE = spatch --python python3

##
## paths
##

INCLUDES =
# INCLUDES = -I/opt/local/include
LIBS =
# LIBS = -L/opt/local/lib

## 
## options
## 

OPT_REGEXP    = none
# OPT_REGEXP    = oniguruma
OPT_GC        = native
#OPT_GC        = bibop
#OPT_GC        = copy
#OPT_GC        = none

## heap size in bytes
HEAPSIZE      = -DJS_SPACE_BYTES=10485760

## enable profiling to create customised VM
# CFLAGS       += -DPROFILE

## word size
# INSN32/64    -- instruction size
# JSVALUE32/64 -- JSValue size  (>= ponter size)
# ALIGN32/64   -- alignment of heap-allocated data
#CPPFLAGS        += -DBIT_INSN32 -DBIT_ALIGN32 -DBIT_JSVALUE32
CPPFLAGS        += -DBIT_INSN64 -DBIT_ALIGN64 -DBIT_JSVALUE64

##
## developer options
##

## accept SBC files
CPPFLAGS       += -DUSE_SBC
## GC collects internal nodes in hidden class graph
CPPFLAGS       += -DHC_SKIP_INTERNAL
## cache shapes at allocation site
CPPFLAGS       += -DALLOC_SITE_CACHE
## GC collects unused shapes (effective if ALLOC_SITE_CACHE is specified)
CPPFLAGS       += -DWEAK_SHAPE_LIST
## Do not hold the list of shapes.  Instead, only the largest shape is held.
#CPPFLAGS       += -DNO_SHAPE_CACHE
## use inlne cache
CPPFLAGS       += -DINLINE_CACHE

## show GC profiling information (make --gc-prof available)
CPPFLAGS       += -DGC_PROF
## show hidden class related profiling information (make --hc-prof available)
CPPFLAGS       += -DHC_PROF
## print flonum usage
#CPPFLAGS       += -DFLONUM_SPACE

## use explicit mark stack rather than recursive call
#CPPFLAGS      += -DMARK_STACK

## array size strategy
CPPFLAGS       += -DNEW_ASIZE_STRATEGY

##
## BiBoP options
##

## page caches the size of bitmaps
CFALGS       += -DBIBOP_CACHE_BMP_GRANULES
## free pages of size one is linked in a separate list
CPPFLAGS       += -DBIBOP_SEGREGATE_1PAGE
## allocate pages of size one from the bottom of the heap
CPPFLAGS       += -DBIBOP_2WAY_ALLOC
## link free blocks in a page to form a freelist
CPPFLAGS       += -DBIBOP_FREELIST
## use flonum pages as if it is a hashtable to encourage sahreing flonum objects
#CPPFLAGS       += -DFLONUM_SPACE
## debug
CPPFLAGS       += -DVERIFY_BIBOP

##
## debug/sanity check options
##

## show values of properties in GETPROP/SETPROP instructions
#CPPFLAGS   += -DDEBUG_GETPROP_VALUE

## GC reports unmatured (not reached the end of HC
## transisiton graph) dead objects
#CPPFLAGS   += -DCHECK_MATURED

## Use Mbed
ifeq ($(MBED), true)
	CPPFLAGS += -DMBED
endif

## fix rand seed
CPPFLAGS    += -DNO_SRAND

include $(EJSVM_DIR)/common.mk
