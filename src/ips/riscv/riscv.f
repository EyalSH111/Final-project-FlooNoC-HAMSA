//INCDIRS      
+INCDIR+$PULP_ENV/src/ips/riscv/rtl/include/

//PACKAGES
$PULP_ENV/src/ips/fpnew/src/fpnew_pkg.sv
$PULP_ENV/src/ips/riscv/rtl/include/riscv_defines.sv

//SUBCOMPONENTS     
-f $PULP_ENV/src/ips/mul/mul.f
-f $PULP_ENV/src/ips/riscv-dbg/riscv-dbg.f

//FILES   
$PULP_ENV/src/ips/riscv/rtl/include/apu_core_package.sv
$PULP_ENV/src/ips/riscv/rtl/include/apu_macros.sv
$PULP_ENV/src/ips/riscv/rtl/include/riscv_tracer_defines.sv
$PULP_ENV/src/ips/riscv/rtl/register_file_test_wrap.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_L0_buffer.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_L0_buffer_sampled.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_alu.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_alu_basic.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_alu_div.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_apu_disp.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_compressed_decoder.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_controller.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_core.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_cs_registers.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_debug_unit.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_ex_stage.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_fetch_fifo.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_hwloop_controller.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_hwloop_regs.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_id_stage.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_if_stage.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_int_controller.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_load_store_unit.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_pmp.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_prefetch_L0_buffer.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_prefetch_buffer.sv
$PULP_ENV/src/ips/riscv/rtl/hamsa_L0_cache.sv
$PULP_ENV/src/ips/riscv/rtl/hamsa_prefetch.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_register_file.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_tracer.sv
$PULP_ENV/src/ips/riscv/rtl/riscv_decoder.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/issue2.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/issue2_allocator.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/issue2_fetch_alloc_mini_decode.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/issue2_fetcher.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/di_interfaces/di_ctrl_interface.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/di_interfaces/di_ifstage_interface.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/di_interfaces/di_pfb_interface.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/di_interfaces/di_reg_xfw_interface.sv
$PULP_ENV/src/ips/riscv/rtl/dual_issue/di_interfaces/di_regfile_interface.sv
$PULP_ENV/src/ips/riscv/rtl/axi_mem_if_SP_wrap.sv
$PULP_ENV/src/ips/riscv/rtl/axi_mem_if_SP_async_wrap.sv
$PULP_ENV/src/ips/riscv/rtl/axi_slice_wrap.sv
$PULP_ENV/src/ips/riscv/rtl/core2axi_wrap.sv
$PULP_ENV/src/ips/riscv/rtl/core_region.sv
$PULP_ENV/src/ips/riscv/rtl/instr_ram_wrap.sv
$PULP_ENV/src/ips/riscv/rtl/ram_mux.sv
$PULP_ENV/src/ips/riscv/rtl/inst_narrower.v
$PULP_ENV/src/ips/common_cells/src/rr_arb_tree.sv

$PULP_ENV/src/ips/riscv/rtl/cache_L0/data/data_cache_datapath.sv
$PULP_ENV/src/ips/riscv/rtl/cache_L0/data/data_cache_L0.sv
$PULP_ENV/src/ips/riscv/rtl/cache_L0/instr/instr_cache_datapath.sv
$PULP_ENV/src/ips/riscv/rtl/cache_L0/instr/instr_cache_L0.sv
$PULP_ENV/src/ips/riscv/rtl/cache_L0/cache_algo.sv
$PULP_ENV/src/ips/riscv/rtl/cache_L0/cache_LRU.sv
