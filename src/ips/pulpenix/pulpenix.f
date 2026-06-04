//INCDIRS
+INCDIR+$PULP_ENV/src/ips/pulpenix/src/soc/includes/

//SUBCOMPONENTS
-f $PULP_ENV/src/ips/std_cells/std_cells.f
-f $PULP_ENV/src/ips/axi/axi_slice/axi_slice.f
-f $PULP_ENV/src/ips/axi/axi_slice_dc/axi_slice_dc.f
-f $PULP_ENV/src/ips/axi/axi_uart_slave/axi_uart_slave.f
-f $PULP_ENV/src/ips/axi/axi_spi_slave/axi_spi_slave.f
-f $PULP_ENV/src/ips/axi/axi_spi_master/axi_spi_master.f
-f $PULP_ENV/src/ips/axi/axi_node/axi_node.f
-f $PULP_ENV/src/ips/axi/axi_mem_if_DP/axi_mem_if_DP.f
-f $PULP_ENV/src/ips/axi/axi2apb/axi2apb.f
-f $PULP_ENV/src/ips/axi/core2axi/core2axi.f
-f $PULP_ENV/src/ips/apb/apb_node/apb_node.f
-f $PULP_ENV/src/ips/apb/apb_uart_sv/apb_uart_sv.f
-f $PULP_ENV/src/ips/apb/apb_timer/apb_timer.f
-f $PULP_ENV/src/ips/apb/apb_i2c/apb_i2c.f
-f $PULP_ENV/src/ips/apb/apb_event_unit/apb_event_unit.f
-f $PULP_ENV/src/ips/apb/apb_fll_if/apb_fll_if.f
-f $PULP_ENV/src/ips/apb/apb_pulpino/apb_pulpino.f
-f $PULP_ENV/src/ips/apb/apb_gpio/apb_gpio.f
-f $PULP_ENV/src/ips/apb/apb_spi_master/apb_spi_master.f
-f $PULP_ENV/src/ips/apb/apb2per/apb2per.f
-f $PULP_ENV/src/ips/riscv/riscv.f
-f $PULP_ENV/src/ips/riscv-exp/riscv-exp.f
-f $PULP_ENV/src/ips/crg_legacy/design/spi/work/d_file
-f $PULP_ENV/src/ips/crg_legacy/design/axi2cbus/work/d_file
-f $PULP_ENV/src/ips/crg_legacy/design/dw_cells/work/pnx_d_file
-f $PULP_ENV/src/ips/crg_legacy/design/dw_sync/work/pnx_d_file
-f $PULP_ENV/src/ips/crg_legacy/design/soc_building_blocks/work/pnx_d_file
-f $PULP_ENV/src/ips/crg_legacy/design/gp_dma/work/d_file
-f $PULP_ENV/src/ips/crg_legacy/sansa_crg_legacy.f
-f $PULP_ENV/src/ips/crg_legacy/design/cbus2axi/work/d_file

//FILES
// floo_hamsa_pkg.sv: compiled from fpgnix_tb.f (after floo_noc.f) for XRUN package order
$PULP_ENV/src/ips/pulpenix/src/soc/msystem.sv
$PULP_ENV/src/ips/pulpenix/src/soc/includes/remote_access_intrfc.sv
$PULP_ENV/src/ips/pulpenix/src/sp_ram_wrap.sv
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/arm_modular_128x4096_sram_hs.sv
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/arm_modular_128x4096_sram_hd.sv
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/sp_sram16384X32_bank_i.v
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/sp_sram2048X128_wbp_bank_i.v
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/sp_sram2048X128_bank_i.v
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/sp_sram4096X128_bank_i.v
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/sp_sram8192X32_bank_i.v
$PULP_ENV/src/ips/pulpenix/src/mem_wrappers/sp_sram1024X8_i.v
$PULP_ENV/src/ips/pulpenix/src/spram.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta1024x8m4s_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta16384x32m16sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta2048x128m4sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta2048x32m4sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta4096x128m4sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta8192x32m16sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta8192x32m8sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc16/ts1n16ffcllulvta2048x32m8sw_120a.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc65/hd/ARM_SPSRAM_32X8192_M16_MEM.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc65/hs/ARM_SPSRAM_128X2048_M4_MEM.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc65/hs/ARM_SPSRAM_64X4096_M8_MEM.v
$PULP_ENV/src/ips/pulpenix/src/mems/tsmc65/hd/ARM_SPSRAM_32X16384_M16_MEM.v
$PULP_ENV/src/ips/pulpenix/src/soc/axi2apb_wrap.sv
$PULP_ENV/src/ips/pulpenix/src/soc/axi_node_intf_wrap.sv
$PULP_ENV/src/ips/pulpenix/src/soc/axi_spi_slave_wrap.sv
$PULP_ENV/src/ips/pulpenix/src/soc/boot_code.sv
$PULP_ENV/src/ips/pulpenix/src/soc/boot_rom_wrap.sv
$PULP_ENV/src/ips/pulpenix/src/soc/clk_rst_gen.sv
$PULP_ENV/src/ips/pulpenix/src/soc/periph_bus_wrap.sv
$PULP_ENV/src/ips/pulpenix/src/soc/peripherals.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/cluster_clock_gating.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/cluster_clock_inverter.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/cluster_clock_mux2.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/generic_fifo.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/pulp_clock_inverter.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/pulp_clock_mux2.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/rstgen.sv
$PULP_ENV/src/ips/pulpenix/src/soc/components/sp_ram.sv

//TODO
//$PULP_ENV/src/ips/fpnew/src/fpnew_pkg.sv
