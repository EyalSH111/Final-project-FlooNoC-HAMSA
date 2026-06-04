HOST = $(shell hostname)

TOOLCHAIN ?= pulp


ifeq (${TOOLCHAIN}, wd)
  PREFIX = /usr/local/wd_gnu_toolchain/bin/riscv64-unknown-elf
  MARCH ?= rv32im
  # MARCH options {rv32im, rv32imc}
endif
ifeq (${TOOLCHAIN}, pulp)
  # toolchain downloaded from: https://www.embecosm.com/resources/tool-chain-downloads/#pulp
  PREFIX = ${PULP_GCC_BIN}/riscv32-unknown-elf
  MARCH ?= rv32imxpulpv3
  # MARCH options {rv32im, rv32imc, rv32imxpulpv3, rv32imcxpulpv3}
endif

ifeq (${TOOLCHAIN}, riscv)
  PREFIX = /opt/pulp/toolchain/gnu-mcu-eclipse/7.2.0-2-20180111-2230/bin/riscv-none-embed
  MARCH ?= rv32im
  # MARCH options {rv32im, rv32imc}
endif

CC = 		${PREFIX}-gcc
OBJDUMP =	${PREFIX}-objdump
OBJCOPY =	${PREFIX}-objcopy

PULP_APPS = ${PULP_ENV}/src/ips/pulpenix_sw/apps
PULP_SW_UTILS = ${PULP_APPS}/sw_utils
S19TOSLM = ${PULP_SW_UTILS}/s19toslm.py
S19TOSFLASH = ${PULP_SW_UTILS}/s19tosflash.py
PULP_LIBS = ${PULP_APPS}/libs
PULP_SW_APPS_REF = ${PULP_APPS}/ref

DI_EN?=true
DCACHE_EN?=true
ICACHE_EN?=false


ifeq (${PIE}, true)
	OPT ?= -O3 -fPIE -fpic
else
	OPT ?= -O3
	# OPT options {-O1 -O2 -O3 -Os -Og -Ofast}
endif

TEST ?= $(shell basename $(CURDIR))

OBJ =	build/test.o \
		${PULP_LIBS}/build/crt0.riscv.tmp_no_eret.o  \
		${PULP_LIBS}/build/bench.o \
		${PULP_LIBS}/build/qprintf.o \
		${PULP_LIBS}/build/exceptions.o \
		${PULP_LIBS}/build/gpio.o \
		${PULP_LIBS}/build/i2c.o \
		${PULP_LIBS}/build/int.o \
		${PULP_LIBS}/build/spi.o \
		${PULP_LIBS}/build/timer.o \
		${PULP_LIBS}/build/uart.o \
		${PULP_LIBS}/build/utils.o \
		${PULP_LIBS}/build/bm_printf.o \
		${PULP_LIBS}/build/ddr_lib.o \
		${PULP_LIBS}/build/iosim.o \
		${PULP_LIBS}/build/pnx_util.o \
		${PULP_LIBS}/build/hamsa_config.o \
		${PULP_LIBS}/build/rcg.o \
		${PULP_LIBS}/build/gp_dma.o \
		${PULP_LIBS}/build/carp.o \
		${PULP_LIBS}/build/edram_bist.o \
		${PULP_LIBS}/build/io_ctrl.o \

#FPGNIX
OBJ := $(filter-out %spi.o, ${OBJ})
OBJ := $(filter-out %edram_bist.o, ${OBJ})

LIB_SRC := $(shell find ${PULP_LIBS} -name '*.[ch]')

BAUD_RATE?=115200
CLK_PERIOD?=100

PLATFORM?=LEO_I

DEFSYM_EDRAM = 'LinkWithoutEdram=1'
DEFSYM_CORE  = 'LinkXcore=1'

all: sflash_stim.slm build/flash.elf_read flash_stim.slm build/test.elf_read 

#COMPILE ${TEST}.c
build/test.o: ${TEST}.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32  \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/sys_lib/inc \
	-I${PULP_LIBS}/string_lib/inc \
	-I${PULP_LIBS}/bench_lib/inc \
	-I${PULP_LIBS}/bm_printf_lib \
	-I${PULP_LIBS}/iosim_lib/inc \
	-I${PULP_LIBS}/ddr_lib \
	-I./ \
	${INCDIR} \
	-DBAUD_RATE=${BAUD_RATE} -DCLK_PERIOD=${CLK_PERIOD} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@


## LINK ###
build/test.elf: ${OBJ}
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32  \
	-Wextra -Wall \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always  \
	-I${PULP_LIBS}/sys_lib/inc \
	-I${PULP_LIBS}/bm_printf_lib \
	-I${PULP_LIBS}/iosim_lib/inc \
	-I${PULP_LIBS}/ddr_lib \
	-L${PULP_SW_APPS_REF} \
	-T${PULP_SW_APPS_REF}/link.riscv.ld -nostartfiles -Wl,--gc-sections \
	-D__riscv__ \
	-Wl,'--defsym',${DEFSYM_EDRAM} \
	-Wl,'--defsym',${DEFSYM_CORE} \
	${OBJ} 	-o $@


#### test code ####

## ELF-READ #
build/%.elf_read: build/%.elf
	mkdir -p build
	$(OBJDUMP) -S -g -d $< > $@

#### S19 ####
build/%.s19: build/%.elf
	mkdir -p build
	$(OBJCOPY) --srec-len 1 --output-target=srec $< $@

#### SLM ####
flash_stim.slm  l2_ram_cut0_hi.slm  l2_ram_cut0_lo.slm  l2_stim.slm  tcdm_bank0.slm: build/test.s19
	mkdir -p build
	$(S19TOSLM) build/test.s19 ${CORE}



#### sFlash boot code ####

## ELF-READ #
build/flash.elf_read: ${PULP_LIBS}/build/flash.o
	mkdir -p build
	$(OBJDUMP) -S -g -d $< > $@

#### S19 ####
build/flash.s19: ${PULP_LIBS}/build/flash.o
	mkdir -p build
	$(OBJCOPY) --srec-len 1 --output-target=srec $< $@

#### SLM ####
sflash_stim.slm: build/flash.s19	
	mkdir -p build
	$(S19TOSFLASH) build/flash.s19



#### boot dma code ####

### ELF-READ boot#
build/boot_dma.elf_read: ${PULP_LIBS}/build/boot_dma.o
	mkdir -p build
	$(OBJDUMP) -S -g -d $< > $@
    
##### S19 boot ####
build/boot_dma.s19: ${PULP_LIBS}/build/boot_dma.o
	mkdir -p build
	$(OBJCOPY) --srec-len 1 --output-target=srec $< $@

#### SLM ####
sflash_stim_boot_dma.slm: build/test.s19 build/boot_dma.s19
	mkdir -p build
	$(S19TOSFLASH) build/test.s19 build/boot_dma.s19



.PHONY: clean
clean:
	\rm -rf ./build *.slm *.elf_read

.POHNY: cleanall
cleanall: clean
	$(MAKE) clean --directory=${PULP_LIBS}


#### LIB ####
${PULP_LIBS}/build/%.o: ${LIB_SRC}
	$(MAKE) --directory=${PULP_LIBS} MARCH=${MARCH} OPT="${OPT}" PLATFORM=${PLATFORM} TOOLCHAIN=${TOOLCHAIN} INCDIR=${INCDIR} DI_EN=${DI_EN} DCACHE_EN=${DCACHE_EN} ICACHE_EN=${ICACHE_EN} BAUD_RATE=${BAUD_RATE} CLK_PERIOD=${CLK_PERIOD}
