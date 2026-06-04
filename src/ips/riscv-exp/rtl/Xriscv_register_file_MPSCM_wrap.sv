// Copyright 2020 EnICS Lab - Bar Ilan University - Israel.
// Copyright and related rights are licensed under the Solderpad Hardware

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Hanan Marinberg  -  hanan.marinberg@biu.ac.il              //
//                                                                            //
// Additional contributions by:                                               //
//                 Tzachi Noy       -  tzachi.noy@biu.ac.il                   //
//                                                                            //
//                                                                            //
// Design Name:    RISC-V register file exp MPSCM wrap                        //
// Project Name:   RISCV                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Register file experimental MPSCM      ,                    //
//                 MPSCM - Multi Ported Standard Cell Memory (Hanan)          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

//
// ADDRESS 0 is NOT WRITABLE !!!!!!!!!!!!!!!!!!!!
//

module Xriscv_register_file_MPSCM_wrap
#(
   parameter ADDR_WIDTH    = 5,
   parameter DATA_WIDTH    = 32
)
(
   // Clock and Reset
   input  logic                   clk,
   input  logic                   rst_n,

   input  logic                   test_en_i,

   //Read port R1
   input  logic [ADDR_WIDTH-1:0]  raddr_a_i,
   output logic [DATA_WIDTH-1:0]  rdata_a_o,

   //Read port R2
   input  logic [ADDR_WIDTH-1:0]  raddr_b_i,
   output logic [DATA_WIDTH-1:0]  rdata_b_o,

   //Read port R3
   input  logic [ADDR_WIDTH-1:0]  raddr_c_i,
   output logic [DATA_WIDTH-1:0]  rdata_c_o,

   // Write port W1
   input  logic [ADDR_WIDTH-1:0]   waddr_a_i,
   input  logic [DATA_WIDTH-1:0]   wdata_a_i,
   input  logic                    we_a_i,

   // Write port W2
   input  logic [ADDR_WIDTH-1:0]   waddr_b_i,
   input  logic [DATA_WIDTH-1:0]   wdata_b_i,
   input  logic                    we_b_i
   
   `ifdef HAMSA_DIX  // Dual-Issue regfile interface
   //, di_regfile_interface.pi di_intrfc_regfile   // Notice regfile exists only in the primary issue
   , input  logic [ADDR_WIDTH-1:0]   raddr_d_i,
     output logic [DATA_WIDTH-1:0]   rdata_d_o,
     input  logic [ADDR_WIDTH-1:0]   raddr_e_i,
     output logic [DATA_WIDTH-1:0]   rdata_e_o,
     input  logic [ADDR_WIDTH-1:0]   waddr_c_i,
     input  logic [DATA_WIDTH-1:0]   wdata_c_i,
     input  logic                    we_c_i
   `endif
   
);

   logic SE = 0;
   logic RE_RP_0 = 1;
   logic RE_RP_1 = 1;
   logic RE_RP_2 = 1;
   logic RE_RP_3 = 1;
   logic RE_RP_4 = 1;

   `ifdef ULVT_ONLY
   mpscm16_ulvt_32x32_WP_3_RP_5
   `else
   mpscm16_32x32_WP_3_RP_5
   `endif

   mpscm16_32x32_WP_3_RP_5_i
   (
      .CLK        ( clk          ),
      //.rst_n      ( rst_n        ),
      .SE         ( 1'b0         ),

      //.test_en_i  ( test_en_i    ),
      //.RE_RP_0    (1'b1          ),
      //.RE_RP_1    (1'b1          ),
      //.RE_RP_2    (1'b1          ),
      //.RE_RP_3    (1'b1          ),
      //.RE_RP_4    (1'b1          ),

      .RADDR_RP_0 ( raddr_a_i    ),
      .DOUT_RP_0  ( rdata_a_o    ),

      .RADDR_RP_1 ( raddr_b_i    ),
      .DOUT_RP_1  ( rdata_b_o    ),

      .RADDR_RP_2 ( raddr_c_i    ),
      .DOUT_RP_2  ( rdata_c_o    ),


      .WADDR_WP_0 ( waddr_a_i    ),
      .DIN_WP_0   ( wdata_a_i    ),
      .WE_WP_0    ( we_a_i       ),

      .WADDR_WP_1 ( waddr_b_i    ),
      .DIN_WP_1   ( wdata_b_i    ),
      .WE_WP_1    ( we_b_i       )
      
        `ifdef HAMSA_DIX  // Dual-Issue Logic ports connection
         , .RADDR_RP_3 ( raddr_d_i    ),
           .DOUT_RP_3  ( rdata_d_o    ),

           .RADDR_RP_4 ( raddr_e_i    ),
           .DOUT_RP_4  ( rdata_e_o    ),

           .WADDR_WP_2 ( waddr_c_i    ),
           .DIN_WP_2   ( wdata_c_i    ),
           .WE_WP_2    ( we_c_i       )
        `endif                     
      
   );





endmodule
