// Bridges HAMSA AXI_BUS xtrn ports (masters[4]/slaves[4]) to Floo chimney struct ports.

`include "axi_bus.sv"
`include "axi/typedef.svh"
`include "axi/assign.svh"

import floo_hamsa_pkg::*;

module hamsa_floo_xtrn_glue #(
  parameter int unsigned HAMSA_MGR_ID_WIDTH = 2,
  parameter int unsigned HAMSA_SLV_ID_WIDTH = 5
) (
  AXI_BUS.Master xtrn_initiator,
  AXI_BUS.Slave  xtrn_target,
  output axi_in_req_t  chimney_mgr_req_o,
  input  axi_in_rsp_t  chimney_mgr_rsp_i,
  input  axi_out_req_t chimney_slv_req_i,
  output axi_out_rsp_t chimney_slv_rsp_o
);

  axi_in_req_t  mgr_req;
  axi_in_rsp_t  mgr_rsp;
  axi_out_req_t slv_req;
  axi_out_rsp_t slv_rsp;

  function automatic axi_in_id_t pad_mgr_id(input logic [HAMSA_MGR_ID_WIDTH-1:0] id);
    pad_mgr_id = '0;
    pad_mgr_id[HAMSA_MGR_ID_WIDTH-1:0] = id;
  endfunction

  function automatic logic [HAMSA_MGR_ID_WIDTH-1:0] trunc_mgr_id(input axi_in_id_t id);
    trunc_mgr_id = id[HAMSA_MGR_ID_WIDTH-1:0];
  endfunction

  function automatic axi_out_id_t pad_slv_id(input logic [HAMSA_SLV_ID_WIDTH-1:0] id);
    pad_slv_id = '0;
    pad_slv_id[HAMSA_SLV_ID_WIDTH-1:0] = id;
  endfunction

  function automatic logic [HAMSA_SLV_ID_WIDTH-1:0] trunc_slv_id(input axi_out_id_t id);
    trunc_slv_id = id[HAMSA_SLV_ID_WIDTH-1:0];
  endfunction

  // Chip initiator (masters[4]) -> chimney manager (axi_in)
  always_comb begin
    mgr_req            = '0;
    mgr_req.aw_valid   = xtrn_initiator.aw_valid;
    mgr_req.aw.addr    = xtrn_initiator.aw_addr;
    mgr_req.aw.len     = xtrn_initiator.aw_len;
    mgr_req.aw.size    = xtrn_initiator.aw_size;
    mgr_req.aw.burst   = xtrn_initiator.aw_burst;
    mgr_req.aw.lock    = xtrn_initiator.aw_lock;
    mgr_req.aw.cache   = xtrn_initiator.aw_cache;
    mgr_req.aw.prot    = xtrn_initiator.aw_prot;
    mgr_req.aw.qos     = xtrn_initiator.aw_qos;
    mgr_req.aw.region  = xtrn_initiator.aw_region;
    mgr_req.aw.atop    = '0;
    mgr_req.aw.id      = pad_mgr_id(xtrn_initiator.aw_id);
    mgr_req.aw.user    = xtrn_initiator.aw_user;
    mgr_req.ar_valid   = xtrn_initiator.ar_valid;
    mgr_req.ar.addr    = xtrn_initiator.ar_addr;
    mgr_req.ar.len     = xtrn_initiator.ar_len;
    mgr_req.ar.size    = xtrn_initiator.ar_size;
    mgr_req.ar.burst   = xtrn_initiator.ar_burst;
    mgr_req.ar.lock    = xtrn_initiator.ar_lock;
    mgr_req.ar.cache   = xtrn_initiator.ar_cache;
    mgr_req.ar.prot    = xtrn_initiator.ar_prot;
    mgr_req.ar.qos     = xtrn_initiator.ar_qos;
    mgr_req.ar.region  = xtrn_initiator.ar_region;
    mgr_req.ar.id      = pad_mgr_id(xtrn_initiator.ar_id);
    mgr_req.ar.user    = xtrn_initiator.ar_user;
    mgr_req.w_valid    = xtrn_initiator.w_valid;
    mgr_req.w.data     = xtrn_initiator.w_data;
    mgr_req.w.strb     = xtrn_initiator.w_strb;
    mgr_req.w.last     = xtrn_initiator.w_last;
    mgr_req.w.user     = xtrn_initiator.w_user;
    mgr_req.b_ready    = xtrn_initiator.b_ready;
    mgr_req.r_ready    = xtrn_initiator.r_ready;

    xtrn_initiator.aw_ready = mgr_rsp.aw_ready;
    xtrn_initiator.ar_ready = mgr_rsp.ar_ready;
    xtrn_initiator.w_ready  = mgr_rsp.w_ready;
    xtrn_initiator.b_valid  = mgr_rsp.b_valid;
    xtrn_initiator.b_id     = trunc_mgr_id(mgr_rsp.b.id);
    xtrn_initiator.b_resp   = mgr_rsp.b.resp;
    xtrn_initiator.b_user   = mgr_rsp.b.user;
    xtrn_initiator.r_valid  = mgr_rsp.r_valid;
    xtrn_initiator.r_id     = trunc_mgr_id(mgr_rsp.r.id);
    xtrn_initiator.r_data   = mgr_rsp.r.data;
    xtrn_initiator.r_resp   = mgr_rsp.r.resp;
    xtrn_initiator.r_last   = mgr_rsp.r.last;
    xtrn_initiator.r_user   = mgr_rsp.r.user;
  end

  assign chimney_mgr_req_o = mgr_req;
  assign mgr_rsp           = chimney_mgr_rsp_i;

  // Chimney subordinate (axi_out) -> chip target (slaves[4])
  always_comb begin
    slv_req = chimney_slv_req_i;
    slv_rsp = '0;

    xtrn_target.aw_valid = slv_req.aw_valid;
    xtrn_target.aw_addr  = slv_req.aw.addr;
    xtrn_target.aw_len   = slv_req.aw.len;
    xtrn_target.aw_size  = slv_req.aw.size;
    xtrn_target.aw_burst = slv_req.aw.burst;
    xtrn_target.aw_lock  = slv_req.aw.lock;
    xtrn_target.aw_cache = slv_req.aw.cache;
    xtrn_target.aw_prot  = slv_req.aw.prot;
    xtrn_target.aw_qos   = slv_req.aw.qos;
    xtrn_target.aw_region = slv_req.aw.region;
    xtrn_target.aw_id    = trunc_slv_id(slv_req.aw.id);
    xtrn_target.aw_user  = slv_req.aw.user;
    xtrn_target.ar_valid = slv_req.ar_valid;
    xtrn_target.ar_addr  = slv_req.ar.addr;
    xtrn_target.ar_len   = slv_req.ar.len;
    xtrn_target.ar_size  = slv_req.ar.size;
    xtrn_target.ar_burst = slv_req.ar.burst;
    xtrn_target.ar_lock   = slv_req.ar.lock;
    xtrn_target.ar_cache  = slv_req.ar.cache;
    xtrn_target.ar_prot   = slv_req.ar.prot;
    xtrn_target.ar_qos    = slv_req.ar.qos;
    xtrn_target.ar_region = slv_req.ar.region;
    xtrn_target.ar_id    = trunc_slv_id(slv_req.ar.id);
    xtrn_target.ar_user  = slv_req.ar.user;
    xtrn_target.w_valid  = slv_req.w_valid;
    xtrn_target.w_data   = slv_req.w.data;
    xtrn_target.w_strb   = slv_req.w.strb;
    xtrn_target.w_last   = slv_req.w.last;
    xtrn_target.w_user   = slv_req.w.user;
    xtrn_target.b_ready  = slv_req.b_ready;
    xtrn_target.r_ready  = slv_req.r_ready;

    slv_rsp.aw_ready = xtrn_target.aw_ready;
    slv_rsp.ar_ready = xtrn_target.ar_ready;
    slv_rsp.w_ready  = xtrn_target.w_ready;
    slv_rsp.b_valid  = xtrn_target.b_valid;
    slv_rsp.b.id     = pad_slv_id(xtrn_target.b_id);
    slv_rsp.b.resp   = xtrn_target.b_resp;
    slv_rsp.b.user   = xtrn_target.b_user;
    slv_rsp.r_valid  = xtrn_target.r_valid;
    slv_rsp.r.id     = pad_slv_id(xtrn_target.r_id);
    slv_rsp.r.data   = xtrn_target.r_data;
    slv_rsp.r.resp   = xtrn_target.r_resp;
    slv_rsp.r.last   = xtrn_target.r_last;
    slv_rsp.r.user   = xtrn_target.r_user;

    chimney_slv_rsp_o = slv_rsp;
  end

endmodule
