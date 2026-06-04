APP ?= fpgnix_smile
PREFIX ?= /project/generic/users/udik/ws/pulp/toolchain/gnu-mcu-eclipse/7.2.0-2-20180111-2230/bin/riscv-none-embed

_COREMARK = coremark
_SELFIE = selfie5
_TFLITE = tflite

ifeq ($(APP), $(_COREMARK))
	_MAKEFILE = Makefile_coremark  
else ifeq ($(APP), $(_TFLITE))
	_MAKEFILE = Makefile_tflite   
else ifeq ($(APP), $(_SELFIE))
	_MAKEFILE = Makefile_selfie5
else ifeq ($(ELF), true)
	_MAKEFILE = Makefile_elf
else
	_MAKEFILE = Makefile
endif

#_MAKEFILE = Makefile_coremark

PULP_APPS = ${PULP_ENV}/src/ips/pulpenix_sw/apps
PULP_SW_UTILS = ${PULP_APPS}/sw_utils
PULP_LIBS = ${PULP_APPS}/libs
APP_SRC_DIR ?= ${PULP_APPS}/${APP}
APP_RUN_DIR ?= ${APP}
REMOTE_BITBANG_DIR = ${PULP_ENV}/src/ips/riscv/tb/dm/remote_bitbang
LIBRARIES = 
SW_INCDIR = ${PULP_ENV}/src/ips/pulpenix/src/fpga

COVERAGE    ?= false
SPIKE       ?= false
RTL_SIM     ?= true

DI          ?= true

CACHE       ?= false

GUI         ?= false
MMAP        ?= $(GUI)
PROBE       ?= false

ALTERA      = TRUE

SOCKET      ?= false
TXONLY      ?= false
TELNET      ?= false
PYSHELL     ?= false
JTAG_UART   ?= false

TRACE       ?= true

QRUN				= DISPLAY=${DISPLAY} qrsh -V -cwd
IRUN      			= irun -unbuffered -sv -v93  -access rw +TB=tb -timescale 1ns/1ps +define+STD_SIM +define+HAMSA_DIX +define+HAMSA_PREFETCH -top fpgnix_tb
IRUN_F_FILES	= -f ${PULP_ENV}/src/tb/fpgnix_tb.f

_XRUN_FLAGS = ${XRUN_FLAGS}
ifeq ($(GUI), true)
    _XRUN_FLAGS += -gui
endif

ifeq ($(MMAP), true)
	_XRUN_FLAGS += -input ${PULP_ENV}/src/tb/mmap.tcl
endif

ifeq ($(RTL_SIM), true)
    _XRUN_FLAGS += +define+RTL_SIM +define+FAKED_FAST_SIM_ALTPLL +define+SMART_UART_TB_NON_R2D2
endif

ifeq ($(DI), true)
    _XRUN_FLAGS += +define+HAMSA_DI
    INSTR_WIDTH = 4
else
    INSTR_WIDTH = 1
endif

ifeq ($(CACHE), true)
   _XRUN_FLAGS += +define+CACHE
endif

_XRUN_FLAGS += +define+ALTERA
_XRUN_FLAGS += -f ${PULP_ENV}/src/tb/altera.f
CLK_PERIOD = 100
BAUD_RATE ?= 115200
_XRUN_FLAGS += +define+CLK_PERIOD=${CLK_PERIOD}
_XRUN_FLAGS += +define+BAUD_RATE=${BAUD_RATE}

ifeq ($(TELNET), true)
    SOCKET = true
    _XRUN_FLAGS += +define+R2D2_TELNET

    TXONLY  = false
    PYSHELL = false
    JTAG_UART = false
endif

ifeq ($(PYSHELL), true)
    SOCKET = true
    _XRUN_FLAGS += +define+R2D2_PYSHELL

    TXONLY  = false
    TELNET  = false
    JTAG_UART = false
endif

ifeq ($(JTAG_UART), true)
    SOCKET = true
    _XRUN_FLAGS += +define+R2D2_JTAG

    PYSHELL = false
    TXONLY  = false
    TELNET  = false
endif

ifeq ($(TRACE), true)
    _XRUN_FLAGS += +define+TRACE_EXECUTION
endif

ifeq ($(TXONLY), true)
    SOCKET      = true
    _XRUN_FLAGS += +define+R2D2_TXONLY

    TELNET  = false
    PYSHELL = false
    JTAG_UART = false
endif

ifeq ($(SOCKET), true)
    _XRUN_FLAGS += +define+USE_SOCKET
endif


ifeq ($(PROBE), true)
    _XRUN_FLAGS += -input ${PULP_ENV}/src/tb/probe_fpga.tcl
endif

ifeq ($(JTAG_BITBANG), true)
  _XRUN_FLAGS += -L${REMOTE_BITBANG_DIR} -lrbs +define+JTAG_BITBANG
  LIBRARIES += ${REMOTE_BITBANG_DIR}/librbs.so
  TOOLCHAIN = pulp
  #TODO, support toolchain=wd?
  REMOTE_COMPILE = true
endif

TOOLCHAIN ?= pulp

ifeq ($(TOOLCHAIN), riscv)
    MARCH          ?= rv32im
    REMOTE_COMPILE ?= false
endif

ifeq ($(TOOLCHAIN), pulp)
    MARCH          ?= rv32imxpulpv3
    # REMOTE_COMPILE ?= true            ---- No longer needed , moved to /opt/pulp...
endif

ifeq ($(TOOLCHAIN), wd)
    MARCH          ?= rv32im
    REMOTE_COMPILE ?= true
endif

ifeq ($(REMOTE_COMPILE), true)
    SSH = ssh enicspulp01 -o SendEnv=PULP_ENV
else
    SSH =
endif

ifeq ($(COVERAGE), true)
  $(info ****************** COVERAGE FLAG *********************)
  _XRUN_FLAGS +=  -uvm -define COVERAGE  +licq +nowarn+CUVWSP +nowarn+LIBNOU +nowarn+SPDUSD -linedebug -uvmlinedebug -coverage all +define+DUMP+TRN +access+rc +UVM_TESTNAME=riscv_vip_base_test
  IRUN_F_FILES	= -f ${PULP_ENV}/src/tb/riscv_vip_tb.f -f ${PULP_ENV}/src/tb/fpgnix_tb.f
endif

ifeq ($(SPIKE), true)
  _XRUN_FLAGS += -L${PULP_ENV}/src/ips/spike/spike_install/lib  -lspike_dpi +define+SPIKE
  IRUN_F_FILES += -f ${PULP_ENV}/src/tb/spike_sv.f
endif


ifneq ($(COMPLIANCE),)
  _XRUN_FLAGS += +REF_FILE=$(COMPLIANCE)
  ifeq ($(PULP_SECURE), true)  
    _XRUN_FLAGS += -defparam  pulpenix_tb.msystem.core_region_i.CORE.RISCV_CORE.PULP_SECURE=1
  endif
endif

ifneq ($(TIMEOUT),)
  _XRUN_FLAGS +=  -defparam pulpenix_tb.timeout=$(TIMEOUT)
endif


.PHONY:all
all: backup run 

.PHONY:clean
clean:
	\rm -rf ${APP_RUN_DIR}/slm_files
	$(MAKE) --directory=${APP_SRC_DIR} -f ../${_MAKEFILE} clean

.PHONY:cleanall
cleanall: clean
	$(MAKE) --directory=${APP_SRC_DIR} -f ../${_MAKEFILE} cleanall

.PHONY:cleanc
cleanc:
	$(MAKE) --directory=${APP_SRC_DIR} -f ../${_MAKEFILE} cleanall

.PHONY:backup
backup:
	-rm -rf ${APP_RUN_DIR}.3
	-mv ${APP_RUN_DIR}.2 ${APP_RUN_DIR}.3
	-mv ${APP_RUN_DIR}.1 ${APP_RUN_DIR}.2
	-mv ${APP_RUN_DIR}   ${APP_RUN_DIR}.1
	mkdir -p ${APP_RUN_DIR}
	\rm -f ${APP_RUN_DIR}/app_src_dir
	ln -s ${APP_SRC_DIR} ${APP_RUN_DIR}/app_src_dir

.PHONY: run
run: compile
	mkdir -p ${APP_RUN_DIR}
	\rm -f ${APP_RUN_DIR}/app_src_dir
	ln -s ${APP_SRC_DIR} ${APP_RUN_DIR}/app_src_dir    
	cd ${APP_RUN_DIR} && ${IRUN} ${_XRUN_FLAGS} ${IRUN_F_FILES}

.PHONY: run_only
run_only: ${APP_RUN_DIR}/slm_files/app_instr.mif ${LIBRARIES}
	mkdir -p ${APP_RUN_DIR}
	\rm -f ${APP_RUN_DIR}/app_src_dir    
	ln -f -s ${APP_SRC_DIR} ${APP_RUN_DIR}/app_src_dir    
	cd ${APP_RUN_DIR} &&  ${IRUN} ${_XRUN_FLAGS} ${IRUN_F_FILES}


.PHONY: gen_floo_noc_irun_f
gen_floo_noc_irun_f:
ifeq ($(FLOO_NOC), true)
	python3 $(PULP_ENV)/scripts/gen_floo_noc_irun_f.py $(FLOO_NOC_ROOT)
endif

.PHONY: xrun-errors
xrun-errors:
	@grep '\*E' $(APP_RUN_DIR)/xrun.log 2>/dev/null | head -20 || echo "No xrun.log or no *E lines in $(APP_RUN_DIR)/"

# Repo root from this makefile (src/tb/sim.make), not $PULP_ENV — avoids ws/ddp23/ddp23_pnx mismatch
_REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
.PHONY: fix-floo-xrun-deps
fix-floo-xrun-deps:
	@test -f $(_REPO_ROOT)/scripts/fix_floo_xrun_dupuni.sh || \
	  (echo "ERROR: missing $(_REPO_ROOT)/scripts/fix_floo_xrun_dupuni.sh — git pull on this repo"; exit 1)
	bash $(_REPO_ROOT)/scripts/fix_floo_xrun_dupuni.sh

.PHONY: compile
ifeq ($(FLOO_NOC_REGEN), 1)
compile: fix-floo-xrun-deps gen_floo_noc_irun_f ${LIBRARIES} ${APP_RUN_DIR}/slm_files/app_instr.mif
else
compile: fix-floo-xrun-deps ${LIBRARIES} ${APP_RUN_DIR}/slm_files/app_instr.mif
endif
	echo COMPILED

${APP_RUN_DIR}/slm_files/l2_stim.slm: ${APP_SRC_DIR}/*
	mkdir -p ${APP_RUN_DIR}/slm_files
	$(SSH) $(MAKE) --directory=${APP_SRC_DIR} -f ../${_MAKEFILE} TOOLCHAIN=${TOOLCHAIN} BAUD_RATE=${BAUD_RATE} CLK_PERIOD=${CLK_PERIOD} MARCH=${MARCH} PLATFORM=FPGNIX INCDIR="-I${SW_INCDIR}"
	cp ${APP_SRC_DIR}/*.slm ${APP_RUN_DIR}/slm_files
	mv ${APP_SRC_DIR}/*.slm ${APP_SRC_DIR}/build
	mv ${APP_SRC_DIR}/spi_stim.txt ${APP_SRC_DIR}/build
	cp ${APP_SRC_DIR}/build/test.elf ${APP_RUN_DIR}/slm_files
	cp ${APP_SRC_DIR}/build/test.elf_read ${APP_RUN_DIR}/slm_files/app_elf_read.txt
	[ "$(MMAP)" == "true" ] && python ${PULP_ENV}/src/tb/mmap_gen.py ${APP_SRC_DIR}/build/test.elf_read ${PULP_ENV}/src/tb/mmap.tcl || echo "NO MMAP"
	[ "$(MMAP)" == "true" ] && cp ${PULP_ENV}/src/tb/mmap.tcl ${APP_RUN_DIR} || echo "NO MMAP"
	mv ${APP_SRC_DIR}/build/test.elf_read ${APP_SRC_DIR}/build/app_elf_read.txt

${APP_RUN_DIR}/slm_files/app_instr.mif: ${APP_RUN_DIR}/slm_files/l2_stim.slm
	cd ${APP_RUN_DIR}/slm_files && ${PULP_SW_UTILS}/slm2mif.py l2_stim.slm tcdm_bank0.slm ${INSTR_WIDTH}

.PHONY: trace
trace: run
	perl ${PULP_ENV}/src/ips/tracevis/parse.pl -i ${APP_SRC_DIR}/build/test.elf ${APP_RUN_DIR}/trace_core_00_0.log > ${APP_RUN_DIR}/trace.json

${REMOTE_BITBANG_DIR}/librbs.so:
	$(SSH) $(MAKE) -C ${REMOTE_BITBANG_DIR} all
