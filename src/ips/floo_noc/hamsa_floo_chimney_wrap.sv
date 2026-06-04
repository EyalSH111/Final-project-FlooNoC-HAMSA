// Thin wrapper so XRUN does not resolve chimney floo_req_o/floo_rsp_o to parent nets.

import floo_hamsa_pkg::*;
import floo_pkg::*;

module hamsa_floo_chimney_wrap #(
  parameter floo_pkg::axi_cfg_t       AxiCfg        = '0,
  parameter floo_pkg::chimney_cfg_t   ChimneyCfg    = '0,
  parameter floo_pkg::route_cfg_t     RouteCfg      = '0,
  parameter bit                       AtopSupport   = 1'b0,
  parameter int unsigned              MaxAtomicTxns = 0,
  parameter type                      id_t          = logic,
  parameter type                      hdr_t         = logic,
  parameter type                      axi_in_req_t  = logic,
  parameter type                      axi_in_rsp_t  = logic,
  parameter type                      axi_out_req_t = logic,
  parameter type                      axi_out_rsp_t = logic,
  parameter type                      floo_req_t    = logic,
  parameter type                      floo_rsp_t    = logic
) (
  input  logic         clk_i,
  input  logic         rst_ni,
  input  logic         test_enable_i,
  input  sram_cfg_t    sram_cfg_i,
  input  axi_in_req_t  axi_in_req_i,
  output axi_in_rsp_t  axi_in_rsp_o,
  output axi_out_req_t axi_out_req_o,
  input  axi_out_rsp_t axi_out_rsp_i,
  input  id_t          id_i,
  input  route_t [RouteCfg.NumRoutes-1:0] route_table_i,
  output floo_req_t    flit_req_out_o,
  output floo_rsp_t    flit_rsp_out_o,
  input  floo_req_t    flit_req_in_i,
  input  floo_rsp_t    flit_rsp_in_i
);

  floo_axi_chimney #(
    .AxiCfg        ( AxiCfg        ),
    .ChimneyCfg    ( ChimneyCfg    ),
    .RouteCfg      ( RouteCfg      ),
    .AtopSupport   ( AtopSupport   ),
    .MaxAtomicTxns ( MaxAtomicTxns ),
    .id_t          ( id_t          ),
    .hdr_t         ( hdr_t         ),
    .axi_in_req_t  ( axi_in_req_t  ),
    .axi_in_rsp_t  ( axi_in_rsp_t  ),
    .axi_out_req_t ( axi_out_req_t ),
    .axi_out_rsp_t ( axi_out_rsp_t ),
    .floo_req_t    ( floo_req_t    ),
    .floo_rsp_t    ( floo_rsp_t    )
  ) u_chimney (
    .clk_i         ( clk_i         ),
    .rst_ni        ( rst_ni        ),
    .test_enable_i ( test_enable_i ),
    .sram_cfg_i    ( sram_cfg_i    ),
    .axi_in_req_i  ( axi_in_req_i  ),
    .axi_in_rsp_o  ( axi_in_rsp_o  ),
    .axi_out_req_o ( axi_out_req_o ),
    .axi_out_rsp_i ( axi_out_rsp_i ),
    .id_i          ( id_i          ),
    .route_table_i ( route_table_i ),
    .floo_req_o    ( flit_req_out_o ),
    .floo_rsp_o    ( flit_rsp_out_o ),
    .floo_req_i    ( flit_req_in_i  ),
    .floo_rsp_i    ( flit_rsp_in_i  )
  );

endmodule
