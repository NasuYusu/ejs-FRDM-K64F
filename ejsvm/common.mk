.PHONY: check clean

OBJDIR := MBED
MBED_DIR=$(EJSVM_DIR)/../mbed
MBED_F=$(MBED_DIR)/mbed_config.h
MBED_MAIN=$(MBED_DIR)/helloworld.c


# cross-platform directory manipulation
ifeq ($(shell echo $$OS),$$OS)
    MAKEDIR = if not exist "$(1)" mkdir "$(1)"
    RM = rmdir /S /Q "$(1)"
else
    MAKEDIR = '$(SHELL)' -c "mkdir -p \"$(1)\""
    RM = '$(SHELL)' -c "rm -rf \"$(1)\""
endif

OBJDIR := BUILD
# Move to the build directory
ifeq (,$(filter $(OBJDIR),$(notdir $(CURDIR))))
.SUFFIXES:
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKETARGET = '$(MAKE)' --no-print-directory -C $(OBJDIR) -f '$(mkfile_path)' \
		$(MAKECMDGOALS)
.PHONY: $(OBJDIR) clean
all: mbed_config.h helloworld.c
	+@$(call MAKEDIR,$(OBJDIR))
	+@$(MAKETARGET)

mbed_config.h: $(MBED_F)
	cp $< $@

helloworld.c: $(MBED_MAIN)
	cp $< $@
$(OBJDIR): all

else
AS      = arm-none-eabi-gcc
CC      = arm-none-eabi-gcc
CPP     = arm-none-eabi-g++
LD      = arm-none-eabi-gcc
ELF2BIN = arm-none-eabi-objcopy
PREPROC = arm-none-eabi-cpp -E -P -Wl,--gc-sections -Wl,--wrap,main -Wl,--wrap,_malloc_r -Wl,--wrap,_free_r -Wl,--wrap,_realloc_r -Wl,--wrap,_memalign_r -Wl,--wrap,_calloc_r -Wl,--wrap,exit -Wl,--wrap,atexit -Wl,-n -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -DMBED_ROM_START=0x0 -DMBED_ROM_SIZE=0x100000 -DMBED_RAM_START=0x20000000 -DMBED_RAM_SIZE=0x30000 -DMBED_RAM1_START=0x1fff0000 -DMBED_RAM1_SIZE=0x10000 -DMBED_BOOT_STACK_SIZE=1024 -DXIP_ENABLE=0

###### この辺りなんとかする ####### -> どうやらディレクトリが移動して変数が消えたっぽい
DATATYPES = $(EJSVM_DIR)/datatypes/default_32.def
OPERANDSPEC = $(EJSVM_DIR)/operand-spec/any.spec
SUPERINSNSPEC = $(EJSVM_DIR)/superinsn-spec/all.si
SUPERINSNTYPE = 4
PYTHON = python3

HEAPSIZE      = -DJS_SPACE_BYTES=10485760
CFLAGS = -O2 -DNDEBUG -UDEBUG $(HEAPSIZE)
INSNGEN_FLAGS = -Xgen:pad_cases true -Xcmp:opt_pass MR:S -Xcmp:rand_seed 0

################

OPT_REGEXP    = none
OPT_GC        = bibop

### CFLAGS ####
CFLAGS        += -DBIT_INSN32 -DBIT_ALIGN32 -DBIT_JSVALUE32
CFLAGS       += -DUSE_SBC
## GC collects internal nodes in hidden class graph
CFLAGS       += -DHC_SKIP_INTERNAL
## cache shapes at allocation site
CFLAGS       += -DALLOC_SITE_CACHE
## GC collects unused shapes (effective if ALLOC_SITE_CACHE is specified)
CFLAGS       += -DWEAK_SHAPE_LIST
## Do not hold the list of shapes.  Instead, only the largest shape is held.
#CFLAGS       += -DNO_SHAPE_CACHE
## use inlne cache
CFLAGS       += -DINLINE_CACHE

CFLAGS       += -DGC_PROF
## show hidden class related profiling information (make --hc-prof available)
CFLAGS       += -DHC_PROF
## print flonum usage
CFLAGS       += -DFLONUM_SPACE

CFLAGS       += -DNEW_ASIZE_STRATEGY
CFALGS       += -DBIBOP_CACHE_BMP_GRANULES
CFLAGS       += -DBIBOP_SEGREGATE_1PAGE
CFLAGS       += -DBIBOP_2WAY_ALLOC
CFLAGS       += -DBIBOP_FREELIST
CFLAGS       += -DVERIFY_BIBOP
CFLAGS    += -DNO_SRAND

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
ifeq ($(PYTHON),)
    PYTHON = python
endif
ifeq ($(CPP_VMDL),)
    CPP_VMDL=$(CC) $(CFLAGS) -E -x c -P
endif
ifeq ($(COCCINELLE),)
    COCCINELLE = spatch
endif
ifeq ($(OPT_GC),)
# GC=native|boehmgc|none
    OPT_GC=native
endif
#ifeq ($(SUPERINSNSPEC),)
#    SUPERINSNSPEC=none
#endif
#ifeq ($(SUPERINSNTYPE),)
#    SUPERINSNTYPE=4
#endif
ifeq ($(OPT_REGEXP),)
# REGEXP=oniguruma|none
    OPT_REGEXP=none
endif

######################################################
# commands and paths

ifeq ($(SUPERINSNTYPE),)

GOTTA=$(PYTHON) $(EJSVM_DIR)/gotta.py\
    --otspec $(OPERANDSPEC)\
    --insndef $(EJSVM_DIR)/instructions.def
else
GOTTA=$(PYTHON) $(EJSVM_DIR)/gotta.py\
    --sispec $(SUPERINSNSPEC)\
    --otspec $(OPERANDSPEC)\
    --insndef $(EJSVM_DIR)/instructions.def\
    --sitype $(SUPERINSNTYPE)
endif

#SILIST=$(GOTTA) --silist --sispec
SILIST=$(SED) -e 's/^.*: *//'

EJSC_DIR=$(EJSVM_DIR)/../ejsc
EJSC=$(EJSC_DIR)/newejsc.jar

VMGEN_DIR=$(EJSVM_DIR)/../vmgen
VMGEN=$(VMGEN_DIR)/vmgen.jar

VMDL_DIR=$(EJSVM_DIR)/../vmdl
VMDL=$(VMDL_DIR)/vmdlc.jar

EJSI_DIR=$(EJSVM_DIR)/../ejsi
EJSI=$(EJSI_DIR)/ejsi

INSNGEN_VMGEN=java -cp $(VMGEN) vmgen.InsnGen
TYPESGEN_VMGEN=java -cp $(VMGEN) vmgen.TypesGen
INSNGEN_VMDL=java -jar $(VMDL)
TYPESGEN_VMDL=java -cp $(VMDL) vmdlc.TypesGen

ifeq ($(USE_VMDL),true)
SPECGEN=java -cp $(VMDL) vmdlc.SpecFileGen
else
SPECGEN=java -cp $(VMGEN) vmgen.SpecFileGen
endif

CPP=$(CC) -E

CFLAGS += -std=gnu89 -Wall -Wno-unused-label -Wno-unused-result $(INCLUDES)
LIBS   += -lm

ifeq ($(USE_VMDL),true)
CFLAGS += -DUSE_VMDL
CFLAGS_VMDL += -Wno-parentheses-equality -Wno-tautological-constant-out-of-range-compare
endif

######################################################
# superinstructions

ifeq ($(SUPERINSNTYPE),1)      # S1 in Table 1 in JIP Vol.12 No.4 p.5
    SUPERINSN_MAKEINSN=true
    SUPERINSN_CUSTOMIZE_OT=false
    SUPERINSN_PSEUDO_IDEF=false
    SUPERINSN_REORDER_DISPATCH=false
else ifeq ($(SUPERINSNTYPE),2) # S4 in Table 1 in JIP Vol.12 No.4 p.5
    SUPERINSN_MAKEINSN=true
    SUPERINSN_CUSTOMIZE_OT=true
    SUPERINSN_PSEUDO_IDEF=false
    SUPERINSN_REORDER_DISPATCH=false
else ifeq ($(SUPERINSNTYPE),3) # S5 in Table 1 in JIP Vol.12 No.4 p.5
    SUPERINSN_MAKEINSN=true
    SUPERINSN_CUSTOMIZE_OT=true
    SUPERINSN_PSEUDO_IDEF=true
    SUPERINSN_REORDER_DISPATCH=false
else ifeq ($(SUPERINSNTYPE),4) # S3 in Table 1 in JIP Vol.12 No.4 p.5
    SUPERINSN_MAKEINSN=false
    SUPERINSN_CUSTOMIZE_OT=false
    SUPERINSN_PSEUDO_IDEF=false
    SUPERINSN_REORDER_DISPATCH=true
else ifeq ($(SUPERINSNTYPE),5) # S2 in Table 1 in JIP Vol.12 No.4 p.5
    SUPERINSN_MAKEINSN=false
    SUPERINSN_CUSTOMIZE_OT=false
    SUPERINSN_PSEUDO_IDEF=false
    SUPERINSN_REORDER_DISPATCH=false
endif

GENERATED_HFILES = \
    instructions-opcode.h \
    instructions-table.h \
    instructions-label.h \
    specfile-fingerprint.h

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
    gc.h \
    context-inl.h \
    types-inl.h \
    gc-inl.h
ifeq ($(USE_VMDL),true)
    HFILES += vmdl-helper.h
endif

SUPERINSNS = $(shell $(GOTTA) --list-si)

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
    builtin-function.o \
    builtin-performance.o \
	cstring.o \
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
ifeq ($(USE_VMDL),true)
OFILES += vmdl-helper.o
endif

ifeq ($(SUPERINSN_MAKEINSN),true)
    INSN_SUPERINSNS = $(patsubst %,insns/%.inc,$(SUPERINSNS))
endif

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
    insns/unsignedrightshift.inc \
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
    insns/makeclosure.inc \
    insns/makeiterator.inc \
    insns/move.inc \
    insns/newframe.inc \
    insns/exitframe.inc \
    insns/nextpropnameidx.inc \
    insns/not.inc \
    insns/number.inc \
    insns/pushhandler.inc \
    insns/seta.inc \
    insns/setarg.inc \
    insns/setfl.inc \
    insns/setglobal.inc \
    insns/setlocal.inc \
    insns/specconst.inc \
    insns/typeof.inc \
    insns/end.inc \
    insns/localret.inc \
    insns/nop.inc \
    insns/pophandler.inc \
    insns/poplocal.inc \
    insns/ret.inc \
    insns/throw.inc \
    insns/unknown.inc

INSN_HANDCRAFT =

CFILES = $(patsubst %.o,%.c,$(OFILES))
CHECKFILES = $(patsubst %.c,$(CHECKFILES_DIR)/%.c,$(CFILES))
INSN_FILES = $(INSN_SUPERINSNS) $(INSN_GENERATED) $(INSN_HANDCRAFT)

######################################################

ifeq ($(OPT_GC),native)
    CFLAGS+=-DUSE_NATIVEGC=1
    OFILES+=freelist-space.o
    HFILES+=freelist-space.h freelist-space-inl.h
endif
ifeq ($(OPT_GC),bibop)
    CFLAGS+=-DUSE_NATIVEGC=1 -DBIBOP
    OFILES+=bibop-space.o
    HFILES+=bibop-space.h bibop-space-inl.h
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
    GENERATED_HFILES += types-handcraft.h
else
    CFLAGS += -DUSE_TYPES_GENERATED=1
    GENERATED_HFILES += types-generated.h
endif

CHECKFILES_DIR = checkfiles
GCCHECK_PATTERN = $(EJSVM_DIR)/gccheck.cocci

# trick rules into thinking we are in the root, when we are in the bulid dir
VPATH = ..

# Boiler-plate
###############################################################################
# Project settings

PROJECT := mbed


# Project settings
###############################################################################
# Objects and Paths

OBJECTS += ./helloworld.o
OBJECTS += ./mbed-os/cmsis/TARGET_CORTEX_M/mbed_tz_context.o
OBJECTS += ./mbed-os/components/802.15.4_RF/atmel-rf-driver/source/NanostackRfPhyAtmel.o
OBJECTS += ./mbed-os/components/802.15.4_RF/atmel-rf-driver/source/at24mac.o
OBJECTS += ./mbed-os/components/802.15.4_RF/mcr20a-rf-driver/source/MCR20Drv.o
OBJECTS += ./mbed-os/components/802.15.4_RF/mcr20a-rf-driver/source/NanostackRfPhyMcr20a.o
OBJECTS += ./mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source/NanostackRfPhys2lp.o
OBJECTS += ./mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source/at24mac_s2lp.o
OBJECTS += ./mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source/rf_configuration.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_EMUL/psa_attest_inject_key.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_EMUL/psa_initial_attestation_api.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_boot_status_loader.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_crypto.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_crypto_keys.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_iat_claims_loader.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attestation_bootloader_data.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/psa_attestation_stubs.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/psa_inject_attestation_key_impl.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/attest_token.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/attestation_core.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/src/t_cose_sign1_sign.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/src/t_cose_util.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/UsefulBuf.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/ieee754.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/qcbor_decode.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/qcbor_encode.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/platform/COMPONENT_PSA_SRV_EMUL/platform_emul.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/platform/COMPONENT_PSA_SRV_IMPL/platform_srv_impl.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/common/psa_storage_common_impl.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/its/COMPONENT_PSA_SRV_EMUL/psa_prot_internal_storage.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/its/COMPONENT_PSA_SRV_IMPL/pits_impl.o
OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/ps/COMPONENT_NSPE/protected_storage.o
OBJECTS += ./mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP/COMMON/fslittle_test.o
OBJECTS += ./mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP/FlashIAPBlockDevice.o
OBJECTS += ./mbed-os/components/storage/blockdevice/COMPONENT_SD/SDBlockDevice.o
OBJECTS += ./mbed-os/components/wifi/esp8266-driver/ESP8266/ESP8266.o
OBJECTS += ./mbed-os/components/wifi/esp8266-driver/ESP8266Interface.o
OBJECTS += ./mbed-os/drivers/source/AnalogIn.o
OBJECTS += ./mbed-os/drivers/source/AnalogOut.o
OBJECTS += ./mbed-os/drivers/source/BusIn.o
OBJECTS += ./mbed-os/drivers/source/BusInOut.o
OBJECTS += ./mbed-os/drivers/source/BusOut.o
OBJECTS += ./mbed-os/drivers/source/CAN.o
OBJECTS += ./mbed-os/drivers/source/DigitalIn.o
OBJECTS += ./mbed-os/drivers/source/DigitalInOut.o
OBJECTS += ./mbed-os/drivers/source/DigitalOut.o
OBJECTS += ./mbed-os/drivers/source/Ethernet.o
OBJECTS += ./mbed-os/drivers/source/FlashIAP.o
OBJECTS += ./mbed-os/drivers/source/I2C.o
OBJECTS += ./mbed-os/drivers/source/I2CSlave.o
OBJECTS += ./mbed-os/drivers/source/InterruptIn.o
OBJECTS += ./mbed-os/drivers/source/InterruptManager.o
OBJECTS += ./mbed-os/drivers/source/MbedCRC.o
OBJECTS += ./mbed-os/drivers/source/PortIn.o
OBJECTS += ./mbed-os/drivers/source/PortInOut.o
OBJECTS += ./mbed-os/drivers/source/PortOut.o
OBJECTS += ./mbed-os/drivers/source/PwmOut.o
OBJECTS += ./mbed-os/drivers/source/QSPI.o
OBJECTS += ./mbed-os/drivers/source/RawSerial.o
OBJECTS += ./mbed-os/drivers/source/ResetReason.o
OBJECTS += ./mbed-os/drivers/source/SPI.o
OBJECTS += ./mbed-os/drivers/source/SPISlave.o
OBJECTS += ./mbed-os/drivers/source/Serial.o
OBJECTS += ./mbed-os/drivers/source/SerialBase.o
OBJECTS += ./mbed-os/drivers/source/SerialWireOutput.o
OBJECTS += ./mbed-os/drivers/source/TableCRC.o
OBJECTS += ./mbed-os/drivers/source/Ticker.o
OBJECTS += ./mbed-os/drivers/source/Timeout.o
OBJECTS += ./mbed-os/drivers/source/Timer.o
OBJECTS += ./mbed-os/drivers/source/TimerEvent.o
OBJECTS += ./mbed-os/drivers/source/UARTSerial.o
OBJECTS += ./mbed-os/drivers/source/Watchdog.o
OBJECTS += ./mbed-os/drivers/source/usb/AsyncOp.o
OBJECTS += ./mbed-os/drivers/source/usb/ByteBuffer.o
OBJECTS += ./mbed-os/drivers/source/usb/EndpointResolver.o
OBJECTS += ./mbed-os/drivers/source/usb/LinkedListBase.o
OBJECTS += ./mbed-os/drivers/source/usb/OperationListBase.o
OBJECTS += ./mbed-os/drivers/source/usb/PolledQueue.o
OBJECTS += ./mbed-os/drivers/source/usb/TaskBase.o
OBJECTS += ./mbed-os/drivers/source/usb/USBAudio.o
OBJECTS += ./mbed-os/drivers/source/usb/USBCDC.o
OBJECTS += ./mbed-os/drivers/source/usb/USBCDC_ECM.o
OBJECTS += ./mbed-os/drivers/source/usb/USBDevice.o
OBJECTS += ./mbed-os/drivers/source/usb/USBHID.o
OBJECTS += ./mbed-os/drivers/source/usb/USBKeyboard.o
OBJECTS += ./mbed-os/drivers/source/usb/USBMIDI.o
OBJECTS += ./mbed-os/drivers/source/usb/USBMSD.o
OBJECTS += ./mbed-os/drivers/source/usb/USBMouse.o
OBJECTS += ./mbed-os/drivers/source/usb/USBMouseKeyboard.o
OBJECTS += ./mbed-os/drivers/source/usb/USBSerial.o
OBJECTS += ./mbed-os/events/source/EventQueue.o
OBJECTS += ./mbed-os/events/source/equeue.o
OBJECTS += ./mbed-os/events/source/equeue_mbed.o
OBJECTS += ./mbed-os/events/source/equeue_posix.o
OBJECTS += ./mbed-os/events/source/mbed_shared_queues.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/ATHandler.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularBase.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularDevice.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularInformation.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularSMS.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_ControlPlane_netif.o
OBJECTS += ./mbed-os/features/cellular/framework/common/APN_db.o
OBJECTS += ./mbed-os/features/cellular/framework/common/CellularLog.o
OBJECTS += ./mbed-os/features/cellular/framework/common/CellularUtil.o
OBJECTS += ./mbed-os/features/cellular/framework/device/CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/device/CellularDevice.o
OBJECTS += ./mbed-os/features/cellular/framework/device/CellularStateMachine.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP/ALT1250_PPP.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP/ALT1250_PPP_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP/ALT1250_PPP_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION_CellularInformation.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/GENERIC/GENERIC_AT3GPP/GENERIC_AT3GPP.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano/PPP/SARA4_PPP.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano/PPP/SARA4_PPP_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularInformation.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularInformation.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_ControlPlane_netif.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/EC2X/QUECTEL_EC2X.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26_CellularInformation.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/UG96/QUECTEL_UG96.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/UG96/QUECTEL_UG96_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/TELIT/HE910/TELIT_HE910.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/TELIT/ME910/TELIT_ME910.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/TELIT/ME910/TELIT_ME910_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT_CellularNetwork.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX_CellularContext.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX_CellularSMS.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX_CellularStack.o
OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/PPP/UBLOX_PPP.o
OBJECTS += ./mbed-os/features/device_key/source/DeviceKey.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_attestation_intf.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_client_api_empty_intf.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_client_api_intf.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_internal_trusted_storage_intf.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_mbed_os_intf.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_protected_storage_intf.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal_attestation_eat.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_attestation.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_greentea.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_interfaces.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_internal_trusted_storage.o
OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_protected_storage.o
OBJECTS += ./mbed-os/features/frameworks/greentea-client/source/greentea_metrics.o
OBJECTS += ./mbed-os/features/frameworks/greentea-client/source/greentea_serial.o
OBJECTS += ./mbed-os/features/frameworks/greentea-client/source/greentea_test_env.o
OBJECTS += ./mbed-os/features/frameworks/mbed-client-cli/source/ns_cmdline.o
OBJECTS += ./mbed-os/features/frameworks/mbed-client-randlib/source/randLIB.o
OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_builder.o
OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_header_check.o
OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_parser.o
OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_protocol.o
OBJECTS += ./mbed-os/features/frameworks/mbed-trace/source/mbed_trace.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/IPv6_fcf_lib/ip_fsc.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libBits/common_functions.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libList/ns_list.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip4string/ip4tos.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip4string/stoip4.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip6string/ip6tos.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip6string/stoip6.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/nsdynmemLIB/nsdynmemLIB.o
OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/nvmHelper/ns_nvm_helper.o
OBJECTS += ./mbed-os/features/frameworks/unity/source/unity.o
OBJECTS += ./mbed-os/features/frameworks/utest/mbed-utest-shim.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/unity_handler.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_case.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_default_handlers.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_greentea_handlers.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_harness.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_shim.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_stack_trace.o
OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_types.o
OBJECTS += ./mbed-os/features/lorawan/LoRaWANInterface.o
OBJECTS += ./mbed-os/features/lorawan/LoRaWANStack.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMac.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMacChannelPlan.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMacCommand.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMacCrypto.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHY.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYAS923.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYAU915.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYCN470.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYCN779.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYEU433.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYEU868.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYIN865.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYKR920.o
OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYUS915.o
OBJECTS += ./mbed-os/features/lorawan/system/LoRaWANTimer.o
OBJECTS += ./mbed-os/features/lwipstack/LWIPInterface.o
OBJECTS += ./mbed-os/features/lwipstack/LWIPInterfaceEMAC.o
OBJECTS += ./mbed-os/features/lwipstack/LWIPInterfaceL3IP.o
OBJECTS += ./mbed-os/features/lwipstack/LWIPInterfacePPP.o
OBJECTS += ./mbed-os/features/lwipstack/LWIPMemoryManager.o
OBJECTS += ./mbed-os/features/lwipstack/LWIPStack.o
OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/arch/lwip_checksum.o
OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/arch/lwip_memcpy.o
OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/arch/lwip_sys_arch.o
OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/lwip_random.o
OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/lwip_tcp_isn.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_api_lib.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_api_msg.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_err.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_if_api.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_netbuf.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_netdb.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_netifapi.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_sockets.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_tcpip.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_autoip.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_dhcp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_etharp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_icmp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_igmp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_ip4.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_ip4_addr.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_ip4_frag.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_dhcp6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ethip6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_icmp6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_inet6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ip6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ip6_addr.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ip6_frag.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_mld6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_nd6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_altcp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_altcp_alloc.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_altcp_tcp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_def.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_dns.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_inet_chksum.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_init.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_ip.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_mem.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_memp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_netif.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_pbuf.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_raw.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_stats.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_sys.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_tcp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_tcp_in.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_tcp_out.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_timeouts.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_udp.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_bridgeif.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_bridgeif_fdb.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_ethernet.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_lowpan6.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_lowpan6_ble.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_lowpan6_common.o
OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_zepif.o
OBJECTS += ./mbed-os/features/lwipstack/lwip_tools.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto_se.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto_slot_management.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto_storage.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_its_file.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/aes.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/aesni.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/arc4.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/aria.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/asn1parse.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/asn1write.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/base64.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/bignum.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/blowfish.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/camellia.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ccm.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/chacha20.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/chachapoly.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/cipher.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/cipher_wrap.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/cmac.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ctr_drbg.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/des.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/dhm.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecdh.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecdsa.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecjpake.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecp.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecp_curves.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/entropy.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/entropy_poll.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/gcm.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/havege.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/hkdf.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/hmac_drbg.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md2.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md4.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md5.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/memory_buffer_alloc.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/nist_kw.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/oid.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/padlock.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pem.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pk.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pk_wrap.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkcs12.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkcs5.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkparse.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkwrite.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/platform.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/platform_util.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/poly1305.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ripemd160.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/rsa.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/rsa_internal.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/sha1.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/sha256.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/sha512.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/threading.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/timing.o
OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/xtea.o
OBJECTS += ./mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_NSPE/src/psa_hrng.o
OBJECTS += ./mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_PSA_SRV_IMPL/src/default_random_seed.o
OBJECTS += ./mbed-os/features/mbedtls/platform/src/mbed_trng.o
OBJECTS += ./mbed-os/features/mbedtls/platform/src/platform_alt.o
OBJECTS += ./mbed-os/features/mbedtls/platform/src/shared_rng.o
OBJECTS += ./mbed-os/features/mbedtls/src/certs.o
OBJECTS += ./mbed-os/features/mbedtls/src/debug.o
OBJECTS += ./mbed-os/features/mbedtls/src/error.o
OBJECTS += ./mbed-os/features/mbedtls/src/net_sockets.o
OBJECTS += ./mbed-os/features/mbedtls/src/pkcs11.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_cache.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_ciphersuites.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_cli.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_cookie.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_msg.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_srv.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_ticket.o
OBJECTS += ./mbed-os/features/mbedtls/src/ssl_tls.o
OBJECTS += ./mbed-os/features/mbedtls/src/version.o
OBJECTS += ./mbed-os/features/mbedtls/src/version_features.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509_create.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509_crl.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509_crt.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509_csr.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509write_crt.o
OBJECTS += ./mbed-os/features/mbedtls/src/x509write_csr.o
OBJECTS += ./mbed-os/features/mbedtls/targets/hash_wrappers.o
OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_connection_handler.o
OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_message_handler.o
OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_security_handler.o
OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_service_api.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/CallbackHandler.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/LoWPANNDInterface.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/MeshInterfaceNanostack.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackEMACInterface.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackEthernetInterface.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackMemoryManager.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackPPPInterface.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/ThreadInterface.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/WisunInterface.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/ethernet_tasklet.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/mesh_system.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/nd_tasklet.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/thread_tasklet.o
OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/wisun_tasklet.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_fhss_timer.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_interrupt.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_random.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_timer.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_event_loop.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_event_loop_mbed.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_event_loop_mutex.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_hal_init.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/nvm/nvm_ram.o
OBJECTS += ./mbed-os/features/nanostack/nanostack-interface/Nanostack.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/event.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/ns_timeout.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/ns_timer.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/system_timer.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/network_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/protocol_6lowpan.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/protocol_6lowpan_bootstrap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/protocol_6lowpan_interface.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Fragmentation/cipv6_fragmenter.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/6lowpan_iphc.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/iphc_compress.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/iphc_decompress.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/lowpan_context.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/beacon_handler.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_data_poll.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_helper.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_ie_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_pairwise_key.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_response_handler.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Mesh/mesh.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ND/nd_router_object.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/NVM/nwk_nvm.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_bbr_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_bbr_commercial.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_beacon.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_bootstrap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_border_router_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_ccm.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_commissioning_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_commissioning_if.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_common.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_dhcpv6_server.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_diagnostic.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_discovery.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_host_bootstrap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_joiner_application.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_leader_service.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_lowpower_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_lowpower_private_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_client.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_if.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_server.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_mdns.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_meshcop_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_mle_message_handler.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_nd.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_neighbor_class.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_net_config_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_network_data_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_network_data_storage.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_network_synch.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_nvm_store.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_resolution_client.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_resolution_server.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_router_bootstrap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_routing.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_test_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/adaptation_interface.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_bbr_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_bootstrap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_common.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_auth_relay.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_pdu.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_relay.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_relay_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_empty_functions.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_ie_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_llc_data_service.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_management_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_mpx_header.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_neighbor_class.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_auth.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_controller.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_nvm_data.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_nvm_store.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_supp.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_timers.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_stats.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_test_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/BorderRouter/border_router.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/icmpv6.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/icmpv6_prefix.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/icmpv6_radv.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6_flow.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6_fragmentation.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6_resolution.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/mld.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/tcp.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/udp.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/buffer_dyn.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/ns_address_internal.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/ns_monitor.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/ns_socket.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/sockbuf.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_Server/DHCPv6_Server_service.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_client/dhcpv6_client_service.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_fhss_callbacks.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_filter.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_header_helper_functions.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_indirect_data.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_mcps_sap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_mlme.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_pd_sap.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_security_mib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_timer.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/sw_mac.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/ethernet/ethernet_mac_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/rf_driver_storage.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/serial/serial_mac_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/virtual_rf/virtual_rf_client.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/virtual_rf/virtual_rf_driver.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MLE/mle.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MLE/mle_tlv.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MPL/mpl.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_core.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_core_sleep.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_stats.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_timer.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_control.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_data.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_downward.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_mrhof.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_objective.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_of0.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_policy.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_upward.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/Common/security_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/eap_protocol.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_avp.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_client.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_eap_header.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_header.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_relay_table.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_server.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/TLS/tls_ccm_crypt.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/TLS/tls_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/eapol/eapol_helper.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/eapol/kde_helper.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_addr.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_eapol_pdu_if.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_socket_if.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot/auth_eap_tls_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot/eap_tls_sec_prot_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot/supp_eap_tls_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/fwh_sec_prot/auth_fwh_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/fwh_sec_prot/supp_fwh_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/gkh_sec_prot/auth_gkh_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/gkh_sec_prot/supp_gkh_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/key_sec_prot/key_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/sec_prot_certs.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/sec_prot_keys.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/sec_prot_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/tls_sec_prot/tls_sec_prot.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/tls_sec_prot/tls_sec_prot_lib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/CCM_lib/ccm_security.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/CCM_lib/mbedOS/aes_mbedtls_adapter.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Neighbor_cache/neighbor_cache.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/SHA256_Lib/ns_sha256.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/SHA256_Lib/shalib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Trickle/trickle.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/blacklist/blacklist.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/etx/etx.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/channel_functions.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/channel_list.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_channel.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_common.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_configuration_interface.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_statistics.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_test_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_ws.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_ws_empty_functions.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fnv_hash/fnv_hash.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/hmac/hmac_sha1.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/ieee_802_11/ieee_802_11.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/load_balance/load_balance.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mac_neighbor_table/mac_neighbor_table.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/mdns/fnet_mdns.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/poll/fnet_poll.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/stack/fnet_stdlib.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/ns_fnet_events.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/ns_fnet_port.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/ns_mdns_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_buffer.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_frame_counter_table.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_interface.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_security.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nd_proxy/nd_proxy.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nist_aes_kw/nist_aes_kw.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/pan_blacklist/pan_blacklist.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/isqrt.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/ns_conf.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/ns_crc.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/ns_file_system.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/whiteboard/whiteboard.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/ipv6_stack/ipv6_routing_table.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/ipv6_stack/protocol_ipv6.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6/dhcp_service_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6/libDHCPv6.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6/libDHCPv6_server.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/multicast_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_6lowpan_parameter_api.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_ipv6.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_load_balance.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_mle.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_rpl.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_short_address_extension.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_test.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/ns_net.o
OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/socket_api.o
OBJECTS += ./mbed-os/features/netsocket/DTLSSocket.o
OBJECTS += ./mbed-os/features/netsocket/DTLSSocketWrapper.o
OBJECTS += ./mbed-os/features/netsocket/EMACInterface.o
OBJECTS += ./mbed-os/features/netsocket/EthernetInterface.o
OBJECTS += ./mbed-os/features/netsocket/ICMPSocket.o
OBJECTS += ./mbed-os/features/netsocket/InternetDatagramSocket.o
OBJECTS += ./mbed-os/features/netsocket/InternetSocket.o
OBJECTS += ./mbed-os/features/netsocket/L3IPInterface.o
OBJECTS += ./mbed-os/features/netsocket/NetStackMemoryManager.o
OBJECTS += ./mbed-os/features/netsocket/NetworkInterface.o
OBJECTS += ./mbed-os/features/netsocket/NetworkInterfaceDefaults.o
OBJECTS += ./mbed-os/features/netsocket/NetworkStack.o
OBJECTS += ./mbed-os/features/netsocket/PPPInterface.o
OBJECTS += ./mbed-os/features/netsocket/SocketAddress.o
OBJECTS += ./mbed-os/features/netsocket/SocketStats.o
OBJECTS += ./mbed-os/features/netsocket/TCPServer.o
OBJECTS += ./mbed-os/features/netsocket/TCPSocket.o
OBJECTS += ./mbed-os/features/netsocket/TLSSocket.o
OBJECTS += ./mbed-os/features/netsocket/TLSSocketWrapper.o
OBJECTS += ./mbed-os/features/netsocket/UDPSocket.o
OBJECTS += ./mbed-os/features/netsocket/WiFiAccessPoint.o
OBJECTS += ./mbed-os/features/netsocket/cellular/CellularNonIPSocket.o
OBJECTS += ./mbed-os/features/netsocket/emac-drivers/TARGET_Freescale_EMAC/TARGET_K64F/hardware_init_MK64F12.o
OBJECTS += ./mbed-os/features/netsocket/emac-drivers/TARGET_Freescale_EMAC/kinetis_emac.o
OBJECTS += ./mbed-os/features/netsocket/nsapi_dns.o
OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_arc4.o
OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_des.o
OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_md4.o
OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_md5.o
OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_sha1.o
OBJECTS += ./mbed-os/features/netsocket/ppp/ppp_nsapi.o
OBJECTS += ./mbed-os/features/netsocket/ppp/ppp_service.o
OBJECTS += ./mbed-os/features/netsocket/ppp/ppp_service_if.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/auth.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/ccp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/chap-md5.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/chap-new.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/chap_ms.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/demand.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/eap.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/eui64.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/fsm.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/ipcp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/ipv6cp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/lcp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/magic.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/mppe.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/multilink.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/ppp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/ppp_ecp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppapi.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppcrypt.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppoe.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppol2tp.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppos.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/upap.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/utils.o
OBJECTS += ./mbed-os/features/netsocket/ppp/source/vj.o
OBJECTS += ./mbed-os/features/nfc/acore/source/ac_buffer.o
OBJECTS += ./mbed-os/features/nfc/acore/source/ac_buffer_builder.o
OBJECTS += ./mbed-os/features/nfc/acore/source/ac_buffer_reader.o
OBJECTS += ./mbed-os/features/nfc/acore/source/ac_stream.o
OBJECTS += ./mbed-os/features/nfc/source/controllers/PN512Driver.o
OBJECTS += ./mbed-os/features/nfc/source/controllers/PN512SPITransportDriver.o
OBJECTS += ./mbed-os/features/nfc/source/controllers/PN512TransportDriver.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCController.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCControllerDriver.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCEEPROM.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCEEPROMDriver.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCNDEFCapable.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCRemoteEndpoint.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCRemoteInitiator.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCTarget.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/Type4RemoteInitiator.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/MessageBuilder.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/MessageParser.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/RecordParser.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/Mime.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/SimpleMessageParser.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/Text.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/URI.o
OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/util.o
OBJECTS += ./mbed-os/features/nfc/stack/ndef/ndef.o
OBJECTS += ./mbed-os/features/nfc/stack/platform/nfc_scheduler.o
OBJECTS += ./mbed-os/features/nfc/stack/platform/nfc_transport.o
OBJECTS += ./mbed-os/features/nfc/stack/tech/iso7816/iso7816.o
OBJECTS += ./mbed-os/features/nfc/stack/tech/iso7816/iso7816_app.o
OBJECTS += ./mbed-os/features/nfc/stack/tech/isodep/isodep_target.o
OBJECTS += ./mbed-os/features/nfc/stack/tech/type4/type4_target.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_cmd.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_hw.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_irq.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_poll.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_registers.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_rf.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_timer.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_transceive.o
OBJECTS += ./mbed-os/features/nfc/stack/transceiver/transceiver.o
OBJECTS += ./mbed-os/features/storage/blockdevice/BufferedBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/ChainingBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/ExhaustibleBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/FlashSimBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/HeapBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/MBRBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/ObservingBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/ProfilingBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/ReadOnlyBlockDevice.o
OBJECTS += ./mbed-os/features/storage/blockdevice/SlicingBlockDevice.o
OBJECTS += ./mbed-os/features/storage/filesystem/Dir.o
OBJECTS += ./mbed-os/features/storage/filesystem/File.o
OBJECTS += ./mbed-os/features/storage/filesystem/FileSystem.o
OBJECTS += ./mbed-os/features/storage/filesystem/fat/ChaN/ff.o
OBJECTS += ./mbed-os/features/storage/filesystem/fat/ChaN/ffunicode.o
OBJECTS += ./mbed-os/features/storage/filesystem/fat/FATFileSystem.o
OBJECTS += ./mbed-os/features/storage/filesystem/littlefs/LittleFileSystem.o
OBJECTS += ./mbed-os/features/storage/filesystem/littlefs/littlefs/lfs.o
OBJECTS += ./mbed-os/features/storage/filesystem/littlefs/littlefs/lfs_util.o
OBJECTS += ./mbed-os/features/storage/kvstore/conf/kv_config.o
OBJECTS += ./mbed-os/features/storage/kvstore/direct_access_devicekey/DirectAccessDevicekey.o
OBJECTS += ./mbed-os/features/storage/kvstore/filesystemstore/FileSystemStore.o
OBJECTS += ./mbed-os/features/storage/kvstore/global_api/kvstore_global_api.o
OBJECTS += ./mbed-os/features/storage/kvstore/kv_map/KVMap.o
OBJECTS += ./mbed-os/features/storage/kvstore/securestore/SecureStore.o
OBJECTS += ./mbed-os/features/storage/kvstore/tdbstore/TDBStore.o
OBJECTS += ./mbed-os/features/storage/nvstore/source/nvstore.o
OBJECTS += ./mbed-os/features/storage/system_storage/SystemStorage.o
OBJECTS += ./mbed-os/hal/LowPowerTickerWrapper.o
OBJECTS += ./mbed-os/hal/mbed_compat.o
OBJECTS += ./mbed-os/hal/mbed_critical_section_api.o
OBJECTS += ./mbed-os/hal/mbed_flash_api.o
OBJECTS += ./mbed-os/hal/mbed_gpio.o
OBJECTS += ./mbed-os/hal/mbed_gpio_irq.o
OBJECTS += ./mbed-os/hal/mbed_itm_api.o
OBJECTS += ./mbed-os/hal/mbed_lp_ticker_api.o
OBJECTS += ./mbed-os/hal/mbed_lp_ticker_wrapper.o
OBJECTS += ./mbed-os/hal/mbed_pinmap_common.o
OBJECTS += ./mbed-os/hal/mbed_pinmap_default.o
OBJECTS += ./mbed-os/hal/mbed_ticker_api.o
OBJECTS += ./mbed-os/hal/mbed_us_ticker_api.o
OBJECTS += ./mbed-os/hal/mpu/mbed_mpu_v7m.o
OBJECTS += ./mbed-os/hal/mpu/mbed_mpu_v8m.o
OBJECTS += ./mbed-os/hal/static_pinmap.o
OBJECTS += ./mbed-os/hal/usb/mbed_usb_phy.o
OBJECTS += ./mbed-os/platform/cxxsupport/mstd_mutex.o
OBJECTS += ./mbed-os/platform/source/ATCmdParser.o
OBJECTS += ./mbed-os/platform/source/CThunkBase.o
OBJECTS += ./mbed-os/platform/source/CallChain.o
OBJECTS += ./mbed-os/platform/source/CriticalSectionLock.o
OBJECTS += ./mbed-os/platform/source/DeepSleepLock.o
OBJECTS += ./mbed-os/platform/source/FileBase.o
OBJECTS += ./mbed-os/platform/source/FileHandle.o
OBJECTS += ./mbed-os/platform/source/FilePath.o
OBJECTS += ./mbed-os/platform/source/FileSystemHandle.o
OBJECTS += ./mbed-os/platform/source/LocalFileSystem.o
OBJECTS += ./mbed-os/platform/source/Stream.o
OBJECTS += ./mbed-os/platform/source/SysTimer.o
OBJECTS += ./mbed-os/platform/source/TARGET_CORTEX_M/TOOLCHAIN_GCC/except.o
OBJECTS += ./mbed-os/platform/source/TARGET_CORTEX_M/mbed_fault_handler.o
OBJECTS += ./mbed-os/platform/source/mbed_alloc_wrappers.o
OBJECTS += ./mbed-os/platform/source/mbed_application.o
OBJECTS += ./mbed-os/platform/source/mbed_assert.o
OBJECTS += ./mbed-os/platform/source/mbed_atomic_impl.o
OBJECTS += ./mbed-os/platform/source/mbed_board.o
OBJECTS += ./mbed-os/platform/source/mbed_critical.o
OBJECTS += ./mbed-os/platform/source/mbed_error.o
OBJECTS += ./mbed-os/platform/source/mbed_error_hist.o
OBJECTS += ./mbed-os/platform/source/mbed_interface.o
OBJECTS += ./mbed-os/platform/source/mbed_mem_trace.o
OBJECTS += ./mbed-os/platform/source/mbed_mktime.o
OBJECTS += ./mbed-os/platform/source/mbed_mpu_mgmt.o
OBJECTS += ./mbed-os/platform/source/mbed_os_timer.o
OBJECTS += ./mbed-os/platform/source/mbed_poll.o
OBJECTS += ./mbed-os/platform/source/mbed_power_mgmt.o
OBJECTS += ./mbed-os/platform/source/mbed_retarget.o
OBJECTS += ./mbed-os/platform/source/mbed_rtc_time.o
OBJECTS += ./mbed-os/platform/source/mbed_sdk_boot.o
OBJECTS += ./mbed-os/platform/source/mbed_semihost_api.o
OBJECTS += ./mbed-os/platform/source/mbed_stats.o
OBJECTS += ./mbed-os/platform/source/mbed_thread.o
OBJECTS += ./mbed-os/platform/source/mbed_wait_api_no_rtos.o
OBJECTS += ./mbed-os/platform/source/mbed_wait_api_rtos.o
OBJECTS += ./mbed-os/platform/source/minimal-printf/mbed_printf_armlink_overrides.o
OBJECTS += ./mbed-os/platform/source/minimal-printf/mbed_printf_implementation.o
OBJECTS += ./mbed-os/platform/source/minimal-printf/mbed_printf_wrapper.o
OBJECTS += ./mbed-os/rtos/source/ConditionVariable.o
OBJECTS += ./mbed-os/rtos/source/EventFlags.o
OBJECTS += ./mbed-os/rtos/source/Kernel.o
OBJECTS += ./mbed-os/rtos/source/Mutex.o
OBJECTS += ./mbed-os/rtos/source/RtosTimer.o
OBJECTS += ./mbed-os/rtos/source/Semaphore.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/TOOLCHAIN_GCC_ARM/mbed_boot_gcc_arm.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_boot.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_rtos_rtx.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_rtx_handlers.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_rtx_idle.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx4/cmsis_os1.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Config/RTX_Config.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/TOOLCHAIN_GCC/TARGET_RTOS_M4_M7/irq_cm4f.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_delay.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_evflags.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_evr.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_kernel.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_lib.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_memory.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_mempool.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_msgqueue.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_mutex.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_semaphore.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_system.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_thread.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_timer.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/Source/os_systick.o
OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/Source/os_tick_ptim.o
OBJECTS += ./mbed-os/rtos/source/ThisThread.o
OBJECTS += ./mbed-os/rtos/source/Thread.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/PeripheralPins.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/crc.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/fsl_clock_config.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/fsl_phy.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/mbed_overrides.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device/TOOLCHAIN_GCC_ARM/startup_MK64F12.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device/system_MK64F12.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_adc16.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_clock.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_cmp.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_cmt.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_crc.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dac.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dmamux.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dspi.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dspi_edma.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_edma.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_enet.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_ewm.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_flash.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_flexbus.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_flexcan.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_ftm.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_gpio.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_i2c.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_i2c_edma.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_llwu.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_lptmr.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_pdb.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_pit.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_pmc.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_rcm.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_rnga.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_rtc.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sai.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sai_edma.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sdhc.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sim.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_smc.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sysmpu.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_uart.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_uart_edma.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_vref.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_wdog.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/mbed_crc_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/pwmout_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/reset_reason.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/serial_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/spi_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/storage_driver.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/trng_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/us_ticker.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/watchdog_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/analogin_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/analogout_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/dma_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/flash_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/gpio_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/gpio_irq_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/i2c_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/lp_ticker.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/pinmap.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/port_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/qspi_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/rtc_api.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/sleep.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/fsl_common.o
OBJECTS += ./mbed-os/targets/TARGET_Freescale/USBPhy_Kinetis.o

 SYS_OBJECTS += ./mbed-os/cmsis/TARGET_CORTEX_M/mbed_tz_context.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/atmel-rf-driver/source/NanostackRfPhyAtmel.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/atmel-rf-driver/source/at24mac.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/mcr20a-rf-driver/source/MCR20Drv.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/mcr20a-rf-driver/source/NanostackRfPhyMcr20a.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source/NanostackRfPhys2lp.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source/at24mac_s2lp.o
 SYS_OBJECTS += ./mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source/rf_configuration.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_EMUL/psa_attest_inject_key.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_EMUL/psa_initial_attestation_api.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_boot_status_loader.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_crypto.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_crypto_keys.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attest_iat_claims_loader.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/attestation_bootloader_data.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/psa_attestation_stubs.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/psa_inject_attestation_key_impl.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/attest_token.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/attestation_core.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/src/t_cose_sign1_sign.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/src/t_cose_util.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/UsefulBuf.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/ieee754.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/qcbor_decode.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/attestation/qcbor/src/qcbor_encode.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/platform/COMPONENT_PSA_SRV_EMUL/platform_emul.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/platform/COMPONENT_PSA_SRV_IMPL/platform_srv_impl.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/common/psa_storage_common_impl.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/its/COMPONENT_PSA_SRV_EMUL/psa_prot_internal_storage.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/its/COMPONENT_PSA_SRV_IMPL/pits_impl.o
 SYS_OBJECTS += ./mbed-os/components/TARGET_PSA/services/storage/ps/COMPONENT_NSPE/protected_storage.o
 SYS_OBJECTS += ./mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP/COMMON/fslittle_test.o
 SYS_OBJECTS += ./mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP/FlashIAPBlockDevice.o
 SYS_OBJECTS += ./mbed-os/components/storage/blockdevice/COMPONENT_SD/SDBlockDevice.o
 SYS_OBJECTS += ./mbed-os/components/wifi/esp8266-driver/ESP8266/ESP8266.o
 SYS_OBJECTS += ./mbed-os/components/wifi/esp8266-driver/ESP8266Interface.o
 SYS_OBJECTS += ./mbed-os/drivers/source/AnalogIn.o
 SYS_OBJECTS += ./mbed-os/drivers/source/AnalogOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/BusIn.o
 SYS_OBJECTS += ./mbed-os/drivers/source/BusInOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/BusOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/CAN.o
 SYS_OBJECTS += ./mbed-os/drivers/source/DigitalIn.o
 SYS_OBJECTS += ./mbed-os/drivers/source/DigitalInOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/DigitalOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/Ethernet.o
 SYS_OBJECTS += ./mbed-os/drivers/source/FlashIAP.o
 SYS_OBJECTS += ./mbed-os/drivers/source/I2C.o
 SYS_OBJECTS += ./mbed-os/drivers/source/I2CSlave.o
 SYS_OBJECTS += ./mbed-os/drivers/source/InterruptIn.o
 SYS_OBJECTS += ./mbed-os/drivers/source/InterruptManager.o
 SYS_OBJECTS += ./mbed-os/drivers/source/MbedCRC.o
 SYS_OBJECTS += ./mbed-os/drivers/source/PortIn.o
 SYS_OBJECTS += ./mbed-os/drivers/source/PortInOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/PortOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/PwmOut.o
 SYS_OBJECTS += ./mbed-os/drivers/source/QSPI.o
 SYS_OBJECTS += ./mbed-os/drivers/source/RawSerial.o
 SYS_OBJECTS += ./mbed-os/drivers/source/ResetReason.o
 SYS_OBJECTS += ./mbed-os/drivers/source/SPI.o
 SYS_OBJECTS += ./mbed-os/drivers/source/SPISlave.o
 SYS_OBJECTS += ./mbed-os/drivers/source/Serial.o
 SYS_OBJECTS += ./mbed-os/drivers/source/SerialBase.o
 SYS_OBJECTS += ./mbed-os/drivers/source/SerialWireOutput.o
 SYS_OBJECTS += ./mbed-os/drivers/source/TableCRC.o
 SYS_OBJECTS += ./mbed-os/drivers/source/Ticker.o
 SYS_OBJECTS += ./mbed-os/drivers/source/Timeout.o
 SYS_OBJECTS += ./mbed-os/drivers/source/Timer.o
 SYS_OBJECTS += ./mbed-os/drivers/source/TimerEvent.o
 SYS_OBJECTS += ./mbed-os/drivers/source/UARTSerial.o
 SYS_OBJECTS += ./mbed-os/drivers/source/Watchdog.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/AsyncOp.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/ByteBuffer.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/EndpointResolver.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/LinkedListBase.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/OperationListBase.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/PolledQueue.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/TaskBase.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBAudio.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBCDC.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBCDC_ECM.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBDevice.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBHID.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBKeyboard.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBMIDI.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBMSD.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBMouse.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBMouseKeyboard.o
 SYS_OBJECTS += ./mbed-os/drivers/source/usb/USBSerial.o
 SYS_OBJECTS += ./mbed-os/events/source/EventQueue.o
 SYS_OBJECTS += ./mbed-os/events/source/equeue.o
 SYS_OBJECTS += ./mbed-os/events/source/equeue_mbed.o
 SYS_OBJECTS += ./mbed-os/events/source/equeue_posix.o
 SYS_OBJECTS += ./mbed-os/events/source/mbed_shared_queues.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/ATHandler.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularBase.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularDevice.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularInformation.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularSMS.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/AT/AT_ControlPlane_netif.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/common/APN_db.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/common/CellularLog.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/common/CellularUtil.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/device/CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/device/CellularDevice.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/device/CellularStateMachine.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP/ALT1250_PPP.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP/ALT1250_PPP_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP/ALT1250_PPP_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION_CellularInformation.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION/GEMALTO_CINTERION_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/GENERIC/GENERIC_AT3GPP/GENERIC_AT3GPP.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano/PPP/SARA4_PPP.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano/PPP/SARA4_PPP_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularInformation.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BC95/QUECTEL_BC95_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularInformation.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/BG96/QUECTEL_BG96_ControlPlane_netif.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/EC2X/QUECTEL_EC2X.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26_CellularInformation.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/M26/QUECTEL_M26_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/UG96/QUECTEL_UG96.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/QUECTEL/UG96/QUECTEL_UG96_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/RiotMicro/AT/RM1000_AT_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/TELIT/HE910/TELIT_HE910.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/TELIT/ME910/TELIT_ME910.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/TELIT/ME910/TELIT_ME910_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT_CellularNetwork.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/AT/UBLOX_AT_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX_CellularContext.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX_CellularSMS.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/N2XX/UBLOX_N2XX_CellularStack.o
 SYS_OBJECTS += ./mbed-os/features/cellular/framework/targets/UBLOX/PPP/UBLOX_PPP.o
 SYS_OBJECTS += ./mbed-os/features/device_key/source/DeviceKey.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_attestation_intf.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_client_api_empty_intf.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_client_api_intf.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_internal_trusted_storage_intf.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_mbed_os_intf.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal/pal_protected_storage_intf.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/pal_attestation_eat.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_attestation.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_greentea.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_interfaces.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_internal_trusted_storage.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/TARGET_PSA/val_protected_storage.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/greentea-client/source/greentea_metrics.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/greentea-client/source/greentea_serial.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/greentea-client/source/greentea_test_env.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-client-cli/source/ns_cmdline.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-client-randlib/source/randLIB.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_builder.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_header_check.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_parser.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-coap/source/sn_coap_protocol.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/mbed-trace/source/mbed_trace.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/IPv6_fcf_lib/ip_fsc.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libBits/common_functions.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libList/ns_list.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip4string/ip4tos.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip4string/stoip4.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip6string/ip6tos.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/libip6string/stoip6.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/nsdynmemLIB/nsdynmemLIB.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/nanostack-libservice/source/nvmHelper/ns_nvm_helper.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/unity/source/unity.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/mbed-utest-shim.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/unity_handler.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_case.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_default_handlers.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_greentea_handlers.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_harness.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_shim.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_stack_trace.o
 SYS_OBJECTS += ./mbed-os/features/frameworks/utest/source/utest_types.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/LoRaWANInterface.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/LoRaWANStack.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMac.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMacChannelPlan.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMacCommand.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/mac/LoRaMacCrypto.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHY.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYAS923.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYAU915.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYCN470.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYCN779.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYEU433.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYEU868.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYIN865.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYKR920.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/lorastack/phy/LoRaPHYUS915.o
 SYS_OBJECTS += ./mbed-os/features/lorawan/system/LoRaWANTimer.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/LWIPInterface.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/LWIPInterfaceEMAC.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/LWIPInterfaceL3IP.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/LWIPInterfacePPP.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/LWIPMemoryManager.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/LWIPStack.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/arch/lwip_checksum.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/arch/lwip_memcpy.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/arch/lwip_sys_arch.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/lwip_random.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip-sys/lwip_tcp_isn.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_api_lib.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_api_msg.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_err.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_if_api.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_netbuf.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_netdb.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_netifapi.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_sockets.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/api/lwip_tcpip.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_autoip.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_dhcp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_etharp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_icmp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_igmp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_ip4.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_ip4_addr.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv4/lwip_ip4_frag.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_dhcp6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ethip6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_icmp6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_inet6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ip6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ip6_addr.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_ip6_frag.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_mld6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/ipv6/lwip_nd6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_altcp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_altcp_alloc.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_altcp_tcp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_def.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_dns.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_inet_chksum.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_init.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_ip.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_mem.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_memp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_netif.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_pbuf.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_raw.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_stats.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_sys.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_tcp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_tcp_in.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_tcp_out.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_timeouts.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/core/lwip_udp.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_bridgeif.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_bridgeif_fdb.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_ethernet.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_lowpan6.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_lowpan6_ble.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_lowpan6_common.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip/src/netif/lwip_zepif.o
 SYS_OBJECTS += ./mbed-os/features/lwipstack/lwip_tools.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto_se.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto_slot_management.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_crypto_storage.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/psa_its_file.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/aes.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/aesni.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/arc4.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/aria.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/asn1parse.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/asn1write.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/base64.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/bignum.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/blowfish.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/camellia.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ccm.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/chacha20.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/chachapoly.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/cipher.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/cipher_wrap.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/cmac.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ctr_drbg.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/des.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/dhm.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecdh.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecdsa.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecjpake.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecp.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ecp_curves.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/entropy.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/entropy_poll.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/gcm.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/havege.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/hkdf.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/hmac_drbg.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md2.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md4.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/md5.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/memory_buffer_alloc.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/nist_kw.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/oid.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/padlock.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pem.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pk.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pk_wrap.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkcs12.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkcs5.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkparse.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/pkwrite.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/platform.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/platform_util.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/poly1305.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/ripemd160.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/rsa.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/rsa_internal.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/sha1.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/sha256.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/sha512.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/threading.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/timing.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/mbed-crypto/src/xtea.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_NSPE/src/psa_hrng.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_PSA_SRV_IMPL/src/default_random_seed.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/platform/src/mbed_trng.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/platform/src/platform_alt.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/platform/src/shared_rng.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/certs.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/debug.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/error.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/net_sockets.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/pkcs11.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_cache.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_ciphersuites.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_cli.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_cookie.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_msg.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_srv.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_ticket.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/ssl_tls.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/version.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/version_features.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509_create.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509_crl.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509_crt.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509_csr.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509write_crt.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/src/x509write_csr.o
 SYS_OBJECTS += ./mbed-os/features/mbedtls/targets/hash_wrappers.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_connection_handler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_message_handler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_security_handler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/coap-service/source/coap_service_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/CallbackHandler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/LoWPANNDInterface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/MeshInterfaceNanostack.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackEMACInterface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackEthernetInterface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackMemoryManager.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/NanostackPPPInterface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/ThreadInterface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/WisunInterface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/ethernet_tasklet.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/mesh_system.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/nd_tasklet.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/thread_tasklet.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/mbed-mesh-api/source/wisun_tasklet.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_fhss_timer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_interrupt.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_random.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/arm_hal_timer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_event_loop.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_event_loop_mbed.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_event_loop_mutex.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/ns_hal_init.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos/nvm/nvm_ram.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/nanostack-interface/Nanostack.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/event.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/ns_timeout.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/ns_timer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source/system_timer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/network_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/protocol_6lowpan.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/protocol_6lowpan_bootstrap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps/Generic/protocol_6lowpan_interface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Fragmentation/cipv6_fragmenter.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/6lowpan_iphc.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/iphc_compress.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/iphc_decompress.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode/lowpan_context.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/beacon_handler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_data_poll.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_helper.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_ie_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_pairwise_key.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC/mac_response_handler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Mesh/mesh.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ND/nd_router_object.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/NVM/nwk_nvm.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_bbr_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_bbr_commercial.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_beacon.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_bootstrap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_border_router_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_ccm.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_commissioning_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_commissioning_if.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_common.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_dhcpv6_server.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_diagnostic.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_discovery.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_host_bootstrap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_joiner_application.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_leader_service.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_lowpower_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_lowpower_private_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_client.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_if.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_management_server.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_mdns.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_meshcop_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_mle_message_handler.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_nd.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_neighbor_class.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_net_config_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_network_data_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_network_data_storage.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_network_synch.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_nvm_store.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_resolution_client.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_resolution_server.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_router_bootstrap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_routing.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread/thread_test_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/adaptation_interface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_bbr_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_bootstrap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_common.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_auth_relay.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_pdu.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_relay.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_eapol_relay_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_empty_functions.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_ie_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_llc_data_service.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_management_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_mpx_header.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_neighbor_class.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_auth.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_controller.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_nvm_data.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_nvm_store.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_supp.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_pae_timers.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_stats.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws/ws_test_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/BorderRouter/border_router.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/icmpv6.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/icmpv6_prefix.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/icmpv6_radv.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6_flow.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6_fragmentation.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/ipv6_resolution.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/mld.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/tcp.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols/udp.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/buffer_dyn.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/ns_address_internal.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/ns_monitor.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/ns_socket.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Core/sockbuf.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_Server/DHCPv6_Server_service.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_client/dhcpv6_client_service.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_fhss_callbacks.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_filter.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_header_helper_functions.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_indirect_data.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_mcps_sap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_mlme.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_pd_sap.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_security_mib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/mac_timer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4/sw_mac.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/ethernet/ethernet_mac_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/rf_driver_storage.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/serial/serial_mac_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/virtual_rf/virtual_rf_client.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/virtual_rf/virtual_rf_driver.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MLE/mle.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MLE/mle_tlv.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/MPL/mpl.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_core.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_core_sleep.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_stats.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/protocol_timer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_control.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_data.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_downward.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_mrhof.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_objective.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_of0.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_policy.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/RPL/rpl_upward.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/Common/security_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/eap_protocol.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_avp.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_client.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_eap_header.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_header.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_relay_table.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA/pana_server.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/TLS/tls_ccm_crypt.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/TLS/tls_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/eapol/eapol_helper.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/eapol/kde_helper.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_addr.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_eapol_pdu_if.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp/kmp_socket_if.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot/auth_eap_tls_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot/eap_tls_sec_prot_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot/supp_eap_tls_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/fwh_sec_prot/auth_fwh_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/fwh_sec_prot/supp_fwh_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/gkh_sec_prot/auth_gkh_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/gkh_sec_prot/supp_gkh_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/key_sec_prot/key_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/sec_prot_certs.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/sec_prot_keys.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/sec_prot_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/tls_sec_prot/tls_sec_prot.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/tls_sec_prot/tls_sec_prot_lib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/CCM_lib/ccm_security.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/CCM_lib/mbedOS/aes_mbedtls_adapter.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Neighbor_cache/neighbor_cache.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/SHA256_Lib/ns_sha256.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/SHA256_Lib/shalib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Trickle/trickle.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/blacklist/blacklist.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/etx/etx.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/channel_functions.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/channel_list.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_channel.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_common.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_configuration_interface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_statistics.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_test_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_ws.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss/fhss_ws_empty_functions.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fnv_hash/fnv_hash.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/hmac/hmac_sha1.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/ieee_802_11/ieee_802_11.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/load_balance/load_balance.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mac_neighbor_table/mac_neighbor_table.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/mdns/fnet_mdns.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/poll/fnet_poll.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/stack/fnet_stdlib.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/ns_fnet_events.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/ns_fnet_port.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/ns_mdns_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_buffer.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_frame_counter_table.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_interface.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service/mle_service_security.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nd_proxy/nd_proxy.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nist_aes_kw/nist_aes_kw.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/pan_blacklist/pan_blacklist.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/isqrt.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/ns_conf.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/ns_crc.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils/ns_file_system.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/whiteboard/whiteboard.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/ipv6_stack/ipv6_routing_table.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/ipv6_stack/protocol_ipv6.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6/dhcp_service_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6/libDHCPv6.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6/libDHCPv6_server.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/multicast_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_6lowpan_parameter_api.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_ipv6.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_load_balance.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_mle.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_rpl.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_short_address_extension.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/net_test.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/ns_net.o
 SYS_OBJECTS += ./mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src/socket_api.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/DTLSSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/DTLSSocketWrapper.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/EMACInterface.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/EthernetInterface.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ICMPSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/InternetDatagramSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/InternetSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/L3IPInterface.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/NetStackMemoryManager.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/NetworkInterface.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/NetworkInterfaceDefaults.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/NetworkStack.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/PPPInterface.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/SocketAddress.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/SocketStats.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/TCPServer.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/TCPSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/TLSSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/TLSSocketWrapper.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/UDPSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/WiFiAccessPoint.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/cellular/CellularNonIPSocket.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/emac-drivers/TARGET_Freescale_EMAC/TARGET_K64F/hardware_init_MK64F12.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/emac-drivers/TARGET_Freescale_EMAC/kinetis_emac.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/nsapi_dns.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_arc4.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_des.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_md4.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_md5.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/polarssl/ppp_sha1.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/ppp_nsapi.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/ppp_service.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/ppp_service_if.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/auth.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/ccp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/chap-md5.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/chap-new.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/chap_ms.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/demand.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/eap.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/eui64.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/fsm.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/ipcp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/ipv6cp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/lcp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/magic.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/mppe.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/multilink.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/ppp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/ppp_ecp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppapi.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppcrypt.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppoe.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppol2tp.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/pppos.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/upap.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/utils.o
 SYS_OBJECTS += ./mbed-os/features/netsocket/ppp/source/vj.o
 SYS_OBJECTS += ./mbed-os/features/nfc/acore/source/ac_buffer.o
 SYS_OBJECTS += ./mbed-os/features/nfc/acore/source/ac_buffer_builder.o
 SYS_OBJECTS += ./mbed-os/features/nfc/acore/source/ac_buffer_reader.o
 SYS_OBJECTS += ./mbed-os/features/nfc/acore/source/ac_stream.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/controllers/PN512Driver.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/controllers/PN512SPITransportDriver.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/controllers/PN512TransportDriver.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCController.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCControllerDriver.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCEEPROM.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCEEPROMDriver.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCNDEFCapable.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCRemoteEndpoint.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCRemoteInitiator.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/NFCTarget.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/Type4RemoteInitiator.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/MessageBuilder.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/MessageParser.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/RecordParser.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/Mime.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/SimpleMessageParser.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/Text.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/URI.o
 SYS_OBJECTS += ./mbed-os/features/nfc/source/nfc/ndef/common/util.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/ndef/ndef.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/platform/nfc_scheduler.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/platform/nfc_transport.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/tech/iso7816/iso7816.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/tech/iso7816/iso7816_app.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/tech/isodep/isodep_target.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/tech/type4/type4_target.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_cmd.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_hw.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_irq.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_poll.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_registers.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_rf.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_timer.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/pn512/pn512_transceive.o
 SYS_OBJECTS += ./mbed-os/features/nfc/stack/transceiver/transceiver.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/BufferedBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/ChainingBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/ExhaustibleBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/FlashSimBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/HeapBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/MBRBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/ObservingBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/ProfilingBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/ReadOnlyBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/blockdevice/SlicingBlockDevice.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/Dir.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/File.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/FileSystem.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/fat/ChaN/ff.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/fat/ChaN/ffunicode.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/fat/FATFileSystem.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/littlefs/LittleFileSystem.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/littlefs/littlefs/lfs.o
 SYS_OBJECTS += ./mbed-os/features/storage/filesystem/littlefs/littlefs/lfs_util.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/conf/kv_config.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/direct_access_devicekey/DirectAccessDevicekey.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/filesystemstore/FileSystemStore.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/global_api/kvstore_global_api.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/kv_map/KVMap.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/securestore/SecureStore.o
 SYS_OBJECTS += ./mbed-os/features/storage/kvstore/tdbstore/TDBStore.o
 SYS_OBJECTS += ./mbed-os/features/storage/nvstore/source/nvstore.o
 SYS_OBJECTS += ./mbed-os/features/storage/system_storage/SystemStorage.o
 SYS_OBJECTS += ./mbed-os/hal/LowPowerTickerWrapper.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_compat.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_critical_section_api.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_flash_api.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_gpio.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_gpio_irq.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_itm_api.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_lp_ticker_api.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_lp_ticker_wrapper.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_pinmap_common.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_pinmap_default.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_ticker_api.o
 SYS_OBJECTS += ./mbed-os/hal/mbed_us_ticker_api.o
 SYS_OBJECTS += ./mbed-os/hal/mpu/mbed_mpu_v7m.o
 SYS_OBJECTS += ./mbed-os/hal/mpu/mbed_mpu_v8m.o
 SYS_OBJECTS += ./mbed-os/hal/static_pinmap.o
 SYS_OBJECTS += ./mbed-os/hal/usb/mbed_usb_phy.o
 SYS_OBJECTS += ./mbed-os/platform/cxxsupport/mstd_mutex.o
 SYS_OBJECTS += ./mbed-os/platform/source/ATCmdParser.o
 SYS_OBJECTS += ./mbed-os/platform/source/CThunkBase.o
 SYS_OBJECTS += ./mbed-os/platform/source/CallChain.o
 SYS_OBJECTS += ./mbed-os/platform/source/CriticalSectionLock.o
 SYS_OBJECTS += ./mbed-os/platform/source/DeepSleepLock.o
 SYS_OBJECTS += ./mbed-os/platform/source/FileBase.o
 SYS_OBJECTS += ./mbed-os/platform/source/FileHandle.o
 SYS_OBJECTS += ./mbed-os/platform/source/FilePath.o
 SYS_OBJECTS += ./mbed-os/platform/source/FileSystemHandle.o
 SYS_OBJECTS += ./mbed-os/platform/source/LocalFileSystem.o
 SYS_OBJECTS += ./mbed-os/platform/source/Stream.o
 SYS_OBJECTS += ./mbed-os/platform/source/SysTimer.o
 SYS_OBJECTS += ./mbed-os/platform/source/TARGET_CORTEX_M/TOOLCHAIN_GCC/except.o
 SYS_OBJECTS += ./mbed-os/platform/source/TARGET_CORTEX_M/mbed_fault_handler.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_alloc_wrappers.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_application.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_assert.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_atomic_impl.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_board.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_critical.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_error.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_error_hist.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_interface.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_mem_trace.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_mktime.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_mpu_mgmt.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_os_timer.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_poll.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_power_mgmt.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_retarget.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_rtc_time.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_sdk_boot.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_semihost_api.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_stats.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_thread.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_wait_api_no_rtos.o
 SYS_OBJECTS += ./mbed-os/platform/source/mbed_wait_api_rtos.o
 SYS_OBJECTS += ./mbed-os/platform/source/minimal-printf/mbed_printf_armlink_overrides.o
 SYS_OBJECTS += ./mbed-os/platform/source/minimal-printf/mbed_printf_implementation.o
 SYS_OBJECTS += ./mbed-os/platform/source/minimal-printf/mbed_printf_wrapper.o
 SYS_OBJECTS += ./mbed-os/rtos/source/ConditionVariable.o
 SYS_OBJECTS += ./mbed-os/rtos/source/EventFlags.o
 SYS_OBJECTS += ./mbed-os/rtos/source/Kernel.o
 SYS_OBJECTS += ./mbed-os/rtos/source/Mutex.o
 SYS_OBJECTS += ./mbed-os/rtos/source/RtosTimer.o
 SYS_OBJECTS += ./mbed-os/rtos/source/Semaphore.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/TOOLCHAIN_GCC_ARM/mbed_boot_gcc_arm.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_boot.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_rtos_rtx.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_rtx_handlers.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/mbed_rtx_idle.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx4/cmsis_os1.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Config/RTX_Config.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/TOOLCHAIN_GCC/TARGET_RTOS_M4_M7/irq_cm4f.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_delay.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_evflags.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_evr.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_kernel.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_lib.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_memory.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_mempool.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_msgqueue.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_mutex.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_semaphore.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_system.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_thread.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source/rtx_timer.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/Source/os_systick.o
 SYS_OBJECTS += ./mbed-os/rtos/source/TARGET_CORTEX/rtx5/Source/os_tick_ptim.o
 SYS_OBJECTS += ./mbed-os/rtos/source/ThisThread.o
 SYS_OBJECTS += ./mbed-os/rtos/source/Thread.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/PeripheralPins.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/crc.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/fsl_clock_config.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/fsl_phy.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM/mbed_overrides.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device/TOOLCHAIN_GCC_ARM/startup_MK64F12.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device/system_MK64F12.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_adc16.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_clock.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_cmp.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_cmt.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_crc.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dac.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dmamux.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dspi.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_dspi_edma.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_edma.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_enet.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_ewm.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_flash.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_flexbus.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_flexcan.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_ftm.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_gpio.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_i2c.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_i2c_edma.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_llwu.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_lptmr.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_pdb.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_pit.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_pmc.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_rcm.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_rnga.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_rtc.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sai.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sai_edma.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sdhc.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sim.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_smc.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_sysmpu.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_uart.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_uart_edma.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_vref.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers/fsl_wdog.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/mbed_crc_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/pwmout_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/reset_reason.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/serial_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/spi_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/storage_driver.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/trng_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/us_ticker.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/watchdog_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/analogin_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/analogout_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/dma_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/flash_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/gpio_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/gpio_irq_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/i2c_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/lp_ticker.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/pinmap.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/port_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/qspi_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/rtc_api.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api/sleep.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/fsl_common.o
 SYS_OBJECTS += ./mbed-os/targets/TARGET_Freescale/USBPhy_Kinetis.o

INCLUDE_PATHS += -I../.
INCLUDE_PATHS += -I.././mbed-os
INCLUDE_PATHS += -I.././mbed-os/cmsis
INCLUDE_PATHS += -I.././mbed-os/cmsis/TARGET_CORTEX_M
INCLUDE_PATHS += -I.././mbed-os/components
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/atmel-rf-driver
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/atmel-rf-driver/atmel-rf-driver
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/atmel-rf-driver/source
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/mcr20a-rf-driver
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/mcr20a-rf-driver/mcr20a-rf-driver
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/mcr20a-rf-driver/source
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source
INCLUDE_PATHS += -I.././mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/stm-s2lp-rf-driver
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/inc
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/inc/psa
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/inc/psa_manifest
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/inc
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/src
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/qcbor
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/qcbor/inc
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/attestation/qcbor/src
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/inc
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/platform/COMPONENT_PSA_SRV_IMPL
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/storage
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/storage/common
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/storage/its
INCLUDE_PATHS += -I.././mbed-os/components/TARGET_PSA/services/storage/its/COMPONENT_PSA_SRV_IMPL
INCLUDE_PATHS += -I.././mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP
INCLUDE_PATHS += -I.././mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP/COMMON
INCLUDE_PATHS += -I.././mbed-os/components/storage/blockdevice/COMPONENT_SD
INCLUDE_PATHS += -I.././mbed-os/components/wifi
INCLUDE_PATHS += -I.././mbed-os/components/wifi/esp8266-driver
INCLUDE_PATHS += -I.././mbed-os/components/wifi/esp8266-driver/ESP8266
INCLUDE_PATHS += -I.././mbed-os/drivers
INCLUDE_PATHS += -I.././mbed-os/drivers/internal
INCLUDE_PATHS += -I.././mbed-os/events
INCLUDE_PATHS += -I.././mbed-os/events/internal
INCLUDE_PATHS += -I.././mbed-os/features
INCLUDE_PATHS += -I.././mbed-os/features/cellular
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/API
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/AT
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/common
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/device
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/Altair
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/Altair/ALT1250
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/GEMALTO
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/GENERIC
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/GENERIC/GENERIC_AT3GPP
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/MultiTech
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano/PPP
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/QUECTEL
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/QUECTEL/BC95
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/QUECTEL/BG96
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/QUECTEL/EC2X
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/QUECTEL/M26
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/QUECTEL/UG96
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/RiotMicro
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/RiotMicro/AT
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/TELIT
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/TELIT/HE910
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/TELIT/ME910
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/UBLOX
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/UBLOX/AT
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/UBLOX/N2XX
INCLUDE_PATHS += -I.././mbed-os/features/cellular/framework/targets/UBLOX/PPP
INCLUDE_PATHS += -I.././mbed-os/features/device_key
INCLUDE_PATHS += -I.././mbed-os/features/device_key/source
INCLUDE_PATHS += -I.././mbed-os/features/frameworks
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/TARGET_PSA
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/TARGET_PSA/pal
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/greentea-client
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/greentea-client/greentea-client
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-client-cli
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-client-cli/mbed-client-cli
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-client-randlib
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-client-randlib/mbed-client-randlib
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-client-randlib/mbed-client-randlib/platform
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-coap
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-coap/mbed-coap
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-coap/source
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-coap/source/include
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-trace
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/mbed-trace/mbed-trace
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/nanostack-libservice
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/nanostack-libservice/mbed-client-libservice
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/nanostack-libservice/mbed-client-libservice/platform
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/unity
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/unity/unity
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/utest
INCLUDE_PATHS += -I.././mbed-os/features/frameworks/utest/utest
INCLUDE_PATHS += -I.././mbed-os/features/lorawan
INCLUDE_PATHS += -I.././mbed-os/features/lorawan/lorastack
INCLUDE_PATHS += -I.././mbed-os/features/lorawan/lorastack/mac
INCLUDE_PATHS += -I.././mbed-os/features/lorawan/lorastack/phy
INCLUDE_PATHS += -I.././mbed-os/features/lorawan/system
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip-sys
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip-sys/arch
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/compat
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/compat/posix
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/compat/posix/arpa
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/compat/posix/net
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/compat/posix/sys
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/lwip
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/lwip/priv
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/lwip/prot
INCLUDE_PATHS += -I.././mbed-os/features/lwipstack/lwip/src/include/netif
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/inc
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/inc/mbedtls
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/mbed-crypto
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/mbed-crypto/inc
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/mbed-crypto/inc/mbedtls
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/mbed-crypto/inc/psa
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/COMPONENT_NSPE
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/platform
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_PSA_SRV_IMPL
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_PSA_SRV_IMPL/inc
INCLUDE_PATHS += -I.././mbed-os/features/mbedtls/platform/inc
INCLUDE_PATHS += -I.././mbed-os/features/nanostack
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/coap-service
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/coap-service/coap-service
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/coap-service/source
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/coap-service/source/include
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/mbed-mesh-api
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/mbed-mesh-api/mbed-mesh-api
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/mbed-mesh-api/source
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/mbed-mesh-api/source/include
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/nanostack-interface
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack-eventloop
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack-eventloop/nanostack-event-loop
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack-eventloop/nanostack-event-loop/platform
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/nanostack
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/nanostack/platform
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Fragmentation
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Mesh
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ND
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/NVM
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/BorderRouter
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Core
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Core/include
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_Server
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_client
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/MAC
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/virtual_rf
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/MLE
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/MPL
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/Include
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/RPL
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/Common
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/TLS
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/eapol
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/fwh_sec_prot
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/gkh_sec_prot
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/key_sec_prot
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/tls_sec_prot
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Neighbor_cache
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Trickle
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/blacklist
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/etx
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fnv_hash
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/hmac
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/ieee_802_11
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/load_balance
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mac_neighbor_table
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/port
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/port/compiler
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/port/cpu
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/dns
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/mdns
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/poll
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/serial
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/stack
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nd_proxy
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nist_aes_kw
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/pan_blacklist
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/whiteboard
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/configs
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/configs/base
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/ipv6_stack
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/libNET
INCLUDE_PATHS += -I.././mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src
INCLUDE_PATHS += -I.././mbed-os/features/netsocket
INCLUDE_PATHS += -I.././mbed-os/features/netsocket/cellular
INCLUDE_PATHS += -I.././mbed-os/features/netsocket/emac-drivers/TARGET_Freescale_EMAC
INCLUDE_PATHS += -I.././mbed-os/features/netsocket/ppp
INCLUDE_PATHS += -I.././mbed-os/features/netsocket/ppp/include
INCLUDE_PATHS += -I.././mbed-os/features/netsocket/ppp/include/polarssl
INCLUDE_PATHS += -I.././mbed-os/features/nfc
INCLUDE_PATHS += -I.././mbed-os/features/nfc/acore
INCLUDE_PATHS += -I.././mbed-os/features/nfc/acore/acore
INCLUDE_PATHS += -I.././mbed-os/features/nfc/controllers
INCLUDE_PATHS += -I.././mbed-os/features/nfc/nfc
INCLUDE_PATHS += -I.././mbed-os/features/nfc/nfc/ndef
INCLUDE_PATHS += -I.././mbed-os/features/nfc/nfc/ndef/common
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/ndef
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/platform
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/tech
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/tech/iso7816
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/tech/isodep
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/tech/type4
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/transceiver
INCLUDE_PATHS += -I.././mbed-os/features/nfc/stack/transceiver/pn512
INCLUDE_PATHS += -I.././mbed-os/features/storage
INCLUDE_PATHS += -I.././mbed-os/features/storage/blockdevice
INCLUDE_PATHS += -I.././mbed-os/features/storage/filesystem
INCLUDE_PATHS += -I.././mbed-os/features/storage/filesystem/fat
INCLUDE_PATHS += -I.././mbed-os/features/storage/filesystem/fat/ChaN
INCLUDE_PATHS += -I.././mbed-os/features/storage/filesystem/littlefs
INCLUDE_PATHS += -I.././mbed-os/features/storage/filesystem/littlefs/littlefs
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/conf
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/direct_access_devicekey
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/filesystemstore
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/global_api
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/include
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/kv_map
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/securestore
INCLUDE_PATHS += -I.././mbed-os/features/storage/kvstore/tdbstore
INCLUDE_PATHS += -I.././mbed-os/features/storage/nvstore
INCLUDE_PATHS += -I.././mbed-os/features/storage/nvstore/source
INCLUDE_PATHS += -I.././mbed-os/features/storage/system_storage
INCLUDE_PATHS += -I.././mbed-os/hal
INCLUDE_PATHS += -I.././mbed-os/hal/storage_abstraction
INCLUDE_PATHS += -I.././mbed-os/hal/usb
INCLUDE_PATHS += -I.././mbed-os/platform
INCLUDE_PATHS += -I.././mbed-os/platform/cxxsupport
INCLUDE_PATHS += -I.././mbed-os/platform/internal
INCLUDE_PATHS += -I.././mbed-os/platform/source
INCLUDE_PATHS += -I.././mbed-os/platform/source/TARGET_CORTEX_M
INCLUDE_PATHS += -I.././mbed-os/platform/source/minimal-printf
INCLUDE_PATHS += -I.././mbed-os/rtos
INCLUDE_PATHS += -I.././mbed-os/rtos/source
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx4
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx5
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx5/Include
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Config
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Include
INCLUDE_PATHS += -I.././mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers
INCLUDE_PATHS += -I.././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api
INCLUDE_PATHS += -I/$(CURDIR)/mbed-os

LIBRARY_PATHS :=
LIBRARIES :=
LINKER_SCRIPT ?= .././mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device/TOOLCHAIN_GCC_ARM/MK64FN1M0xxx12.ld

# Objects and Paths
###############################################################################
# Tools and Flags

AS      = arm-none-eabi-gcc
CC      = arm-none-eabi-gcc
#CPP     = arm-none-eabi-g++
LD      = arm-none-eabi-gcc
ELF2BIN = arm-none-eabi-objcopy
PREPROC = arm-none-eabi-cpp -E -P -Wl,--gc-sections -Wl,--wrap,main -Wl,--wrap,_malloc_r -Wl,--wrap,_free_r -Wl,--wrap,_realloc_r -Wl,--wrap,_memalign_r -Wl,--wrap,_calloc_r -Wl,--wrap,exit -Wl,--wrap,atexit -Wl,-n -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -DMBED_ROM_START=0x0 -DMBED_ROM_SIZE=0x100000 -DMBED_RAM_START=0x20000000 -DMBED_RAM_SIZE=0x30000 -DMBED_RAM1_START=0x1fff0000 -DMBED_RAM1_SIZE=0x10000 -DMBED_BOOT_STACK_SIZE=1024 -DXIP_ENABLE=0


C_FLAGS += -std=gnu11
C_FLAGS += -include
C_FLAGS += mbed_config.h
C_FLAGS += -DDEVICE_USTICKER=1
C_FLAGS += -DDEVICE_SPI=1
C_FLAGS += -D__MBED__=1
C_FLAGS += -DDEVICE_I2CSLAVE=1
C_FLAGS += -DTARGET_M4
C_FLAGS += -DTARGET_CORTEX
C_FLAGS += -DTARGET_K64F
C_FLAGS += -DCPU_MK64FN1M0VMD12
C_FLAGS += -DDEVICE_SLEEP=1
C_FLAGS += -DCOMPONENT_PSA_SRV_EMUL=1
C_FLAGS += -DCOMPONENT_FLASHIAP=1
C_FLAGS += -DDEVICE_RESET_REASON=1
C_FLAGS += -DFSL_RTOS_MBED
C_FLAGS += -DTARGET_RTOS_M4_M7
C_FLAGS += -DTARGET_Freescale_EMAC
C_FLAGS += -DTARGET_KPSDK_MCUS
C_FLAGS += -DTARGET_LIKE_MBED
C_FLAGS += -DTOOLCHAIN_GCC_ARM
C_FLAGS += -DDEVICE_WATCHDOG=1
C_FLAGS += -DDEVICE_SPISLAVE=1
C_FLAGS += -DDEVICE_RTC=1
C_FLAGS += -DDEVICE_USBDEVICE=1
C_FLAGS += -DTARGET_FRDM
C_FLAGS += -DCOMPONENT_PSA_SRV_IMPL=1
C_FLAGS += -DDEVICE_EMAC=1
C_FLAGS += -DTOOLCHAIN_GCC
C_FLAGS += -DMBED_BUILD_TIMESTAMP=1588052885.089377
C_FLAGS += -DDEVICE_LPTICKER=1
C_FLAGS += -DDEVICE_SPI_ASYNCH=1
C_FLAGS += -D__CMSIS_RTOS
C_FLAGS += -DDEVICE_PORTOUT=1
C_FLAGS += -DCOMPONENT_SD=1
C_FLAGS += -DTARGET_NAME=K64F
C_FLAGS += -DTARGET_MCUXpresso_MCUS
C_FLAGS += -DDEVICE_PORTIN=1
C_FLAGS += -DDEVICE_STDIO_MESSAGES=1
C_FLAGS += -DTARGET_FF_ARDUINO
C_FLAGS += -D__FPU_PRESENT=1
C_FLAGS += -D__CORTEX_M4
C_FLAGS += -DDEVICE_SERIAL_ASYNCH=1
C_FLAGS += -DDEVICE_ANALOGOUT=1
C_FLAGS += -DTARGET_KSDK2_MCUS
C_FLAGS += -DDEVICE_FLASH=1
C_FLAGS += -DTARGET_Freescale
C_FLAGS += -DMBED_SPLIT_HEAP
C_FLAGS += -DDEVICE_CRC=1
C_FLAGS += -DDEVICE_PWMOUT=1
C_FLAGS += -DDEVICE_ANALOGIN=1
C_FLAGS += -DTARGET_CORTEX_M
C_FLAGS += -DTARGET_RELEASE
C_FLAGS += -DMBED_TICKLESS
C_FLAGS += -DCOMPONENT_NSPE=1
C_FLAGS += -D__MBED_CMSIS_RTOS_CM
C_FLAGS += -DDEVICE_PORTINOUT=1
C_FLAGS += -DDEVICE_I2C=1
C_FLAGS += -DTARGET_MCU_K64F
C_FLAGS += -DDEVICE_TRNG=1
C_FLAGS += -DDEVICE_SERIAL=1
C_FLAGS += -DDEVICE_SERIAL_FC=1
C_FLAGS += -DDEVICE_INTERRUPTIN=1
C_FLAGS += -DTARGET_PSA
C_FLAGS += -DARM_MATH_CM4
C_FLAGS += -DTARGET_LIKE_CORTEX_M4
C_FLAGS += -DTARGET_KPSDK_CODE
C_FLAGS += -include
C_FLAGS += mbed_config.h
C_FLAGS += -std=gnu11
C_FLAGS += -c
C_FLAGS += -Wall
C_FLAGS += -Wextra
C_FLAGS += -Wno-unused-parameter
C_FLAGS += -Wno-missing-field-initializers
C_FLAGS += -fmessage-length=0
C_FLAGS += -fno-exceptions
C_FLAGS += -ffunction-sections
C_FLAGS += -fdata-sections
C_FLAGS += -funsigned-char
C_FLAGS += -MMD
C_FLAGS += -fno-delete-null-pointer-checks
C_FLAGS += -fomit-frame-pointer
C_FLAGS += -Og
C_FLAGS += -g3
C_FLAGS += -DMBED_DEBUG
C_FLAGS += -DMBED_TRAP_ERRORS_ENABLED=1
C_FLAGS += -mcpu=cortex-m4
C_FLAGS += -mthumb
C_FLAGS += -mfpu=fpv4-sp-d16
C_FLAGS += -mfloat-abi=softfp
C_FLAGS += -DMBED_ROM_START=0x0
C_FLAGS += -DMBED_ROM_SIZE=0x100000
C_FLAGS += -DMBED_RAM_START=0x20000000
C_FLAGS += -DMBED_RAM_SIZE=0x30000
C_FLAGS += -DMBED_RAM1_START=0x1fff0000
C_FLAGS += -DMBED_RAM1_SIZE=0x10000

CXX_FLAGS += -std=gnu++14
CXX_FLAGS += -fno-rtti
CXX_FLAGS += -Wvla
CXX_FLAGS += -include
CXX_FLAGS += mbed_config.h
CXX_FLAGS += -DDEVICE_USTICKER=1
CXX_FLAGS += -DDEVICE_SPI=1
CXX_FLAGS += -D__MBED__=1
CXX_FLAGS += -DDEVICE_I2CSLAVE=1
CXX_FLAGS += -DTARGET_M4
CXX_FLAGS += -DTARGET_CORTEX
CXX_FLAGS += -DTARGET_K64F
CXX_FLAGS += -DCPU_MK64FN1M0VMD12
CXX_FLAGS += -DDEVICE_SLEEP=1
CXX_FLAGS += -DCOMPONENT_PSA_SRV_EMUL=1
CXX_FLAGS += -DCOMPONENT_FLASHIAP=1
CXX_FLAGS += -DDEVICE_RESET_REASON=1
CXX_FLAGS += -DFSL_RTOS_MBED
CXX_FLAGS += -DTARGET_RTOS_M4_M7
CXX_FLAGS += -DTARGET_Freescale_EMAC
CXX_FLAGS += -DTARGET_KPSDK_MCUS
CXX_FLAGS += -DTARGET_LIKE_MBED
CXX_FLAGS += -DTOOLCHAIN_GCC_ARM
CXX_FLAGS += -DDEVICE_WATCHDOG=1
CXX_FLAGS += -DDEVICE_SPISLAVE=1
CXX_FLAGS += -DDEVICE_RTC=1
CXX_FLAGS += -DDEVICE_USBDEVICE=1
CXX_FLAGS += -DTARGET_FRDM
CXX_FLAGS += -DCOMPONENT_PSA_SRV_IMPL=1
CXX_FLAGS += -DDEVICE_EMAC=1
CXX_FLAGS += -DTOOLCHAIN_GCC
CXX_FLAGS += -DMBED_BUILD_TIMESTAMP=1588052885.089377
CXX_FLAGS += -DDEVICE_LPTICKER=1
CXX_FLAGS += -DDEVICE_SPI_ASYNCH=1
CXX_FLAGS += -D__CMSIS_RTOS
CXX_FLAGS += -DDEVICE_PORTOUT=1
CXX_FLAGS += -DCOMPONENT_SD=1
CXX_FLAGS += -DTARGET_NAME=K64F
CXX_FLAGS += -DTARGET_MCUXpresso_MCUS
CXX_FLAGS += -DDEVICE_PORTIN=1
CXX_FLAGS += -DDEVICE_STDIO_MESSAGES=1
CXX_FLAGS += -DTARGET_FF_ARDUINO
CXX_FLAGS += -D__FPU_PRESENT=1
CXX_FLAGS += -D__CORTEX_M4
CXX_FLAGS += -DDEVICE_SERIAL_ASYNCH=1
CXX_FLAGS += -DDEVICE_ANALOGOUT=1
CXX_FLAGS += -DTARGET_KSDK2_MCUS
CXX_FLAGS += -DDEVICE_FLASH=1
CXX_FLAGS += -DTARGET_Freescale
CXX_FLAGS += -DMBED_SPLIT_HEAP
CXX_FLAGS += -DDEVICE_CRC=1
CXX_FLAGS += -DDEVICE_PWMOUT=1
CXX_FLAGS += -DDEVICE_ANALOGIN=1
CXX_FLAGS += -DTARGET_CORTEX_M
CXX_FLAGS += -DTARGET_RELEASE
CXX_FLAGS += -DMBED_TICKLESS
CXX_FLAGS += -DCOMPONENT_NSPE=1
CXX_FLAGS += -D__MBED_CMSIS_RTOS_CM
CXX_FLAGS += -DDEVICE_PORTINOUT=1
CXX_FLAGS += -DDEVICE_I2C=1
CXX_FLAGS += -DTARGET_MCU_K64F
CXX_FLAGS += -DDEVICE_TRNG=1
CXX_FLAGS += -DDEVICE_SERIAL=1
CXX_FLAGS += -DDEVICE_SERIAL_FC=1
CXX_FLAGS += -DDEVICE_INTERRUPTIN=1
CXX_FLAGS += -DTARGET_PSA
CXX_FLAGS += -DARM_MATH_CM4
CXX_FLAGS += -DTARGET_LIKE_CORTEX_M4
CXX_FLAGS += -DTARGET_KPSDK_CODE
CXX_FLAGS += -include
CXX_FLAGS += mbed_config.h
CXX_FLAGS += -std=gnu++14
CXX_FLAGS += -fno-rtti
CXX_FLAGS += -Wvla
CXX_FLAGS += -c
CXX_FLAGS += -Wall
CXX_FLAGS += -Wextra
CXX_FLAGS += -Wno-unused-parameter
CXX_FLAGS += -Wno-missing-field-initializers
CXX_FLAGS += -fmessage-length=0
CXX_FLAGS += -fno-exceptions
CXX_FLAGS += -ffunction-sections
CXX_FLAGS += -fdata-sections
CXX_FLAGS += -funsigned-char
CXX_FLAGS += -MMD
CXX_FLAGS += -fno-delete-null-pointer-checks
CXX_FLAGS += -fomit-frame-pointer
CXX_FLAGS += -Og
CXX_FLAGS += -g3
CXX_FLAGS += -DMBED_DEBUG
CXX_FLAGS += -DMBED_TRAP_ERRORS_ENABLED=1
CXX_FLAGS += -mcpu=cortex-m4
CXX_FLAGS += -mthumb
CXX_FLAGS += -mfpu=fpv4-sp-d16
CXX_FLAGS += -mfloat-abi=softfp
CXX_FLAGS += -DMBED_ROM_START=0x0
CXX_FLAGS += -DMBED_ROM_SIZE=0x100000
CXX_FLAGS += -DMBED_RAM_START=0x20000000
CXX_FLAGS += -DMBED_RAM_SIZE=0x30000
CXX_FLAGS += -DMBED_RAM1_START=0x1fff0000
CXX_FLAGS += -DMBED_RAM1_SIZE=0x10000

ASM_FLAGS += -x
ASM_FLAGS += assembler-with-cpp
ASM_FLAGS += -D__CMSIS_RTOS
ASM_FLAGS += -DFSL_RTOS_MBED
ASM_FLAGS += -DMBED_TICKLESS
ASM_FLAGS += -D__MBED_CMSIS_RTOS_CM
ASM_FLAGS += -DCPU_MK64FN1M0VMD12
ASM_FLAGS += -D__FPU_PRESENT=1
ASM_FLAGS += -D__CORTEX_M4
ASM_FLAGS += -DARM_MATH_CM4
ASM_FLAGS += -DMBED_SPLIT_HEAP
ASM_FLAGS += -I..
ASM_FLAGS += -I../mbed-os
ASM_FLAGS += -I../mbed-os/cmsis
ASM_FLAGS += -I../mbed-os/cmsis/TARGET_CORTEX_M
ASM_FLAGS += -I../mbed-os/components
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/atmel-rf-driver
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/atmel-rf-driver/atmel-rf-driver
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/atmel-rf-driver/source
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/mcr20a-rf-driver
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/mcr20a-rf-driver/mcr20a-rf-driver
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/mcr20a-rf-driver/source
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/source
ASM_FLAGS += -I../mbed-os/components/802.15.4_RF/stm-s2lp-rf-driver/stm-s2lp-rf-driver
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/inc
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/inc/psa
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/inc/psa_manifest
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/inc
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/COMPONENT_PSA_SRV_IMPL/tfm_impl/t_cose/src
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/qcbor
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/qcbor/inc
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/attestation/qcbor/src
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/inc
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/platform/COMPONENT_PSA_SRV_IMPL
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/storage
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/storage/common
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/storage/its
ASM_FLAGS += -I../mbed-os/components/TARGET_PSA/services/storage/its/COMPONENT_PSA_SRV_IMPL
ASM_FLAGS += -I../mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP
ASM_FLAGS += -I../mbed-os/components/storage/blockdevice/COMPONENT_FLASHIAP/COMMON
ASM_FLAGS += -I../mbed-os/components/storage/blockdevice/COMPONENT_SD
ASM_FLAGS += -I../mbed-os/components/wifi
ASM_FLAGS += -I../mbed-os/components/wifi/esp8266-driver
ASM_FLAGS += -I../mbed-os/components/wifi/esp8266-driver/ESP8266
ASM_FLAGS += -I../mbed-os/drivers
ASM_FLAGS += -I../mbed-os/drivers/internal
ASM_FLAGS += -I../mbed-os/events
ASM_FLAGS += -I../mbed-os/events/internal
ASM_FLAGS += -I../mbed-os/features
ASM_FLAGS += -I../mbed-os/features/cellular
ASM_FLAGS += -I../mbed-os/features/cellular/framework
ASM_FLAGS += -I../mbed-os/features/cellular/framework/API
ASM_FLAGS += -I../mbed-os/features/cellular/framework/AT
ASM_FLAGS += -I../mbed-os/features/cellular/framework/common
ASM_FLAGS += -I../mbed-os/features/cellular/framework/device
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/Altair
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/Altair/ALT1250
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/Altair/ALT1250/PPP
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/GEMALTO
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/GEMALTO/CINTERION
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/GENERIC
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/GENERIC/GENERIC_AT3GPP
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/MultiTech
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/MultiTech/DragonflyNano/PPP
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/QUECTEL
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/QUECTEL/BC95
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/QUECTEL/BG96
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/QUECTEL/EC2X
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/QUECTEL/M26
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/QUECTEL/UG96
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/RiotMicro
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/RiotMicro/AT
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/TELIT
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/TELIT/HE910
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/TELIT/ME910
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/UBLOX
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/UBLOX/AT
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/UBLOX/N2XX
ASM_FLAGS += -I../mbed-os/features/cellular/framework/targets/UBLOX/PPP
ASM_FLAGS += -I../mbed-os/features/device_key
ASM_FLAGS += -I../mbed-os/features/device_key/source
ASM_FLAGS += -I../mbed-os/features/frameworks
ASM_FLAGS += -I../mbed-os/features/frameworks/TARGET_PSA
ASM_FLAGS += -I../mbed-os/features/frameworks/TARGET_PSA/pal
ASM_FLAGS += -I../mbed-os/features/frameworks/greentea-client
ASM_FLAGS += -I../mbed-os/features/frameworks/greentea-client/greentea-client
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-client-cli
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-client-cli/mbed-client-cli
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-client-randlib
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-client-randlib/mbed-client-randlib
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-client-randlib/mbed-client-randlib/platform
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-coap
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-coap/mbed-coap
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-coap/source
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-coap/source/include
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-trace
ASM_FLAGS += -I../mbed-os/features/frameworks/mbed-trace/mbed-trace
ASM_FLAGS += -I../mbed-os/features/frameworks/nanostack-libservice
ASM_FLAGS += -I../mbed-os/features/frameworks/nanostack-libservice/mbed-client-libservice
ASM_FLAGS += -I../mbed-os/features/frameworks/nanostack-libservice/mbed-client-libservice/platform
ASM_FLAGS += -I../mbed-os/features/frameworks/unity
ASM_FLAGS += -I../mbed-os/features/frameworks/unity/unity
ASM_FLAGS += -I../mbed-os/features/frameworks/utest
ASM_FLAGS += -I../mbed-os/features/frameworks/utest/utest
ASM_FLAGS += -I../mbed-os/features/lorawan
ASM_FLAGS += -I../mbed-os/features/lorawan/lorastack
ASM_FLAGS += -I../mbed-os/features/lorawan/lorastack/mac
ASM_FLAGS += -I../mbed-os/features/lorawan/lorastack/phy
ASM_FLAGS += -I../mbed-os/features/lorawan/system
ASM_FLAGS += -I../mbed-os/features/lwipstack
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip-sys
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip-sys/arch
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/compat
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/compat/posix
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/compat/posix/arpa
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/compat/posix/net
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/compat/posix/sys
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/lwip
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/lwip/priv
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/lwip/prot
ASM_FLAGS += -I../mbed-os/features/lwipstack/lwip/src/include/netif
ASM_FLAGS += -I../mbed-os/features/mbedtls
ASM_FLAGS += -I../mbed-os/features/mbedtls/inc
ASM_FLAGS += -I../mbed-os/features/mbedtls/inc/mbedtls
ASM_FLAGS += -I../mbed-os/features/mbedtls/mbed-crypto
ASM_FLAGS += -I../mbed-os/features/mbedtls/mbed-crypto/inc
ASM_FLAGS += -I../mbed-os/features/mbedtls/mbed-crypto/inc/mbedtls
ASM_FLAGS += -I../mbed-os/features/mbedtls/mbed-crypto/inc/psa
ASM_FLAGS += -I../mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL
ASM_FLAGS += -I../mbed-os/features/mbedtls/mbed-crypto/platform/COMPONENT_PSA_SRV_IMPL/COMPONENT_NSPE
ASM_FLAGS += -I../mbed-os/features/mbedtls/platform
ASM_FLAGS += -I../mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_PSA_SRV_IMPL
ASM_FLAGS += -I../mbed-os/features/mbedtls/platform/TARGET_PSA/COMPONENT_PSA_SRV_IMPL/inc
ASM_FLAGS += -I../mbed-os/features/mbedtls/platform/inc
ASM_FLAGS += -I../mbed-os/features/nanostack
ASM_FLAGS += -I../mbed-os/features/nanostack/coap-service
ASM_FLAGS += -I../mbed-os/features/nanostack/coap-service/coap-service
ASM_FLAGS += -I../mbed-os/features/nanostack/coap-service/source
ASM_FLAGS += -I../mbed-os/features/nanostack/coap-service/source/include
ASM_FLAGS += -I../mbed-os/features/nanostack/mbed-mesh-api
ASM_FLAGS += -I../mbed-os/features/nanostack/mbed-mesh-api/mbed-mesh-api
ASM_FLAGS += -I../mbed-os/features/nanostack/mbed-mesh-api/source
ASM_FLAGS += -I../mbed-os/features/nanostack/mbed-mesh-api/source/include
ASM_FLAGS += -I../mbed-os/features/nanostack/nanostack-hal-mbed-cmsis-rtos
ASM_FLAGS += -I../mbed-os/features/nanostack/nanostack-interface
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack-eventloop
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack-eventloop/nanostack-event-loop
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack-eventloop/nanostack-event-loop/platform
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack-eventloop/source
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/nanostack
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/nanostack/platform
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Bootstraps
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Fragmentation
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/IPHC_Decode
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/MAC
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Mesh
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ND
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/NVM
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/Thread
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/6LoWPAN/ws
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/BorderRouter
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Common_Protocols
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Core
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Core/include
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_Server
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/DHCPv6_client
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/MAC
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/IEEE802_15_4
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/MAC/virtual_rf
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/MLE
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/MPL
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/NWK_INTERFACE/Include
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/RPL
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/Common
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/PANA
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/TLS
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/eapol
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/kmp
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/eap_tls_sec_prot
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/fwh_sec_prot
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/gkh_sec_prot
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/key_sec_prot
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Security/protocols/tls_sec_prot
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Neighbor_cache
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/Trickle
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/blacklist
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/etx
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fhss
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/fnv_hash
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/hmac
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/ieee_802_11
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/load_balance
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mac_neighbor_table
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/port
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/port/compiler
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/port/cpu
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/dns
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/mdns
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/poll
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/services/serial
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mdns/fnet/fnet_stack/stack
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/mle_service
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nd_proxy
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/nist_aes_kw
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/pan_blacklist
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/utils
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/Service_Libs/whiteboard
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/configs
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/configs/base
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/ipv6_stack
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/libDHCPv6
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/libNET
ASM_FLAGS += -I../mbed-os/features/nanostack/sal-stack-nanostack/source/libNET/src
ASM_FLAGS += -I../mbed-os/features/netsocket
ASM_FLAGS += -I../mbed-os/features/netsocket/cellular
ASM_FLAGS += -I../mbed-os/features/netsocket/emac-drivers/TARGET_Freescale_EMAC
ASM_FLAGS += -I../mbed-os/features/netsocket/ppp
ASM_FLAGS += -I../mbed-os/features/netsocket/ppp/include
ASM_FLAGS += -I../mbed-os/features/netsocket/ppp/include/polarssl
ASM_FLAGS += -I../mbed-os/features/nfc
ASM_FLAGS += -I../mbed-os/features/nfc/acore
ASM_FLAGS += -I../mbed-os/features/nfc/acore/acore
ASM_FLAGS += -I../mbed-os/features/nfc/controllers
ASM_FLAGS += -I../mbed-os/features/nfc/nfc
ASM_FLAGS += -I../mbed-os/features/nfc/nfc/ndef
ASM_FLAGS += -I../mbed-os/features/nfc/nfc/ndef/common
ASM_FLAGS += -I../mbed-os/features/nfc/stack
ASM_FLAGS += -I../mbed-os/features/nfc/stack/ndef
ASM_FLAGS += -I../mbed-os/features/nfc/stack/platform
ASM_FLAGS += -I../mbed-os/features/nfc/stack/tech
ASM_FLAGS += -I../mbed-os/features/nfc/stack/tech/iso7816
ASM_FLAGS += -I../mbed-os/features/nfc/stack/tech/isodep
ASM_FLAGS += -I../mbed-os/features/nfc/stack/tech/type4
ASM_FLAGS += -I../mbed-os/features/nfc/stack/transceiver
ASM_FLAGS += -I../mbed-os/features/nfc/stack/transceiver/pn512
ASM_FLAGS += -I../mbed-os/features/storage
ASM_FLAGS += -I../mbed-os/features/storage/blockdevice
ASM_FLAGS += -I../mbed-os/features/storage/filesystem
ASM_FLAGS += -I../mbed-os/features/storage/filesystem/fat
ASM_FLAGS += -I../mbed-os/features/storage/filesystem/fat/ChaN
ASM_FLAGS += -I../mbed-os/features/storage/filesystem/littlefs
ASM_FLAGS += -I../mbed-os/features/storage/filesystem/littlefs/littlefs
ASM_FLAGS += -I../mbed-os/features/storage/kvstore
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/conf
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/direct_access_devicekey
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/filesystemstore
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/global_api
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/include
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/kv_map
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/securestore
ASM_FLAGS += -I../mbed-os/features/storage/kvstore/tdbstore
ASM_FLAGS += -I../mbed-os/features/storage/nvstore
ASM_FLAGS += -I../mbed-os/features/storage/nvstore/source
ASM_FLAGS += -I../mbed-os/features/storage/system_storage
ASM_FLAGS += -I../mbed-os/hal
ASM_FLAGS += -I../mbed-os/hal/storage_abstraction
ASM_FLAGS += -I../mbed-os/hal/usb
ASM_FLAGS += -I../mbed-os/platform
ASM_FLAGS += -I../mbed-os/platform/cxxsupport
ASM_FLAGS += -I../mbed-os/platform/internal
ASM_FLAGS += -I../mbed-os/platform/source
ASM_FLAGS += -I../mbed-os/platform/source/TARGET_CORTEX_M
ASM_FLAGS += -I../mbed-os/platform/source/minimal-printf
ASM_FLAGS += -I../mbed-os/rtos
ASM_FLAGS += -I../mbed-os/rtos/source
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx4
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx5
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx5/Include
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Config
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Include
ASM_FLAGS += -I../mbed-os/rtos/source/TARGET_CORTEX/rtx5/RTX/Source
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/TARGET_FRDM
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/device
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/TARGET_MCU_K64F/drivers
ASM_FLAGS += -I../mbed-os/targets/TARGET_Freescale/TARGET_MCUXpresso_MCUS/api
ASM_FLAGS += -I/$(CURDIR)/mbed-os
ASM_FLAGS += -include
ASM_FLAGS += ./mbed_config.h
ASM_FLAGS += -x
ASM_FLAGS += assembler-with-cpp
ASM_FLAGS += -c
ASM_FLAGS += -Wall
ASM_FLAGS += -Wextra
ASM_FLAGS += -Wno-unused-parameter
ASM_FLAGS += -Wno-missing-field-initializers
ASM_FLAGS += -fmessage-length=0
ASM_FLAGS += -fno-exceptions
ASM_FLAGS += -ffunction-sections
ASM_FLAGS += -fdata-sections
ASM_FLAGS += -funsigned-char
ASM_FLAGS += -MMD
ASM_FLAGS += -fno-delete-null-pointer-checks
ASM_FLAGS += -fomit-frame-pointer
ASM_FLAGS += -Og
ASM_FLAGS += -g3
ASM_FLAGS += -DMBED_DEBUG
ASM_FLAGS += -DMBED_TRAP_ERRORS_ENABLED=1
ASM_FLAGS += -mcpu=cortex-m4
ASM_FLAGS += -mthumb
ASM_FLAGS += -mfpu=fpv4-sp-d16
ASM_FLAGS += -mfloat-abi=softfp


LD_FLAGS :=-Wl,--gc-sections -Wl,--wrap,main -Wl,--wrap,_malloc_r -Wl,--wrap,_free_r -Wl,--wrap,_realloc_r -Wl,--wrap,_memalign_r -Wl,--wrap,_calloc_r -Wl,--wrap,exit -Wl,--wrap,atexit -Wl,-n -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -DMBED_ROM_START=0x0 -DMBED_ROM_SIZE=0x100000 -DMBED_RAM_START=0x20000000 -DMBED_RAM_SIZE=0x30000 -DMBED_RAM1_START=0x1fff0000 -DMBED_RAM1_SIZE=0x10000 -DMBED_BOOT_STACK_SIZE=1024 -DXIP_ENABLE=0 
LD_SYS_LIBS :=-Wl,--start-group -lstdc++ -lsupc++ -lm -lc -lgcc -lnosys  -Wl,--end-group

######################################################

all: ejsvm ejsc.jar ejsi

ejsc.jar: $(EJSC)
	cp $< $@

ejsi: $(EJSI)
	cp $< $@

ejsvm :: $(OFILES) ejsvm.spec
	$(CC) $(LDFLAGS) -o $@ $(OFILES) $(LIBS) $(LD_SYS_LIBS)

instructions-opcode.h: $(EJSVM_DIR)/instructions.def $(SUPERINSNSPEC)
	$(GOTTA) --gen-insn-opcode -o $@

instructions-table.h: $(EJSVM_DIR)/instructions.def $(SUPERINSNSPEC)
	$(GOTTA) --gen-insn-table -o $@

instructions-label.h: $(EJSVM_DIR)/instructions.def $(SUPERINSNSPEC)
	$(GOTTA) --gen-insn-label -o $@

vmloop-cases.inc: $(EJSVM_DIR)/instructions.def
	$(GOTTA) --gen-vmloop-cases -o $@

ifeq ($(SUPERINSNTYPE),)
ejsvm.spec: $(EJSVM_DIR)/instructions.def $(VMDL)
	$(SPECGEN) --insndef $(EJSVM_DIR)/instructions.def -o ejsvm.spec\
		--fingerprint specfile-fingerprint.h
	cp $@ ../
specfile-fingerprint.h: ejsvm.spec
	touch $@
else
ejsvm.spec specfile-fingerprint.h: $(EJSVM_DIR)/instructions.def $(SUPERINSNSPEC) $(VMDL)
	$(SPECGEN) --insndef $(EJSVM_DIR)/instructions.def\
		--sispec $(SUPERINSNSPEC) -o ejsvm.spec\
		--fingerprint specfile-fingerprint.h
	cp $@ ../
endif

$(INSN_HANDCRAFT):insns/%.inc: $(EJSVM_DIR)/insns-handcraft/%.inc
	mkdir -p insns
	cp $< $@

insns-vmdl/%.vmd: $(EJSVM_DIR)/insns-vmdl/%.vmd $(EJSVM_DIR)/insns-vmdl/externc.vmdh
	mkdir -p insns-vmdl
	$(CPP_VMDL) $< > $@ || (rm $@; exit 1)

ifeq ($(DATATYPES),)
$(INSN_GENERATED):insns/%.inc: $(EJSVM_DIR)/insns-handcraft/%.inc
	mkdir -p insns
	cp $< $@
else ifeq ($(SUPERINSN_REORDER_DISPATCH),true)

ifeq ($(USE_VMDL), true)
$(INSN_GENERATED):insns/%.inc: insns-vmdl/%.vmd $(VMDL)
	mkdir -p insns
	$(INSNGEN_VMDL) $(VMDLC_FLAGS) \
		-Xgen:type_label true \
		-Xcmp:tree_layer \
		`$(GOTTA) --print-dispatch-order $(patsubst insns/%.inc,%,$@)` \
	-d $(DATATYPES) -o $(OPERANDSPEC) -i  $(EJSVM_DIR)/instructions.def $< > $@ || (rm $@; exit 1)
else
$(INSN_GENERATED):insns/%.inc: $(EJSVM_DIR)/insns-def/%.idef $(VMGEN)
	mkdir -p insns
	$(INSNGEN_VMGEN) $(INSNGEN_FLAGS) \
		-Xgen:type_label true \
		-Xcmp:tree_layer \
		`$(GOTTA) --print-dispatch-order $(patsubst insns/%.inc,%,$@)` \
		$(DATATYPES) $< $(OPERANDSPEC) insns
endif
else
ifeq ($(USE_VMDL), true)
$(INSN_GENERATED):insns/%.inc: insns-vmdl/%.vmd $(VMDL)
	mkdir -p insns
	$(INSNGEN_VMDL) $(VMDLC_FLAGS) \
		-Xgen:type_label true \
		-Xcmp:tree_layer p0:p1:p2:h0:h1:h2 \
		-d $(DATATYPES) -o $(OPERANDSPEC) -i  $(EJSVM_DIR)/instructions.def $< > $@ || (rm $@; exit 1)
else
$(INSN_GENERATED):insns/%.inc: $(EJSVM_DIR)/insns-def/%.idef $(VMGEN)
	mkdir -p insns
	$(INSNGEN_VMGEN) $(INSNGEN_FLAGS) \
		-Xgen:type_label true \
		-Xcmp:tree_layer p0:p1:p2:h0:h1:h2 \
		$(DATATYPES) $< $(OPERANDSPEC) insns
endif
endif

# generate si-otspec/*.ot for each superinsns
SI_OTSPEC_DIR = si/otspec
SI_OTSPECS = $(patsubst %,$(SI_OTSPEC_DIR)/%.ot,$(SUPERINSNS))
ifeq ($(SUPERINSN_CUSTOMIZE_OT),true)
$(SI_OTSPECS): $(OPERANDSPEC) $(SUPERINSNSPEC)
	mkdir -p $(SI_OTSPEC_DIR)
	$(GOTTA) --gen-ot-spec $(patsubst $(SI_OTSPEC_DIR)/%.ot,%,$@) -o $@
else
$(SI_OTSPECS): $(OPERANDSPEC)
	mkdir -p $(SI_OTSPEC_DIR)
	cp $< $@
endif


# generate insns/*.inc for each superinsns
ifeq ($(DATATYPES),)
$(INSN_SUPERINSNS):
	echo "Superinstruction needs DATATYPES specified"
	exit 1
else

SI_IDEF_DIR = si/idefs
orig_insn = \
    $(shell $(GOTTA) --print-original-insn-name $(patsubst insns/%.inc,%,$1))
tmp_idef = $(SI_IDEF_DIR)/$(patsubst insns/%.inc,%,$1)

ifeq ($(SUPERINSN_PSEUDO_IDEF),true)
ifeq ($(USE_VMDL), true)
$(INSN_SUPERINSNS):insns/%.inc: $(EJSVM_DIR)/insns-vmdl/* $(SUPERINSNSPEC) $(SI_OTSPEC_DIR)/%.ot $(VMDL)
	mkdir -p $(SI_IDEF_DIR)
	$(GOTTA) \
		--gen-pseudo-vmdl $(call orig_insn,$@) $(patsubst insns/%.inc,%,$@) \
		-o $(call tmp_idef,$@).vmd
	mkdir -p insns
	$(INSNGEN_VMDL) $(VMDLC_FLAGS) \
		-Xgen:label_prefix $(patsubst insns/%.inc,%,$@) \
		-Xcmp:tree_layer p0:p1:p2:h0:h1:h2 \
		-d $(DATATYPES) \
		-i $(EJSVM_DIR)/instructions.def \
		-o $(patsubst insns/%.inc,$(SI_OTSPEC_DIR)/%.ot,$@) \
		$(call tmp_idef,$@).vmd > $@ || (rm $@; exit 1)
else
$(INSN_SUPERINSNS):insns/%.inc: $(EJSVM_DIR)/insns-def/* $(SUPERINSNSPEC) $(SI_OTSPEC_DIR)/%.ot $(VMGEN)
	mkdir -p $(SI_IDEF_DIR)
	$(GOTTA) \
		--gen-pseudo-idef $(call orig_insn,$@) \
		-o $(call tmp_idef,$@).idef
	mkdir -p insns
	$(INSNGEN_VMGEN) $(INSNGEN_FLAGS) \
		-Xgen:label_prefix $(patsubst insns/%.inc,%,$@) \
		-Xcmp:tree_layer p0:p1:p2:h0:h1:h2 $(DATATYPES) \
		$(call tmp_idef,$@).idef \
		$(patsubst insns/%.inc,$(SI_OTSPEC_DIR)/%.ot,$@) > $@ || (rm $@; exit 1)
endif
else
ifeq ($(USE_VMDL), true)
$(INSN_SUPERINSNS):insns/%.inc: $(EJSVM_DIR)/insns-vmdl/* $(SUPERINSNSPEC) $(SI_OTSPEC_DIR)/%.ot $(VMDL)
	mkdir -p insns-vmdl
	$(CPP_VMDL) $(EJSVM_DIR)/insns-vmdl/$(call orig_insn,$@).vmd > insns-vmdl/$(call orig_insn,$@).vmd || (rm $@; exit 1)
	mkdir -p insns
	$(INSNGEN_VMDL) $(VMDLC_FLAGS) \
		-Xgen:label_prefix $(patsubst insns/%.inc,%,$@) \
		-Xcmp:tree_layer p0:p1:p2:h0:h1:h2 \
		-d $(DATATYPES) \
		-i $(EJSVM_DIR)/instructions.def \
		-o $(patsubst insns/%.inc,$(SI_OTSPEC_DIR)/%.ot,$@) \
		insns-vmdl/$(call orig_insn,$@).vmd > $@ || (rm $@; exit 1)
else
$(INSN_SUPERINSNS):insns/%.inc: $(EJSVM_DIR)/insns-def/* $(SUPERINSNSPEC) $(SI_OTSPEC_DIR)/%.ot $(VMGEN)
	mkdir -p insns
	$(INSNGEN_VMGEN) $(INSNGEN_FLAGS) \
		-Xgen:label_prefix $(patsubst insns/%.inc,%,$@) \
		-Xcmp:tree_layer p0:p1:p2:h0:h1:h2 $(DATATYPES) \
		$(EJSVM_DIR)/insns-def/$(call orig_insn,$@).idef \
		$(patsubst insns/%.inc,$(SI_OTSPEC_DIR)/%.ot,$@) > $@ || (rm $@; exit 1)
endif
endif
endif

instructions.h: instructions-opcode.h instructions-table.h

%.c:: $(EJSVM_DIR)/%.c
	cp $< $@

%.h:: $(EJSVM_DIR)/%.h
	cp $< $@

object.o: object-compat.c

vmloop.o: vmloop.c vmloop-cases.inc $(INSN_FILES) $(HFILES)
	$(CC) -c $(CFLAGS) $(C_FLAGS) $(INCLUDE_PATHS) $(CFLAGS_VMDL) -o $@ $<

%.o: %.c $(HFILES)
	$(CC) -c $(CFLAGS) $(C_FLAGS) $(INCLUDE_PATHS) -o $@ $<

#### vmgen
$(VMGEN):
	(cd $(VMGEN_DIR); ant)

#### vmdl
$(VMDL):
	(cd $(VMDL_DIR); ant)

#### ejsc
$(EJSC): $(VMGEN) ejsvm.spec
	(cd $(EJSC_DIR); ant clean; ant -Dspecfile=$(PWD)/ejsvm.spec)

#### ejsi
$(EJSI):
	make -C $(EJSI_DIR)

#### check

CHECKFILES   = $(patsubst %.c,$(CHECKFILES_DIR)/%.c,$(CFILES))
CHECKRESULTS = $(patsubst %.c,$(CHECKFILES_DIR)/%.c.checkresult,$(CFILES))
CHECKTARGETS = $(patsubst %.c,%.c.check,$(CFILES))

ifeq ($(USE_VMDL),true)
types-generated.h: $(DATATYPES) $(VMDL)
	$(TYPESGEN_VMDL) $< > $@ || (rm $@; exit 1)
else
types-generated.h: $(DATATYPES) $(VMGEN)
	$(TYPESGEN_VMGEN) $< > $@ || (rm $@; exit 1)
endif

$(CHECKFILES):$(CHECKFILES_DIR)/%.c: %.c $(HFILES)
	mkdir -p $(CHECKFILES_DIR)
	$(CPP) $(CFLAGS) -DCOCCINELLE_CHECK=1 $< > $@ || (rm $@; exit 1)

$(CHECKFILES_DIR)/vmloop.c: vmloop-cases.inc $(INSN_FILES)

.PHONY: %.check
$(CHECKTARGETS):%.c.check: $(CHECKFILES_DIR)/%.c
	$(COCCINELLE) --sp-file $(GCCHECK_PATTERN) $<

$(CHECKRESULTS):$(CHECKFILES_DIR)/%.c.checkresult: $(CHECKFILES_DIR)/%.c
	$(COCCINELLE) --sp-file $(GCCHECK_PATTERN) $< > $@ || (rm $@; exit 1)

check: $(CHECKRESULTS)
	cat $^

endif # mbed end

#### clean

clean:
	rm -f *.o $(GENERATED_HFILES) vmloop-cases.inc *.c *.h
	rm -rf insns
	rm -f *.checkresult
	rm -rf $(CHECKFILES_DIR)
	rm -rf si
	rm -rf insns-vmdl
	rm -f ejsvm ejsvm.spec ejsi ejsc.jar
	$(call RM,$(OBJDIR))

cleanest:
	rm -f *.o $(GENERATED_HFILES) vmloop-cases.inc *.c *.h
	rm -rf insns
	rm -f *.checkresult
	rm -rf $(CHECKFILES_DIR)
	rm -rf si
	rm -rf insns-vmdl
	rm -f ejsvm ejsvm.spec ejsi ejsc.jar
	(cd $(VMGEN_DIR); ant clean)
	rm -f $(VMGEN)
	(cd $(VMDL_DIR); ant clean)
	rm -f $(VMDL)
	(cd $(EJSC_DIR); ant clean)
	rm -f $(EJSC)
	make -C $(EJSI_DIR) clean
	$(call RM,$(OBJDIR))
