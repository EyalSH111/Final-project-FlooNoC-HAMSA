// Time-stamp: <2010-05-30 1730 ronen>
//-----------------------------------------------------------------------------
// Title         : mux2to1.v
// Project   :<project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : Ronen Daly
// Created       : 30-05-2010
// Last modified : 30-05-2010
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

module mux2to1 (/*AUTOARG*/
   // Outputs
   y,
   // Inputs
   s, a1, a0
   );


   /*********************  DEFINE  *********************/

   /*******************  PARAMETERS  *******************/

   parameter DW = 16;

   /******************  PHY GENERIC PARAMETERS  ********************/
  // Constellation Coding
   localparam           QPSK = 4'd2;
   localparam           QAM8 = 4'd3;
   localparam           QAM16 = 4'd4;
   localparam           QAM32 = 4'd5;
   localparam           QAM64 = 4'd6;
   localparam           QAM128 = 4'd7;
   localparam           QAM256 = 4'd8;
   localparam           QAM512 = 4'd9;
   localparam           QAM1024 = 4'd10;
   localparam           QAM2048 = 4'd11;
   // Symbol Type
   localparam SYMBOL_TYPE_DATA      = 3'd0;
   localparam SYMBOL_TYPE_PA        = 3'd1;
   localparam SYMBOL_TYPE_PILOT     = 3'd2;
   localparam SYMBOL_TYPE_SPILOT    = 3'd3;
   localparam SYMBOL_TYPE_MSG       = 3'd4;
   localparam SYMBOL_TYPE_PA_PILOT  = 3'd5;
   localparam SYMBOL_TYPE_NOT_VALID = 3'd6;
   localparam SYMBOL_TYPE_RESERVED  = 3'd7;
   

   /*********************  INPUT   *********************/
   input      s;
   input [DW-1:0] a1;
   input [DW-1:0] a0;
  
   /*********************  OUTPUT  *********************/
   output [DW-1:0] y;
  
   /*********************  INOUT  *********************/
  
   /*********************** REGS    ********************/
  
   /*********************** COMB REGS    ********************/
   // reg stm ; // wired

   /*********************   WIRE   *********************/
  
   /*********************   AUTOSAFE    **********/
  

   /****************************************************
    **********
    **********             CODE
    **********
    ****************************************************/


   assign     y[DW-1:-0]  = s ? a1[DW-1:0] : a0[DW-1:0];
   
endmodule // <modulename>



