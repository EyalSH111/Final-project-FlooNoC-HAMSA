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

DI_EN?=true
ifeq (${DI_EN}, true)
	DI_INIT=DI_ON
else
	DI_INIT=DI_OFF
endif

ICACHE_EN?=false
ifeq (${ICACHE_EN}, true)
	ICACHE_INIT=ICACHE_ON
else
	ICACHE_INIT=ICACHE_OFF
endif

DCACHE_EN?=true
ifeq (${DCACHE_EN}, true)
	DCACHE_INIT=DCACHE_ON
else
	DCACHE_INIT=DCACHE_OFF
endif

BAUD_RATE?=115200
CLK_PERIOD?=100

CC = 		${PREFIX}-gcc
OBJDUMP =	${PREFIX}-objdump
OBJCOPY =	${PREFIX}-objcopy

PULP_APPS = ${PULP_ENV}/src/ips/pulpenix_sw/apps
PULP_SW_UTILS = ${PULP_APPS}/sw_utils
S19TOSLM = ${PULP_SW_UTILS}/s19toslm.py
PULP_LIBS = ${PULP_APPS}/libs
PULP_SW_APPS_REF = ${PULP_APPS}/ref

OPT ?= -O3
# OPT options {-O1 -O2 -O3 -Os -Og -Ofast}

OBJ =	build/crt0.riscv.tmp_no_eret.o  \
		build/flash.o \
		build/boot_dma.o \
		build/bench.o \
		build/qprintf.o \
		build/exceptions.o \
		build/gpio.o \
		build/i2c.o \
		build/int.o \
		build/spi.o \
		build/timer.o \
		build/uart.o \
		build/utils.o \
		build/bm_printf.o \
		build/iosim.o \
		build/rcg.o \
		build/gp_dma.o \
		build/carp.o \
		build/edram_bist.o \
		build/hamsa_config.o \
		build/pnx_util.o \
		build/io_ctrl.o \
        build/ddr_lib.o \

#FPGNIX
OBJ := $(filter-out %spi.o, ${OBJ})
OBJ := $(filter-out %edram_bist.o, ${OBJ})


PLATFORM?=LEO_I

.PHONY: all
all: ${OBJ}

.PHONY: clean
clean:
	\rm -rf ./build *.slm *.elf_read

build/%.o: sys_lib/src/%.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/sys_lib/inc \
	-I${PULP_LIBS}/string_lib/inc \
	-I${PULP_LIBS}/bench_lib/inc \
	-I${PULP_LIBS}/bm_printf_lib \
	-I./ \
    ${INCDIR} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@

build/%.o: string_lib/src/%.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/sys_lib/inc \
	-I${PULP_LIBS}/string_lib/inc \
	${INCDIR} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@

build/%.o: bench_lib/src/%.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/sys_lib/inc \
	-I${PULP_LIBS}/bench_lib/inc \
	-I${PULP_LIBS}/string_lib/inc \
	-I${PULP_LIBS}/bm_printf_lib \
	${INCDIR} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@

build/%.o: iosim_lib/src/%.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/sys_lib/inc \
	-I${PULP_LIBS}/iosim_lib/inc \
	-I${PULP_LIBS}/bm_printf_lib \
	${INCDIR} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@

build/%.o: bm_printf_lib/%.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/bm_printf_lib \
	-I${PULP_LIBS}/sys_lib/inc \
	${INCDIR} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@

build/%.o: ddr_lib/%.c
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/ddr_lib \
	-I${PULP_LIBS}/bm_printf_lib \
    -I${PULP_LIBS}/iosim_lib/inc \
    -I${PULP_LIBS}/sys_lib/inc \
	${INCDIR} \
	-D__riscv__ -D${PLATFORM} \
	$< -o $@

build/boot_dma.o: ../ref/boot_dma.S
	mkdir -p build
	$(CC) -march=rv32i -mabi=ilp32 -c $< -o $@

build/flash.o: ../ref/flash.S
	mkdir -p build
	$(CC) -c -march=rv32i -mabi=ilp32 $< -o $@

build/%.o: ../ref/%.S
	mkdir -p build
	$(CC) -ggdb -march=${MARCH} ${OPT} -mabi=ilp32 \
	-c -Wextra -Wall  \
	-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
	-fdata-sections -ffunction-sections -fdiagnostics-color=always \
	-I${PULP_LIBS}/sys_lib/inc \
	-D__riscv__ -D${PLATFORM} \
	-D${DI_INIT} \
	-D${ICACHE_INIT} \
	-D${DCACHE_INIT} \
	-DBAUD_RATE=${BAUD_RATE} \
	-DCLK_PERIOD=${CLK_PERIOD} \
	${INCDIR} \
	$< -o $@


