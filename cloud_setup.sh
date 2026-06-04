export DDP23_USER_WS=/data/project/tsmc65/users/$USER/ws
# GitHub FlooNoC integration tree (not legacy ddp23/ddp23_pnx)
export PULP_ENV=$DDP23_USER_WS/ddp23_pnx
export FLOO_NOC_ROOT=$DDP23_USER_WS/FlooNoC
export XBOX_SRC=$PULP_ENV/src/ips/xbox
export MY_DDP23_APPS=$PULP_ENV/src/ips/pulpenix_sw/apps
export PULP_GCC_BIN=/data/project/tsmc65/shared/ddp_hackathon/toolchain/pulp-gcc-centos7-20200913/bin
alias ddp23_make="make -f $PULP_ENV/src/tb/sim.make BAUD_RATE=2500000"
export PATH=/project/tsmc65/shared/misc_udi_kra_shared/python2.7/pypy2.7-v7.3.20-linux64/bin:$PATH

