#!/usr/bin/env python3
"""Regenerate src/ips/floo_noc/floo_noc_deps.f — minimal RTL for HAMSA stage-1 + XRUN.

Uses HAMSA's existing src/ips/common_cells for fifo_v3, rr_arb_tree, cdc_2phase, etc.
Only lists vendored files that are unique or required before pulpenix.f.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "src" / "ips" / "floo_noc"
OUT = ROOT / "floo_noc_deps.f"

# Order matters: packages and leaf cells before parents.
DEPS_SOURCES = (
    # --- packages ---
    "deps/common_cells/src/cf_math_pkg.sv",
    "deps/axi/src/axi_pkg.sv",
    "deps/axi/src/axi_intf.sv",
    # --- common_cells (not duplicated in HAMSA pulpenix/riscv file lists) ---
    "deps/common_cells/src/sync.sv",
    "deps/common_cells/src/binary_to_gray.sv",
    "deps/common_cells/src/gray_to_binary.sv",
    "deps/common_cells/src/addr_decode.sv",
    "deps/common_cells/src/lzc.sv",
    "deps/common_cells/src/spill_register_flushable.sv",
    "deps/common_cells/src/spill_register.sv",
    "deps/common_cells/src/stream_fifo.sv",
    "deps/common_cells/src/stream_fifo_optimal_wrap.sv",
    "deps/common_cells/src/stream_register.sv",
    "deps/common_cells/src/stream_arbiter_flushable.sv",
    "deps/common_cells/src/stream_arbiter.sv",
    "deps/common_cells/src/cdc_fifo_gray.sv",
    # --- axi (Floo chimney + rob_wrapper only) ---
    "deps/axi/src/axi_err_slv.sv",
    "deps/axi/src/axi_demux_simple.sv",
)


def main() -> None:
    lines = [
        "// floo_noc_deps.f - minimal vendored deps for HAMSA + Cadence XRUN\n",
        "// Regenerate: python3 scripts/gen_floo_noc_deps_f.py\n",
        "// fifo_v3, rr_arb_tree, cdc_2phase, id_queue: from HAMSA + floo_noc.f xrun_compat\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells\n",
    ]
    for rel in DEPS_SOURCES:
        path = ROOT / rel
        if not path.is_file():
            raise SystemExit(f"MISSING: {path}")
        lines.append(f"$PULP_ENV/src/ips/floo_noc/{rel}\n")
    OUT.write_text("".join(lines), encoding="utf-8")
    print(f"wrote {OUT} ({len(DEPS_SOURCES)} sources)")


if __name__ == "__main__":
    main()
