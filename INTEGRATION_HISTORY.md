# FlooNoC ↔ HAMSA Integration History

This file records the background, decisions, file-level changes, and **XRUN bring-up fixes**
for replacing the legacy PULP `axi_node` crossbar in `msystem.sv` with a 2×2 **FlooNoC AXI mesh**,
while keeping the **HAMSA / XRUN (`irun`) simulation flow** unchanged.

**Git branch (HAMSA):** `floo-noc-integration` on `github.com:EyalSH111/hamsa`  
**Git branch (FlooNoC SAM/mesh):** `hamsa-2x2-integration` on `EyalSH111/Final-project-FlooNoC-HAMSA` (or sibling clone)

---

## 1. Starting point (before changes)

| Item | Location | Notes |
|------|----------|-------|
| HAMSA SoC top interconnect | `src/ips/pulpenix/src/soc/msystem.sv` | Single `axi_node_intf_wrap` crossbar |
| 6 AXI initiators | `masters[5:0]` | core, debug, SPI, UART, xtrn slave, DMA |
| 5 AXI targets | `slaves[4:0]` | instr/data RAM, peripherals, MMSPI, xtrn master |
| Simulation flow | `src/tb/sim.make` | `make -f sim.make APP=helloworld` → Cadence **XRUN 23.09** |
| Demo app | `src/ips/pulpenix_sw/apps/helloworld/helloworld.c` | Printed `HELLO DDP24` on UART |
| FlooNoC bring-up | `../FlooNoC/` (sibling of `hamsa/`) | 2×2 mesh demo, Questa/Bender flow |

### Planned 2×2 tile map

| Tile | Role | HAMSA connections |
|------|------|-------------------|
| (0,0) | Compute | `masters[0]` core, `masters[1]` debug |
| (0,1) | Memory | `slaves[0]` instr, `slaves[1]` data |
| (1,0) | Periph + DMA | `masters[5]` DMA, `masters[3]` UART, `slaves[2]` peripherals |
| (1,1) | External I/O | `masters[2]` SPI, `masters[4]` xtrn, `slaves[3]` MMSPI, `slaves[4]` xtrn |

Xbox TCM (`xbox_dmem_*`) stays on `core_region_i` (not on the NoC).

---

## 2. What we changed (summary)

| Change | Why |
|--------|-----|
| Added `floo_hamsa_noc_wrap.sv` | Drop-in replacement for `axi_node_intf_wrap` using real `floo_axi_mesh_noc` |
| Added `hamsa_floo_axi_bridge.sv` | HAMSA uses `AXI_BUS` interfaces; FlooNoC uses struct types (`axi_in_req_t`, …) |
| Kept local `axi_node_intf_wrap` **inside each tile** | Per-tile master mux / slave demux (same address rules as before) |
| Updated `msystem.sv` | Instantiate `floo_hamsa_noc_wrap` instead of bare crossbar |
| Patched `FlooNoC/generated/floo_axi_mesh_noc_pkg.sv` SAM | Route HAMSA address map to correct mesh tiles (5 rules) |
| Added `scripts/gen_floo_noc_irun_f.py` + `src/tb/floo_noc_irun.f` | Pull FlooNoC + Bender deps into **XRUN** compile (not Questa) |
| Added `src/ips/floo_noc/xrun_compat/` | Patched Floo RTL for Cadence XRUN 23.09 limitations |
| Updated `src/tb/sim.make` | `FLOO_NOC=true` (default), `floo_noc_irun.f` before `fpgnix_tb.f`, `xrun-errors` target |
| Updated `helloworld.c` | Success string: **`Hey we use floonoc!`** on UART |
| Updated `cloud_setup.sh` / `nx_setup.sh` | Export `FLOO_NOC_ROOT` |

---

## 3. File-by-file changelog

### HAMSA (`ddp23_pnx`)

| File | Action | Reason |
|------|--------|--------|
| `src/ips/floo_noc/floo_hamsa_noc_wrap.sv` | **NEW / EDIT** | Top interconnect: 2×2 mesh + per-tile mux/demux; XRUN-safe interface wiring |
| `src/ips/floo_noc/hamsa_floo_axi_bridge.sv` | **NEW** | `AXI_BUS` ↔ Floo AXI struct conversion + ID padding |
| `src/ips/floo_noc/xrun_compat/*.sv` | **NEW** | XRUN-compatible copies of upstream Floo modules (see §5) |
| `src/ips/pulpenix/src/soc/msystem.sv` | **EDIT** | Swap `axi_node_intf_wrap` → `floo_hamsa_noc_wrap` |
| `src/ips/pulpenix/pulpenix.f` | **EDIT** | Compile HAMSA glue RTL; **do not** duplicate mesh (comes from `floo_noc_irun.f`) |
| `src/tb/sim.make` | **EDIT** | FlooNoC flags, filelist order, `xrun-errors`, optional regen via `FLOO_NOC_REGEN=1` |
| `src/tb/floo_noc_irun.f` | **NEW (generated)** | FlooNoC dependency file list for `irun`; **package must compile before xrun_compat** |
| `scripts/gen_floo_noc_irun_f.py` | **NEW / EDIT** | Regenerate `floo_noc_irun.f`; maps files to `xrun_compat/`; fixes pkg compile order |
| `src/ips/pulpenix_sw/apps/helloworld/helloworld.c` | **EDIT** | FlooNoC success banner on UART |
| `cloud_setup.sh`, `nx_setup.sh` | **EDIT** | Set `FLOO_NOC_ROOT` |
| `INTEGRATION_HISTORY.md` | **EDIT** | This document |

### FlooNoC (`$FLOO_NOC_ROOT`, sibling repo)

| File | Action | Reason |
|------|--------|--------|
| `generated/floo_axi_mesh_noc_pkg.sv` | **EDIT** (force-add) | HAMSA SAM: 5 regions, 32-bit addr, tile IDs for instr/data/periph/MMSPI/xtrn |
| `generated/floo_axi_mesh_noc.sv` | **EDIT** (force-add) | 2×2 mesh RTL from FlooGen / HAMSA profile |
| `floogen/examples/hamsa_axi_mesh_2x2.yml` | optional | FlooGen source for regeneration |

---

## 4. XRUN bring-up: errors and fixes

Cadence **XRUN 23.09** on university RC3 exposed several issues not seen in Questa.

| Error | Cause | Fix |
|-------|-------|-----|
| `NOPBIND floo_axi_mesh_noc_pkg` | Mesh/wrap compiled before package, or duplicate/missing filelist | Compile `floo_noc_irun.f` **before** `fpgnix_tb.f`; ensure **one** `floo_axi_mesh_noc_pkg.sv` line **before** `xrun_compat/floo_id_translation.sv` |
| `*E,SVVMAP` on `floo_id_translation.sv`, `floo_meta_buffer.sv` | XRUN does not support array parameters in `#()` (e.g. `Sam` rules) | `xrun_compat/`: remove `Sam` from port lists; use `floo_axi_mesh_noc_pkg::Sam` inside modules |
| `*E,SVVMAP` on `id_queue.sv` | `localparam type` in parameter port list | `xrun_compat/id_queue.sv`: use `parameter type` |
| Questa-only sources in filelist | `axi_test.sv`, `clk_mux_glitch_free.sv`, iDMA testbench, etc. | `gen_floo_noc_irun_f.py` excludes sim/test files; uses `bender flist -t rtl -t axi_mesh` when available |
| Duplicate `common_cells` modules | HAMSA `pulpenix.f` already compiles `cdc_2phase`, `fifo_v2/v3`, `rr_arb_tree` | Generator skips those basenames from FlooNoC list |
| `INNOTR` in wrap | Interface name / connection mismatch on tile (0,1) | Renamed signals; `.slave(tile01_floo_s)` without `{}` for single slave |
| `*E,CUIUCN` / `*E,CUIMBC` / `*E,CUINPD` in `floo_hamsa_noc_wrap.sv` | XRUN rejects `{slave[i], slave[j]}` interface concatenation; scalar vs array port mismatch when `NB_MASTER=1` or `NB_SLAVE=1` | Mux tiles: `tileXX_mux_m[0:0]`, `tileXX_slv[1:0]`, `` `AXI_ASSIGN_SLAVE ``. Demux tiles: `tile01_floo_s[0:0]`, `tile11_floo_s[0:0]`, bridge on `[0]` |
| `sim.make:237` `Error 1` | Generic make failure after XRUN exit | **Not the root cause** — always run `make … xrun-errors` and fix first `*E` in log |

### `xrun_compat/` modules (compile instead of upstream)

| File | Change |
|------|--------|
| `id_queue.sv` | `parameter type` instead of `localparam type` in `#()` |
| `floo_id_translation.sv` | No `Sam` parameter; `addr_map_i(floo_axi_mesh_noc_pkg::Sam)`, `.NoRules(SamNumRules)` |
| `floo_meta_buffer.sv` | No `Sam` parameter; child `floo_id_translation` without `.Sam()` |
| `floo_axi_chimney.sv` | No `Sam` parameter; no `.Sam()` on `floo_id_translation` |
| `floo_axi_mesh_noc.sv` | No `.Sam()` on chimney instances |

`gen_floo_noc_irun_f.py` redirects these paths to `$PULP_ENV/src/ips/floo_noc/xrun_compat/`.

### `floo_noc_irun.f` compile order (critical)

XRUN requires:

1. `floo_pkg.sv` and dependencies (via filelist)
2. **`$FLOO_NOC_ROOT/generated/floo_axi_mesh_noc_pkg.sv`** — **before** any module that `import floo_axi_mesh_noc_pkg::*`
3. `xrun_compat/floo_id_translation.sv`, `floo_meta_buffer.sv`, `floo_axi_chimney.sv`
4. `xrun_compat/floo_axi_mesh_noc.sv`
5. HAMSA glue: `hamsa_floo_axi_bridge.sv`, `floo_hamsa_noc_wrap.sv`

Verify on RC3:

```bash
grep -n "floo_axi_mesh_noc_pkg.sv\|floo_id_translation.sv" $PULP_ENV/src/tb/floo_noc_irun.f
```

Line number of `floo_axi_mesh_noc_pkg.sv` must be **less than** `floo_id_translation.sv`.  
Only **one** package line in the file.

---

## 5. Git and repository layout

| Repo | Remote / branch | Contents |
|------|-----------------|----------|
| HAMSA | `github` → `EyalSH111/hamsa`, branch `floo-noc-integration` | Wrapper, bridges, `sim.make`, `xrun_compat`, generator, helloworld |
| FlooNoC | `origin` → `EyalSH111/Final-project-FlooNoC-HAMSA`, branch `hamsa-2x2-integration` | `generated/*.sv` (force-added; `generated/` is gitignored upstream) |

**Note:** University GitLab `origin` on HAMSA may be read-only; pull fixes from **`github`**, not only `origin`.

### Notable commits on `floo-noc-integration` (HAMSA)

| Commit | Description |
|--------|-------------|
| (initial) | Floo wrap, msystem, sim.make, helloworld banner |
| `fe6ce55` | Exclude `axi_test.sv`, `clk_mux_glitch_free.sv` from file list |
| `5a662c3` | Python 3.6 compatibility for generator (RC3) |
| `5747c20` | `xrun_compat/id_queue.sv`, `xrun-errors` target, skip duplicate common_cells |
| `5ba0710` | SAM via package in xrun_compat; chimney + mesh xrun_compat; generator redirects |
| `335643d` | XRUN interface array fixes in `floo_hamsa_noc_wrap.sv`; generator pkg ordering |

---

## 6. How to run

### University RC3 (primary)

```bash
export DDP23_USER_WS=/data/project/tsmc65/users/eyalsho/ws
export PULP_ENV=$DDP23_USER_WS/ddp23_pnx
export FLOO_NOC_ROOT=$DDP23_USER_WS/FlooNoC
cd $PULP_ENV

# Get latest HAMSA integration branch
git fetch github floo-noc-integration
git merge github/floo-noc-integration

# FlooNoC deps + generated SAM (if not already)
cd $FLOO_NOC_ROOT && bender update
git checkout hamsa-2x2-integration   # in FlooNoC clone

# Regenerate filelist only when needed (or FLOO_NOC_REGEN=1 on compile)
python3 $PULP_ENV/scripts/gen_floo_noc_irun_f.py $FLOO_NOC_ROOT

# Confirm package order after regen
grep -n "floo_axi_mesh_noc_pkg.sv\|floo_id_translation.sv" src/tb/floo_noc_irun.f

# Build + sim
rm -rf helloworld helloworld.1 helloworld.2 helloworld.3
make -f $PULP_ENV/src/tb/sim.make APP=helloworld FLOO_NOC=true BAUD_RATE=2500000
make -f $PULP_ENV/src/tb/sim.make APP=helloworld xrun-errors
```

**Expected UART output:** `Hey we use floonoc!` then `--- FINISH ---`.

### Local WSL

```bash
export PULP_ENV=/mnt/c/Users/eyals/hamsa/ddp23_pnx
export FLOO_NOC_ROOT=/mnt/c/Users/eyals/FlooNoC
source $PULP_ENV/nx_setup.sh
# same make commands as above
```

### Disable FlooNoC (legacy crossbar)

```bash
make -f $PULP_ENV/src/tb/sim.make APP=helloworld FLOO_NOC=false
```

### Debug helper

```bash
make -f $PULP_ENV/src/tb/sim.make APP=helloworld xrun-errors
```

---

## 7. Architecture (after integration)

```
core/dbg ──► tile(0,0) ──► Floo 2×2 mesh ──► tile(0,1) ──► instr/data RAM
                              │
                              ├──► tile(1,0) ──► peripherals (+ DMA/UART masters)
                              └──► tile(1,1) ──► MMSPI / xtrn
```

Local `axi_node_intf_wrap` blocks only mux/demux **within** a tile; inter-tile traffic uses FlooNoC.

Inside `floo_hamsa_noc_wrap`, each tile mux connects via explicit interface arrays (`tileXX_slv[1:0]`, `tileXX_mux_m[0:0]`) — required for XRUN elaboration.

---

## 8. Parameters aligned with HAMSA

| Parameter | Value | Where |
|-----------|-------|-------|
| AddrWidth | 32 | `floo_axi_mesh_noc_pkg::AxiCfg`, HAMSA `AXI_ADDR_WIDTH` |
| DataWidth | 32 | same |
| ID width | 10 (Floo) / 2 (initiators) / 5 (targets) | wrap: `AXI_INITIATOR_ID_WIDTH`, `AXI_TARGET_ID_WIDTH`; bridges pad to Floo |
| Ordering | `NoRoB` | Floo chimney default / HAMSA in-order |
| SAM rules | 5 | `floo_axi_mesh_noc_pkg::Sam`, `SamNumRules` |

---

## 9. Known follow-ups

- [ ] Confirm `helloworld` UART prints **`Hey we use floonoc!`** after elaboration passes on RC3
- [ ] Full SoC regression (DMA, MMSPI, xtrn) — start with helloworld only
- [ ] Regenerate mesh from FlooGen YAML when topology changes; re-apply or embed HAMSA SAM
- [ ] FPGA flows (`pulpenix_fpga.qsf`, `filelist.tcl`) not updated for FlooNoC
- [ ] Optional: FlooNoC as git submodule under HAMSA instead of sibling checkout
- [ ] If `make compile` runs `gen_floo_noc_irun_f` and breaks pkg order, use updated generator (`335643d+`) or set `FLOO_NOC_REGEN=0` (default unless `FLOO_NOC_REGEN=1`)

---

## 10. Session log

| Date | Event |
|------|-------|
| 2026-05-27 | Cloned `ddp23_pnx` into `hamsa/`; reviewed FlooNoC 2×2 demo in sibling `FlooNoC/` |
| 2026-05-27 | Implemented `floo_hamsa_noc_wrap` + XRUN file list; SAM mapped to HAMSA memory map |
| 2026-05-27 | `helloworld` updated to print **`Hey we use floonoc!`** |
| 2026-05-27 | Branch `floo-noc-integration` pushed to GitHub; FlooNoC `hamsa-2x2-integration` with force-added `generated/` |
| 2026-05-27 | XRUN compile fixes: RTL-only filelist, Python 3.6, `xrun_compat`, duplicate module exclusions |
| 2026-05-27 | XRUN: `NOPBIND` fixed by `floo_axi_mesh_noc_pkg.sv` compile order in `floo_noc_irun.f` |
| 2026-05-27 | XRUN: `SVVMAP` fixed by removing `Sam` array parameters in `xrun_compat` |
| 2026-05-27 | XRUN: elaboration `CUIUCN`/`CUIMBC` fixed by interface array wiring in `floo_hamsa_noc_wrap.sv` (`335643d`) |
| 2026-05-27 | XRUN: demux tiles — `tile01_floo_s[0:0]`, `tile11_floo_s[0:0]` for `NB_SLAVE=1` demux instances |
| 2026-05-27 | XRUN: `CUVUNF` on `tile10_periph_bridge` — separate `AXI_INITIATOR_ID_WIDTH` (2) vs `AXI_TARGET_ID_WIDTH` (5) on wrap ports |
