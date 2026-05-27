// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_axi_mesh_noc_pkg;

  import floo_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

  typedef enum logic[2:0] {
    ClusterX0Y0 = 0,
    ClusterX0Y1 = 1,
    ClusterX1Y0 = 2,
    ClusterX1Y1 = 3,
    Hbm0 = 4,
    Hbm1 = 5,
    NumEndpoints = 6} ep_id_e;



  typedef enum logic[2:0] {
    ClusterX0Y0SamIdx = 0,
    ClusterX0Y1SamIdx = 1,
    ClusterX1Y0SamIdx = 2,
    ClusterX1Y1SamIdx = 3,
    Hbm0SamIdx = 4,
    Hbm1SamIdx = 5} sam_idx_e;



  typedef logic[0:0] rob_idx_t;
typedef logic[0:0] port_id_t;
typedef logic[1:0] x_bits_t;
typedef logic[0:0] y_bits_t;
typedef struct packed {
    x_bits_t x;
    y_bits_t y;
    port_id_t port_id;
} id_t;

typedef logic route_t;


  localparam int unsigned SamNumRules = 5;

typedef struct packed {
    id_t idx;
    logic [31:0] start_addr;
    logic [31:0] end_addr;
} sam_rule_t;

// HAMSA msystem address map -> 2x2 cluster tile IDs (see floo_hamsa_noc_wrap.sv)
localparam sam_rule_t[SamNumRules-1:0] Sam = '{
'{    idx: '{x: 2, y: 1, port_id: 0},
    start_addr: 32'h1AC0_0000,
    end_addr: 32'hFFFF_FFFF}, // xtrn_master / tile (1,1)
'{    idx: '{x: 2, y: 1, port_id: 0},
    start_addr: 32'h1A80_0000,
    end_addr: 32'h1ABF_FFFF}, // MMSPI / tile (1,1)
'{    idx: '{x: 2, y: 0, port_id: 0},
    start_addr: 32'h1A10_0000,
    end_addr: 32'h1A4F_FFFF}, // peripherals / tile (1,0)
'{    idx: '{x: 1, y: 1, port_id: 0},
    start_addr: 32'h0010_0000,
    end_addr: 32'h001F_FFFF}, // data RAM / tile (0,1)
'{    idx: '{x: 1, y: 1, port_id: 0},
    start_addr: 32'h0000_0000,
    end_addr: 32'h000F_FFFF}  // instr RAM / tile (0,1)
};



  localparam route_cfg_t RouteCfg = '{    RouteAlgo: XYRouting,
    UseIdTable: 1'b1,
    XYAddrOffsetX: 32,
    XYAddrOffsetY: 34,
    IdAddrOffset: 0,
    NumSamRules: 5,
    NumRoutes: 0,
    EnMultiCast: 1'b0,
    EnParallelReduction: 1'b0,
    EnNarrowOffloadReduction: 1'b0,
    EnWideOffloadReduction: 1'b0};


    typedef logic[31:0] axi_in_addr_t;
typedef logic[31:0] axi_in_data_t;
typedef logic[3:0] axi_in_strb_t;
typedef logic[9:0] axi_in_id_t;
typedef logic[0:0] axi_in_user_t;
`AXI_TYPEDEF_ALL_CT(axi_in,             axi_in_req_t,             axi_in_rsp_t,             axi_in_addr_t,             axi_in_id_t,             axi_in_data_t,             axi_in_strb_t,             axi_in_user_t)


    typedef logic[31:0] axi_out_addr_t;
typedef logic[31:0] axi_out_data_t;
typedef logic[3:0] axi_out_strb_t;
typedef logic[9:0] axi_out_id_t;
typedef logic[0:0] axi_out_user_t;
`AXI_TYPEDEF_ALL_CT(axi_out,             axi_out_req_t,             axi_out_rsp_t,             axi_out_addr_t,             axi_out_id_t,             axi_out_data_t,             axi_out_strb_t,             axi_out_user_t)



  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, axi_ch_e, rob_idx_t)
  localparam axi_cfg_t AxiCfg = '{    AddrWidth: 32,
    DataWidth: 32,
    InIdWidth: 10,
    OutIdWidth: 10,
    UserWidth: 1};
`FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, AxiCfg, hdr_t)

`FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)


endpackage
