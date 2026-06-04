
# Compile C source

echo "Compiling Application $1"


$RISCV_GCC_BIN/$RISCV_XX-gcc -O3 -march=rv32im -mabi=ilp32  \
-S    -Wextra -Wall  \
-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
-fdata-sections -ffunction-sections -fdiagnostics-color=always \
-I$RISCV_PULP_LIBS/sys_lib/inc \
-I$RISCV_PULP_LIBS/string_lib/inc \
-I$RISCV_PULP_LIBS/bench_lib/inc \
-I$RISCV_PULP_LIBS/bm_print_scan_uart \
-D_UART_MODE_ -I./ ./$1.c -o $1.c.s

# Link


 $RISCV_GCC_BIN/$RISCV_XX-gcc -O3 -march=rv32im -mabi=ilp32  \
  -Wextra -Wall \
-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
-fdata-sections -ffunction-sections -fdiagnostics-color=always  \
-I$RISCV_PULP_LIBS/sys_lib/inc \
-I$RISCV_PULP_LIBS/bm_print_scan_uart \
-L$RISCV_PULP_SW_APPS_REF \
-T$RISCV_PULP_SW_APPS_REF/link.riscv_loadable.ld -nostartfiles -Wl,--gc-sections \
-D__riscv__  \
$1.c.s \
../ref/crt0.S  \
../libs/bench_lib/bench.c.s \
../libs/sys_lib/exceptions.c.s \
../libs/sys_lib/gpio.c.s \
../libs/sys_lib/i2c.c.s \
../libs/sys_lib/int.c.s \
../libs/sys_lib/spi.c.s \
../libs/sys_lib/timer.c.s \
../libs/sys_lib/uart.c.s \
../libs/sys_lib/utils.c.s \
../libs/bm_print_scan_uart/bm_print_scan_uart.c.s \
-o $1_loadable.elf


# dump object in text


$RISCV_GCC_BIN/$RISCV_XX-objdump  -g -d $1_loadable.elf > $1_loadable_elf.txt
 
# Convert 

$RISCV_GCC_BIN/$RISCV_XX-objcopy  --srec-len 1 --output-target=srec $1_loadable.elf $1_loadable.s19

$RISCV_PULP_SW_UTILS/s19to_loadh.py ./$1_loadable.s19  0x00003000 0x00101000


mv instr_loadh.txt $1_instr_loadh.txt
mv tcdm_bank0_loadh.txt $1_data_loadh.txt

 
 
