//-----------------------------------------------------------------------------
// Title         : <title>
// Project       : <project>
//-----------------------------------------------------------------------------
// File          : CV*_top.v
// Author        : Ido Peled  <idop@jupiter>
// Created       : 09.08.2010
// Last modified : 09.08.2010
//-----------------------------------------------------------------------------
// Description : the top module contains a memory wrapper, of a 2 port memory, and an arrbiter, that gives priority to PHY blockes over CBUS I/F access
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
// 09.08.2010 : created
//-----------------------------------------------------------------------------

module TP_ARBITER_TOP_TEMPLATE
  (/*autoarg*/
   // Outputs
   cbus_waccept, cbus_rresp, cbus_rddata, rd_data,
   // Inputs
   cbus_req, cbus_slv_cmd, cbus_slv_address, cbus_slv_wdata, wr_addr, wr_data,
   wr_mask, wr_me_en, wr_clk, rd_addr, rd_me_en, rd_clk, scan_mode,
   sreset_n, rm, rme, test1_rd, wme, test1_wr
   );
    
   localparam DW       = DW_TEMPLATE;
   localparam AW       = AW_TEMPLATE;

   parameter CBUS_AW = AW; 
   parameter MSB_DONT_CARE_WIDTH = 32-DW;
   
   
   input 	    cbus_req;
   input 	    cbus_slv_cmd;
   input [CBUS_AW-1:0] cbus_slv_address;
   input [DW-1:0]      cbus_slv_wdata;
   output 	       cbus_waccept;
   output 	       cbus_rresp;
   output [31:0]       cbus_rddata;
   
   output [DW-1 :0]    rd_data;     // Data Output 
   
     // Wr Ports
   input [AW-1:0] wr_addr;    // [I] [AW-1:0] Write Address
   input [DW-1:0] wr_data;    // [I] [DW-1:0] Write Data
   input [DW-1:0] wr_mask;    // [I] [DW-1:0] write Data mask
   input          wr_me_en;   // [I] 1b Write Memory Enable
   input          wr_clk;     // [I] 1b Write Clk
   // Rd Ports
   input [AW-1:0]  rd_addr;    // [I] [AW-1:0] Read Address
   input           rd_me_en;   // [I] 1b Read Memory Enable
   input           rd_clk;     // [I] 1b Read Clk
   // System
   input           scan_mode;   // [I] 1b Scan mode
   input           sreset_n;
   // Debug
   input [3:0]     rm;      // [I] 4b Read margin [3:0]
   input           rme;     // [I] 1b Read Margin enable
   input           test1_rd;// [I] 1b Ram Test Mode
   input           wme;     // [I] 1b Write Margin Enable
   input           test1_wr; // [I] 1b Ram Test Mode

   reg 		     cbus_rresp_d1;
   reg [DW-1:0]      rddatap;
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [AW-1:0]	arbiter_rd_addr;	// From tp_arbiter_i0 of tp_arbiter.v
   wire			arbiter_rd_me_en;	// From tp_arbiter_i0 of tp_arbiter.v
   wire [AW-1:0]	arbiter_wr_addr;	// From tp_arbiter_i0 of tp_arbiter.v
   wire [DW-1:0]	arbiter_wr_data;	// From tp_arbiter_i0 of tp_arbiter.v
   wire [DW-1:0]	arbiter_wr_mask;	// From tp_arbiter_i0 of tp_arbiter.v
   wire			arbiter_wr_me_en;	// From tp_arbiter_i0 of tp_arbiter.v
   // End of automatics

   /*tp_arbiter AUTO_TEMPLATE (
    .wr_addr_out			(arbiter_wr_addr[AW-1:0]),
    .wr_data_out			(arbiter_wr_data[DW-1:0]),
    .wr_me_en_out			(arbiter_wr_me_en),
    .wr_mask_out			(arbiter_wr_mask[DW-1:0]),
    .rd_addr_out			(arbiter_rd_addr[AW-1:0]),
    .rd_me_en_out			(arbiter_rd_me_en),
    .cbus_cmd				(cbus_slv_cmd),
    .cbus_addr		        	(cbus_slv_address[AW-1:0]),
    .cbus_wrdata			(cbus_slv_wdata[DW-1:0]),
    .phy_wr_addr			(wr_addr[AW-1:0]),
    .phy_wr_data			(wr_data[DW-1:0]),
    .phy_wr_me_en			(wr_me_en),
    .phy_wr_mask			(wr_mask[DW-1:0]),
    .phy_rd_addr			(rd_addr[AW-1:0]),
    .phy_rd_me_en			(rd_me_en),
    ); */
   
   tp_arbiter #(.DW(DW),.AW(AW)) tp_arbiter_i0
     (/*autoinst*/
      // Outputs
      .wr_addr_out			(arbiter_wr_addr[AW-1:0]), // Templated
      .wr_data_out			(arbiter_wr_data[DW-1:0]), // Templated
      .wr_me_en_out			(arbiter_wr_me_en),	 // Templated
      .wr_mask_out			(arbiter_wr_mask[DW-1:0]), // Templated
      .rd_addr_out			(arbiter_rd_addr[AW-1:0]), // Templated
      .rd_me_en_out			(arbiter_rd_me_en),	 // Templated
      .cbus_waccept			(cbus_waccept),
      .cbus_rresp			(cbus_rresp),
      // Inputs
      .cbus_req				(cbus_req),
      .cbus_cmd				(cbus_slv_cmd),// Templated
      .cbus_addr			(cbus_slv_address[AW-1:0]), // Templated
      .cbus_wrdata			(cbus_slv_wdata[DW-1:0]), // Templated
      .phy_wr_addr			(wr_addr[AW-1:0]),	 // Templated
      .phy_wr_data			(wr_data[DW-1:0]),	 // Templated
      .phy_wr_me_en			(wr_me_en),		 // Templated
      .phy_wr_mask			(wr_mask[DW-1:0]),	 // Templated
      .phy_rd_addr			(rd_addr[AW-1:0]),	 // Templated
      .phy_rd_me_en			(rd_me_en));		 // Templated

   
   /*TP_WRAPPER_TEMPLATE AUTO_TEMPLATE (
    .wr_addr				(arbiter_wr_addr[AW-1:0]),
    .wr_data				(arbiter_wr_data[DW-1:0]),
    .wr_mask				(arbiter_wr_mask[DW-1:0]),
    .wr_me_en				(arbiter_wr_me_en),
    .rd_addr				(arbiter_rd_addr[AW-1:0]),
    .rd_me_en				(arbiter_rd_me_en),
    ); */
   
   TP_WRAPPER_TEMPLATE TP_WRAPPER_TEMPLATE_i0
     (/*autoinst*/
      // Outputs
      .rd_data				(rd_data[DW-1:0]),
      // Inputs
      .wr_addr				(arbiter_wr_addr[AW-1:0]), // Templated
      .wr_data				(arbiter_wr_data[DW-1:0]), // Templated
      .wr_mask				(arbiter_wr_mask[DW-1:0]), // Templated
      .wr_me_en				(arbiter_wr_me_en),	 // Templated
      .wr_clk				(wr_clk),
      .rd_addr				(arbiter_rd_addr[AW-1:0]), // Templated
      .rd_me_en				(arbiter_rd_me_en),	 // Templated
      .rd_clk				(rd_clk),
      .scan_mode			(scan_mode),
      .sreset_n				(sreset_n),
      .rm				(rm[3:0]),
      .rme				(rme),
      .test1_rd				(test1_rd),
      .wme				(wme),
      .test1_wr				(test1_wr));

   always @(posedge rd_clk)
     if (~sreset_n)
       rddatap[DW-1:0] <= {DW{1'b0}};
     else
       rddatap[DW-1:0] <= cbus_rresp ? rd_data[DW-1:0] : rddatap[DW-1:0];

   always @(posedge clk)
     if (~sreset_n)
       cbus_rresp_d1 <= 1'b0;
     else
       cbus_rresp_d1 <= cbus_rresp;
   
   assign cbus_rddata[31:0] = cbus_rresp_d1 ? {{MSB_DONT_CARE_WIDTH{1'b0}},rddatap[DW-1:0]} : 32'h0;

endmodule // TP_ARBITER_TOP_TEMPLATE

