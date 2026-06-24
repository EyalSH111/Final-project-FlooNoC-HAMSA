# Stage-1 FlooNoC PoC Runbook

This runbook preserves the known-good single-tile HAMSA + FlooNoC PoC flow.
Use it whenever you need to return to the Stage-1 proof, rerun the simulation,
collect evidence, or open SimVision waves.

## What This PoC Proves

The Stage-1 PoC proves that HAMSA can host the FlooNoC RTL and that the
external/inter-tile AXI path (`masters[4]` / `slaves[4]`, the xtrn port) can
be converted into FlooNoC flits through the HAMSA-Floo glue and Chimney.

It also proves that the local HAMSA SoC still boots and runs software: the
RISC-V core accesses the local UART through the original intra-tile AXI
crossbar and prints `Hey we use floonoc!`.

This PoC does not prove a full remote tile-to-tile transaction. There is only
one HAMSA tile, and the transaction is completed through local Stage-1
bring-up response/loopback logic.

## Repository And Branch

Working repository on the RC server:

```bash
/data/project/tsmc65/users/eyalsho/ws/ddp23_pnx_PoC
```

Working local/PC repository:

```bash
c:\Users\eyals\hamsa\ddp23_pnx_PoC
```

Known-good branch:

```bash
ddp23_pnx_PoC
```

## Environment Setup On RC

Start from the RC server shell:

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS/ddp23_pnx_PoC
source cloud_setup.sh
```

Check that Cadence is available:

```bash
which xrun || which irun
```

If this prints nothing, the Cadence/Xcelium environment is not loaded. The
simulation will fail with `irun: command not found`, and no `helloworld/xrun.log`
will be created.

## Normal Simulation

From the repository root:

```bash
ddp23_make APP=helloworld run REBUILD=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"
```

Expected pass checks:

```bash
grep -E 'FLOO_STIM|FLOO_MON|Hey|FINISH' helloworld/xrun.log
```

Known-good output:

```text
[FLOO_STIM] driving AXI write on masters[4] (rstn_sys=1)
[FLOO_STIM] aw_ready @ time 50550000
[FLOO_MON] time=50550000 chimney_floo_req_o.valid flit_count=1
[FLOO_STIM] w_ready @ time 50650000
[FLOO_MON] time=50650000 chimney_floo_req_o.valid flit_count=2
[FLOO_STIM] write response @ time 50750000
Hey we use floonoc!
--- FINISH ---
```

Meaning:

- `aw_ready`: AXI write-address transfer on `masters[4]` was accepted.
- `flit_count=1`: the Chimney emitted the first Floo request flit.
- `w_ready`: AXI write-data transfer on `masters[4]` was accepted.
- `flit_count=2`: the Chimney emitted the second Floo request flit.
- `write response`: the PoC write transaction completed without deadlock.
- `Hey we use floonoc!`: HAMSA software ran and printed through the real local UART.
- `--- FINISH ---`: the test completed normally.

## Save Evidence Artifacts

After a successful run:

```bash
mkdir -p ~/floo_poc_artifacts
cp helloworld/xrun.log ~/floo_poc_artifacts/xrun_$(git rev-parse --short HEAD).log
grep -E 'FLOO_BUILD|FLOO_STIM|FLOO_MON|Hey|FINISH' helloworld/xrun.log > ~/floo_poc_artifacts/floo_summary.txt
git log -1 --oneline > ~/floo_poc_artifacts/git_rev.txt
```

## SimVision Wave Flow

Generate waves:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true MMAP=false XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"
cd helloworld
simvision waves.shm &
```

Alternative live GUI flow:

```bash
ddp23_make APP=helloworld run REBUILD=true GUI=true PROBE=true MMAP=false XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"
```

If the GUI opens at the `xcelium>` prompt, type:

```tcl
run
```

If you see:

```text
couldn't change working directory to "helloworld": no such file or directory
```

exit the interactive simulator, return to the repository root, and rerun the
make command from there.

## Important SimVision Hierarchy

Main hierarchy:

```text
fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem
```

Useful signals from `fpgnix_tb`:

```text
floo_tb_clk
floo_rstn
floo_stim_state
floo_flit_count
```

Useful signals from `msystem`:

```text
clk_sys
rstn_sys
masters[4].aw_valid
masters[4].aw_ready
masters[4].aw_addr
masters[4].w_valid
masters[4].w_ready
masters[4].w_data
masters[4].w_last
masters[4].b_valid
masters[4].b_ready
masters[4].b_resp
slaves[4].aw_valid
slaves[4].aw_ready
slaves[4].w_valid
slaves[4].w_ready
slaves[4].b_valid
slaves[4].b_ready
chimney_mgr_req
chimney_mgr_rsp
chimney_floo_req_o
chimney_floo_req_i
router_req_in
router_req_out
floo_north_req_o
floo_north_req_i
```

Best report screenshot window:

```text
50.55 us to 50.75 us
```

In picoseconds:

```text
50550000 ps to 50750000 ps
```

The best screenshot should show:

- `masters[4].aw_valid` / `masters[4].aw_ready` handshake.
- `chimney_floo_req_o` activity for the first flit.
- `masters[4].w_valid` / `masters[4].w_ready` handshake.
- `chimney_floo_req_o` activity for the second flit.
- `masters[4].b_valid` / `masters[4].b_ready` response.

## Report Wording

Use this precise statement:

```text
The Stage-1 PoC demonstrates that HAMSA xtrn AXI traffic can be accepted on
masters[4], converted by the HAMSA-Floo glue and Chimney into FlooNoC request
flits, and completed without deadlock. In parallel, the real HAMSA core boots
and prints through the local UART, proving that the FlooNoC integration does
not break the base SoC. This is a single-tile integration proof and not yet a
full remote tile-to-tile transaction.
```

## Common Problems

### `irun: command not found`

Cadence/Xcelium is not loaded. Run:

```bash
tsmc65
source cloud_setup.sh
which xrun || which irun
```

### `helloworld/xrun.log: No such file or directory`

The simulation did not run or failed before creating the log. Fix the simulator
environment first, then rerun.

### SimVision Opens But No Signals Are Visible

Expand:

```text
fpgnix_tb -> fpgnix -> vqm_msystem_wrap -> msystem
```

Then send the relevant signals to the waveform window.

### `masters` / `slaves` Are Hard To Find

They are SystemVerilog interface arrays. In SimVision, expand:

```text
msystem -> masters -> 4
msystem -> slaves -> 4
```

If the object list does not show them, use the Find/Filter box and search for
`masters`, `aw_valid`, or `chimney_floo_req_o`.
