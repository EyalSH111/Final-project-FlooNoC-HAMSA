#!/usr/bin/env python3
"""Regenerate src/ips/floo_noc/floo_noc_deps.f with portable $PULP_ENV paths only."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "src" / "ips" / "floo_noc"
OUT = ROOT / "floo_noc_deps.f"

# TB / verification / XRUN-problematic (see gen_floo_noc_irun_f.py)
SKIP = frozenset(
    {
        "axi_test.sv",
        "axi_chan_compare.sv",
        "axi_dumper.sv",
        "axi_sim_mem.sv",
        "clk_mux_glitch_free.sv",
        "popcount.sv",
        "ring_buffer.sv",
        "mem_to_banks.sv",
        "mem_to_banks_detailed.sv",
        "axi_to_mem.sv",
        "axi_to_detailed_mem.sv",
        "axi_to_mem_banked.sv",
        "axi_to_mem_interleaved.sv",
        "axi_to_mem_split.sv",
        "axi_zero_mem.sv",
        "axi_bus_compare.sv",
        "axi_slave_compare.sv",
        "heaviside.sv",
        "stream_omega_net.sv",
    }
)

# Already in HAMSA / riscv-dbg file lists — compiling twice causes duplicate-module errors.
HAMSA_DUPLICATE_BASENAMES = frozenset(
    {
        "cdc_2phase.sv",
        "fifo_v2.sv",
        "fifo_v3.sv",
        "rr_arb_tree.sv",
        "id_queue.sv",
    }
)

SKIP_SUBSTR = (
    "/test/",
    "/tests/",
    "/tb/",
    "/deprecated/",
    "hw/test/",
    "hw/tb/",
)

# Cadence XRUN: packages must compile before modules that import them.
PKG_FIRST = (
    "deps/common_cells/src/cf_math_pkg.sv",
    "deps/common_cells/src/ecc_pkg.sv",
    "deps/common_cells/src/cb_filter_pkg.sv",
    "deps/common_cells/src/cdc_reset_ctrlr_pkg.sv",
    "deps/axi/src/axi_pkg.sv",
)


def should_skip(sv: Path) -> bool:
    rel = sv.relative_to(ROOT).as_posix()
    if sv.name in SKIP or sv.name in HAMSA_DUPLICATE_BASENAMES:
        return True
    if sv.name.endswith("_tb.sv"):
        return True
    return any(part in rel for part in SKIP_SUBSTR)


def compile_order_key(sv: Path) -> tuple:
    rel = sv.relative_to(ROOT).as_posix()
    if rel in PKG_FIRST:
        return (0, PKG_FIRST.index(rel))
    if sv.name.endswith("_pkg.sv"):
        return (1, rel)
    if sv.name == "axi_intf.sv":
        return (2, rel)
    return (3, rel)


def main() -> None:
    files = [sv for sv in (ROOT / "deps").rglob("*.sv") if not should_skip(sv)]
    files.sort(key=compile_order_key)

    lines = [
        "// floo_noc_deps.f - vendored axi + common_cells ($PULP_ENV paths only)\n",
        "// Regenerate: python3 scripts/gen_floo_noc_deps_f.py\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells\n",
    ]
    for sv in files:
        rel = sv.relative_to(ROOT).as_posix()
        lines.append(f"$PULP_ENV/src/ips/floo_noc/{rel}\n")
    OUT.write_text("".join(lines), encoding="utf-8")
    print(f"wrote {OUT} ({len(lines)} lines, {len(files)} sources)")


if __name__ == "__main__":
    main()
