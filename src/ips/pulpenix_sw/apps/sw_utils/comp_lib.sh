# Compile C source

echo "Compiling lib $1/$2"
set new_path = "${RISCV_PULP_LIBS}/$1/../$2.s"
echo "File $RISCV_PULP_LIBS/$1/$2 --> $new_path"

$RISCV_GCC_BIN/$RISCV_XX-gcc -O3 -march=rv32im -mabi=ilp32 \
-S  -Wextra -Wall  \
-Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
-fdata-sections -ffunction-sections -fdiagnostics-color=always \
-Wimplicit-fallthrough=0 \
-I$RISCV_PULP_LIBS/sys_lib/inc \
-I$RISCV_PULP_LIBS/string_lib/inc \
-I$RISCV_PULP_LIBS/bench_lib/inc \
-I$RISCV_PULP_LIBS/iosim_lib/inc \
-I$RISCV_PULP_LIBS/bm_printf_lib \
-I$RISCV_PULP_LIBS/uart/inc \
-I$RISCV_PULP_LIBS/bm_print_scan_uart \
$RISCV_PULP_LIBS/$1/$2 -o $new_path
