//-----------------------------------------------------------------------------
// Title         : <title>
// Project       : <project>
//-----------------------------------------------------------------------------
// File          : mem_arbiter.v
// Author        : Ido Peled  <idop@jupiter>
// Created       : 08.08.2010
// Last modified : 08.08.2010
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
// 08.08.2010 : created
//-----------------------------------------------------------------------------

module sp_arbiter
  (/*autoarg*/
   // Outputs
   addr_out, wr_data_out, wr_en_out, wr_mask_out, en_out,
   cbus_waccept, cbus_rresp,
   // Inputs
   cbus_req, cbus_cmd, cbus_addr, cbus_wrdata, phy_addr, phy_wr_data,
   phy_wr_en, phy_wr_mask, phy_en
   );

   parameter DW = 32 ;
   parameter AW = 32 ;
   
   
   output [AW-1:0] addr_out;        // Address 
   output [DW-1:0] wr_data_out;     // [I] [31:0]
   output 	   wr_en_out;       // [I] 1b
   output [DW-1:0] wr_mask_out;     // [I] Write Mask   
   output 	   en_out;      // [I] 1b       
   
   input 	   cbus_req;
   input 	   cbus_cmd;
   input [AW-1:0]  cbus_addr;
   input [DW-1:0]  cbus_wrdata;
   output 	   cbus_waccept;
   output 	   cbus_rresp;
   
   input [AW-1:0]  phy_addr;        // Address 
   input [DW-1:0]  phy_wr_data;     // [I] [31:0]
   input 	   phy_wr_en;       // [I] 1b
   input [DW-1:0]  phy_wr_mask;     // [I] Write Mask
   input 	   phy_en;      // [I] 1b
   
   wire [AW-1:0]   addr_out;        // Address 
   wire [DW-1:0]   wr_data_out;     // [I] [31:0]
   wire 	   wr_en_out;       // [I] 1b
   wire [DW-1:0]   wr_mask_out;     // [I] Write Mask   
   wire 	   en_out; 
   wire 	   cbus_waccept;
   wire 	   cbus_rresp;
   
   wire 	   cbus_wr_req;
   wire 	   cbus_rd_req;
   
   
   assign 	   cbus_wr_req = cbus_req & ~cbus_cmd;
   assign 	   cbus_rd_req = cbus_req & cbus_cmd;
   
   assign 	   addr_out[AW-1:0] = phy_en ? phy_addr[AW-1:0] : cbus_addr[AW-1:0];
   assign 	   wr_data_out[DW-1:0] = phy_en ? phy_wr_data[DW-1:0] : cbus_wrdata[DW-1:0];
   assign 	   wr_en_out = phy_en ? phy_wr_en : cbus_wr_req;
   assign 	   wr_mask_out[DW-1:0] = phy_en ? phy_wr_mask[DW-1:0] : {DW{1'b1}};
   assign 	   en_out = phy_en | cbus_req;
   
   assign 	   cbus_waccept = ~phy_en & cbus_wr_req;
   assign 	   cbus_rresp = ~phy_en & cbus_rd_req;
   
endmodule // sp_arbiter


