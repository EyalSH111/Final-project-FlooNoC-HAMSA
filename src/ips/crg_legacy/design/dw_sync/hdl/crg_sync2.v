// User: ronen
// Date: 23_07_2011-Time 16_47_31
// Version:/main/9
// Description:
//         change to SVT High density instead of HVT
//////
// User: sasiez
// Date: 11_05_2011-Time 16_39_05
// Version:/main/7
// Description:
//               changed the random mechanism
//////
//-----------------------------------------------------------------------------
// Title         : crg_sync2
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : crg_sync2.v
// Author        : Ran Nachum Tool  <ran@earth.ceragon.com>
// Created       : 25.02.2010
// Last modified : 25.02.2010
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
// 25.02.2010 : created
// 04.03.2018 : TSMC 16FFC standard cells instantiated (Slava Yuzhaninov - yuzhans@biu.ac.il)
//-----------------------------------------------------------------------------

module crg_sync2 (clk, d, q ) ;

   input     wire clk ;
   input     wire d   ;
   output    wire q   ;

`ifndef RTL_SIM
   wire q1;

   `ifdef TSMC_65
       m_ff #(.X_SIZE (1) ) I_crg_sync1 (.CK(clk), .D(d), .Q(q1));
       m_ff #(.X_SIZE (2) ) I_crg_sync2 (.CK(clk), .D(q1), .Q(q));
   `elsif TSMC16
       `ifdef PNR
            sync_2ff I_sync_2ff (.clk(clk),.in(d),.out(q));
       `else
            m_ff #(.X_SIZE (0) ) I_crg_sync1 (.CK(clk), .D(d), .Q(q1));
            m_ff #(.X_SIZE (2) ) I_crg_sync2 (.CK(clk), .D(q1), .Q(q));
        `endif // !`elsif PNR
    `endif // !`elsif TSMC16
 
`else
   wire    q_tmp1; // temporary 1st stage captured at the first clock cycle
   wire    q_tmp2; // temporary 1st stage captured at the second clock cycle
   wire    q_tmp3;
   m_ff I_crg_sync1 (.CK(clk), .D(d), .Q(q_tmp1));
   m_ff I_crg_sync2 (.CK(clk), .D(q_tmp1), .Q(q_tmp2));
   m_ff I_crg_sync3 (.CK(clk), .D(q_tmp2), .Q(q_tmp3));

   parameter LOCAL_RAND_SYNC = 1'b1;

   integer   rand_seed,randseed,seed_modifier,i,arg;
   wire      global_rand_sync;
   wire      random_sync;


   reg [1023:0] string_tmp;
   initial
     begin
        $sformat(string_tmp,"%m");
        arg = 0;
        for (i=0 ; i < 32 ; i = i + 1) begin
           arg = arg ^ string_tmp;
           string_tmp = string_tmp >> 32;
        end
        if (!$value$plusargs("SYNC_RAND_SEED=%d",  randseed)) randseed=0;
        rand_seed = randseed ^ arg;
     end // initial begin

   assign global_rand_sync = ($test$plusargs("RAND_SYNC"));
   assign random_sync = LOCAL_RAND_SYNC & global_rand_sync;

   reg select;
   always @(q)
     select <= ({$random(rand_seed)} % 2) & 1'b1;

   reg rand_select;
   always @(posedge clk)
     rand_select <= ~random_sync | select;

   assign q = rand_select ? q_tmp2 : q_tmp3;
`endif
endmodule // crg_sync2
