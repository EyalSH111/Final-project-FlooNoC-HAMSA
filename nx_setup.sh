setenv DDP23_USER_WS /project/generic/users/$USER/ws
setenv PULP_ENV $DDP23_USER_WS/ddp23_pulpenix/ddp23_pnx
setenv FLOO_NOC_ROOT `cd $PULP_ENV/../../FlooNoC && pwd`
setenv XBOX_SRC $PULP_ENV/src/ips/xbox
setenv MY_DDP23_APPS $PULP_ENV/src/ips/pulpenix_sw/apps
setenv PULP_GCC_BIN /opt/pulp/pulp-gcc-centos6-20200913/bin
alias ddp23_make "qrun make -f $PULP_ENV/src/tb/sim.make BAUD_RATE=2500000"
