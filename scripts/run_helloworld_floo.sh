#!/usr/bin/env bash
# Full Floo helloworld sim: verify RTL revision, wipe Xcelium snapshot, make run, check log.
set -euo pipefail

ROOT="${PULP_ENV:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT"
export PULP_ENV="$ROOT"

echo "=== repo: $ROOT ==="
git fetch origin ddp23_pnx_PoC 2>/dev/null || true
git pull origin ddp23_pnx_PoC

REV=$(git rev-parse --short HEAD)
echo "=== HEAD: $REV ==="

# 7ba341c fixes sim.make: REBUILD=true on 5121e38 only ran rm and never started irun.
if ! git merge-base --is-ancestor 7ba341c HEAD 2>/dev/null; then
  echo "ERROR: need git commit 7ba341c or newer (sim.make run fix). Run: git pull origin ddp23_pnx_PoC"
  exit 1
fi

if ! grep -q '\[FLOO_BUILD\].*RTL_SIM' src/ips/pulpenix/src/soc/msystem.sv; then
  echo "ERROR: RTL missing stage-1 Floo RTL_SIM markers in msystem.sv (git pull?)."
  exit 1
fi

APP=helloworld
LOG="${APP}/xrun.log"
# Avoid stale xrun.log when backup rotation did not move helloworld (e.g. helloworld.1 exists).
rm -f "$LOG" "${APP}.1/xrun.log" 2>/dev/null || true
rm -rf "${APP}/xcelium.d" "${APP}/INCA_libs"

echo "=== make run (full compile + irun; may take several minutes) ==="
make -f src/tb/sim.make APP="${APP}" run XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"

if [ ! -f "$LOG" ]; then
  echo "ERROR: $LOG not created — irun did not run. Check make output above for errors."
  exit 1
fi

echo "=== log checks: $LOG ==="
grep -E 'FLOO_BUILD|FLOO_BOOT|FLOO_STIM|FLOO_MON|Hey|FINISH' "$LOG" || true

if ! grep -q '\[FLOO_BUILD\]' "$LOG"; then
  echo "ERROR: xrun.log missing [FLOO_BUILD] (stale snapshot or elaboration failed)."
  exit 1
fi

if grep -q 'TIMEOUT waiting for b_valid' "$LOG"; then
  echo "WARN: b_valid timeout (unexpected after ffa374a RTL_SIM shims)."
fi

if grep -q 'Hey we use floonoc' "$LOG" || grep -qF '--- FINISH ---' "$LOG"; then
  echo "PASS: UART / finish seen in log."
else
  echo "WARN: no Hey/FINISH — paste FLOO_BUILD + FLOO_BOOT from $LOG"
fi
