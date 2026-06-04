// Copyright 2020 EnICS Lab - Bar Ilan University - Israel.
// Copyright and related rights are licensed under the Solderpad Hardware

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Hanan Marinberg  -  hanan.marinberg@biu.ac.il              //
//                                                                            //
// Additional contributions by:                                               //
//                 Tzachi Noy       -  tzachi.noy@biu.ac.il                   //
//                                                                            //
//                                                                            //
// Design Name:    RISC-V register file exp Mux and DeMUX                     //
// Project Name:   RISCV                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Register file experimental Multiplexer,                    //
//                 Choose which register file to activate                     //
//                 between:                                                   //
//                 MPSCM - Multi Ported Standard Cell Memory (Hanan)          //
//                 XXX (Tomer)                                                //
//                 RTL - the original rtl reg file of RISC-V                  //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

//
// ADDRESS 0 is NOT WRITABLE !!!!!!!!!!!!!!!!!!!!
//

module Xriscv_register_file_mux  // MUX and DeMUX
#(
   parameter ADDR_WIDTH    = 5,
   parameter DATA_WIDTH    = 32,
   parameter FPU           = 0,
   parameter Zfinx         = 0
)
(
   // Clock and Reset
   input  logic                   clk,
   input  logic                   rst_n,

   input  logic                   reg_mux_i,
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
    ,di_regfile_interface.pi di_intrfc_regfile   // Notice regfile exists only in the primary issue
   `endif

);

  typedef enum logic { MPSCM, ORIGINAL_REG } reg_file_t;
  reg_file_t reg_mux_i_e;
  assign reg_mux_i_e = reg_file_t'(reg_mux_i);

  // MPSCM signals:
  logic                   MPSCM_clk;
  logic                   MPSCM_rst_n;
  logic                   MPSCM_test_en_i;
  logic [ADDR_WIDTH-1:0]  MPSCM_raddr_a_i;
  logic [DATA_WIDTH-1:0]  MPSCM_rdata_a_o;
  logic [ADDR_WIDTH-1:0]  MPSCM_raddr_b_i;
  logic [DATA_WIDTH-1:0]  MPSCM_rdata_b_o;
  logic [ADDR_WIDTH-1:0]  MPSCM_raddr_c_i;
  logic [DATA_WIDTH-1:0]  MPSCM_rdata_c_o;
  logic [ADDR_WIDTH-1:0]  MPSCM_waddr_a_i;
  logic [DATA_WIDTH-1:0]  MPSCM_wdata_a_i;
  logic                   MPSCM_we_a_i;
  logic [ADDR_WIDTH-1:0]  MPSCM_waddr_b_i;
  logic [DATA_WIDTH-1:0]  MPSCM_wdata_b_i;
  logic                   MPSCM_we_b_i;
  `ifdef HAMSA_DIX  // Dual-Issue regfile interface
   //di_regfile_interface MPSCM_di_intrfc_regfile();   // Notice regfile exists only in the primary issue
    logic [ADDR_WIDTH-1:0]  MPSCM_raddr_d_i;
    logic [DATA_WIDTH-1:0]  MPSCM_rdata_d_o;
    logic [ADDR_WIDTH-1:0]  MPSCM_raddr_e_i;
    logic [DATA_WIDTH-1:0]  MPSCM_rdata_e_o;
    logic [ADDR_WIDTH-1:0]  MPSCM_waddr_c_i;
    logic [DATA_WIDTH-1:0]  MPSCM_wdata_c_i;
    logic                   MPSCM_we_c_i;
  `endif

  // ORIGINAL_REG signals:
  logic                   ORIG_clk;
  logic                   ORIG_rst_n;
  logic                   ORIG_test_en_i;
  logic [ADDR_WIDTH-1:0]  ORIG_raddr_a_i;
  logic [DATA_WIDTH-1:0]  ORIG_rdata_a_o;
  logic [ADDR_WIDTH-1:0]  ORIG_raddr_b_i;
  logic [DATA_WIDTH-1:0]  ORIG_rdata_b_o;
  logic [ADDR_WIDTH-1:0]  ORIG_raddr_c_i;
  logic [DATA_WIDTH-1:0]  ORIG_rdata_c_o;
  logic [ADDR_WIDTH-1:0]  ORIG_waddr_a_i;
  logic [DATA_WIDTH-1:0]  ORIG_wdata_a_i;
  logic                   ORIG_we_a_i;
  logic [ADDR_WIDTH-1:0]  ORIG_waddr_b_i;
  logic [DATA_WIDTH-1:0]  ORIG_wdata_b_i;
  logic                   ORIG_we_b_i;
  `ifdef HAMSA_DIX  // Dual-Issue regfile interface
   //di_regfile_interface ORIG_di_intrfc_regfile();   // Notice regfile exists only in the primary issue
    logic [ADDR_WIDTH-1:0]  ORIG_raddr_d_i;
    logic [DATA_WIDTH-1:0]  ORIG_rdata_d_o;
    logic [ADDR_WIDTH-1:0]  ORIG_raddr_e_i;
    logic [DATA_WIDTH-1:0]  ORIG_rdata_e_o;
    logic [ADDR_WIDTH-1:0]  ORIG_waddr_c_i;
    logic [DATA_WIDTH-1:0]  ORIG_wdata_c_i;
    logic                   ORIG_we_c_i;
  `endif

  // Clock Gates:
  wire EN_MPSCM, EN_ORIG;
  assign EN_MPSCM = (reg_mux_i_e==MPSCM);
  assign EN_ORIG =  (reg_mux_i_e==ORIGINAL_REG);

  m_cg CG_MPSCM (.CK(clk), .E(EN_MPSCM), .SE(1'b0), .ECK(MPSCM_clk) );
  m_cg CG_ORIG  (.CK(clk), .E(EN_ORIG),  .SE(1'b0), .ECK(ORIG_clk)  );

  always @*
  begin : demux
    case (reg_mux_i_e)
    MPSCM:
        begin
            MPSCM_rst_n             = rst_n;
            MPSCM_test_en_i         = test_en_i;
            MPSCM_raddr_a_i         = raddr_a_i;
            MPSCM_raddr_b_i         = raddr_b_i;
            MPSCM_raddr_c_i         = raddr_c_i;
            MPSCM_raddr_d_i         = di_intrfc_regfile.raddr_a2;
            MPSCM_raddr_e_i         = di_intrfc_regfile.raddr_b2;
            MPSCM_waddr_a_i         = waddr_a_i;
            MPSCM_wdata_a_i         = wdata_a_i;
            MPSCM_we_a_i            = we_a_i;
            MPSCM_waddr_b_i         = waddr_b_i;
            MPSCM_wdata_b_i         = wdata_b_i;
            MPSCM_we_b_i            = we_b_i;
            MPSCM_waddr_c_i         = di_intrfc_regfile.waddr_b2;
            MPSCM_wdata_c_i         = di_intrfc_regfile.wdata_b2;
            MPSCM_we_c_i            = di_intrfc_regfile.we_b2;

            //ORIG_* = 0;
            ORIG_rst_n             = 0;
            ORIG_test_en_i         = 0;
            ORIG_raddr_a_i         = 0;
            ORIG_raddr_b_i         = 0;
            ORIG_raddr_c_i         = 0;
            ORIG_raddr_d_i         = 0;
            ORIG_raddr_e_i         = 0;
            ORIG_waddr_a_i         = 0;
            ORIG_wdata_a_i         = 0;
            ORIG_we_a_i            = 0;
            ORIG_waddr_b_i         = 0;
            ORIG_wdata_b_i         = 0;
            ORIG_we_b_i            = 0;
            ORIG_waddr_c_i         = 0;
            ORIG_wdata_c_i         = 0;
            ORIG_we_c_i            = 0;

       end
    default: //ORIGINAL_REG
        begin
            //MPCSM_* = 0
            MPSCM_rst_n             = 0;
            MPSCM_test_en_i         = 0;
            MPSCM_raddr_a_i         = 0;
            MPSCM_raddr_b_i         = 0;
            MPSCM_raddr_c_i         = 0;
            MPSCM_raddr_d_i         = 0;
            MPSCM_raddr_e_i         = 0;
            MPSCM_waddr_a_i         = 0;
            MPSCM_wdata_a_i         = 0;
            MPSCM_we_a_i            = 0;
            MPSCM_waddr_b_i         = 0;
            MPSCM_wdata_b_i         = 0;
            MPSCM_we_b_i            = 0;
            MPSCM_waddr_c_i         = 0;
            MPSCM_wdata_c_i         = 0;
            MPSCM_we_c_i            = 0;

            ORIG_rst_n             = rst_n;
            ORIG_test_en_i         = test_en_i;
            ORIG_raddr_a_i         = raddr_a_i;
            ORIG_raddr_b_i         = raddr_b_i;
            ORIG_raddr_c_i         = raddr_c_i;
            ORIG_raddr_d_i         = di_intrfc_regfile.raddr_a2;
            ORIG_raddr_e_i         = di_intrfc_regfile.raddr_b2;
            ORIG_waddr_a_i         = waddr_a_i;
            ORIG_wdata_a_i         = wdata_a_i;
            ORIG_we_a_i            = we_a_i;
            ORIG_waddr_b_i         = waddr_b_i;
            ORIG_wdata_b_i         = wdata_b_i;
            ORIG_we_b_i            = we_b_i;
            ORIG_waddr_c_i         = di_intrfc_regfile.waddr_b2;
            ORIG_wdata_c_i         = di_intrfc_regfile.wdata_b2;
            ORIG_we_c_i            = di_intrfc_regfile.we_b2;
        end
    endcase
  end

  always @(*)
  begin : mux
    case (reg_mux_i_e)
    MPSCM:
      begin
        rdata_a_o =                     MPSCM_rdata_a_o;
        rdata_b_o =                     MPSCM_rdata_b_o;
        rdata_c_o =                     MPSCM_rdata_c_o;
        di_intrfc_regfile.rdata_a2 =    MPSCM_rdata_d_o;
        di_intrfc_regfile.rdata_b2 =    MPSCM_rdata_e_o;
      end
    default: //ORIGINAL_REG
      begin
        rdata_a_o =                     ORIG_rdata_a_o;
        rdata_b_o =                     ORIG_rdata_b_o;
        rdata_c_o =                     ORIG_rdata_c_o;
        di_intrfc_regfile.rdata_a2 =    ORIG_rdata_d_o;
        di_intrfc_regfile.rdata_b2 =    ORIG_rdata_e_o;
      end
    endcase
  end

  `ifndef ALTERA
   Xriscv_register_file_MPSCM_wrap
   #(
      .ADDR_WIDTH ( ADDR_WIDTH          ),
      .DATA_WIDTH ( DATA_WIDTH          )
   )
   riscv_register_file_MPSCM_wrap_i
   (
      .clk        ( MPSCM_clk           ),
      .rst_n      ( MPSCM_rst_n         ),
      .test_en_i  ( MPSCM_test_en_i     ),
      .raddr_a_i  ( MPSCM_raddr_a_i     ),
      .rdata_a_o  ( MPSCM_rdata_a_o     ),
      .raddr_b_i  ( MPSCM_raddr_b_i     ),
      .rdata_b_o  ( MPSCM_rdata_b_o     ),
      .raddr_c_i  ( MPSCM_raddr_c_i     ),
      .rdata_c_o  ( MPSCM_rdata_c_o     ),
      .waddr_a_i  ( MPSCM_waddr_a_i     ),
      .wdata_a_i  ( MPSCM_wdata_a_i     ),
      .we_a_i     ( MPSCM_we_a_i        ),
      .waddr_b_i  ( MPSCM_waddr_b_i     ),
      .wdata_b_i  ( MPSCM_wdata_b_i     ),
      .we_b_i     ( MPSCM_we_b_i        )
      `ifdef HAMSA_DIX  // Dual-Issue Logic ports connection
      , .raddr_d_i  ( MPSCM_raddr_d_i     ),
        .rdata_d_o  ( MPSCM_rdata_d_o     ),
        .raddr_e_i  ( MPSCM_raddr_e_i     ),
        .rdata_e_o  ( MPSCM_rdata_e_o     ),
        .waddr_c_i  ( MPSCM_waddr_c_i     ),
        .wdata_c_i  ( MPSCM_wdata_c_i     ),
        .we_c_i     ( MPSCM_we_c_i        )
      `endif
   );
   `endif

  Xriscv_register_file
   #(
      .ADDR_WIDTH ( ADDR_WIDTH         ),
      .DATA_WIDTH ( DATA_WIDTH         ),
      .FPU        ( FPU                ),
      .Zfinx      ( Zfinx              )
   )
   Xriscv_register_file_i
   (
      .clk        ( ORIG_clk           ),
      .rst_n      ( ORIG_rst_n         ),
      .test_en_i  ( ORIG_test_en_i     ),
      .raddr_a_i  ( raddr_a_i          ),
      .rdata_a_o  ( ORIG_rdata_a_o     ),
      .raddr_b_i  ( ORIG_raddr_b_i     ),
      .rdata_b_o  ( ORIG_rdata_b_o     ),
      .raddr_c_i  ( ORIG_raddr_c_i     ),
      .rdata_c_o  ( ORIG_rdata_c_o     ),
      .waddr_a_i  ( ORIG_waddr_a_i     ),
      .wdata_a_i  ( ORIG_wdata_a_i     ),
      .we_a_i     ( ORIG_we_a_i        ),
      .waddr_b_i  ( ORIG_waddr_b_i     ),
      .wdata_b_i  ( ORIG_wdata_b_i     ),
      .we_b_i     ( ORIG_we_b_i        )
      `ifdef HAMSA_DIX  // Dual-Issue Logic ports connection
      , .raddr_d_i  ( ORIG_raddr_d_i     ),
        .rdata_d_o  ( ORIG_rdata_d_o     ),
        .raddr_e_i  ( ORIG_raddr_e_i     ),
        .rdata_e_o  ( ORIG_rdata_e_o     ),
        .waddr_c_i  ( ORIG_waddr_c_i     ),
        .wdata_c_i  ( ORIG_wdata_c_i     ),
        .we_c_i     ( ORIG_we_c_i        )
      `endif
   );

endmodule
