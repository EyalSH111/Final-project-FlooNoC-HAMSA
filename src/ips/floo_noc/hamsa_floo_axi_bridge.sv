// Bridge between HAMSA AXI_BUS (interface) and FlooNoC AXI struct types.
`include "axi_bus.sv"

`ifdef USE_FLOO_NOC
import floo_axi_mesh_noc_pkg::*;
`endif

// Local initiator (core/DMA/...) -> Floo chimney manager port (axi_in)
module hamsa_floo_axi_bridge #(
  parameter int unsigned HAMSA_ADDR_WIDTH = 32,
  parameter int unsigned HAMSA_DATA_WIDTH = 32,
  parameter int unsigned HAMSA_ID_WIDTH   = 4,
  parameter int unsigned HAMSA_USER_WIDTH = 1,
  parameter int unsigned FLOO_ID_WIDTH    = 10,
  parameter type floo_req_t = logic,
  parameter type floo_rsp_t = logic
) (
  AXI_BUS        hamsa,
  output floo_req_t floo_req_o,
  input  floo_rsp_t floo_rsp_i
);

  assign floo_req_o.aw_valid = hamsa.aw_valid;
  assign floo_req_o.aw.addr  = hamsa.aw_addr[HAMSA_ADDR_WIDTH-1:0];
  assign floo_req_o.aw.len   = hamsa.aw_len;
  assign floo_req_o.aw.size  = hamsa.aw_size;
  assign floo_req_o.aw.burst = hamsa.aw_burst;
  assign floo_req_o.aw.lock  = hamsa.aw_lock;
  assign floo_req_o.aw.cache = hamsa.aw_cache;
  assign floo_req_o.aw.prot  = hamsa.aw_prot;
  assign floo_req_o.aw.qos   = hamsa.aw_qos;
  assign floo_req_o.aw.region = hamsa.aw_region;
  assign floo_req_o.aw.atop  = '0;
  assign floo_req_o.aw.id    = {{(FLOO_ID_WIDTH-HAMSA_ID_WIDTH){1'b0}}, hamsa.aw_id};
  assign floo_req_o.aw.user  = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.aw_user};

  assign floo_req_o.ar_valid = hamsa.ar_valid;
  assign floo_req_o.ar.addr  = hamsa.ar_addr[HAMSA_ADDR_WIDTH-1:0];
  assign floo_req_o.ar.len   = hamsa.ar_len;
  assign floo_req_o.ar.size  = hamsa.ar_size;
  assign floo_req_o.ar.burst = hamsa.ar_burst;
  assign floo_req_o.ar.lock  = hamsa.ar_lock;
  assign floo_req_o.ar.cache = hamsa.ar_cache;
  assign floo_req_o.ar.prot  = hamsa.ar_prot;
  assign floo_req_o.ar.qos   = hamsa.ar_qos;
  assign floo_req_o.ar.region = hamsa.ar_region;
  assign floo_req_o.ar.id    = {{(FLOO_ID_WIDTH-HAMSA_ID_WIDTH){1'b0}}, hamsa.ar_id};
  assign floo_req_o.ar.user  = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.ar_user};

  assign floo_req_o.w_valid  = hamsa.w_valid;
  assign floo_req_o.w.data   = hamsa.w_data;
  assign floo_req_o.w.strb   = hamsa.w_strb;
  assign floo_req_o.w.last   = hamsa.w_last;
  assign floo_req_o.w.user   = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.w_user};

  assign floo_req_o.b_ready  = hamsa.b_ready;
  assign floo_req_o.r_ready  = hamsa.r_ready;

  assign hamsa.aw_ready = floo_rsp_i.aw_ready;
  assign hamsa.ar_ready = floo_rsp_i.ar_ready;
  assign hamsa.w_ready  = floo_rsp_i.w_ready;

  assign hamsa.b_valid = floo_rsp_i.b_valid;
  assign hamsa.b_id    = floo_rsp_i.b.id[HAMSA_ID_WIDTH-1:0];
  assign hamsa.b_resp  = floo_rsp_i.b.resp;
  assign hamsa.b_user  = floo_rsp_i.b.user[HAMSA_USER_WIDTH-1:0];

  assign hamsa.r_valid = floo_rsp_i.r_valid;
  assign hamsa.r_id    = floo_rsp_i.r.id[HAMSA_ID_WIDTH-1:0];
  assign hamsa.r_data  = floo_rsp_i.r.data;
  assign hamsa.r_resp  = floo_rsp_i.r.resp;
  assign hamsa.r_last  = floo_rsp_i.r.last;
  assign hamsa.r_user  = floo_rsp_i.r.user[HAMSA_USER_WIDTH-1:0];

endmodule

// Floo chimney subordinate (network master) -> HAMSA interconnect initiator port
// Uses concrete axi_out_* types (not parameter type) for Cadence xmelab compatibility.
module hamsa_floo_axi_bridge_noc_init #(
  parameter int unsigned HAMSA_ADDR_WIDTH = 32,
  parameter int unsigned HAMSA_DATA_WIDTH = 32,
  parameter int unsigned HAMSA_ID_WIDTH   = 5,
  parameter int unsigned HAMSA_USER_WIDTH = 1,
  parameter int unsigned FLOO_ID_WIDTH    = 10
) (
  AXI_BUS.Master        hamsa,
  input  axi_out_req_t  floo_req_i,
  output axi_out_rsp_t  floo_rsp_o
);

  assign hamsa.aw_valid = floo_req_i.aw_valid;
  assign hamsa.aw_addr  = floo_req_i.aw.addr;
  assign hamsa.aw_len   = floo_req_i.aw.len;
  assign hamsa.aw_size  = floo_req_i.aw.size;
  assign hamsa.aw_burst = floo_req_i.aw.burst;
  assign hamsa.aw_lock  = floo_req_i.aw.lock;
  assign hamsa.aw_cache = floo_req_i.aw.cache;
  assign hamsa.aw_prot  = floo_req_i.aw.prot;
  assign hamsa.aw_qos   = floo_req_i.aw.qos;
  assign hamsa.aw_region = floo_req_i.aw.region;
  assign hamsa.aw_id    = floo_req_i.aw.id[HAMSA_ID_WIDTH-1:0];
  assign hamsa.aw_user  = floo_req_i.aw.user[HAMSA_USER_WIDTH-1:0];

  assign hamsa.ar_valid = floo_req_i.ar_valid;
  assign hamsa.ar_addr  = floo_req_i.ar.addr;
  assign hamsa.ar_len   = floo_req_i.ar.len;
  assign hamsa.ar_size  = floo_req_i.ar.size;
  assign hamsa.ar_burst = floo_req_i.ar.burst;
  assign hamsa.ar_lock  = floo_req_i.ar.lock;
  assign hamsa.ar_cache = floo_req_i.ar.cache;
  assign hamsa.ar_prot  = floo_req_i.ar.prot;
  assign hamsa.ar_qos   = floo_req_i.ar.qos;
  assign hamsa.ar_region = floo_req_i.ar.region;
  assign hamsa.ar_id    = floo_req_i.ar.id[HAMSA_ID_WIDTH-1:0];
  assign hamsa.ar_user  = floo_req_i.ar.user[HAMSA_USER_WIDTH-1:0];

  assign hamsa.w_valid  = floo_req_i.w_valid;
  assign hamsa.w_data   = floo_req_i.w.data;
  assign hamsa.w_strb   = floo_req_i.w.strb;
  assign hamsa.w_last   = floo_req_i.w.last;
  assign hamsa.w_user   = floo_req_i.w.user[HAMSA_USER_WIDTH-1:0];

  assign floo_rsp_o.aw_ready = hamsa.aw_ready;
  assign floo_rsp_o.ar_ready = hamsa.ar_ready;
  assign floo_rsp_o.w_ready  = hamsa.w_ready;

  assign floo_rsp_o.b_valid = hamsa.b_valid;
  assign floo_rsp_o.b.id    = {{(FLOO_ID_WIDTH-HAMSA_ID_WIDTH){1'b0}}, hamsa.b_id};
  assign floo_rsp_o.b.resp  = hamsa.b_resp;
  assign floo_rsp_o.b.user  = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.b_user};

  assign floo_rsp_o.r_valid = hamsa.r_valid;
  assign floo_rsp_o.r.id    = {{(FLOO_ID_WIDTH-HAMSA_ID_WIDTH){1'b0}}, hamsa.r_id};
  assign floo_rsp_o.r.data  = hamsa.r_data;
  assign floo_rsp_o.r.resp  = hamsa.r_resp;
  assign floo_rsp_o.r.last  = hamsa.r_last;
  assign floo_rsp_o.r.user  = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.r_user};

endmodule

// HAMSA memory target <- Floo subordinate request/response
module hamsa_floo_axi_bridge_mem_tgt #(
  parameter int unsigned HAMSA_ADDR_WIDTH = 32,
  parameter int unsigned HAMSA_DATA_WIDTH = 32,
  parameter int unsigned HAMSA_ID_WIDTH   = 5,
  parameter int unsigned HAMSA_USER_WIDTH = 1,
  parameter int unsigned FLOO_ID_WIDTH    = 10,
  parameter type floo_req_t = logic,
  parameter type floo_rsp_t = logic
) (
  AXI_BUS        hamsa,
  output floo_req_t floo_req_o,
  input  floo_rsp_t floo_rsp_i
);

  assign floo_req_o.aw_ready = hamsa.aw_ready;
  assign floo_req_o.ar_ready = hamsa.ar_ready;
  assign floo_req_o.w_ready  = hamsa.w_ready;

  assign hamsa.aw_valid = floo_rsp_i.aw_valid;
  assign hamsa.aw_addr  = floo_rsp_i.aw.addr;
  assign hamsa.aw_len   = floo_rsp_i.aw.len;
  assign hamsa.aw_size  = floo_rsp_i.aw.size;
  assign hamsa.aw_burst = floo_rsp_i.aw.burst;
  assign hamsa.aw_lock  = floo_rsp_i.aw.lock;
  assign hamsa.aw_cache = floo_rsp_i.aw.cache;
  assign hamsa.aw_prot  = floo_rsp_i.aw.prot;
  assign hamsa.aw_qos   = floo_rsp_i.aw.qos;
  assign hamsa.aw_region = floo_rsp_i.aw.region;
  assign hamsa.aw_id    = floo_rsp_i.aw.id[HAMSA_ID_WIDTH-1:0];
  assign hamsa.aw_user  = floo_rsp_i.aw.user[HAMSA_USER_WIDTH-1:0];

  assign hamsa.ar_valid = floo_rsp_i.ar_valid;
  assign hamsa.ar_addr  = floo_rsp_i.ar.addr;
  assign hamsa.ar_len   = floo_rsp_i.ar.len;
  assign hamsa.ar_size  = floo_rsp_i.ar.size;
  assign hamsa.ar_burst = floo_rsp_i.ar.burst;
  assign hamsa.ar_lock  = floo_rsp_i.ar.lock;
  assign hamsa.ar_cache = floo_rsp_i.ar.cache;
  assign hamsa.ar_prot  = floo_rsp_i.ar.prot;
  assign hamsa.ar_qos   = floo_rsp_i.ar.qos;
  assign hamsa.ar_region = floo_rsp_i.ar.region;
  assign hamsa.ar_id    = floo_rsp_i.ar.id[HAMSA_ID_WIDTH-1:0];
  assign hamsa.ar_user  = floo_rsp_i.ar.user[HAMSA_USER_WIDTH-1:0];

  assign hamsa.w_valid  = floo_rsp_i.w_valid;
  assign hamsa.w_data   = floo_rsp_i.w.data;
  assign hamsa.w_strb   = floo_rsp_i.w.strb;
  assign hamsa.w_last   = floo_rsp_i.w.last;
  assign hamsa.w_user   = floo_rsp_i.w.user[HAMSA_USER_WIDTH-1:0];

  assign floo_req_o.b_valid = hamsa.b_valid;
  assign floo_req_o.b.id    = {{(FLOO_ID_WIDTH-HAMSA_ID_WIDTH){1'b0}}, hamsa.b_id};
  assign floo_req_o.b.resp  = hamsa.b_resp;
  assign floo_req_o.b.user  = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.b_user};

  assign floo_req_o.r_valid = hamsa.r_valid;
  assign floo_req_o.r.id    = {{(FLOO_ID_WIDTH-HAMSA_ID_WIDTH){1'b0}}, hamsa.r_id};
  assign floo_req_o.r.data  = hamsa.r_data;
  assign floo_req_o.r.resp  = hamsa.r_resp;
  assign floo_req_o.r.last  = hamsa.r_last;
  assign floo_req_o.r.user  = {{(1-HAMSA_USER_WIDTH){1'b0}}, hamsa.r_user};

endmodule
