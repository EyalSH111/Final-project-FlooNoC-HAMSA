# HAMSA + FlooNoC Full Integration Report

## Executive Summary

This work integrates FlooNoC into the HAMSA/PULPenix SoC by routing HAMSA's external AXI path (`xtrn`, exposed through `masters[4]` / `slaves[4]`) through a Floo AXI Chimney and Router. The final demo proves a full end-to-end transaction: HAMSA-side AXI traffic is converted into Floo flits, routed to a remote NoC-side endpoint, converted back to AXI, written into a selectable remote AXI RAM bank, read back, and checked for correctness.

The latest proof is stronger than the original single-register demo. The remote endpoint now contains four independent 256-word RAM banks, and the testbench can select which RAM bank and which words to access using plusargs.

Final proof line from the passing run:

```text
[FLOO_2X2] PASS: 4/4 remote RAM readbacks matched
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
              Remote Floo AXI RAM Endpoint
             +-----------------------------+
             | remote Chimney              |
             | Floo flits <-> AXI          |
             |                             |
             | RAM bank 0: 256 x 32-bit    |
             | RAM bank 1: 256 x 32-bit    |
             | RAM bank 2: 256 x 32-bit    |
             | RAM bank 3: 256 x 32-bit    |
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
   Chimney to reconstruct AXI, and performs the access on a local AXI RAM bank.

6. The remote endpoint sends B or R responses back through FlooNoC.

7. HAMSA-side Chimney converts response flits back into AXI responses. The TB
   checks the readback data and prints PASS/FAIL.
```

## Remote RAM Bank Map

The current endpoint contains four independent RAM banks. Each bank has 256 words, and each word is 32 bits.

```text
RAM bank 0 -> 0x0010_0000 .. 0x0010_03ff
RAM bank 1 -> 0x0010_0400 .. 0x0010_07ff
RAM bank 2 -> 0x0010_0800 .. 0x0010_0bff
RAM bank 3 -> 0x0010_0c00 .. 0x0010_0fff
```

Address decoding inside the remote endpoint:

```text
address[20]    -> routes traffic to remote NoC endpoint
address[11:10] -> selects RAM bank 0..3
address[9:2]   -> selects word 0..255 inside that RAM bank
address[1:0]   -> byte offset inside the 32-bit word
```

Example:

```text
0x0010_0840 = bank 2, word 16
0x0010_0844 = bank 2, word 17
0x0010_0848 = bank 2, word 18
0x0010_084c = bank 2, word 19
```

## How To Run

From the RC / TSMC65 environment:

```bash
tsmc65
cd /data/project/tsmc65/users/eyalsho/ws/ddp23_pnx_PoC
source cloud_setup.sh
git checkout hamsa-2x2-full-integration
git fetch origin
git reset --hard origin/hamsa-2x2-full-integration
```

Default proof, RAM bank 0, words 0..3:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"
```

Selectable RAM proof, RAM bank 2, words 16..19:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_BANK=2 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=ABCD2000"
```

Extract the proof from the log:

```bash
grep -E '\*E|FLOO_BUILD|FLOO_2X2|FLOO_STIM|FLOO_MON|TIMEOUT|Hey|FINISH|PASS|FAIL|latency_cycles|bank=' helloworld/xrun.log
```

## Testbench Options

```text
FLOO_REMOTE_BANK  = RAM bank to access, 0..3
FLOO_REMOTE_IDX   = first word inside that RAM bank, 0..255
FLOO_REMOTE_WORDS = number of consecutive words to test, 1..4
FLOO_REMOTE_DATA  = first write data value
```

The testbench writes consecutive data values. For example:

```bash
+FLOO_REMOTE_BANK=2 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=ABCD2000
```

produces:

```text
bank 2 word 16 -> 0xabcd2000
bank 2 word 17 -> 0xabcd2001
bank 2 word 18 -> 0xabcd2002
bank 2 word 19 -> 0xabcd2003
```

## Proof From Passing Run

The passing run targeted bank 2, words 16..19:

```text
[FLOO_STIM] remote RAM target base=0x00100000 bank=2 first_word=16 words=4 first_data=0xabcd2000
[FLOO_2X2] remote AXI RAM AR addr=0x00100840 bank=2 word=16 id=0x7f @ time 54350000
[FLOO_2X2] remote AXI RAM R response accepted bank=2 word=16 data=0xabcd2000 @ time 54450000
[FLOO_STIM] read response bank=2 word=16 data=0xabcd2000 latency_cycles=6 @ time 54650000
[FLOO_2X2] PASS: remote RAM readback bank=2 word=16 data=0xabcd2000
...
[FLOO_2X2] SUMMARY: remote RAM readbacks pass=4 fail=0 total=4
[FLOO_2X2] PASS: 4/4 remote RAM readbacks matched
Hey we use floonoc!
--- FINISH ---
```

## Timing And Measurement

The testbench records a simple latency counter around each AXI transaction. It prints:

```text
[FLOO_STIM] write response bank=... word=... latency_cycles=...
[FLOO_STIM] read response bank=... word=... data=... latency_cycles=...
```

In the passing bank-2 run:

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
4 writes + 4 reads to consecutive words in a selected RAM bank
bank selection + word selection + unique data per word
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
- The remote AXI RAM bank stores different data values at different addresses.
- AXI read responses return through the reverse NoC path and match expected data.
- The testbench can select different RAM banks and addresses without RTL edits.

## What This Does Not Yet Prove

The demo does not yet instantiate four physically separate NoC tiles, each with a separate router coordinate. Instead, it implements four independent RAM banks behind one remote NoC endpoint. This is a good final-project tradeoff: it demonstrates address-based remote memory selection through the integrated NoC path while avoiding the risk of a late topology expansion.

## Waveform Suggestions

For GUI proof in SimVision, open `helloworld/waves.shm` after a `PROBE=true` run and inspect:

```text
fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.masters[4]
fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.chimney_floo_req_o
fpgnix_tb.fpgnix.floo_req_o
fpgnix_tb.fpgnix.floo_rsp_i
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_slv_req
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_slv_rsp
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_aw_bank_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_ar_bank_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_aw_idx_q
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint.remote_ar_idx_q
```

Recommended screenshots:

- AXI AW/W/B handshake for one write to bank 2.
- Floo request flit activity on the north link.
- Remote endpoint AW/W decode showing bank 2 and word 16.
- AXI AR/R handshake for the readback.
- Final log window showing `PASS: 4/4 remote RAM readbacks matched`.

## Short Explanation For Presentation

We integrated FlooNoC into HAMSA by replacing the external/inter-tile AXI path with a Chimney + Router path. The demo drives AXI traffic from HAMSA's `xtrn` port, converts it into Floo flits, sends it to a remote endpoint, converts it back into AXI, and accesses a selectable remote RAM bank. The latest version has four remote RAM banks, each with 256 words. The testbench selects bank 2 and words 16..19, writes unique data values, reads them back, and reports 4/4 matches while HAMSA continues to boot and print `Hey we use floonoc!`.
