# HAMSA + FlooNoC Full Integration Report

## Executive Summary

This work integrates FlooNoC into the HAMSA/PULPenix SoC by routing HAMSA's external AXI path (`xtrn`, exposed through `masters[4]` / `slaves[4]`) through a Floo AXI Chimney and Router. The final demo proves a full end-to-end transaction: HAMSA-side AXI traffic is converted into Floo flits, routed to a remote NoC-side endpoint, converted back to AXI, written into a selectable remote AXI slave region, read back, and checked for correctness.

The latest branch is stronger than the equal-bank demo. The remote endpoint now exposes three different memory-mapped AXI slave regions: a small fast register file, a medium RAM, and a large RAM. The testbench can select which slave region and which words to access using plusargs.

Final proof line from the passing run:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

## Current Architecture

### High-Level View

```text
                  HAMSA / PULPenix SoC
             +-----------------------------+
             | CPU, boot ROM, UART, APB    |
             | existing intra-tile AXI     |
             |                             |
             | xtrn AXI port masters[4]    |
             +-------------+---------------+
                           |
                           v
                  hamsa_floo_xtrn_glue
                           |
                           v
                  hamsa_floo_chimney_wrap
                    AXI <-> Floo flits
                           |
                           v
                    floo_axi_router
                      north NoC link
                           |
                           v
              Remote Floo AXI Slave Endpoint
             +-----------------------------+
             | remote Chimney              |
             | Floo flits <-> AXI          |
             |                             |
             | small reg: 16 x 32-bit      |
             | medium RAM: 256 x 32-bit    |
             | large RAM: 1024 x 32-bit    |
             +-----------------------------+
```

### Detailed Transaction Flow

```text
1. Testbench drives HAMSA xtrn AXI write/read on masters[4].

2. hamsa_floo_xtrn_glue adapts HAMSA AXI_BUS signals to the struct-based AXI
   types used by FlooNoC.

3. HAMSA-side hamsa_floo_chimney_wrap packetizes AXI AW/W/AR channels into
   Floo request flits, and later depacketizes Floo response flits into AXI B/R.

4. floo_axi_router sends those flits over the north link toward the remote tile
   endpoint. The demo uses address bit 20 (0x0010_0000 range) to route to the
   remote location.

5. Remote hamsa_floo_remote_mem_endpoint accepts request flits, uses a second
   Chimney to reconstruct AXI, decodes the address, and performs the access on
   a local memory-mapped AXI slave region.

6. The remote endpoint sends B or R responses back through FlooNoC.

7. HAMSA-side Chimney converts response flits back into AXI responses. The TB
   checks the readback data and prints PASS/FAIL.
```

## Remote AXI Slave Memory Map

The current endpoint contains three different AXI slave regions:

```text
target 0: small fast register file, 16 x 32-bit  -> 0x0010_0000 .. 0x0010_00ff
target 1: medium RAM,              256 x 32-bit -> 0x0010_1000 .. 0x0010_13ff
target 2: large RAM,              1024 x 32-bit -> 0x0010_2000 .. 0x0010_2fff
```

Address decoding inside the remote endpoint:

```text
address[20]    -> routes traffic to remote NoC endpoint
address[13:12] -> selects target 0..2
address[5:2]   -> word inside small register file
address[9:2]   -> word inside medium RAM
address[11:2]  -> word inside large RAM
address[1:0]   -> byte offset inside the 32-bit word
```

Example:

```text
0x0010_0000 = small_reg, word 0
0x0010_1040 = medium_ram, word 16
0x0010_2400 = large_ram, word 256
```

## How To Run

From the RC / TSMC65 environment:

```bash
tsmc65
cd /data/project/tsmc65/users/eyalsho/ws/ddp23_pnx_PoC
source cloud_setup.sh
git checkout hamsa-separate-remote-endpoints
git fetch origin
git reset --hard origin/hamsa-separate-remote-endpoints
```

Small register-file target, words 0..3:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=0 +FLOO_REMOTE_IDX=0 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=A0000000"
```

Medium RAM target, words 16..19:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=1 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=B0001000"
```

Large RAM target, words 256..259:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=2 +FLOO_REMOTE_IDX=256 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=C0002000"
```

Extract the proof from the log:

```bash
grep -E '\*E|FLOO_BUILD|FLOO_2X2|FLOO_STIM|FLOO_MON|TIMEOUT|Hey|FINISH|PASS|FAIL|latency_cycles|target=|slave=' helloworld/xrun.log
```

## Testbench Options

```text
FLOO_REMOTE_TARGET = slave region to access: 0=small_reg, 1=medium_ram, 2=large_ram
FLOO_REMOTE_IDX    = first word inside that target
FLOO_REMOTE_WORDS = number of consecutive words to test, 1..4
FLOO_REMOTE_DATA  = first write data value
```

The testbench writes consecutive data values. For example:

```bash
+FLOO_REMOTE_TARGET=2 +FLOO_REMOTE_IDX=256 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=C0002000
```

produces:

```text
large_ram word 256 -> 0xc0002000
large_ram word 257 -> 0xc0002001
large_ram word 258 -> 0xc0002002
large_ram word 259 -> 0xc0002003
```

## Expected Proof From RC Runs

Each target run should show the selected remote slave, the decoded address, four readbacks, and a final pass summary:

```text
[FLOO_STIM] remote target base=0x00100000 target=2 offset=0x00002000 first_word=256 words=4 first_data=0xc0002000
[FLOO_2X2] remote AXI slave AR addr=0x00102400 slave=large_ram ...
[FLOO_2X2] remote AXI slave R response accepted slave=large_ram ... data=0xc0002000
[FLOO_STIM] read response target=2 word=256 data=0xc0002000 latency_cycles=...
[FLOO_2X2] PASS: remote slave readback target=2 word=256 data=0xc0002000
...
[FLOO_2X2] SUMMARY: remote slave readbacks pass=4 fail=0 total=4
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

## Timing And Measurement

The testbench records a simple latency counter around each AXI transaction. It prints:

```text
[FLOO_STIM] write response target=... word=... latency_cycles=...
[FLOO_STIM] read response target=... word=... data=... latency_cycles=...
```

In the previous passing baseline:

```text
write response latency: 8 cycles
read response latency:  6 cycles
```

This is not a full performance benchmark of FlooNoC, because the testbench sends simple single-beat AXI transactions and the remote endpoint is intentionally minimal. It is still useful for report evidence because it shows that the path is not only functionally correct but also measurable.

## Stress Test Status

Yes, the latest run is a small stress test compared with the original single-access PoC.

Original proof:

```text
1 write + 1 readback to one remote storage location
```

Current proof:

```text
4 writes + 4 reads to consecutive words in a selected remote slave region
target selection + word selection + unique data per word
PASS/FAIL summary across all readbacks
latency printed for each transaction
```

This is still intentionally small so the project remains stable near completion. A larger stress test could increase `FLOO_REMOTE_WORDS`, but the current TB clamps it to 4 to keep the log short and the demo predictable.

## What This Proves

The demo proves:

- HAMSA still boots and executes software after FlooNoC integration.
- The HAMSA `xtrn` AXI path is connected to FlooNoC through glue and Chimney logic.
- AXI requests are converted into Floo flits and cross the router/north link.
- A remote endpoint receives the flits and reconstructs AXI transactions.
- Different remote AXI slave regions store different data values at different addresses.
- AXI read responses return through the reverse NoC path and match expected data.
- The testbench can select different remote slaves and addresses without RTL edits.

## What This Does Not Yet Prove

The demo does not yet instantiate multiple physically separate NoC tiles, each with a separate router coordinate. Instead, it implements multiple separate AXI slave regions behind one remote NoC endpoint. This is a good final-project tradeoff: it demonstrates realistic memory-mapped remote slave selection through the integrated NoC path while avoiding the risk of a late topology expansion.

## Waveform Suggestions

For GUI proof in SimVision, open `helloworld/waves.shm` after a `PROBE=true` run and inspect:

```text
fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.masters[4]
fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.chimney_floo_req_o
fpgnix_tb.fpgnix.floo_req_o
fpgnix_tb.fpgnix.floo_rsp_i
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_slv_req
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_slv_rsp
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_aw_target_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_ar_target_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_aw_small_idx_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_aw_medium_idx_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_aw_large_idx_q
```

Recommended screenshots:

- AXI AW/W/B handshake for one write to the selected remote slave.
- Floo request flit activity on the north link.
- Remote endpoint AW/W decode showing `small_reg`, `medium_ram`, or `large_ram`.
- AXI AR/R handshake for the readback.
- Final log window showing `PASS: 4/4 remote slave readbacks matched`.

## Short Explanation For Presentation

We integrated FlooNoC into HAMSA by replacing the external/inter-tile AXI path with a Chimney + Router path. The demo drives AXI traffic from HAMSA's `xtrn` port, converts it into Floo flits, sends it to a remote endpoint, converts it back into AXI, and accesses a selectable remote AXI slave region. The latest version has a small fast register file, a medium RAM, and a large RAM. The testbench selects a target, writes unique data values to consecutive words, reads them back, and reports 4/4 matches while HAMSA continues to boot and print `Hey we use floonoc!`.
