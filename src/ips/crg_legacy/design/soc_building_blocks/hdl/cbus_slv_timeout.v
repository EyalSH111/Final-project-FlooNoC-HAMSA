// User: ronen 
// Date: 24_08_2011-Time 16_14_27
// Version:/main/4
// Description:
// 		 strech the cbus error_pulse signal to 32 phy clocks 
// 		 for SOC slow clock domain 
////// 
// Time-stamp: <2011-08-24 1611 ronen>
//-----------------------------------------------------------------------------
// Title         : <title> 
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : cbus_slv_timeout.v
// Author        : Ido Peled
// Created       : 
// Last modified : <moddate>
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c) <copydate> by <company> This model is the confidential and
//       |          |                |
//-------------------------------------------------------------------------------------------------

module  cbus_slv_timeout  (/*AUTOARG*/
   // Outputs
   cbus_access_err, cbus_rresp, cbus_waccept,
   // Inputs
   clk, sreset_n, cbus_m_req, cbus_m_cmd, cbus_slv_rresp,
   cbus_slv_waccept, timeout_en, timeout_val
   );

   parameter COUNTER_DW = 32;

   input         clk;
   input 	 sreset_n;
   input 	 cbus_m_req;
   input 	 cbus_m_cmd;
   input 	 cbus_slv_rresp;
   input 	 cbus_slv_waccept;
   
   input 	 timeout_en;
   input [COUNTER_DW-1:0] timeout_val;
	 
   output 	 cbus_access_err;
   
   output 	 cbus_rresp;
   output 	 cbus_waccept;
   
   /*AUTOINPUT*/
   
   ///*AUTOOUTPUT*/
    
   /*AUTOWIRE*/

   wire 		rd_req;
   wire 		wr_req;
   wire 		counter_en;
   wire 		counter_clr;
   wire [COUNTER_DW-1:0] timeout_cnt;
   wire 		 cbus_rresp;
   wire 		 cbus_waccept;
   wire 		 next_cbus_access_err;
   reg 			 cbus_access_err;
   reg [4:0]             cbus_error_cnt;
   
   assign 	 rd_req = cbus_m_req & cbus_m_cmd;
   assign 	 wr_req  = cbus_m_req & ~cbus_m_cmd;
   assign 	 counter_en = timeout_en & ((rd_req & ~cbus_slv_rresp) | (wr_req & ~cbus_slv_waccept) | counter_clr);
   assign 	 counter_clr = cbus_rresp | cbus_waccept;
 
  
   /* counter AUTO_TEMPLATE (
    .count_value		(timeout_cnt[COUNTER_DW-1:0]),
    .clken			(counter_en),
    .clear			(counter_clr),
    .clear_value		({COUNTER_DW{1'b0}}),
    .step			({{(COUNTER_DW-1){1'b0}},1'b1}),
    .cnt_type			(1'b1),    
    .enable_compare		(1'b1),
    .limit			({COUNTER_DW{1'b1}}));*/
   
   counter #(.WIDTH(COUNTER_DW))
     counter (/*AUTOINST*/
	      // Outputs
	      .count_value		(timeout_cnt[COUNTER_DW-1:0]), // Templated
	      // Inputs
	      .sreset_n			(sreset_n),
	      .clk			(clk),
	      .clken			(counter_en),		 // Templated
	      .clear			(counter_clr),		 // Templated
	      .clear_value		({COUNTER_DW{1'b0}}),	 // Templated
	      .step			({{(COUNTER_DW-1){1'b0}},1'b1}), // Templated
	      .cnt_type			(1'b1),			 // Templated
	      .enable_compare		(1'b1),			 // Templated
	      .limit			({COUNTER_DW{1'b1}}));	 // Templated
   
   assign next_cbus_access_err = timeout_en & ((timeout_cnt[COUNTER_DW-1:0] == timeout_val[COUNTER_DW-1:0]));
   assign cbus_rresp = rd_req & (cbus_slv_rresp | next_cbus_access_err);
   assign cbus_waccept = wr_req & (cbus_slv_waccept | next_cbus_access_err);

//   always @(posedge clk)
//     if (~sreset_n)
//       cbus_access_err <= 1'b0;
//     else
//       cbus_access_err <= next_cbus_access_err;

   // stretch the cbus_error pulse to 32 clock cycles
   // soc can sample the data (different clock domain)

    always @(posedge clk)
      if (~sreset_n)
        cbus_error_cnt <= 5'h0;
      else if (next_cbus_access_err)
        cbus_error_cnt <= 5'h1;
           else if (cbus_error_cnt != 5'h0)
             cbus_error_cnt <= cbus_error_cnt +1'b1;

   always @(posedge clk)
     if (~sreset_n)
       cbus_access_err <= 1'b0;
     else
       cbus_access_err <= cbus_error_cnt != 5'h0;  
   
endmodule 

