#!/usr/bin/env bash
# One-shot fix for *E,DUPUNI (duplicate common_cells). Safe to re-run.
# Usage:  cd $PULP_ENV && bash scripts/fix_floo_xrun_dupuni.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEPS_F="$ROOT/src/ips/floo_noc/floo_noc_deps.f"
CC_VENDOR="$ROOT/src/ips/floo_noc/deps/common_cells"
AXI_SIM="$ROOT/src/ips/floo_noc/xrun_compat/axi_sim"

echo "==> Remove vendored common_cells RTL (HAMSA uses src/ips/common_cells)"
for d in src vendor_src_not_for_xrun test formal; do
  if [[ -d "$CC_VENDOR/$d" ]]; then
    rm -rf "$CC_VENDOR/$d"
    echo "    removed $CC_VENDOR/$d"
  fi
done
# Legacy path on servers that never pulled the rename
find "$CC_VENDOR" -type f -name '*.sv' ! -path '*/include/*' -delete 2>/dev/null || true

mkdir -p "$AXI_SIM"
for f in axi_pkg.sv axi_intf.sv axi_err_slv.sv axi_demux_simple.sv; do
  if [[ ! -f "$AXI_SIM/$f" ]]; then
    cp "$ROOT/src/ips/floo_noc/deps/axi/src/$f" "$AXI_SIM/$f"
  fi
done

if command -v python3 >/dev/null 2>&1 && [[ -f scripts/gen_floo_noc_deps_f.py ]]; then
  python3 scripts/gen_floo_noc_deps_f.py
else
  cat >"$DEPS_F" <<'EOF'
// floo_noc_deps.f — FlooNoC deps for HAMSA sim (fixed by scripts/fix_floo_xrun_dupuni.sh)
+incdir+$PULP_ENV/src/ips/common_cells/include
+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include
$PULP_ENV/src/ips/common_cells/src/cf_math_pkg.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/axi_sim/axi_pkg.sv
$PULP_ENV/src/ips/common_cells/src/sync.sv
$PULP_ENV/src/ips/common_cells/src/binary_to_gray.sv
$PULP_ENV/src/ips/common_cells/src/gray_to_binary.sv
$PULP_ENV/src/ips/common_cells/src/addr_decode.sv
$PULP_ENV/src/ips/common_cells/src/lzc.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/spill_register_flushable.sv
$PULP_ENV/src/ips/common_cells/src/spill_register.sv
$PULP_ENV/src/ips/common_cells/src/stream_fifo.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/stream_fifo_optimal_wrap.sv
$PULP_ENV/src/ips/common_cells/src/stream_register.sv
$PULP_ENV/src/ips/common_cells/src/stream_arbiter_flushable.sv
$PULP_ENV/src/ips/common_cells/src/stream_arbiter.sv
$PULP_ENV/src/ips/common_cells/src/cdc_fifo_gray.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/delta_counter/delta_counter.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/axi_sim/axi_err_slv.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/axi_sim/axi_demux_simple.sv
EOF
fi

FPGNIX_F="$ROOT/src/tb/fpgnix_tb.f"
if grep -q '^+INCDIR+$PULP_ENV/src/$' "$FPGNIX_F" 2>/dev/null; then
  sed -i.bak '/^+INCDIR+$PULP_ENV\/src\/$/d' "$FPGNIX_F"
  echo "==> Removed +INCDIR+\$PULP_ENV/src/ from fpgnix_tb.f"
fi

bash "$ROOT/scripts/check_floo_xrun_deps.sh"
echo "==> OK. Clean sim cache, then rebuild:"
echo "    rm -rf helloworld/xcelium.d helloworld/INCA_libs"
echo "    make -f src/tb/sim.make APP=helloworld"
