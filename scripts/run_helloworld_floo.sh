#!/usr/bin/env bash
# Full Floo helloworld sim: verify RTL revision, wipe Xcelium snapshot, make, check log.
set -euo pipefail

ROOT="${PULP_ENV:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"
export PULP_ENV="$ROOT"

echo "=== repo: $ROOT ==="
git fetch origin ddp23_pnx_PoC 2>/dev/null || true
git pull origin ddp23_pnx_PoC

REV=$(git rev-parse --short HEAD)
echo "=== HEAD: $REV ==="

if ! grep -q 'xtrn slv B/R' src/ips/pulpenix/src/soc/msystem.sv; then
  echo "ERROR: RTL missing ffa374a+ fixes (need 'xtrn slv B/R' in msystem.sv). git pull failed or wrong tree."
  exit 1
fi

APP=helloworld
rm -rf "${APP}/xcelium.d" "${APP}/INCA_libs"
make -f src/tb/sim.make APP="${APP}" REBUILD=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"

LOG="${APP}/xrun.log"
echo "=== log checks: $LOG ==="
grep -E 'FLOO_BUILD|FLOO_BOOT|FLOO_STIM|FLOO_MON|Hey|FINISH' "$LOG" || true

if ! grep -q 'xtrn slv B/R' "$LOG"; then
  echo "ERROR: xrun.log still shows OLD elaboration (no 'xtrn slv B/R' in FLOO_BUILD)."
  echo "       Do not use 'xcelium> run' on an old snapshot. This script wiped xcelium.d — if you still see old text, check PULP_ENV points here."
  exit 1
fi

if grep -q 'TIMEOUT waiting for b_valid' "$LOG"; then
  echo "WARN: b_valid timeout still present (unexpected after ffa374a)."
fi

if grep -q 'Hey we use floonoc' "$LOG" || grep -q 'FINISH' "$LOG"; then
  echo "PASS: UART / finish seen in log."
else
  echo "WARN: no Hey/FINISH yet — paste FLOO_BUILD + FLOO_BOOT lines for debug."
fi
