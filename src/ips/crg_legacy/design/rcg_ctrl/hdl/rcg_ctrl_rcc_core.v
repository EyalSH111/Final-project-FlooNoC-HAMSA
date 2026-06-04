// Time-stamp: <2014-03-26 2222 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Jupiter Global Clock Controller
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_core.v
// Author        :   <naftalyb@NAFTALYB-LT6410>
// Created       : 30.01.2013
// Last modified : 30.01.2013
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Copyright (c) 2013 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 30.01.2013 : created
//------------------------------------------------------------------------------

module rcg_ctrl_rcc_core(/*AUTOARG*/
   // Outputs
   rcg_ctrl_rcc_rf_state_out, mod_disable, mod_disable_req,
   mod_rst_out_n, clk_out, clk_out_div_en,
   // Inputs
   clk_in, clk_in_mux, gclk_div_cg_en, gclk_div_en, opcg_clk_cg_en,
   grst_n, hgrst_n, rcg_ctrl_rf_clk, rcg_ctrl_rcc_rf_stb,
   rcg_ctrl_rcc_rf_state_in, force_rcc_on, force_rcc_off,
   mod_cg_en_add_dly, mod_disable_ack, mod_force_enable,
   mod_hw_rst_req, mod_init_state, mod_grstn_cgen_dly, scan_clk,
   opcg_mode, scan_mode, scan_enable, scan_async_ctrl
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------

   //----------------------------------------------------------------------------
   // Input clocks (functional high speed clok and scan clock)
   //----------------------------------------------------------------------------
   input                      clk_in;
   input                      clk_in_mux;
   input                      gclk_div_cg_en;
   input                      gclk_div_en;
   input                      opcg_clk_cg_en;
   //----------------------------------------------------------------------------
   // Global resets from POR/GRST blocks
   //----------------------------------------------------------------------------
   input                      grst_n;
   input                      hgrst_n;
   //----------------------------------------------------------------------------
   // Registers file signals
   //----------------------------------------------------------------------------
   input                      rcg_ctrl_rf_clk;
   input                      rcg_ctrl_rcc_rf_stb;
   input [2:0]                rcg_ctrl_rcc_rf_state_in;
   output [5:0]               rcg_ctrl_rcc_rf_state_out;
   //----------------------------------------------------------------------------
   // Registers file signals
   //----------------------------------------------------------------------------
   input                      force_rcc_on;
   input                      force_rcc_off;
   input                      mod_cg_en_add_dly;
   input                      mod_disable_ack;
   input                      mod_force_enable;
   input                      mod_hw_rst_req;
   input [1:0]                mod_init_state;
   input [7:0]                mod_grstn_cgen_dly;
   output                     mod_disable;
   output                     mod_disable_req;
   output                     mod_rst_out_n;
   //----------------------------------------------------------------------------
   // DFT control signals
   //----------------------------------------------------------------------------
   input                      scan_clk;
   input                      opcg_mode;
   input                      scan_mode;
   input                      scan_enable;
   input                      scan_async_ctrl;

   //----------------------------------------------------------------------------
   // Global clock outpus and status
   //----------------------------------------------------------------------------
   output                     clk_out;
   output                     clk_out_div_en;

   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   wire                       clk_out;
   reg                        clk_out_div_en;
   //wire                       clk_out_div_en;
   wire                       mod_gclk_cg_en;
   wire                       gclk_func_clk_cg_en;
   wire                       gclk_func_clk_cg_out;
   wire                       clk_in_scan_mux_sel;

   /*autowire*/

   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   /*autoinput*/
   ////*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   /* rcg_ctrl_rcc AUTO_TEMPLATE
     (
      .mod_src_clk                      (clk_in_mux),
     );
   */
   rcg_ctrl_rcc I_rcg_ctrl_rcc
     (/*autoinst*/
      // Outputs
      .rcg_ctrl_rcc_rf_state_out        (rcg_ctrl_rcc_rf_state_out[5:0]),
      .mod_rst_out_n                    (mod_rst_out_n),
      .mod_gclk_cg_en                   (mod_gclk_cg_en),
      .mod_disable_req                  (mod_disable_req),
      .mod_disable                      (mod_disable),
      // Inputs
      .grst_n                           (grst_n),
      .hgrst_n                          (hgrst_n),
      .mod_hw_rst_req                   (mod_hw_rst_req),
      .clk_in                           (clk_in),
      .scan_mode                        (scan_mode),
      .scan_async_ctrl                  (scan_async_ctrl),
      .force_rcc_on                     (force_rcc_on),
      .force_rcc_off                    (force_rcc_off),
      .rcg_ctrl_rf_clk                  (rcg_ctrl_rf_clk),
      .rcg_ctrl_rcc_rf_stb              (rcg_ctrl_rcc_rf_stb),
      .rcg_ctrl_rcc_rf_state_in         (rcg_ctrl_rcc_rf_state_in[2:0]),
      .mod_src_clk                      (clk_in_mux),            // Templated
      .mod_disable_ack                  (mod_disable_ack),
      .mod_force_enable                 (mod_force_enable),
      .mod_init_state                   (mod_init_state[1:0]),
      .mod_cg_en_add_dly                (mod_cg_en_add_dly),
      .mod_grstn_cgen_dly               (mod_grstn_cgen_dly[7:0]));



   assign gclk_func_clk_cg_en = gclk_div_cg_en && mod_gclk_cg_en && ~scan_mode;

   crg_clk_clockgate I_rcg_ctrl_cg
     (
      // Outputs
      .out_clk                          (gclk_func_clk_cg_out),
      // Inputs
      .clk                              (clk_in_mux),
      .en                               (gclk_func_clk_cg_en || opcg_clk_cg_en),
      .ten                              (1'b0));

   assign clk_in_scan_mux_sel = scan_mode && (scan_enable || ~opcg_mode);

   crg_clk_mx2  I_clk_in_scan_mux
     (
      // Outputs
      .y                                (clk_out),
      // Inputs
      .a                                (gclk_func_clk_cg_out),
      .b                                (scan_clk),
      .s                                (clk_in_scan_mux_sel));

   wire clk_out_div_en_pre_s2;
   reg  clk_out_div_en_pre_s1;

   
   assign clk_out_div_en_pre_s2 = gclk_func_clk_cg_en && gclk_div_en;

   always @(posedge clk_in or negedge hgrst_n)
   if (!hgrst_n) begin 
      clk_out_div_en        <= 1'b0;
      clk_out_div_en_pre_s1 <= 1'b0;
   end else begin
      clk_out_div_en        <= clk_out_div_en_pre_s1;
      clk_out_div_en_pre_s1 <= clk_out_div_en_pre_s2;
   end
 

endmodule // rcg_ctrl_rcc_core
// Local Variables:
// verilog-library-directories:("." ".." "$NEGEV_IP/design/crgn/dw_sync/16nm/hdl" "$NEGEV_IP/design/crgn/dw_cells/16nm/hdl")
// verilog-auto-inst-param-value:t
// End:
