# HAMSA + FlooNoC Full Integration Artifacts

This folder keeps the durable evidence and report material for the `hamsa-2x2-full-integration` branch.

## What Is Saved Here

- `HAMSA_FlooNoC_Full_Integration_Report.md` - full written report with architecture, flow diagrams, run instructions, and proof interpretation.
- `proof_bank2_run_excerpt.txt` - passing Xcelium log excerpt from the 4-bank RAM demo.

## Current Proof

The latest proof uses one remote NoC-side AXI endpoint containing four independent RAM banks:

```text
RAM bank 0 -> 0x0010_0000 .. 0x0010_03ff
RAM bank 1 -> 0x0010_0400 .. 0x0010_07ff
RAM bank 2 -> 0x0010_0800 .. 0x0010_0bff
RAM bank 3 -> 0x0010_0c00 .. 0x0010_0fff
```

The saved passing run targets RAM bank 2, words 16..19:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_BANK=2 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=ABCD2000"
```

Expected final proof:

```text
[FLOO_2X2] PASS: 4/4 remote RAM readbacks matched
Hey we use floonoc!
--- FINISH ---
```
