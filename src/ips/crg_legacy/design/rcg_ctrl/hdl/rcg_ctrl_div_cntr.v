// Time-stamp: <2015-09-07 1456 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Jupiter Global Clock Controller
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_div_cntr.v
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

module rcg_ctrl_div_cntr(/*AUTOARG*/
   // Outputs
   gclk_div_out, gclk_div_cg_en, gclk_div_en, div_clk_align, 
   // Inputs
   clk_in, grst_n, hgrst_n, div_ratio, div_aln_rst_n, divider_go_pls
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter DIV_WIDTH = 16;
   parameter DIV_TYPE  = "HALF_DC";
   parameter HALFDC_UP = 1;
   
   //----------------------------------------------------------------------------
   // Input clocks (functional high speed clok and scan clock)
   //----------------------------------------------------------------------------
   input                 clk_in;
   //----------------------------------------------------------------------------
   // Global resets from POR/GRST blocks
   //----------------------------------------------------------------------------
   input                 grst_n;
   input                 hgrst_n;
   //----------------------------------------------------------------------------
   // Divider ratio and alignment signals
   //----------------------------------------------------------------------------
   input [DIV_WIDTH-1:0] div_ratio;
   input                 div_aln_rst_n;
   input                 divider_go_pls;
   //----------------------------------------------------------------------------
   // Global clock outpus and status
   //----------------------------------------------------------------------------
   output                gclk_div_out;
   output                gclk_div_cg_en;
   output                div_clk_align;
   output                gclk_div_en;
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   reg [DIV_WIDTH-1:0]   count;
   wire                  div_clk_align;
   wire                  div_clk_align_compr;
   wire                  div_clk_align_pre;
   wire                  div_clk_align_compr_pre;
   wire                  gclk_div_out;
   wire                  gclk_div_cg_en;
   wire                  div_bypass;
 
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/
   
   // period counter. counts from 1..div_ratio (to save another substractor)
   always @(posedge clk_in or negedge grst_n)
     if (!grst_n)          count <=  {{DIV_WIDTH-1{1'b0}}, 1'b1};
     else if ((count == div_ratio) || divider_go_pls || !div_aln_rst_n)
       count <=  {{DIV_WIDTH-1{1'b0}}, 1'b1};
          else                 count <=  count + 1'b1;

   // clock divider is passed if division factor is 0 or 1
   assign               div_bypass = ((div_ratio == 0) | (div_ratio == 1));

   // output indication of this divider alignment towards other dividers
   assign               div_clk_align_compr = (count == div_ratio);
   assign               div_clk_align_compr_pre = (div_ratio == {{DIV_WIDTH-2{1'b0}},2'b10}) ? (count == div_ratio) : (count == div_ratio - {{DIV_WIDTH-2{1'b0}},2'b10});

   crg_clk_mx2 I_div_clk_align_pre_mux
     (
      // Outputs
      .y                                (div_clk_align_pre),
      // Inputs
      .a                                (div_clk_align_compr_pre),
      .b                                (1'b1),
      .s                                (div_bypass | ~grst_n));

   
   crg_clk_mx2 I_div_clk_align_mux
     (
      // Outputs
      .y                                (div_clk_align),
      // Inputs
      .a                                (div_clk_align_compr),
      .b                                (1'b1),
      .s                                (div_bypass | ~grst_n));

   generate
   if (DIV_TYPE == "HALF_DC" && HALFDC_UP == 1) begin : half_dc_divider_gen_60_40

   reg                   gclk_div_out_reg;
   wire                  mux_sel;    
   reg                   bp_mux_sel;    

   assign               gclk_div_cg_en = 1'b1;
        
   
   // divider clock output. duty cycle is half period rounded up.
   always @(posedge clk_in or negedge grst_n)
     if (!grst_n)                                gclk_div_out_reg = 1'b0; //noytzach: changed to blocking assignment
     else if (divider_go_pls || !div_aln_rst_n)  gclk_div_out_reg = 1'b0; //   "    : see Gotcha #29 in Sutherland's "Verilog and SystemVerilog Gotchas"
          else                                   gclk_div_out_reg = (count <= {1'b0, (div_ratio[DIV_WIDTH-1:1] + div_ratio[0])});
   
   // implementation og bypass mux
   assign               mux_sel = ( (~grst_n & div_aln_rst_n) | (div_bypass  & div_aln_rst_n));
  
`ifdef PALLADIUM          
   always @(posedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     bp_mux_sel <=  1'b0;
     else              bp_mux_sel <=  mux_sel;
`else 
   always @(negedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     bp_mux_sel <=  1'b0;
     else              bp_mux_sel <=  mux_sel;
`endif

   
   crg_clk_mx2 I_div_bypass_mux
     (
      // Outputs
      .y                                (gclk_div_out),
      // Inputs
      .a                                (gclk_div_out_reg),
      .b                                (clk_in),
      .s                                (bp_mux_sel));

   // Add optional div_en signal that marks the last phase before the rising edge
   reg                 gclk_div_en_reg;
        
   always @(posedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     gclk_div_en_reg <=  1'b0;
     else              gclk_div_en_reg <=  div_aln_rst_n & div_clk_align_pre;

   assign gclk_div_en = gclk_div_en_reg;
   
   end // block: half_dc_divider_gen_60_40

   else if (DIV_TYPE == "HALF_DC" && HALFDC_UP == 0) begin : half_dc_divider_gen_40_60

   reg                   gclk_div_out_reg;
   wire                  mux_sel;    
   reg                   bp_mux_sel;    

   assign               gclk_div_cg_en = 1'b1;
        
   
   // divider clock output. duty cycle is half period rounded up.
   always @(posedge clk_in or negedge grst_n)
     if (!grst_n)                                gclk_div_out_reg = 1'b0; //noytzach: changed to blocking assignment
     else if (divider_go_pls || !div_aln_rst_n)  gclk_div_out_reg = 1'b0; //   "    : see Gotcha #29 in Sutherland's "Verilog and SystemVerilog Gotchas"
          else                                   gclk_div_out_reg = (count <= {1'b0, (div_ratio[DIV_WIDTH-1:1])});
   
   // implementation og bypass mux
   assign               mux_sel = ( (~grst_n & div_aln_rst_n) | (div_bypass  & div_aln_rst_n));
  
`ifdef PALLADIUM          
   always @(posedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     bp_mux_sel <=  1'b0;
     else              bp_mux_sel <=  mux_sel;
`else 
   always @(negedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     bp_mux_sel <=  1'b0;
     else              bp_mux_sel <=  mux_sel;
`endif

   
   crg_clk_mx2 I_div_bypass_mux
     (
      // Outputs
      .y                                (gclk_div_out),
      // Inputs
      .a                                (gclk_div_out_reg),
      .b                                (clk_in),
      .s                                (bp_mux_sel));


   // Add optional div_en signal that marks the last phase before the rising edge
   reg                 gclk_div_en_reg;
        
   always @(posedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     gclk_div_en_reg <=  1'b0;
     else              gclk_div_en_reg <=  div_aln_rst_n & div_clk_align_pre;

   assign gclk_div_en = gclk_div_en_reg;


   
   end // block: half_dc_divider_gen_40_60
        
   else if (DIV_TYPE == "PULSE_DIV") begin : pulse_divider_gen

   reg                 gclk_div_cg_en_reg;
        
   always @(posedge clk_in or negedge hgrst_n)
     if (!hgrst_n)     gclk_div_cg_en_reg <=  1'b0;
     else              gclk_div_cg_en_reg <=  div_aln_rst_n & div_clk_align;

   assign gclk_div_out = 1'b0;

   assign gclk_div_en  = 1'b0;
        
   assign gclk_div_cg_en = gclk_div_cg_en_reg;

   end
   endgenerate
endmodule // rcg_ctrl_div_cntr

// Local Variables:
// verilog-library-directories:("." "../hdl/")
// End:
