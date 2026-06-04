// User: ronen 
// Date: 24_10_2011-Time 10_12_59
// Version:/main/15
// Description:
// 		 fixed for reading even addresses 
////// 
// User: ronen 
// Date: 14_09_2011-Time 20_02_03
// Version:/main/14
// Description:
// 		 support burst and back to back  
////// 
//-----------------------------------------------------------------------------
// Title         : cbus_width_converter
// Project       : jupiter
//-----------------------------------------------------------------------------
// File          : cbus_width_converter.v
// Author        : Ido Peled  <idop@jupiter>
// Created       : 05.08.2010
// Last modified : 05.08.2010
//-----------------------------------------------------------------------------
// Description : converts a double read/write transaction towards a memory, with data width greater than 32, to a single transaction
//<description>
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
// 05.08.2010 : created
//-----------------------------------------------------------------------------

module cbus_width_converter
  (/*autoarg*/
   // Outputs
   cbus_rddata, cbus_waccept, cbus_rresp, cbus_width_converter_req,
   cbus_width_converter_cmd, cbus_width_converter_addr,
   cbus_width_converter_wrdata,
   // Inputs
   clk, sreset_n, cbus_req, cbus_cmd, cbus_addr, cbus_wrdata,
   rd_data, arbiter_waccept, arbiter_rresp
   );
   
   parameter DW = 32;
   parameter AW = 32;
   
   parameter CBUS_AW = AW + 1;
   parameter MSB_DONT_CARE_WIDTH = 64-DW;

   
   input     clk;
   input     sreset_n;

   //CBUS I/F
   input cbus_req;
   input cbus_cmd;
   input [CBUS_AW-1:0] cbus_addr;
   input [31:0]        cbus_wrdata;
   
   output [31:0]       cbus_rddata;
   output 	       cbus_waccept;
   output 	       cbus_rresp;
   
   //MEM I/F
   input [DW-1:0]      rd_data;
   input 	       arbiter_waccept;
   input 	       arbiter_rresp;

  
   output 	       cbus_width_converter_req;
   output 	       cbus_width_converter_cmd;
   output [AW-1:0]     cbus_width_converter_addr;
   output [DW-1:0]     cbus_width_converter_wrdata;
   
    /*autoinput*/

    /*autooutput*/

   wire [31:0] 	       cbus_rddata;
   wire 	       cbus_waccept;
   wire 	       cbus_rresp;
   
   wire 	       cbus_width_converter_req;
   wire 	       cbus_width_converter_cmd;
   wire [AW-1:0]       cbus_width_converter_addr;
   wire [DW-1:0]       cbus_width_converter_wrdata;
   
   wire 	       wr_req;
   wire 	       rd_req;
   
   wire 	       cbus_width_converter_wr_req;
   wire 	       cbus_width_converter_rd_req;
   
   wire 	   first_phase;
   wire 	   second_phase;
   reg 		   first_phase_d1;
    
   /*autowire*/

   wire 	   update_wrdata_reg;
   
   reg [31:0] 	   wrdata_d1;
   reg [DW-1:0]    rd_datap;
   reg 		   arbiter_rresp_d1;

   wire [31:0] 	   extended_rd_datap;
   /*autoreg*/


   
   assign 	   wr_req = cbus_req & ~cbus_cmd;
   assign 	   rd_req = cbus_req & cbus_cmd;

 
//   assign 	   cbus_width_converter_rd_req = rd_req & first_phase ? cbus_req : 1'b0;

   assign 	   cbus_width_converter_rd_req = rd_req & first_phase & ~arbiter_rresp_d1;
   
   // shoudl be one clock read cycle

//      always @(posedge clk)
//        if (~sreset_n)
//          cbus_width_converter_rd_req <= 1'b0;
////        else if (arbiter_rresp)
//        else if (cbus_rresp | arbiter_rresp)
//          cbus_width_converter_rd_req <= 1'b0;
//             else
//               cbus_width_converter_rd_req <= rd_req & first_phase;   
   
   assign 	   cbus_width_converter_req = cbus_width_converter_wr_req | cbus_width_converter_rd_req;
   
   assign 	   cbus_width_converter_cmd = cbus_cmd;
   assign 	   cbus_rresp = rd_req ? 
				first_phase ? arbiter_rresp_d1 : 1'b1 : 
				1'b0;
   
      
   always @(posedge clk)
    if (~sreset_n)
      arbiter_rresp_d1 <= 1'b0;
    else
      arbiter_rresp_d1 <= arbiter_rresp;
   
   always @(posedge clk)
    if (~sreset_n)
      rd_datap[DW-1:0] <= {DW{1'b0}};
    else
      rd_datap[DW-1:0] <= arbiter_rresp_d1 ? rd_data[DW-1:0] : rd_datap[DW-1:0];
   
   always @(posedge clk)
    if (~sreset_n)
      wrdata_d1[31:0] <= 32'h0;
    else
      wrdata_d1[31:0] <= update_wrdata_reg ? cbus_wrdata[31:0] : wrdata_d1[31:0];
   

    generate
       if ((DW > 64) & (MSB_DONT_CARE_WIDTH == 0)) begin : full_96_width
	  assign extended_rd_datap[31:0] = rd_datap[DW-1:64];
       end
    endgenerate
   generate
      if ((DW > 64) & (MSB_DONT_CARE_WIDTH > 0)) begin  : not_full_96_width
	 assign extended_rd_datap[31:0] = {{MSB_DONT_CARE_WIDTH{1'b0}},rd_datap[DW-1:64]};
      end
   endgenerate
   generate
      if ((DW <= 64) & (MSB_DONT_CARE_WIDTH == 0)) begin : full_64_width
	 assign extended_rd_datap[31:0] = rd_datap[DW-1:32];
      end
   endgenerate
   generate
      if ((DW <= 64) & (MSB_DONT_CARE_WIDTH > 0)) begin  : not_full_64_width
	 assign extended_rd_datap[31:0] = {{MSB_DONT_CARE_WIDTH{1'b0}},rd_datap[DW-1:32]};
      end
   endgenerate
   
   generate
      if (DW > 64) begin : wider_than_64
	 
	 reg [31:0]  wrdata_d2;
	 wire third_phase;
	 reg  second_phase_d1;
	
	 always @(posedge clk)
	   if (~sreset_n)
	     wrdata_d2[31:0] <= 32'h0;
	   else
	     wrdata_d2[31:0] <= update_wrdata_reg ? wrdata_d1[31:0] : wrdata_d2[31:0];
	 
	 assign first_phase = cbus_addr[1:0] == 2'b00;
	 assign second_phase = cbus_addr[1:0] == 2'b01;
	 assign third_phase = cbus_addr[1:0] == 2'b10;
	 always @(posedge clk)
	   if (~sreset_n)
	     first_phase_d1 <= 1'b0;
	   else
	     first_phase_d1 <= first_phase;
	 always @(posedge clk)
	   if (~sreset_n)
	     second_phase_d1 <= 1'b0;
	   else
	     second_phase_d1 <= second_phase;
	 
	 assign cbus_width_converter_wr_req = wr_req & third_phase;
	 assign cbus_width_converter_addr[AW-1:0] = cbus_addr[CBUS_AW-1:2];
	 assign cbus_width_converter_wrdata[DW-1:0] = {cbus_wrdata[DW-64-1:0],wrdata_d1[31:0],wrdata_d2[31:0]};
	 assign cbus_waccept = wr_req ? 
			       third_phase ? arbiter_waccept : 1'b1 :
			       1'b0;
	 assign cbus_rddata[31:0] = first_phase_d1 ? rd_datap[31:0] :
				    second_phase_d1 ? rd_datap[63:32] :
				    extended_rd_datap[31:0];
	 assign update_wrdata_reg = wr_req & (first_phase | second_phase);
      end
      
      else begin : wider_than_32
	 assign first_phase = ~cbus_addr[0];
	 assign second_phase = ~first_phase;
	 always @(posedge clk)
	   if (~sreset_n)
	     first_phase_d1 <= 1'b0;
	   else
	     first_phase_d1 <= first_phase;
	 assign cbus_width_converter_wr_req = wr_req & second_phase;
	 assign cbus_width_converter_addr[AW-1:0] = cbus_addr[CBUS_AW-1:1];
	 assign cbus_width_converter_wrdata[DW-1:0] = {cbus_wrdata[DW-32-1:0],wrdata_d1[31:0]};
	 assign cbus_waccept = wr_req ? 
		     	       first_phase ? 1'b1 : arbiter_waccept :
		     	       1'b0;	 
	 assign cbus_rddata[31:0] = first_phase_d1 ? rd_datap[31:0] : extended_rd_datap[31:0];
	 assign update_wrdata_reg = wr_req & first_phase;
      end
      
   endgenerate


 
   

endmodule // cbus_width_converter



   
   
   
   
