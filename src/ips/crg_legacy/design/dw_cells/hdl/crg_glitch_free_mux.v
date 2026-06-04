// User: ronen
// Date: 25_07_2011-Time 18_24_08
// Version:/main/6
// Description:
//         replace all  High density cells to SVT instead of HVT
//////
//-----------------------------------------------------------------------------
// Title         : Glitch Free clock mux
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : crg_glitch_free_mux.v
// Author        : Ran Nachum Tool  <ran@earth.ceragon.com>
// Created       : 28.02.2010
// Last modified : 28.02.2010
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by Ceragon This model is the confidential and
// proprietary property of Ceragon and the possession or use of this
// file requires a written license from Ceragon.
//------------------------------------------------------------------------------
// Modification history :
// 28.02.2010 : created
// 04.03.2018 : TSMC 16FFC standard cells instantiated (Slava Yuzhaninov - yuzhans@biu.ac.il)
//-----------------------------------------------------------------------------

module crg_glitch_free_mux (/*autoarg*/
                            // Outputs
                            clk_out,
                            // Inputs
                            clk_a, clk_b, sel, rst_n
                            );

   input     clk_a;
   input     clk_b;
   input     sel;
   input     rst_n;
   output    clk_out;


   wire      sel_stage_a;
   wire      sel_stage_a_sync;
   wire      sel_stage_b;
   wire      sel_stage_b_sync;

   wire      clk_out_a;
   wire      clk_out_b;

   wire      clk_out;
   wire      sel_n;

   wire      sel_a;
   wire      a_rst_n;
   wire      sel_a_d1;
   wire      sel_a_d2;
   wire      sel_a_d2_inv;

   wire      sel_b;
   wire      b_rst_n;
   wire      sel_b_d1;
   wire      sel_b_d2;
   wire      sel_b_d2_inv;


   // ----------------------   Stage a   ----------------------

   crg_clk_inv I_sel_in_inv    (
                                .a (sel),
                                .y (sel_n)
                                );

   crg_clk_inv I_b_out_inv     (
                                .a (sel_b_d2),
                                .y (sel_b_d2_inv)
                                );

   crg_clk_an2 I_a_in_and2     (
                                .a (sel_n),
                                .b (sel_b_d2_inv),
                                .y (sel_a)
                                );

   crg_sync2_arst I_rsta_n_sync (
                                 .q     (a_rst_n),
                                 .clr_n (rst_n),
                                 .d     (1'b1),
                                 .clk   (clk_a)
                                 );

   crg_sync2n_arst I_a_sel_sync2n (
                                   .clr_n (a_rst_n),
                                   .clk (clk_a),
                                   .d   (sel_a),
                                   .q   (sel_a_d2)
                                   );

   crg_clk_nand2 I_a_nand2     (
                                .a (clk_a),
                                .b (sel_a_d2),
                                .y (clk_out_a)
                                );

   // ----------------------   Stage b   ----------------------

   crg_clk_inv I_a_out_inv      (
                                 .a (sel_a_d2),
                                 .y (sel_a_d2_inv)
                                 );

   crg_clk_an2 I_b_in_and2      (
                                 .a (sel),
                                 .b (sel_a_d2_inv),
                                 .y (sel_b)
                                 );

   crg_sync2_arst I_rstb_n_sync (
                                 .q     (b_rst_n),
                                 .clr_n (rst_n),
                                 .d     (1'b1),
                                 .clk   (clk_b)
                                 );

   crg_sync2n_arst I_b_sel_sync2n (
                                   .clr_n (b_rst_n),
                                   .clk (clk_b),
                                   .d   (sel_b),
                                   .q   (sel_b_d2)
                                   );

   crg_clk_nand2 I_b_nand2      (
                                 .a (clk_b),
                                 .b (sel_b_d2),
                                 .y (clk_out_b)
                                 );

   // ----------------------   final nand   ----------------------

   crg_clk_nand2 I_final_nand2  (
                                 .a (clk_out_a),
                                 .b (clk_out_b),
                                 .y (clk_out)
                                 );

endmodule // crg_glitch_free_mux
