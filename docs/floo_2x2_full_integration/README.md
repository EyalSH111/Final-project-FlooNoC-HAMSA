# HAMSA + FlooNoC Full Integration Artifacts

This folder keeps the durable report material for the current
`hamsa-separate-remote-endpoints` branch.

## What Is Saved Here

- `HAMSA_FlooNoC_Project_Report.md` - full start-to-finish project report with overview, goals, architecture diagrams, implementation details, fixes, run commands, proof logs, and performance explanation.
- `HAMSA_FlooNoC_Full_Integration_Report.md` - shorter integration report focused on the final NoC/AXI proof.
- `HAMSA_FlooNoC_Full_Integration_Report.docx` - Word version of the integration report.
- `make_docx.py` - local script used to generate the Word document without external Python packages.
- `proof_bank2_run_excerpt.txt` - older saved passing Xcelium log excerpt from the previous 4-bank RAM demo.

## Current Proof

The latest proof uses one remote NoC-side endpoint with three distinct
memory-mapped AXI slave regions:

```text
target 0: small_reg,  16 x 32-bit   -> 0x0010_0000 .. 0x0010_00ff
target 1: medium_ram, 256 x 32-bit  -> 0x0010_1000 .. 0x0010_13ff
target 2: large_ram,  1024 x 32-bit -> 0x0010_2000 .. 0x0010_2fff
```

Run the three targets separately:

```bash
# target 0: small register file, words 1..4
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=0 +FLOO_REMOTE_IDX=1 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=A0000001"

# target 1: medium RAM, words 16..19
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=1 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=B0001000"

# target 2: large RAM, words 256..259
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=2 +FLOO_REMOTE_IDX=256 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=C0002000"
```

Expected final proof in each run:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

The observed directed-test latency is 8 cycles for each write response and 6
cycles for each read response.
