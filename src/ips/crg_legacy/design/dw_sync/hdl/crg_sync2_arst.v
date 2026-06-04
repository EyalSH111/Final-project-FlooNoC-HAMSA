// User: ronen
// Date: 23_07_2011-Time 16_47_32
// Version:/main/10
// Description:
//         change to SVT High density instead of HVT
//////
//-----------------------------------------------------------------------------
// Title         : CRG Sync2 async reset_n FF
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : crg_sync2_arst.v
// Author        : Ran Nachum Tool  <ran@earth.ceragon.com>
// Created       : 25.02.2010
// Last modified : 25.02.2010
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by Ceragon This model is the confidential and
// proprietary property of Ceragon and the possession or use of this
// file requires a written license from Ceragon.
//------------------------------------------------------------------------------
// Modification history :
// 25.02.2010 : created
// 04.03.2018 : TSMC 16FFC standard cells instantiated (Slava Yuzhaninov - yuzhans@biu.ac.il)
//-----------------------------------------------------------------------------



module crg_sync2_arst (clr_n, d, clk, q);

   input        wire clr_n;          // Active low  async clear input
   input        wire d;              //  data input
   input        wire clk;            //  clock input
   output       wire q;              //  data output

   parameter RESET_STATE = 1'b0;


`ifndef RTL_SIM
    wire q1;
    generate
        if (RESET_STATE == 1'b0) begin : async_reset
            m_ff_arst I_crg_sync1 (.CK(clk), .D(d), .RN(clr_n), .Q(q1));
            m_ff_arst I_crg_sync2 (.CK(clk), .D(q1), .RN(clr_n), .Q(q));
        end else begin : async_set
            m_ff_aset I_crg_sync1 (.CK(clk), .D(d), .SN(clr_n), .Q(q1));
            m_ff_aset I_crg_sync2 (.CK(clk), .D(q1), .SN(clr_n), .Q(q));
        end
    endgenerate
`else // `ifndef RTL_SIM
    wire    flop1_r_tmp1; // temporary 1st stage captured at the first clock cycle
    wire    flop1_r_tmp2; // temporary 1st stage captured at the second clock cycle
    wire    flop1_r_tmp3; // temporary 1st stage captured at the third clock cycle
    generate
        if (RESET_STATE == 1'b0) begin : async_reset
            m_ff_arst I_crg_sync1 (.CK(clk), .D(d           ), .RN(clr_n), .Q(flop1_r_tmp1));
            m_ff_arst I_crg_sync2 (.CK(clk), .D(flop1_r_tmp1), .RN(clr_n), .Q(flop1_r_tmp2));
            m_ff_arst I_crg_sync3 (.CK(clk), .D(flop1_r_tmp2), .RN(clr_n), .Q(flop1_r_tmp3));
        end else begin : async_set
            m_ff_aset I_crg_sync1 (.CK(clk), .D(d           ), .SN(clr_n), .Q(flop1_r_tmp1));
            m_ff_aset I_crg_sync2 (.CK(clk), .D(flop1_r_tmp1), .SN(clr_n), .Q(flop1_r_tmp2));
            m_ff_aset I_crg_sync3 (.CK(clk), .D(flop1_r_tmp2), .SN(clr_n), .Q(flop1_r_tmp3));
        end
    endgenerate
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
     select <=  ({$random(rand_seed)} % 2) & 1'b1;

   reg rand_select;
   always @(posedge clk)
     rand_select <= ~random_sync | select;

   assign q = rand_select ? flop1_r_tmp2 : flop1_r_tmp3;
`endif

endmodule // crg_sync2_arst
