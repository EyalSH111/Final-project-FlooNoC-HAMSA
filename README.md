
# HAMSA + FlooNoC Integration

This branch contains the HAMSA/FlooNoC integration demos.

- Stable Stage-1 PoC: HAMSA xtrn AXI traffic is converted into Floo flits.
- Full integration demo: HAMSA xtrn AXI traffic crosses a FlooNoC path to a NoC-side AXI endpoint with four independent 256-word RAM banks, writes several words, reads them back, checks correctness, and prints latency per transaction.

## Quick Run On RC / TSMC65

First-time clone:

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS
git clone git@github.com:EyalSH111/Final-project-FlooNoC-HAMSA.git ddp23_pnx_PoC
cd ddp23_pnx_PoC
git checkout hamsa-2x2-full-integration
source cloud_setup.sh
```

If the repository already exists:

```bash
tsmc65
export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
cd $DDP23_USER_WS/ddp23_pnx_PoC
git fetch origin
git checkout hamsa-2x2-full-integration
git pull --ff-only origin hamsa-2x2-full-integration
source cloud_setup.sh
```

Run the default end-to-end RAM readback test:

```bash
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60"
grep -E 'FLOO_BUILD|FLOO_2X2|FLOO_STIM|FLOO_MON|TIMEOUT|Hey|FINISH|write response|read response|PASS|FAIL' helloworld/xrun.log
```

Expected final proof:

```text
[FLOO_2X2] PASS: 4/4 remote RAM readbacks matched
Hey we use floonoc!
--- FINISH ---
```

Choose which remote RAM bank and words to exercise:

```bash
# Default: write/read 4 words in RAM bank 0, starting at word 0.
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_BANK=0 +FLOO_REMOTE_IDX=0 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=F100F100"

# Run the same proof in RAM bank 2, starting at word 16.
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_BANK=2 +FLOO_REMOTE_IDX=16 +FLOO_REMOTE_WORDS=4 +FLOO_REMOTE_DATA=ABCD2000"

# Single-word targeted proof in RAM bank 3.
ddp23_make APP=helloworld run REBUILD=true PROBE=true XRUN_FLAGS="+FLOO_SIM_TIMEOUT_S=60 +FLOO_REMOTE_BANK=3 +FLOO_REMOTE_IDX=3 +FLOO_REMOTE_WORDS=1 +FLOO_REMOTE_DATA=ABCD3003"
```

`FLOO_REMOTE_BANK` selects one of four independent RAM banks. `FLOO_REMOTE_IDX` selects the first RAM word inside that bank. The TB writes `FLOO_REMOTE_WORDS` consecutive words, then reads them back. Internally, bank selection uses AXI address bits `[11:10]` and word selection uses `[9:2]`. The base address remains `0x0010_0000`, which routes to the remote tile/endpoint by setting `XYAddrOffsetY=20`.

Address map:

```text
RAM bank 0 -> 0x0010_0000 .. 0x0010_03ff
RAM bank 1 -> 0x0010_0400 .. 0x0010_07ff
RAM bank 2 -> 0x0010_0800 .. 0x0010_0bff
RAM bank 3 -> 0x0010_0c00 .. 0x0010_0fff
```

Useful proof lines in `helloworld/xrun.log`:

```text
[FLOO_STIM] write response bank=... word=... latency_cycles=...
[FLOO_STIM] read response bank=... word=... data=... latency_cycles=...
[FLOO_2X2] PASS: remote RAM readback bank=... word=...
[FLOO_2X2] PASS: 4/4 remote RAM readbacks matched
```

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
