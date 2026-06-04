// Time-stamp: <2011-04-14 1610 naftalyb>
//-----------------------------------------------------------------------------
// Title         : soc_adc_controller.v
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : soc_adc_controller.v
// Author        : Naftaly Blum
// Created       : 14-04-2011
// Last modified : 14-04-2011
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

module soc_adc_controller (/*AUTOARG*/
   // Outputs
   adc_start, adc_data_out, adc_strb_out,
   // Inputs
   sys_slow_cbus_clk, sys_slow_cbus_rst_n, aux_adc_ref_20mhz_clk,
   scan_mode, adc_data_in, adc_dvalid, adc_ready, adc_en
   );


   /*********************  DEFINE  *********************/

   /*******************  PARAMETERS  *******************/
   parameter DW = 10;

   /*********************  INPUT   *********************/
   // general I/F
   input sys_slow_cbus_clk;
   input sys_slow_cbus_rst_n;

   input aux_adc_ref_20mhz_clk;
   input scan_mode;
   
   input [DW-1:0]      adc_data_in;  // data from ADC
   input               adc_dvalid; 
   input               adc_ready;
   input               adc_en;
   
   /*AUTOINPUT*/

   /*********************  OUTPUT  *********************/
   output              adc_start;
   output reg [DW-1:0] adc_data_out;
   output reg          adc_strb_out;
   /*AUTOOUTPUT*/

   /*********************  INOUT  *********************/
   /*AUTOINOUT*/

   /*********************** CODE ************************/
   wire                adc_en_sync;
   wire                adc_start_pls;
   wire                sys_slow_cbus_rst_n_sync;

   // Sync bcfg request to aux-adc clock
   crg_sync2 I_aux2_strb_sync2
     (
      // Outputs
      .q        (adc_en_sync),
      // Inputs
      .d        (adc_en),
      .clk      (aux_adc_ref_20mhz_clk));

   // Sync cub_rst_n to aux_adc clock
   crg_reset_sync I_crg_reset_sync
     (
      .arst_n   (sys_slow_cbus_rst_n), 
      .clk      (aux_adc_ref_20mhz_clk), 
      .scan_mode(scan_mode), 
      .rst_out_n(sys_slow_cbus_rst_n_sync));

   assign adc_start = adc_ready & adc_start_pls;

   // bcfg adc_en rising edge detector
   pulse_h_h I_pulse_h_h_adc_start (
              // Outputs
              .out                      (adc_start_pls),
              // Inputs
              .in                       (adc_en_sync),
              .clk                      (aux_adc_ref_20mhz_clk),
              .sreset_n                 (sys_slow_cbus_rst_n_sync));

   // adc_dvalid rising egde detector
   pulse_h_h I_pulse_h_h_adc_strb (
              // Outputs
              .out                      (adc_strb),
              // Inputs
              .in                       (adc_dvalid),
              .clk                      (sys_slow_cbus_clk),
              .sreset_n                 (sys_slow_cbus_rst_n));
   
   always @(posedge sys_slow_cbus_clk) // sample adc_data_in after adc_dvalid rises
     if (~sys_slow_cbus_rst_n) 
       adc_data_out[DW-1:0] <= {DW{1'b0}};
     else
       begin
            if (adc_strb)
              begin
                   adc_data_out[DW-1:0] <= adc_data_in[DW-1:0];
                   adc_strb_out <= 1'b1;
              end
            else
              begin
                   adc_strb_out <= 1'b0;
              end // else: !if(adc_strb)
       end // else: !if(~sys_slow_cbus_rst_n)

endmodule // soc_adc_controller

// Local Variables:
// verilog-library-directories:("." "$JUPITER_DIR/common/general/dw_cells" "$DB_DIR/jupiter/common/general/hdl")
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h" ".sv" ".vams")
// End:



