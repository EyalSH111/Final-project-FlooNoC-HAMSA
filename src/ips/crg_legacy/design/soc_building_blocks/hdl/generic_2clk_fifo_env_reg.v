/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////                                                                 ////
////  generic_2clk_fifo_env_reg.v                                    ////
////                                                                 ////
////  This file is part of the phy project                           ////
////                                                                 ////
////  Known problems (limits):                                       ////
////  None                                                           ////
////                                                                 ////
////  To Do:                                                         ////
////  Nothing.                                                       ////
////                                                                 ////
////  Author(s):                                                     ////
////      - udil@ceragon.com                                         ////
////      - Udi Lavie                                                ////
////                                                                 ////
////  Created:        08.06.10                                       ////
////  Last Updated:   08.06.10                                       ////
////                                                                 ////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////


// this block is a wrapper for the blocks:
// 1) generic_2clk_fifo
// 2) generic_2port_reg_ram
//
// together - it forms a complete 2 clock FIFO based on FFs

module generic_2clk_fifo_env_reg ( wr_clk,
                               wr_reset_out_n,
                               wr_op,
                               wr_data,
                               wr_full,
                               wr_empty,
                               wr_entry_used,
                               wr_full_err,
                               rd_clk,
                               rd_reset_n,
                               rd_op,
                               rd_data,
                               rd_full,
                               rd_empty,
                               rd_entry_used,
                               rd_empty_err,
                               scan_mode
                             );


  // ADDITINAL FUNCTIONS
  // ===================
  `include "jupiter_functions.v"

   parameter DEPTH = 256;                // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DW = 32;                    // data bus width of the fifo
   parameter PTR_WIDTH = clog2(DEPTH);   // address bus width of the fifo

   input  wr_clk;
   output wr_reset_out_n;
   input  wr_op;
   input  [DW-1:0] wr_data;
   output wr_full;
   output wr_empty;
   output [PTR_WIDTH :0] wr_entry_used;
   output wr_full_err;
   input  rd_clk;
   input  rd_reset_n;
   input  rd_op;
   output [DW-1:0] rd_data;
   output rd_full;
   output rd_empty;
   output [PTR_WIDTH :0] rd_entry_used;
   output rd_empty_err;
   input  scan_mode;

   wire [PTR_WIDTH - 1:0] wr_addr;
   wire [DW-1:0] wr_data;
   wire [PTR_WIDTH :0] wr_entry_used;

   wire [PTR_WIDTH - 1:0] rd_addr;
   wire [DW-1:0] rd_data;
   wire [PTR_WIDTH :0] rd_entry_used;
   wire                rd_reset_n_d;
   wire                rd_reset_n_muxed;


   crg_scan_ff  rd_reset_sync (
             .clk(rd_clk),
             .d(rd_reset_n),
             .q(rd_reset_n_d)                            
          );

   crg_clk_mx2
     I_rd_reset_n_clk_mx
       ( // Outputs
        .y                              (rd_reset_n_muxed),
        // Inputs
        .a                              (rd_reset_n_d),
        .b                              (rd_reset_n),
        .s                              (scan_mode));

   

generic_2clk_fifo #(  .PTR_WIDTH( PTR_WIDTH ),
                          .NUM_OF_ENTRIES( DEPTH )
          ) Igeneric_2clk_fifo (
             .scan_mode (scan_mode),
             // Port a: Rd
             .clka(rd_clk),
             .reseta_n(rd_reset_n_muxed),
             .rd_op(rd_op),
             .rd_addr(rd_addr),
             .fulla(rd_full),
             .emptya(rd_empty),
             .entry_useda(rd_entry_used),
             .err_rdemptya(rd_empty_err),
             // Port b: Wr
             .clkb(wr_clk),
             .resetb_out_n(wr_reset_out_n),
             .wr_op(wr_op),
             .wr_addr(wr_addr),
             .fullb(wr_full),
             .emptyb(wr_empty),
             .entry_usedb(wr_entry_used),
             .err_wrfullb(wr_full_err)
          );



generic_2port_reg_ram #(  .DW( DW ),      // width
                  .DEPTH( DEPTH ) // depth
          ) u_generic_2port_reg_ram (
             // Wr Ports
             .wr_addr   (wr_addr),
             .data_in   (wr_data),
             .wr        (wr_op),
             .clk       (wr_clk),
             .cs_n      (1'b0),
             // Rd Ports
             .data_out  (rd_data),
             .rd_addr   (rd_addr),
             // System
             .sreset_n  (wr_reset_out_n)
          );

endmodule // generic_2clk_fifo_env_reg

