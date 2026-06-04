#!/usr/bin/env python3
"""Generate src/tb/floo_noc_irun.f for Cadence XRUN from FlooNoC Bender RTL sources.

Questa compile_vsim.tcl pulls simulation/test targets (axi_test.sv, common_verification,
clk_mux_glitch_free.sv). XRUN needs RTL-only: bender script flist -t rtl -t axi_mesh.

Compatible with Python 3.6+ (RC3 default python3).
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Set

# Files or path fragments that break or are unnecessary on Cadence XRUN 23.x.
XRUN_SKIP_BASENAMES = frozenset(
    {
        "axi_test.sv",
        "apb_test.sv",
        "reg_test.sv",
        "axi_chan_compare.sv",
        "axi_dumper.sv",
        "axi_sim_mem.sv",
        "clk_mux_glitch_free.sv",
        "popcount.sv",  # localparam in #( ) port list; only needed by iDMA (not mesh RTL)
        "ring_buffer.sv",  # localparam in #( ) port list; not used by Floo mesh
        "mem_to_banks.sv",
        "mem_to_banks_detailed.sv",  # localparam type in #( ) — XRUN SVVMAP; not used by mesh
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
        "clk_rst_gen.sv",
        "sim_timeout.sv",
        "stream_watchdog.sv",
        "signal_highlighter.sv",
        "rand_id_queue.sv",
        "rand_stream_mst.sv",
        "rand_stream_slv.sv",
        "rand_synch_driver.sv",
        "rand_synch_holdable_driver.sv",
        "rand_verif_pkg.sv",
    }
)

# Already compiled via HAMSA pulpenix/riscv (duplicate module if included again).
HAMSA_DUPLICATE_BASENAMES = frozenset(
    {
        "cdc_2phase.sv",
        "fifo_v2.sv",
        "fifo_v3.sv",
        "rr_arb_tree.sv",
    }
)

XRUN_SKIP_SUBSTR = (
    "/test/",
    "/tests/",
    "/tb/",
    "hw/test/",
    "hw/tb/",
    "_tb.sv",
    "common_verification",
    "checkouts/idma-",  # FlooNoC dep; only used by hw/test DMA nodes, not HAMSA mesh
    "/jobs/",
    "synth_test/",
    "axi_synth_bench",
)


def should_skip(rel):
    # type: (str) -> bool
    norm = rel.replace("\\", "/")
    base = norm.rsplit("/", 1)[-1]
    if base in XRUN_SKIP_BASENAMES:
        return True
    # PULP *_(apb|axi|reg)_test.sv packages use classes (Questa TB only).
    if base.endswith("_test.sv"):
        return True
    if base in HAMSA_DUPLICATE_BASENAMES:
        return True
    return any(s in norm for s in XRUN_SKIP_SUBSTR)


XRUN_COMPAT_FILES = frozenset(
    {
        "id_queue.sv",
        "floo_id_translation.sv",
        "floo_meta_buffer.sv",
        "floo_axi_chimney.sv",
        "floo_axi_mesh_noc.sv",
    }
)


def irun_source_line(rel):
    # type: (str) -> str
    norm = rel.replace("\\", "/")
    base = norm.rsplit("/", 1)[-1]
    if base in XRUN_COMPAT_FILES:
        if base == "id_queue.sv" and "common_cells" in norm:
            return "$PULP_ENV/src/ips/floo_noc/xrun_compat/id_queue.sv"
        if base == "floo_axi_mesh_noc.sv" and norm.startswith("generated/"):
            return "$PULP_ENV/src/ips/floo_noc/xrun_compat/floo_axi_mesh_noc.sv"
        if base in (
            "floo_id_translation.sv",
            "floo_meta_buffer.sv",
            "floo_axi_chimney.sv",
        ) and norm.startswith("hw/"):
            return "$PULP_ENV/src/ips/floo_noc/xrun_compat/{}".format(base)
    return "$FLOO_NOC_ROOT/{}".format(norm)


def rel_from_floo(floo_root, path):
    # type: (Path, str) -> Optional[str]
    p = Path(path.replace("\\", "/"))
    if p.suffix.lower() not in (".sv", ".v", ".svh", ".vh"):
        return None
    try:
        rel = p.resolve().relative_to(floo_root.resolve())
    except ValueError:
        s = path.replace("\\", "/")
        marker = "/FlooNoC/"
        idx = s.find(marker)
        if idx >= 0:
            rel = Path(s[idx + len(marker) :])
        elif s.startswith("$ROOT/"):
            rel = Path(s[len("$ROOT/") :])
        else:
            return None
    return rel.as_posix()


def collect_from_bender(floo_root):
    # type: (Path) -> Optional[List[str]]
    bender = shutil.which("bender")
    if bender is None:
        local = floo_root / "bender"
        if local.is_file():
            bender = str(local)
        else:
            return None

    cmd = [
        bender,
        "script",
        "flist",
        "-t",
        "rtl",
        "-t",
        "axi_mesh",
    ]
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(floo_root),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            check=False,
            timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        print("NOTE: bender flist failed ({}), falling back to compile_vsim.tcl".format(exc), file=sys.stderr)
        return None

    if proc.returncode != 0:
        print("NOTE: bender flist exit {}: {}".format(proc.returncode, proc.stderr.strip()), file=sys.stderr)
        return None

    files = []  # type: List[str]
    seen = set()  # type: Set[str]
    for token in proc.stdout.split():
        if token.startswith(("+", "-")):
            continue
        rel = rel_from_floo(floo_root, token)
        if rel is None or should_skip(rel):
            continue
        if rel in seen:
            continue
        seen.add(rel)
        files.append(rel)
    return files if files else None


def collect_from_vsim_tcl(floo_root):
    # type: (Path) -> List[str]
    tcl = floo_root / "scripts" / "compile_vsim.tcl"
    if not tcl.is_file():
        raise FileNotFoundError("missing {}".format(tcl))

    text = tcl.read_text(encoding="utf-8", errors="replace")
    paths = re.findall(r'"\$ROOT/([^"]+\.(?:sv|v))"', text)
    files = []  # type: List[str]
    seen = set()  # type: Set[str]
    for rel in paths:
        norm = rel.replace("\\", "/")
        if should_skip(norm):
            continue
        if norm in seen:
            continue
        seen.add(norm)
        files.append(norm)
    return files


def write_irun_f(floo_root, out, files):
    # type: (Path, Path, List[str]) -> None
    lines = [
        "// Auto-generated by scripts/gen_floo_noc_irun_f.py — do not edit by hand.",
        "// Regenerate: python3 scripts/gen_floo_noc_irun_f.py $FLOO_NOC_ROOT",
        "// RTL-only (bender -t rtl -t axi_mesh); excludes Questa/sim-only sources for XRUN.",
        "// Compile this file BEFORE fpgnix_tb.f (see sim.make).",
        "",
        "+define+TARGET_RTL",
        "+define+TARGET_AXI_MESH",
        "+define+TARGET_SIMULATION",
        "+incdir+$FLOO_NOC_ROOT/hw/include",
    ]

    inc_added = set()  # type: Set[str]
    for rel in files:
        if "checkouts/" not in rel:
            continue
        checkout = rel.split("checkouts/", 1)[1].split("/", 1)[0]
        base = "$FLOO_NOC_ROOT/.bender/git/checkouts/{}".format(checkout)
        for suffix in ("/include", ""):
            entry = base + suffix
            if entry not in inc_added:
                inc_added.add(entry)
                lines.append("+incdir+{}".format(entry))

    lines.append("")
    seen = {f.replace("\\", "/") for f in files}
    gen_pkg = "generated/floo_axi_mesh_noc_pkg.sv"
    pkg_line = "$FLOO_NOC_ROOT/{}".format(gen_pkg)
    pkg_emitted = False
    for rel in files:
        norm = rel.replace("\\", "/")
        if norm == gen_pkg:
            continue
        line = irun_source_line(rel)
        if not pkg_emitted and "xrun_compat/floo_id_translation.sv" in line:
            lines.append(pkg_line)
            pkg_emitted = True
        lines.append(line)

    gen_top = "generated/floo_axi_mesh_noc.sv"
    if gen_pkg not in seen and not pkg_emitted:
        lines.append(pkg_line)
    if gen_top not in seen:
        lines.append("$FLOO_NOC_ROOT/{}".format(gen_top))

    lines.append("$PULP_ENV/src/ips/floo_noc/hamsa_floo_axi_bridge.sv")
    lines.append("$PULP_ENV/src/ips/floo_noc/floo_hamsa_noc_wrap.sv")

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    # type: () -> int
    root = Path(__file__).resolve().parents[1]
    floo_root = Path(sys.argv[1]) if len(sys.argv) > 1 else root.parent / "FlooNoC"
    out = root / "src" / "tb" / "floo_noc_irun.f"

    if not floo_root.is_dir():
        print("ERROR: FlooNoC root not found: {}".format(floo_root), file=sys.stderr)
        return 1

    source = "bender flist (-t rtl -t axi_mesh)"
    files = collect_from_bender(floo_root)
    if files is None:
        source = "compile_vsim.tcl (filtered)"
        try:
            files = collect_from_vsim_tcl(floo_root)
        except FileNotFoundError as exc:
            print("ERROR: {}".format(exc), file=sys.stderr)
            return 1

    write_irun_f(floo_root, out, files)
    print("Wrote {} ({} RTL files from {} + HAMSA glue)".format(out, len(files), source))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
