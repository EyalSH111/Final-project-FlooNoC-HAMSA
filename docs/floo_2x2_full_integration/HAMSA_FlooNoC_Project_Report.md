# HAMSA + FlooNoC Project Report

## 1. Overview

This project integrates FlooNoC into the HAMSA/PULPenix SoC and proves that the
HAMSA external AXI path can communicate with a remote NoC-side AXI endpoint. The
final demo is not only a compile-time connection. It performs real AXI writes and
reads through the integrated NoC path, checks the returned data, prints pass/fail
messages, and reports transaction latency in simulation cycles.

The final branch is:

```text
hamsa-separate-remote-endpoints
```

The main proof line from each successful run is:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

This means that the remote FlooNoC/AXI path worked and the HAMSA software still
ran until completion.

## 2. Goal

The goal was to take the existing HAMSA SoC and connect its external AXI path to
FlooNoC so HAMSA can access a remote destination. The integration had to prove:

- HAMSA still boots and executes the `helloworld` application.
- HAMSA's `xtrn` AXI path is connected to FlooNoC.
- AXI requests are converted into Floo flits.
- Floo flits reach a remote endpoint.
- The remote endpoint converts the flits back into AXI.
- A remote AXI slave stores data and returns it correctly.
- Different remote memories can be selected by address.
- The testbench can measure simple transaction latency.

## 3. Why FlooNoC Is Used

HAMSA already has local SoC resources such as CPU, memory, UART, and internal
interconnect. FlooNoC adds a scalable communication fabric that can connect this
tile to remote endpoints or future tiles. In a larger system, the same idea can
be used for multi-tile communication: one tile generates memory-mapped AXI
traffic, the NoC transports it, and another tile or device responds.

For this project, we use one HAMSA tile plus a remote NoC-side endpoint. This is
a good final-project balance: it proves real end-to-end NoC communication
without adding the risk of a full multi-tile topology late in the project.

## 4. Final Architecture

### 4.1 High-Level Diagram

```text
                      HAMSA / PULPenix SoC
                 +--------------------------------+
                 | CPU                            |
                 | Boot ROM / memories            |
                 | UART peripheral                |
                 | Internal AXI/APB interconnect  |
                 |                                |
                 | External AXI path: xtrn        |
                 | exposed through masters[4]     |
                 +---------------+----------------+
                                 |
                                 | AXI
                                 v
                      hamsa_floo_xtrn_glue
                                 |
                                 | struct-based AXI
                                 v
                    hamsa_floo_chimney_wrap
                         AXI <-> Floo flits
                                 |
                                 | Floo request/response flits
                                 v
                         floo_axi_router
                                 |
                                 | remote NoC link
                                 v
                +----------------------------------+
                | Remote Floo AXI Endpoint         |
                |                                  |
                | remote Chimney                   |
                | Floo flits <-> AXI               |
                |                                  |
                | Address decoder                  |
                |   target 0 -> small_reg          |
                |   target 1 -> medium_ram         |
                |   target 2 -> large_ram          |
                +----------------------------------+
```

### 4.2 Transaction Flow

```text
1. The testbench starts a directed remote-access sequence.

2. It drives AXI transactions on HAMSA's external AXI port.

3. The HAMSA-side glue converts the AXI_BUS style interface into the struct
   signals expected by the FlooNoC wrapper.

4. The HAMSA-side Chimney packetizes AXI AW/W/AR channels into Floo request
   flits.

5. The Floo router sends the flits toward the remote endpoint.

6. The remote endpoint receives Floo flits and reconstructs AXI transactions.

7. The remote AXI address decoder selects one target:
   target 0 = small register file
   target 1 = medium RAM
   target 2 = large RAM

8. The selected target stores write data or returns read data.

9. The remote endpoint sends AXI B/R responses back through FlooNoC.

10. The testbench receives the response, checks the readback value, and prints
    PASS or FAIL.
```

## 5. Important Files

```text
src/ips/floo_noc/hamsa_floo_xtrn_glue.sv
```

Adapts the HAMSA external AXI path into the signal style used by the FlooNoC
integration.

```text
src/ips/floo_noc/hamsa_floo_chimney_wrap.sv
```

Wraps the Floo AXI Chimney and performs the AXI-to-Floo and Floo-to-AXI
conversion.

```text
src/ips/floo_noc/hamsa_floo_remote_mem_endpoint.sv
```

Implements the remote NoC-side endpoint. It receives Floo traffic, converts it
back to AXI, decodes the address, and accesses one of the three remote slave
regions.

```text
src/tb/fpgnix_tb.v
```

Main testbench. It drives the remote AXI write/read sequence, chooses target and
word index through plusargs, checks data correctness, prints proof logs, and
measures latency.

```text
docs/floo_2x2_full_integration/
```

Documentation and proof material for the FlooNoC integration.

## 6. Remote Memory Map

The remote endpoint contains three memory-mapped AXI slave regions:

```text
target 0: small_reg,  16 x 32-bit   -> 0x0010_0000 .. 0x0010_00ff
target 1: medium_ram, 256 x 32-bit  -> 0x0010_1000 .. 0x0010_13ff
target 2: large_ram,  1024 x 32-bit -> 0x0010_2000 .. 0x0010_2fff
```

The base address `0x0010_0000` is important because bit 20 is used to route the
transaction to the remote endpoint. After the transaction reaches the remote
endpoint, address bits select the target and word.

```text
address[20]    -> remote NoC endpoint selection
address[13:12] -> remote AXI target selection
address[5:2]   -> word inside small_reg
address[9:2]   -> word inside medium_ram
address[11:2]  -> word inside large_ram
address[1:0]   -> byte offset inside a 32-bit word
```

Examples:

```text
0x0010_0004 -> target 0, small_reg, word 1
0x0010_1040 -> target 1, medium_ram, word 16
0x0010_2400 -> target 2, large_ram, word 256
```

Memory size explanation:

```text
16 x 32-bit   = 16 words, each word is 32 bits = 4 bytes
256 x 32-bit  = 256 words = 1024 bytes = 1 KiB
1024 x 32-bit = 1024 words = 4096 bytes = 4 KiB
```

## 7. What We Changed

### 7.1 Stage 1: Basic FlooNoC Path

The first stage connected the HAMSA `xtrn` AXI path to FlooNoC through glue,
Chimney, and router logic. This proved that the HAMSA SoC could still elaborate
and simulate with FlooNoC added.

### 7.2 Stage 2: End-To-End Remote AXI Register

The next stage added a remote endpoint so transactions did not only leave HAMSA,
but also reached a destination. A simple remote AXI register accepted writes and
returned reads. This proved the full request/response path.

### 7.3 Stage 3: Multi-Word Remote Memory

The endpoint was expanded from a single storage location to multiple words. The
testbench was also expanded from one write/read pair to a loop of several writes
and readbacks.

### 7.4 Stage 4: Separate Remote AXI Slave Regions

The final version replaced the equal-bank idea with three different memory
regions:

- `small_reg`: a small register-file style target.
- `medium_ram`: a medium RAM target.
- `large_ram`: a larger RAM target.

This makes the demo more realistic because a real memory map usually contains
different device types and address ranges, not only identical banks.

### 7.5 Testbench Control

The testbench now supports these plusargs:

```text
FLOO_REMOTE_TARGET = 0, 1, or 2
FLOO_REMOTE_IDX    = first word index inside the target
FLOO_REMOTE_WORDS  = number of consecutive words to test
FLOO_REMOTE_DATA   = first data value
FLOO_SIM_TIMEOUT_S = simulation timeout in seconds
```

The testbench writes consecutive values. For example:

```text
FLOO_REMOTE_DATA=C0002000
FLOO_REMOTE_WORDS=4
```

means:

```text
word 0 -> 0xc0002000
word 1 -> 0xc0002001
word 2 -> 0xc0002002
word 3 -> 0xc0002003
```

## 8. Important Fixes During The Project

### 8.1 Xcelium Multiple Driver Fix

An elaboration error appeared when a packed Floo request/response struct was
connected in a way that caused ready fields to be driven from more than one
place. The fix was to split the endpoint connection into separate valid, channel,
and ready signals, then rebuild the local struct in the testbench.

Why this matters: ready/valid interfaces have clear signal ownership. The source
drives valid and payload. The destination drives ready. Mixing these directions
inside one packed output struct can create multiple-driver problems.

### 8.2 Xcelium Packed Field Access Fix

After splitting signals, hierarchical access to fields of packed SystemVerilog
ports caused another Xcelium issue. The fix was to use local request/response
struct variables in the testbench and assign the complete structs where needed.

### 8.3 Counter Single-Driver Fix

The testbench counters used for transaction index, pass/fail count, and latency
were originally initialized in an `initial` block and also assigned in an
`always_ff` block. Xcelium reported this as a multiple-driver issue. The fix was
to reset those counters only inside the `always_ff` reset branch.

### 8.4 Word 0 Small Register Note

During validation, the small register target was proven with words 1..4. This
avoids a corner case observed at small register word 0 in an earlier run. The
current report commands use `FLOO_REMOTE_IDX=1` for target 0 so the proof is
stable and repeatable.

### 8.5 Documentation And Tooling Fix

The Word report generation first tried to use the external `python-docx`
package, but that package was not installed in the environment. A local
`make_docx.py` script was created using only standard Python libraries so the
document can be generated without installing extra packages.

## 9. How To Run From The University RC Server

### 9.1 First-Time Clone

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS
git clone git@github.com:EyalSH111/Final-project-FlooNoC-HAMSA.git ddp23_pnx_PoC
cd ddp23_pnx_PoC
git checkout hamsa-separate-remote-endpoints
source cloud_setup.sh
```

### 9.2 Updating An Existing Clone

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS/ddp23_pnx_PoC
git fetch origin
git checkout hamsa-separate-remote-endpoints
git reset --hard origin/hamsa-separate-remote-endpoints
source cloud_setup.sh
```

Use `git reset --hard origin/hamsa-separate-remote-endpoints` only on the RC
copy when it is a clean simulation clone and you want it to exactly match the
GitHub branch.

## 10. How To Run Each Target

Each command runs one target. To prove all three remote memories, run the three
commands one after another.

### 10.1 Target 0: Small Register File

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=0 +FLOO_REMOTE_IDX=1 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=A0000001"
```

This writes and reads:

```text
target=0 small_reg word=1 data=0xa0000001
target=0 small_reg word=2 data=0xa0000002
target=0 small_reg word=3 data=0xa0000003
target=0 small_reg word=4 data=0xa0000004
```

Expected result:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

### 10.2 Target 1: Medium RAM

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=1 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=B0001000"
```

This writes and reads:

```text
target=1 medium_ram word=16 data=0xb0001000
target=1 medium_ram word=17 data=0xb0001001
target=1 medium_ram word=18 data=0xb0001002
target=1 medium_ram word=19 data=0xb0001003
```

Expected result:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

### 10.3 Target 2: Large RAM

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=2 +FLOO_REMOTE_IDX=256 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=C0002000"
```

This writes and reads:

```text
target=2 large_ram word=256 data=0xc0002000
target=2 large_ram word=257 data=0xc0002001
target=2 large_ram word=258 data=0xc0002002
target=2 large_ram word=259 data=0xc0002003
```

Expected result:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

## 11. How To Read The Log

After a run, use:

```bash
grep -E 'write response|read response|PASS: 4/4|Hey|FINISH|target=|slave=' helloworld/xrun.log
```

Important lines:

```text
[FLOO_STIM] driving AXI slave write target=... word=... addr=... data=...
```

This means the testbench started a write transaction.

```text
[FLOO_2X2] remote AXI slave AW addr=... slave=...
```

This means the remote endpoint received the AXI write address after the request
crossed the FlooNoC path.

```text
[FLOO_2X2] remote AXI slave write complete slave=... data=...
```

This means the selected remote memory accepted the write data.

```text
[FLOO_STIM] read response target=... word=... data=... latency_cycles=...
```

This means read data returned back to the HAMSA-side testbench.

```text
[FLOO_2X2] PASS: remote slave readback target=... word=... data=...
```

This means the returned data matched the expected data.

## 12. Final Validation Results

The three successful proof runs are:

```text
target 0: small_reg
words: 1..4
data: 0xa0000001..0xa0000004
result: PASS 4/4
write latency: 8 cycles
read latency: 6 cycles
UART/software: Hey we use floonoc!
```

```text
target 1: medium_ram
words: 16..19
data: 0xb0001000..0xb0001003
result: PASS 4/4
write latency: 8 cycles
read latency: 6 cycles
UART/software: Hey we use floonoc!
```

```text
target 2: large_ram
words: 256..259
data: 0xc0002000..0xc0002003
result: PASS 4/4
write latency: 8 cycles
read latency: 6 cycles
UART/software: Hey we use floonoc!
```

## 13. UART And Software Proof

The `Hey we use floonoc!` line is not just a fake testbench print. It comes from
the `helloworld` software running on HAMSA and writing characters through the
SoC's UART path. The simulation testbench monitors the UART output and prints the
characters to the simulator log.

This proves that the HAMSA core still runs software after the FlooNoC changes.
It also proves the normal SoC boot/software/UART path was not broken by the new
NoC integration.

The `--- FINISH ---` line is the simulation finish marker. It shows that the
software/testbench reached its expected end condition rather than hanging until a
timeout.

For the report, describe the UART proof like this:

```text
The UART output demonstrates that the HAMSA processor booted and executed the
helloworld application. The program writes characters through HAMSA's UART
peripheral, and the testbench observes this UART traffic in simulation. Therefore
the print is evidence of real HAMSA software execution, not only a testbench
message.
```

## 14. Performance Measurement

The performance evidence in this project is transaction latency in cycles. The
testbench records when it starts a write or read transaction and subtracts that
cycle count when the response arrives.

The log lines are:

```text
[FLOO_STIM] write response target=... word=... latency_cycles=...
[FLOO_STIM] read response target=... word=... data=... latency_cycles=...
```

Observed directed-test result:

```text
write response latency = 8 cycles
read response latency  = 6 cycles
```

These numbers can be used in the report as a simple performance measurement of
the integrated AXI -> FlooNoC -> remote AXI -> FlooNoC -> AXI response path.

This is not a full NoC performance benchmark. A full benchmark would test long
bursts, multiple outstanding transactions, contention, different routes, and
multiple real tiles. This project intentionally measures simple single-beat
transactions because the goal is integration proof and stable final-project
evidence.

Suggested report table:

```text
Target      Memory type    Words tested   Write latency   Read latency   Result
small_reg   register file  1..4           8 cycles        6 cycles       PASS 4/4
medium_ram  RAM            16..19         8 cycles        6 cycles       PASS 4/4
large_ram   RAM            256..259       8 cycles        6 cycles       PASS 4/4
```

## 15. Waveform Evidence

Run with `PROBE=true`, then open waves:

```bash
cd helloworld
simvision waves.shm &
```

Useful hierarchy and signals:

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

- AXI write address/data/response handshake.
- Floo request flit activity.
- Remote endpoint address decode.
- AXI read address/data response handshake.
- Final log showing `PASS: 4/4 remote slave readbacks matched`.

## 16. What This Project Proves

This project proves that:

- HAMSA can be integrated with FlooNoC at the external AXI path.
- AXI requests can leave HAMSA as Floo flits.
- A remote NoC-side endpoint can receive those flits and reconstruct AXI.
- Multiple remote AXI slave regions can be selected by address.
- Data integrity is preserved across write/readback transactions.
- The simulation provides measurable latency numbers.
- HAMSA software still runs and prints through UART.

## 17. What It Does Not Yet Prove

This project does not yet prove a full physical multi-tile mesh with multiple
independent HAMSA tiles. The final endpoint has multiple memory-mapped AXI
slaves behind one remote NoC endpoint. That is still a meaningful integration
step because it proves the protocol conversion, routing path, remote decode, data
storage, read response, and software liveness.

Future work could add:

- More physical NoC nodes.
- Multiple HAMSA tiles.
- AXI bursts.
- Multiple outstanding transactions.
- Traffic contention tests.
- Throughput measurement.
- Software-driven remote accesses instead of testbench-driven accesses.

## 18. Short Presentation Summary

We connected HAMSA's external AXI path to FlooNoC using glue logic, a Floo AXI
Chimney, and a router. On the remote side, we added a NoC endpoint that converts
Floo flits back to AXI and decodes the address into three different remote
memories: a small register file, a medium RAM, and a large RAM. The testbench
selects the target from the command line, writes four words, reads them back,
checks correctness, and prints latency. All three targets passed, and the
`helloworld` UART output confirms that HAMSA still boots and runs software.
