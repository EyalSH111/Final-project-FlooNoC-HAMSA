// Time-stamp: <2010-10-20 1734 ronen>
//-----------------------------------------------------------------------------
// Title         : phy_gclk.v
// Project   :<project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : Ronen Daly
// Created       : 07-07-2010
// Last modified : 07-07-2010
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c)  by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
//-----------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
// Rev.  | Date:    | Revised By:    | Description:
//=================================================================================================
// 1.0   | <moddate>| <author>       | 1. global disable for Green Mode: controlled from the SOC "gclk_global_en"
//       |          |                |    All gclk will have the same Phase.
//       |          |                | 2. used as divided clock by clk_ratio [] 
//       |          |                |    clk_ratio = 0,1,2,3 & gclk_en is tied to 0 and DIV_CLK parameter is eq to 1
//       |          |                | 3. used as function  mode DIV_CLK paramter is 0 and gclk_en is valid
//       |          |                | 4. gclk cnt clear reset the gclk counters for synchronize all gclk blocks in the PHY
//       |          |                | 
//       |          |                | 
//-------------------------------------------------------------------------------------------------

module phy_gclk (/*AUTOARG*/
   // Outputs
   gclk, gclk_pre,
   // Inputs
   sys_clk, clk_en, hw_reset_n, cg_sel, gclk_global_en, clk_ratio,
   gclk_cnt_clear, div_clk_en, dft_clk_en, scan_enable
   );


   /*********************  DEFINE  *********************/

   /*******************  PARAMETERS  *******************/
   parameter DW = 3;
   
   localparam     GCLK_EN = 2'b00;
   localparam     GCLK_BP = 2'b01;
   localparam     GCLK_DIS = 2'b10;

   /******************  PHY GENERIC PARAMETERS  ********************/
 
   
   /*********************  INPUT   *********************/

   input          clk_en;
   input          hw_reset_n;
   input    [1:0] cg_sel;
   input          gclk_global_en;
   input [DW-1:0] clk_ratio;
   input          gclk_cnt_clear;
   input          div_clk_en;
   input          dft_clk_en;
   input          scan_enable;
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input                sys_clk;                // To gclk_inst of crg_clk_clockgate_cust.v
   // End of automatics


   /*********************  OUTPUT  *********************/
   output         gclk_pre;
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output               gclk;                   // From gclk_inst of crg_clk_clockgate_cust.v
   // End of automatics

   /*********************  INOUT  *********************/
   /*AUTOINOUT*/

   /*********************** REGS    ********************/
   /*AUTOREGINPUT*/
   /*AUTOREG*/

   reg [DW -1:0]  clk_cnt;

   /*********************** COMB REGS    ********************/
   // reg stm ; // wired

   /*********************   WIRE   *********************/

   wire [1:0]     gclk_cg_sel;
   wire           gclk_en;
   wire           dft_gclk_en;
   /*AUTOWIRE*/
   
   /*********************   AUTOSAFE    **********/
 
   /****************************************************
    **********
    **********             CODE
    **********
    ****************************************************/
   // Global enable used for global shut down
   assign         gclk_cg_sel[1:0] = gclk_global_en ? cg_sel[1:0] : GCLK_DIS;

   always @(posedge sys_clk or negedge hw_reset_n)
     if (~hw_reset_n)
       clk_cnt <= {DW{1'h0}};
     else if (gclk_global_en)
       clk_cnt <= gclk_cnt_clear         ? {DW{1'h0}} :
                  (clk_cnt == clk_ratio) ? {DW{1'h0}} : 
                  clk_cnt + 1'b1;
          else
            clk_cnt <= {DW{1'h0}};
               
   
   assign               gclk_en  = div_clk_en ? ~(|clk_cnt) : clk_en;             
   assign               gclk_pre = gclk_en;
   // OPen gclk for synchronous reset distribution
   assign               dft_gclk_en = scan_enable | dft_clk_en | ~hw_reset_n;
   
   
   /* crg_clk_clockgate_cust AUTO_TEMPLATE (
    .clk               (sys_clk),
    .out_clk           (gclk),
    .cg_sel            (gclk_cg_sel[1:0]),
    .clk_en            (gclk_en),
    .scan_enable       (dft_gclk_en),
    );*/
   
   crg_clk_clockgate_cust
     gclk_inst (/*AUTOINST*/
                // Outputs
                .out_clk                (gclk),                  // Templated
                // Inputs
                .clk                    (sys_clk),               // Templated
                .scan_enable            (dft_gclk_en),           // Templated
                .cg_sel                 (gclk_cg_sel[1:0]),      // Templated
                .clk_en                 (gclk_en));               // Templated
   
   
endmodule // <modulename>



