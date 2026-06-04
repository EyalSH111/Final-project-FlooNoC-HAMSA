
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
