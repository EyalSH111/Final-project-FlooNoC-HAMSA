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

module Xriscv_register_file_CARME_wrap
#(
   localparam ADDR_WIDTH    = 5,
   localparam DATA_WIDTH    = 32
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
   input  logic                    we_b_i,

   `ifdef HAMSA_DIX  // Dual-Issue regfile interface
   //, di_regfile_interface.pi di_intrfc_regfile   // Notice regfile exists only in the primary issue
     input  logic [ADDR_WIDTH-1:0]   raddr_d_i,
     output logic [DATA_WIDTH-1:0]   rdata_d_o,
     input  logic [ADDR_WIDTH-1:0]   raddr_e_i,
     output logic [DATA_WIDTH-1:0]   rdata_e_o,
     input  logic [ADDR_WIDTH-1:0]   waddr_c_i,
     input  logic [DATA_WIDTH-1:0]   wdata_c_i,
     input  logic                    we_c_i,
   `endif

   // Scan interface (and PWD_N) connected to registers
   input  logic [3:0]                   carme_rf_cfg,
   output logic [1:0]                   carme_rf_status

);

logic CLK_S;
logic SCAN;
logic SCAN_E;
logic [1:0] SCAN_O;
logic PWD_N;

assign CLK_S  = carme_rf_cfg[0];
assign SCAN   = carme_rf_cfg[1];
assign SCAN_E = carme_rf_cfg[2];
assign PWD_N  = !carme_rf_cfg[3];
assign carme_rf_status = SCAN_O; // is 2 bit

   `ifdef HAMSA_DIX

   TOP_3W_5R_Test i_carme_3w5r_rf (
                                   .DATA_IN_A (wdata_a_i),
                                   .DATA_IN_B (wdata_b_i),
                                   .DATA_IN_C (wdata_c_i),
                                   .WRITE_A   (we_a_i),
                                   .WRITE_B   (we_b_i),
                                   .WRITE_C   (we_c_i),
                                   .CLK_A     (clk),
                                   .RST_N     (rst_n),
                                   .PWD_N     (PWD_N),
                                   .CLK_S     (CLK_S),
                                   .SCAN      (SCAN),
                                   .SCAN_E    (SCAN_E),
                                   .SCAN_O    (SCAN_O),
                                   .WR_ADD_A  (waddr_a_i),
                                   .WR_ADD_B  (waddr_b_i),
                                   .WR_ADD_C  (waddr_c_i),
                                   .A_A       (raddr_a_i),
                                   .A_B       (raddr_b_i),
                                   .A_C       (raddr_c_i),
                                   .A_D       (raddr_d_i),
                                   .A_E       (raddr_e_i),
                                   .OUT0      (rdata_a_o),
                                   .OUT1      (rdata_b_o),
                                   .OUT2      (rdata_c_o),
                                   .OUT3      (rdata_d_o),
                                   .OUT4      (rdata_e_o)
                                   );
   `endif

endmodule
