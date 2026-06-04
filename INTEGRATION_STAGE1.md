# Stage-1 FlooNoC inside HAMSA (single-tile PoC)

Repository: `ddp23_pnx_PoC` (bootstrap from `ddp23_pnx` / GitLab `udik/ddp23_pnx`).

## Architecture

- **Intra-tile:** unchanged `axi_node_intf_wrap` (5 targets, 6 initiators).
- **Inter-tile / chip boundary:** only `masters[4]` and `slaves[4]` (former xtrn) through `u_hamsa_chimney` + 5-port `floo_axi_router`.
- **North (port 0):** top-level `floo_req_o` / `floo_rsp_o` and `floo_req_i` / `floo_rsp_i`.
- **E/W/S:** tied off; **Eject (4):** chimney.

## Build

```bash
export PULP_ENV=/path/to/ddp23_pnx_PoC
make -f $PULP_ENV/src/tb/sim.make APP=helloworld
```

FlooNoC RTL is vendored under `src/ips/floo_noc/` (`floo_noc.f` + `floo_noc_deps.f`). No `$FLOO_NOC_ROOT` required.

### If you see `*E,DUPUNI` (duplicate `common_cells`)

1. `git pull` on branch `ddp23_pnx_PoC`, **or** run `bash scripts/fix_floo_xrun_dupuni.sh` (works even if pull is behind).
2. Confirm: `grep -c 'floo_noc/deps/common_cells/src' src/ips/floo_noc/floo_noc_deps.f` → **0**
3. Confirm: `grep -c 'src/ips/common_cells' src/ips/floo_noc/floo_noc_deps.f` → **>0**
4. Confirm: `test ! -d src/ips/floo_noc/deps/common_cells/src` (optional; rename hides vendor RTL)
5. `rm -rf helloworld/xcelium.d helloworld/INCA_libs` then rebuild.

See `src/ips/floo_noc/deps/README_XRUN.md`.

## Simulation checks

### Normal run (chimney enabled)

Expect UART helloworld plus log lines:

```
[FLOO_MON] chimney floo_req_o.valid ...
[FLOO_MON] SUMMARY: cumulative flits=<N>
[FLOO_MON] PASS: non-zero flit activity through FlooNoC chimney

Log checks: `grep FLOO_MON helloworld/xrun.log` and `grep 'FLOO_MON.*PASS'` (not `grep '[FLOO_MON] PASS'` — the line includes `: non-zero...`).
```

North loopback in `fpgnix_tb.v` registers `floo_req_o` → `floo_req_i` (and rsp) to stimulate mesh port activity.

### Break test (chimney disabled)

```bash
make -f $PULP_ENV/src/tb/sim.make APP=helloworld XRUN_FLAGS="+define+FLOO_CHIMNEY_DISABLED"
```

Or comment out `u_hamsa_chimney` / router / glue in `msystem.sv`, then re-run simulation.
3. Expect `[FLOO_MON] FAIL: zero flits` and no PASS on flit counter.
4. Restore chimney → PASS returns with `flit_count > 0`.

## Key files

| File | Role |
|------|------|
| `src/ips/pulpenix/src/soc/floo_hamsa_pkg.sv` | AXI/Floo types, XY tile (0,0) |
| `src/ips/floo_noc/hamsa_floo_xtrn_glue.sv` | `AXI_BUS` ↔ chimney structs |
| `src/ips/pulpenix/src/soc/msystem.sv` | Chimney + router integration |
| `src/ips/floo_noc/floo_noc.f` | 19 Floo RTL files + deps |
| `src/tb/fpgnix_tb.v` | Loopback + flit monitor |
