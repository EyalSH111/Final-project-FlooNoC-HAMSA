// this filelist is used to build the fpga port of pulpenix - fpgnix
$PULP_ENV/src/ips/pulpenix/src/fpga/fpgnix_address_map.vh
-f $PULP_ENV/src/ips/pulpenix/pulpenix.f
-f $XBOX_SRC/xbox.f
-f $PULP_ENV/src/ips/ddr/altera_ddr_64bit/altera_ddr_64bit.f
-f $PULP_ENV/src/ips/ddr/src/ddr.f
$PULP_ENV/src/ips/pulpenix/src/fpga/faked_fast_sim_altpll.v
$PULP_ENV/src/ips/pulpenix/src/fpga/vqm_msystem_wrap.v
$PULP_ENV/src/ips/pulpenix/src/fpga/fpgnix_gpp.sv
$PULP_ENV/src/ips/pulpenix/src/fpga/fpgnix_hir.sv
