// Stage-1 FlooNoC compile manifest (self-contained under $PULP_ENV/src/ips/floo_noc)
// Compile before pulpenix.f / msystem.sv

+incdir+$PULP_ENV/src/ips/floo_noc/hw/include
+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include
+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells/include
// Do NOT add +incdir+.../deps/common_cells (src/): XRUN auto-compiles all .sv → DUPUNI vs HAMSA common_cells

-f $PULP_ENV/src/ips/floo_noc/floo_noc_deps.f

$PULP_ENV/src/ips/floo_noc/hw/floo_pkg.sv
// XRUN 23.x: id_queue uses parameter type (not localparam type in deps/)
$PULP_ENV/src/ips/floo_noc/xrun_compat/id_queue.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_cut.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_fifo.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_cdc.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_route_select.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/floo_id_translation.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_vc_arbiter.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_wormhole_arbiter.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_simple_rob.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_rob.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_rob_wrapper.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_reduction_sync.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_route_xymask.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_route_comp.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/floo_meta_buffer.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_reduction_arbiter.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_output_arbiter.sv
$PULP_ENV/src/ips/floo_noc/xrun_compat/floo_axi_chimney.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_router.sv
$PULP_ENV/src/ips/floo_noc/hw/floo_axi_router.sv

$PULP_ENV/src/ips/floo_noc/hamsa_floo_xtrn_glue.sv
