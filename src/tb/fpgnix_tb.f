//INCDIRS
// Do not use +INCDIR+$PULP_ENV/src/ — XRUN can pick up floo_noc/deps/*.sv and cause *E,DUPUNI
+INCDIR+$PULP_ENV/src/soc/
+INCDIR+$PULP_ENV/src/soc/includes/
//+INCDIR+$PULP_ENV/src/soc/flash/
+INCDIR+$PULP_ENV/src/ips/ddr/altera_ddr_64bit
+INCDIR+$PULP_ENV/src/ips/pulpenix/src/fpga

//SUBCOMPONENTS
-f $PULP_ENV/src/ips/floo_noc/floo_noc.f
+incdir+$PULP_ENV/src/ips/floo_noc/hw/include
+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include
// NOPBIND fix: solo dir — not under soc/ (XRUN same-directory batch)
$PULP_ENV/src/ips/floo_noc/xrun_compat/floo_hamsa_pkg/floo_hamsa_pkg.sv
$PULP_ENV/src/ips/floo_noc/hamsa_floo_chimney_wrap.sv
$PULP_ENV/src/ips/floo_noc/hamsa_floo_xtrn_glue.sv
-f $PULP_ENV/src/ips/pulpenix/fpgnix.f

//FILES
$PULP_ENV/src/tb/fpgnix_tb.v
$PULP_ENV/src/tb/smart_uart_tb_non_r2d2.sv
$PULP_ENV/src/tb/py_spi_tb/sv/sock.c
$PULP_ENV/src/tb/py_spi_tb/sv/sock.sv
//$PULP_ENV/src/tb/py_spi_tb/sv/py_spi_tb.sv

// DDR dimm memory
$PULP_ENV/src/tb/ddr2_64bit_mem_model.v
$PULP_ENV/src/tb/ddr2_dimm.v


