//-----------------------------------------------------------------------------
// Title         : <title>
// Project       : <project>
//-----------------------------------------------------------------------------
// File          : CV*_top.v
// Author        : Ido Peled  <idop@jupiter>
// Created       : 09.08.2010
// Last modified : 09.08.2010
//-----------------------------------------------------------------------------
// Description : the top module contains a memory wrapper, of a single port memory, and an arrbiter, that gives priority to PHY blockes over CBUS I/F access
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
// 09.08.2010 : created
//-----------------------------------------------------------------------------

module SP_ARBITER_TOP_TEMPLATE
  (/*autoarg*/
   // Outputs
   cbus_waccept, cbus_rresp, cbus_rddata, rd_data,
   // Inputs
   clk, cbus_req, cbus_slv_cmd, cbus_slv_address, cbus_slv_wdata, addr, wr_data,
   wr_en, wr_mask, en, sreset_n, rm, rme, test1, scan_mode
   );
    
   localparam DW       = DW_TEMPLATE;
   localparam AW       = AW_TEMPLATE;

   parameter CBUS_AW = AW; 
   parameter MSB_DONT_CARE_WIDTH = 32-DW;
   
   input 	    clk;

   
   input 	    cbus_req;
   input 	    cbus_slv_cmd;
   input [CBUS_AW-1:0] cbus_slv_address;
   input [DW-1:0]      cbus_slv_wdata;
   output 	       cbus_waccept;
   output 	       cbus_rresp;
   output [31:0]       cbus_rddata;
   
   output [DW-1 :0]    rd_data;     // Data Output 
   
   input [AW-1:0]    addr;        // Address 
   input [DW-1:0]    wr_data;     // [I] [31:0]
   input 	     wr_en;       // [I] 1b
   input [DW-1:0]    wr_mask;     // [I] Write Mask
   input 	     en;      // [I] 1b
   input 	     sreset_n;
   input [4-1:0]     rm;      // [I] [3:0]
   input 	     rme;
   input 	     test1;
   // System
   input 	     scan_mode;   // [I] 1b Scan mode    
   
   reg 		     arbiter_rresp_d1;
   reg [DW-1:0]      rddatap;
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [AW-1:0]	arbiter_addr;		// From sp_arbiter_i0 of sp_arbiter.v
   wire			arbiter_en;		// From sp_arbiter_i0 of sp_arbiter.v
   wire [DW-1:0]	arbiter_wr_data;	// From sp_arbiter_i0 of sp_arbiter.v
   wire			arbiter_wr_en;		// From sp_arbiter_i0 of sp_arbiter.v
   wire [DW-1:0]	arbiter_wr_mask;	// From sp_arbiter_i0 of sp_arbiter.v
   wire 		arbiter_rresp;     	// From sp_arbiter_i0 of sp_arbiter.v
   // End of automatics

   /*sp_arbiter AUTO_TEMPLATE (
    .addr_out			(arbiter_addr[AW-1:0]),
    .wr_data_out		(arbiter_wr_data[DW-1:0]),
    .wr_en_out			(arbiter_wr_en),
    .wr_mask_out		(arbiter_wr_mask[DW-1:0]),
    .en_out			(arbiter_en),
    .cbus_rresp			(arbiter_rresp),
    .cbus_cmd			(cbus_slv_cmd),
    .cbus_addr			(cbus_slv_address[CBUS_AW-1:0]), 
    .cbus_wrdata		(cbus_slv_wdata[DW-1:0]),
    .phy_addr			(addr[AW-1:0]),
    .phy_wr_data		(wr_data[DW-1:0]),
    .phy_wr_en			(wr_en),
    .phy_wr_mask		(wr_mask[DW-1:0]),
    .phy_en			(en),
    ); */
   
   sp_arbiter #(.DW(DW),.AW(AW)) sp_arbiter_i0
     (/*autoinst*/
      // Outputs
      .addr_out				(arbiter_addr[AW-1:0]),	 // Templated
      .wr_data_out			(arbiter_wr_data[DW-1:0]), // Templated
      .wr_en_out			(arbiter_wr_en),	 // Templated
      .wr_mask_out			(arbiter_wr_mask[DW-1:0]), // Templated
      .en_out				(arbiter_en),		 // Templated
      .cbus_waccept			(cbus_waccept),
      .cbus_rresp			(arbiter_rresp), // Templated
      // Inputs
      .cbus_req				(cbus_req),
      .cbus_cmd				(cbus_slv_cmd), // Templated
      .cbus_addr			(cbus_slv_address[CBUS_AW-1:0]), // Templated
      .cbus_wrdata			(cbus_slv_wdata[DW-1:0]), // Templated
      .phy_addr				(addr[AW-1:0]),		 // Templated
      .phy_wr_data			(wr_data[DW-1:0]),	 // Templated
      .phy_wr_en			(wr_en),		 // Templated
      .phy_wr_mask			(wr_mask[DW-1:0]),	 // Templated
      .phy_en				(en));			 // Templated

   
   /*SP_WRAPPER_TEMPLATE AUTO_TEMPLATE (
    .addr			(arbiter_addr[AW-1:0]),
    .wr_data			(arbiter_wr_data[DW-1:0]),
    .wr_en			(arbiter_wr_en),
    .wr_mask			(arbiter_wr_mask[DW-1:0]),
    .en				(arbiter_en),
    ); */
   
   SP_WRAPPER_TEMPLATE SP_WRAPPER_TEMPLATE_i0
     (/*autoinst*/
      // Outputs
      .rd_data				(rd_data[DW-1:0]),
      // Inputs
      .addr				(arbiter_addr[AW-1:0]),	 // Templated
      .wr_data				(arbiter_wr_data[DW-1:0]), // Templated
      .wr_en				(arbiter_wr_en),	 // Templated
      .wr_mask				(arbiter_wr_mask[DW-1:0]), // Templated
      .en				(arbiter_en),		 // Templated
      .clk				(clk),
      .sreset_n				(sreset_n),
      .rm				(rm[4-1:0]),
      .rme				(rme),
      .test1				(test1),
      .scan_mode			(scan_mode));

   always @(posedge clk)
     if (~sreset_n)
       rddatap[DW-1:0] <= {DW{1'b0}};
     else
       rddatap[DW-1:0] <= cbus_rresp ? rd_data[DW-1:0] : rddatap[DW-1:0];

 //  always @(posedge clk)
 //    if (~sreset_n)
 //      arbiter_rresp_d1 <= 1'b0;
 //    else
 //      arbiter_rresp_d1 <= arbiter_rresp;


    // burst and Back to back support
   
   always @(posedge clk)
     if (~sreset_n)
       arbiter_rresp_d1 <= 1'b0;
     else
       arbiter_rresp_d1 <= arbiter_rresp & ~arbiter_rresp_d1;  
   
   generate
       if (MSB_DONT_CARE_WIDTH > 0) begin : extend_rdata
	  assign cbus_rddata[31:0] = {{MSB_DONT_CARE_WIDTH{1'b0}},rddatap[DW-1:0]};
       end
       else begin : assign_rdata
	  assign cbus_rddata[31:0] = rddatap[DW-1:0];
       end
   endgenerate
	  
   assign cbus_rresp = arbiter_rresp_d1 & cbus_req;
   
endmodule // SP_ARBITER_TOP_TEMPLATE

