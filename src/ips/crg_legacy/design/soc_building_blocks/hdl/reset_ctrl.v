// User: ronen 
// Date: 06_11_2013-Time 09_14_56
// Version:/main/2
// Description:
// 		 add rcg reset to the main resets 
////// 
// Time-stamp: <2011-01-23 1649 udil>
//-----------------------------------------------------------------------------
// Title         : reset_ctrl.v
// Project   :<project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : Ronen Daly
// Created       : 27-06-2010
// Last modified : 27-06-2010
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
// 1.0   | <moddate>| <author>       |
//       |          |                |
//-------------------------------------------------------------------------------------------------

module reset_ctrl (/*AUTOARG*/
   // Outputs
   sreset_n,
   // Inputs
   scan_mode, hw_reset_n, sw_warm_n_rst_select, sw_reg_srst_n,
   warm_reg_srst_n, mctrl_sw_rst_n, mctrl_reset_cntrl,
   mctrl_sw_warm_n_rst_select, rcg_srst_n
   );


   /*********************  DEFINE  *********************/

   /*******************  PARAMETERS  *******************/
   parameter DW = 32;
   /******************  PHY GENERIC PARAMETERS  ********************/
 
   

   /*********************  INPUT   *********************/
   // general I/F
   input           scan_mode; // Scan Mode
   input           hw_reset_n; // hardware reset for DFT 
   input           sw_warm_n_rst_select; // Reset source selection 1 sw rest 0 warm reset 
   input [DW-1:0]  sw_reg_srst_n; // Sw reset for interbnal blocks
   input [DW-1:0]  warm_reg_srst_n;// War reset controlled from TOP
   input           mctrl_sw_rst_n; // Micro controller SW reset strobe
   input 	  mctrl_reset_cntrl;
   input 	  mctrl_sw_warm_n_rst_select;
   input [DW-1:0]  rcg_srst_n;  // RCG reset from the RCG unit False Path
   output [DW-1:0] sreset_n;
         

   /*AUTOINPUT*/


   /*********************  OUTPUT  *********************/
   /*AUTOOUTPUT*/

   /*********************  INOUT  *********************/
   /*AUTOINOUT*/

   /*********************** REGS    ********************/
   /*AUTOREGINPUT*/
   /*AUTOREG*/

   /*********************** COMB REGS    ********************/
   // reg stm ; // wired

   /*********************   WIRE   *********************/
   /*AUTOWIRE*/
   wire 	   sw_reset_select;
   
   /*********************   AUTOSAFE    **********/


   /****************************************************
    **********
    **********             CODE
    **********
    ****************************************************/

   assign 	   sw_reset_select = mctrl_reset_cntrl ? mctrl_sw_warm_n_rst_select : sw_warm_n_rst_select;
   
   assign          sreset_n[DW-1:0] = scan_mode ? {DW{hw_reset_n}} :
                                      sw_reset_select ? (sw_reg_srst_n[DW-1:0]   & {DW{mctrl_sw_rst_n}} & rcg_srst_n[DW-1:0]) : 
                                                        (warm_reg_srst_n[DW-1:0] & {DW{mctrl_sw_rst_n}} & rcg_srst_n[DW-1:0]) ;
 
   
endmodule // <modulename>



