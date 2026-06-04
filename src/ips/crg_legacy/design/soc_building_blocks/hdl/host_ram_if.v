// Time-stamp: <2010-04-13 1713 ronen>
//-----------------------------------------------------------------------------
// Title         : host_ram_if.v
// Project   :<project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : Ronen Daly
// Created       : 13-04-2010
// Last modified : 13-04-2010
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


module host_ram_if
  (
   // host outputs
   hack,              //[o] host ack
   h_ram_data_val,    //[o] host ram data valid pulse
   // Ram outputs
   ram_data,          //[o] ram data (write)
   ram_add,           //[o] ram add
   ram_cen,           //[o] ram cen
   ram_wen,           //[o] ram wen
   // host inputs
   hadd,              //[i] host address
   hdata_in,          //[i] host data
   hwr,               //[i] host write
   hrd,               //[i] host read
   // block inputs
   block_add,         //[i] block add
   block_din,         //[i] block data in
   block_rd,          //[i] block read
   block_wr,          //[i] block write
   // general
   clk,               //[i] clk
   sreset_n           //[i] sync reset active low
   );
   
   // PARAMETERS
   parameter                       HD_W          = 7;
   parameter 			   HADD_W        = 6;
   
   parameter 			   RAM_DI_W      = HD_W;
   parameter 			   RAM_ADD_W     = HADD_W;
   parameter 			   BLOCK_ADD_W   = HADD_W;
   parameter 			   BLOCK_D_W     = RAM_DI_W;
   
   // I/O
   output 			   hack;
   output 			   h_ram_data_val;
   
   output [RAM_DI_W-1:0] 	   ram_data;
   output [RAM_ADD_W-1:0] 	   ram_add;
   output 			   ram_cen;
   output 			   ram_wen;
   
   input [HADD_W-1:0] 		   hadd;
   input [HD_W-1:0] 		   hdata_in;
   input 			   hwr;
   input 			   hrd;
   
   input [BLOCK_ADD_W-1:0] 	   block_add;
   input 			   block_rd;
   input 			   block_wr;
   input [RAM_DI_W-1:0] 	   block_din;
   
   input 			   clk;
   input 			   sreset_n;
   
   
   wire 			   host_access;
   wire 			   block_access;
   wire [RAM_DI_W-1:0] 		   ram_data;
   wire 			   ram_cen;
   wire 			   ram_wen;
   wire [RAM_ADD_W-1:0] 	   ram_add;
   wire 			   h_ram_data_val;
      
   reg 				   hwr_d;
   reg 				   hrd_d;
   reg 				   hrd_d2;
   reg 				   hack;
  
   // *********************************************************
   // Control RAM Management & host access
   // *********************************************************
   assign 			   host_access  = (hwr & ~hwr_d) | (hrd & ~hrd_d);
   assign 			   block_access = block_wr | block_rd;
   assign 			   ram_data     = block_wr ? block_din : hdata_in;
   assign 			   ram_cen      = block_access | host_access;
   assign 			   ram_wen      = block_wr ? 1'b1 : ( block_rd ? 1'b0 : hwr & ~hwr_d );
   assign 			   ram_add      = (host_access & ~block_access) ? hadd : block_add;
   
   
   always @(posedge clk)
     if (~sreset_n)
       begin
	    hwr_d  <= 1'b0;
	    hrd_d  <= 1'b0;
	    hrd_d2 <= 1'b0;
       end
     else
       begin
	    hwr_d  <= hwr_d ? hwr : hwr & ~block_access;
	    hrd_d  <= hrd_d ? hrd : hrd & ~block_access;
	    hrd_d2 <= hrd_d;
       end
   
   always @(posedge clk)
     if (~sreset_n)
       hack <= 1'b0;
     else
       hack <= ((hwr & ~hwr_d & ~block_access) | (hrd_d & ~hrd_d2)) & ~hack;
   
   assign h_ram_data_val = hrd_d & ~hrd_d2;
   
endmodule // host_ram_if


