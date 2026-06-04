// User: udil 
// Date: 23_03_2011-Time 11_10_52
// Version:/main/1
// Description:
// 		 Added file element "phy_empty_zero.v". 
////// 
// Time-stamp: <2011-03-30 1557 udil>
//-----------------------------------------------------------------------------
// Title         : adc_controller.v
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : adc_controller.v
// Author        : Udi Lavie
// Created       : 16-08-2010
// Last modified : 16-08-2010
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

module adc_controller (/*AUTOARG*/
   // Outputs
   adc_start, adc_data_out, adc_strb,
   // Inputs
   clk, sreset_n, adc_data_in, adc_dvalid, adc_ready,
   adc_en
   );


   /*********************  DEFINE  *********************/

   /*******************  PARAMETERS  *******************/
   parameter DW = 10;

   /*********************  INPUT   *********************/
   // general I/F
   input clk;
   input sreset_n;

   input [DW-1:0]      adc_data_in;  // data from ADC
   input               adc_dvalid; 
   input               adc_ready;
   input               adc_en;
   
   /*AUTOINPUT*/

   /*********************  OUTPUT  *********************/
   output reg          adc_start;
   output reg [DW-1:0] adc_data_out;
   output              adc_strb;
   /*AUTOOUTPUT*/

   /*********************  INOUT  *********************/
   /*AUTOINOUT*/

   /*********************** CODE ************************/

   always @(posedge clk)  // the MSB bit of cnt_20_clks is used as the clock.
     if (~sreset_n)
       adc_start <= 1'b0;   
     else 
       adc_start <= adc_ready & adc_en; // level signal - we don't care if there's metastability 

   pulse_h_h
     pulse_h_h(
              // Outputs
              .out                      (adc_strb),
              // Inputs
              .in                       (adc_dvalid),
              .clk                      (clk),
              .sreset_n                 (sreset_n));
   
   always @(posedge clk) // sample adc_data_in after adc_dvalid rises
     if (~sreset_n) 
       adc_data_out[DW-1:0] <= {DW{1'b0}};
     else if (adc_strb)     
       adc_data_out[DW-1:0] <= adc_data_in[DW-1:0];
          
endmodule // adc_controller



