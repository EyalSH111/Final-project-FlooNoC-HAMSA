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


def main() -> None:
    lines = [
        "// floo_noc_deps.f - vendored axi + common_cells ($PULP_ENV paths only)\n",
        "// Regenerate: python3 scripts/gen_floo_noc_deps_f.py\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells/include\n",
        "+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells\n",
    ]
    for sv in sorted((ROOT / "deps").rglob("*.sv")):
        if sv.name in SKIP:
            continue
        rel = sv.relative_to(ROOT).as_posix()
        lines.append(f"$PULP_ENV/src/ips/floo_noc/{rel}\n")
    OUT.write_text("".join(lines), encoding="utf-8")
    print(f"wrote {OUT} ({len(lines)} lines)")


if __name__ == "__main__":
    main()
