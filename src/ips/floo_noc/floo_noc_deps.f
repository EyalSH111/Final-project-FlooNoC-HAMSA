// floo_noc_deps.f - minimal vendored deps for HAMSA + Cadence XRUN
// Regenerate: python3 scripts/gen_floo_noc_deps_f.py
// fifo_v3, rr_arb_tree, cdc_2phase, id_queue: from HAMSA + floo_noc.f xrun_compat
+incdir+$PULP_ENV/src/ips/floo_noc/deps/axi/include
+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells/include
+incdir+$PULP_ENV/src/ips/floo_noc/deps/common_cells
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/cf_math_pkg.sv
$PULP_ENV/src/ips/floo_noc/deps/axi/src/axi_pkg.sv
$PULP_ENV/src/ips/floo_noc/deps/axi/src/axi_intf.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/sync.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/binary_to_gray.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/gray_to_binary.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/addr_decode.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/lzc.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/spill_register_flushable.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/spill_register.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/stream_fifo.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/stream_fifo_optimal_wrap.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/stream_register.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/stream_arbiter_flushable.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/stream_arbiter.sv
$PULP_ENV/src/ips/floo_noc/deps/common_cells/src/cdc_fifo_gray.sv
$PULP_ENV/src/ips/floo_noc/deps/axi/src/axi_err_slv.sv
$PULP_ENV/src/ips/floo_noc/deps/axi/src/axi_demux_simple.sv
