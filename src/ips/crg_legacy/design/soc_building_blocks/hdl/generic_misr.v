// Time-stamp: <2011-10-23 1325 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Parameterized MISR function
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : generic_misr.v
// Author        : Naftaly Blum
// Created       : 21.09.2011
// Last modified : 21.09.2011
//-----------------------------------------------------------------------------
// Description :
// Important: 2 <= MISR_DW <= 32
//      MISR_DW <= MISR_LFSR_DW <= 32
//-----------------------------------------------------------------------------
// Copyright (c) 2011 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD.
//------------------------------------------------------------------------------
// Modification history :
// 21.09.2011 : created
//------------------------------------------------------------------------------
module generic_misr (/*AUTOARG*/
   // Outputs
   misr_out,
   // Inputs
   func_clk, func_rst_n, lfsr_load, lfsr_start, lfsr_seed, misr_in
   ) ;

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter MISR_LFSR_DW = 8;
   parameter MISR_DW = 8;
   
   //----------------------------------------------------------------------------
   // Clock/reset
   //----------------------------------------------------------------------------
   input                      func_clk;
   input                      func_rst_n;
   //----------------------------------------------------------------------------
   // LFSR Control
   //----------------------------------------------------------------------------
   input                      lfsr_load;
   input                      lfsr_start;
   input [MISR_LFSR_DW-1:0]   lfsr_seed;
   input [MISR_DW-1:0]        misr_in;
   output [MISR_LFSR_DW-1:0]  misr_out;
   
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   /*autowire*/
   integer                    i;
   wire [31:0]                i_taps_array[2:32];
   wire [31:0]                i_taps_entry;
   wire [MISR_LFSR_DW-1:0]    i_taps;
   wire [MISR_LFSR_DW-1:0]    i_misr_in_padded;
   reg [MISR_LFSR_DW-1:0]     lfsr_sreg;
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   
   //----------------------------------------------------------------------------
   // Minimum number of taps that will yield maximal length sequences for 
   // LFSRs ranging from 2 to 32 bits.
   //----------------------------------------------------------------------------
   assign i_taps_array[2]  = 32'b00000000000000000000000000000011;
   assign i_taps_array[3]  = 32'b00000000000000000000000000000101;
   assign i_taps_array[4]  = 32'b00000000000000000000000000001001;
   assign i_taps_array[5]  = 32'b00000000000000000000000000010010;
   assign i_taps_array[6]  = 32'b00000000000000000000000000100001;
   assign i_taps_array[7]  = 32'b00000000000000000000000001000001;
   assign i_taps_array[8]  = 32'b00000000000000000000000010001110;
   assign i_taps_array[9]  = 32'b00000000000000000000000100001000;
   assign i_taps_array[10] = 32'b00000000000000000000001000000100;
   assign i_taps_array[11] = 32'b00000000000000000000010000000010;
   assign i_taps_array[12] = 32'b00000000000000000000100000101001;
   assign i_taps_array[13] = 32'b00000000000000000001000000001101;
   assign i_taps_array[14] = 32'b00000000000000000010000000010101;
   assign i_taps_array[15] = 32'b00000000000000000100000000000001;
   assign i_taps_array[16] = 32'b00000000000000001000000000010110;
   assign i_taps_array[17] = 32'b00000000000000010000000000000100;
   assign i_taps_array[18] = 32'b00000000000000100000000001000000;
   assign i_taps_array[19] = 32'b00000000000001000000000000010011;
   assign i_taps_array[20] = 32'b00000000000010000000000000000100;
   assign i_taps_array[21] = 32'b00000000000100000000000000000010;
   assign i_taps_array[22] = 32'b00000000001000000000000000000001;
   assign i_taps_array[23] = 32'b00000000010000000000000000010000;
   assign i_taps_array[24] = 32'b00000000100000000000000000001101;
   assign i_taps_array[25] = 32'b00000001000000000000000000000100;
   assign i_taps_array[26] = 32'b00000010000000000000000000100011;
   assign i_taps_array[27] = 32'b00000100000000000000000000010011;
   assign i_taps_array[28] = 32'b00001000000000000000000000000100;
   assign i_taps_array[29] = 32'b00010000000000000000000000000010;
   assign i_taps_array[30] = 32'b00100000000000000000000000101001;
   assign i_taps_array[31] = 32'b01000000000000000000000000000100;
   assign i_taps_array[32] = 32'b10000000000000000000000001100010;

   assign i_taps_entry     = i_taps_array[MISR_LFSR_DW];
   assign i_taps           = i_taps_entry[MISR_LFSR_DW-1:0];
   assign i_misr_in_padded = {{(MISR_LFSR_DW-MISR_DW){1'b0}}, misr_in};
   
   assign misr_out         = lfsr_sreg;

   /*autotieoff*/
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   //---------------------------------------------------------------------------------
   // Linear Feedback Shift Register 
   //---------------------------------------------------------------------------------
   always @ (posedge func_clk)
     begin
        if (!func_rst_n)
	  begin
               lfsr_sreg <= {MISR_LFSR_DW{1'b1}};
	  end // if (!func_rst_n)
	else
	  begin
               // Defaults
               if (lfsr_load == 1'b1)
                 begin
                      lfsr_sreg <= lfsr_seed;
                 end
               else if (lfsr_start == 1'b1)
                 begin
                      lfsr_sreg[0] <= lfsr_sreg[MISR_LFSR_DW-1] ^ i_misr_in_padded[0];
                      for (i = MISR_LFSR_DW-1 ; i >= 1 ; i = i-1)
                        begin
                             if (i_taps[i-1] == 1'b1)
                               begin
                                    lfsr_sreg[i] <= lfsr_sreg[i-1] ^ i_misr_in_padded[i] ^ lfsr_sreg[MISR_LFSR_DW-1];
                               end
                             else
                               begin
                                    lfsr_sreg[i] <= lfsr_sreg[i-1] ^ i_misr_in_padded[i];
                               end
                        end
                 end
               else
                 begin
                      lfsr_sreg[MISR_LFSR_DW-1:0] <= lfsr_sreg[MISR_LFSR_DW-1:0];
                 end
	  end // else: !if(!func_rst_n)
     end // always @ (posedge func_clk or negedge func_rst_n)

endmodule // generic_misr

// Local Variables:
// verilog-library-directories:("." "../hdl/" "$JUPITER_DIR/common/general/dw_cells")
// End:
