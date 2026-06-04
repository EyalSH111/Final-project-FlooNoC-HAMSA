// Time-stamp: <2014-03-26 1346 naftalyb>
//-----------------------------------------------------------------------------
// Title         : <title> 
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : cbus_err_cnt.v
// Author        : Ran Nachum
// Created       : 
// Last modified : <moddate>
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c) <copydate> by <company> This model is the confidential and
//       |          |                |
//-------------------------------------------------------------------------------------------------

module  cbus_err_cnt  (/*AUTOARG*/
   // Outputs
   cbus_access_err, dummy_cbus_rresp, dummy_cbus_waccept,
   // Inputs
   cbus_clk, cbus_rst_n, cbus_m_req, bcfg_cbus_timeout_val,
   bcfg_cbus_err_cnt_en
   );


   input         cbus_clk;
   input 	 cbus_rst_n;
   input 	 cbus_m_req;
   
   
   input [31:0]  bcfg_cbus_timeout_val;
   input 	 bcfg_cbus_err_cnt_en;
	 
   output 	 cbus_access_err;
   
   output 	 dummy_cbus_rresp;
   output 	 dummy_cbus_waccept;
   
   /*AUTOINPUT*/
   
   /*AUTOOUTPUT*/
    
   /*AUTOWIRE*/

   
   wire 	 bcfg_cbus_err_cnt_en_sync2;
   
   crg_sync2 I_pre_grst_n_ind_sync2
     (
      // Outputs
      .q				(bcfg_cbus_err_cnt_en_sync2),
      // Inputs
      .clk				(cbus_clk),
      .d				(bcfg_cbus_err_cnt_en));
   
   
   reg [31:0] 	 cbus_timeout_cnt;   
   always @ (posedge cbus_clk  or negedge cbus_rst_n) 
     begin
	if (!cbus_rst_n)
	  begin
	     cbus_timeout_cnt[31:0] <= 8'h0;
	  end
	else
	  begin
	     if (cbus_m_req)
	       begin
		  cbus_timeout_cnt[31:0] <= (cbus_timeout_cnt[31:0] < bcfg_cbus_timeout_val[31:0]) ? cbus_timeout_cnt[31:0] +1 : cbus_timeout_cnt[31:0];
		  
	       end
	     else
	       begin
		  cbus_timeout_cnt[31:0] <= 8'h0;
	       end
	  end // else: !if(!cbus_rst_n)
     end // always @ (posedge cbus_clk  or negedge cbus_rst_n)

   
   reg 			 cbus_access_err_t;
   reg 			 cbus_access_err_d1;
   reg 			 cbus_access_err_d2;
   reg 			 cbus_access_err_d3;
   reg 			 cbus_access_err_d4;
   reg 			 cbus_access_err_d5;

   reg   		 cbus_access_err;

   
   always @ (posedge cbus_clk  or negedge cbus_rst_n) 
     begin
	if (!cbus_rst_n)
	  begin
	     cbus_access_err_t     <= 1'h0;
             cbus_access_err       <= 1'b0;
	  end
	else
	  begin  
   	     cbus_access_err       <= bcfg_cbus_err_cnt_en_sync2 & (cbus_access_err_t | cbus_access_err_d1 | cbus_access_err_d2 | cbus_access_err_d3 | cbus_access_err_d4 | cbus_access_err_d5);
	     cbus_access_err_t     <= (cbus_timeout_cnt[31:0] == bcfg_cbus_timeout_val[31:0]);
	     cbus_access_err_d1    <= cbus_access_err_t;
	     cbus_access_err_d2    <= cbus_access_err_d1;
	     cbus_access_err_d3    <= cbus_access_err_d2;
	     cbus_access_err_d4    <= cbus_access_err_d3;
	     cbus_access_err_d5    <= cbus_access_err_d4;	     
	  end
     end // always @ (posedge cbus_clk  or negedge cbus_rst_n)
   
   
   reg 		 dummy_cbus_rresp;
   reg 		 dummy_cbus_waccept;   
   always @ (posedge cbus_clk  or negedge cbus_rst_n) 
     begin
	if (!cbus_rst_n)
	  begin
	     dummy_cbus_rresp      <= 1'h0;
	     dummy_cbus_waccept    <= 1'h0;
	  end
	else
	  begin	     
	     if(cbus_access_err)
	       begin
		  dummy_cbus_rresp      <= bcfg_cbus_err_cnt_en_sync2;
		  dummy_cbus_waccept    <= bcfg_cbus_err_cnt_en_sync2;
	       end
	     else
	       begin
		  dummy_cbus_rresp      <= 1'h0;
		  dummy_cbus_waccept    <= 1'h0;
	       end
	  end // else: !if(!cbus_rst_n)
     end // always @ (posedge cbus_clk  or negedge cbus_rst_n)
   
   
endmodule // cbus_err_cnt


// Local Variables:
// verilog-library-directories:("." "../hdl/")
// End:

