// Time-stamp: <2015-08-16 1903 naftalyb>
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
// Copyright (c) 2011 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 30.01.2013 : created
//------------------------------------------------------------------------------

module rcg_ctrl_core(/*AUTOARG*/
   // Outputs
   rcg_ctrl_rcc_rf_state_out, mod_disable, mod_disable_req,
   mod_rst_out_n, divider_go_ack, div_clk_align, clk_out,
   clk_out_div_en,
   // Inputs
   clk_in, scan_clk, pre_grst_n_ind, grst_n, hgrst_n, rcg_ctrl_rf_clk,
   rcg_ctrl_rcc_rf_stb, rcg_ctrl_rcc_rf_state_in, force_rcc_on,
   force_rcc_off, mod_cg_en_add_dly, mod_disable_ack,
   mod_force_enable, mod_hw_rst_req, mod_init_state,
   mod_grstn_cgen_dly, scan_mode, scan_enable, opcg_mode,
   opcg_trigger, scan_async_ctrl, div_ratio, divider_go,
   div_clk_align_vec, udef_vec_en, udef_vec
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter DIV_NUM   = 4;
   parameter DIV_WIDTH = 16;
   parameter RCC_NUM = 1;
   parameter DIV_TYPE  = "HALF_DC";
   parameter HALFDC_UP = 1;
   parameter RCC_BYP_VEC = {RCC_NUM{1'b0}};
   
   //----------------------------------------------------------------------------
   // Input clocks (functional high speed clok and scan clock)
   //----------------------------------------------------------------------------
   input                 clk_in;
   input                 scan_clk;
   //----------------------------------------------------------------------------
   // Global resets from POR/GRST blocks
   //----------------------------------------------------------------------------
   input                 pre_grst_n_ind;
   input                 grst_n;
   input                 hgrst_n;
   //----------------------------------------------------------------------------
   // Registers file signals
   //----------------------------------------------------------------------------
   input                 rcg_ctrl_rf_clk;
   input [RCC_NUM-1:0]   rcg_ctrl_rcc_rf_stb;
   input [((3)*RCC_NUM-1):0] rcg_ctrl_rcc_rf_state_in;   
   output [((6)*RCC_NUM-1):0] rcg_ctrl_rcc_rf_state_out;
   //----------------------------------------------------------------------------
   // Registers file signals
   //----------------------------------------------------------------------------
   input [RCC_NUM-1:0]        force_rcc_on;
   input [RCC_NUM-1:0]        force_rcc_off;
   input [RCC_NUM-1:0]        mod_cg_en_add_dly;
   input [RCC_NUM-1:0]        mod_disable_ack;
   input [RCC_NUM-1:0]        mod_force_enable;
   input [RCC_NUM-1:0]        mod_hw_rst_req;
   input [((2)*RCC_NUM-1):0]  mod_init_state;
   input [((8)*RCC_NUM-1):0]  mod_grstn_cgen_dly;
   output [RCC_NUM-1:0]       mod_disable;
   output [RCC_NUM-1:0]       mod_disable_req;
   output [RCC_NUM-1:0]       mod_rst_out_n;
   //----------------------------------------------------------------------------
   // DFT control signals
   //----------------------------------------------------------------------------
   input                 scan_mode;
   input                 scan_enable;
   input                 opcg_mode;
   input                 opcg_trigger;
   input                 scan_async_ctrl;
   //----------------------------------------------------------------------------
   // Divider ratio and alignment signals
   //----------------------------------------------------------------------------
   input [DIV_WIDTH-1:0] div_ratio;
   input                 divider_go;
   output                divider_go_ack;
   input [DIV_NUM-1:0]   div_clk_align_vec;
   output                div_clk_align;
   //----------------------------------------------------------------------------
   // Divider ratio from JTAG controlled user defined registers
   //----------------------------------------------------------------------------
   input                 udef_vec_en;
   input [DIV_WIDTH-1:0] udef_vec;
   //----------------------------------------------------------------------------
   // Global clock outpus and status
   //----------------------------------------------------------------------------
   output [RCC_NUM-1:0]  clk_out;
   output [RCC_NUM-1:0]  clk_out_div_en;   

   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   wire                  clk_in;        
   wire [RCC_NUM-1:0]    clk_out;
   wire [RCC_NUM-1:0]    clk_out_div_en;   
   wire                  gclk_div_cg_en;
   wire                  gclk_div_en;
   wire                  opcg_clk_cg_en;
   wire                  gclk_div_out;
   wire                  clk_in_mux;
   wire [((6)*RCC_NUM-1):0] rcg_ctrl_rcc_rf_state_out;   
   wire [RCC_NUM-1:0]       mod_disable;
   wire [RCC_NUM-1:0]       mod_disable_req;
   wire [RCC_NUM-1:0]       mod_rst_out_n;
   
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   /*autoinput*/
   ////*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   generate

   if (DIV_TYPE == "HALF_DC") begin : half_dc_divider_gen
      assign clk_in_mux = gclk_div_out;
   end

   else if (DIV_TYPE == "PULSE_DIV") begin : pulse_divider_gen
      assign clk_in_mux = clk_in;
   end

   endgenerate

   /* rcg_ctrl_div_top AUTO_TEMPLATE 
     (
     );
   */
   rcg_ctrl_div #(.DIV_WIDTH(DIV_WIDTH), .DIV_NUM(DIV_NUM), .DIV_TYPE(DIV_TYPE), .HALFDC_UP(HALFDC_UP)) I_rcg_ctrl_div
     (/*autoinst*/
      // Outputs
      .divider_go_ack                   (divider_go_ack),
      .div_clk_align                    (div_clk_align),
      .gclk_div_cg_en                   (gclk_div_cg_en),
      .gclk_div_en                      (gclk_div_en),
      .gclk_div_out                     (gclk_div_out),
      // Inputs
      .clk_in                           (clk_in),
      .pre_grst_n_ind                   (pre_grst_n_ind),
      .grst_n                           (grst_n),
      .hgrst_n                          (hgrst_n),
      .div_ratio                        (div_ratio[DIV_WIDTH-1:0]),
      .divider_go                       (divider_go),
      .div_clk_align_vec                (div_clk_align_vec[DIV_NUM-1:0]),
      .udef_vec_en                      (udef_vec_en),
      .udef_vec                         (udef_vec[DIV_WIDTH-1:0]));

   /* rcg_ctrl_opcg AUTO_TEMPLATE 
     (
      .clk_in                          (clk_in_mux),
     );
   */
   rcg_ctrl_opcg I_rcg_ctrl_opcg
     (/*autoinst*/
      // Outputs
      .opcg_clk_cg_en                   (opcg_clk_cg_en),
      // Inputs
      .clk_in                           (clk_in_mux),            // Templated
      .grst_n                           (grst_n),
      .scan_mode                        (scan_mode),
      .scan_enable                      (scan_enable),
      .opcg_mode                        (opcg_mode),
      .opcg_trigger                     (opcg_trigger),
      .gclk_div_cg_en                   (gclk_div_cg_en));


  generate
  genvar                i;
  for (i=0; i<RCC_NUM ; i=i+1) begin : rcg_ctrl_rcc_core_gen
       if (RCC_BYP_VEC[i] == 1'b0) begin : regular_rcc
            rcg_ctrl_rcc_core I_rcg_ctrl_rcc_core
              (
               // Outputs
               .rcg_ctrl_rcc_rf_state_out        (rcg_ctrl_rcc_rf_state_out[(6*(i+1))-1:(6*i)]),
               .mod_disable                      (mod_disable[i]),
               .mod_disable_req                  (mod_disable_req[i]),
               .mod_rst_out_n                    (mod_rst_out_n[i]),
               .clk_out                          (clk_out[i]),
               .clk_out_div_en                   (clk_out_div_en[i]),
               // Inputs
               .clk_in                           (clk_in),
               .clk_in_mux                       (clk_in_mux),
               .scan_clk                         (scan_clk),
               .gclk_div_cg_en                   (gclk_div_cg_en),
               .gclk_div_en                      (gclk_div_en),      
               .opcg_clk_cg_en                   (opcg_clk_cg_en),
               .grst_n                           (grst_n),
               .hgrst_n                          (hgrst_n),
               .rcg_ctrl_rf_clk                  (rcg_ctrl_rf_clk),
               .rcg_ctrl_rcc_rf_stb              (rcg_ctrl_rcc_rf_stb[i]),
               .rcg_ctrl_rcc_rf_state_in         (rcg_ctrl_rcc_rf_state_in[(3*(i+1))-1:(3*i)]),
               .force_rcc_on                     (force_rcc_on[i]),
               .force_rcc_off                    (force_rcc_off[i]),
               .mod_cg_en_add_dly                (mod_cg_en_add_dly[i]),
               .mod_disable_ack                  (mod_disable_ack[i]),
               .mod_force_enable                 (mod_force_enable[i]),
               .mod_hw_rst_req                   (mod_hw_rst_req[i]),
               .mod_init_state                   (mod_init_state[(2*(i+1))-1:(2*i)]),
               .mod_grstn_cgen_dly               (mod_grstn_cgen_dly[(8*(i+1))-1:(8*i)]),
               .scan_mode                        (scan_mode),
               .scan_enable                      (scan_enable),
               .opcg_mode                        (opcg_mode),
               .scan_async_ctrl                  (scan_async_ctrl));
       end // block: normal_rcc
       else
         begin : bypassed_rcc // In "bypassed" RCC, the RF clock if fed from 
            rcg_ctrl_rcc_core I_rcg_ctrl_rcc_core
              (
               // Outputs
               .rcg_ctrl_rcc_rf_state_out        (rcg_ctrl_rcc_rf_state_out[(6*(i+1))-1:(6*i)]),
               .mod_disable                      (mod_disable[i]),
               .mod_disable_req                  (mod_disable_req[i]),
               .mod_rst_out_n                    (mod_rst_out_n[i]),
               .clk_out                          (clk_out[i]),
               .clk_out_div_en                   (clk_out_div_en[i]),
               // Inputs
               .clk_in                           (clk_in),
               .clk_in_mux                       (clk_in_mux),
               .scan_clk                         (scan_clk),
               .gclk_div_cg_en                   (gclk_div_cg_en),
               .gclk_div_en                      (gclk_div_en),      
               .opcg_clk_cg_en                   (opcg_clk_cg_en),
               .grst_n                           (grst_n),
               .hgrst_n                          (hgrst_n),
               .rcg_ctrl_rf_clk                  (rcg_ctrl_rf_clk),
               .rcg_ctrl_rcc_rf_stb              (rcg_ctrl_rcc_rf_stb[i]),
               .rcg_ctrl_rcc_rf_state_in         (rcg_ctrl_rcc_rf_state_in[(3*(i+1))-1:(3*i)]),
               .force_rcc_on                     (1'b1),
               .force_rcc_off                    (force_rcc_off[i]),
               .mod_cg_en_add_dly                (mod_cg_en_add_dly[i]),
               .mod_disable_ack                  (mod_disable_ack[i]),
               .mod_force_enable                 (mod_force_enable[i]),
               .mod_hw_rst_req                   (mod_hw_rst_req[i]),
               .mod_init_state                   (mod_init_state[(2*(i+1))-1:(2*i)]),
               .mod_grstn_cgen_dly               (mod_grstn_cgen_dly[(8*(i+1))-1:(8*i)]),
               .scan_mode                        (scan_mode),
               .scan_enable                      (scan_enable),
               .opcg_mode                        (opcg_mode),
               .scan_async_ctrl                  (scan_async_ctrl));
         end // block: bypassed_rcc
  end // block: rcg_ctrl_rcc_core_gen
  endgenerate
   
endmodule // rcg_ctrl_core

// Local Variables:
// verilog-library-directories:("." "../../")
// End:
