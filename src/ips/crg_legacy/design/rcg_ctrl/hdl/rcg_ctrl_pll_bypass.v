// Time-stamp: <2013-05-13 1205 naftalyb>
//-----------------------------------------------------------------------------
// Title         : RCG PLL bypass
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_pll_bypass.v
// Author        :   <naftalyb@NAFTALYB-LT6410>
// Created       : 8.05.2013
// Last modified : 8.05.2013
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2013 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 8.05.2013 : created
//------------------------------------------------------------------------------

module rcg_ctrl_pll_bypass(/*AUTOARG*/
   // Outputs
   pll_clk_out,
   // Inputs
   pll_clk_in, ref_clk, hgrst_n, scan_mode, pll_bypass_pad,
   pll_bypass_r, pll_bypass_src_r
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------

   //----------------------------------------------------------------------------
   // Input clock from PLL.
   //----------------------------------------------------------------------------
   input                 pll_clk_in;
   //----------------------------------------------------------------------------
   // Reference input clock.
   //----------------------------------------------------------------------------
   input                 ref_clk;
   //----------------------------------------------------------------------------
   // PLL-clock/Ref-clock multiplexed signal towards the RCG block.
   //----------------------------------------------------------------------------
   output                pll_clk_out;
   //----------------------------------------------------------------------------
   // Power-on/External reset signal.
   //----------------------------------------------------------------------------
   input                 hgrst_n;
   //----------------------------------------------------------------------------
   // Scan-mode signal.
   //----------------------------------------------------------------------------
   input                 scan_mode;
   //----------------------------------------------------------------------------
   // PLL bypass control signals.
   //----------------------------------------------------------------------------
   input                 pll_bypass_pad;
   input                 pll_bypass_r;
   input                 pll_bypass_src_r;

   //----------------------------------------------------------------------------
   // Signals Definitions.
   //----------------------------------------------------------------------------
   wire                  pll_bypass;
   wire                  pll_clk_out;
   
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   
   /*autotieoff*/
   
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   crg_clk_mx2 I_pll_bypass_src
     (
      // Outputs
      .y				(pll_bypass),
      // Inputs
      .a				(pll_bypass_pad),
      .b				(pll_bypass_r),
      .s				(pll_bypass_src_r & ~scan_mode));
   
   crg_glitch_free_mux I_pll_bypass_mux
     (
      // Outputs
      .clk_out				(pll_clk_out),
      // Inputs
      .clk_a				(pll_clk_in),
      .clk_b				(ref_clk),
      .rst_n                            (hgrst_n),
      .sel				(pll_bypass));
   

endmodule // rcg_ctrl_pll_bypass

// Local Variables:
// verilog-library-directories:("." "../../")
// End: