
# HAMSA + FlooNoC Integration

This repository contains a working HAMSA/PULPenix SoC integration with FlooNoC.
The main proof is an end-to-end AXI transaction path: HAMSA-side external AXI
traffic enters FlooNoC, crosses the NoC fabric, reaches a remote AXI endpoint,
writes data into a selected remote memory region, reads it back, and checks the
result in simulation.

The current branch is:

```text
hamsa-separate-remote-endpoints
```

What this branch demonstrates:

- HAMSA still boots and runs the `helloworld` software.
- The HAMSA `xtrn` AXI path is connected into FlooNoC through AXI/Floo Chimney logic.
- Remote traffic is decoded into three memory-mapped AXI slave regions.
- The testbench can choose the target, first word, number of words, and data from the command line.
- The simulation prints PASS/FAIL and per-transaction latency in cycles.

Detailed documentation is in:

```text
docs/floo_2x2_full_integration/HAMSA_FlooNoC_Project_Report.md
docs/floo_2x2_full_integration/HAMSA_FlooNoC_Full_Integration_Report.md
docs/floo_2x2_full_integration/HAMSA_FlooNoC_Full_Integration_Report.docx
```

## Quick Run On RC / TSMC65

First-time clone:

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS
git clone git@github.com:EyalSH111/Final-project-FlooNoC-HAMSA.git ddp23_pnx_PoC
cd ddp23_pnx_PoC
git checkout hamsa-separate-remote-endpoints
source cloud_setup.sh
```

If the repository already exists:

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS/ddp23_pnx_PoC
git fetch origin
git checkout hamsa-separate-remote-endpoints
git pull --ff-only origin hamsa-separate-remote-endpoints
source cloud_setup.sh
```

Run the default end-to-end readback test:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"
grep -E 'FLOO_BUILD|FLOO_2X2|FLOO_STIM|FLOO_MON|TIMEOUT|Hey|FINISH|write response|read response|PASS|FAIL' helloworld/xrun.log
```

Expected final proof:

```text
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
Hey we use floonoc!
--- FINISH ---
```

Run each remote AXI target separately:

```bash
# Target 0: small register-file slave, words 1..4.
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=0 +FLOO_REMOTE_IDX=1 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=A0000001"

# Target 1: medium RAM slave, words 16..19.
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=1 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=B0001000"

# Target 2: large RAM slave, words 256..259.
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_TARGET=2 +FLOO_REMOTE_IDX=256 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=C0002000"
```

Each command runs one target. To prove all three remote memories, run the three
commands above one after another. `FLOO_REMOTE_TARGET` selects one of three
remote AXI slave regions. `FLOO_REMOTE_IDX` selects the first word inside that
target. The TB writes `FLOO_REMOTE_WORDS` consecutive words, then reads them
back. The base address remains `0x0010_0000`, which routes to the remote
tile/endpoint by setting `XYAddrOffsetY=20`.

Address map:

```text
target 0: small fast register file, 16 x 32-bit  -> 0x0010_0000 .. 0x0010_00ff
target 1: medium RAM,              256 x 32-bit -> 0x0010_1000 .. 0x0010_13ff
target 2: large RAM,              1024 x 32-bit -> 0x0010_2000 .. 0x0010_2fff
```

Memory size meaning:

```text
16 x 32-bit   = 16 words, each word is 32 bits / 4 bytes
256 x 32-bit  = 256 words, 1024 bytes total
1024 x 32-bit = 1024 words, 4096 bytes total
```

Useful proof lines in `helloworld/xrun.log`:

```text
[FLOO_STIM] write response target=... word=... latency_cycles=...
[FLOO_STIM] read response target=... word=... data=... latency_cycles=...
[FLOO_2X2] PASS: remote slave readback target=... word=...
[FLOO_2X2] PASS: 4/4 remote slave readbacks matched
```

Performance measurement is printed directly by the testbench:

```text
[FLOO_STIM] write response target=... word=... latency_cycles=...
[FLOO_STIM] read response target=... word=... data=... latency_cycles=...
```

Use these lines to compare the small register file, medium RAM, and large RAM
runs. In the current single-beat directed tests, the observed values are:

```text
write response latency: 8 cycles
read response latency:  6 cycles
```

This is a directed latency measurement for the integrated path, not a full
throughput benchmark.

Open waves after a `PROBE=true` run:

```bash
cd helloworld
simvision waves.shm &
```

Useful wave hierarchy:

```text
fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem
fpgnix_tb.i_hamsa_floo_remote_mem_endpoint
```

## Legacy Course Setup Notes

First time setup (just once)  
----------------------------

open a terminal and enter following commands   

```bash
# RC3 Cloud environment:
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
mkdir  $DDP23_USER_WS/ddp23 
cd  $DDP23_USER_WS/ddp23 

# Enics environment (Aplicable only for Enics Labs system users) :
generic
setenv DDP23_USER_WS /project/generic/users/$USER/ws
mkdir  $DDP23_USER_WS/ddp23_pulpenix 
cd  $DDP23_USER_WS/ddp23_pulpenix
```


git clone  https://gitlab.com/udik/ddp23_pnx.git  
gitlab username and password might be required  

Only in case above clone does not work try this:  
git clone git@gitlab.com:udik/ddp23_pnx.git  

```
mkdir sim  
 
Cloud users: Edit ~/.bashrc  
Enics users: Edit ~/.cshrc 
 (This file automatically runs every time you open a terminal)  
You may invoke editing the file with vscode by  
code ~/.bashrc  (or code ~/.cshrc for Enics users)  
Carefully add these lines to the end of the file:  

Cloud users:
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
source $DDP23_USER_WS/ddp23/ddp23_pnx/cloud_setup.sh  

Enics Users:
setenv DDP23_USER_WS /project/generic/users/$USER/ws
source $DDP23_USER_WS/ddp23/ddp23_pnx/nx_setup.sh 

Save and close the file  
close all terminal and open a new one to proceed.  
```

Helloworld Simulation
---------------------

In a fresh new terminal :  

tsmc65  

cd $PULP_ENV/../sim  

Execute this:

ddp23_make APP=helloworld  

Some warnnings may show up, you may ignore them for now, eventuelly this should be displayed:  

HELLO DDP24  
--- FINISH ---  

If so you are done with the initial setup  

you may now slightly modify the C source file (e.g. personalize to hello your name):  

The C source file is located at:  

$MY_DDP23_APPS/helloworld/helloworld.c   

and re-run:

ddp23_make APP=helloworld

Your modification should be noticed in the outcome simulation print.

Running with DDR interface enabled  
------------------------------------

**Real DDR simulated, extremely slow runtime**  
ddp23_make APP=hello_ddr XRUN_FLAGS="+define+DDR_INTRFC"

**Pseudo DDR simulated, much faster runtime**  
ddp23_make APP=hello_ddr XRUN_FLAGS="+define+DDR_INTRFC+PSD_DDR"
