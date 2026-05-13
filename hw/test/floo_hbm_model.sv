// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>

`include "axi/assign.svh"

/// A very simple model of the HBM memory controller with configurable delay
module floo_hbm_model #(
  parameter time         TA           = 1ns,
  parameter time         TT           = 9ns,
  parameter int unsigned Latency      = 100,
  parameter int unsigned NumChannels  = 1,
  parameter int unsigned AddrWidth    = 32,
  parameter int unsigned DataWidth    = 32,
  parameter int unsigned UserWidth    = 1,
  parameter int unsigned IdWidth      = 2,
  parameter type axi_req_t            = logic,
  parameter type axi_rsp_t            = logic,
  parameter type aw_chan_t            = logic,
  parameter type w_chan_t             = logic,
  parameter type b_chan_t             = logic,
  parameter type ar_chan_t            = logic,
  parameter type r_chan_t             = logic
) (
  input logic clk_i,
  input logic rst_ni,
  input axi_req_t [NumChannels-1:0] hbm_req_i,
  output axi_rsp_t [NumChannels-1:0] hbm_rsp_o
);

  // AXI multicut
  axi_req_t [NumChannels-1:0] hbm_req;
  axi_rsp_t [NumChannels-1:0] hbm_rsp;


  for (genvar i = 0; i < NumChannels; i++) begin : gen_channels
    axi_multicut #(
      .NoCuts     ( Latency/2 ),
      .aw_chan_t  ( aw_chan_t ),
      .w_chan_t   ( w_chan_t  ),
      .b_chan_t   ( b_chan_t  ),
      .ar_chan_t  ( ar_chan_t ),
      .r_chan_t   ( r_chan_t  ),
      .axi_req_t  ( axi_req_t ),
      .axi_resp_t ( axi_rsp_t )
    ) i_axi_multicut (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .mst_req_o (hbm_req[i]),
      .mst_resp_i(hbm_rsp[i]),
      .slv_req_i (hbm_req_i[i]),
      .slv_resp_o(hbm_rsp_o[i])
    );
  end

  logic [NumChannels-1:0] mon_w_valid;
  logic [NumChannels-1:0][AddrWidth-1:0] mon_w_addr;
  logic [NumChannels-1:0][DataWidth-1:0] mon_w_data;
  logic [NumChannels-1:0][IdWidth-1:0] mon_w_id;
  logic [NumChannels-1:0][UserWidth-1:0] mon_w_user;
  axi_pkg::len_t [NumChannels-1:0] mon_w_beat_count;
  logic [NumChannels-1:0] mon_w_last;
  logic [NumChannels-1:0] mon_r_valid;
  logic [NumChannels-1:0][AddrWidth-1:0] mon_r_addr;
  logic [NumChannels-1:0][DataWidth-1:0] mon_r_data;
  logic [NumChannels-1:0][IdWidth-1:0] mon_r_id;
  logic [NumChannels-1:0][UserWidth-1:0] mon_r_user;
  axi_pkg::len_t [NumChannels-1:0] mon_r_beat_count;
  logic [NumChannels-1:0] mon_r_last;

  // Deterministic memory backend, no randomize()/license dependency.
  axi_sim_mem #(
    .AddrWidth         ( AddrWidth   ),
    .DataWidth         ( DataWidth   ),
    .IdWidth           ( IdWidth     ),
    .UserWidth         ( UserWidth   ),
    .NumPorts          ( NumChannels ),
    .axi_req_t         ( axi_req_t   ),
    .axi_rsp_t         ( axi_rsp_t   ),
    .WarnUninitialized ( 1'b0        ),
    .UninitializedData ( "zeros"     ),
    .ApplDelay         ( TA          ),
    .AcqDelay          ( TT          )
  ) i_axi_sim_mem (
    .clk_i             ( clk_i             ),
    .rst_ni            ( rst_ni            ),
    .axi_req_i         ( hbm_req           ),
    .axi_rsp_o         ( hbm_rsp           ),
    .mon_w_valid_o     ( mon_w_valid       ),
    .mon_w_addr_o      ( mon_w_addr        ),
    .mon_w_data_o      ( mon_w_data        ),
    .mon_w_id_o        ( mon_w_id          ),
    .mon_w_user_o      ( mon_w_user        ),
    .mon_w_beat_count_o( mon_w_beat_count  ),
    .mon_w_last_o      ( mon_w_last        ),
    .mon_r_valid_o     ( mon_r_valid       ),
    .mon_r_addr_o      ( mon_r_addr        ),
    .mon_r_data_o      ( mon_r_data        ),
    .mon_r_id_o        ( mon_r_id          ),
    .mon_r_user_o      ( mon_r_user        ),
    .mon_r_beat_count_o( mon_r_beat_count  ),
    .mon_r_last_o      ( mon_r_last        )
  );

endmodule
