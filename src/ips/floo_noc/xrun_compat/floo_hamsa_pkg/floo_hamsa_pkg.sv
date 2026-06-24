// Copyright 2026
// Stage-1 HAMSA single-tile FlooNoC configuration package.

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_hamsa_pkg;

  import floo_pkg::*;

  localparam int unsigned NumX = 1;
  localparam int unsigned NumY = 2;
  localparam int unsigned NumRoutes = 5;

  localparam axi_cfg_t AxiCfg = '{
    AddrWidth:  32,
    DataWidth:  32,
    UserWidth:  1,
    InIdWidth:  5,
    OutIdWidth: 7
  };

  localparam route_cfg_t RouteCfg = '{
    RouteAlgo:                 XYRouting,
    UseIdTable:                1'b0,
    XYAddrOffsetX:             16,
    XYAddrOffsetY:             20,
    IdAddrOffset:              0,
    NumSamRules:               1,
    NumRoutes:                 1,
    EnMultiCast:               1'b0,
    EnParallelReduction:       1'b0,
    EnNarrowOffloadReduction:  1'b0,
    EnWideOffloadReduction:    1'b0
  };

  localparam chimney_cfg_t ChimneyCfg = ChimneyDefaultCfg;

  localparam bit          AtopSupport    = 1'b1;
  localparam int unsigned MaxAtomicTxns  = 4;

  typedef logic [0:0] rob_idx_t;
  typedef logic [0:0] port_id_t;
  typedef logic [0:0] x_bits_t;
  typedef logic [0:0] y_bits_t;

  `FLOO_TYPEDEF_XY_NODE_ID_T(id_t, x_bits_t, y_bits_t, port_id_t)
  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, axi_ch_e, rob_idx_t)

  typedef logic [AxiCfg.AddrWidth-1:0]  axi_in_addr_t;
  typedef logic [AxiCfg.DataWidth-1:0]  axi_in_data_t;
  typedef logic [AxiCfg.DataWidth/8-1:0] axi_in_strb_t;
  typedef logic [AxiCfg.InIdWidth-1:0]  axi_in_id_t;
  typedef logic [AxiCfg.UserWidth-1:0]  axi_in_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_in, axi_in_req_t, axi_in_rsp_t, axi_in_addr_t, axi_in_id_t,
                      axi_in_data_t, axi_in_strb_t, axi_in_user_t)

  typedef logic [AxiCfg.AddrWidth-1:0]   axi_out_addr_t;
  typedef logic [AxiCfg.DataWidth-1:0]   axi_out_data_t;
  typedef logic [AxiCfg.DataWidth/8-1:0] axi_out_strb_t;
  typedef logic [AxiCfg.OutIdWidth-1:0]  axi_out_id_t;
  typedef logic [AxiCfg.UserWidth-1:0]   axi_out_user_t;
  `AXI_TYPEDEF_ALL_CT(axi_out, axi_out_req_t, axi_out_rsp_t, axi_out_addr_t, axi_out_id_t,
                      axi_out_data_t, axi_out_strb_t, axi_out_user_t)

  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, axi_in, AxiCfg, hdr_t)
  `FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)

  localparam id_t TileId       = '{x: 1'b0, y: 1'b0, port_id: 1'b0};
  localparam id_t RemoteTileId = '{x: 1'b0, y: 1'b1, port_id: 1'b0};

  localparam int unsigned FlooReqBits = $bits(floo_req_t);
  localparam int unsigned FlooRspBits = $bits(floo_rsp_t);

endpackage
