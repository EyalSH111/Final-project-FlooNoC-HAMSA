// Time-stamp: <2015-07-26 1249 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Jupiter Global Clock Controller
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_div.v
// Author        :   <naftalyb@NAFTALYB-LT6410>
// Created       : 30.01.2013
// Last modified : 30.01.2013
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2011 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 30.01.2013 : created
//------------------------------------------------------------------------------

module rcg_ctrl_div(/*AUTOARG*/
   // Outputs
   divider_go_ack, div_clk_align, gclk_div_cg_en, gclk_div_en, gclk_div_out,
   // Inputs
   clk_in, pre_grst_n_ind, grst_n, hgrst_n, div_ratio, divider_go,
   div_clk_align_vec, udef_vec_en, udef_vec
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter DIV_NUM   = 1;
   parameter DIV_WIDTH = 16;
   parameter DIV_TYPE  = "HALF_DC";
   parameter HALFDC_UP = 1;
   
   //----------------------------------------------------------------------------
   // Input clocks (functional high speed clok and scan clock)
   //----------------------------------------------------------------------------
   input                 clk_in;
   //----------------------------------------------------------------------------
   // Global resets from POR/GRST blocks
   //----------------------------------------------------------------------------
   input                 pre_grst_n_ind;
   input                 grst_n;
   input                 hgrst_n;
   //----------------------------------------------------------------------------
   // Divider ratio and alignment signals
   //----------------------------------------------------------------------------
   input [DIV_WIDTH-1:0] div_ratio;
   input                 divider_go;
   output                divider_go_ack;
   input [DIV_NUM-1:0]   div_clk_align_vec;
   output                div_clk_align;
   //----------------------------------------------------------------------------
   // Divider ratio from JTAG controlled user defined registers
   //----------------------------------------------------------------------------
   input                 udef_vec_en;
   input [DIV_WIDTH-1:0] udef_vec;
   //----------------------------------------------------------------------------
   // Global clock outpus and status
   //----------------------------------------------------------------------------
   output                gclk_div_cg_en;
   output                gclk_div_en;
   output                gclk_div_out;
   
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   wire                  clks_are_align_w;
   wire                  clk_in;
   
   reg [DIV_WIDTH-1:0]   div_ratio_r;
   reg                   divider_go_lvl;
   reg                   divider_go_lvl_s0;
   reg                   divider_go_lvl_s1;
   reg                   div_aln_rst_n;
   reg [7:0]             div_aln_cnt;
   
   wire                  divider_go_pls_t;
   wire                  divider_go_pls;

   reg                   udef_vec_en_sync2_s0;
   reg                   udef_vec_en_sync2_s1;
   wire                  udef_vec_en_sync2;
   wire                  udef_vec_en_pls;
   wire [DIV_WIDTH-1:0]  div_ratio_in;

   reg                   divider_go_ack;
   
   /*autowire*/

   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   //----------------------------------------------------------------------------
   // Alignment Logic, this signal is asserted when all dividers are aligned
   //----------------------------------------------------------------------------
   assign clks_are_align_w = &div_clk_align_vec[DIV_NUM-1:0];

   //----------------------------------------------------------------------------
   //JTAG user define dividers setting, sync. udef_en signal into clk_in domain
   //----------------------------------------------------------------------------
   crg_sync2 I_udef_vec_en0_sync2
     (
      // Outputs
      .q                                (udef_vec_en_sync2),
      // Inputs
      .clk                              (clk_in),
      .d                                (udef_vec_en));

   //----------------------------------------------------------------------------
   //JTAG user define dividers setting, detect low to high transtion of udef_en
   //----------------------------------------------------------------------------
   always @(posedge clk_in)
     begin
        if(!grst_n)
          begin
               udef_vec_en_sync2_s0  <=  1'b0;
               udef_vec_en_sync2_s1 <=  1'b0;
          end
        else
          begin
               udef_vec_en_sync2_s0 <=  udef_vec_en_sync2;
               udef_vec_en_sync2_s1 <=  udef_vec_en_sync2_s0;
          end // else: !if(!grst_n)
     end // always @ (posedge clk_in)
   
   
   assign udef_vec_en_pls =  udef_vec_en_sync2_s0 & ~udef_vec_en_sync2_s1;

   //---------------------------------------------------------------------------
   // Sample divider ratio from the register to be used by the divider only 
   // after go bit is set and sync
   //----------------------------------------------------------------------------
   assign div_ratio_in = udef_vec_en_sync2_s0 ? udef_vec[DIV_WIDTH-1:0] : (divider_go_pls_t ? div_ratio[DIV_WIDTH-1:0]  : div_ratio_r[DIV_WIDTH-1:0]);
   
   always @(posedge clk_in)
     begin
        if(!grst_n)
          begin
               div_ratio_r[DIV_WIDTH-1:0]  <=   div_ratio[DIV_WIDTH-1:0] ;
          end
        else
          begin
               div_ratio_r[DIV_WIDTH-1:0]  <=   div_ratio_in[DIV_WIDTH-1:0];
          end // else: !if(!grst_n)
     end // always @ (posedge clk_in)
   
   //---------------------------------------------------------------------------
   // Divder go pulse stretching. divider_go_lvl signal is asserted when
   // all counters are aligned and divider go is set.
   //---------------------------------------------------------------------------
   always @(posedge clk_in)
     begin
        if(!grst_n)
          begin
               divider_go_lvl <=  1'b0; 
          end
        else
          begin
               if (!divider_go_lvl & divider_go)
                 begin
                      divider_go_lvl <=   (clks_are_align_w & divider_go);
                 end
               else if (divider_go)
                 begin
                      divider_go_lvl <=  divider_go_lvl;
                 end
               else if (divider_go_lvl_s1)
                 begin
                      divider_go_lvl <=  1'b0;
                 end
          end // else: !if(!grst_n)
     end // always @ (posedge clk_in)
   
   always @(posedge clk_in)
     begin
        if(!grst_n)
          begin
               divider_go_lvl_s0 <=  1'b0;
               divider_go_lvl_s1 <=  1'b0;  
          end
        else
          begin
               divider_go_lvl_s0 <=  divider_go_lvl;
               divider_go_lvl_s1 <=  divider_go_lvl_s0;
          end // else: !if(!grst_n)
     end // always @ (posedge clk_in)
   
   //---------------------------------------------------------------------------
   // divider_go_pls is set for one cycle when dividers are align, divder_go
   // is high and divider_go_lvl is low.
   //---------------------------------------------------------------------------
   assign divider_go_pls_t = clks_are_align_w & divider_go & ~divider_go_lvl; // & ~divider_go_lvl_s0;
   assign divider_go_pls   = udef_vec_en_sync2_s0 ? udef_vec_en_pls : divider_go_pls_t;
   
   //---------------------------------------------------------------------------
   // This process generates ack. signal towards programming model to
   // indicate the complition of the dividers divisor update process.
   //---------------------------------------------------------------------------
   always @(posedge clk_in)
     begin
        if(!grst_n)
          begin
               divider_go_ack <=  1'b0;
          end
        else if (!divider_go)
          begin
               divider_go_ack <=  1'b0;
          end
        else if (!divider_go_ack)
          begin
               divider_go_ack <=  divider_go_lvl_s1;
          end
        else if (divider_go)
          begin
               divider_go_ack <=  divider_go_lvl_s1 | divider_go_ack;
          end
     end // always @ (posedge clk_in)

   //---------------------------------------------------------------------------
   // This process detects the complition of the grst sequence and generates
   // the reset signal for the divider counter.
   //---------------------------------------------------------------------------
   always @(posedge clk_in or negedge hgrst_n)
     begin
        if(!hgrst_n)
          begin
               div_aln_rst_n <=  1'b1;
               div_aln_cnt <=  8'd0; 
          end
        else 
          begin
             if(!grst_n & !pre_grst_n_ind)
               begin
                    div_aln_rst_n <=  1'b1;
                    div_aln_cnt <=  8'd0;
               end
             else if (!grst_n & pre_grst_n_ind)
               begin
                    div_aln_rst_n <=  1'b0;
                    div_aln_cnt <=  8'd0;
               end
             else if (grst_n & div_aln_cnt < 8'd15)
               begin
                    div_aln_rst_n <=  1'b0;
                    div_aln_cnt <=  div_aln_cnt +1;
               end
             else
               begin
                    div_aln_rst_n <=  1'b1;
                    div_aln_cnt <=  div_aln_cnt;
               end // else: !if(grst_n & div_aln_cnt < 8'd15)
          end // else: !if(!hgrst_n)
     end // always @ (posedge clk_in or negedge hgrst_n)

   rcg_ctrl_div_cntr #(.DIV_WIDTH(DIV_WIDTH), .DIV_TYPE(DIV_TYPE), .HALFDC_UP(HALFDC_UP)) I_rcg_ctrl_div_cntr
     (/*autoinst*/
      // Outputs
      .gclk_div_out                     (gclk_div_out),
      .gclk_div_cg_en                   (gclk_div_cg_en),
      .gclk_div_en                      (gclk_div_en),
      .div_clk_align                    (div_clk_align),
      // Inputs
      .clk_in                           (clk_in),
      .grst_n                           (grst_n),
      .hgrst_n                          (hgrst_n),
      .div_ratio                        (div_ratio_r[DIV_WIDTH-1:0]),
      .div_aln_rst_n                    (div_aln_rst_n),
      .divider_go_pls                   (divider_go_pls));
          
endmodule // rcg_ctrl_div

// Local Variables:
// verilog-library-directories:("." "../hdl/")
// End:
