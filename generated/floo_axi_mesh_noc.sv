// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module floo_axi_mesh_noc
  import floo_pkg::*;
  import floo_axi_mesh_noc_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_enable_i,
  input axi_in_req_t             [1:0][1:0] cluster_axi_in_req_i,
  output axi_in_rsp_t             [1:0][1:0] cluster_axi_in_rsp_o,
  output axi_out_req_t             [1:0][1:0] cluster_axi_out_req_o,
  input axi_out_rsp_t             [1:0][1:0] cluster_axi_out_rsp_i,
  output axi_out_req_t             [1:0] hbm_axi_out_req_o,
  input axi_out_rsp_t             [1:0] hbm_axi_out_rsp_i

);

floo_req_t router_0_0_to_router_0_1_req;
floo_rsp_t router_0_1_to_router_0_0_rsp;

floo_req_t router_0_0_to_router_1_0_req;
floo_rsp_t router_1_0_to_router_0_0_rsp;

floo_req_t router_0_0_to_cluster_ni_0_0_req;
floo_rsp_t cluster_ni_0_0_to_router_0_0_rsp;

floo_req_t router_0_0_to_hbm_ni_0_req;
floo_rsp_t hbm_ni_0_to_router_0_0_rsp;

floo_req_t router_0_1_to_router_0_0_req;
floo_rsp_t router_0_0_to_router_0_1_rsp;

floo_req_t router_0_1_to_router_1_1_req;
floo_rsp_t router_1_1_to_router_0_1_rsp;

floo_req_t router_0_1_to_cluster_ni_0_1_req;
floo_rsp_t cluster_ni_0_1_to_router_0_1_rsp;

floo_req_t router_0_1_to_hbm_ni_1_req;
floo_rsp_t hbm_ni_1_to_router_0_1_rsp;

floo_req_t router_1_0_to_router_0_0_req;
floo_rsp_t router_0_0_to_router_1_0_rsp;

floo_req_t router_1_0_to_router_1_1_req;
floo_rsp_t router_1_1_to_router_1_0_rsp;

floo_req_t router_1_0_to_cluster_ni_1_0_req;
floo_rsp_t cluster_ni_1_0_to_router_1_0_rsp;

floo_req_t router_1_1_to_router_0_1_req;
floo_rsp_t router_0_1_to_router_1_1_rsp;

floo_req_t router_1_1_to_router_1_0_req;
floo_rsp_t router_1_0_to_router_1_1_rsp;

floo_req_t router_1_1_to_cluster_ni_1_1_req;
floo_rsp_t cluster_ni_1_1_to_router_1_1_rsp;

floo_req_t cluster_ni_0_0_to_router_0_0_req;
floo_rsp_t router_0_0_to_cluster_ni_0_0_rsp;

floo_req_t cluster_ni_0_1_to_router_0_1_req;
floo_rsp_t router_0_1_to_cluster_ni_0_1_rsp;

floo_req_t cluster_ni_1_0_to_router_1_0_req;
floo_rsp_t router_1_0_to_cluster_ni_1_0_rsp;

floo_req_t cluster_ni_1_1_to_router_1_1_req;
floo_rsp_t router_1_1_to_cluster_ni_1_1_rsp;

floo_req_t hbm_ni_0_to_router_0_0_req;
floo_rsp_t router_0_0_to_hbm_ni_0_rsp;

floo_req_t hbm_ni_1_to_router_0_1_req;
floo_rsp_t router_0_1_to_hbm_ni_1_rsp;



  localparam id_t CLUSTER_NI_0_0_ID = '{x: 1, y: 0, port_id: 0};

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(axi_in_req_t),
  .axi_in_rsp_t(axi_in_rsp_t),
  .axi_out_req_t(axi_out_req_t),
  .axi_out_rsp_t(axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) cluster_ni_0_0 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( cluster_axi_in_req_i[0][0] ),
  .axi_in_rsp_o  ( cluster_axi_in_rsp_o[0][0] ),
  .axi_out_req_o ( cluster_axi_out_req_o[0][0] ),
  .axi_out_rsp_i ( cluster_axi_out_rsp_i[0][0] ),
  .id_i             ( CLUSTER_NI_0_0_ID       ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cluster_ni_0_0_to_router_0_0_req   ),
  .floo_rsp_i       ( router_0_0_to_cluster_ni_0_0_rsp   ),
  .floo_req_i       ( router_0_0_to_cluster_ni_0_0_req   ),
  .floo_rsp_o       ( cluster_ni_0_0_to_router_0_0_rsp   )
);

  localparam id_t CLUSTER_NI_0_1_ID = '{x: 1, y: 1, port_id: 0};

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(axi_in_req_t),
  .axi_in_rsp_t(axi_in_rsp_t),
  .axi_out_req_t(axi_out_req_t),
  .axi_out_rsp_t(axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) cluster_ni_0_1 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( cluster_axi_in_req_i[0][1] ),
  .axi_in_rsp_o  ( cluster_axi_in_rsp_o[0][1] ),
  .axi_out_req_o ( cluster_axi_out_req_o[0][1] ),
  .axi_out_rsp_i ( cluster_axi_out_rsp_i[0][1] ),
  .id_i             ( CLUSTER_NI_0_1_ID       ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cluster_ni_0_1_to_router_0_1_req   ),
  .floo_rsp_i       ( router_0_1_to_cluster_ni_0_1_rsp   ),
  .floo_req_i       ( router_0_1_to_cluster_ni_0_1_req   ),
  .floo_rsp_o       ( cluster_ni_0_1_to_router_0_1_rsp   )
);

  localparam id_t CLUSTER_NI_1_0_ID = '{x: 2, y: 0, port_id: 0};

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(axi_in_req_t),
  .axi_in_rsp_t(axi_in_rsp_t),
  .axi_out_req_t(axi_out_req_t),
  .axi_out_rsp_t(axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) cluster_ni_1_0 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( cluster_axi_in_req_i[1][0] ),
  .axi_in_rsp_o  ( cluster_axi_in_rsp_o[1][0] ),
  .axi_out_req_o ( cluster_axi_out_req_o[1][0] ),
  .axi_out_rsp_i ( cluster_axi_out_rsp_i[1][0] ),
  .id_i             ( CLUSTER_NI_1_0_ID       ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cluster_ni_1_0_to_router_1_0_req   ),
  .floo_rsp_i       ( router_1_0_to_cluster_ni_1_0_rsp   ),
  .floo_req_i       ( router_1_0_to_cluster_ni_1_0_req   ),
  .floo_rsp_o       ( cluster_ni_1_0_to_router_1_0_rsp   )
);

  localparam id_t CLUSTER_NI_1_1_ID = '{x: 2, y: 1, port_id: 0};

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b1)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(axi_in_req_t),
  .axi_in_rsp_t(axi_in_rsp_t),
  .axi_out_req_t(axi_out_req_t),
  .axi_out_rsp_t(axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) cluster_ni_1_1 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( cluster_axi_in_req_i[1][1] ),
  .axi_in_rsp_o  ( cluster_axi_in_rsp_o[1][1] ),
  .axi_out_req_o ( cluster_axi_out_req_o[1][1] ),
  .axi_out_rsp_i ( cluster_axi_out_rsp_i[1][1] ),
  .id_i             ( CLUSTER_NI_1_1_ID       ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( cluster_ni_1_1_to_router_1_1_req   ),
  .floo_rsp_i       ( router_1_1_to_cluster_ni_1_1_rsp   ),
  .floo_req_i       ( router_1_1_to_cluster_ni_1_1_req   ),
  .floo_rsp_o       ( cluster_ni_1_1_to_router_1_1_rsp   )
);

  localparam id_t HBM_NI_0_ID = '{x: 0, y: 0, port_id: 0};

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(axi_in_req_t),
  .axi_in_rsp_t(axi_in_rsp_t),
  .axi_out_req_t(axi_out_req_t),
  .axi_out_rsp_t(axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) hbm_ni_0 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
  .axi_out_req_o ( hbm_axi_out_req_o[0] ),
  .axi_out_rsp_i ( hbm_axi_out_rsp_i[0] ),
  .id_i             ( HBM_NI_0_ID       ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( hbm_ni_0_to_router_0_0_req   ),
  .floo_rsp_i       ( router_0_0_to_hbm_ni_0_rsp   ),
  .floo_req_i       ( router_0_0_to_hbm_ni_0_req   ),
  .floo_rsp_o       ( hbm_ni_0_to_router_0_0_rsp   )
);

  localparam id_t HBM_NI_1_ID = '{x: 0, y: 1, port_id: 0};

floo_axi_chimney  #(
  .AxiCfg(AxiCfg),
  .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
  .RouteCfg(RouteCfg),
  .id_t(id_t),
  .rob_idx_t(rob_idx_t),
  .hdr_t  (hdr_t),
  .sam_rule_t(sam_rule_t),
  .Sam(Sam),
  .axi_in_req_t(axi_in_req_t),
  .axi_in_rsp_t(axi_in_rsp_t),
  .axi_out_req_t(axi_out_req_t),
  .axi_out_rsp_t(axi_out_rsp_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) hbm_ni_1 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .sram_cfg_i ( '0 ),
  .axi_in_req_i  ( '0 ),
  .axi_in_rsp_o  (    ),
  .axi_out_req_o ( hbm_axi_out_req_o[1] ),
  .axi_out_rsp_i ( hbm_axi_out_rsp_i[1] ),
  .id_i             ( HBM_NI_1_ID       ),
  .route_table_i    ( '0                          ),
  .floo_req_o       ( hbm_ni_1_to_router_0_1_req   ),
  .floo_rsp_i       ( router_0_1_to_hbm_ni_1_rsp   ),
  .floo_req_i       ( router_0_1_to_hbm_ni_1_req   ),
  .floo_rsp_o       ( hbm_ni_1_to_router_0_1_rsp   )
);


floo_req_t router_0_0_req_in [4:0];
floo_rsp_t router_0_0_rsp_out [4:0];
floo_req_t router_0_0_req_out [4:0];
floo_rsp_t router_0_0_rsp_in [4:0];

    assign router_0_0_req_in[0] = router_0_1_to_router_0_0_req;
    assign router_0_0_req_in[1] = router_1_0_to_router_0_0_req;
    assign router_0_0_req_in[2] = '0;
    assign router_0_0_req_in[3] = hbm_ni_0_to_router_0_0_req;
    assign router_0_0_req_in[4] = cluster_ni_0_0_to_router_0_0_req;

    assign router_0_0_to_router_0_1_rsp = router_0_0_rsp_out[0];
    assign router_0_0_to_router_1_0_rsp = router_0_0_rsp_out[1];
    assign router_0_0_to_hbm_ni_0_rsp = router_0_0_rsp_out[3];
    assign router_0_0_to_cluster_ni_0_0_rsp = router_0_0_rsp_out[4];

    assign router_0_0_to_router_0_1_req = router_0_0_req_out[0];
    assign router_0_0_to_router_1_0_req = router_0_0_req_out[1];
    assign router_0_0_to_hbm_ni_0_req = router_0_0_req_out[3];
    assign router_0_0_to_cluster_ni_0_0_req = router_0_0_req_out[4];

    assign router_0_0_rsp_in[0] = router_0_1_to_router_0_0_rsp;
    assign router_0_0_rsp_in[1] = router_1_0_to_router_0_0_rsp;
    assign router_0_0_rsp_in[2] = '0;
    assign router_0_0_rsp_in[3] = hbm_ni_0_to_router_0_0_rsp;
    assign router_0_0_rsp_in[4] = cluster_ni_0_0_to_router_0_0_rsp;

  localparam id_t ROUTER_0_0_ID = '{x: 1, y: 0, port_id: 0};

floo_axi_router #(
  .AxiCfg(AxiCfg),
  .RouteAlgo (XYRouting),
  .NumRoutes (5),
  .NumInputs (5),
  .NumOutputs (5),
  .InFifoDepth (2),
  .OutFifoDepth (2),
  .id_t(id_t),
  .hdr_t(hdr_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) router_0_0 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i (ROUTER_0_0_ID),
  .id_route_map_i ('0),
  .floo_req_i (router_0_0_req_in),
  .floo_rsp_o (router_0_0_rsp_out),
  .floo_req_o (router_0_0_req_out),
  .floo_rsp_i (router_0_0_rsp_in)
);


floo_req_t router_0_1_req_in [4:0];
floo_rsp_t router_0_1_rsp_out [4:0];
floo_req_t router_0_1_req_out [4:0];
floo_rsp_t router_0_1_rsp_in [4:0];

    assign router_0_1_req_in[0] = '0;
    assign router_0_1_req_in[1] = router_1_1_to_router_0_1_req;
    assign router_0_1_req_in[2] = router_0_0_to_router_0_1_req;
    assign router_0_1_req_in[3] = hbm_ni_1_to_router_0_1_req;
    assign router_0_1_req_in[4] = cluster_ni_0_1_to_router_0_1_req;

    assign router_0_1_to_router_1_1_rsp = router_0_1_rsp_out[1];
    assign router_0_1_to_router_0_0_rsp = router_0_1_rsp_out[2];
    assign router_0_1_to_hbm_ni_1_rsp = router_0_1_rsp_out[3];
    assign router_0_1_to_cluster_ni_0_1_rsp = router_0_1_rsp_out[4];

    assign router_0_1_to_router_1_1_req = router_0_1_req_out[1];
    assign router_0_1_to_router_0_0_req = router_0_1_req_out[2];
    assign router_0_1_to_hbm_ni_1_req = router_0_1_req_out[3];
    assign router_0_1_to_cluster_ni_0_1_req = router_0_1_req_out[4];

    assign router_0_1_rsp_in[0] = '0;
    assign router_0_1_rsp_in[1] = router_1_1_to_router_0_1_rsp;
    assign router_0_1_rsp_in[2] = router_0_0_to_router_0_1_rsp;
    assign router_0_1_rsp_in[3] = hbm_ni_1_to_router_0_1_rsp;
    assign router_0_1_rsp_in[4] = cluster_ni_0_1_to_router_0_1_rsp;

  localparam id_t ROUTER_0_1_ID = '{x: 1, y: 1, port_id: 0};

floo_axi_router #(
  .AxiCfg(AxiCfg),
  .RouteAlgo (XYRouting),
  .NumRoutes (5),
  .NumInputs (5),
  .NumOutputs (5),
  .InFifoDepth (2),
  .OutFifoDepth (2),
  .id_t(id_t),
  .hdr_t(hdr_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) router_0_1 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i (ROUTER_0_1_ID),
  .id_route_map_i ('0),
  .floo_req_i (router_0_1_req_in),
  .floo_rsp_o (router_0_1_rsp_out),
  .floo_req_o (router_0_1_req_out),
  .floo_rsp_i (router_0_1_rsp_in)
);


floo_req_t router_1_0_req_in [4:0];
floo_rsp_t router_1_0_rsp_out [4:0];
floo_req_t router_1_0_req_out [4:0];
floo_rsp_t router_1_0_rsp_in [4:0];

    assign router_1_0_req_in[0] = router_1_1_to_router_1_0_req;
    assign router_1_0_req_in[1] = '0;
    assign router_1_0_req_in[2] = '0;
    assign router_1_0_req_in[3] = router_0_0_to_router_1_0_req;
    assign router_1_0_req_in[4] = cluster_ni_1_0_to_router_1_0_req;

    assign router_1_0_to_router_1_1_rsp = router_1_0_rsp_out[0];
    assign router_1_0_to_router_0_0_rsp = router_1_0_rsp_out[3];
    assign router_1_0_to_cluster_ni_1_0_rsp = router_1_0_rsp_out[4];

    assign router_1_0_to_router_1_1_req = router_1_0_req_out[0];
    assign router_1_0_to_router_0_0_req = router_1_0_req_out[3];
    assign router_1_0_to_cluster_ni_1_0_req = router_1_0_req_out[4];

    assign router_1_0_rsp_in[0] = router_1_1_to_router_1_0_rsp;
    assign router_1_0_rsp_in[1] = '0;
    assign router_1_0_rsp_in[2] = '0;
    assign router_1_0_rsp_in[3] = router_0_0_to_router_1_0_rsp;
    assign router_1_0_rsp_in[4] = cluster_ni_1_0_to_router_1_0_rsp;

  localparam id_t ROUTER_1_0_ID = '{x: 2, y: 0, port_id: 0};

floo_axi_router #(
  .AxiCfg(AxiCfg),
  .RouteAlgo (XYRouting),
  .NumRoutes (5),
  .NumInputs (5),
  .NumOutputs (5),
  .InFifoDepth (2),
  .OutFifoDepth (2),
  .id_t(id_t),
  .hdr_t(hdr_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) router_1_0 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i (ROUTER_1_0_ID),
  .id_route_map_i ('0),
  .floo_req_i (router_1_0_req_in),
  .floo_rsp_o (router_1_0_rsp_out),
  .floo_req_o (router_1_0_req_out),
  .floo_rsp_i (router_1_0_rsp_in)
);


floo_req_t router_1_1_req_in [4:0];
floo_rsp_t router_1_1_rsp_out [4:0];
floo_req_t router_1_1_req_out [4:0];
floo_rsp_t router_1_1_rsp_in [4:0];

    assign router_1_1_req_in[0] = '0;
    assign router_1_1_req_in[1] = '0;
    assign router_1_1_req_in[2] = router_1_0_to_router_1_1_req;
    assign router_1_1_req_in[3] = router_0_1_to_router_1_1_req;
    assign router_1_1_req_in[4] = cluster_ni_1_1_to_router_1_1_req;

    assign router_1_1_to_router_1_0_rsp = router_1_1_rsp_out[2];
    assign router_1_1_to_router_0_1_rsp = router_1_1_rsp_out[3];
    assign router_1_1_to_cluster_ni_1_1_rsp = router_1_1_rsp_out[4];

    assign router_1_1_to_router_1_0_req = router_1_1_req_out[2];
    assign router_1_1_to_router_0_1_req = router_1_1_req_out[3];
    assign router_1_1_to_cluster_ni_1_1_req = router_1_1_req_out[4];

    assign router_1_1_rsp_in[0] = '0;
    assign router_1_1_rsp_in[1] = '0;
    assign router_1_1_rsp_in[2] = router_1_0_to_router_1_1_rsp;
    assign router_1_1_rsp_in[3] = router_0_1_to_router_1_1_rsp;
    assign router_1_1_rsp_in[4] = cluster_ni_1_1_to_router_1_1_rsp;

  localparam id_t ROUTER_1_1_ID = '{x: 2, y: 1, port_id: 0};

floo_axi_router #(
  .AxiCfg(AxiCfg),
  .RouteAlgo (XYRouting),
  .NumRoutes (5),
  .NumInputs (5),
  .NumOutputs (5),
  .InFifoDepth (2),
  .OutFifoDepth (2),
  .id_t(id_t),
  .hdr_t(hdr_t),
  .floo_req_t(floo_req_t),
  .floo_rsp_t(floo_rsp_t)
) router_1_1 (
  .clk_i,
  .rst_ni,
  .test_enable_i,
  .id_i (ROUTER_1_1_ID),
  .id_route_map_i ('0),
  .floo_req_i (router_1_1_req_in),
  .floo_rsp_o (router_1_1_rsp_out),
  .floo_req_o (router_1_1_req_out),
  .floo_rsp_i (router_1_1_rsp_in)
);



endmodule
