// Time-stamp: <2010-07-07 1334 ronen>
//-----------------------------------------------------------------------------
// Title         : fram_2p.v
// Project   :<project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : Ronen Daly
// Created       : 10-03-2010
// Last modified : 10-03-2010
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
//-----------------------------------------------------------

module fram_sp
  (
   rd_data,
   addr,
   wr_data,
   wr_en,
   ram_en,
   clk
   );
  
   
   // ************************************************************ 
   // Parameters
   // ************************************************************
   
   parameter MEM_SIZE  = 1024;
   parameter AW = 10;
   parameter FPGA_DW = 8;
   
   // ************************************************************
   // I/O Declaration
   // ************************************************************
   
   output [FPGA_DW-1:0] rd_data;
   input [AW-1:0]  addr;
   input [FPGA_DW-1:0]  wr_data;
   input                  wr_en;
   input                  ram_en;
   input                  clk;
   
   // ************************************************************
   // Internal registers and wirings
   // ************************************************************
   wire [FPGA_DW-1:0]   rd_data;
   wire                   we;
   wire                   re;
   
   reg [AW-1:0]    addr_reg;
   reg [FPGA_DW-1:0]    mem_core_array[0:MEM_SIZE-1]; // synthesis syn_ramstyle = "block_ram"


   // ************************************************************ 
   // implement the RAM
   // ************************************************************   
   assign                 we =  wr_en & ram_en;
   assign                 re = ~wr_en & ram_en;


   always @(posedge clk)
     begin
        if (we)
          mem_core_array[addr] <= wr_data;
     end
   
   always @(posedge clk)
     begin
        if (re | we)
          addr_reg <= #1 addr;
     end
   
   assign rd_data = mem_core_array[addr_reg];
   

endmodule // fram_sp
