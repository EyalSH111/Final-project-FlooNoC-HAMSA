#!/usr/bin/env python3
"""Regenerate src/ips/floo_noc/floo_noc_deps.f for HAMSA + Cadence XRUN.

Use ONE common_cells tree ($PULP_ENV/src/ips/common_cells). Never list .sv under
floo_noc/deps/common_cells/vendor_src_not_for_xrun (reference only).

AXI: use xrun_compat/axi_sim/ only — not deps/axi/src/ (XRUN 23.x compiles every .sv
in the same directory as any listed file, which duplicates HAMSA modules).
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FLOO = ROOT / "src" / "ips" / "floo_noc"
HAMSA_CC = ROOT / "src" / "ips" / "common_cells"
OUT = FLOO / "floo_noc_deps.f"

# Paths written into .f (must exist under repo).
DEPS_SOURCES = (
    # packages first
    "src/ips/common_cells/src/cf_math_pkg.sv",
    "src/ips/floo_noc/xrun_compat/axi_sim/axi_pkg.sv",
    # not axi_intf.sv — duplicates HAMSA AXI_BUS in pulpenix/src/soc/includes/axi_bus.sv
    # HAMSA common_cells (shared with riscv-dbg / pulpenix — compile once)
    "src/ips/common_cells/src/sync.sv",
    "src/ips/common_cells/src/binary_to_gray.sv",
    "src/ips/common_cells/src/gray_to_binary.sv",
    "src/ips/common_cells/src/addr_decode.sv",
    "src/ips/common_cells/src/lzc.sv",
    # HAMSA tree has spill_register.sv only; flushable lives under floo_noc/xrun_compat (solo file)
    "src/ips/floo_noc/xrun_compat/spill_register_flushable.sv",
    "src/ips/common_cells/src/spill_register.sv",
    "src/ips/common_cells/src/stream_fifo.sv",
    "src/ips/floo_noc/xrun_compat/stream_fifo_optimal_wrap.sv",
    "src/ips/common_cells/src/stream_register.sv",
    "src/ips/common_cells/src/stream_arbiter_flushable.sv",
    "src/ips/common_cells/src/stream_arbiter.sv",
    "src/ips/common_cells/src/cdc_fifo_gray.sv",
    # Floo-specific vendored axi only
    "src/ips/floo_noc/xrun_compat/axi_sim/axi_err_slv.sv",
    "src/ips/floo_noc/xrun_compat/axi_sim/axi_demux_simple.sv",
)


def main() -> None:
    lines = [
        "// floo_noc_deps.f — FlooNoC deps for HAMSA sim (auto-generated)\n",
        "// Regenerate: python3 scripts/gen_floo_noc_deps_f.py\n",
        "// common_cells: ONLY $PULP_ENV/src/ips/common_cells (never deps/common_cells/vendor_src_*)\n",
        "// axi sim: ONLY xrun_compat/axi_sim (never deps/axi/src/*.sv)\n",
        "+incdir+$PULP_ENV/src/ips/common_cells/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include\n",
    ]
    for rel in DEPS_SOURCES:
        path = ROOT / rel
        if not path.is_file():
            raise SystemExit(f"MISSING: {path}")
        lines.append(f"$PULP_ENV/{rel.replace(chr(92), '/')}\n")
    OUT.write_text("".join(lines), encoding="utf-8")
    print(f"wrote {OUT} ({len(DEPS_SOURCES)} sources)")


if __name__ == "__main__":
    main()
