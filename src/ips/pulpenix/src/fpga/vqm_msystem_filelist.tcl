set PULP_ENV $env(PULP_ENV)

puts "* incdirs..."
set_option -include_path ../..
set_option -include_path ../soc/
set_option -include_path ../soc/includes/
set_option -include_path ../soc/flash/
set_option -include_path ../soc/includes/
set_option -include_path ${PULP_ENV}/src/ips/axi/axi_node/
set_option -include_path ${PULP_ENV}/src/ips/axi/axi_node/
set_option -include_path ${PULP_ENV}/src/ips/apb/apb_uart_sv/
set_option -include_path ${PULP_ENV}/src/ips/apb/apb_i2c/
set_option -include_path ${PULP_ENV}/src/ips/apb/apb_event_unit/include/
set_option -include_path ${PULP_ENV}/src/ips/riscv/rtl/include/
set_option -include_path ${PULP_ENV}/src/ips/adv_dbg_if/rtl/
set_option -include_path ${PULP_ENV}/src/ips/crg_legacy/design/axi2cbus/hdl
set_option -incluse_path ${PULP_ENV}/src/ips/crg_legacy/design/cbus2axi/hdl
puts "* add_file..."
add_file ${PULP_ENV}/src/ips/fpnew/src/fpnew_pkg.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/include/riscv_defines.sv
add_file ../soc/includes/axi_bus.sv
add_file ../soc/includes/apb_bus.sv
add_file ./fpgnix_address_map.vh
# add_file ./fpgnix.v
add_file  ./vqm_msystem_wrap.v

add_file ../crr/spi_slave_native.v
add_file ./altera_sram.v
add_file ./altera_sram_16384x32.v
add_file ./altera_sram_2048x128.v
add_file ./altera_sram_4096x128.v
add_file ./altera_sram_16384x128.v
add_file ./altera_sram_8192x32.v
add_file ./altera_sram_12288x128.v
add_file ./altera_sram_10240x128.v
add_file ./altera_sram_7680x128.v
add_file ./altera_sram_49152x32.v

add_file ./pll.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_axi_biu.sv
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_axi_defines.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_axi_module.sv
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_crc32.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_defines.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_or1k_biu.sv
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_or1k_defines.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_or1k_module.sv
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_or1k_status_reg.sv
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_tap_defines.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_tap_top.v
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adbg_top.sv
add_file ${PULP_ENV}/src/ips/adv_dbg_if/rtl/adv_dbg_if.sv
# add_file ${PULP_ENV}/src/ips/altera_sim/altera_mf.v
add_file ${PULP_ENV}/src/ips/apb/apb2per/apb2per.sv
add_file ${PULP_ENV}/src/ips/apb/apb_event_unit/apb_event_unit.sv
add_file ${PULP_ENV}/src/ips/apb/apb_event_unit/generic_service_unit.sv
#add_file ${PULP_ENV}/src/ips/apb/apb_event_unit/include/defines_event_unit.sv
add_file ${PULP_ENV}/src/ips/apb/apb_event_unit/sleep_unit.sv
add_file ${PULP_ENV}/src/ips/apb/apb_fll_if/apb_fll_if.sv
add_file ${PULP_ENV}/src/ips/apb/apb_gpio/apb_gpio.sv
add_file ${PULP_ENV}/src/ips/apb/apb_i2c/apb_i2c.sv
add_file ${PULP_ENV}/src/ips/apb/apb_i2c/i2c_master_bit_ctrl.sv
add_file ${PULP_ENV}/src/ips/apb/apb_i2c/i2c_master_byte_ctrl.sv
add_file ${PULP_ENV}/src/ips/apb/apb_i2c/i2c_master_defines.sv
add_file ${PULP_ENV}/src/ips/apb/apb_node/apb_node.sv
add_file ${PULP_ENV}/src/ips/apb/apb_node/apb_node_wrap.sv
add_file ${PULP_ENV}/src/ips/apb/apb_pulpino/apb_pulpino.sv
add_file ${PULP_ENV}/src/ips/apb/apb_spi_master/apb_spi_master.sv
add_file ${PULP_ENV}/src/ips/apb/apb_spi_master/spi_master_apb_if.sv
add_file ${PULP_ENV}/src/ips/apb/apb_timer/apb_timer.sv
add_file ${PULP_ENV}/src/ips/apb/apb_timer/timer.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/apb_uart.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/io_generic_fifo.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/openocd_bitbang.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/openocd_jtag.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/smart_uart_defines.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/uart_interrupt.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/uart_rx.sv
add_file ${PULP_ENV}/src/ips/apb/apb_uart_sv/uart_tx.sv
add_file ${PULP_ENV}/src/ips/axi/axi2apb/axi2apb.sv
add_file ${PULP_ENV}/src/ips/axi/axi2apb/axi2apb32.sv
add_file ${PULP_ENV}/src/ips/axi/axi_mem_if_DP/axi_mem_if_SP.sv
add_file ${PULP_ENV}/src/ips/axi/axi_mem_if_DP/axi_mem_if_SP_async.sv
add_file ${PULP_ENV}/src/ips/axi/axi_mem_if_DP/axi_read_only_ctrl.sv
add_file ${PULP_ENV}/src/ips/axi/axi_mem_if_DP/axi_write_only_ctrl.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_AR_allocator.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_AW_allocator.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_ArbitrationTree.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_BR_allocator.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_BW_allocator.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_DW_allocator.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_FanInPrimitive_Req.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_RR_Flag_Req.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_address_decoder_AR.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_address_decoder_AW.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_address_decoder_BR.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_address_decoder_BW.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_address_decoder_DW.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_multiplexer.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_node.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_request_block.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/axi_response_block.sv
add_file ${PULP_ENV}/src/ips/axi/axi_node/defines.v
add_file ${PULP_ENV}/src/ips/axi/axi_slice/axi_ar_buffer.sv
add_file ${PULP_ENV}/src/ips/axi/axi_slice/axi_aw_buffer.sv
add_file ${PULP_ENV}/src/ips/axi/axi_slice/axi_b_buffer.sv
add_file ${PULP_ENV}/src/ips/axi/axi_slice/axi_r_buffer.sv
add_file ${PULP_ENV}/src/ips/axi/axi_slice/axi_slice.sv
add_file ${PULP_ENV}/src/ips/axi/axi_slice/axi_w_buffer.sv
add_file ${PULP_ENV}/src/ips/axi/axi_slice_dc/dc_data_buffer.v
add_file ${PULP_ENV}/src/ips/axi/axi_slice_dc/dc_full_detector.v
add_file ${PULP_ENV}/src/ips/axi/axi_slice_dc/dc_synchronizer.v
add_file ${PULP_ENV}/src/ips/axi/axi_slice_dc/dc_token_ring.v
add_file ${PULP_ENV}/src/ips/axi/axi_slice_dc/dc_token_ring_fifo_din.v
add_file ${PULP_ENV}/src/ips/axi/axi_slice_dc/dc_token_ring_fifo_dout.v
add_file ${PULP_ENV}/src/ips/axi/axi_spi_master/spi_master_clkgen.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_master/spi_master_controller.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_master/spi_master_fifo.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_master/spi_master_rx.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_master/spi_master_tx.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/axi_spi_slave.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_axi_plug.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_cmd_parser.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_controller.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_dc_fifo.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_regs.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_rx.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_syncro.sv
add_file ${PULP_ENV}/src/ips/axi/axi_spi_slave/spi_slave_tx.sv
add_file ${PULP_ENV}/src/ips/axi/axi_uart_slave/axi_uart_slave.sv
add_file ${PULP_ENV}/src/ips/axi/core2axi/core2axi.sv
add_file ${PULP_ENV}/src/ips/common_cells/src/cdc_2phase.sv
add_file ${PULP_ENV}/src/ips/common_cells/src/deprecated/fifo_v2.sv
add_file ${PULP_ENV}/src/ips/common_cells/src/fifo_v3.sv
add_file ${PULP_ENV}/src/ips/common_cells/src/rr_arb_tree.sv
add_file ${PULP_ENV}/src/ips/crg_legacy/design/axi2cbus/hdl/axi2cbus_cfg.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/axi2cbus/hdl/axi2cbus_top.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/axi2cbus/hdl/axi_slv_if.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/axi2cbus/hdl/cbus_slv_if.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_an2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_clockgate.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_inv.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_mx2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_nand2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_xor2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_glitch_free_mux.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_tieoff.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_sync/hdl/crg_reset_sync.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_sync/hdl/crg_sync2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_sync/hdl/crg_sync2_arst.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_sync/hdl/crg_sync2n_arst.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/intc.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/sc_fifo.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_clkgen.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_cntif.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_core.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_machine.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_sfi_mm.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_shifter.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_sync.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/spi/hdl/spi_top.v
add_file ${PULP_ENV}/src/ips/interco/RTL/lint_2_axi.sv
add_file ${PULP_ENV}/src/ips/mul/rtl/riscv_mult.sv
add_file ../soc/axi2apb_wrap.sv
add_file ../soc/axi_node_intf_wrap.sv
add_file ../soc/axi_spi_slave_wrap.sv
add_file ../soc/boot_code.sv
add_file ../soc/boot_rom_wrap.sv
add_file ../soc/clk_rst_gen.sv
add_file ../soc/components/cluster_clock_gating.sv
add_file ../soc/components/cluster_clock_inverter.sv
add_file ../soc/components/cluster_clock_mux2.sv
add_file ../soc/components/generic_fifo.sv
add_file ../soc/components/pulp_clock_inverter.sv
add_file ../soc/components/pulp_clock_mux2.sv
add_file ../soc/components/rstgen.sv
add_file ../soc/components/sp_ram.sv
# add_file ../soc/gpp_regfile_example.sv
add_file ../soc/includes/config.sv
add_file ../soc/includes/remote_access_intrfc.sv
add_file ../soc/msystem.sv
add_file ../soc/periph_bus_wrap.sv
add_file ../soc/peripherals.sv
add_file ../sp_ram_wrap.sv
add_file ../spram.v



# add_file ${PULP_ENV}/src/fpga/altera_sp_ram_1024x256_be.v
# add_file ${PULP_ENV}/src/ips/xbox/xbox_mem.sv
# add_file ${PULP_ENV}/src/ips/xbox/xbox_imx.sv
# add_file ${PULP_ENV}/src/ips/xbox/xbox.sv

add_file ${PULP_ENV}/src/ips/riscv-dbg/debug_rom/debug_rom.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dm_pkg.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dm_csrs.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dm_mem.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dm_sba.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dm_top.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dm_wrap.v
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dmi_cdc.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dmi_jtag.sv
add_file ${PULP_ENV}/src/ips/riscv-dbg/src/dmi_jtag_tap.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/axi_mem_if_SP_wrap.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/axi_mem_if_SP_async_wrap.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/axi_slice_wrap.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/cache_L0/cache_LRU.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/cache_L0/cache_algo.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/cache_L0/data/data_cache_L0.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/cache_L0/data/data_cache_datapath.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/cache_L0/instr/instr_cache_L0.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/cache_L0/instr/instr_cache_datapath.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/core2axi_wrap.sv
#add_file ${PULP_ENV}/src/ips/riscv/rtl/core_region.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/di_interfaces/di_ctrl_interface.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/di_interfaces/di_ifstage_interface.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/di_interfaces/di_pfb_interface.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/di_interfaces/di_reg_xfw_interface.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/di_interfaces/di_regfile_interface.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/issue2.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/issue2_allocator.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/issue2_fetch_alloc_mini_decode.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/dual_issue/issue2_fetcher.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/include/apu_core_package.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/include/apu_macros.sv
# add_file ${PULP_ENV}/src/ips/riscv/rtl/include/riscv_tracer_defines.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/inst_narrower.v
add_file ${PULP_ENV}/src/ips/riscv/rtl/instr_ram_wrap.sv
#add_file ${PULP_ENV}/src/ips/riscv/rtl/ram_mux.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/register_file_test_wrap.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_L0_buffer.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_L0_buffer_sampled.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_alu.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_alu_basic.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_alu_div.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_apu_disp.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_compressed_decoder.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_controller.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_core.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_cs_registers.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_debug_unit.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_decoder.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_ex_stage.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_fetch_fifo.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_hwloop_controller.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_hwloop_regs.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_id_stage.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_if_stage.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_int_controller.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_load_store_unit.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_pmp.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_prefetch_L0_buffer.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_prefetch_buffer.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/hamsa_prefetch.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/hamsa_L0_cache.sv
add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_register_file.sv
# add_file ${PULP_ENV}/src/ips/riscv/rtl/riscv_tracer.sv
# add_file ${PULP_ENV}/src/ips/riscv/tb/dm/SimJTAG.sv
add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xcore_region.sv
#add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xissue2.sv
add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xram_mux.sv
#add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xregister_file_test_wrap.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_controller.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_core.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_id_stage.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_register_file.sv
#add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_register_file_CARME_wrap.sv
#add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_register_file_MPSCM_wrap.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/Xriscv_register_file_mux.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/uASLR.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/uASLR_data.sv
# add_file ${PULP_ENV}/src/ips/riscv-exp/rtl/uASLR_inst.sv
add_file ${PULP_ENV}/src/ips/std_cells/rtl/glitch_free_clock_mux.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_and.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_and3.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_buf.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_cg.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_ff.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_ffsync.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_ff_arst.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_ffsync_arst.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_ff_aset.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_ffn_arst.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_inv.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_lat.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_lat_trans_low.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_mx2.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_mx4.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_nand.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_nor.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_or.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_tie_hi.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_tie_lo.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_xnor.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/m_xor.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/reset_sample.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/rst_sync.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/sync_2ff.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/sync_2ff_arst.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/sync_2ff_aset.v
add_file ${PULP_ENV}/src/ips/std_cells/rtl/sync_2ffn_arst.v
add_file ./pulpenix_defines.v
add_file ../soc/boot_flash_direct_intrfc.v
add_file ../soc/flash/wbqspiflash.v
add_file ../soc/flash/flash_boot.v
add_file ../soc/flash/llqspi.v
# add_file ../tb/mem_preload.v
# add_file ../tb/pulpenix_tb.v
# add_file ../tb/s25fl129p00.v
# add_file ../tb/sflash_tb.v
# add_file ../tb/tb_xx_driver.v
# add_file ../tb/uart_vip.sv
add_file ${PULP_ENV}/src/ips/crg_legacy/design/gp_dma/hdl/gp_dma_arb.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/gp_dma/hdl/gp_dma_fifo.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/gp_dma/hdl/gp_dma_regs.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/gp_dma/hdl/gp_dma.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/gp_dma/hdl/gp_dma_top.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/apb2cbus.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/generic_clk_div.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/generic_fifo_crgn.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/generic_fifo_env_2prf_a128d32.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/soc_building_blocks/hdl/generic_fifo_env_2prf_a256d24.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_bscan_cell.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_chip_jtag.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_buf.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_clockgate_cust.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_mx4.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_nor2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_clk_or2.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_ff_arst.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_lat.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_mx3.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_mx4.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_cells/hdl/crg_scan_ff.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_sync/hdl/crg_reset_cross.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/dw_sync/hdl/crg_sync2_arst_bus.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/cbus2axi/hdl/axi_mstr_if.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/cbus2axi/hdl/cbus2axi_top.v
add_file ${PULP_ENV}/src/ips/crg_legacy/design/cbus2axi/hdl/cbus_mstr_if.v
add_file ./edram_ss.v
