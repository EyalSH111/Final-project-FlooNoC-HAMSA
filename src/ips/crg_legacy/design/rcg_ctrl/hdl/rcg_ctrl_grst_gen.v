//-----------------------------------------------------------------------------
// Title         : RCG Global-Reset Generator
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_grst_gen.v
// Author        : naftalyb@ceragon.com
// Created       : 4.07.2013
// Last modified : Time-stamp: <2015-12-20 1427 naftalyb>
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2013 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 4.07.2013 : created
//------------------------------------------------------------------------------

module rcg_ctrl_grst_gen(/*AUTOARG*/
   // Outputs
   rcg_hgrst_n, rcg_grst_n, rcg_pre_grst_n_ind,
   // Inputs
   ref_clk, hgrst_n, grst_n
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter             RESET_DURATION   =  1024;
   
   //----------------------------------------------------------------------------
   // Reference input clock.
   //----------------------------------------------------------------------------
   input                 ref_clk;
   //----------------------------------------------------------------------------
   // Global resets from POR/GRST blocks.
   //----------------------------------------------------------------------------
   input                 hgrst_n; // asserts upon assertion of POR or RST_in resets
   input                 grst_n; // asserts for 1024 cycles afer hgrst_n
   //----------------------------------------------------------------------------
   // RCG domain grst_n, hgrst_n and pre_grst_n_ind signals.
   //----------------------------------------------------------------------------
   output                rcg_hgrst_n; // crg_sync2 version of hgrst_n
   output                rcg_grst_n; // asserts for 1024 cycles afer rcg_hgrst_n
   output                rcg_pre_grst_n_ind; // de-assert 5 cycles before rcg_grst_n
   
   //----------------------------------------------------------------------------
   // Signals Definitions.
   //----------------------------------------------------------------------------
   wire                  rcg_hgrst_n_sync2;
   reg                   rcg_grst_n_req_s0;
   reg                   rcg_grst_n_req_pls_s0;
   reg                   rcg_grst_n_req_pls_s1;
   reg                   rcg_grst_n_req_pls_s2;
   reg                   rcg_grst_n_req_strch;
   reg                   rcg_grst_n_r;
   reg                   rcg_pre_grst_n_ind_r;
   reg [15:0]            grst_n_cnt;
   
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   assign                rcg_hgrst_n = rcg_hgrst_n_sync2;
   assign                rcg_grst_n = rcg_grst_n_r;
   assign                rcg_pre_grst_n_ind = rcg_pre_grst_n_ind_r;
   
   /*autotieoff*/
   
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   //----------------------------------------------------------------------------
   // Synchronize hgrst_n to ref_clk
   //----------------------------------------------------------------------------
   crg_sync2_arst I_rst_n_sync2
     (
      // Outputs
      .q           (rcg_hgrst_n_sync2),
      // Inputs
      .clr_n       (hgrst_n),
      .d           (1'b1),
      .clk         (ref_clk));

   //----------------------------------------------------------------------------
   // Synchronize grst_n (from SoC rst-control) to ref_clk
   //----------------------------------------------------------------------------
   crg_sync2 I_grst_n_sync2
     (
      // Outputs
      .q           (grst_n_sync2),
      // Inputs
      .d           (grst_n),
      .clk         (ref_clk));

   //----------------------------------------------------------------------------
   // Generate pulse when  grst_n_sync2 goes from high to low.
   //----------------------------------------------------------------------------
   wire  rcg_grst_n_req_pls = rcg_grst_n_req_s0 & ~grst_n_sync2;

   always @(posedge ref_clk or negedge rcg_hgrst_n_sync2)
     begin
          if (!rcg_hgrst_n_sync2)
            rcg_grst_n_req_s0 <= 1'b0;
          else
            rcg_grst_n_req_s0 <= grst_n_sync2;
     end // always @ (posedge ref_clk or negedge rcg_hgrst_n_sync2)
   
   //----------------------------------------------------------------------------
   // Strech "rcg_grst_n_req_pls" for duration of 3 ref_clk cycles.
   //----------------------------------------------------------------------------
   always @(posedge ref_clk or negedge rcg_hgrst_n_sync2)
     begin
          if (rcg_hgrst_n_sync2 == 1'b0)
            begin
                 rcg_grst_n_req_pls_s0 <= 1'b0;
                 rcg_grst_n_req_pls_s1 <= 1'b0;
                 rcg_grst_n_req_pls_s2 <= 1'b0;
            end
          else
            begin
                 rcg_grst_n_req_pls_s0 <= rcg_grst_n_req_pls;
                 rcg_grst_n_req_pls_s1 <= rcg_grst_n_req_pls_s0;
                 rcg_grst_n_req_pls_s2 <= rcg_grst_n_req_pls_s1;
            end // else: !if(!hgrst_n)
     end // always @ (posedge ref_clk or negedge rcg_hgrst_n_sync2)
   
   always @(posedge ref_clk or negedge rcg_hgrst_n_sync2)
     begin
          if (rcg_hgrst_n_sync2 == 1'b0)
            rcg_grst_n_req_strch <= 1'b0;
          else
            rcg_grst_n_req_strch <= rcg_grst_n_req_pls_s0 | rcg_grst_n_req_pls_s1 | rcg_grst_n_req_pls_s2;
     end // always @ (posedge ref_clk or negedge rcg_hgrst_n_sync2)

   //----------------------------------------------------------------------------
   // grst_n counter. This counter restes upon assertion of "rcg_hgrst_n_sync2"
   // or "rcg_grst_n_req_strch". The counter will count until it reaches
   // RESET_DURATION value.
   //----------------------------------------------------------------------------
   always @(posedge ref_clk or negedge rcg_hgrst_n_sync2)
     begin
          if (rcg_hgrst_n_sync2 == 1'b0)
            grst_n_cnt[15:0] <= 16'h0;
          else if (rcg_grst_n_req_strch)
            grst_n_cnt[15:0] <= 16'h0;
          else
            grst_n_cnt[15:0] <= (grst_n_cnt[15:0] < RESET_DURATION) ? grst_n_cnt[15:0] + 16'h1 : grst_n_cnt[15:0];
     end // always @ (posedge ref_clk or negedge rcg_hgrst_n_sync2)
   
   //----------------------------------------------------------------------------
   // rcg_grst_n_r generation. rcg_grst_n_r clears upon de-assertion of
   // "rcg_hgrst_n_sync2" or assertion of "rcg_grst_n_req_strch". It will
   // go high when grst_n_cnt[15:0] reaches RESET_DURATION value.
   //----------------------------------------------------------------------------
   always @(posedge ref_clk or negedge rcg_hgrst_n_sync2)
     begin
       if (rcg_hgrst_n_sync2 == 1'b0)
         rcg_grst_n_r  <= 1'b0;
       else
         begin
           if(grst_n_cnt[15:0] == RESET_DURATION)
             rcg_grst_n_r  <= ~rcg_grst_n_req_strch;
           else if(grst_n_cnt[15:0] < RESET_DURATION)
             rcg_grst_n_r  <= 1'b0;         
         end // else: !if(!hgrst_n)
     end // always @ (posedge ref_clk or negedge rcg_hgrst_n_sync2)
   
   //----------------------------------------------------------------------------
   // rcg_pre_grst_n_ind_r generation. During grst_n preiod, 5 cycles before
   // grst_n_cnt[15:0] reaches RESET_DURATION value, "rcg_pre_grst_n_ind_r"
   // will be asserted. It will de-assert upon the de-assertion of "rcg_grst_n_r"
   // (at the end of the grst sequence).
   //----------------------------------------------------------------------------
   always @(posedge ref_clk or negedge rcg_hgrst_n_sync2)
     begin
       if (rcg_hgrst_n_sync2 == 1'b0)
         rcg_pre_grst_n_ind_r  <= 1'b0;
       else
         rcg_pre_grst_n_ind_r  <= ((grst_n_cnt[15:0] > RESET_DURATION - 5) & ~rcg_grst_n_r)   ? 1'b1 : 1'b0;
     end // always @ (posedge ref_clk or negedge rcg_hgrst_n_sync2)
   

endmodule // rcg_ctrl_grst_gen

// Local Variables:
// verilog-library-directories:("." "../../")
// End: