#!/usr/bin/env bash
set -euo pipefail
ROOT="${PULP_ENV:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"
fail=0

if [[ -d src/ips/floo_noc/deps/common_cells/src ]]; then
  echo "FAIL: $ROOT/src/ips/floo_noc/deps/common_cells/src still exists (run fix_floo_xrun_dupuni.sh)"
  fail=1
fi

sv_vendor=$(find src/ips/floo_noc/deps/common_cells -type f -name '*.sv' ! -path '*/include/*' 2>/dev/null | head -5 || true)
if [[ -n "$sv_vendor" ]]; then
  echo "FAIL: vendored .sv under deps/common_cells (not include):"
  echo "$sv_vendor"
  fail=1
fi

if grep -q 'floo_noc/deps/common_cells/src' src/ips/floo_noc/floo_noc_deps.f 2>/dev/null; then
  echo "FAIL: floo_noc_deps.f still lists floo_noc/deps/common_cells/src"
  fail=1
fi
if grep -q 'floo_noc/deps/axi/src' src/ips/floo_noc/floo_noc_deps.f 2>/dev/null; then
  echo "FAIL: floo_noc_deps.f still lists deps/axi/src (use xrun_compat/axi_sim)"
  fail=1
fi
if ! grep -q 'src/ips/common_cells' src/ips/floo_noc/floo_noc_deps.f 2>/dev/null; then
  echo "FAIL: floo_noc_deps.f must list src/ips/common_cells (HAMSA tree)"
  fail=1
fi
if [[ ! -f src/ips/floo_noc/xrun_compat/axi_sim/axi_pkg.sv ]]; then
  echo "FAIL: missing xrun_compat/axi_sim/axi_pkg.sv"
  fail=1
fi
if grep -q '^+INCDIR+$PULP_ENV/src/$' src/tb/fpgnix_tb.f 2>/dev/null; then
  echo "FAIL: fpgnix_tb.f still has broad +INCDIR+\$PULP_ENV/src/"
  fail=1
fi

if [[ $fail -eq 0 ]]; then
  echo "OK: Floo XRUN dep layout looks safe"
else
  exit 1
fi
