/* verilog_memcomp Version: c0.3.2-EAC */
/* common_memcomp Version: 4.0.5-EAC */
/* lang compiler Version: 4.1.6-EAC2 Oct 30 2012 16:32:37 */
//
//       CONFIDENTIAL AND PROPRIETARY SOFTWARE OF ARM PHYSICAL IP, INC.
//      
//       Copyright (c) 1993 - 2020 ARM Physical IP, Inc.  All Rights Reserved.
//      
//       Use of this Software is subject to the terms and conditions of the
//       applicable license agreement with ARM Physical IP, Inc.
//       In addition, this Software is protected by patents, copyright law 
//       and international treaties.
//      
//       The copyright notice(s) in this Software does not indicate actual or
//       intended publication of this Software.
//
//      Verilog model for Synchronous Single-Port Ram
//
//       Instance Name:              ARM_SPSRAM_64X4096_M8_MEM
//       Words:                      4096
//       Bits:                       64
//       Mux:                        8
//       Drive:                      6
//       Write Mask:                 On
//       Write Thru:                 Off
//       Extra Margin Adjustment:    On
//       Redundant Columns:          2
//       Test Muxes                  On
//       Power Gating:               Off
//       Retention:                  On
//       Pipeline:                   Off
//       Read Disturb Test:	        Off
//       
//       Creation Date:  Mon Feb 17 00:25:54 2020
//       Version: 	r0p0
//
//      Modeling Assumptions: This model supports full gate level simulation
//          including proper x-handling and timing check behavior.  Unit
//          delay timing is included in the model. Back-annotation of SDF
//          (v3.0 or v2.1) is supported.  SDF can be created utilyzing the delay
//          calculation views provided with this generator and supported
//          delay calculators.  All buses are modeled [MSB:LSB].  All 
//          ports are padded with Verilog primitives.
//
//      Modeling Limitations: None.
//
//      Known Bugs: None.
//
//      Known Work Arounds: N/A
//
`timescale 1 ns/1 ps
`define ARM_MEM_PROP 1.000
`define ARM_MEM_RETAIN 1.000
`define ARM_MEM_PERIOD 3.000
`define ARM_MEM_WIDTH 1.000
`define ARM_MEM_SETUP 1.000
`define ARM_MEM_HOLD 0.500
`define ARM_MEM_COLLISION 3.000
// If ARM_HVM_MODEL is defined at Simulator Command Line, it Selects the Hierarchical Verilog Model
`ifdef ARM_HVM_MODEL


module datapath_latch_ARM_SPSRAM_64X4096_M8_MEM (CLK,Q_update,D_update,SE,SI,D,DFTRAMBYP,mem_path,XQ,Q);
	input CLK,Q_update,D_update,SE,SI,D,DFTRAMBYP,mem_path,XQ;
	output Q;

	reg    D_int;
	reg    Q;

   //  Model PHI2 portion
   always @(CLK or SE or SI or D) begin
      if (CLK === 1'b0) begin
         if (SE===1'b1)
           D_int=SI;
         else if (SE===1'bx)
           D_int=1'bx;
         else
           D_int=D;
      end
   end

   // model output side of RAM latch
   always @(posedge Q_update or posedge D_update or mem_path or posedge XQ) begin
      #0;
      if (XQ===1'b0) begin
         if (DFTRAMBYP===1'b1)
           Q=D_int;
         else
           Q=mem_path;
      end
      else
        Q=1'bx;
   end
endmodule // datapath_latch_ARM_SPSRAM_64X4096_M8_MEM

// If ARM_UD_MODEL is defined at Simulator Command Line, it Selects the Fast Functional Model
`ifdef ARM_UD_MODEL

// Following parameter Values can be overridden at Simulator Command Line.

// ARM_UD_DP Defines the delay through Data Paths, for Memory Models it represents BIST MUX output delays.
`ifdef ARM_UD_DP
`else
`define ARM_UD_DP #0.001
`endif
// ARM_UD_CP Defines the delay through Clock Path Cells, for Memory Models it is not used.
`ifdef ARM_UD_CP
`else
`define ARM_UD_CP
`endif
// ARM_UD_SEQ Defines the delay through the Memory, for Memory Models it is used for CLK->Q delays.
`ifdef ARM_UD_SEQ
`else
`define ARM_UD_SEQ #0.01
`endif

`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module ARM_SPSRAM_64X4096_M8_MEM (VDD, VDDP, VSS, CENY, WENY, AY, GWENY, Q, SO, CLK,
    CEN, WEN, A, D, EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE,
    DFTRAMBYP);
`else
module ARM_SPSRAM_64X4096_M8_MEM (CENY, WENY, AY, GWENY, Q, SO, CLK, CEN, WEN, A, D,
    EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE, DFTRAMBYP);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 64;
  parameter WORDS = 4096;
  parameter MUX = 8;
  parameter MEM_WIDTH = 512; // redun block size 8, 256 on left, 256 on right
  parameter MEM_HEIGHT = 512;
  parameter WP_SIZE = 1 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 0;

  output  CENY;
  output [63:0] WENY;
  output [11:0] AY;
  output  GWENY;
  output [63:0] Q;
  output [1:0] SO;
  input  CLK;
  input  CEN;
  input [63:0] WEN;
  input [11:0] A;
  input [63:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  TEN;
  input  TCEN;
  input [63:0] TWEN;
  input [11:0] TA;
  input [63:0] TD;
  input  GWEN;
  input  TGWEN;
  input  RET1N;
  input [1:0] SI;
  input  SE;
  input  DFTRAMBYP;
`ifdef POWER_PINS
  inout VDD;
  inout VDDP;
  inout VSS;
`endif

  reg pre_charge_st;
  integer row_address;
  integer mux_address;
  initial row_address = 0;
  initial mux_address = 0;
  reg [511:0] mem [0:511];
  reg [511:0] row, row_t;
  reg LAST_CLK;
  reg [511:0] row_mask;
  reg [511:0] new_data;
  reg [511:0] data_out;
  reg [63:0] readLatch0;
  reg [63:0] shifted_readLatch0;
  reg  read_mux_sel0_p2;
  wire [63:0] Q_int;
  reg XQ, Q_update;
  reg XD_sh, D_sh_update;
  wire [63:0] D_int_bmux;
  reg [63:0] mem_path;
  reg [63:0] writeEnable;
  reg clk0_int;

  wire  CENY_;
  wire [63:0] WENY_;
  wire [11:0] AY_;
  wire  GWENY_;
  wire [63:0] Q_;
  wire [1:0] SO_;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire [63:0] WEN_;
  reg [63:0] WEN_int;
  wire [11:0] A_;
  reg [11:0] A_int;
  wire [63:0] D_;
  reg [63:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  TEN_;
  reg  TEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire [63:0] TWEN_;
  reg [63:0] TWEN_int;
  wire [11:0] TA_;
  reg [11:0] TA_int;
  wire [63:0] TD_;
  reg [63:0] TD_int;
  wire  GWEN_;
  reg  GWEN_int;
  wire  TGWEN_;
  reg  TGWEN_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire [1:0] SI_;
  wire [1:0] SI_int;
  wire  SE_;
  reg  SE_int;
  wire  DFTRAMBYP_;
  reg  DFTRAMBYP_int;
  reg  DFTRAMBYP_p2;

  assign CENY = CENY_; 
  assign WENY[0] = WENY_[0]; 
  assign WENY[1] = WENY_[1]; 
  assign WENY[2] = WENY_[2]; 
  assign WENY[3] = WENY_[3]; 
  assign WENY[4] = WENY_[4]; 
  assign WENY[5] = WENY_[5]; 
  assign WENY[6] = WENY_[6]; 
  assign WENY[7] = WENY_[7]; 
  assign WENY[8] = WENY_[8]; 
  assign WENY[9] = WENY_[9]; 
  assign WENY[10] = WENY_[10]; 
  assign WENY[11] = WENY_[11]; 
  assign WENY[12] = WENY_[12]; 
  assign WENY[13] = WENY_[13]; 
  assign WENY[14] = WENY_[14]; 
  assign WENY[15] = WENY_[15]; 
  assign WENY[16] = WENY_[16]; 
  assign WENY[17] = WENY_[17]; 
  assign WENY[18] = WENY_[18]; 
  assign WENY[19] = WENY_[19]; 
  assign WENY[20] = WENY_[20]; 
  assign WENY[21] = WENY_[21]; 
  assign WENY[22] = WENY_[22]; 
  assign WENY[23] = WENY_[23]; 
  assign WENY[24] = WENY_[24]; 
  assign WENY[25] = WENY_[25]; 
  assign WENY[26] = WENY_[26]; 
  assign WENY[27] = WENY_[27]; 
  assign WENY[28] = WENY_[28]; 
  assign WENY[29] = WENY_[29]; 
  assign WENY[30] = WENY_[30]; 
  assign WENY[31] = WENY_[31]; 
  assign WENY[32] = WENY_[32]; 
  assign WENY[33] = WENY_[33]; 
  assign WENY[34] = WENY_[34]; 
  assign WENY[35] = WENY_[35]; 
  assign WENY[36] = WENY_[36]; 
  assign WENY[37] = WENY_[37]; 
  assign WENY[38] = WENY_[38]; 
  assign WENY[39] = WENY_[39]; 
  assign WENY[40] = WENY_[40]; 
  assign WENY[41] = WENY_[41]; 
  assign WENY[42] = WENY_[42]; 
  assign WENY[43] = WENY_[43]; 
  assign WENY[44] = WENY_[44]; 
  assign WENY[45] = WENY_[45]; 
  assign WENY[46] = WENY_[46]; 
  assign WENY[47] = WENY_[47]; 
  assign WENY[48] = WENY_[48]; 
  assign WENY[49] = WENY_[49]; 
  assign WENY[50] = WENY_[50]; 
  assign WENY[51] = WENY_[51]; 
  assign WENY[52] = WENY_[52]; 
  assign WENY[53] = WENY_[53]; 
  assign WENY[54] = WENY_[54]; 
  assign WENY[55] = WENY_[55]; 
  assign WENY[56] = WENY_[56]; 
  assign WENY[57] = WENY_[57]; 
  assign WENY[58] = WENY_[58]; 
  assign WENY[59] = WENY_[59]; 
  assign WENY[60] = WENY_[60]; 
  assign WENY[61] = WENY_[61]; 
  assign WENY[62] = WENY_[62]; 
  assign WENY[63] = WENY_[63]; 
  assign AY[0] = AY_[0]; 
  assign AY[1] = AY_[1]; 
  assign AY[2] = AY_[2]; 
  assign AY[3] = AY_[3]; 
  assign AY[4] = AY_[4]; 
  assign AY[5] = AY_[5]; 
  assign AY[6] = AY_[6]; 
  assign AY[7] = AY_[7]; 
  assign AY[8] = AY_[8]; 
  assign AY[9] = AY_[9]; 
  assign AY[10] = AY_[10]; 
  assign AY[11] = AY_[11]; 
  assign GWENY = GWENY_; 
  assign Q[0] = Q_[0]; 
  assign Q[1] = Q_[1]; 
  assign Q[2] = Q_[2]; 
  assign Q[3] = Q_[3]; 
  assign Q[4] = Q_[4]; 
  assign Q[5] = Q_[5]; 
  assign Q[6] = Q_[6]; 
  assign Q[7] = Q_[7]; 
  assign Q[8] = Q_[8]; 
  assign Q[9] = Q_[9]; 
  assign Q[10] = Q_[10]; 
  assign Q[11] = Q_[11]; 
  assign Q[12] = Q_[12]; 
  assign Q[13] = Q_[13]; 
  assign Q[14] = Q_[14]; 
  assign Q[15] = Q_[15]; 
  assign Q[16] = Q_[16]; 
  assign Q[17] = Q_[17]; 
  assign Q[18] = Q_[18]; 
  assign Q[19] = Q_[19]; 
  assign Q[20] = Q_[20]; 
  assign Q[21] = Q_[21]; 
  assign Q[22] = Q_[22]; 
  assign Q[23] = Q_[23]; 
  assign Q[24] = Q_[24]; 
  assign Q[25] = Q_[25]; 
  assign Q[26] = Q_[26]; 
  assign Q[27] = Q_[27]; 
  assign Q[28] = Q_[28]; 
  assign Q[29] = Q_[29]; 
  assign Q[30] = Q_[30]; 
  assign Q[31] = Q_[31]; 
  assign Q[32] = Q_[32]; 
  assign Q[33] = Q_[33]; 
  assign Q[34] = Q_[34]; 
  assign Q[35] = Q_[35]; 
  assign Q[36] = Q_[36]; 
  assign Q[37] = Q_[37]; 
  assign Q[38] = Q_[38]; 
  assign Q[39] = Q_[39]; 
  assign Q[40] = Q_[40]; 
  assign Q[41] = Q_[41]; 
  assign Q[42] = Q_[42]; 
  assign Q[43] = Q_[43]; 
  assign Q[44] = Q_[44]; 
  assign Q[45] = Q_[45]; 
  assign Q[46] = Q_[46]; 
  assign Q[47] = Q_[47]; 
  assign Q[48] = Q_[48]; 
  assign Q[49] = Q_[49]; 
  assign Q[50] = Q_[50]; 
  assign Q[51] = Q_[51]; 
  assign Q[52] = Q_[52]; 
  assign Q[53] = Q_[53]; 
  assign Q[54] = Q_[54]; 
  assign Q[55] = Q_[55]; 
  assign Q[56] = Q_[56]; 
  assign Q[57] = Q_[57]; 
  assign Q[58] = Q_[58]; 
  assign Q[59] = Q_[59]; 
  assign Q[60] = Q_[60]; 
  assign Q[61] = Q_[61]; 
  assign Q[62] = Q_[62]; 
  assign Q[63] = Q_[63]; 
  assign SO[0] = SO_[0]; 
  assign SO[1] = SO_[1]; 
  assign CLK_ = CLK;
  assign CEN_ = CEN;
  assign WEN_[0] = WEN[0];
  assign WEN_[1] = WEN[1];
  assign WEN_[2] = WEN[2];
  assign WEN_[3] = WEN[3];
  assign WEN_[4] = WEN[4];
  assign WEN_[5] = WEN[5];
  assign WEN_[6] = WEN[6];
  assign WEN_[7] = WEN[7];
  assign WEN_[8] = WEN[8];
  assign WEN_[9] = WEN[9];
  assign WEN_[10] = WEN[10];
  assign WEN_[11] = WEN[11];
  assign WEN_[12] = WEN[12];
  assign WEN_[13] = WEN[13];
  assign WEN_[14] = WEN[14];
  assign WEN_[15] = WEN[15];
  assign WEN_[16] = WEN[16];
  assign WEN_[17] = WEN[17];
  assign WEN_[18] = WEN[18];
  assign WEN_[19] = WEN[19];
  assign WEN_[20] = WEN[20];
  assign WEN_[21] = WEN[21];
  assign WEN_[22] = WEN[22];
  assign WEN_[23] = WEN[23];
  assign WEN_[24] = WEN[24];
  assign WEN_[25] = WEN[25];
  assign WEN_[26] = WEN[26];
  assign WEN_[27] = WEN[27];
  assign WEN_[28] = WEN[28];
  assign WEN_[29] = WEN[29];
  assign WEN_[30] = WEN[30];
  assign WEN_[31] = WEN[31];
  assign WEN_[32] = WEN[32];
  assign WEN_[33] = WEN[33];
  assign WEN_[34] = WEN[34];
  assign WEN_[35] = WEN[35];
  assign WEN_[36] = WEN[36];
  assign WEN_[37] = WEN[37];
  assign WEN_[38] = WEN[38];
  assign WEN_[39] = WEN[39];
  assign WEN_[40] = WEN[40];
  assign WEN_[41] = WEN[41];
  assign WEN_[42] = WEN[42];
  assign WEN_[43] = WEN[43];
  assign WEN_[44] = WEN[44];
  assign WEN_[45] = WEN[45];
  assign WEN_[46] = WEN[46];
  assign WEN_[47] = WEN[47];
  assign WEN_[48] = WEN[48];
  assign WEN_[49] = WEN[49];
  assign WEN_[50] = WEN[50];
  assign WEN_[51] = WEN[51];
  assign WEN_[52] = WEN[52];
  assign WEN_[53] = WEN[53];
  assign WEN_[54] = WEN[54];
  assign WEN_[55] = WEN[55];
  assign WEN_[56] = WEN[56];
  assign WEN_[57] = WEN[57];
  assign WEN_[58] = WEN[58];
  assign WEN_[59] = WEN[59];
  assign WEN_[60] = WEN[60];
  assign WEN_[61] = WEN[61];
  assign WEN_[62] = WEN[62];
  assign WEN_[63] = WEN[63];
  assign A_[0] = A[0];
  assign A_[1] = A[1];
  assign A_[2] = A[2];
  assign A_[3] = A[3];
  assign A_[4] = A[4];
  assign A_[5] = A[5];
  assign A_[6] = A[6];
  assign A_[7] = A[7];
  assign A_[8] = A[8];
  assign A_[9] = A[9];
  assign A_[10] = A[10];
  assign A_[11] = A[11];
  assign D_[0] = D[0];
  assign D_[1] = D[1];
  assign D_[2] = D[2];
  assign D_[3] = D[3];
  assign D_[4] = D[4];
  assign D_[5] = D[5];
  assign D_[6] = D[6];
  assign D_[7] = D[7];
  assign D_[8] = D[8];
  assign D_[9] = D[9];
  assign D_[10] = D[10];
  assign D_[11] = D[11];
  assign D_[12] = D[12];
  assign D_[13] = D[13];
  assign D_[14] = D[14];
  assign D_[15] = D[15];
  assign D_[16] = D[16];
  assign D_[17] = D[17];
  assign D_[18] = D[18];
  assign D_[19] = D[19];
  assign D_[20] = D[20];
  assign D_[21] = D[21];
  assign D_[22] = D[22];
  assign D_[23] = D[23];
  assign D_[24] = D[24];
  assign D_[25] = D[25];
  assign D_[26] = D[26];
  assign D_[27] = D[27];
  assign D_[28] = D[28];
  assign D_[29] = D[29];
  assign D_[30] = D[30];
  assign D_[31] = D[31];
  assign D_[32] = D[32];
  assign D_[33] = D[33];
  assign D_[34] = D[34];
  assign D_[35] = D[35];
  assign D_[36] = D[36];
  assign D_[37] = D[37];
  assign D_[38] = D[38];
  assign D_[39] = D[39];
  assign D_[40] = D[40];
  assign D_[41] = D[41];
  assign D_[42] = D[42];
  assign D_[43] = D[43];
  assign D_[44] = D[44];
  assign D_[45] = D[45];
  assign D_[46] = D[46];
  assign D_[47] = D[47];
  assign D_[48] = D[48];
  assign D_[49] = D[49];
  assign D_[50] = D[50];
  assign D_[51] = D[51];
  assign D_[52] = D[52];
  assign D_[53] = D[53];
  assign D_[54] = D[54];
  assign D_[55] = D[55];
  assign D_[56] = D[56];
  assign D_[57] = D[57];
  assign D_[58] = D[58];
  assign D_[59] = D[59];
  assign D_[60] = D[60];
  assign D_[61] = D[61];
  assign D_[62] = D[62];
  assign D_[63] = D[63];
  assign EMA_[0] = EMA[0];
  assign EMA_[1] = EMA[1];
  assign EMA_[2] = EMA[2];
  assign EMAW_[0] = EMAW[0];
  assign EMAW_[1] = EMAW[1];
  assign TEN_ = TEN;
  assign TCEN_ = TCEN;
  assign TWEN_[0] = TWEN[0];
  assign TWEN_[1] = TWEN[1];
  assign TWEN_[2] = TWEN[2];
  assign TWEN_[3] = TWEN[3];
  assign TWEN_[4] = TWEN[4];
  assign TWEN_[5] = TWEN[5];
  assign TWEN_[6] = TWEN[6];
  assign TWEN_[7] = TWEN[7];
  assign TWEN_[8] = TWEN[8];
  assign TWEN_[9] = TWEN[9];
  assign TWEN_[10] = TWEN[10];
  assign TWEN_[11] = TWEN[11];
  assign TWEN_[12] = TWEN[12];
  assign TWEN_[13] = TWEN[13];
  assign TWEN_[14] = TWEN[14];
  assign TWEN_[15] = TWEN[15];
  assign TWEN_[16] = TWEN[16];
  assign TWEN_[17] = TWEN[17];
  assign TWEN_[18] = TWEN[18];
  assign TWEN_[19] = TWEN[19];
  assign TWEN_[20] = TWEN[20];
  assign TWEN_[21] = TWEN[21];
  assign TWEN_[22] = TWEN[22];
  assign TWEN_[23] = TWEN[23];
  assign TWEN_[24] = TWEN[24];
  assign TWEN_[25] = TWEN[25];
  assign TWEN_[26] = TWEN[26];
  assign TWEN_[27] = TWEN[27];
  assign TWEN_[28] = TWEN[28];
  assign TWEN_[29] = TWEN[29];
  assign TWEN_[30] = TWEN[30];
  assign TWEN_[31] = TWEN[31];
  assign TWEN_[32] = TWEN[32];
  assign TWEN_[33] = TWEN[33];
  assign TWEN_[34] = TWEN[34];
  assign TWEN_[35] = TWEN[35];
  assign TWEN_[36] = TWEN[36];
  assign TWEN_[37] = TWEN[37];
  assign TWEN_[38] = TWEN[38];
  assign TWEN_[39] = TWEN[39];
  assign TWEN_[40] = TWEN[40];
  assign TWEN_[41] = TWEN[41];
  assign TWEN_[42] = TWEN[42];
  assign TWEN_[43] = TWEN[43];
  assign TWEN_[44] = TWEN[44];
  assign TWEN_[45] = TWEN[45];
  assign TWEN_[46] = TWEN[46];
  assign TWEN_[47] = TWEN[47];
  assign TWEN_[48] = TWEN[48];
  assign TWEN_[49] = TWEN[49];
  assign TWEN_[50] = TWEN[50];
  assign TWEN_[51] = TWEN[51];
  assign TWEN_[52] = TWEN[52];
  assign TWEN_[53] = TWEN[53];
  assign TWEN_[54] = TWEN[54];
  assign TWEN_[55] = TWEN[55];
  assign TWEN_[56] = TWEN[56];
  assign TWEN_[57] = TWEN[57];
  assign TWEN_[58] = TWEN[58];
  assign TWEN_[59] = TWEN[59];
  assign TWEN_[60] = TWEN[60];
  assign TWEN_[61] = TWEN[61];
  assign TWEN_[62] = TWEN[62];
  assign TWEN_[63] = TWEN[63];
  assign TA_[0] = TA[0];
  assign TA_[1] = TA[1];
  assign TA_[2] = TA[2];
  assign TA_[3] = TA[3];
  assign TA_[4] = TA[4];
  assign TA_[5] = TA[5];
  assign TA_[6] = TA[6];
  assign TA_[7] = TA[7];
  assign TA_[8] = TA[8];
  assign TA_[9] = TA[9];
  assign TA_[10] = TA[10];
  assign TA_[11] = TA[11];
  assign TD_[0] = TD[0];
  assign TD_[1] = TD[1];
  assign TD_[2] = TD[2];
  assign TD_[3] = TD[3];
  assign TD_[4] = TD[4];
  assign TD_[5] = TD[5];
  assign TD_[6] = TD[6];
  assign TD_[7] = TD[7];
  assign TD_[8] = TD[8];
  assign TD_[9] = TD[9];
  assign TD_[10] = TD[10];
  assign TD_[11] = TD[11];
  assign TD_[12] = TD[12];
  assign TD_[13] = TD[13];
  assign TD_[14] = TD[14];
  assign TD_[15] = TD[15];
  assign TD_[16] = TD[16];
  assign TD_[17] = TD[17];
  assign TD_[18] = TD[18];
  assign TD_[19] = TD[19];
  assign TD_[20] = TD[20];
  assign TD_[21] = TD[21];
  assign TD_[22] = TD[22];
  assign TD_[23] = TD[23];
  assign TD_[24] = TD[24];
  assign TD_[25] = TD[25];
  assign TD_[26] = TD[26];
  assign TD_[27] = TD[27];
  assign TD_[28] = TD[28];
  assign TD_[29] = TD[29];
  assign TD_[30] = TD[30];
  assign TD_[31] = TD[31];
  assign TD_[32] = TD[32];
  assign TD_[33] = TD[33];
  assign TD_[34] = TD[34];
  assign TD_[35] = TD[35];
  assign TD_[36] = TD[36];
  assign TD_[37] = TD[37];
  assign TD_[38] = TD[38];
  assign TD_[39] = TD[39];
  assign TD_[40] = TD[40];
  assign TD_[41] = TD[41];
  assign TD_[42] = TD[42];
  assign TD_[43] = TD[43];
  assign TD_[44] = TD[44];
  assign TD_[45] = TD[45];
  assign TD_[46] = TD[46];
  assign TD_[47] = TD[47];
  assign TD_[48] = TD[48];
  assign TD_[49] = TD[49];
  assign TD_[50] = TD[50];
  assign TD_[51] = TD[51];
  assign TD_[52] = TD[52];
  assign TD_[53] = TD[53];
  assign TD_[54] = TD[54];
  assign TD_[55] = TD[55];
  assign TD_[56] = TD[56];
  assign TD_[57] = TD[57];
  assign TD_[58] = TD[58];
  assign TD_[59] = TD[59];
  assign TD_[60] = TD[60];
  assign TD_[61] = TD[61];
  assign TD_[62] = TD[62];
  assign TD_[63] = TD[63];
  assign GWEN_ = GWEN;
  assign TGWEN_ = TGWEN;
  assign RET1N_ = RET1N;
  assign SI_[0] = SI[0];
  assign SI_[1] = SI[1];
  assign SE_ = SE;
  assign DFTRAMBYP_ = DFTRAMBYP;

  assign `ARM_UD_DP CENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? CEN_ : TCEN_)) : 1'bx;
  assign `ARM_UD_DP WENY_ = (RET1N_ | pre_charge_st) ? ({64{DFTRAMBYP_}} & (TEN_ ? WEN_ : TWEN_)) : {64{1'bx}};
  assign `ARM_UD_DP AY_ = (RET1N_ | pre_charge_st) ? ({12{DFTRAMBYP_}} & (TEN_ ? A_ : TA_)) : {12{1'bx}};
  assign `ARM_UD_DP GWENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? GWEN_ : TGWEN_)) : 1'bx;
  assign `ARM_UD_SEQ Q_ = (RET1N_ | pre_charge_st) ? ((Q_int)) : {64{1'bx}};
  assign `ARM_UD_DP SO_ = (RET1N_ | pre_charge_st) ? ({Q_[32], Q_[31]}) : {2{1'bx}};

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial begin
    #0;
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
  end
`endif
  always @ (EMA_) begin
  	if(EMA_ < 2) 
   	$display("Warning: Set Value for EMA doesn't match Default value 2 in %m at %0t", $time);
  end
  always @ (EMAW_) begin
  	if(EMAW_ < 0) 
   	$display("Warning: Set Value for EMAW doesn't match Default value 0 in %m at %0t", $time);
  end

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval===1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction

  function isBit1;
    input bitval;
    begin
      isBit1 = ( bitval===1'b1 ) ? 1'b1 : 1'b0;
    end
  endfunction



  task readWrite;
  begin
    if (GWEN_int !== 1'b1 && DFTRAMBYP_int=== 1'b0 && SE_int === 1'bx) begin
      failedWrite(0);
    end else if (DFTRAMBYP_int=== 1'b0 && SE_int === 1'b1) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_int === 1'b0 && (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{(EMA_int & isBit1(DFTRAMBYP_int)), (EMAW_int & isBit1(DFTRAMBYP_int))} === 1'bx) begin
        XQ = 1'b1; Q_update = 1'b1;
    end else if (^{(CEN_int & !isBit1(DFTRAMBYP_int)), EMA_int, EMAW_int, RET1N_int} === 1'bx) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0) && DFTRAMBYP_int === 1'b0) begin
        XQ = GWEN_int !== 1'b1 ? 1'b0 : 1'b1; Q_update = GWEN_int !== 1'b1 ? 1'b0 : 1'b1;
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx && DFTRAMBYP_int === 1'b0) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1) begin
      if(isBitX(DFTRAMBYP_int) || isBitX(SE_int))
        D_int = {64{1'bx}};

      mux_address = (A_int & 3'b111);
      row_address = (A_int >> 3);
      if (DFTRAMBYP_int !== 1'b1) begin
      if (row_address > 511)
        row = {512{1'bx}};
      else
        row = mem[row_address];
      end
      if( (isBitX(GWEN_int) && DFTRAMBYP_int!==1) || isBitX(DFTRAMBYP_int) ) begin
        writeEnable = {64{1'bx}};
        D_int = {64{1'bx}};
      end else
          writeEnable = ~ ( {64{GWEN_int}} | {WEN_int[63], WEN_int[62], WEN_int[61],
          WEN_int[60], WEN_int[59], WEN_int[58], WEN_int[57], WEN_int[56], WEN_int[55],
          WEN_int[54], WEN_int[53], WEN_int[52], WEN_int[51], WEN_int[50], WEN_int[49],
          WEN_int[48], WEN_int[47], WEN_int[46], WEN_int[45], WEN_int[44], WEN_int[43],
          WEN_int[42], WEN_int[41], WEN_int[40], WEN_int[39], WEN_int[38], WEN_int[37],
          WEN_int[36], WEN_int[35], WEN_int[34], WEN_int[33], WEN_int[32], WEN_int[31],
          WEN_int[30], WEN_int[29], WEN_int[28], WEN_int[27], WEN_int[26], WEN_int[25],
          WEN_int[24], WEN_int[23], WEN_int[22], WEN_int[21], WEN_int[20], WEN_int[19],
          WEN_int[18], WEN_int[17], WEN_int[16], WEN_int[15], WEN_int[14], WEN_int[13],
          WEN_int[12], WEN_int[11], WEN_int[10], WEN_int[9], WEN_int[8], WEN_int[7],
          WEN_int[6], WEN_int[5], WEN_int[4], WEN_int[3], WEN_int[2], WEN_int[1], WEN_int[0]});
      if (GWEN_int !== 1'b1 || DFTRAMBYP_int === 1'b1 || DFTRAMBYP_int === 1'bx) begin
        row_mask =  ( {7'b0000000, writeEnable[63], 7'b0000000, writeEnable[62], 7'b0000000, writeEnable[61],
          7'b0000000, writeEnable[60], 7'b0000000, writeEnable[59], 7'b0000000, writeEnable[58],
          7'b0000000, writeEnable[57], 7'b0000000, writeEnable[56], 7'b0000000, writeEnable[55],
          7'b0000000, writeEnable[54], 7'b0000000, writeEnable[53], 7'b0000000, writeEnable[52],
          7'b0000000, writeEnable[51], 7'b0000000, writeEnable[50], 7'b0000000, writeEnable[49],
          7'b0000000, writeEnable[48], 7'b0000000, writeEnable[47], 7'b0000000, writeEnable[46],
          7'b0000000, writeEnable[45], 7'b0000000, writeEnable[44], 7'b0000000, writeEnable[43],
          7'b0000000, writeEnable[42], 7'b0000000, writeEnable[41], 7'b0000000, writeEnable[40],
          7'b0000000, writeEnable[39], 7'b0000000, writeEnable[38], 7'b0000000, writeEnable[37],
          7'b0000000, writeEnable[36], 7'b0000000, writeEnable[35], 7'b0000000, writeEnable[34],
          7'b0000000, writeEnable[33], 7'b0000000, writeEnable[32], 7'b0000000, writeEnable[31],
          7'b0000000, writeEnable[30], 7'b0000000, writeEnable[29], 7'b0000000, writeEnable[28],
          7'b0000000, writeEnable[27], 7'b0000000, writeEnable[26], 7'b0000000, writeEnable[25],
          7'b0000000, writeEnable[24], 7'b0000000, writeEnable[23], 7'b0000000, writeEnable[22],
          7'b0000000, writeEnable[21], 7'b0000000, writeEnable[20], 7'b0000000, writeEnable[19],
          7'b0000000, writeEnable[18], 7'b0000000, writeEnable[17], 7'b0000000, writeEnable[16],
          7'b0000000, writeEnable[15], 7'b0000000, writeEnable[14], 7'b0000000, writeEnable[13],
          7'b0000000, writeEnable[12], 7'b0000000, writeEnable[11], 7'b0000000, writeEnable[10],
          7'b0000000, writeEnable[9], 7'b0000000, writeEnable[8], 7'b0000000, writeEnable[7],
          7'b0000000, writeEnable[6], 7'b0000000, writeEnable[5], 7'b0000000, writeEnable[4],
          7'b0000000, writeEnable[3], 7'b0000000, writeEnable[2], 7'b0000000, writeEnable[1],
          7'b0000000, writeEnable[0]} << mux_address);
        new_data =  ( {7'b0000000, D_int[63], 7'b0000000, D_int[62], 7'b0000000, D_int[61],
          7'b0000000, D_int[60], 7'b0000000, D_int[59], 7'b0000000, D_int[58], 7'b0000000, D_int[57],
          7'b0000000, D_int[56], 7'b0000000, D_int[55], 7'b0000000, D_int[54], 7'b0000000, D_int[53],
          7'b0000000, D_int[52], 7'b0000000, D_int[51], 7'b0000000, D_int[50], 7'b0000000, D_int[49],
          7'b0000000, D_int[48], 7'b0000000, D_int[47], 7'b0000000, D_int[46], 7'b0000000, D_int[45],
          7'b0000000, D_int[44], 7'b0000000, D_int[43], 7'b0000000, D_int[42], 7'b0000000, D_int[41],
          7'b0000000, D_int[40], 7'b0000000, D_int[39], 7'b0000000, D_int[38], 7'b0000000, D_int[37],
          7'b0000000, D_int[36], 7'b0000000, D_int[35], 7'b0000000, D_int[34], 7'b0000000, D_int[33],
          7'b0000000, D_int[32], 7'b0000000, D_int[31], 7'b0000000, D_int[30], 7'b0000000, D_int[29],
          7'b0000000, D_int[28], 7'b0000000, D_int[27], 7'b0000000, D_int[26], 7'b0000000, D_int[25],
          7'b0000000, D_int[24], 7'b0000000, D_int[23], 7'b0000000, D_int[22], 7'b0000000, D_int[21],
          7'b0000000, D_int[20], 7'b0000000, D_int[19], 7'b0000000, D_int[18], 7'b0000000, D_int[17],
          7'b0000000, D_int[16], 7'b0000000, D_int[15], 7'b0000000, D_int[14], 7'b0000000, D_int[13],
          7'b0000000, D_int[12], 7'b0000000, D_int[11], 7'b0000000, D_int[10], 7'b0000000, D_int[9],
          7'b0000000, D_int[8], 7'b0000000, D_int[7], 7'b0000000, D_int[6], 7'b0000000, D_int[5],
          7'b0000000, D_int[4], 7'b0000000, D_int[3], 7'b0000000, D_int[2], 7'b0000000, D_int[1],
          7'b0000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        if (DFTRAMBYP_int === 1'b1 && SE_int === 1'b0) begin
        end else if (GWEN_int !== 1'b1 && DFTRAMBYP_int === 1'b1 && SE_int === 1'bx) begin
        	XQ = 1'b1; Q_update = 1'b1;
        end else begin
        mem[row_address] = row;
        end
      end else begin
        data_out = (row >> (mux_address%8));
        readLatch0 = {data_out[504], data_out[496], data_out[488], data_out[480], data_out[472],
          data_out[464], data_out[456], data_out[448], data_out[440], data_out[432],
          data_out[424], data_out[416], data_out[408], data_out[400], data_out[392],
          data_out[384], data_out[376], data_out[368], data_out[360], data_out[352],
          data_out[344], data_out[336], data_out[328], data_out[320], data_out[312],
          data_out[304], data_out[296], data_out[288], data_out[280], data_out[272],
          data_out[264], data_out[256], data_out[248], data_out[240], data_out[232],
          data_out[224], data_out[216], data_out[208], data_out[200], data_out[192],
          data_out[184], data_out[176], data_out[168], data_out[160], data_out[152],
          data_out[144], data_out[136], data_out[128], data_out[120], data_out[112],
          data_out[104], data_out[96], data_out[88], data_out[80], data_out[72], data_out[64],
          data_out[56], data_out[48], data_out[40], data_out[32], data_out[24], data_out[16],
          data_out[8], data_out[0]};
        shifted_readLatch0 = readLatch0;
        mem_path = {shifted_readLatch0[63], shifted_readLatch0[62], shifted_readLatch0[61],
          shifted_readLatch0[60], shifted_readLatch0[59], shifted_readLatch0[58], shifted_readLatch0[57],
          shifted_readLatch0[56], shifted_readLatch0[55], shifted_readLatch0[54], shifted_readLatch0[53],
          shifted_readLatch0[52], shifted_readLatch0[51], shifted_readLatch0[50], shifted_readLatch0[49],
          shifted_readLatch0[48], shifted_readLatch0[47], shifted_readLatch0[46], shifted_readLatch0[45],
          shifted_readLatch0[44], shifted_readLatch0[43], shifted_readLatch0[42], shifted_readLatch0[41],
          shifted_readLatch0[40], shifted_readLatch0[39], shifted_readLatch0[38], shifted_readLatch0[37],
          shifted_readLatch0[36], shifted_readLatch0[35], shifted_readLatch0[34], shifted_readLatch0[33],
          shifted_readLatch0[32], shifted_readLatch0[31], shifted_readLatch0[30], shifted_readLatch0[29],
          shifted_readLatch0[28], shifted_readLatch0[27], shifted_readLatch0[26], shifted_readLatch0[25],
          shifted_readLatch0[24], shifted_readLatch0[23], shifted_readLatch0[22], shifted_readLatch0[21],
          shifted_readLatch0[20], shifted_readLatch0[19], shifted_readLatch0[18], shifted_readLatch0[17],
          shifted_readLatch0[16], shifted_readLatch0[15], shifted_readLatch0[14], shifted_readLatch0[13],
          shifted_readLatch0[12], shifted_readLatch0[11], shifted_readLatch0[10], shifted_readLatch0[9],
          shifted_readLatch0[8], shifted_readLatch0[7], shifted_readLatch0[6], shifted_readLatch0[5],
          shifted_readLatch0[4], shifted_readLatch0[3], shifted_readLatch0[2], shifted_readLatch0[1],
          shifted_readLatch0[0]};
        	XQ = 1'b0; Q_update = 1'b1;
      end
      if (DFTRAMBYP_int === 1'b1) begin
        	XQ = 1'b0; Q_update = 1'b1;
      end
      if( isBitX(GWEN_int) && DFTRAMBYP_int !== 1'b1) begin
        XQ = 1'b1; Q_update = 1'b1;
      end
      if( isBitX(DFTRAMBYP_int) ) begin
        XQ = 1'b1; Q_update = 1'b1;
      end
      if( isBitX(SE_int) && DFTRAMBYP_int === 1'b1 ) begin
        XQ = 1'b1; Q_update = 1'b1;
      end
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or DFTRAMBYP_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  		DFTRAMBYP_p2 = DFTRAMBYP_;
  	end
  end

`ifdef POWER_PINS
  always @ (VDD) begin
      if (VDD != 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDD should be powered down after VDDP, Illegal power down sequencing in %m at %0t", $time);
       end
        $display("In PowerDown Mode in %m at %0t", $time);
        failedWrite(0);
      end
      if (VDD == 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDDP should be powered up after VDD in %m at %0t", $time);
        $display("Illegal power up sequencing in %m at %0t", $time);
       end
        failedWrite(0);
      end
  end
`endif
`ifdef POWER_PINS
  always @ (RET1N_ or VDDP or VDD) begin
`else     
  always @ RET1N_ begin
`endif
`ifdef POWER_PINS
    if (RET1N_ == 1'b1 && RET1N_int == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 && pre_charge_st == 1'b1 && (CEN_ === 1'bx || TCEN_ === 1'bx || DFTRAMBYP_ === 1'bx || CLK_ === 1'bx)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end
`else     
`endif
`ifdef POWER_PINS
`else     
      pre_charge_st = 0;
`endif
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end
`ifdef POWER_PINS
    if (RET1N_ == 1'b0 && VDD == 1'b1 && VDDP == 1'b1) begin
      pre_charge_st = 1;
    end else if (RET1N_ == 1'b0 && VDDP == 1'b0) begin
      pre_charge_st = 0;
      if (VDD != 1'b1) begin
        failedWrite(0);
      end
`else     
    if (RET1N_ == 1'b0) begin
`endif
        XQ = 1'b1; Q_update = 1'b1;
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
`ifdef POWER_PINS
    end else if (RET1N_ == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 &&  pre_charge_st == 1'b1) begin
      pre_charge_st = 0;
    end else begin
      pre_charge_st = 0;
`else     
    end else begin
`endif
        XQ = 1'b1; Q_update = 1'b1;
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
    end
    RET1N_int = RET1N_;
    #0;
        Q_update = 1'b0;
  end


  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
`endif
`ifdef POWER_PINS
  if (RET1N_ == 1'b0) begin
`else     
  if (RET1N_ == 1'b0) begin
`endif
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if ((CLK_ === 1'b1 || CLK_ === 1'b0) && LAST_CLK === 1'bx) begin
       D_sh_update = 1'b0;  XD_sh = 1'b0;
       XQ = 1'b0; Q_update = 1'b0; 
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      SE_int = SE_;
      DFTRAMBYP_int = DFTRAMBYP_;
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
      if (DFTRAMBYP_=== 1'b1 && SE_ === 1'b1) begin
        XQ = 1'b0; Q_update = 1'b1;
      end else begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
    readWrite;
      end
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
      Q_update = 1'b0;
      D_sh_update = 1'b0;
      XQ = 1'b0;
    end
  end
    LAST_CLK = CLK_;
  end

  assign SI_int = SE_ ? SI_ : {2{1'b0}};
  assign D_int_bmux = TEN_ ? D_ : TD_;

  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ0 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(SI_int[0]), .D(D_int_bmux[0]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[0]), .XQ(XQ), .Q(Q_int[0]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ1 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[0]), .D(D_int_bmux[1]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[1]), .XQ(XQ), .Q(Q_int[1]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ2 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[1]), .D(D_int_bmux[2]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[2]), .XQ(XQ), .Q(Q_int[2]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ3 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[2]), .D(D_int_bmux[3]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[3]), .XQ(XQ), .Q(Q_int[3]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ4 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[3]), .D(D_int_bmux[4]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[4]), .XQ(XQ), .Q(Q_int[4]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ5 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[4]), .D(D_int_bmux[5]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[5]), .XQ(XQ), .Q(Q_int[5]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ6 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[5]), .D(D_int_bmux[6]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[6]), .XQ(XQ), .Q(Q_int[6]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ7 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[6]), .D(D_int_bmux[7]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[7]), .XQ(XQ), .Q(Q_int[7]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ8 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[7]), .D(D_int_bmux[8]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[8]), .XQ(XQ), .Q(Q_int[8]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ9 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[8]), .D(D_int_bmux[9]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[9]), .XQ(XQ), .Q(Q_int[9]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ10 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[9]), .D(D_int_bmux[10]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[10]), .XQ(XQ), .Q(Q_int[10]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ11 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[10]), .D(D_int_bmux[11]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[11]), .XQ(XQ), .Q(Q_int[11]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ12 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[11]), .D(D_int_bmux[12]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[12]), .XQ(XQ), .Q(Q_int[12]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ13 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[12]), .D(D_int_bmux[13]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[13]), .XQ(XQ), .Q(Q_int[13]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ14 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[13]), .D(D_int_bmux[14]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[14]), .XQ(XQ), .Q(Q_int[14]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ15 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[14]), .D(D_int_bmux[15]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[15]), .XQ(XQ), .Q(Q_int[15]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ16 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[15]), .D(D_int_bmux[16]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[16]), .XQ(XQ), .Q(Q_int[16]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ17 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[16]), .D(D_int_bmux[17]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[17]), .XQ(XQ), .Q(Q_int[17]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ18 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[17]), .D(D_int_bmux[18]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[18]), .XQ(XQ), .Q(Q_int[18]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ19 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[18]), .D(D_int_bmux[19]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[19]), .XQ(XQ), .Q(Q_int[19]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ20 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[19]), .D(D_int_bmux[20]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[20]), .XQ(XQ), .Q(Q_int[20]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ21 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[20]), .D(D_int_bmux[21]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[21]), .XQ(XQ), .Q(Q_int[21]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ22 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[21]), .D(D_int_bmux[22]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[22]), .XQ(XQ), .Q(Q_int[22]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ23 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[22]), .D(D_int_bmux[23]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[23]), .XQ(XQ), .Q(Q_int[23]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ24 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[23]), .D(D_int_bmux[24]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[24]), .XQ(XQ), .Q(Q_int[24]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ25 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[24]), .D(D_int_bmux[25]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[25]), .XQ(XQ), .Q(Q_int[25]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ26 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[25]), .D(D_int_bmux[26]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[26]), .XQ(XQ), .Q(Q_int[26]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ27 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[26]), .D(D_int_bmux[27]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[27]), .XQ(XQ), .Q(Q_int[27]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ28 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[27]), .D(D_int_bmux[28]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[28]), .XQ(XQ), .Q(Q_int[28]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ29 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[28]), .D(D_int_bmux[29]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[29]), .XQ(XQ), .Q(Q_int[29]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ30 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[29]), .D(D_int_bmux[30]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[30]), .XQ(XQ), .Q(Q_int[30]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ31 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[30]), .D(D_int_bmux[31]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[31]), .XQ(XQ), .Q(Q_int[31]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ32 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[33]), .D(D_int_bmux[32]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[32]), .XQ(XQ), .Q(Q_int[32]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ33 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[34]), .D(D_int_bmux[33]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[33]), .XQ(XQ), .Q(Q_int[33]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ34 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[35]), .D(D_int_bmux[34]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[34]), .XQ(XQ), .Q(Q_int[34]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ35 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[36]), .D(D_int_bmux[35]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[35]), .XQ(XQ), .Q(Q_int[35]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ36 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[37]), .D(D_int_bmux[36]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[36]), .XQ(XQ), .Q(Q_int[36]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ37 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[38]), .D(D_int_bmux[37]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[37]), .XQ(XQ), .Q(Q_int[37]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ38 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[39]), .D(D_int_bmux[38]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[38]), .XQ(XQ), .Q(Q_int[38]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ39 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[40]), .D(D_int_bmux[39]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[39]), .XQ(XQ), .Q(Q_int[39]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ40 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[41]), .D(D_int_bmux[40]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[40]), .XQ(XQ), .Q(Q_int[40]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ41 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[42]), .D(D_int_bmux[41]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[41]), .XQ(XQ), .Q(Q_int[41]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ42 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[43]), .D(D_int_bmux[42]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[42]), .XQ(XQ), .Q(Q_int[42]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ43 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[44]), .D(D_int_bmux[43]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[43]), .XQ(XQ), .Q(Q_int[43]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ44 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[45]), .D(D_int_bmux[44]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[44]), .XQ(XQ), .Q(Q_int[44]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ45 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[46]), .D(D_int_bmux[45]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[45]), .XQ(XQ), .Q(Q_int[45]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ46 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[47]), .D(D_int_bmux[46]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[46]), .XQ(XQ), .Q(Q_int[46]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ47 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[48]), .D(D_int_bmux[47]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[47]), .XQ(XQ), .Q(Q_int[47]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ48 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[49]), .D(D_int_bmux[48]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[48]), .XQ(XQ), .Q(Q_int[48]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ49 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[50]), .D(D_int_bmux[49]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[49]), .XQ(XQ), .Q(Q_int[49]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ50 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[51]), .D(D_int_bmux[50]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[50]), .XQ(XQ), .Q(Q_int[50]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ51 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[52]), .D(D_int_bmux[51]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[51]), .XQ(XQ), .Q(Q_int[51]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ52 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[53]), .D(D_int_bmux[52]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[52]), .XQ(XQ), .Q(Q_int[52]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ53 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[54]), .D(D_int_bmux[53]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[53]), .XQ(XQ), .Q(Q_int[53]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ54 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[55]), .D(D_int_bmux[54]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[54]), .XQ(XQ), .Q(Q_int[54]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ55 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[56]), .D(D_int_bmux[55]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[55]), .XQ(XQ), .Q(Q_int[55]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ56 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[57]), .D(D_int_bmux[56]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[56]), .XQ(XQ), .Q(Q_int[56]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ57 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[58]), .D(D_int_bmux[57]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[57]), .XQ(XQ), .Q(Q_int[57]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ58 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[59]), .D(D_int_bmux[58]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[58]), .XQ(XQ), .Q(Q_int[58]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ59 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[60]), .D(D_int_bmux[59]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[59]), .XQ(XQ), .Q(Q_int[59]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ60 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[61]), .D(D_int_bmux[60]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[60]), .XQ(XQ), .Q(Q_int[60]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ61 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[62]), .D(D_int_bmux[61]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[61]), .XQ(XQ), .Q(Q_int[61]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ62 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[63]), .D(D_int_bmux[62]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[62]), .XQ(XQ), .Q(Q_int[62]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ63 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(SI_int[1]), .D(D_int_bmux[63]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[63]), .XQ(XQ), .Q(Q_int[63]));


// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
 always @ (VDD or VDDP or VSS) begin
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
 end
`endif

endmodule
`endcelldefine
`else
`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module ARM_SPSRAM_64X4096_M8_MEM (VDD, VDDP, VSS, CENY, WENY, AY, GWENY, Q, SO, CLK,
    CEN, WEN, A, D, EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE,
    DFTRAMBYP);
`else
module ARM_SPSRAM_64X4096_M8_MEM (CENY, WENY, AY, GWENY, Q, SO, CLK, CEN, WEN, A, D,
    EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE, DFTRAMBYP);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 64;
  parameter WORDS = 4096;
  parameter MUX = 8;
  parameter MEM_WIDTH = 512; // redun block size 8, 256 on left, 256 on right
  parameter MEM_HEIGHT = 512;
  parameter WP_SIZE = 1 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 0;

  output  CENY;
  output [63:0] WENY;
  output [11:0] AY;
  output  GWENY;
  output [63:0] Q;
  output [1:0] SO;
  input  CLK;
  input  CEN;
  input [63:0] WEN;
  input [11:0] A;
  input [63:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  TEN;
  input  TCEN;
  input [63:0] TWEN;
  input [11:0] TA;
  input [63:0] TD;
  input  GWEN;
  input  TGWEN;
  input  RET1N;
  input [1:0] SI;
  input  SE;
  input  DFTRAMBYP;
`ifdef POWER_PINS
  inout VDD;
  inout VDDP;
  inout VSS;
`endif

  reg pre_charge_st;
  integer row_address;
  integer mux_address;
  initial row_address = 0;
  initial mux_address = 0;
  reg [511:0] mem [0:511];
  reg [511:0] row, row_t;
  reg LAST_CLK;
  reg [511:0] row_mask;
  reg [511:0] new_data;
  reg [511:0] data_out;
  reg [63:0] readLatch0;
  reg [63:0] shifted_readLatch0;
  reg  read_mux_sel0_p2;
  wire [63:0] Q_int;
  reg XQ, Q_update;
  reg XD_sh, D_sh_update;
  wire [63:0] D_int_bmux;
  reg [63:0] mem_path;
  reg [63:0] writeEnable;

  reg NOT_CEN, NOT_WEN63, NOT_WEN62, NOT_WEN61, NOT_WEN60, NOT_WEN59, NOT_WEN58, NOT_WEN57;
  reg NOT_WEN56, NOT_WEN55, NOT_WEN54, NOT_WEN53, NOT_WEN52, NOT_WEN51, NOT_WEN50;
  reg NOT_WEN49, NOT_WEN48, NOT_WEN47, NOT_WEN46, NOT_WEN45, NOT_WEN44, NOT_WEN43;
  reg NOT_WEN42, NOT_WEN41, NOT_WEN40, NOT_WEN39, NOT_WEN38, NOT_WEN37, NOT_WEN36;
  reg NOT_WEN35, NOT_WEN34, NOT_WEN33, NOT_WEN32, NOT_WEN31, NOT_WEN30, NOT_WEN29;
  reg NOT_WEN28, NOT_WEN27, NOT_WEN26, NOT_WEN25, NOT_WEN24, NOT_WEN23, NOT_WEN22;
  reg NOT_WEN21, NOT_WEN20, NOT_WEN19, NOT_WEN18, NOT_WEN17, NOT_WEN16, NOT_WEN15;
  reg NOT_WEN14, NOT_WEN13, NOT_WEN12, NOT_WEN11, NOT_WEN10, NOT_WEN9, NOT_WEN8, NOT_WEN7;
  reg NOT_WEN6, NOT_WEN5, NOT_WEN4, NOT_WEN3, NOT_WEN2, NOT_WEN1, NOT_WEN0, NOT_A11;
  reg NOT_A10, NOT_A9, NOT_A8, NOT_A7, NOT_A6, NOT_A5, NOT_A4, NOT_A3, NOT_A2, NOT_A1;
  reg NOT_A0, NOT_D63, NOT_D62, NOT_D61, NOT_D60, NOT_D59, NOT_D58, NOT_D57, NOT_D56;
  reg NOT_D55, NOT_D54, NOT_D53, NOT_D52, NOT_D51, NOT_D50, NOT_D49, NOT_D48, NOT_D47;
  reg NOT_D46, NOT_D45, NOT_D44, NOT_D43, NOT_D42, NOT_D41, NOT_D40, NOT_D39, NOT_D38;
  reg NOT_D37, NOT_D36, NOT_D35, NOT_D34, NOT_D33, NOT_D32, NOT_D31, NOT_D30, NOT_D29;
  reg NOT_D28, NOT_D27, NOT_D26, NOT_D25, NOT_D24, NOT_D23, NOT_D22, NOT_D21, NOT_D20;
  reg NOT_D19, NOT_D18, NOT_D17, NOT_D16, NOT_D15, NOT_D14, NOT_D13, NOT_D12, NOT_D11;
  reg NOT_D10, NOT_D9, NOT_D8, NOT_D7, NOT_D6, NOT_D5, NOT_D4, NOT_D3, NOT_D2, NOT_D1;
  reg NOT_D0, NOT_EMA2, NOT_EMA1, NOT_EMA0, NOT_EMAW1, NOT_EMAW0, NOT_TEN, NOT_TCEN;
  reg NOT_TWEN63, NOT_TWEN62, NOT_TWEN61, NOT_TWEN60, NOT_TWEN59, NOT_TWEN58, NOT_TWEN57;
  reg NOT_TWEN56, NOT_TWEN55, NOT_TWEN54, NOT_TWEN53, NOT_TWEN52, NOT_TWEN51, NOT_TWEN50;
  reg NOT_TWEN49, NOT_TWEN48, NOT_TWEN47, NOT_TWEN46, NOT_TWEN45, NOT_TWEN44, NOT_TWEN43;
  reg NOT_TWEN42, NOT_TWEN41, NOT_TWEN40, NOT_TWEN39, NOT_TWEN38, NOT_TWEN37, NOT_TWEN36;
  reg NOT_TWEN35, NOT_TWEN34, NOT_TWEN33, NOT_TWEN32, NOT_TWEN31, NOT_TWEN30, NOT_TWEN29;
  reg NOT_TWEN28, NOT_TWEN27, NOT_TWEN26, NOT_TWEN25, NOT_TWEN24, NOT_TWEN23, NOT_TWEN22;
  reg NOT_TWEN21, NOT_TWEN20, NOT_TWEN19, NOT_TWEN18, NOT_TWEN17, NOT_TWEN16, NOT_TWEN15;
  reg NOT_TWEN14, NOT_TWEN13, NOT_TWEN12, NOT_TWEN11, NOT_TWEN10, NOT_TWEN9, NOT_TWEN8;
  reg NOT_TWEN7, NOT_TWEN6, NOT_TWEN5, NOT_TWEN4, NOT_TWEN3, NOT_TWEN2, NOT_TWEN1;
  reg NOT_TWEN0, NOT_TA11, NOT_TA10, NOT_TA9, NOT_TA8, NOT_TA7, NOT_TA6, NOT_TA5, NOT_TA4;
  reg NOT_TA3, NOT_TA2, NOT_TA1, NOT_TA0, NOT_TD63, NOT_TD62, NOT_TD61, NOT_TD60, NOT_TD59;
  reg NOT_TD58, NOT_TD57, NOT_TD56, NOT_TD55, NOT_TD54, NOT_TD53, NOT_TD52, NOT_TD51;
  reg NOT_TD50, NOT_TD49, NOT_TD48, NOT_TD47, NOT_TD46, NOT_TD45, NOT_TD44, NOT_TD43;
  reg NOT_TD42, NOT_TD41, NOT_TD40, NOT_TD39, NOT_TD38, NOT_TD37, NOT_TD36, NOT_TD35;
  reg NOT_TD34, NOT_TD33, NOT_TD32, NOT_TD31, NOT_TD30, NOT_TD29, NOT_TD28, NOT_TD27;
  reg NOT_TD26, NOT_TD25, NOT_TD24, NOT_TD23, NOT_TD22, NOT_TD21, NOT_TD20, NOT_TD19;
  reg NOT_TD18, NOT_TD17, NOT_TD16, NOT_TD15, NOT_TD14, NOT_TD13, NOT_TD12, NOT_TD11;
  reg NOT_TD10, NOT_TD9, NOT_TD8, NOT_TD7, NOT_TD6, NOT_TD5, NOT_TD4, NOT_TD3, NOT_TD2;
  reg NOT_TD1, NOT_TD0, NOT_GWEN, NOT_TGWEN, NOT_SI1, NOT_SI0, NOT_SE, NOT_DFTRAMBYP;
  reg NOT_RET1N;
  reg NOT_CLK_PER, NOT_CLK_MINH, NOT_CLK_MINL;
  reg clk0_int;

  wire  CENY_;
  wire [63:0] WENY_;
  wire [11:0] AY_;
  wire  GWENY_;
  wire [63:0] Q_;
  wire [1:0] SO_;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire [63:0] WEN_;
  reg [63:0] WEN_int;
  wire [11:0] A_;
  reg [11:0] A_int;
  wire [63:0] D_;
  reg [63:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  TEN_;
  reg  TEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire [63:0] TWEN_;
  reg [63:0] TWEN_int;
  wire [11:0] TA_;
  reg [11:0] TA_int;
  wire [63:0] TD_;
  reg [63:0] TD_int;
  wire  GWEN_;
  reg  GWEN_int;
  wire  TGWEN_;
  reg  TGWEN_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire [1:0] SI_;
  wire [1:0] SI_int;
  wire  SE_;
  reg  SE_int;
  wire  DFTRAMBYP_;
  reg  DFTRAMBYP_int;
  reg  DFTRAMBYP_p2;

  buf B0(CENY, CENY_);
  buf B1(WENY[0], WENY_[0]);
  buf B2(WENY[1], WENY_[1]);
  buf B3(WENY[2], WENY_[2]);
  buf B4(WENY[3], WENY_[3]);
  buf B5(WENY[4], WENY_[4]);
  buf B6(WENY[5], WENY_[5]);
  buf B7(WENY[6], WENY_[6]);
  buf B8(WENY[7], WENY_[7]);
  buf B9(WENY[8], WENY_[8]);
  buf B10(WENY[9], WENY_[9]);
  buf B11(WENY[10], WENY_[10]);
  buf B12(WENY[11], WENY_[11]);
  buf B13(WENY[12], WENY_[12]);
  buf B14(WENY[13], WENY_[13]);
  buf B15(WENY[14], WENY_[14]);
  buf B16(WENY[15], WENY_[15]);
  buf B17(WENY[16], WENY_[16]);
  buf B18(WENY[17], WENY_[17]);
  buf B19(WENY[18], WENY_[18]);
  buf B20(WENY[19], WENY_[19]);
  buf B21(WENY[20], WENY_[20]);
  buf B22(WENY[21], WENY_[21]);
  buf B23(WENY[22], WENY_[22]);
  buf B24(WENY[23], WENY_[23]);
  buf B25(WENY[24], WENY_[24]);
  buf B26(WENY[25], WENY_[25]);
  buf B27(WENY[26], WENY_[26]);
  buf B28(WENY[27], WENY_[27]);
  buf B29(WENY[28], WENY_[28]);
  buf B30(WENY[29], WENY_[29]);
  buf B31(WENY[30], WENY_[30]);
  buf B32(WENY[31], WENY_[31]);
  buf B33(WENY[32], WENY_[32]);
  buf B34(WENY[33], WENY_[33]);
  buf B35(WENY[34], WENY_[34]);
  buf B36(WENY[35], WENY_[35]);
  buf B37(WENY[36], WENY_[36]);
  buf B38(WENY[37], WENY_[37]);
  buf B39(WENY[38], WENY_[38]);
  buf B40(WENY[39], WENY_[39]);
  buf B41(WENY[40], WENY_[40]);
  buf B42(WENY[41], WENY_[41]);
  buf B43(WENY[42], WENY_[42]);
  buf B44(WENY[43], WENY_[43]);
  buf B45(WENY[44], WENY_[44]);
  buf B46(WENY[45], WENY_[45]);
  buf B47(WENY[46], WENY_[46]);
  buf B48(WENY[47], WENY_[47]);
  buf B49(WENY[48], WENY_[48]);
  buf B50(WENY[49], WENY_[49]);
  buf B51(WENY[50], WENY_[50]);
  buf B52(WENY[51], WENY_[51]);
  buf B53(WENY[52], WENY_[52]);
  buf B54(WENY[53], WENY_[53]);
  buf B55(WENY[54], WENY_[54]);
  buf B56(WENY[55], WENY_[55]);
  buf B57(WENY[56], WENY_[56]);
  buf B58(WENY[57], WENY_[57]);
  buf B59(WENY[58], WENY_[58]);
  buf B60(WENY[59], WENY_[59]);
  buf B61(WENY[60], WENY_[60]);
  buf B62(WENY[61], WENY_[61]);
  buf B63(WENY[62], WENY_[62]);
  buf B64(WENY[63], WENY_[63]);
  buf B65(AY[0], AY_[0]);
  buf B66(AY[1], AY_[1]);
  buf B67(AY[2], AY_[2]);
  buf B68(AY[3], AY_[3]);
  buf B69(AY[4], AY_[4]);
  buf B70(AY[5], AY_[5]);
  buf B71(AY[6], AY_[6]);
  buf B72(AY[7], AY_[7]);
  buf B73(AY[8], AY_[8]);
  buf B74(AY[9], AY_[9]);
  buf B75(AY[10], AY_[10]);
  buf B76(AY[11], AY_[11]);
  buf B77(GWENY, GWENY_);
  buf B78(Q[0], Q_[0]);
  buf B79(Q[1], Q_[1]);
  buf B80(Q[2], Q_[2]);
  buf B81(Q[3], Q_[3]);
  buf B82(Q[4], Q_[4]);
  buf B83(Q[5], Q_[5]);
  buf B84(Q[6], Q_[6]);
  buf B85(Q[7], Q_[7]);
  buf B86(Q[8], Q_[8]);
  buf B87(Q[9], Q_[9]);
  buf B88(Q[10], Q_[10]);
  buf B89(Q[11], Q_[11]);
  buf B90(Q[12], Q_[12]);
  buf B91(Q[13], Q_[13]);
  buf B92(Q[14], Q_[14]);
  buf B93(Q[15], Q_[15]);
  buf B94(Q[16], Q_[16]);
  buf B95(Q[17], Q_[17]);
  buf B96(Q[18], Q_[18]);
  buf B97(Q[19], Q_[19]);
  buf B98(Q[20], Q_[20]);
  buf B99(Q[21], Q_[21]);
  buf B100(Q[22], Q_[22]);
  buf B101(Q[23], Q_[23]);
  buf B102(Q[24], Q_[24]);
  buf B103(Q[25], Q_[25]);
  buf B104(Q[26], Q_[26]);
  buf B105(Q[27], Q_[27]);
  buf B106(Q[28], Q_[28]);
  buf B107(Q[29], Q_[29]);
  buf B108(Q[30], Q_[30]);
  buf B109(Q[31], Q_[31]);
  buf B110(Q[32], Q_[32]);
  buf B111(Q[33], Q_[33]);
  buf B112(Q[34], Q_[34]);
  buf B113(Q[35], Q_[35]);
  buf B114(Q[36], Q_[36]);
  buf B115(Q[37], Q_[37]);
  buf B116(Q[38], Q_[38]);
  buf B117(Q[39], Q_[39]);
  buf B118(Q[40], Q_[40]);
  buf B119(Q[41], Q_[41]);
  buf B120(Q[42], Q_[42]);
  buf B121(Q[43], Q_[43]);
  buf B122(Q[44], Q_[44]);
  buf B123(Q[45], Q_[45]);
  buf B124(Q[46], Q_[46]);
  buf B125(Q[47], Q_[47]);
  buf B126(Q[48], Q_[48]);
  buf B127(Q[49], Q_[49]);
  buf B128(Q[50], Q_[50]);
  buf B129(Q[51], Q_[51]);
  buf B130(Q[52], Q_[52]);
  buf B131(Q[53], Q_[53]);
  buf B132(Q[54], Q_[54]);
  buf B133(Q[55], Q_[55]);
  buf B134(Q[56], Q_[56]);
  buf B135(Q[57], Q_[57]);
  buf B136(Q[58], Q_[58]);
  buf B137(Q[59], Q_[59]);
  buf B138(Q[60], Q_[60]);
  buf B139(Q[61], Q_[61]);
  buf B140(Q[62], Q_[62]);
  buf B141(Q[63], Q_[63]);
  buf B142(SO[0], SO_[0]);
  buf B143(SO[1], SO_[1]);
  buf B144(CLK_, CLK);
  buf B145(CEN_, CEN);
  buf B146(WEN_[0], WEN[0]);
  buf B147(WEN_[1], WEN[1]);
  buf B148(WEN_[2], WEN[2]);
  buf B149(WEN_[3], WEN[3]);
  buf B150(WEN_[4], WEN[4]);
  buf B151(WEN_[5], WEN[5]);
  buf B152(WEN_[6], WEN[6]);
  buf B153(WEN_[7], WEN[7]);
  buf B154(WEN_[8], WEN[8]);
  buf B155(WEN_[9], WEN[9]);
  buf B156(WEN_[10], WEN[10]);
  buf B157(WEN_[11], WEN[11]);
  buf B158(WEN_[12], WEN[12]);
  buf B159(WEN_[13], WEN[13]);
  buf B160(WEN_[14], WEN[14]);
  buf B161(WEN_[15], WEN[15]);
  buf B162(WEN_[16], WEN[16]);
  buf B163(WEN_[17], WEN[17]);
  buf B164(WEN_[18], WEN[18]);
  buf B165(WEN_[19], WEN[19]);
  buf B166(WEN_[20], WEN[20]);
  buf B167(WEN_[21], WEN[21]);
  buf B168(WEN_[22], WEN[22]);
  buf B169(WEN_[23], WEN[23]);
  buf B170(WEN_[24], WEN[24]);
  buf B171(WEN_[25], WEN[25]);
  buf B172(WEN_[26], WEN[26]);
  buf B173(WEN_[27], WEN[27]);
  buf B174(WEN_[28], WEN[28]);
  buf B175(WEN_[29], WEN[29]);
  buf B176(WEN_[30], WEN[30]);
  buf B177(WEN_[31], WEN[31]);
  buf B178(WEN_[32], WEN[32]);
  buf B179(WEN_[33], WEN[33]);
  buf B180(WEN_[34], WEN[34]);
  buf B181(WEN_[35], WEN[35]);
  buf B182(WEN_[36], WEN[36]);
  buf B183(WEN_[37], WEN[37]);
  buf B184(WEN_[38], WEN[38]);
  buf B185(WEN_[39], WEN[39]);
  buf B186(WEN_[40], WEN[40]);
  buf B187(WEN_[41], WEN[41]);
  buf B188(WEN_[42], WEN[42]);
  buf B189(WEN_[43], WEN[43]);
  buf B190(WEN_[44], WEN[44]);
  buf B191(WEN_[45], WEN[45]);
  buf B192(WEN_[46], WEN[46]);
  buf B193(WEN_[47], WEN[47]);
  buf B194(WEN_[48], WEN[48]);
  buf B195(WEN_[49], WEN[49]);
  buf B196(WEN_[50], WEN[50]);
  buf B197(WEN_[51], WEN[51]);
  buf B198(WEN_[52], WEN[52]);
  buf B199(WEN_[53], WEN[53]);
  buf B200(WEN_[54], WEN[54]);
  buf B201(WEN_[55], WEN[55]);
  buf B202(WEN_[56], WEN[56]);
  buf B203(WEN_[57], WEN[57]);
  buf B204(WEN_[58], WEN[58]);
  buf B205(WEN_[59], WEN[59]);
  buf B206(WEN_[60], WEN[60]);
  buf B207(WEN_[61], WEN[61]);
  buf B208(WEN_[62], WEN[62]);
  buf B209(WEN_[63], WEN[63]);
  buf B210(A_[0], A[0]);
  buf B211(A_[1], A[1]);
  buf B212(A_[2], A[2]);
  buf B213(A_[3], A[3]);
  buf B214(A_[4], A[4]);
  buf B215(A_[5], A[5]);
  buf B216(A_[6], A[6]);
  buf B217(A_[7], A[7]);
  buf B218(A_[8], A[8]);
  buf B219(A_[9], A[9]);
  buf B220(A_[10], A[10]);
  buf B221(A_[11], A[11]);
  buf B222(D_[0], D[0]);
  buf B223(D_[1], D[1]);
  buf B224(D_[2], D[2]);
  buf B225(D_[3], D[3]);
  buf B226(D_[4], D[4]);
  buf B227(D_[5], D[5]);
  buf B228(D_[6], D[6]);
  buf B229(D_[7], D[7]);
  buf B230(D_[8], D[8]);
  buf B231(D_[9], D[9]);
  buf B232(D_[10], D[10]);
  buf B233(D_[11], D[11]);
  buf B234(D_[12], D[12]);
  buf B235(D_[13], D[13]);
  buf B236(D_[14], D[14]);
  buf B237(D_[15], D[15]);
  buf B238(D_[16], D[16]);
  buf B239(D_[17], D[17]);
  buf B240(D_[18], D[18]);
  buf B241(D_[19], D[19]);
  buf B242(D_[20], D[20]);
  buf B243(D_[21], D[21]);
  buf B244(D_[22], D[22]);
  buf B245(D_[23], D[23]);
  buf B246(D_[24], D[24]);
  buf B247(D_[25], D[25]);
  buf B248(D_[26], D[26]);
  buf B249(D_[27], D[27]);
  buf B250(D_[28], D[28]);
  buf B251(D_[29], D[29]);
  buf B252(D_[30], D[30]);
  buf B253(D_[31], D[31]);
  buf B254(D_[32], D[32]);
  buf B255(D_[33], D[33]);
  buf B256(D_[34], D[34]);
  buf B257(D_[35], D[35]);
  buf B258(D_[36], D[36]);
  buf B259(D_[37], D[37]);
  buf B260(D_[38], D[38]);
  buf B261(D_[39], D[39]);
  buf B262(D_[40], D[40]);
  buf B263(D_[41], D[41]);
  buf B264(D_[42], D[42]);
  buf B265(D_[43], D[43]);
  buf B266(D_[44], D[44]);
  buf B267(D_[45], D[45]);
  buf B268(D_[46], D[46]);
  buf B269(D_[47], D[47]);
  buf B270(D_[48], D[48]);
  buf B271(D_[49], D[49]);
  buf B272(D_[50], D[50]);
  buf B273(D_[51], D[51]);
  buf B274(D_[52], D[52]);
  buf B275(D_[53], D[53]);
  buf B276(D_[54], D[54]);
  buf B277(D_[55], D[55]);
  buf B278(D_[56], D[56]);
  buf B279(D_[57], D[57]);
  buf B280(D_[58], D[58]);
  buf B281(D_[59], D[59]);
  buf B282(D_[60], D[60]);
  buf B283(D_[61], D[61]);
  buf B284(D_[62], D[62]);
  buf B285(D_[63], D[63]);
  buf B286(EMA_[0], EMA[0]);
  buf B287(EMA_[1], EMA[1]);
  buf B288(EMA_[2], EMA[2]);
  buf B289(EMAW_[0], EMAW[0]);
  buf B290(EMAW_[1], EMAW[1]);
  buf B291(TEN_, TEN);
  buf B292(TCEN_, TCEN);
  buf B293(TWEN_[0], TWEN[0]);
  buf B294(TWEN_[1], TWEN[1]);
  buf B295(TWEN_[2], TWEN[2]);
  buf B296(TWEN_[3], TWEN[3]);
  buf B297(TWEN_[4], TWEN[4]);
  buf B298(TWEN_[5], TWEN[5]);
  buf B299(TWEN_[6], TWEN[6]);
  buf B300(TWEN_[7], TWEN[7]);
  buf B301(TWEN_[8], TWEN[8]);
  buf B302(TWEN_[9], TWEN[9]);
  buf B303(TWEN_[10], TWEN[10]);
  buf B304(TWEN_[11], TWEN[11]);
  buf B305(TWEN_[12], TWEN[12]);
  buf B306(TWEN_[13], TWEN[13]);
  buf B307(TWEN_[14], TWEN[14]);
  buf B308(TWEN_[15], TWEN[15]);
  buf B309(TWEN_[16], TWEN[16]);
  buf B310(TWEN_[17], TWEN[17]);
  buf B311(TWEN_[18], TWEN[18]);
  buf B312(TWEN_[19], TWEN[19]);
  buf B313(TWEN_[20], TWEN[20]);
  buf B314(TWEN_[21], TWEN[21]);
  buf B315(TWEN_[22], TWEN[22]);
  buf B316(TWEN_[23], TWEN[23]);
  buf B317(TWEN_[24], TWEN[24]);
  buf B318(TWEN_[25], TWEN[25]);
  buf B319(TWEN_[26], TWEN[26]);
  buf B320(TWEN_[27], TWEN[27]);
  buf B321(TWEN_[28], TWEN[28]);
  buf B322(TWEN_[29], TWEN[29]);
  buf B323(TWEN_[30], TWEN[30]);
  buf B324(TWEN_[31], TWEN[31]);
  buf B325(TWEN_[32], TWEN[32]);
  buf B326(TWEN_[33], TWEN[33]);
  buf B327(TWEN_[34], TWEN[34]);
  buf B328(TWEN_[35], TWEN[35]);
  buf B329(TWEN_[36], TWEN[36]);
  buf B330(TWEN_[37], TWEN[37]);
  buf B331(TWEN_[38], TWEN[38]);
  buf B332(TWEN_[39], TWEN[39]);
  buf B333(TWEN_[40], TWEN[40]);
  buf B334(TWEN_[41], TWEN[41]);
  buf B335(TWEN_[42], TWEN[42]);
  buf B336(TWEN_[43], TWEN[43]);
  buf B337(TWEN_[44], TWEN[44]);
  buf B338(TWEN_[45], TWEN[45]);
  buf B339(TWEN_[46], TWEN[46]);
  buf B340(TWEN_[47], TWEN[47]);
  buf B341(TWEN_[48], TWEN[48]);
  buf B342(TWEN_[49], TWEN[49]);
  buf B343(TWEN_[50], TWEN[50]);
  buf B344(TWEN_[51], TWEN[51]);
  buf B345(TWEN_[52], TWEN[52]);
  buf B346(TWEN_[53], TWEN[53]);
  buf B347(TWEN_[54], TWEN[54]);
  buf B348(TWEN_[55], TWEN[55]);
  buf B349(TWEN_[56], TWEN[56]);
  buf B350(TWEN_[57], TWEN[57]);
  buf B351(TWEN_[58], TWEN[58]);
  buf B352(TWEN_[59], TWEN[59]);
  buf B353(TWEN_[60], TWEN[60]);
  buf B354(TWEN_[61], TWEN[61]);
  buf B355(TWEN_[62], TWEN[62]);
  buf B356(TWEN_[63], TWEN[63]);
  buf B357(TA_[0], TA[0]);
  buf B358(TA_[1], TA[1]);
  buf B359(TA_[2], TA[2]);
  buf B360(TA_[3], TA[3]);
  buf B361(TA_[4], TA[4]);
  buf B362(TA_[5], TA[5]);
  buf B363(TA_[6], TA[6]);
  buf B364(TA_[7], TA[7]);
  buf B365(TA_[8], TA[8]);
  buf B366(TA_[9], TA[9]);
  buf B367(TA_[10], TA[10]);
  buf B368(TA_[11], TA[11]);
  buf B369(TD_[0], TD[0]);
  buf B370(TD_[1], TD[1]);
  buf B371(TD_[2], TD[2]);
  buf B372(TD_[3], TD[3]);
  buf B373(TD_[4], TD[4]);
  buf B374(TD_[5], TD[5]);
  buf B375(TD_[6], TD[6]);
  buf B376(TD_[7], TD[7]);
  buf B377(TD_[8], TD[8]);
  buf B378(TD_[9], TD[9]);
  buf B379(TD_[10], TD[10]);
  buf B380(TD_[11], TD[11]);
  buf B381(TD_[12], TD[12]);
  buf B382(TD_[13], TD[13]);
  buf B383(TD_[14], TD[14]);
  buf B384(TD_[15], TD[15]);
  buf B385(TD_[16], TD[16]);
  buf B386(TD_[17], TD[17]);
  buf B387(TD_[18], TD[18]);
  buf B388(TD_[19], TD[19]);
  buf B389(TD_[20], TD[20]);
  buf B390(TD_[21], TD[21]);
  buf B391(TD_[22], TD[22]);
  buf B392(TD_[23], TD[23]);
  buf B393(TD_[24], TD[24]);
  buf B394(TD_[25], TD[25]);
  buf B395(TD_[26], TD[26]);
  buf B396(TD_[27], TD[27]);
  buf B397(TD_[28], TD[28]);
  buf B398(TD_[29], TD[29]);
  buf B399(TD_[30], TD[30]);
  buf B400(TD_[31], TD[31]);
  buf B401(TD_[32], TD[32]);
  buf B402(TD_[33], TD[33]);
  buf B403(TD_[34], TD[34]);
  buf B404(TD_[35], TD[35]);
  buf B405(TD_[36], TD[36]);
  buf B406(TD_[37], TD[37]);
  buf B407(TD_[38], TD[38]);
  buf B408(TD_[39], TD[39]);
  buf B409(TD_[40], TD[40]);
  buf B410(TD_[41], TD[41]);
  buf B411(TD_[42], TD[42]);
  buf B412(TD_[43], TD[43]);
  buf B413(TD_[44], TD[44]);
  buf B414(TD_[45], TD[45]);
  buf B415(TD_[46], TD[46]);
  buf B416(TD_[47], TD[47]);
  buf B417(TD_[48], TD[48]);
  buf B418(TD_[49], TD[49]);
  buf B419(TD_[50], TD[50]);
  buf B420(TD_[51], TD[51]);
  buf B421(TD_[52], TD[52]);
  buf B422(TD_[53], TD[53]);
  buf B423(TD_[54], TD[54]);
  buf B424(TD_[55], TD[55]);
  buf B425(TD_[56], TD[56]);
  buf B426(TD_[57], TD[57]);
  buf B427(TD_[58], TD[58]);
  buf B428(TD_[59], TD[59]);
  buf B429(TD_[60], TD[60]);
  buf B430(TD_[61], TD[61]);
  buf B431(TD_[62], TD[62]);
  buf B432(TD_[63], TD[63]);
  buf B433(GWEN_, GWEN);
  buf B434(TGWEN_, TGWEN);
  buf B435(RET1N_, RET1N);
  buf B436(SI_[0], SI[0]);
  buf B437(SI_[1], SI[1]);
  buf B438(SE_, SE);
  buf B439(DFTRAMBYP_, DFTRAMBYP);

  assign CENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? CEN_ : TCEN_)) : 1'bx;
  assign WENY_ = (RET1N_ | pre_charge_st) ? ({64{DFTRAMBYP_}} & (TEN_ ? WEN_ : TWEN_)) : {64{1'bx}};
  assign AY_ = (RET1N_ | pre_charge_st) ? ({12{DFTRAMBYP_}} & (TEN_ ? A_ : TA_)) : {12{1'bx}};
  assign GWENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? GWEN_ : TGWEN_)) : 1'bx;
  assign Q_ = (RET1N_ | pre_charge_st) ? ((Q_int)) : {64{1'bx}};
  assign SO_ = (RET1N_ | pre_charge_st) ? ({Q_[32], Q_[31]}) : {2{1'bx}};

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial begin
    #0;
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
  end
`endif
  always @ (EMA_) begin
  	if(EMA_ < 2) 
   	$display("Warning: Set Value for EMA doesn't match Default value 2 in %m at %0t", $time);
  end
  always @ (EMAW_) begin
  	if(EMAW_ < 0) 
   	$display("Warning: Set Value for EMAW doesn't match Default value 0 in %m at %0t", $time);
  end

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval===1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction

  function isBit1;
    input bitval;
    begin
      isBit1 = ( bitval===1'b1 ) ? 1'b1 : 1'b0;
    end
  endfunction



  task readWrite;
  begin
    if (GWEN_int !== 1'b1 && DFTRAMBYP_int=== 1'b0 && SE_int === 1'bx) begin
      failedWrite(0);
    end else if (DFTRAMBYP_int=== 1'b0 && SE_int === 1'b1) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_int === 1'b0 && (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{(EMA_int & isBit1(DFTRAMBYP_int)), (EMAW_int & isBit1(DFTRAMBYP_int))} === 1'bx) begin
        XQ = 1'b1; Q_update = 1'b1;
    end else if (^{(CEN_int & !isBit1(DFTRAMBYP_int)), EMA_int, EMAW_int, RET1N_int} === 1'bx) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0) && DFTRAMBYP_int === 1'b0) begin
        XQ = GWEN_int !== 1'b1 ? 1'b0 : 1'b1; Q_update = GWEN_int !== 1'b1 ? 1'b0 : 1'b1;
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx && DFTRAMBYP_int === 1'b0) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1) begin
      if(isBitX(DFTRAMBYP_int) || isBitX(SE_int))
        D_int = {64{1'bx}};

      mux_address = (A_int & 3'b111);
      row_address = (A_int >> 3);
      if (DFTRAMBYP_int !== 1'b1) begin
      if (row_address > 511)
        row = {512{1'bx}};
      else
        row = mem[row_address];
      end
      if( (isBitX(GWEN_int) && DFTRAMBYP_int!==1) || isBitX(DFTRAMBYP_int) ) begin
        writeEnable = {64{1'bx}};
        D_int = {64{1'bx}};
      end else
          writeEnable = ~ ( {64{GWEN_int}} | {WEN_int[63], WEN_int[62], WEN_int[61],
          WEN_int[60], WEN_int[59], WEN_int[58], WEN_int[57], WEN_int[56], WEN_int[55],
          WEN_int[54], WEN_int[53], WEN_int[52], WEN_int[51], WEN_int[50], WEN_int[49],
          WEN_int[48], WEN_int[47], WEN_int[46], WEN_int[45], WEN_int[44], WEN_int[43],
          WEN_int[42], WEN_int[41], WEN_int[40], WEN_int[39], WEN_int[38], WEN_int[37],
          WEN_int[36], WEN_int[35], WEN_int[34], WEN_int[33], WEN_int[32], WEN_int[31],
          WEN_int[30], WEN_int[29], WEN_int[28], WEN_int[27], WEN_int[26], WEN_int[25],
          WEN_int[24], WEN_int[23], WEN_int[22], WEN_int[21], WEN_int[20], WEN_int[19],
          WEN_int[18], WEN_int[17], WEN_int[16], WEN_int[15], WEN_int[14], WEN_int[13],
          WEN_int[12], WEN_int[11], WEN_int[10], WEN_int[9], WEN_int[8], WEN_int[7],
          WEN_int[6], WEN_int[5], WEN_int[4], WEN_int[3], WEN_int[2], WEN_int[1], WEN_int[0]});
      if (GWEN_int !== 1'b1 || DFTRAMBYP_int === 1'b1 || DFTRAMBYP_int === 1'bx) begin
        row_mask =  ( {7'b0000000, writeEnable[63], 7'b0000000, writeEnable[62], 7'b0000000, writeEnable[61],
          7'b0000000, writeEnable[60], 7'b0000000, writeEnable[59], 7'b0000000, writeEnable[58],
          7'b0000000, writeEnable[57], 7'b0000000, writeEnable[56], 7'b0000000, writeEnable[55],
          7'b0000000, writeEnable[54], 7'b0000000, writeEnable[53], 7'b0000000, writeEnable[52],
          7'b0000000, writeEnable[51], 7'b0000000, writeEnable[50], 7'b0000000, writeEnable[49],
          7'b0000000, writeEnable[48], 7'b0000000, writeEnable[47], 7'b0000000, writeEnable[46],
          7'b0000000, writeEnable[45], 7'b0000000, writeEnable[44], 7'b0000000, writeEnable[43],
          7'b0000000, writeEnable[42], 7'b0000000, writeEnable[41], 7'b0000000, writeEnable[40],
          7'b0000000, writeEnable[39], 7'b0000000, writeEnable[38], 7'b0000000, writeEnable[37],
          7'b0000000, writeEnable[36], 7'b0000000, writeEnable[35], 7'b0000000, writeEnable[34],
          7'b0000000, writeEnable[33], 7'b0000000, writeEnable[32], 7'b0000000, writeEnable[31],
          7'b0000000, writeEnable[30], 7'b0000000, writeEnable[29], 7'b0000000, writeEnable[28],
          7'b0000000, writeEnable[27], 7'b0000000, writeEnable[26], 7'b0000000, writeEnable[25],
          7'b0000000, writeEnable[24], 7'b0000000, writeEnable[23], 7'b0000000, writeEnable[22],
          7'b0000000, writeEnable[21], 7'b0000000, writeEnable[20], 7'b0000000, writeEnable[19],
          7'b0000000, writeEnable[18], 7'b0000000, writeEnable[17], 7'b0000000, writeEnable[16],
          7'b0000000, writeEnable[15], 7'b0000000, writeEnable[14], 7'b0000000, writeEnable[13],
          7'b0000000, writeEnable[12], 7'b0000000, writeEnable[11], 7'b0000000, writeEnable[10],
          7'b0000000, writeEnable[9], 7'b0000000, writeEnable[8], 7'b0000000, writeEnable[7],
          7'b0000000, writeEnable[6], 7'b0000000, writeEnable[5], 7'b0000000, writeEnable[4],
          7'b0000000, writeEnable[3], 7'b0000000, writeEnable[2], 7'b0000000, writeEnable[1],
          7'b0000000, writeEnable[0]} << mux_address);
        new_data =  ( {7'b0000000, D_int[63], 7'b0000000, D_int[62], 7'b0000000, D_int[61],
          7'b0000000, D_int[60], 7'b0000000, D_int[59], 7'b0000000, D_int[58], 7'b0000000, D_int[57],
          7'b0000000, D_int[56], 7'b0000000, D_int[55], 7'b0000000, D_int[54], 7'b0000000, D_int[53],
          7'b0000000, D_int[52], 7'b0000000, D_int[51], 7'b0000000, D_int[50], 7'b0000000, D_int[49],
          7'b0000000, D_int[48], 7'b0000000, D_int[47], 7'b0000000, D_int[46], 7'b0000000, D_int[45],
          7'b0000000, D_int[44], 7'b0000000, D_int[43], 7'b0000000, D_int[42], 7'b0000000, D_int[41],
          7'b0000000, D_int[40], 7'b0000000, D_int[39], 7'b0000000, D_int[38], 7'b0000000, D_int[37],
          7'b0000000, D_int[36], 7'b0000000, D_int[35], 7'b0000000, D_int[34], 7'b0000000, D_int[33],
          7'b0000000, D_int[32], 7'b0000000, D_int[31], 7'b0000000, D_int[30], 7'b0000000, D_int[29],
          7'b0000000, D_int[28], 7'b0000000, D_int[27], 7'b0000000, D_int[26], 7'b0000000, D_int[25],
          7'b0000000, D_int[24], 7'b0000000, D_int[23], 7'b0000000, D_int[22], 7'b0000000, D_int[21],
          7'b0000000, D_int[20], 7'b0000000, D_int[19], 7'b0000000, D_int[18], 7'b0000000, D_int[17],
          7'b0000000, D_int[16], 7'b0000000, D_int[15], 7'b0000000, D_int[14], 7'b0000000, D_int[13],
          7'b0000000, D_int[12], 7'b0000000, D_int[11], 7'b0000000, D_int[10], 7'b0000000, D_int[9],
          7'b0000000, D_int[8], 7'b0000000, D_int[7], 7'b0000000, D_int[6], 7'b0000000, D_int[5],
          7'b0000000, D_int[4], 7'b0000000, D_int[3], 7'b0000000, D_int[2], 7'b0000000, D_int[1],
          7'b0000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        if (DFTRAMBYP_int === 1'b1 && SE_int === 1'b0) begin
        end else if (GWEN_int !== 1'b1 && DFTRAMBYP_int === 1'b1 && SE_int === 1'bx) begin
        	XQ = 1'b1; Q_update = 1'b1;
        end else begin
        mem[row_address] = row;
        end
      end else begin
        data_out = (row >> (mux_address%8));
        readLatch0 = {data_out[504], data_out[496], data_out[488], data_out[480], data_out[472],
          data_out[464], data_out[456], data_out[448], data_out[440], data_out[432],
          data_out[424], data_out[416], data_out[408], data_out[400], data_out[392],
          data_out[384], data_out[376], data_out[368], data_out[360], data_out[352],
          data_out[344], data_out[336], data_out[328], data_out[320], data_out[312],
          data_out[304], data_out[296], data_out[288], data_out[280], data_out[272],
          data_out[264], data_out[256], data_out[248], data_out[240], data_out[232],
          data_out[224], data_out[216], data_out[208], data_out[200], data_out[192],
          data_out[184], data_out[176], data_out[168], data_out[160], data_out[152],
          data_out[144], data_out[136], data_out[128], data_out[120], data_out[112],
          data_out[104], data_out[96], data_out[88], data_out[80], data_out[72], data_out[64],
          data_out[56], data_out[48], data_out[40], data_out[32], data_out[24], data_out[16],
          data_out[8], data_out[0]};
        shifted_readLatch0 = readLatch0;
        mem_path = {shifted_readLatch0[63], shifted_readLatch0[62], shifted_readLatch0[61],
          shifted_readLatch0[60], shifted_readLatch0[59], shifted_readLatch0[58], shifted_readLatch0[57],
          shifted_readLatch0[56], shifted_readLatch0[55], shifted_readLatch0[54], shifted_readLatch0[53],
          shifted_readLatch0[52], shifted_readLatch0[51], shifted_readLatch0[50], shifted_readLatch0[49],
          shifted_readLatch0[48], shifted_readLatch0[47], shifted_readLatch0[46], shifted_readLatch0[45],
          shifted_readLatch0[44], shifted_readLatch0[43], shifted_readLatch0[42], shifted_readLatch0[41],
          shifted_readLatch0[40], shifted_readLatch0[39], shifted_readLatch0[38], shifted_readLatch0[37],
          shifted_readLatch0[36], shifted_readLatch0[35], shifted_readLatch0[34], shifted_readLatch0[33],
          shifted_readLatch0[32], shifted_readLatch0[31], shifted_readLatch0[30], shifted_readLatch0[29],
          shifted_readLatch0[28], shifted_readLatch0[27], shifted_readLatch0[26], shifted_readLatch0[25],
          shifted_readLatch0[24], shifted_readLatch0[23], shifted_readLatch0[22], shifted_readLatch0[21],
          shifted_readLatch0[20], shifted_readLatch0[19], shifted_readLatch0[18], shifted_readLatch0[17],
          shifted_readLatch0[16], shifted_readLatch0[15], shifted_readLatch0[14], shifted_readLatch0[13],
          shifted_readLatch0[12], shifted_readLatch0[11], shifted_readLatch0[10], shifted_readLatch0[9],
          shifted_readLatch0[8], shifted_readLatch0[7], shifted_readLatch0[6], shifted_readLatch0[5],
          shifted_readLatch0[4], shifted_readLatch0[3], shifted_readLatch0[2], shifted_readLatch0[1],
          shifted_readLatch0[0]};
        	XQ = 1'b0; Q_update = 1'b1;
      end
      if (DFTRAMBYP_int === 1'b1) begin
        	XQ = 1'b0; Q_update = 1'b1;
      end
      if( isBitX(GWEN_int) && DFTRAMBYP_int !== 1'b1) begin
        XQ = 1'b1; Q_update = 1'b1;
      end
      if( isBitX(DFTRAMBYP_int) ) begin
        XQ = 1'b1; Q_update = 1'b1;
      end
      if( isBitX(SE_int) && DFTRAMBYP_int === 1'b1 ) begin
        XQ = 1'b1; Q_update = 1'b1;
      end
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or DFTRAMBYP_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  		DFTRAMBYP_p2 = DFTRAMBYP_;
  	end
  end

`ifdef POWER_PINS
  always @ (VDD) begin
      if (VDD != 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDD should be powered down after VDDP, Illegal power down sequencing in %m at %0t", $time);
       end
        $display("In PowerDown Mode in %m at %0t", $time);
        failedWrite(0);
      end
      if (VDD == 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDDP should be powered up after VDD in %m at %0t", $time);
        $display("Illegal power up sequencing in %m at %0t", $time);
       end
        failedWrite(0);
      end
  end
`endif
`ifdef POWER_PINS
  always @ (RET1N_ or VDDP or VDD) begin
`else     
  always @ RET1N_ begin
`endif
`ifdef POWER_PINS
    if (RET1N_ == 1'b1 && RET1N_int == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 && pre_charge_st == 1'b1 && (CEN_ === 1'bx || TCEN_ === 1'bx || DFTRAMBYP_ === 1'bx || CLK_ === 1'bx)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end
`else     
`endif
`ifdef POWER_PINS
`else     
      pre_charge_st = 0;
`endif
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end
`ifdef POWER_PINS
    if (RET1N_ == 1'b0 && VDD == 1'b1 && VDDP == 1'b1) begin
      pre_charge_st = 1;
    end else if (RET1N_ == 1'b0 && VDDP == 1'b0) begin
      pre_charge_st = 0;
      if (VDD != 1'b1) begin
        failedWrite(0);
      end
`else     
    if (RET1N_ == 1'b0) begin
`endif
        XQ = 1'b1; Q_update = 1'b1;
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
`ifdef POWER_PINS
    end else if (RET1N_ == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 &&  pre_charge_st == 1'b1) begin
      pre_charge_st = 0;
    end else begin
      pre_charge_st = 0;
`else     
    end else begin
`endif
        XQ = 1'b1; Q_update = 1'b1;
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
    end
    RET1N_int = RET1N_;
    #0;
        Q_update = 1'b0;
  end


  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
`endif
`ifdef POWER_PINS
  if (RET1N_ == 1'b0) begin
`else     
  if (RET1N_ == 1'b0) begin
`endif
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
        XQ = 1'b1; Q_update = 1'b1;
    end else if ((CLK_ === 1'b1 || CLK_ === 1'b0) && LAST_CLK === 1'bx) begin
       D_sh_update = 1'b0;  XD_sh = 1'b0;
       XQ = 1'b0; Q_update = 1'b0; 
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      SE_int = SE_;
      DFTRAMBYP_int = DFTRAMBYP_;
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
      if (DFTRAMBYP_=== 1'b1 && SE_ === 1'b1) begin
        XQ = 1'b0; Q_update = 1'b1;
      end else begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
    readWrite;
      end
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
      Q_update = 1'b0;
      D_sh_update = 1'b0;
      XQ = 1'b0;
    end
  end
    LAST_CLK = CLK_;
  end

  reg globalNotifier0;
  initial globalNotifier0 = 1'b0;

  always @ globalNotifier0 begin
    if ($realtime == 0) begin
    end else if ((EMAW_int[0] === 1'bx & DFTRAMBYP_int === 1'b1) || (EMAW_int[1] === 1'bx & DFTRAMBYP_int === 1'b1) || 
      (EMA_int[0] === 1'bx & DFTRAMBYP_int === 1'b1) || (EMA_int[1] === 1'bx & DFTRAMBYP_int === 1'b1) || 
      (EMA_int[2] === 1'bx & DFTRAMBYP_int === 1'b1)) begin
        XQ = 1'b1; Q_update = 1'b1;
    end else if ((CEN_int === 1'bx & DFTRAMBYP_int === 1'b0) || EMAW_int[0] === 1'bx || 
      EMAW_int[1] === 1'bx || EMA_int[0] === 1'bx || EMA_int[1] === 1'bx || EMA_int[2] === 1'bx || 
      RET1N_int === 1'bx || clk0_int === 1'bx) begin
        XQ = 1'b1; Q_update = 1'b1;
      failedWrite(0);
    end else if (TEN_int === 1'bx) begin
      if(((CEN_ === 1'b1 & TCEN_ === 1'b1) & DFTRAMBYP_int === 1'b0) | (DFTRAMBYP_int === 1'b1 & SE_int === 1'b1)) begin
      end else begin
        XQ = 1'b1; Q_update = 1'b1;
      if (DFTRAMBYP_int === 1'b0) begin
          failedWrite(0);
      end
      end
    end else begin
      #0;
      readWrite;
   end
      #0;
        XQ = 1'b0; Q_update = 1'b0;
    globalNotifier0 = 1'b0;
  end

  assign SI_int = SE_ ? SI_ : {2{1'b0}};
  assign D_int_bmux = TEN_ ? D_ : TD_;

  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ0 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(SI_int[0]), .D(D_int_bmux[0]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[0]), .XQ(XQ), .Q(Q_int[0]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ1 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[0]), .D(D_int_bmux[1]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[1]), .XQ(XQ), .Q(Q_int[1]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ2 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[1]), .D(D_int_bmux[2]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[2]), .XQ(XQ), .Q(Q_int[2]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ3 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[2]), .D(D_int_bmux[3]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[3]), .XQ(XQ), .Q(Q_int[3]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ4 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[3]), .D(D_int_bmux[4]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[4]), .XQ(XQ), .Q(Q_int[4]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ5 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[4]), .D(D_int_bmux[5]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[5]), .XQ(XQ), .Q(Q_int[5]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ6 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[5]), .D(D_int_bmux[6]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[6]), .XQ(XQ), .Q(Q_int[6]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ7 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[6]), .D(D_int_bmux[7]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[7]), .XQ(XQ), .Q(Q_int[7]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ8 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[7]), .D(D_int_bmux[8]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[8]), .XQ(XQ), .Q(Q_int[8]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ9 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[8]), .D(D_int_bmux[9]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[9]), .XQ(XQ), .Q(Q_int[9]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ10 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[9]), .D(D_int_bmux[10]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[10]), .XQ(XQ), .Q(Q_int[10]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ11 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[10]), .D(D_int_bmux[11]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[11]), .XQ(XQ), .Q(Q_int[11]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ12 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[11]), .D(D_int_bmux[12]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[12]), .XQ(XQ), .Q(Q_int[12]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ13 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[12]), .D(D_int_bmux[13]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[13]), .XQ(XQ), .Q(Q_int[13]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ14 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[13]), .D(D_int_bmux[14]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[14]), .XQ(XQ), .Q(Q_int[14]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ15 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[14]), .D(D_int_bmux[15]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[15]), .XQ(XQ), .Q(Q_int[15]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ16 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[15]), .D(D_int_bmux[16]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[16]), .XQ(XQ), .Q(Q_int[16]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ17 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[16]), .D(D_int_bmux[17]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[17]), .XQ(XQ), .Q(Q_int[17]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ18 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[17]), .D(D_int_bmux[18]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[18]), .XQ(XQ), .Q(Q_int[18]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ19 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[18]), .D(D_int_bmux[19]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[19]), .XQ(XQ), .Q(Q_int[19]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ20 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[19]), .D(D_int_bmux[20]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[20]), .XQ(XQ), .Q(Q_int[20]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ21 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[20]), .D(D_int_bmux[21]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[21]), .XQ(XQ), .Q(Q_int[21]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ22 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[21]), .D(D_int_bmux[22]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[22]), .XQ(XQ), .Q(Q_int[22]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ23 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[22]), .D(D_int_bmux[23]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[23]), .XQ(XQ), .Q(Q_int[23]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ24 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[23]), .D(D_int_bmux[24]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[24]), .XQ(XQ), .Q(Q_int[24]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ25 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[24]), .D(D_int_bmux[25]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[25]), .XQ(XQ), .Q(Q_int[25]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ26 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[25]), .D(D_int_bmux[26]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[26]), .XQ(XQ), .Q(Q_int[26]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ27 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[26]), .D(D_int_bmux[27]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[27]), .XQ(XQ), .Q(Q_int[27]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ28 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[27]), .D(D_int_bmux[28]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[28]), .XQ(XQ), .Q(Q_int[28]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ29 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[28]), .D(D_int_bmux[29]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[29]), .XQ(XQ), .Q(Q_int[29]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ30 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[29]), .D(D_int_bmux[30]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[30]), .XQ(XQ), .Q(Q_int[30]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ31 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[30]), .D(D_int_bmux[31]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[31]), .XQ(XQ), .Q(Q_int[31]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ32 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[33]), .D(D_int_bmux[32]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[32]), .XQ(XQ), .Q(Q_int[32]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ33 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[34]), .D(D_int_bmux[33]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[33]), .XQ(XQ), .Q(Q_int[33]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ34 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[35]), .D(D_int_bmux[34]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[34]), .XQ(XQ), .Q(Q_int[34]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ35 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[36]), .D(D_int_bmux[35]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[35]), .XQ(XQ), .Q(Q_int[35]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ36 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[37]), .D(D_int_bmux[36]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[36]), .XQ(XQ), .Q(Q_int[36]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ37 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[38]), .D(D_int_bmux[37]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[37]), .XQ(XQ), .Q(Q_int[37]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ38 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[39]), .D(D_int_bmux[38]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[38]), .XQ(XQ), .Q(Q_int[38]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ39 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[40]), .D(D_int_bmux[39]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[39]), .XQ(XQ), .Q(Q_int[39]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ40 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[41]), .D(D_int_bmux[40]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[40]), .XQ(XQ), .Q(Q_int[40]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ41 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[42]), .D(D_int_bmux[41]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[41]), .XQ(XQ), .Q(Q_int[41]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ42 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[43]), .D(D_int_bmux[42]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[42]), .XQ(XQ), .Q(Q_int[42]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ43 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[44]), .D(D_int_bmux[43]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[43]), .XQ(XQ), .Q(Q_int[43]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ44 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[45]), .D(D_int_bmux[44]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[44]), .XQ(XQ), .Q(Q_int[44]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ45 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[46]), .D(D_int_bmux[45]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[45]), .XQ(XQ), .Q(Q_int[45]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ46 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[47]), .D(D_int_bmux[46]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[46]), .XQ(XQ), .Q(Q_int[46]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ47 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[48]), .D(D_int_bmux[47]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[47]), .XQ(XQ), .Q(Q_int[47]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ48 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[49]), .D(D_int_bmux[48]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[48]), .XQ(XQ), .Q(Q_int[48]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ49 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[50]), .D(D_int_bmux[49]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[49]), .XQ(XQ), .Q(Q_int[49]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ50 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[51]), .D(D_int_bmux[50]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[50]), .XQ(XQ), .Q(Q_int[50]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ51 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[52]), .D(D_int_bmux[51]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[51]), .XQ(XQ), .Q(Q_int[51]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ52 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[53]), .D(D_int_bmux[52]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[52]), .XQ(XQ), .Q(Q_int[52]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ53 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[54]), .D(D_int_bmux[53]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[53]), .XQ(XQ), .Q(Q_int[53]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ54 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[55]), .D(D_int_bmux[54]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[54]), .XQ(XQ), .Q(Q_int[54]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ55 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[56]), .D(D_int_bmux[55]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[55]), .XQ(XQ), .Q(Q_int[55]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ56 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[57]), .D(D_int_bmux[56]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[56]), .XQ(XQ), .Q(Q_int[56]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ57 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[58]), .D(D_int_bmux[57]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[57]), .XQ(XQ), .Q(Q_int[57]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ58 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[59]), .D(D_int_bmux[58]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[58]), .XQ(XQ), .Q(Q_int[58]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ59 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[60]), .D(D_int_bmux[59]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[59]), .XQ(XQ), .Q(Q_int[59]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ60 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[61]), .D(D_int_bmux[60]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[60]), .XQ(XQ), .Q(Q_int[60]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ61 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[62]), .D(D_int_bmux[61]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[61]), .XQ(XQ), .Q(Q_int[61]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ62 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(Q_int[63]), .D(D_int_bmux[62]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[62]), .XQ(XQ), .Q(Q_int[62]));
  datapath_latch_ARM_SPSRAM_64X4096_M8_MEM uDQ63 (.CLK(CLK), .Q_update(Q_update), .D_update(D_sh_update), .SE(SE_), .SI(SI_int[1]), .D(D_int_bmux[63]), .DFTRAMBYP(DFTRAMBYP_), .mem_path(mem_path[63]), .XQ(XQ), .Q(Q_int[63]));


// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
 always @ (VDD or VDDP or VSS) begin
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
 end
`endif

  always @ NOT_CEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN63 begin
    WEN_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN62 begin
    WEN_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN61 begin
    WEN_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN60 begin
    WEN_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN59 begin
    WEN_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN58 begin
    WEN_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN57 begin
    WEN_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN56 begin
    WEN_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN55 begin
    WEN_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN54 begin
    WEN_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN53 begin
    WEN_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN52 begin
    WEN_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN51 begin
    WEN_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN50 begin
    WEN_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN49 begin
    WEN_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN48 begin
    WEN_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN47 begin
    WEN_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN46 begin
    WEN_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN45 begin
    WEN_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN44 begin
    WEN_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN43 begin
    WEN_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN42 begin
    WEN_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN41 begin
    WEN_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN40 begin
    WEN_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN39 begin
    WEN_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN38 begin
    WEN_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN37 begin
    WEN_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN36 begin
    WEN_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN35 begin
    WEN_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN34 begin
    WEN_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN33 begin
    WEN_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN32 begin
    WEN_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN31 begin
    WEN_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN30 begin
    WEN_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN29 begin
    WEN_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN28 begin
    WEN_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN27 begin
    WEN_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN26 begin
    WEN_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN25 begin
    WEN_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN24 begin
    WEN_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN23 begin
    WEN_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN22 begin
    WEN_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN21 begin
    WEN_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN20 begin
    WEN_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN19 begin
    WEN_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN18 begin
    WEN_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN17 begin
    WEN_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN16 begin
    WEN_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN15 begin
    WEN_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN14 begin
    WEN_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN13 begin
    WEN_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN12 begin
    WEN_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN11 begin
    WEN_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN10 begin
    WEN_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN9 begin
    WEN_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN8 begin
    WEN_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN7 begin
    WEN_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN6 begin
    WEN_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN5 begin
    WEN_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN4 begin
    WEN_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN3 begin
    WEN_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN2 begin
    WEN_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN1 begin
    WEN_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN0 begin
    WEN_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A11 begin
    A_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A10 begin
    A_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A9 begin
    A_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D63 begin
    D_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D62 begin
    D_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D61 begin
    D_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D60 begin
    D_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D59 begin
    D_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D58 begin
    D_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D57 begin
    D_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D56 begin
    D_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D55 begin
    D_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D54 begin
    D_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D53 begin
    D_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D52 begin
    D_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D51 begin
    D_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D50 begin
    D_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D49 begin
    D_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D48 begin
    D_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D47 begin
    D_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D46 begin
    D_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D45 begin
    D_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D44 begin
    D_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D43 begin
    D_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D42 begin
    D_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D41 begin
    D_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D40 begin
    D_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D39 begin
    D_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D38 begin
    D_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D37 begin
    D_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D36 begin
    D_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D35 begin
    D_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D34 begin
    D_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D33 begin
    D_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D32 begin
    D_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D31 begin
    D_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D30 begin
    D_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D29 begin
    D_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D28 begin
    D_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D27 begin
    D_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D26 begin
    D_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D25 begin
    D_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D24 begin
    D_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D23 begin
    D_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D22 begin
    D_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D21 begin
    D_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D20 begin
    D_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D19 begin
    D_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D18 begin
    D_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D17 begin
    D_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D16 begin
    D_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D15 begin
    D_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D14 begin
    D_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D13 begin
    D_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D12 begin
    D_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D11 begin
    D_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D10 begin
    D_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D9 begin
    D_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D8 begin
    D_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA2 begin
    EMA_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA1 begin
    EMA_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA0 begin
    EMA_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW1 begin
    EMAW_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW0 begin
    EMAW_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TEN begin
    TEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TCEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN63 begin
    WEN_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN62 begin
    WEN_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN61 begin
    WEN_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN60 begin
    WEN_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN59 begin
    WEN_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN58 begin
    WEN_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN57 begin
    WEN_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN56 begin
    WEN_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN55 begin
    WEN_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN54 begin
    WEN_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN53 begin
    WEN_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN52 begin
    WEN_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN51 begin
    WEN_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN50 begin
    WEN_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN49 begin
    WEN_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN48 begin
    WEN_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN47 begin
    WEN_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN46 begin
    WEN_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN45 begin
    WEN_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN44 begin
    WEN_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN43 begin
    WEN_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN42 begin
    WEN_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN41 begin
    WEN_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN40 begin
    WEN_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN39 begin
    WEN_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN38 begin
    WEN_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN37 begin
    WEN_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN36 begin
    WEN_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN35 begin
    WEN_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN34 begin
    WEN_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN33 begin
    WEN_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN32 begin
    WEN_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN31 begin
    WEN_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN30 begin
    WEN_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN29 begin
    WEN_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN28 begin
    WEN_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN27 begin
    WEN_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN26 begin
    WEN_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN25 begin
    WEN_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN24 begin
    WEN_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN23 begin
    WEN_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN22 begin
    WEN_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN21 begin
    WEN_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN20 begin
    WEN_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN19 begin
    WEN_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN18 begin
    WEN_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN17 begin
    WEN_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN16 begin
    WEN_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN15 begin
    WEN_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN14 begin
    WEN_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN13 begin
    WEN_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN12 begin
    WEN_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN11 begin
    WEN_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN10 begin
    WEN_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN9 begin
    WEN_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN8 begin
    WEN_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN7 begin
    WEN_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN6 begin
    WEN_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN5 begin
    WEN_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN4 begin
    WEN_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN3 begin
    WEN_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN2 begin
    WEN_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN1 begin
    WEN_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN0 begin
    WEN_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA11 begin
    A_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA10 begin
    A_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA9 begin
    A_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD63 begin
    D_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD62 begin
    D_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD61 begin
    D_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD60 begin
    D_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD59 begin
    D_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD58 begin
    D_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD57 begin
    D_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD56 begin
    D_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD55 begin
    D_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD54 begin
    D_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD53 begin
    D_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD52 begin
    D_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD51 begin
    D_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD50 begin
    D_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD49 begin
    D_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD48 begin
    D_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD47 begin
    D_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD46 begin
    D_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD45 begin
    D_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD44 begin
    D_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD43 begin
    D_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD42 begin
    D_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD41 begin
    D_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD40 begin
    D_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD39 begin
    D_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD38 begin
    D_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD37 begin
    D_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD36 begin
    D_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD35 begin
    D_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD34 begin
    D_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD33 begin
    D_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD32 begin
    D_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD31 begin
    D_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD30 begin
    D_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD29 begin
    D_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD28 begin
    D_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD27 begin
    D_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD26 begin
    D_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD25 begin
    D_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD24 begin
    D_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD23 begin
    D_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD22 begin
    D_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD21 begin
    D_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD20 begin
    D_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD19 begin
    D_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD18 begin
    D_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD17 begin
    D_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD16 begin
    D_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD15 begin
    D_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD14 begin
    D_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD13 begin
    D_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD12 begin
    D_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD11 begin
    D_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD10 begin
    D_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD9 begin
    D_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD8 begin
    D_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_GWEN begin
    GWEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TGWEN begin
    GWEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_SI1 begin
        XQ = 1'b1; Q_update = 1'b1;
  end
  always @ NOT_SI0 begin
        XQ = 1'b1; Q_update = 1'b1;
  end
  always @ NOT_SE begin
        XQ = 1'b1; Q_update = 1'b1;
    SE_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_DFTRAMBYP begin
    DFTRAMBYP_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_RET1N begin
    RET1N_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end

  always @ NOT_CLK_PER begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINH begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINL begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end


  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0;
  wire RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0;

  wire RET1Neq1aTENeq1, RET1Neq1aTENeq0, RET1Neq1aTENeq1aCENeq0, RET1Neq1aTENeq0aTCENeq0;
  wire RET1Neq1aSEeq1, RET1Neq1;

  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[63] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[62] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[61] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[60] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[59] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[58] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[57] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[56] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[55] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[54] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[53] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[52] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[51] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[50] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[49] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[48] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[47] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[46] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[45] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[44] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[43] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[42] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[41] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[40] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[39] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[38] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[37] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[36] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[35] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[34] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[33] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[32] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[31] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[30] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[29] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[28] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[27] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[26] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[25] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[24] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[23] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[22] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[21] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[20] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[19] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[18] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[17] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[16] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[15] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[14] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[13] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[12] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[11] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[10] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[9] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[8] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[7] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[6] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[5] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[4] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[3] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[2] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[1] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[0] && !GWEN));
  assign RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[63] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[62] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[61] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[60] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[59] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[58] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[57] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[56] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[55] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[54] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[53] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[52] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[51] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[50] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[49] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[48] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[47] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[46] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[45] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[44] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[43] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[42] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[41] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[40] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[39] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[38] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[37] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[36] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[35] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[34] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[33] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[32] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[31] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[30] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[29] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[28] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[27] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[26] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[25] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[24] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[23] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[22] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[21] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[20] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[19] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[18] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[17] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[16] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[15] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[14] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[13] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[12] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[11] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[10] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[9] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[8] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[7] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[6] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[5] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[4] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[3] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[2] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[1] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[0] && !TGWEN));


  assign RET1Neq1aTENeq1aCENeq0 = RET1N && TEN && !CEN;
  assign RET1Neq1aTENeq0aTCENeq0 = RET1N && !TEN && !TCEN;

  assign RET1Neq1aTENeq1 = RET1N && TEN;
  assign RET1Neq1aTENeq0 = RET1N && !TEN;
  assign RET1Neq1aSEeq1 = RET1N && SE;
  assign RET1Neq1 = RET1N;

  specify

    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (CEN +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TCEN +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && CEN == 1'b0 && TCEN == 1'b1)
       (TEN -=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && CEN == 1'b1 && TCEN == 1'b0)
       (TEN +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[63] == 1'b0 && TWEN[63] == 1'b1)
       (TEN -=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[63] == 1'b1 && TWEN[63] == 1'b0)
       (TEN +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[62] == 1'b0 && TWEN[62] == 1'b1)
       (TEN -=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[62] == 1'b1 && TWEN[62] == 1'b0)
       (TEN +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[61] == 1'b0 && TWEN[61] == 1'b1)
       (TEN -=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[61] == 1'b1 && TWEN[61] == 1'b0)
       (TEN +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[60] == 1'b0 && TWEN[60] == 1'b1)
       (TEN -=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[60] == 1'b1 && TWEN[60] == 1'b0)
       (TEN +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[59] == 1'b0 && TWEN[59] == 1'b1)
       (TEN -=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[59] == 1'b1 && TWEN[59] == 1'b0)
       (TEN +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[58] == 1'b0 && TWEN[58] == 1'b1)
       (TEN -=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[58] == 1'b1 && TWEN[58] == 1'b0)
       (TEN +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[57] == 1'b0 && TWEN[57] == 1'b1)
       (TEN -=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[57] == 1'b1 && TWEN[57] == 1'b0)
       (TEN +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[56] == 1'b0 && TWEN[56] == 1'b1)
       (TEN -=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[56] == 1'b1 && TWEN[56] == 1'b0)
       (TEN +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[55] == 1'b0 && TWEN[55] == 1'b1)
       (TEN -=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[55] == 1'b1 && TWEN[55] == 1'b0)
       (TEN +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[54] == 1'b0 && TWEN[54] == 1'b1)
       (TEN -=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[54] == 1'b1 && TWEN[54] == 1'b0)
       (TEN +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[53] == 1'b0 && TWEN[53] == 1'b1)
       (TEN -=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[53] == 1'b1 && TWEN[53] == 1'b0)
       (TEN +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[52] == 1'b0 && TWEN[52] == 1'b1)
       (TEN -=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[52] == 1'b1 && TWEN[52] == 1'b0)
       (TEN +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[51] == 1'b0 && TWEN[51] == 1'b1)
       (TEN -=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[51] == 1'b1 && TWEN[51] == 1'b0)
       (TEN +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[50] == 1'b0 && TWEN[50] == 1'b1)
       (TEN -=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[50] == 1'b1 && TWEN[50] == 1'b0)
       (TEN +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[49] == 1'b0 && TWEN[49] == 1'b1)
       (TEN -=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[49] == 1'b1 && TWEN[49] == 1'b0)
       (TEN +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[48] == 1'b0 && TWEN[48] == 1'b1)
       (TEN -=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[48] == 1'b1 && TWEN[48] == 1'b0)
       (TEN +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[47] == 1'b0 && TWEN[47] == 1'b1)
       (TEN -=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[47] == 1'b1 && TWEN[47] == 1'b0)
       (TEN +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[46] == 1'b0 && TWEN[46] == 1'b1)
       (TEN -=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[46] == 1'b1 && TWEN[46] == 1'b0)
       (TEN +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[45] == 1'b0 && TWEN[45] == 1'b1)
       (TEN -=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[45] == 1'b1 && TWEN[45] == 1'b0)
       (TEN +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[44] == 1'b0 && TWEN[44] == 1'b1)
       (TEN -=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[44] == 1'b1 && TWEN[44] == 1'b0)
       (TEN +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[43] == 1'b0 && TWEN[43] == 1'b1)
       (TEN -=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[43] == 1'b1 && TWEN[43] == 1'b0)
       (TEN +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[42] == 1'b0 && TWEN[42] == 1'b1)
       (TEN -=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[42] == 1'b1 && TWEN[42] == 1'b0)
       (TEN +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[41] == 1'b0 && TWEN[41] == 1'b1)
       (TEN -=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[41] == 1'b1 && TWEN[41] == 1'b0)
       (TEN +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[40] == 1'b0 && TWEN[40] == 1'b1)
       (TEN -=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[40] == 1'b1 && TWEN[40] == 1'b0)
       (TEN +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[39] == 1'b0 && TWEN[39] == 1'b1)
       (TEN -=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[39] == 1'b1 && TWEN[39] == 1'b0)
       (TEN +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[38] == 1'b0 && TWEN[38] == 1'b1)
       (TEN -=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[38] == 1'b1 && TWEN[38] == 1'b0)
       (TEN +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[37] == 1'b0 && TWEN[37] == 1'b1)
       (TEN -=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[37] == 1'b1 && TWEN[37] == 1'b0)
       (TEN +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[36] == 1'b0 && TWEN[36] == 1'b1)
       (TEN -=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[36] == 1'b1 && TWEN[36] == 1'b0)
       (TEN +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[35] == 1'b0 && TWEN[35] == 1'b1)
       (TEN -=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[35] == 1'b1 && TWEN[35] == 1'b0)
       (TEN +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[34] == 1'b0 && TWEN[34] == 1'b1)
       (TEN -=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[34] == 1'b1 && TWEN[34] == 1'b0)
       (TEN +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[33] == 1'b0 && TWEN[33] == 1'b1)
       (TEN -=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[33] == 1'b1 && TWEN[33] == 1'b0)
       (TEN +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[32] == 1'b0 && TWEN[32] == 1'b1)
       (TEN -=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[32] == 1'b1 && TWEN[32] == 1'b0)
       (TEN +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[31] == 1'b0 && TWEN[31] == 1'b1)
       (TEN -=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[31] == 1'b1 && TWEN[31] == 1'b0)
       (TEN +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[30] == 1'b0 && TWEN[30] == 1'b1)
       (TEN -=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[30] == 1'b1 && TWEN[30] == 1'b0)
       (TEN +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[29] == 1'b0 && TWEN[29] == 1'b1)
       (TEN -=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[29] == 1'b1 && TWEN[29] == 1'b0)
       (TEN +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[28] == 1'b0 && TWEN[28] == 1'b1)
       (TEN -=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[28] == 1'b1 && TWEN[28] == 1'b0)
       (TEN +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[27] == 1'b0 && TWEN[27] == 1'b1)
       (TEN -=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[27] == 1'b1 && TWEN[27] == 1'b0)
       (TEN +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[26] == 1'b0 && TWEN[26] == 1'b1)
       (TEN -=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[26] == 1'b1 && TWEN[26] == 1'b0)
       (TEN +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[25] == 1'b0 && TWEN[25] == 1'b1)
       (TEN -=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[25] == 1'b1 && TWEN[25] == 1'b0)
       (TEN +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[24] == 1'b0 && TWEN[24] == 1'b1)
       (TEN -=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[24] == 1'b1 && TWEN[24] == 1'b0)
       (TEN +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[23] == 1'b0 && TWEN[23] == 1'b1)
       (TEN -=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[23] == 1'b1 && TWEN[23] == 1'b0)
       (TEN +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[22] == 1'b0 && TWEN[22] == 1'b1)
       (TEN -=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[22] == 1'b1 && TWEN[22] == 1'b0)
       (TEN +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[21] == 1'b0 && TWEN[21] == 1'b1)
       (TEN -=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[21] == 1'b1 && TWEN[21] == 1'b0)
       (TEN +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[20] == 1'b0 && TWEN[20] == 1'b1)
       (TEN -=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[20] == 1'b1 && TWEN[20] == 1'b0)
       (TEN +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[19] == 1'b0 && TWEN[19] == 1'b1)
       (TEN -=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[19] == 1'b1 && TWEN[19] == 1'b0)
       (TEN +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[18] == 1'b0 && TWEN[18] == 1'b1)
       (TEN -=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[18] == 1'b1 && TWEN[18] == 1'b0)
       (TEN +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[17] == 1'b0 && TWEN[17] == 1'b1)
       (TEN -=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[17] == 1'b1 && TWEN[17] == 1'b0)
       (TEN +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[16] == 1'b0 && TWEN[16] == 1'b1)
       (TEN -=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[16] == 1'b1 && TWEN[16] == 1'b0)
       (TEN +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[15] == 1'b0 && TWEN[15] == 1'b1)
       (TEN -=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[15] == 1'b1 && TWEN[15] == 1'b0)
       (TEN +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[14] == 1'b0 && TWEN[14] == 1'b1)
       (TEN -=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[14] == 1'b1 && TWEN[14] == 1'b0)
       (TEN +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[13] == 1'b0 && TWEN[13] == 1'b1)
       (TEN -=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[13] == 1'b1 && TWEN[13] == 1'b0)
       (TEN +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[12] == 1'b0 && TWEN[12] == 1'b1)
       (TEN -=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[12] == 1'b1 && TWEN[12] == 1'b0)
       (TEN +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[11] == 1'b0 && TWEN[11] == 1'b1)
       (TEN -=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[11] == 1'b1 && TWEN[11] == 1'b0)
       (TEN +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[10] == 1'b0 && TWEN[10] == 1'b1)
       (TEN -=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[10] == 1'b1 && TWEN[10] == 1'b0)
       (TEN +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[9] == 1'b0 && TWEN[9] == 1'b1)
       (TEN -=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[9] == 1'b1 && TWEN[9] == 1'b0)
       (TEN +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[8] == 1'b0 && TWEN[8] == 1'b1)
       (TEN -=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[8] == 1'b1 && TWEN[8] == 1'b0)
       (TEN +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[7] == 1'b0 && TWEN[7] == 1'b1)
       (TEN -=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[7] == 1'b1 && TWEN[7] == 1'b0)
       (TEN +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[6] == 1'b0 && TWEN[6] == 1'b1)
       (TEN -=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[6] == 1'b1 && TWEN[6] == 1'b0)
       (TEN +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[5] == 1'b0 && TWEN[5] == 1'b1)
       (TEN -=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[5] == 1'b1 && TWEN[5] == 1'b0)
       (TEN +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[4] == 1'b0 && TWEN[4] == 1'b1)
       (TEN -=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[4] == 1'b1 && TWEN[4] == 1'b0)
       (TEN +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[3] == 1'b0 && TWEN[3] == 1'b1)
       (TEN -=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[3] == 1'b1 && TWEN[3] == 1'b0)
       (TEN +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[2] == 1'b0 && TWEN[2] == 1'b1)
       (TEN -=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[2] == 1'b1 && TWEN[2] == 1'b0)
       (TEN +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[1] == 1'b0 && TWEN[1] == 1'b1)
       (TEN -=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[1] == 1'b1 && TWEN[1] == 1'b0)
       (TEN +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[0] == 1'b0 && TWEN[0] == 1'b1)
       (TEN -=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[0] == 1'b1 && TWEN[0] == 1'b0)
       (TEN +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[63] +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[62] +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[61] +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[60] +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[59] +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[58] +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[57] +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[56] +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[55] +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[54] +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[53] +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[52] +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[51] +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[50] +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[49] +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[48] +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[47] +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[46] +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[45] +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[44] +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[43] +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[42] +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[41] +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[40] +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[39] +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[38] +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[37] +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[36] +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[35] +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[34] +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[33] +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[32] +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[31] +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[30] +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[29] +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[28] +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[27] +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[26] +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[25] +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[24] +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[23] +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[22] +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[21] +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[20] +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[19] +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[18] +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[17] +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[16] +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[15] +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[14] +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[13] +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[12] +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[11] +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[10] +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[9] +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[8] +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[7] +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[6] +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[5] +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[4] +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[3] +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[2] +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[1] +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[0] +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[63] +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[62] +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[61] +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[60] +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[59] +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[58] +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[57] +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[56] +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[55] +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[54] +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[53] +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[52] +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[51] +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[50] +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[49] +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[48] +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[47] +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[46] +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[45] +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[44] +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[43] +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[42] +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[41] +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[40] +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[39] +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[38] +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[37] +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[36] +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[35] +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[34] +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[33] +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[32] +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[31] +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[30] +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[29] +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[28] +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[27] +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[26] +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[25] +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[24] +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[23] +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[22] +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[21] +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[20] +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[19] +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[18] +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[17] +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[16] +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[15] +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[14] +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[13] +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[12] +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[11] +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[10] +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[9] +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[8] +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[7] +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[6] +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[5] +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[4] +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[3] +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[2] +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[1] +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[0] +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[11] == 1'b0 && TA[11] == 1'b1)
       (TEN -=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[11] == 1'b1 && TA[11] == 1'b0)
       (TEN +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[10] == 1'b0 && TA[10] == 1'b1)
       (TEN -=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[10] == 1'b1 && TA[10] == 1'b0)
       (TEN +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[9] == 1'b0 && TA[9] == 1'b1)
       (TEN -=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[9] == 1'b1 && TA[9] == 1'b0)
       (TEN +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[8] == 1'b0 && TA[8] == 1'b1)
       (TEN -=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[8] == 1'b1 && TA[8] == 1'b0)
       (TEN +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[7] == 1'b0 && TA[7] == 1'b1)
       (TEN -=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[7] == 1'b1 && TA[7] == 1'b0)
       (TEN +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[6] == 1'b0 && TA[6] == 1'b1)
       (TEN -=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[6] == 1'b1 && TA[6] == 1'b0)
       (TEN +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[5] == 1'b0 && TA[5] == 1'b1)
       (TEN -=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[5] == 1'b1 && TA[5] == 1'b0)
       (TEN +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[4] == 1'b0 && TA[4] == 1'b1)
       (TEN -=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[4] == 1'b1 && TA[4] == 1'b0)
       (TEN +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[3] == 1'b0 && TA[3] == 1'b1)
       (TEN -=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[3] == 1'b1 && TA[3] == 1'b0)
       (TEN +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[2] == 1'b0 && TA[2] == 1'b1)
       (TEN -=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[2] == 1'b1 && TA[2] == 1'b0)
       (TEN +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[1] == 1'b0 && TA[1] == 1'b1)
       (TEN -=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[1] == 1'b1 && TA[1] == 1'b0)
       (TEN +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[0] == 1'b0 && TA[0] == 1'b1)
       (TEN -=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[0] == 1'b1 && TA[0] == 1'b0)
       (TEN +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[11] +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[10] +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[9] +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[8] +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[7] +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[6] +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[5] +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[4] +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[3] +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[2] +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[1] +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[0] +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[11] +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[10] +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[9] +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[8] +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[7] +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[6] +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[5] +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[4] +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[3] +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[2] +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[1] +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[0] +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (GWEN +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TGWEN +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && GWEN == 1'b0 && TGWEN == 1'b1)
       (TEN -=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && GWEN == 1'b1 && TGWEN == 1'b0)
       (TEN +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);


   // Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $period(posedge CLK, `ARM_MEM_PERIOD, NOT_CLK_PER);
   `else
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
   `endif


   // Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $width(posedge CLK, `ARM_MEM_WIDTH, 0, NOT_CLK_MINH);
       $width(negedge CLK, `ARM_MEM_WIDTH, 0, NOT_CLK_MINL);
   `else
       $width(posedge CLK &&& RET1Neq1, `ARM_MEM_WIDTH, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& RET1Neq1, `ARM_MEM_WIDTH, 0, NOT_CLK_MINL);
   `endif

    $setuphold(posedge CLK &&& RET1Neq1aTENeq1, posedge CEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_CEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1, negedge CEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_CEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0, posedge D[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0, negedge D[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0, posedge D[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0, negedge D[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0, posedge D[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0, negedge D[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0, posedge D[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0, negedge D[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0, posedge D[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0, negedge D[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0, posedge D[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0, negedge D[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0, posedge D[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0, negedge D[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0, posedge D[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0, negedge D[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0, posedge D[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0, negedge D[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0, posedge D[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0, negedge D[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0, posedge D[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0, negedge D[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0, posedge D[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0, negedge D[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0, posedge D[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0, negedge D[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0, posedge D[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0, negedge D[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0, posedge D[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0, negedge D[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0, posedge D[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0, negedge D[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0, posedge D[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0, negedge D[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0, posedge D[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0, negedge D[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0, posedge D[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0, negedge D[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0, posedge D[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0, negedge D[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0, posedge D[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0, negedge D[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0, posedge D[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0, negedge D[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0, posedge D[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0, negedge D[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0, posedge D[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0, negedge D[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0, posedge D[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0, negedge D[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0, posedge D[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0, negedge D[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0, posedge D[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0, negedge D[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0, posedge D[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0, negedge D[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0, posedge D[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0, negedge D[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0, posedge D[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0, negedge D[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0, posedge D[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0, negedge D[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0, posedge D[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0, negedge D[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0, posedge D[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0, negedge D[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0, posedge D[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0, negedge D[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0, posedge D[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0, negedge D[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0, posedge D[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0, negedge D[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0, posedge D[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0, negedge D[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0, posedge D[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0, negedge D[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0, posedge D[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0, negedge D[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0, posedge D[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0, negedge D[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0, posedge D[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0, negedge D[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0, posedge D[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0, negedge D[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0, posedge D[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0, negedge D[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0, posedge D[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0, negedge D[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0, posedge D[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0, negedge D[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0, posedge D[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0, negedge D[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0, posedge D[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0, negedge D[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0, posedge D[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0, negedge D[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0, posedge D[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0, negedge D[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0, posedge D[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0, negedge D[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0, posedge D[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0, negedge D[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0, posedge D[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0, negedge D[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0, posedge D[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0, negedge D[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0, posedge D[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0, negedge D[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0, posedge D[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0, negedge D[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0, posedge D[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0, negedge D[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0, posedge D[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0, negedge D[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0, posedge D[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0, negedge D[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0, posedge D[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0, negedge D[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0, posedge D[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0, negedge D[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0, posedge D[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0, negedge D[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0, posedge D[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0, negedge D[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0, posedge D[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0, negedge D[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0, posedge D[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0, negedge D[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMAW[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMAW[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMAW[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMAW[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW0);
    $setuphold(posedge CLK &&& RET1Neq1, posedge TEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TEN);
    $setuphold(posedge CLK &&& RET1Neq1, negedge TEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0, posedge TCEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TCEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0, negedge TCEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TCEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0, posedge TD[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0, negedge TD[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0, posedge TD[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0, negedge TD[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0, posedge TD[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0, negedge TD[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0, posedge TD[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0, negedge TD[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0, posedge TD[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0, negedge TD[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0, posedge TD[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0, negedge TD[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0, posedge TD[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0, negedge TD[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0, posedge TD[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0, negedge TD[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0, posedge TD[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0, negedge TD[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0, posedge TD[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0, negedge TD[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0, posedge TD[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0, negedge TD[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0, posedge TD[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0, negedge TD[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0, posedge TD[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0, negedge TD[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0, posedge TD[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0, negedge TD[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0, posedge TD[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0, negedge TD[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0, posedge TD[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0, negedge TD[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0, posedge TD[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0, negedge TD[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0, posedge TD[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0, negedge TD[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0, posedge TD[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0, negedge TD[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0, posedge TD[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0, negedge TD[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0, posedge TD[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0, negedge TD[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0, posedge TD[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0, negedge TD[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0, posedge TD[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0, negedge TD[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0, posedge TD[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0, negedge TD[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0, posedge TD[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0, negedge TD[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0, posedge TD[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0, negedge TD[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0, posedge TD[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0, negedge TD[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0, posedge TD[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0, negedge TD[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0, posedge TD[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0, negedge TD[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0, posedge TD[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0, negedge TD[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0, posedge TD[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0, negedge TD[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0, posedge TD[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0, negedge TD[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0, posedge TD[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0, negedge TD[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0, posedge TD[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0, negedge TD[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0, posedge TD[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0, negedge TD[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0, posedge TD[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0, negedge TD[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0, posedge TD[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0, negedge TD[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0, posedge TD[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0, negedge TD[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0, posedge TD[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0, negedge TD[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0, posedge TD[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0, negedge TD[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0, posedge TD[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0, negedge TD[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0, posedge TD[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0, negedge TD[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0, posedge TD[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0, negedge TD[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0, posedge TD[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0, negedge TD[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0, posedge TD[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0, negedge TD[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0, posedge TD[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0, negedge TD[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0, posedge TD[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0, negedge TD[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0, posedge TD[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0, negedge TD[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0, posedge TD[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0, negedge TD[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0, posedge TD[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0, negedge TD[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0, posedge TD[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0, negedge TD[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0, posedge TD[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0, negedge TD[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0, posedge TD[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0, negedge TD[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0, posedge TD[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0, negedge TD[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0, posedge TD[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0, negedge TD[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0, posedge TD[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0, negedge TD[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0, posedge TD[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0, negedge TD[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0, posedge TD[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0, negedge TD[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0, posedge TD[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0, negedge TD[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0, posedge TD[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0, negedge TD[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0, posedge TD[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0, negedge TD[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0, posedge TD[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0, negedge TD[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0, posedge TD[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0, negedge TD[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0, posedge TD[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0, negedge TD[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge GWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_GWEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge GWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_GWEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TGWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TGWEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TGWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TGWEN);
    $setuphold(posedge CLK, posedge RET1N, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CLK, negedge RET1N, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, posedge SI[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI1);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, posedge SI[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI0);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, negedge SI[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI1);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, negedge SI[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI0);
    $setuphold(posedge CLK &&& RET1Neq1, posedge SE, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SE);
    $setuphold(posedge CLK &&& RET1Neq1, negedge SE, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SE);
    $setuphold(posedge CLK &&& RET1Neq1, posedge DFTRAMBYP, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_DFTRAMBYP);
    $setuphold(posedge CLK &&& RET1Neq1, negedge DFTRAMBYP, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_DFTRAMBYP);
    $setuphold(negedge RET1N, negedge CEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge RET1N, negedge CEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge RET1N, negedge TCEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge RET1N, negedge TCEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge DFTRAMBYP, posedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge DFTRAMBYP, negedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CEN, negedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CEN, posedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge TCEN, negedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge TCEN, posedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge RET1N, posedge DFTRAMBYP, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge RET1N, posedge DFTRAMBYP, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
  endspecify


endmodule
`endcelldefine
  `endif
  `else
// If ARM_UD_MODEL is defined at Simulator Command Line, it Selects the Fast Functional Model
`ifdef ARM_UD_MODEL

// Following parameter Values can be overridden at Simulator Command Line.

// ARM_UD_DP Defines the delay through Data Paths, for Memory Models it represents BIST MUX output delays.
`ifdef ARM_UD_DP
`else
`define ARM_UD_DP #0.001
`endif
// ARM_UD_CP Defines the delay through Clock Path Cells, for Memory Models it is not used.
`ifdef ARM_UD_CP
`else
`define ARM_UD_CP
`endif
// ARM_UD_SEQ Defines the delay through the Memory, for Memory Models it is used for CLK->Q delays.
`ifdef ARM_UD_SEQ
`else
`define ARM_UD_SEQ #0.01
`endif

`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module ARM_SPSRAM_64X4096_M8_MEM (VDD, VDDP, VSS, CENY, WENY, AY, GWENY, Q, SO, CLK,
    CEN, WEN, A, D, EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE,
    DFTRAMBYP);
`else
module ARM_SPSRAM_64X4096_M8_MEM (CENY, WENY, AY, GWENY, Q, SO, CLK, CEN, WEN, A, D,
    EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE, DFTRAMBYP);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 64;
  parameter WORDS = 4096;
  parameter MUX = 8;
  parameter MEM_WIDTH = 512; // redun block size 8, 256 on left, 256 on right
  parameter MEM_HEIGHT = 512;
  parameter WP_SIZE = 1 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 0;

  output  CENY;
  output [63:0] WENY;
  output [11:0] AY;
  output  GWENY;
  output [63:0] Q;
  output [1:0] SO;
  input  CLK;
  input  CEN;
  input [63:0] WEN;
  input [11:0] A;
  input [63:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  TEN;
  input  TCEN;
  input [63:0] TWEN;
  input [11:0] TA;
  input [63:0] TD;
  input  GWEN;
  input  TGWEN;
  input  RET1N;
  input [1:0] SI;
  input  SE;
  input  DFTRAMBYP;
`ifdef POWER_PINS
  inout VDD;
  inout VDDP;
  inout VSS;
`endif

  reg pre_charge_st;
  integer row_address;
  integer mux_address;
  initial row_address = 0;
  initial mux_address = 0;
  reg [511:0] mem [0:511];
  reg [511:0] row, row_t;
  reg LAST_CLK;
  reg [511:0] row_mask;
  reg [511:0] new_data;
  reg [511:0] data_out;
  reg [63:0] readLatch0;
  reg [63:0] shifted_readLatch0;
  reg  read_mux_sel0_p2;
  reg [63:0] Q_int;
  reg [63:0] writeEnable;
  reg clk0_int;

  wire  CENY_;
  wire [63:0] WENY_;
  wire [11:0] AY_;
  wire  GWENY_;
  wire [63:0] Q_;
  wire [1:0] SO_;
  reg [1:0] SO_int;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire [63:0] WEN_;
  reg [63:0] WEN_int;
  wire [11:0] A_;
  reg [11:0] A_int;
  wire [63:0] D_;
  reg [63:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  TEN_;
  reg  TEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire [63:0] TWEN_;
  reg [63:0] TWEN_int;
  wire [11:0] TA_;
  reg [11:0] TA_int;
  wire [63:0] TD_;
  reg [63:0] TD_int;
  wire  GWEN_;
  reg  GWEN_int;
  wire  TGWEN_;
  reg  TGWEN_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire [1:0] SI_;
  reg [1:0] SI_int;
  wire  SE_;
  reg  SE_int;
  wire  DFTRAMBYP_;
  reg  DFTRAMBYP_int;
  reg  DFTRAMBYP_p2;

  assign CENY = CENY_; 
  assign WENY[0] = WENY_[0]; 
  assign WENY[1] = WENY_[1]; 
  assign WENY[2] = WENY_[2]; 
  assign WENY[3] = WENY_[3]; 
  assign WENY[4] = WENY_[4]; 
  assign WENY[5] = WENY_[5]; 
  assign WENY[6] = WENY_[6]; 
  assign WENY[7] = WENY_[7]; 
  assign WENY[8] = WENY_[8]; 
  assign WENY[9] = WENY_[9]; 
  assign WENY[10] = WENY_[10]; 
  assign WENY[11] = WENY_[11]; 
  assign WENY[12] = WENY_[12]; 
  assign WENY[13] = WENY_[13]; 
  assign WENY[14] = WENY_[14]; 
  assign WENY[15] = WENY_[15]; 
  assign WENY[16] = WENY_[16]; 
  assign WENY[17] = WENY_[17]; 
  assign WENY[18] = WENY_[18]; 
  assign WENY[19] = WENY_[19]; 
  assign WENY[20] = WENY_[20]; 
  assign WENY[21] = WENY_[21]; 
  assign WENY[22] = WENY_[22]; 
  assign WENY[23] = WENY_[23]; 
  assign WENY[24] = WENY_[24]; 
  assign WENY[25] = WENY_[25]; 
  assign WENY[26] = WENY_[26]; 
  assign WENY[27] = WENY_[27]; 
  assign WENY[28] = WENY_[28]; 
  assign WENY[29] = WENY_[29]; 
  assign WENY[30] = WENY_[30]; 
  assign WENY[31] = WENY_[31]; 
  assign WENY[32] = WENY_[32]; 
  assign WENY[33] = WENY_[33]; 
  assign WENY[34] = WENY_[34]; 
  assign WENY[35] = WENY_[35]; 
  assign WENY[36] = WENY_[36]; 
  assign WENY[37] = WENY_[37]; 
  assign WENY[38] = WENY_[38]; 
  assign WENY[39] = WENY_[39]; 
  assign WENY[40] = WENY_[40]; 
  assign WENY[41] = WENY_[41]; 
  assign WENY[42] = WENY_[42]; 
  assign WENY[43] = WENY_[43]; 
  assign WENY[44] = WENY_[44]; 
  assign WENY[45] = WENY_[45]; 
  assign WENY[46] = WENY_[46]; 
  assign WENY[47] = WENY_[47]; 
  assign WENY[48] = WENY_[48]; 
  assign WENY[49] = WENY_[49]; 
  assign WENY[50] = WENY_[50]; 
  assign WENY[51] = WENY_[51]; 
  assign WENY[52] = WENY_[52]; 
  assign WENY[53] = WENY_[53]; 
  assign WENY[54] = WENY_[54]; 
  assign WENY[55] = WENY_[55]; 
  assign WENY[56] = WENY_[56]; 
  assign WENY[57] = WENY_[57]; 
  assign WENY[58] = WENY_[58]; 
  assign WENY[59] = WENY_[59]; 
  assign WENY[60] = WENY_[60]; 
  assign WENY[61] = WENY_[61]; 
  assign WENY[62] = WENY_[62]; 
  assign WENY[63] = WENY_[63]; 
  assign AY[0] = AY_[0]; 
  assign AY[1] = AY_[1]; 
  assign AY[2] = AY_[2]; 
  assign AY[3] = AY_[3]; 
  assign AY[4] = AY_[4]; 
  assign AY[5] = AY_[5]; 
  assign AY[6] = AY_[6]; 
  assign AY[7] = AY_[7]; 
  assign AY[8] = AY_[8]; 
  assign AY[9] = AY_[9]; 
  assign AY[10] = AY_[10]; 
  assign AY[11] = AY_[11]; 
  assign GWENY = GWENY_; 
  assign Q[0] = Q_[0]; 
  assign Q[1] = Q_[1]; 
  assign Q[2] = Q_[2]; 
  assign Q[3] = Q_[3]; 
  assign Q[4] = Q_[4]; 
  assign Q[5] = Q_[5]; 
  assign Q[6] = Q_[6]; 
  assign Q[7] = Q_[7]; 
  assign Q[8] = Q_[8]; 
  assign Q[9] = Q_[9]; 
  assign Q[10] = Q_[10]; 
  assign Q[11] = Q_[11]; 
  assign Q[12] = Q_[12]; 
  assign Q[13] = Q_[13]; 
  assign Q[14] = Q_[14]; 
  assign Q[15] = Q_[15]; 
  assign Q[16] = Q_[16]; 
  assign Q[17] = Q_[17]; 
  assign Q[18] = Q_[18]; 
  assign Q[19] = Q_[19]; 
  assign Q[20] = Q_[20]; 
  assign Q[21] = Q_[21]; 
  assign Q[22] = Q_[22]; 
  assign Q[23] = Q_[23]; 
  assign Q[24] = Q_[24]; 
  assign Q[25] = Q_[25]; 
  assign Q[26] = Q_[26]; 
  assign Q[27] = Q_[27]; 
  assign Q[28] = Q_[28]; 
  assign Q[29] = Q_[29]; 
  assign Q[30] = Q_[30]; 
  assign Q[31] = Q_[31]; 
  assign Q[32] = Q_[32]; 
  assign Q[33] = Q_[33]; 
  assign Q[34] = Q_[34]; 
  assign Q[35] = Q_[35]; 
  assign Q[36] = Q_[36]; 
  assign Q[37] = Q_[37]; 
  assign Q[38] = Q_[38]; 
  assign Q[39] = Q_[39]; 
  assign Q[40] = Q_[40]; 
  assign Q[41] = Q_[41]; 
  assign Q[42] = Q_[42]; 
  assign Q[43] = Q_[43]; 
  assign Q[44] = Q_[44]; 
  assign Q[45] = Q_[45]; 
  assign Q[46] = Q_[46]; 
  assign Q[47] = Q_[47]; 
  assign Q[48] = Q_[48]; 
  assign Q[49] = Q_[49]; 
  assign Q[50] = Q_[50]; 
  assign Q[51] = Q_[51]; 
  assign Q[52] = Q_[52]; 
  assign Q[53] = Q_[53]; 
  assign Q[54] = Q_[54]; 
  assign Q[55] = Q_[55]; 
  assign Q[56] = Q_[56]; 
  assign Q[57] = Q_[57]; 
  assign Q[58] = Q_[58]; 
  assign Q[59] = Q_[59]; 
  assign Q[60] = Q_[60]; 
  assign Q[61] = Q_[61]; 
  assign Q[62] = Q_[62]; 
  assign Q[63] = Q_[63]; 
  assign SO[0] = SO_[0]; 
  assign SO[1] = SO_[1]; 
  assign CLK_ = CLK;
  assign CEN_ = CEN;
  assign WEN_[0] = WEN[0];
  assign WEN_[1] = WEN[1];
  assign WEN_[2] = WEN[2];
  assign WEN_[3] = WEN[3];
  assign WEN_[4] = WEN[4];
  assign WEN_[5] = WEN[5];
  assign WEN_[6] = WEN[6];
  assign WEN_[7] = WEN[7];
  assign WEN_[8] = WEN[8];
  assign WEN_[9] = WEN[9];
  assign WEN_[10] = WEN[10];
  assign WEN_[11] = WEN[11];
  assign WEN_[12] = WEN[12];
  assign WEN_[13] = WEN[13];
  assign WEN_[14] = WEN[14];
  assign WEN_[15] = WEN[15];
  assign WEN_[16] = WEN[16];
  assign WEN_[17] = WEN[17];
  assign WEN_[18] = WEN[18];
  assign WEN_[19] = WEN[19];
  assign WEN_[20] = WEN[20];
  assign WEN_[21] = WEN[21];
  assign WEN_[22] = WEN[22];
  assign WEN_[23] = WEN[23];
  assign WEN_[24] = WEN[24];
  assign WEN_[25] = WEN[25];
  assign WEN_[26] = WEN[26];
  assign WEN_[27] = WEN[27];
  assign WEN_[28] = WEN[28];
  assign WEN_[29] = WEN[29];
  assign WEN_[30] = WEN[30];
  assign WEN_[31] = WEN[31];
  assign WEN_[32] = WEN[32];
  assign WEN_[33] = WEN[33];
  assign WEN_[34] = WEN[34];
  assign WEN_[35] = WEN[35];
  assign WEN_[36] = WEN[36];
  assign WEN_[37] = WEN[37];
  assign WEN_[38] = WEN[38];
  assign WEN_[39] = WEN[39];
  assign WEN_[40] = WEN[40];
  assign WEN_[41] = WEN[41];
  assign WEN_[42] = WEN[42];
  assign WEN_[43] = WEN[43];
  assign WEN_[44] = WEN[44];
  assign WEN_[45] = WEN[45];
  assign WEN_[46] = WEN[46];
  assign WEN_[47] = WEN[47];
  assign WEN_[48] = WEN[48];
  assign WEN_[49] = WEN[49];
  assign WEN_[50] = WEN[50];
  assign WEN_[51] = WEN[51];
  assign WEN_[52] = WEN[52];
  assign WEN_[53] = WEN[53];
  assign WEN_[54] = WEN[54];
  assign WEN_[55] = WEN[55];
  assign WEN_[56] = WEN[56];
  assign WEN_[57] = WEN[57];
  assign WEN_[58] = WEN[58];
  assign WEN_[59] = WEN[59];
  assign WEN_[60] = WEN[60];
  assign WEN_[61] = WEN[61];
  assign WEN_[62] = WEN[62];
  assign WEN_[63] = WEN[63];
  assign A_[0] = A[0];
  assign A_[1] = A[1];
  assign A_[2] = A[2];
  assign A_[3] = A[3];
  assign A_[4] = A[4];
  assign A_[5] = A[5];
  assign A_[6] = A[6];
  assign A_[7] = A[7];
  assign A_[8] = A[8];
  assign A_[9] = A[9];
  assign A_[10] = A[10];
  assign A_[11] = A[11];
  assign D_[0] = D[0];
  assign D_[1] = D[1];
  assign D_[2] = D[2];
  assign D_[3] = D[3];
  assign D_[4] = D[4];
  assign D_[5] = D[5];
  assign D_[6] = D[6];
  assign D_[7] = D[7];
  assign D_[8] = D[8];
  assign D_[9] = D[9];
  assign D_[10] = D[10];
  assign D_[11] = D[11];
  assign D_[12] = D[12];
  assign D_[13] = D[13];
  assign D_[14] = D[14];
  assign D_[15] = D[15];
  assign D_[16] = D[16];
  assign D_[17] = D[17];
  assign D_[18] = D[18];
  assign D_[19] = D[19];
  assign D_[20] = D[20];
  assign D_[21] = D[21];
  assign D_[22] = D[22];
  assign D_[23] = D[23];
  assign D_[24] = D[24];
  assign D_[25] = D[25];
  assign D_[26] = D[26];
  assign D_[27] = D[27];
  assign D_[28] = D[28];
  assign D_[29] = D[29];
  assign D_[30] = D[30];
  assign D_[31] = D[31];
  assign D_[32] = D[32];
  assign D_[33] = D[33];
  assign D_[34] = D[34];
  assign D_[35] = D[35];
  assign D_[36] = D[36];
  assign D_[37] = D[37];
  assign D_[38] = D[38];
  assign D_[39] = D[39];
  assign D_[40] = D[40];
  assign D_[41] = D[41];
  assign D_[42] = D[42];
  assign D_[43] = D[43];
  assign D_[44] = D[44];
  assign D_[45] = D[45];
  assign D_[46] = D[46];
  assign D_[47] = D[47];
  assign D_[48] = D[48];
  assign D_[49] = D[49];
  assign D_[50] = D[50];
  assign D_[51] = D[51];
  assign D_[52] = D[52];
  assign D_[53] = D[53];
  assign D_[54] = D[54];
  assign D_[55] = D[55];
  assign D_[56] = D[56];
  assign D_[57] = D[57];
  assign D_[58] = D[58];
  assign D_[59] = D[59];
  assign D_[60] = D[60];
  assign D_[61] = D[61];
  assign D_[62] = D[62];
  assign D_[63] = D[63];
  assign EMA_[0] = EMA[0];
  assign EMA_[1] = EMA[1];
  assign EMA_[2] = EMA[2];
  assign EMAW_[0] = EMAW[0];
  assign EMAW_[1] = EMAW[1];
  assign TEN_ = TEN;
  assign TCEN_ = TCEN;
  assign TWEN_[0] = TWEN[0];
  assign TWEN_[1] = TWEN[1];
  assign TWEN_[2] = TWEN[2];
  assign TWEN_[3] = TWEN[3];
  assign TWEN_[4] = TWEN[4];
  assign TWEN_[5] = TWEN[5];
  assign TWEN_[6] = TWEN[6];
  assign TWEN_[7] = TWEN[7];
  assign TWEN_[8] = TWEN[8];
  assign TWEN_[9] = TWEN[9];
  assign TWEN_[10] = TWEN[10];
  assign TWEN_[11] = TWEN[11];
  assign TWEN_[12] = TWEN[12];
  assign TWEN_[13] = TWEN[13];
  assign TWEN_[14] = TWEN[14];
  assign TWEN_[15] = TWEN[15];
  assign TWEN_[16] = TWEN[16];
  assign TWEN_[17] = TWEN[17];
  assign TWEN_[18] = TWEN[18];
  assign TWEN_[19] = TWEN[19];
  assign TWEN_[20] = TWEN[20];
  assign TWEN_[21] = TWEN[21];
  assign TWEN_[22] = TWEN[22];
  assign TWEN_[23] = TWEN[23];
  assign TWEN_[24] = TWEN[24];
  assign TWEN_[25] = TWEN[25];
  assign TWEN_[26] = TWEN[26];
  assign TWEN_[27] = TWEN[27];
  assign TWEN_[28] = TWEN[28];
  assign TWEN_[29] = TWEN[29];
  assign TWEN_[30] = TWEN[30];
  assign TWEN_[31] = TWEN[31];
  assign TWEN_[32] = TWEN[32];
  assign TWEN_[33] = TWEN[33];
  assign TWEN_[34] = TWEN[34];
  assign TWEN_[35] = TWEN[35];
  assign TWEN_[36] = TWEN[36];
  assign TWEN_[37] = TWEN[37];
  assign TWEN_[38] = TWEN[38];
  assign TWEN_[39] = TWEN[39];
  assign TWEN_[40] = TWEN[40];
  assign TWEN_[41] = TWEN[41];
  assign TWEN_[42] = TWEN[42];
  assign TWEN_[43] = TWEN[43];
  assign TWEN_[44] = TWEN[44];
  assign TWEN_[45] = TWEN[45];
  assign TWEN_[46] = TWEN[46];
  assign TWEN_[47] = TWEN[47];
  assign TWEN_[48] = TWEN[48];
  assign TWEN_[49] = TWEN[49];
  assign TWEN_[50] = TWEN[50];
  assign TWEN_[51] = TWEN[51];
  assign TWEN_[52] = TWEN[52];
  assign TWEN_[53] = TWEN[53];
  assign TWEN_[54] = TWEN[54];
  assign TWEN_[55] = TWEN[55];
  assign TWEN_[56] = TWEN[56];
  assign TWEN_[57] = TWEN[57];
  assign TWEN_[58] = TWEN[58];
  assign TWEN_[59] = TWEN[59];
  assign TWEN_[60] = TWEN[60];
  assign TWEN_[61] = TWEN[61];
  assign TWEN_[62] = TWEN[62];
  assign TWEN_[63] = TWEN[63];
  assign TA_[0] = TA[0];
  assign TA_[1] = TA[1];
  assign TA_[2] = TA[2];
  assign TA_[3] = TA[3];
  assign TA_[4] = TA[4];
  assign TA_[5] = TA[5];
  assign TA_[6] = TA[6];
  assign TA_[7] = TA[7];
  assign TA_[8] = TA[8];
  assign TA_[9] = TA[9];
  assign TA_[10] = TA[10];
  assign TA_[11] = TA[11];
  assign TD_[0] = TD[0];
  assign TD_[1] = TD[1];
  assign TD_[2] = TD[2];
  assign TD_[3] = TD[3];
  assign TD_[4] = TD[4];
  assign TD_[5] = TD[5];
  assign TD_[6] = TD[6];
  assign TD_[7] = TD[7];
  assign TD_[8] = TD[8];
  assign TD_[9] = TD[9];
  assign TD_[10] = TD[10];
  assign TD_[11] = TD[11];
  assign TD_[12] = TD[12];
  assign TD_[13] = TD[13];
  assign TD_[14] = TD[14];
  assign TD_[15] = TD[15];
  assign TD_[16] = TD[16];
  assign TD_[17] = TD[17];
  assign TD_[18] = TD[18];
  assign TD_[19] = TD[19];
  assign TD_[20] = TD[20];
  assign TD_[21] = TD[21];
  assign TD_[22] = TD[22];
  assign TD_[23] = TD[23];
  assign TD_[24] = TD[24];
  assign TD_[25] = TD[25];
  assign TD_[26] = TD[26];
  assign TD_[27] = TD[27];
  assign TD_[28] = TD[28];
  assign TD_[29] = TD[29];
  assign TD_[30] = TD[30];
  assign TD_[31] = TD[31];
  assign TD_[32] = TD[32];
  assign TD_[33] = TD[33];
  assign TD_[34] = TD[34];
  assign TD_[35] = TD[35];
  assign TD_[36] = TD[36];
  assign TD_[37] = TD[37];
  assign TD_[38] = TD[38];
  assign TD_[39] = TD[39];
  assign TD_[40] = TD[40];
  assign TD_[41] = TD[41];
  assign TD_[42] = TD[42];
  assign TD_[43] = TD[43];
  assign TD_[44] = TD[44];
  assign TD_[45] = TD[45];
  assign TD_[46] = TD[46];
  assign TD_[47] = TD[47];
  assign TD_[48] = TD[48];
  assign TD_[49] = TD[49];
  assign TD_[50] = TD[50];
  assign TD_[51] = TD[51];
  assign TD_[52] = TD[52];
  assign TD_[53] = TD[53];
  assign TD_[54] = TD[54];
  assign TD_[55] = TD[55];
  assign TD_[56] = TD[56];
  assign TD_[57] = TD[57];
  assign TD_[58] = TD[58];
  assign TD_[59] = TD[59];
  assign TD_[60] = TD[60];
  assign TD_[61] = TD[61];
  assign TD_[62] = TD[62];
  assign TD_[63] = TD[63];
  assign GWEN_ = GWEN;
  assign TGWEN_ = TGWEN;
  assign RET1N_ = RET1N;
  assign SI_[0] = SI[0];
  assign SI_[1] = SI[1];
  assign SE_ = SE;
  assign DFTRAMBYP_ = DFTRAMBYP;

  assign `ARM_UD_DP CENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? CEN_ : TCEN_)) : 1'bx;
  assign `ARM_UD_DP WENY_ = (RET1N_ | pre_charge_st) ? ({64{DFTRAMBYP_}} & (TEN_ ? WEN_ : TWEN_)) : {64{1'bx}};
  assign `ARM_UD_DP AY_ = (RET1N_ | pre_charge_st) ? ({12{DFTRAMBYP_}} & (TEN_ ? A_ : TA_)) : {12{1'bx}};
  assign `ARM_UD_DP GWENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? GWEN_ : TGWEN_)) : 1'bx;
  assign `ARM_UD_SEQ Q_ = (RET1N_ | pre_charge_st) ? ((Q_int)) : {64{1'bx}};
  assign `ARM_UD_DP SO_ = (RET1N_ | pre_charge_st) ? ({Q_[32], Q_[31]}) : {2{1'bx}};

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial begin
    #0;
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
  end
`endif
  always @ (EMA_) begin
  	if(EMA_ < 2) 
   	$display("Warning: Set Value for EMA doesn't match Default value 2 in %m at %0t", $time);
  end
  always @ (EMAW_) begin
  	if(EMAW_ < 0) 
   	$display("Warning: Set Value for EMAW doesn't match Default value 0 in %m at %0t", $time);
  end

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval===1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction

  function isBit1;
    input bitval;
    begin
      isBit1 = ( bitval===1'b1 ) ? 1'b1 : 1'b0;
    end
  endfunction



  task readWrite;
  begin
    if (GWEN_int !== 1'b1 && DFTRAMBYP_int=== 1'b0 && SE_int === 1'bx) begin
      failedWrite(0);
    end else if (DFTRAMBYP_int=== 1'b0 && SE_int === 1'b1) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0 && (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{(EMA_int & isBit1(DFTRAMBYP_int)), (EMAW_int & isBit1(DFTRAMBYP_int))} === 1'bx) begin
        Q_int = {64{1'bx}};
    end else if (^{(CEN_int & !isBit1(DFTRAMBYP_int)), EMA_int, EMAW_int, RET1N_int} === 1'bx) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0) && DFTRAMBYP_int === 1'b0) begin
      Q_int = GWEN_int !== 1'b1 ? Q_int : {64{1'bx}};
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx && DFTRAMBYP_int === 1'b0) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1) begin
      if(isBitX(DFTRAMBYP_int) || isBitX(SE_int))
        D_int = {64{1'bx}};

      mux_address = (A_int & 3'b111);
      row_address = (A_int >> 3);
      if (DFTRAMBYP_int !== 1'b1) begin
      if (row_address > 511)
        row = {512{1'bx}};
      else
        row = mem[row_address];
      end
      if( (isBitX(GWEN_int) && DFTRAMBYP_int!==1) || isBitX(DFTRAMBYP_int) ) begin
        writeEnable = {64{1'bx}};
        D_int = {64{1'bx}};
      end else
          writeEnable = ~ ( {64{GWEN_int}} | {WEN_int[63], WEN_int[62], WEN_int[61],
          WEN_int[60], WEN_int[59], WEN_int[58], WEN_int[57], WEN_int[56], WEN_int[55],
          WEN_int[54], WEN_int[53], WEN_int[52], WEN_int[51], WEN_int[50], WEN_int[49],
          WEN_int[48], WEN_int[47], WEN_int[46], WEN_int[45], WEN_int[44], WEN_int[43],
          WEN_int[42], WEN_int[41], WEN_int[40], WEN_int[39], WEN_int[38], WEN_int[37],
          WEN_int[36], WEN_int[35], WEN_int[34], WEN_int[33], WEN_int[32], WEN_int[31],
          WEN_int[30], WEN_int[29], WEN_int[28], WEN_int[27], WEN_int[26], WEN_int[25],
          WEN_int[24], WEN_int[23], WEN_int[22], WEN_int[21], WEN_int[20], WEN_int[19],
          WEN_int[18], WEN_int[17], WEN_int[16], WEN_int[15], WEN_int[14], WEN_int[13],
          WEN_int[12], WEN_int[11], WEN_int[10], WEN_int[9], WEN_int[8], WEN_int[7],
          WEN_int[6], WEN_int[5], WEN_int[4], WEN_int[3], WEN_int[2], WEN_int[1], WEN_int[0]});
      if (GWEN_int !== 1'b1 || DFTRAMBYP_int === 1'b1 || DFTRAMBYP_int === 1'bx) begin
        row_mask =  ( {7'b0000000, writeEnable[63], 7'b0000000, writeEnable[62], 7'b0000000, writeEnable[61],
          7'b0000000, writeEnable[60], 7'b0000000, writeEnable[59], 7'b0000000, writeEnable[58],
          7'b0000000, writeEnable[57], 7'b0000000, writeEnable[56], 7'b0000000, writeEnable[55],
          7'b0000000, writeEnable[54], 7'b0000000, writeEnable[53], 7'b0000000, writeEnable[52],
          7'b0000000, writeEnable[51], 7'b0000000, writeEnable[50], 7'b0000000, writeEnable[49],
          7'b0000000, writeEnable[48], 7'b0000000, writeEnable[47], 7'b0000000, writeEnable[46],
          7'b0000000, writeEnable[45], 7'b0000000, writeEnable[44], 7'b0000000, writeEnable[43],
          7'b0000000, writeEnable[42], 7'b0000000, writeEnable[41], 7'b0000000, writeEnable[40],
          7'b0000000, writeEnable[39], 7'b0000000, writeEnable[38], 7'b0000000, writeEnable[37],
          7'b0000000, writeEnable[36], 7'b0000000, writeEnable[35], 7'b0000000, writeEnable[34],
          7'b0000000, writeEnable[33], 7'b0000000, writeEnable[32], 7'b0000000, writeEnable[31],
          7'b0000000, writeEnable[30], 7'b0000000, writeEnable[29], 7'b0000000, writeEnable[28],
          7'b0000000, writeEnable[27], 7'b0000000, writeEnable[26], 7'b0000000, writeEnable[25],
          7'b0000000, writeEnable[24], 7'b0000000, writeEnable[23], 7'b0000000, writeEnable[22],
          7'b0000000, writeEnable[21], 7'b0000000, writeEnable[20], 7'b0000000, writeEnable[19],
          7'b0000000, writeEnable[18], 7'b0000000, writeEnable[17], 7'b0000000, writeEnable[16],
          7'b0000000, writeEnable[15], 7'b0000000, writeEnable[14], 7'b0000000, writeEnable[13],
          7'b0000000, writeEnable[12], 7'b0000000, writeEnable[11], 7'b0000000, writeEnable[10],
          7'b0000000, writeEnable[9], 7'b0000000, writeEnable[8], 7'b0000000, writeEnable[7],
          7'b0000000, writeEnable[6], 7'b0000000, writeEnable[5], 7'b0000000, writeEnable[4],
          7'b0000000, writeEnable[3], 7'b0000000, writeEnable[2], 7'b0000000, writeEnable[1],
          7'b0000000, writeEnable[0]} << mux_address);
        new_data =  ( {7'b0000000, D_int[63], 7'b0000000, D_int[62], 7'b0000000, D_int[61],
          7'b0000000, D_int[60], 7'b0000000, D_int[59], 7'b0000000, D_int[58], 7'b0000000, D_int[57],
          7'b0000000, D_int[56], 7'b0000000, D_int[55], 7'b0000000, D_int[54], 7'b0000000, D_int[53],
          7'b0000000, D_int[52], 7'b0000000, D_int[51], 7'b0000000, D_int[50], 7'b0000000, D_int[49],
          7'b0000000, D_int[48], 7'b0000000, D_int[47], 7'b0000000, D_int[46], 7'b0000000, D_int[45],
          7'b0000000, D_int[44], 7'b0000000, D_int[43], 7'b0000000, D_int[42], 7'b0000000, D_int[41],
          7'b0000000, D_int[40], 7'b0000000, D_int[39], 7'b0000000, D_int[38], 7'b0000000, D_int[37],
          7'b0000000, D_int[36], 7'b0000000, D_int[35], 7'b0000000, D_int[34], 7'b0000000, D_int[33],
          7'b0000000, D_int[32], 7'b0000000, D_int[31], 7'b0000000, D_int[30], 7'b0000000, D_int[29],
          7'b0000000, D_int[28], 7'b0000000, D_int[27], 7'b0000000, D_int[26], 7'b0000000, D_int[25],
          7'b0000000, D_int[24], 7'b0000000, D_int[23], 7'b0000000, D_int[22], 7'b0000000, D_int[21],
          7'b0000000, D_int[20], 7'b0000000, D_int[19], 7'b0000000, D_int[18], 7'b0000000, D_int[17],
          7'b0000000, D_int[16], 7'b0000000, D_int[15], 7'b0000000, D_int[14], 7'b0000000, D_int[13],
          7'b0000000, D_int[12], 7'b0000000, D_int[11], 7'b0000000, D_int[10], 7'b0000000, D_int[9],
          7'b0000000, D_int[8], 7'b0000000, D_int[7], 7'b0000000, D_int[6], 7'b0000000, D_int[5],
          7'b0000000, D_int[4], 7'b0000000, D_int[3], 7'b0000000, D_int[2], 7'b0000000, D_int[1],
          7'b0000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        if (DFTRAMBYP_int === 1'b1 && SE_int === 1'b0) begin
        end else if (GWEN_int !== 1'b1 && DFTRAMBYP_int === 1'b1 && SE_int === 1'bx) begin
             Q_int = {64{1'bx}};
        end else begin
        mem[row_address] = row;
        end
      end else begin
        data_out = (row >> (mux_address%8));
        readLatch0 = {data_out[504], data_out[496], data_out[488], data_out[480], data_out[472],
          data_out[464], data_out[456], data_out[448], data_out[440], data_out[432],
          data_out[424], data_out[416], data_out[408], data_out[400], data_out[392],
          data_out[384], data_out[376], data_out[368], data_out[360], data_out[352],
          data_out[344], data_out[336], data_out[328], data_out[320], data_out[312],
          data_out[304], data_out[296], data_out[288], data_out[280], data_out[272],
          data_out[264], data_out[256], data_out[248], data_out[240], data_out[232],
          data_out[224], data_out[216], data_out[208], data_out[200], data_out[192],
          data_out[184], data_out[176], data_out[168], data_out[160], data_out[152],
          data_out[144], data_out[136], data_out[128], data_out[120], data_out[112],
          data_out[104], data_out[96], data_out[88], data_out[80], data_out[72], data_out[64],
          data_out[56], data_out[48], data_out[40], data_out[32], data_out[24], data_out[16],
          data_out[8], data_out[0]};
        shifted_readLatch0 = readLatch0;
        Q_int = {shifted_readLatch0[63], shifted_readLatch0[62], shifted_readLatch0[61],
          shifted_readLatch0[60], shifted_readLatch0[59], shifted_readLatch0[58], shifted_readLatch0[57],
          shifted_readLatch0[56], shifted_readLatch0[55], shifted_readLatch0[54], shifted_readLatch0[53],
          shifted_readLatch0[52], shifted_readLatch0[51], shifted_readLatch0[50], shifted_readLatch0[49],
          shifted_readLatch0[48], shifted_readLatch0[47], shifted_readLatch0[46], shifted_readLatch0[45],
          shifted_readLatch0[44], shifted_readLatch0[43], shifted_readLatch0[42], shifted_readLatch0[41],
          shifted_readLatch0[40], shifted_readLatch0[39], shifted_readLatch0[38], shifted_readLatch0[37],
          shifted_readLatch0[36], shifted_readLatch0[35], shifted_readLatch0[34], shifted_readLatch0[33],
          shifted_readLatch0[32], shifted_readLatch0[31], shifted_readLatch0[30], shifted_readLatch0[29],
          shifted_readLatch0[28], shifted_readLatch0[27], shifted_readLatch0[26], shifted_readLatch0[25],
          shifted_readLatch0[24], shifted_readLatch0[23], shifted_readLatch0[22], shifted_readLatch0[21],
          shifted_readLatch0[20], shifted_readLatch0[19], shifted_readLatch0[18], shifted_readLatch0[17],
          shifted_readLatch0[16], shifted_readLatch0[15], shifted_readLatch0[14], shifted_readLatch0[13],
          shifted_readLatch0[12], shifted_readLatch0[11], shifted_readLatch0[10], shifted_readLatch0[9],
          shifted_readLatch0[8], shifted_readLatch0[7], shifted_readLatch0[6], shifted_readLatch0[5],
          shifted_readLatch0[4], shifted_readLatch0[3], shifted_readLatch0[2], shifted_readLatch0[1],
          shifted_readLatch0[0]};
      end
      if (DFTRAMBYP_int === 1'b1) begin
        Q_int = D_int;
      end
      if( isBitX(GWEN_int) && DFTRAMBYP_int !== 1'b1) begin
        Q_int = {64{1'bx}};
      end
      if( isBitX(DFTRAMBYP_int) )
        Q_int = {64{1'bx}};
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or DFTRAMBYP_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  		DFTRAMBYP_p2 = DFTRAMBYP_;
  	end
  end

`ifdef POWER_PINS
  always @ (VDD) begin
      if (VDD != 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDD should be powered down after VDDP, Illegal power down sequencing in %m at %0t", $time);
       end
        $display("In PowerDown Mode in %m at %0t", $time);
        failedWrite(0);
      end
      if (VDD == 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDDP should be powered up after VDD in %m at %0t", $time);
        $display("Illegal power up sequencing in %m at %0t", $time);
       end
        failedWrite(0);
      end
  end
`endif
`ifdef POWER_PINS
  always @ (RET1N_ or VDDP or VDD) begin
`else     
  always @ RET1N_ begin
`endif
`ifdef POWER_PINS
    if (RET1N_ == 1'b1 && RET1N_int == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 && pre_charge_st == 1'b1 && (CEN_ === 1'bx || TCEN_ === 1'bx || DFTRAMBYP_ === 1'bx || CLK_ === 1'bx)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end
`else     
`endif
`ifdef POWER_PINS
`else     
      pre_charge_st = 0;
`endif
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end
`ifdef POWER_PINS
    if (RET1N_ == 1'b0 && VDD == 1'b1 && VDDP == 1'b1) begin
      pre_charge_st = 1;
    end else if (RET1N_ == 1'b0 && VDDP == 1'b0) begin
      pre_charge_st = 0;
      if (VDD != 1'b1) begin
        failedWrite(0);
      end
`else     
    if (RET1N_ == 1'b0) begin
`endif
      Q_int = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SI_int = {2{1'bx}};
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
`ifdef POWER_PINS
    end else if (RET1N_ == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 &&  pre_charge_st == 1'b1) begin
      pre_charge_st = 0;
    end else begin
      pre_charge_st = 0;
`else     
    end else begin
`endif
        Q_int = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SI_int = {2{1'bx}};
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
    end
    RET1N_int = RET1N_;
  end

  always @ (SI_int) begin
  	#0;
      if (DFTRAMBYP_=== 1'b1 && SE_ === 1'b1 && ^SI_int === 1'bx) begin
	Q_int[63] = SI_int[1]; 
	Q_int[0] = SI_int[0]; 
  	end
  end

  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
`endif
`ifdef POWER_PINS
  if (RET1N_ == 1'b0) begin
`else     
  if (RET1N_ == 1'b0) begin
`endif
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      SI_int = SI_;
      SE_int = SE_;
      DFTRAMBYP_int = DFTRAMBYP_;
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      SI_int = SI_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
      if (DFTRAMBYP_=== 1'b1 && SE_ === 1'b1) begin
	Q_int[63:32] = {SI_[1], Q_int[63:33]}; 
	Q_int[31:0] = {Q_int[30:0], SI_[0]}; 
      end else begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      SI_int = SI_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
    readWrite;
      end
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
    end
  end
    LAST_CLK = CLK_;
  end
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
 always @ (VDD or VDDP or VSS) begin
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
 end
`endif

endmodule
`endcelldefine
`else
`celldefine
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
module ARM_SPSRAM_64X4096_M8_MEM (VDD, VDDP, VSS, CENY, WENY, AY, GWENY, Q, SO, CLK,
    CEN, WEN, A, D, EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE,
    DFTRAMBYP);
`else
module ARM_SPSRAM_64X4096_M8_MEM (CENY, WENY, AY, GWENY, Q, SO, CLK, CEN, WEN, A, D,
    EMA, EMAW, TEN, TCEN, TWEN, TA, TD, GWEN, TGWEN, RET1N, SI, SE, DFTRAMBYP);
`endif

  parameter ASSERT_PREFIX = "";
  parameter BITS = 64;
  parameter WORDS = 4096;
  parameter MUX = 8;
  parameter MEM_WIDTH = 512; // redun block size 8, 256 on left, 256 on right
  parameter MEM_HEIGHT = 512;
  parameter WP_SIZE = 1 ;
  parameter UPM_WIDTH = 3;
  parameter UPMW_WIDTH = 2;
  parameter UPMS_WIDTH = 0;

  output  CENY;
  output [63:0] WENY;
  output [11:0] AY;
  output  GWENY;
  output [63:0] Q;
  output [1:0] SO;
  input  CLK;
  input  CEN;
  input [63:0] WEN;
  input [11:0] A;
  input [63:0] D;
  input [2:0] EMA;
  input [1:0] EMAW;
  input  TEN;
  input  TCEN;
  input [63:0] TWEN;
  input [11:0] TA;
  input [63:0] TD;
  input  GWEN;
  input  TGWEN;
  input  RET1N;
  input [1:0] SI;
  input  SE;
  input  DFTRAMBYP;
`ifdef POWER_PINS
  inout VDD;
  inout VDDP;
  inout VSS;
`endif

  reg pre_charge_st;
  integer row_address;
  integer mux_address;
  initial row_address = 0;
  initial mux_address = 0;
  reg [511:0] mem [0:511];
  reg [511:0] row, row_t;
  reg LAST_CLK;
  reg [511:0] row_mask;
  reg [511:0] new_data;
  reg [511:0] data_out;
  reg [63:0] readLatch0;
  reg [63:0] shifted_readLatch0;
  reg  read_mux_sel0_p2;
  reg [63:0] Q_int;
  reg [63:0] writeEnable;

  reg NOT_CEN, NOT_WEN63, NOT_WEN62, NOT_WEN61, NOT_WEN60, NOT_WEN59, NOT_WEN58, NOT_WEN57;
  reg NOT_WEN56, NOT_WEN55, NOT_WEN54, NOT_WEN53, NOT_WEN52, NOT_WEN51, NOT_WEN50;
  reg NOT_WEN49, NOT_WEN48, NOT_WEN47, NOT_WEN46, NOT_WEN45, NOT_WEN44, NOT_WEN43;
  reg NOT_WEN42, NOT_WEN41, NOT_WEN40, NOT_WEN39, NOT_WEN38, NOT_WEN37, NOT_WEN36;
  reg NOT_WEN35, NOT_WEN34, NOT_WEN33, NOT_WEN32, NOT_WEN31, NOT_WEN30, NOT_WEN29;
  reg NOT_WEN28, NOT_WEN27, NOT_WEN26, NOT_WEN25, NOT_WEN24, NOT_WEN23, NOT_WEN22;
  reg NOT_WEN21, NOT_WEN20, NOT_WEN19, NOT_WEN18, NOT_WEN17, NOT_WEN16, NOT_WEN15;
  reg NOT_WEN14, NOT_WEN13, NOT_WEN12, NOT_WEN11, NOT_WEN10, NOT_WEN9, NOT_WEN8, NOT_WEN7;
  reg NOT_WEN6, NOT_WEN5, NOT_WEN4, NOT_WEN3, NOT_WEN2, NOT_WEN1, NOT_WEN0, NOT_A11;
  reg NOT_A10, NOT_A9, NOT_A8, NOT_A7, NOT_A6, NOT_A5, NOT_A4, NOT_A3, NOT_A2, NOT_A1;
  reg NOT_A0, NOT_D63, NOT_D62, NOT_D61, NOT_D60, NOT_D59, NOT_D58, NOT_D57, NOT_D56;
  reg NOT_D55, NOT_D54, NOT_D53, NOT_D52, NOT_D51, NOT_D50, NOT_D49, NOT_D48, NOT_D47;
  reg NOT_D46, NOT_D45, NOT_D44, NOT_D43, NOT_D42, NOT_D41, NOT_D40, NOT_D39, NOT_D38;
  reg NOT_D37, NOT_D36, NOT_D35, NOT_D34, NOT_D33, NOT_D32, NOT_D31, NOT_D30, NOT_D29;
  reg NOT_D28, NOT_D27, NOT_D26, NOT_D25, NOT_D24, NOT_D23, NOT_D22, NOT_D21, NOT_D20;
  reg NOT_D19, NOT_D18, NOT_D17, NOT_D16, NOT_D15, NOT_D14, NOT_D13, NOT_D12, NOT_D11;
  reg NOT_D10, NOT_D9, NOT_D8, NOT_D7, NOT_D6, NOT_D5, NOT_D4, NOT_D3, NOT_D2, NOT_D1;
  reg NOT_D0, NOT_EMA2, NOT_EMA1, NOT_EMA0, NOT_EMAW1, NOT_EMAW0, NOT_TEN, NOT_TCEN;
  reg NOT_TWEN63, NOT_TWEN62, NOT_TWEN61, NOT_TWEN60, NOT_TWEN59, NOT_TWEN58, NOT_TWEN57;
  reg NOT_TWEN56, NOT_TWEN55, NOT_TWEN54, NOT_TWEN53, NOT_TWEN52, NOT_TWEN51, NOT_TWEN50;
  reg NOT_TWEN49, NOT_TWEN48, NOT_TWEN47, NOT_TWEN46, NOT_TWEN45, NOT_TWEN44, NOT_TWEN43;
  reg NOT_TWEN42, NOT_TWEN41, NOT_TWEN40, NOT_TWEN39, NOT_TWEN38, NOT_TWEN37, NOT_TWEN36;
  reg NOT_TWEN35, NOT_TWEN34, NOT_TWEN33, NOT_TWEN32, NOT_TWEN31, NOT_TWEN30, NOT_TWEN29;
  reg NOT_TWEN28, NOT_TWEN27, NOT_TWEN26, NOT_TWEN25, NOT_TWEN24, NOT_TWEN23, NOT_TWEN22;
  reg NOT_TWEN21, NOT_TWEN20, NOT_TWEN19, NOT_TWEN18, NOT_TWEN17, NOT_TWEN16, NOT_TWEN15;
  reg NOT_TWEN14, NOT_TWEN13, NOT_TWEN12, NOT_TWEN11, NOT_TWEN10, NOT_TWEN9, NOT_TWEN8;
  reg NOT_TWEN7, NOT_TWEN6, NOT_TWEN5, NOT_TWEN4, NOT_TWEN3, NOT_TWEN2, NOT_TWEN1;
  reg NOT_TWEN0, NOT_TA11, NOT_TA10, NOT_TA9, NOT_TA8, NOT_TA7, NOT_TA6, NOT_TA5, NOT_TA4;
  reg NOT_TA3, NOT_TA2, NOT_TA1, NOT_TA0, NOT_TD63, NOT_TD62, NOT_TD61, NOT_TD60, NOT_TD59;
  reg NOT_TD58, NOT_TD57, NOT_TD56, NOT_TD55, NOT_TD54, NOT_TD53, NOT_TD52, NOT_TD51;
  reg NOT_TD50, NOT_TD49, NOT_TD48, NOT_TD47, NOT_TD46, NOT_TD45, NOT_TD44, NOT_TD43;
  reg NOT_TD42, NOT_TD41, NOT_TD40, NOT_TD39, NOT_TD38, NOT_TD37, NOT_TD36, NOT_TD35;
  reg NOT_TD34, NOT_TD33, NOT_TD32, NOT_TD31, NOT_TD30, NOT_TD29, NOT_TD28, NOT_TD27;
  reg NOT_TD26, NOT_TD25, NOT_TD24, NOT_TD23, NOT_TD22, NOT_TD21, NOT_TD20, NOT_TD19;
  reg NOT_TD18, NOT_TD17, NOT_TD16, NOT_TD15, NOT_TD14, NOT_TD13, NOT_TD12, NOT_TD11;
  reg NOT_TD10, NOT_TD9, NOT_TD8, NOT_TD7, NOT_TD6, NOT_TD5, NOT_TD4, NOT_TD3, NOT_TD2;
  reg NOT_TD1, NOT_TD0, NOT_GWEN, NOT_TGWEN, NOT_SI1, NOT_SI0, NOT_SE, NOT_DFTRAMBYP;
  reg NOT_RET1N;
  reg NOT_CLK_PER, NOT_CLK_MINH, NOT_CLK_MINL;
  reg clk0_int;

  wire  CENY_;
  wire [63:0] WENY_;
  wire [11:0] AY_;
  wire  GWENY_;
  wire [63:0] Q_;
  wire [1:0] SO_;
  reg [1:0] SO_int;
 wire  CLK_;
  wire  CEN_;
  reg  CEN_int;
  reg  CEN_p2;
  wire [63:0] WEN_;
  reg [63:0] WEN_int;
  wire [11:0] A_;
  reg [11:0] A_int;
  wire [63:0] D_;
  reg [63:0] D_int;
  wire [2:0] EMA_;
  reg [2:0] EMA_int;
  wire [1:0] EMAW_;
  reg [1:0] EMAW_int;
  wire  TEN_;
  reg  TEN_int;
  wire  TCEN_;
  reg  TCEN_int;
  reg  TCEN_p2;
  wire [63:0] TWEN_;
  reg [63:0] TWEN_int;
  wire [11:0] TA_;
  reg [11:0] TA_int;
  wire [63:0] TD_;
  reg [63:0] TD_int;
  wire  GWEN_;
  reg  GWEN_int;
  wire  TGWEN_;
  reg  TGWEN_int;
  wire  RET1N_;
  reg  RET1N_int;
  wire [1:0] SI_;
  reg [1:0] SI_int;
  wire  SE_;
  reg  SE_int;
  wire  DFTRAMBYP_;
  reg  DFTRAMBYP_int;
  reg  DFTRAMBYP_p2;

  buf B440(CENY, CENY_);
  buf B441(WENY[0], WENY_[0]);
  buf B442(WENY[1], WENY_[1]);
  buf B443(WENY[2], WENY_[2]);
  buf B444(WENY[3], WENY_[3]);
  buf B445(WENY[4], WENY_[4]);
  buf B446(WENY[5], WENY_[5]);
  buf B447(WENY[6], WENY_[6]);
  buf B448(WENY[7], WENY_[7]);
  buf B449(WENY[8], WENY_[8]);
  buf B450(WENY[9], WENY_[9]);
  buf B451(WENY[10], WENY_[10]);
  buf B452(WENY[11], WENY_[11]);
  buf B453(WENY[12], WENY_[12]);
  buf B454(WENY[13], WENY_[13]);
  buf B455(WENY[14], WENY_[14]);
  buf B456(WENY[15], WENY_[15]);
  buf B457(WENY[16], WENY_[16]);
  buf B458(WENY[17], WENY_[17]);
  buf B459(WENY[18], WENY_[18]);
  buf B460(WENY[19], WENY_[19]);
  buf B461(WENY[20], WENY_[20]);
  buf B462(WENY[21], WENY_[21]);
  buf B463(WENY[22], WENY_[22]);
  buf B464(WENY[23], WENY_[23]);
  buf B465(WENY[24], WENY_[24]);
  buf B466(WENY[25], WENY_[25]);
  buf B467(WENY[26], WENY_[26]);
  buf B468(WENY[27], WENY_[27]);
  buf B469(WENY[28], WENY_[28]);
  buf B470(WENY[29], WENY_[29]);
  buf B471(WENY[30], WENY_[30]);
  buf B472(WENY[31], WENY_[31]);
  buf B473(WENY[32], WENY_[32]);
  buf B474(WENY[33], WENY_[33]);
  buf B475(WENY[34], WENY_[34]);
  buf B476(WENY[35], WENY_[35]);
  buf B477(WENY[36], WENY_[36]);
  buf B478(WENY[37], WENY_[37]);
  buf B479(WENY[38], WENY_[38]);
  buf B480(WENY[39], WENY_[39]);
  buf B481(WENY[40], WENY_[40]);
  buf B482(WENY[41], WENY_[41]);
  buf B483(WENY[42], WENY_[42]);
  buf B484(WENY[43], WENY_[43]);
  buf B485(WENY[44], WENY_[44]);
  buf B486(WENY[45], WENY_[45]);
  buf B487(WENY[46], WENY_[46]);
  buf B488(WENY[47], WENY_[47]);
  buf B489(WENY[48], WENY_[48]);
  buf B490(WENY[49], WENY_[49]);
  buf B491(WENY[50], WENY_[50]);
  buf B492(WENY[51], WENY_[51]);
  buf B493(WENY[52], WENY_[52]);
  buf B494(WENY[53], WENY_[53]);
  buf B495(WENY[54], WENY_[54]);
  buf B496(WENY[55], WENY_[55]);
  buf B497(WENY[56], WENY_[56]);
  buf B498(WENY[57], WENY_[57]);
  buf B499(WENY[58], WENY_[58]);
  buf B500(WENY[59], WENY_[59]);
  buf B501(WENY[60], WENY_[60]);
  buf B502(WENY[61], WENY_[61]);
  buf B503(WENY[62], WENY_[62]);
  buf B504(WENY[63], WENY_[63]);
  buf B505(AY[0], AY_[0]);
  buf B506(AY[1], AY_[1]);
  buf B507(AY[2], AY_[2]);
  buf B508(AY[3], AY_[3]);
  buf B509(AY[4], AY_[4]);
  buf B510(AY[5], AY_[5]);
  buf B511(AY[6], AY_[6]);
  buf B512(AY[7], AY_[7]);
  buf B513(AY[8], AY_[8]);
  buf B514(AY[9], AY_[9]);
  buf B515(AY[10], AY_[10]);
  buf B516(AY[11], AY_[11]);
  buf B517(GWENY, GWENY_);
  buf B518(Q[0], Q_[0]);
  buf B519(Q[1], Q_[1]);
  buf B520(Q[2], Q_[2]);
  buf B521(Q[3], Q_[3]);
  buf B522(Q[4], Q_[4]);
  buf B523(Q[5], Q_[5]);
  buf B524(Q[6], Q_[6]);
  buf B525(Q[7], Q_[7]);
  buf B526(Q[8], Q_[8]);
  buf B527(Q[9], Q_[9]);
  buf B528(Q[10], Q_[10]);
  buf B529(Q[11], Q_[11]);
  buf B530(Q[12], Q_[12]);
  buf B531(Q[13], Q_[13]);
  buf B532(Q[14], Q_[14]);
  buf B533(Q[15], Q_[15]);
  buf B534(Q[16], Q_[16]);
  buf B535(Q[17], Q_[17]);
  buf B536(Q[18], Q_[18]);
  buf B537(Q[19], Q_[19]);
  buf B538(Q[20], Q_[20]);
  buf B539(Q[21], Q_[21]);
  buf B540(Q[22], Q_[22]);
  buf B541(Q[23], Q_[23]);
  buf B542(Q[24], Q_[24]);
  buf B543(Q[25], Q_[25]);
  buf B544(Q[26], Q_[26]);
  buf B545(Q[27], Q_[27]);
  buf B546(Q[28], Q_[28]);
  buf B547(Q[29], Q_[29]);
  buf B548(Q[30], Q_[30]);
  buf B549(Q[31], Q_[31]);
  buf B550(Q[32], Q_[32]);
  buf B551(Q[33], Q_[33]);
  buf B552(Q[34], Q_[34]);
  buf B553(Q[35], Q_[35]);
  buf B554(Q[36], Q_[36]);
  buf B555(Q[37], Q_[37]);
  buf B556(Q[38], Q_[38]);
  buf B557(Q[39], Q_[39]);
  buf B558(Q[40], Q_[40]);
  buf B559(Q[41], Q_[41]);
  buf B560(Q[42], Q_[42]);
  buf B561(Q[43], Q_[43]);
  buf B562(Q[44], Q_[44]);
  buf B563(Q[45], Q_[45]);
  buf B564(Q[46], Q_[46]);
  buf B565(Q[47], Q_[47]);
  buf B566(Q[48], Q_[48]);
  buf B567(Q[49], Q_[49]);
  buf B568(Q[50], Q_[50]);
  buf B569(Q[51], Q_[51]);
  buf B570(Q[52], Q_[52]);
  buf B571(Q[53], Q_[53]);
  buf B572(Q[54], Q_[54]);
  buf B573(Q[55], Q_[55]);
  buf B574(Q[56], Q_[56]);
  buf B575(Q[57], Q_[57]);
  buf B576(Q[58], Q_[58]);
  buf B577(Q[59], Q_[59]);
  buf B578(Q[60], Q_[60]);
  buf B579(Q[61], Q_[61]);
  buf B580(Q[62], Q_[62]);
  buf B581(Q[63], Q_[63]);
  buf B582(SO[0], SO_[0]);
  buf B583(SO[1], SO_[1]);
  buf B584(CLK_, CLK);
  buf B585(CEN_, CEN);
  buf B586(WEN_[0], WEN[0]);
  buf B587(WEN_[1], WEN[1]);
  buf B588(WEN_[2], WEN[2]);
  buf B589(WEN_[3], WEN[3]);
  buf B590(WEN_[4], WEN[4]);
  buf B591(WEN_[5], WEN[5]);
  buf B592(WEN_[6], WEN[6]);
  buf B593(WEN_[7], WEN[7]);
  buf B594(WEN_[8], WEN[8]);
  buf B595(WEN_[9], WEN[9]);
  buf B596(WEN_[10], WEN[10]);
  buf B597(WEN_[11], WEN[11]);
  buf B598(WEN_[12], WEN[12]);
  buf B599(WEN_[13], WEN[13]);
  buf B600(WEN_[14], WEN[14]);
  buf B601(WEN_[15], WEN[15]);
  buf B602(WEN_[16], WEN[16]);
  buf B603(WEN_[17], WEN[17]);
  buf B604(WEN_[18], WEN[18]);
  buf B605(WEN_[19], WEN[19]);
  buf B606(WEN_[20], WEN[20]);
  buf B607(WEN_[21], WEN[21]);
  buf B608(WEN_[22], WEN[22]);
  buf B609(WEN_[23], WEN[23]);
  buf B610(WEN_[24], WEN[24]);
  buf B611(WEN_[25], WEN[25]);
  buf B612(WEN_[26], WEN[26]);
  buf B613(WEN_[27], WEN[27]);
  buf B614(WEN_[28], WEN[28]);
  buf B615(WEN_[29], WEN[29]);
  buf B616(WEN_[30], WEN[30]);
  buf B617(WEN_[31], WEN[31]);
  buf B618(WEN_[32], WEN[32]);
  buf B619(WEN_[33], WEN[33]);
  buf B620(WEN_[34], WEN[34]);
  buf B621(WEN_[35], WEN[35]);
  buf B622(WEN_[36], WEN[36]);
  buf B623(WEN_[37], WEN[37]);
  buf B624(WEN_[38], WEN[38]);
  buf B625(WEN_[39], WEN[39]);
  buf B626(WEN_[40], WEN[40]);
  buf B627(WEN_[41], WEN[41]);
  buf B628(WEN_[42], WEN[42]);
  buf B629(WEN_[43], WEN[43]);
  buf B630(WEN_[44], WEN[44]);
  buf B631(WEN_[45], WEN[45]);
  buf B632(WEN_[46], WEN[46]);
  buf B633(WEN_[47], WEN[47]);
  buf B634(WEN_[48], WEN[48]);
  buf B635(WEN_[49], WEN[49]);
  buf B636(WEN_[50], WEN[50]);
  buf B637(WEN_[51], WEN[51]);
  buf B638(WEN_[52], WEN[52]);
  buf B639(WEN_[53], WEN[53]);
  buf B640(WEN_[54], WEN[54]);
  buf B641(WEN_[55], WEN[55]);
  buf B642(WEN_[56], WEN[56]);
  buf B643(WEN_[57], WEN[57]);
  buf B644(WEN_[58], WEN[58]);
  buf B645(WEN_[59], WEN[59]);
  buf B646(WEN_[60], WEN[60]);
  buf B647(WEN_[61], WEN[61]);
  buf B648(WEN_[62], WEN[62]);
  buf B649(WEN_[63], WEN[63]);
  buf B650(A_[0], A[0]);
  buf B651(A_[1], A[1]);
  buf B652(A_[2], A[2]);
  buf B653(A_[3], A[3]);
  buf B654(A_[4], A[4]);
  buf B655(A_[5], A[5]);
  buf B656(A_[6], A[6]);
  buf B657(A_[7], A[7]);
  buf B658(A_[8], A[8]);
  buf B659(A_[9], A[9]);
  buf B660(A_[10], A[10]);
  buf B661(A_[11], A[11]);
  buf B662(D_[0], D[0]);
  buf B663(D_[1], D[1]);
  buf B664(D_[2], D[2]);
  buf B665(D_[3], D[3]);
  buf B666(D_[4], D[4]);
  buf B667(D_[5], D[5]);
  buf B668(D_[6], D[6]);
  buf B669(D_[7], D[7]);
  buf B670(D_[8], D[8]);
  buf B671(D_[9], D[9]);
  buf B672(D_[10], D[10]);
  buf B673(D_[11], D[11]);
  buf B674(D_[12], D[12]);
  buf B675(D_[13], D[13]);
  buf B676(D_[14], D[14]);
  buf B677(D_[15], D[15]);
  buf B678(D_[16], D[16]);
  buf B679(D_[17], D[17]);
  buf B680(D_[18], D[18]);
  buf B681(D_[19], D[19]);
  buf B682(D_[20], D[20]);
  buf B683(D_[21], D[21]);
  buf B684(D_[22], D[22]);
  buf B685(D_[23], D[23]);
  buf B686(D_[24], D[24]);
  buf B687(D_[25], D[25]);
  buf B688(D_[26], D[26]);
  buf B689(D_[27], D[27]);
  buf B690(D_[28], D[28]);
  buf B691(D_[29], D[29]);
  buf B692(D_[30], D[30]);
  buf B693(D_[31], D[31]);
  buf B694(D_[32], D[32]);
  buf B695(D_[33], D[33]);
  buf B696(D_[34], D[34]);
  buf B697(D_[35], D[35]);
  buf B698(D_[36], D[36]);
  buf B699(D_[37], D[37]);
  buf B700(D_[38], D[38]);
  buf B701(D_[39], D[39]);
  buf B702(D_[40], D[40]);
  buf B703(D_[41], D[41]);
  buf B704(D_[42], D[42]);
  buf B705(D_[43], D[43]);
  buf B706(D_[44], D[44]);
  buf B707(D_[45], D[45]);
  buf B708(D_[46], D[46]);
  buf B709(D_[47], D[47]);
  buf B710(D_[48], D[48]);
  buf B711(D_[49], D[49]);
  buf B712(D_[50], D[50]);
  buf B713(D_[51], D[51]);
  buf B714(D_[52], D[52]);
  buf B715(D_[53], D[53]);
  buf B716(D_[54], D[54]);
  buf B717(D_[55], D[55]);
  buf B718(D_[56], D[56]);
  buf B719(D_[57], D[57]);
  buf B720(D_[58], D[58]);
  buf B721(D_[59], D[59]);
  buf B722(D_[60], D[60]);
  buf B723(D_[61], D[61]);
  buf B724(D_[62], D[62]);
  buf B725(D_[63], D[63]);
  buf B726(EMA_[0], EMA[0]);
  buf B727(EMA_[1], EMA[1]);
  buf B728(EMA_[2], EMA[2]);
  buf B729(EMAW_[0], EMAW[0]);
  buf B730(EMAW_[1], EMAW[1]);
  buf B731(TEN_, TEN);
  buf B732(TCEN_, TCEN);
  buf B733(TWEN_[0], TWEN[0]);
  buf B734(TWEN_[1], TWEN[1]);
  buf B735(TWEN_[2], TWEN[2]);
  buf B736(TWEN_[3], TWEN[3]);
  buf B737(TWEN_[4], TWEN[4]);
  buf B738(TWEN_[5], TWEN[5]);
  buf B739(TWEN_[6], TWEN[6]);
  buf B740(TWEN_[7], TWEN[7]);
  buf B741(TWEN_[8], TWEN[8]);
  buf B742(TWEN_[9], TWEN[9]);
  buf B743(TWEN_[10], TWEN[10]);
  buf B744(TWEN_[11], TWEN[11]);
  buf B745(TWEN_[12], TWEN[12]);
  buf B746(TWEN_[13], TWEN[13]);
  buf B747(TWEN_[14], TWEN[14]);
  buf B748(TWEN_[15], TWEN[15]);
  buf B749(TWEN_[16], TWEN[16]);
  buf B750(TWEN_[17], TWEN[17]);
  buf B751(TWEN_[18], TWEN[18]);
  buf B752(TWEN_[19], TWEN[19]);
  buf B753(TWEN_[20], TWEN[20]);
  buf B754(TWEN_[21], TWEN[21]);
  buf B755(TWEN_[22], TWEN[22]);
  buf B756(TWEN_[23], TWEN[23]);
  buf B757(TWEN_[24], TWEN[24]);
  buf B758(TWEN_[25], TWEN[25]);
  buf B759(TWEN_[26], TWEN[26]);
  buf B760(TWEN_[27], TWEN[27]);
  buf B761(TWEN_[28], TWEN[28]);
  buf B762(TWEN_[29], TWEN[29]);
  buf B763(TWEN_[30], TWEN[30]);
  buf B764(TWEN_[31], TWEN[31]);
  buf B765(TWEN_[32], TWEN[32]);
  buf B766(TWEN_[33], TWEN[33]);
  buf B767(TWEN_[34], TWEN[34]);
  buf B768(TWEN_[35], TWEN[35]);
  buf B769(TWEN_[36], TWEN[36]);
  buf B770(TWEN_[37], TWEN[37]);
  buf B771(TWEN_[38], TWEN[38]);
  buf B772(TWEN_[39], TWEN[39]);
  buf B773(TWEN_[40], TWEN[40]);
  buf B774(TWEN_[41], TWEN[41]);
  buf B775(TWEN_[42], TWEN[42]);
  buf B776(TWEN_[43], TWEN[43]);
  buf B777(TWEN_[44], TWEN[44]);
  buf B778(TWEN_[45], TWEN[45]);
  buf B779(TWEN_[46], TWEN[46]);
  buf B780(TWEN_[47], TWEN[47]);
  buf B781(TWEN_[48], TWEN[48]);
  buf B782(TWEN_[49], TWEN[49]);
  buf B783(TWEN_[50], TWEN[50]);
  buf B784(TWEN_[51], TWEN[51]);
  buf B785(TWEN_[52], TWEN[52]);
  buf B786(TWEN_[53], TWEN[53]);
  buf B787(TWEN_[54], TWEN[54]);
  buf B788(TWEN_[55], TWEN[55]);
  buf B789(TWEN_[56], TWEN[56]);
  buf B790(TWEN_[57], TWEN[57]);
  buf B791(TWEN_[58], TWEN[58]);
  buf B792(TWEN_[59], TWEN[59]);
  buf B793(TWEN_[60], TWEN[60]);
  buf B794(TWEN_[61], TWEN[61]);
  buf B795(TWEN_[62], TWEN[62]);
  buf B796(TWEN_[63], TWEN[63]);
  buf B797(TA_[0], TA[0]);
  buf B798(TA_[1], TA[1]);
  buf B799(TA_[2], TA[2]);
  buf B800(TA_[3], TA[3]);
  buf B801(TA_[4], TA[4]);
  buf B802(TA_[5], TA[5]);
  buf B803(TA_[6], TA[6]);
  buf B804(TA_[7], TA[7]);
  buf B805(TA_[8], TA[8]);
  buf B806(TA_[9], TA[9]);
  buf B807(TA_[10], TA[10]);
  buf B808(TA_[11], TA[11]);
  buf B809(TD_[0], TD[0]);
  buf B810(TD_[1], TD[1]);
  buf B811(TD_[2], TD[2]);
  buf B812(TD_[3], TD[3]);
  buf B813(TD_[4], TD[4]);
  buf B814(TD_[5], TD[5]);
  buf B815(TD_[6], TD[6]);
  buf B816(TD_[7], TD[7]);
  buf B817(TD_[8], TD[8]);
  buf B818(TD_[9], TD[9]);
  buf B819(TD_[10], TD[10]);
  buf B820(TD_[11], TD[11]);
  buf B821(TD_[12], TD[12]);
  buf B822(TD_[13], TD[13]);
  buf B823(TD_[14], TD[14]);
  buf B824(TD_[15], TD[15]);
  buf B825(TD_[16], TD[16]);
  buf B826(TD_[17], TD[17]);
  buf B827(TD_[18], TD[18]);
  buf B828(TD_[19], TD[19]);
  buf B829(TD_[20], TD[20]);
  buf B830(TD_[21], TD[21]);
  buf B831(TD_[22], TD[22]);
  buf B832(TD_[23], TD[23]);
  buf B833(TD_[24], TD[24]);
  buf B834(TD_[25], TD[25]);
  buf B835(TD_[26], TD[26]);
  buf B836(TD_[27], TD[27]);
  buf B837(TD_[28], TD[28]);
  buf B838(TD_[29], TD[29]);
  buf B839(TD_[30], TD[30]);
  buf B840(TD_[31], TD[31]);
  buf B841(TD_[32], TD[32]);
  buf B842(TD_[33], TD[33]);
  buf B843(TD_[34], TD[34]);
  buf B844(TD_[35], TD[35]);
  buf B845(TD_[36], TD[36]);
  buf B846(TD_[37], TD[37]);
  buf B847(TD_[38], TD[38]);
  buf B848(TD_[39], TD[39]);
  buf B849(TD_[40], TD[40]);
  buf B850(TD_[41], TD[41]);
  buf B851(TD_[42], TD[42]);
  buf B852(TD_[43], TD[43]);
  buf B853(TD_[44], TD[44]);
  buf B854(TD_[45], TD[45]);
  buf B855(TD_[46], TD[46]);
  buf B856(TD_[47], TD[47]);
  buf B857(TD_[48], TD[48]);
  buf B858(TD_[49], TD[49]);
  buf B859(TD_[50], TD[50]);
  buf B860(TD_[51], TD[51]);
  buf B861(TD_[52], TD[52]);
  buf B862(TD_[53], TD[53]);
  buf B863(TD_[54], TD[54]);
  buf B864(TD_[55], TD[55]);
  buf B865(TD_[56], TD[56]);
  buf B866(TD_[57], TD[57]);
  buf B867(TD_[58], TD[58]);
  buf B868(TD_[59], TD[59]);
  buf B869(TD_[60], TD[60]);
  buf B870(TD_[61], TD[61]);
  buf B871(TD_[62], TD[62]);
  buf B872(TD_[63], TD[63]);
  buf B873(GWEN_, GWEN);
  buf B874(TGWEN_, TGWEN);
  buf B875(RET1N_, RET1N);
  buf B876(SI_[0], SI[0]);
  buf B877(SI_[1], SI[1]);
  buf B878(SE_, SE);
  buf B879(DFTRAMBYP_, DFTRAMBYP);

  assign CENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? CEN_ : TCEN_)) : 1'bx;
  assign WENY_ = (RET1N_ | pre_charge_st) ? ({64{DFTRAMBYP_}} & (TEN_ ? WEN_ : TWEN_)) : {64{1'bx}};
  assign AY_ = (RET1N_ | pre_charge_st) ? ({12{DFTRAMBYP_}} & (TEN_ ? A_ : TA_)) : {12{1'bx}};
  assign GWENY_ = (RET1N_ | pre_charge_st) ? (DFTRAMBYP_ & (TEN_ ? GWEN_ : TGWEN_)) : 1'bx;
   `ifdef ARM_FAULT_MODELING
     ARM_SPSRAM_64X4096_M8_MEM_error_injection u1(.CLK(CLK_), .Q_out(Q_), .A(A_int), .CEN(CEN_int), .DFTRAMBYP(DFTRAMBYP_int), .SE(SE_int), .GWEN(GWEN_int), .WEN(WEN_int), .Q_in(Q_int));
  `else
  assign Q_ = (RET1N_ | pre_charge_st) ? ((Q_int)) : {64{1'bx}};
  `endif
  assign SO_ = (RET1N_ | pre_charge_st) ? ({Q_[32], Q_[31]}) : {2{1'bx}};

// If INITIALIZE_MEMORY is defined at Simulator Command Line, it Initializes the Memory with all ZEROS.
`ifdef INITIALIZE_MEMORY
  integer i;
  initial begin
    #0;
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'b0}};
  end
`endif
  always @ (EMA_) begin
  	if(EMA_ < 2) 
   	$display("Warning: Set Value for EMA doesn't match Default value 2 in %m at %0t", $time);
  end
  always @ (EMAW_) begin
  	if(EMAW_ < 0) 
   	$display("Warning: Set Value for EMAW doesn't match Default value 0 in %m at %0t", $time);
  end

  task failedWrite;
  input port_f;
  integer i;
  begin
    for (i = 0; i < MEM_HEIGHT; i = i + 1)
      mem[i] = {MEM_WIDTH{1'bx}};
  end
  endtask

  function isBitX;
    input bitval;
    begin
      isBitX = ( bitval===1'bx || bitval===1'bz ) ? 1'b1 : 1'b0;
    end
  endfunction

  function isBit1;
    input bitval;
    begin
      isBit1 = ( bitval===1'b1 ) ? 1'b1 : 1'b0;
    end
  endfunction



  task readWrite;
  begin
    if (GWEN_int !== 1'b1 && DFTRAMBYP_int=== 1'b0 && SE_int === 1'bx) begin
      failedWrite(0);
    end else if (DFTRAMBYP_int=== 1'b0 && SE_int === 1'b1) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'bx || RET1N_int === 1'bz) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0 && (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_int === 1'b0) begin
      // no cycle in retention mode
    end else if (^{(EMA_int & isBit1(DFTRAMBYP_int)), (EMAW_int & isBit1(DFTRAMBYP_int))} === 1'bx) begin
        Q_int = {64{1'bx}};
    end else if (^{(CEN_int & !isBit1(DFTRAMBYP_int)), EMA_int, EMAW_int, RET1N_int} === 1'bx) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if ((A_int >= WORDS) && (CEN_int === 1'b0) && DFTRAMBYP_int === 1'b0) begin
      Q_int = GWEN_int !== 1'b1 ? Q_int : {64{1'bx}};
    end else if (CEN_int === 1'b0 && (^A_int) === 1'bx && DFTRAMBYP_int === 1'b0) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (CEN_int === 1'b0 || DFTRAMBYP_int === 1'b1) begin
      if(isBitX(DFTRAMBYP_int) || isBitX(SE_int))
        D_int = {64{1'bx}};

      mux_address = (A_int & 3'b111);
      row_address = (A_int >> 3);
      if (DFTRAMBYP_int !== 1'b1) begin
      if (row_address > 511)
        row = {512{1'bx}};
      else
        row = mem[row_address];
      end
      if( (isBitX(GWEN_int) && DFTRAMBYP_int!==1) || isBitX(DFTRAMBYP_int) ) begin
        writeEnable = {64{1'bx}};
        D_int = {64{1'bx}};
      end else
          writeEnable = ~ ( {64{GWEN_int}} | {WEN_int[63], WEN_int[62], WEN_int[61],
          WEN_int[60], WEN_int[59], WEN_int[58], WEN_int[57], WEN_int[56], WEN_int[55],
          WEN_int[54], WEN_int[53], WEN_int[52], WEN_int[51], WEN_int[50], WEN_int[49],
          WEN_int[48], WEN_int[47], WEN_int[46], WEN_int[45], WEN_int[44], WEN_int[43],
          WEN_int[42], WEN_int[41], WEN_int[40], WEN_int[39], WEN_int[38], WEN_int[37],
          WEN_int[36], WEN_int[35], WEN_int[34], WEN_int[33], WEN_int[32], WEN_int[31],
          WEN_int[30], WEN_int[29], WEN_int[28], WEN_int[27], WEN_int[26], WEN_int[25],
          WEN_int[24], WEN_int[23], WEN_int[22], WEN_int[21], WEN_int[20], WEN_int[19],
          WEN_int[18], WEN_int[17], WEN_int[16], WEN_int[15], WEN_int[14], WEN_int[13],
          WEN_int[12], WEN_int[11], WEN_int[10], WEN_int[9], WEN_int[8], WEN_int[7],
          WEN_int[6], WEN_int[5], WEN_int[4], WEN_int[3], WEN_int[2], WEN_int[1], WEN_int[0]});
      if (GWEN_int !== 1'b1 || DFTRAMBYP_int === 1'b1 || DFTRAMBYP_int === 1'bx) begin
        row_mask =  ( {7'b0000000, writeEnable[63], 7'b0000000, writeEnable[62], 7'b0000000, writeEnable[61],
          7'b0000000, writeEnable[60], 7'b0000000, writeEnable[59], 7'b0000000, writeEnable[58],
          7'b0000000, writeEnable[57], 7'b0000000, writeEnable[56], 7'b0000000, writeEnable[55],
          7'b0000000, writeEnable[54], 7'b0000000, writeEnable[53], 7'b0000000, writeEnable[52],
          7'b0000000, writeEnable[51], 7'b0000000, writeEnable[50], 7'b0000000, writeEnable[49],
          7'b0000000, writeEnable[48], 7'b0000000, writeEnable[47], 7'b0000000, writeEnable[46],
          7'b0000000, writeEnable[45], 7'b0000000, writeEnable[44], 7'b0000000, writeEnable[43],
          7'b0000000, writeEnable[42], 7'b0000000, writeEnable[41], 7'b0000000, writeEnable[40],
          7'b0000000, writeEnable[39], 7'b0000000, writeEnable[38], 7'b0000000, writeEnable[37],
          7'b0000000, writeEnable[36], 7'b0000000, writeEnable[35], 7'b0000000, writeEnable[34],
          7'b0000000, writeEnable[33], 7'b0000000, writeEnable[32], 7'b0000000, writeEnable[31],
          7'b0000000, writeEnable[30], 7'b0000000, writeEnable[29], 7'b0000000, writeEnable[28],
          7'b0000000, writeEnable[27], 7'b0000000, writeEnable[26], 7'b0000000, writeEnable[25],
          7'b0000000, writeEnable[24], 7'b0000000, writeEnable[23], 7'b0000000, writeEnable[22],
          7'b0000000, writeEnable[21], 7'b0000000, writeEnable[20], 7'b0000000, writeEnable[19],
          7'b0000000, writeEnable[18], 7'b0000000, writeEnable[17], 7'b0000000, writeEnable[16],
          7'b0000000, writeEnable[15], 7'b0000000, writeEnable[14], 7'b0000000, writeEnable[13],
          7'b0000000, writeEnable[12], 7'b0000000, writeEnable[11], 7'b0000000, writeEnable[10],
          7'b0000000, writeEnable[9], 7'b0000000, writeEnable[8], 7'b0000000, writeEnable[7],
          7'b0000000, writeEnable[6], 7'b0000000, writeEnable[5], 7'b0000000, writeEnable[4],
          7'b0000000, writeEnable[3], 7'b0000000, writeEnable[2], 7'b0000000, writeEnable[1],
          7'b0000000, writeEnable[0]} << mux_address);
        new_data =  ( {7'b0000000, D_int[63], 7'b0000000, D_int[62], 7'b0000000, D_int[61],
          7'b0000000, D_int[60], 7'b0000000, D_int[59], 7'b0000000, D_int[58], 7'b0000000, D_int[57],
          7'b0000000, D_int[56], 7'b0000000, D_int[55], 7'b0000000, D_int[54], 7'b0000000, D_int[53],
          7'b0000000, D_int[52], 7'b0000000, D_int[51], 7'b0000000, D_int[50], 7'b0000000, D_int[49],
          7'b0000000, D_int[48], 7'b0000000, D_int[47], 7'b0000000, D_int[46], 7'b0000000, D_int[45],
          7'b0000000, D_int[44], 7'b0000000, D_int[43], 7'b0000000, D_int[42], 7'b0000000, D_int[41],
          7'b0000000, D_int[40], 7'b0000000, D_int[39], 7'b0000000, D_int[38], 7'b0000000, D_int[37],
          7'b0000000, D_int[36], 7'b0000000, D_int[35], 7'b0000000, D_int[34], 7'b0000000, D_int[33],
          7'b0000000, D_int[32], 7'b0000000, D_int[31], 7'b0000000, D_int[30], 7'b0000000, D_int[29],
          7'b0000000, D_int[28], 7'b0000000, D_int[27], 7'b0000000, D_int[26], 7'b0000000, D_int[25],
          7'b0000000, D_int[24], 7'b0000000, D_int[23], 7'b0000000, D_int[22], 7'b0000000, D_int[21],
          7'b0000000, D_int[20], 7'b0000000, D_int[19], 7'b0000000, D_int[18], 7'b0000000, D_int[17],
          7'b0000000, D_int[16], 7'b0000000, D_int[15], 7'b0000000, D_int[14], 7'b0000000, D_int[13],
          7'b0000000, D_int[12], 7'b0000000, D_int[11], 7'b0000000, D_int[10], 7'b0000000, D_int[9],
          7'b0000000, D_int[8], 7'b0000000, D_int[7], 7'b0000000, D_int[6], 7'b0000000, D_int[5],
          7'b0000000, D_int[4], 7'b0000000, D_int[3], 7'b0000000, D_int[2], 7'b0000000, D_int[1],
          7'b0000000, D_int[0]} << mux_address);
        row = (row & ~row_mask) | (row_mask & (~row_mask | new_data));
        if (DFTRAMBYP_int === 1'b1 && SE_int === 1'b0) begin
        end else if (GWEN_int !== 1'b1 && DFTRAMBYP_int === 1'b1 && SE_int === 1'bx) begin
             Q_int = {64{1'bx}};
        end else begin
        mem[row_address] = row;
        end
      end else begin
        data_out = (row >> (mux_address%8));
        readLatch0 = {data_out[504], data_out[496], data_out[488], data_out[480], data_out[472],
          data_out[464], data_out[456], data_out[448], data_out[440], data_out[432],
          data_out[424], data_out[416], data_out[408], data_out[400], data_out[392],
          data_out[384], data_out[376], data_out[368], data_out[360], data_out[352],
          data_out[344], data_out[336], data_out[328], data_out[320], data_out[312],
          data_out[304], data_out[296], data_out[288], data_out[280], data_out[272],
          data_out[264], data_out[256], data_out[248], data_out[240], data_out[232],
          data_out[224], data_out[216], data_out[208], data_out[200], data_out[192],
          data_out[184], data_out[176], data_out[168], data_out[160], data_out[152],
          data_out[144], data_out[136], data_out[128], data_out[120], data_out[112],
          data_out[104], data_out[96], data_out[88], data_out[80], data_out[72], data_out[64],
          data_out[56], data_out[48], data_out[40], data_out[32], data_out[24], data_out[16],
          data_out[8], data_out[0]};
        shifted_readLatch0 = readLatch0;
        Q_int = {shifted_readLatch0[63], shifted_readLatch0[62], shifted_readLatch0[61],
          shifted_readLatch0[60], shifted_readLatch0[59], shifted_readLatch0[58], shifted_readLatch0[57],
          shifted_readLatch0[56], shifted_readLatch0[55], shifted_readLatch0[54], shifted_readLatch0[53],
          shifted_readLatch0[52], shifted_readLatch0[51], shifted_readLatch0[50], shifted_readLatch0[49],
          shifted_readLatch0[48], shifted_readLatch0[47], shifted_readLatch0[46], shifted_readLatch0[45],
          shifted_readLatch0[44], shifted_readLatch0[43], shifted_readLatch0[42], shifted_readLatch0[41],
          shifted_readLatch0[40], shifted_readLatch0[39], shifted_readLatch0[38], shifted_readLatch0[37],
          shifted_readLatch0[36], shifted_readLatch0[35], shifted_readLatch0[34], shifted_readLatch0[33],
          shifted_readLatch0[32], shifted_readLatch0[31], shifted_readLatch0[30], shifted_readLatch0[29],
          shifted_readLatch0[28], shifted_readLatch0[27], shifted_readLatch0[26], shifted_readLatch0[25],
          shifted_readLatch0[24], shifted_readLatch0[23], shifted_readLatch0[22], shifted_readLatch0[21],
          shifted_readLatch0[20], shifted_readLatch0[19], shifted_readLatch0[18], shifted_readLatch0[17],
          shifted_readLatch0[16], shifted_readLatch0[15], shifted_readLatch0[14], shifted_readLatch0[13],
          shifted_readLatch0[12], shifted_readLatch0[11], shifted_readLatch0[10], shifted_readLatch0[9],
          shifted_readLatch0[8], shifted_readLatch0[7], shifted_readLatch0[6], shifted_readLatch0[5],
          shifted_readLatch0[4], shifted_readLatch0[3], shifted_readLatch0[2], shifted_readLatch0[1],
          shifted_readLatch0[0]};
      end
      if (DFTRAMBYP_int === 1'b1) begin
        Q_int = D_int;
      end
      if( isBitX(GWEN_int) && DFTRAMBYP_int !== 1'b1) begin
        Q_int = {64{1'bx}};
      end
      if( isBitX(DFTRAMBYP_int) )
        Q_int = {64{1'bx}};
    end
  end
  endtask
  always @ (CEN_ or TCEN_ or TEN_ or DFTRAMBYP_ or CLK_) begin
  	if(CLK_ == 1'b0) begin
  		CEN_p2 = CEN_;
  		TCEN_p2 = TCEN_;
  		DFTRAMBYP_p2 = DFTRAMBYP_;
  	end
  end

`ifdef POWER_PINS
  always @ (VDD) begin
      if (VDD != 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDD should be powered down after VDDP, Illegal power down sequencing in %m at %0t", $time);
       end
        $display("In PowerDown Mode in %m at %0t", $time);
        failedWrite(0);
      end
      if (VDD == 1'b1) begin
       if (VDDP == 1'b1) begin
        $display("VDDP should be powered up after VDD in %m at %0t", $time);
        $display("Illegal power up sequencing in %m at %0t", $time);
       end
        failedWrite(0);
      end
  end
`endif
`ifdef POWER_PINS
  always @ (RET1N_ or VDDP or VDD) begin
`else     
  always @ RET1N_ begin
`endif
`ifdef POWER_PINS
    if (RET1N_ == 1'b1 && RET1N_int == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 && pre_charge_st == 1'b1 && (CEN_ === 1'bx || TCEN_ === 1'bx || DFTRAMBYP_ === 1'bx || CLK_ === 1'bx)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end
`else     
`endif
`ifdef POWER_PINS
`else     
      pre_charge_st = 0;
`endif
    if (RET1N_ === 1'bx || RET1N_ === 1'bz) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b0 && RET1N_int === 1'b1 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (RET1N_ === 1'b1 && RET1N_int === 1'b0 && (CEN_p2 === 1'b0 || TCEN_p2 === 1'b0 || DFTRAMBYP_p2 === 1'b1)) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end
`ifdef POWER_PINS
    if (RET1N_ == 1'b0 && VDD == 1'b1 && VDDP == 1'b1) begin
      pre_charge_st = 1;
    end else if (RET1N_ == 1'b0 && VDDP == 1'b0) begin
      pre_charge_st = 0;
      if (VDD != 1'b1) begin
        failedWrite(0);
      end
`else     
    if (RET1N_ == 1'b0) begin
`endif
      Q_int = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SI_int = {2{1'bx}};
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
`ifdef POWER_PINS
    end else if (RET1N_ == 1'b1 && VDD == 1'b1 && VDDP == 1'b1 &&  pre_charge_st == 1'b1) begin
      pre_charge_st = 0;
    end else begin
      pre_charge_st = 0;
`else     
    end else begin
`endif
        Q_int = {64{1'bx}};
      CEN_int = 1'bx;
      WEN_int = {64{1'bx}};
      A_int = {12{1'bx}};
      D_int = {64{1'bx}};
      EMA_int = {3{1'bx}};
      EMAW_int = {2{1'bx}};
      TEN_int = 1'bx;
      TCEN_int = 1'bx;
      TWEN_int = {64{1'bx}};
      TA_int = {12{1'bx}};
      TD_int = {64{1'bx}};
      GWEN_int = 1'bx;
      TGWEN_int = 1'bx;
      RET1N_int = 1'bx;
      SI_int = {2{1'bx}};
      SE_int = 1'bx;
      DFTRAMBYP_int = 1'bx;
    end
    RET1N_int = RET1N_;
  end

  always @ (SI_int) begin
  	#0;
      if (DFTRAMBYP_=== 1'b1 && SE_ === 1'b1 && ^SI_int === 1'bx) begin
	Q_int[63] = SI_int[1]; 
	Q_int[0] = SI_int[0]; 
  	end
  end

  always @ CLK_ begin
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
`endif
`ifdef POWER_PINS
  if (RET1N_ == 1'b0) begin
`else     
  if (RET1N_ == 1'b0) begin
`endif
      // no cycle in retention mode
  end else begin
    if ((CLK_ === 1'bx || CLK_ === 1'bz) && RET1N_ !== 1'b0) begin
      failedWrite(0);
        Q_int = {64{1'bx}};
    end else if (CLK_ === 1'b1 && LAST_CLK === 1'b0) begin
      SI_int = SI_;
      SE_int = SE_;
      DFTRAMBYP_int = DFTRAMBYP_;
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      SI_int = SI_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
      if (DFTRAMBYP_=== 1'b1 && SE_ === 1'b1) begin
	Q_int[63:32] = {SI_[1], Q_int[63:33]}; 
	Q_int[31:0] = {Q_int[30:0], SI_[0]}; 
      end else begin
      CEN_int = TEN_ ? CEN_ : TCEN_;
      EMA_int = EMA_;
      EMAW_int = EMAW_;
      TEN_int = TEN_;
      TWEN_int = TWEN_;
      RET1N_int = RET1N_;
      SI_int = SI_;
      if (DFTRAMBYP_=== 1'b1 || CEN_int != 1'b1) begin
        WEN_int = TEN_ ? WEN_ : TWEN_;
        A_int = TEN_ ? A_ : TA_;
        D_int = TEN_ ? D_ : TD_;
        TCEN_int = TCEN_;
        TA_int = TA_;
        TD_int = TD_;
        GWEN_int = TEN_ ? GWEN_ : TGWEN_;
        TGWEN_int = TGWEN_;
        DFTRAMBYP_int = DFTRAMBYP_;
      end
      clk0_int = 1'b0;
    readWrite;
      end
    end else if (CLK_ === 1'b0 && LAST_CLK === 1'b1) begin
    end
  end
    LAST_CLK = CLK_;
  end

  reg globalNotifier0;
  initial globalNotifier0 = 1'b0;

  always @ globalNotifier0 begin
    if ($realtime == 0) begin
    end else if ((EMAW_int[0] === 1'bx & DFTRAMBYP_int === 1'b1) || (EMAW_int[1] === 1'bx & DFTRAMBYP_int === 1'b1) || 
      (EMA_int[0] === 1'bx & DFTRAMBYP_int === 1'b1) || (EMA_int[1] === 1'bx & DFTRAMBYP_int === 1'b1) || 
      (EMA_int[2] === 1'bx & DFTRAMBYP_int === 1'b1)) begin
        Q_int = {64{1'bx}};
    end else if ((CEN_int === 1'bx & DFTRAMBYP_int === 1'b0) || EMAW_int[0] === 1'bx || 
      EMAW_int[1] === 1'bx || EMA_int[0] === 1'bx || EMA_int[1] === 1'bx || EMA_int[2] === 1'bx || 
      RET1N_int === 1'bx || clk0_int === 1'bx) begin
        Q_int = {64{1'bx}};
      failedWrite(0);
    end else if (TEN_int === 1'bx) begin
      if(((CEN_ === 1'b1 & TCEN_ === 1'b1) & DFTRAMBYP_int === 1'b0) | (DFTRAMBYP_int === 1'b1 & SE_int === 1'b1)) begin
      end else begin
        Q_int = {64{1'bx}};
      if (DFTRAMBYP_int === 1'b0) begin
          failedWrite(0);
      end
      end
    end else if (^SI_int === 1'bx && DFTRAMBYP_int === 1'b1) begin
    end else begin
      #0;
      readWrite;
   end
    globalNotifier0 = 1'b0;
  end
// If POWER_PINS is defined at Simulator Command Line, it selects the module definition with Power Ports
`ifdef POWER_PINS
 always @ (VDD or VDDP or VSS) begin
    if (VDD === 1'bx || VDD === 1'bz)
      $display("Warning: Unknown value for VDD %b in %m at %0t", VDD, $time);
    if (VDDP === 1'bx || VDDP === 1'bz)
      $display("Warning: Unknown value for VDDP %b in %m at %0t", VDDP, $time);
    if (VSS === 1'bx || VSS === 1'bz)
      $display("Warning: Unknown value for VSS %b in %m at %0t", VSS, $time);
 end
`endif

  always @ NOT_CEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN63 begin
    WEN_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN62 begin
    WEN_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN61 begin
    WEN_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN60 begin
    WEN_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN59 begin
    WEN_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN58 begin
    WEN_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN57 begin
    WEN_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN56 begin
    WEN_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN55 begin
    WEN_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN54 begin
    WEN_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN53 begin
    WEN_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN52 begin
    WEN_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN51 begin
    WEN_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN50 begin
    WEN_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN49 begin
    WEN_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN48 begin
    WEN_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN47 begin
    WEN_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN46 begin
    WEN_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN45 begin
    WEN_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN44 begin
    WEN_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN43 begin
    WEN_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN42 begin
    WEN_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN41 begin
    WEN_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN40 begin
    WEN_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN39 begin
    WEN_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN38 begin
    WEN_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN37 begin
    WEN_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN36 begin
    WEN_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN35 begin
    WEN_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN34 begin
    WEN_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN33 begin
    WEN_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN32 begin
    WEN_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN31 begin
    WEN_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN30 begin
    WEN_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN29 begin
    WEN_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN28 begin
    WEN_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN27 begin
    WEN_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN26 begin
    WEN_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN25 begin
    WEN_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN24 begin
    WEN_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN23 begin
    WEN_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN22 begin
    WEN_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN21 begin
    WEN_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN20 begin
    WEN_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN19 begin
    WEN_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN18 begin
    WEN_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN17 begin
    WEN_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN16 begin
    WEN_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN15 begin
    WEN_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN14 begin
    WEN_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN13 begin
    WEN_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN12 begin
    WEN_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN11 begin
    WEN_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN10 begin
    WEN_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN9 begin
    WEN_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN8 begin
    WEN_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN7 begin
    WEN_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN6 begin
    WEN_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN5 begin
    WEN_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN4 begin
    WEN_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN3 begin
    WEN_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN2 begin
    WEN_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN1 begin
    WEN_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_WEN0 begin
    WEN_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A11 begin
    A_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A10 begin
    A_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A9 begin
    A_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_A0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D63 begin
    D_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D62 begin
    D_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D61 begin
    D_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D60 begin
    D_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D59 begin
    D_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D58 begin
    D_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D57 begin
    D_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D56 begin
    D_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D55 begin
    D_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D54 begin
    D_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D53 begin
    D_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D52 begin
    D_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D51 begin
    D_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D50 begin
    D_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D49 begin
    D_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D48 begin
    D_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D47 begin
    D_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D46 begin
    D_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D45 begin
    D_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D44 begin
    D_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D43 begin
    D_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D42 begin
    D_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D41 begin
    D_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D40 begin
    D_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D39 begin
    D_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D38 begin
    D_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D37 begin
    D_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D36 begin
    D_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D35 begin
    D_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D34 begin
    D_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D33 begin
    D_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D32 begin
    D_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D31 begin
    D_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D30 begin
    D_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D29 begin
    D_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D28 begin
    D_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D27 begin
    D_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D26 begin
    D_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D25 begin
    D_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D24 begin
    D_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D23 begin
    D_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D22 begin
    D_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D21 begin
    D_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D20 begin
    D_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D19 begin
    D_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D18 begin
    D_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D17 begin
    D_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D16 begin
    D_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D15 begin
    D_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D14 begin
    D_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D13 begin
    D_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D12 begin
    D_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D11 begin
    D_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D10 begin
    D_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D9 begin
    D_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D8 begin
    D_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_D0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA2 begin
    EMA_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA1 begin
    EMA_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMA0 begin
    EMA_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW1 begin
    EMAW_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_EMAW0 begin
    EMAW_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TEN begin
    TEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TCEN begin
    CEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN63 begin
    WEN_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN62 begin
    WEN_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN61 begin
    WEN_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN60 begin
    WEN_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN59 begin
    WEN_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN58 begin
    WEN_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN57 begin
    WEN_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN56 begin
    WEN_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN55 begin
    WEN_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN54 begin
    WEN_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN53 begin
    WEN_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN52 begin
    WEN_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN51 begin
    WEN_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN50 begin
    WEN_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN49 begin
    WEN_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN48 begin
    WEN_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN47 begin
    WEN_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN46 begin
    WEN_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN45 begin
    WEN_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN44 begin
    WEN_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN43 begin
    WEN_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN42 begin
    WEN_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN41 begin
    WEN_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN40 begin
    WEN_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN39 begin
    WEN_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN38 begin
    WEN_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN37 begin
    WEN_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN36 begin
    WEN_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN35 begin
    WEN_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN34 begin
    WEN_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN33 begin
    WEN_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN32 begin
    WEN_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN31 begin
    WEN_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN30 begin
    WEN_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN29 begin
    WEN_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN28 begin
    WEN_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN27 begin
    WEN_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN26 begin
    WEN_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN25 begin
    WEN_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN24 begin
    WEN_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN23 begin
    WEN_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN22 begin
    WEN_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN21 begin
    WEN_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN20 begin
    WEN_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN19 begin
    WEN_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN18 begin
    WEN_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN17 begin
    WEN_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN16 begin
    WEN_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN15 begin
    WEN_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN14 begin
    WEN_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN13 begin
    WEN_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN12 begin
    WEN_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN11 begin
    WEN_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN10 begin
    WEN_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN9 begin
    WEN_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN8 begin
    WEN_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN7 begin
    WEN_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN6 begin
    WEN_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN5 begin
    WEN_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN4 begin
    WEN_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN3 begin
    WEN_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN2 begin
    WEN_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN1 begin
    WEN_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TWEN0 begin
    WEN_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA11 begin
    A_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA10 begin
    A_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA9 begin
    A_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA8 begin
    A_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA7 begin
    A_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA6 begin
    A_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA5 begin
    A_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA4 begin
    A_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA3 begin
    A_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA2 begin
    A_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA1 begin
    A_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TA0 begin
    A_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD63 begin
    D_int[63] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD62 begin
    D_int[62] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD61 begin
    D_int[61] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD60 begin
    D_int[60] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD59 begin
    D_int[59] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD58 begin
    D_int[58] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD57 begin
    D_int[57] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD56 begin
    D_int[56] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD55 begin
    D_int[55] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD54 begin
    D_int[54] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD53 begin
    D_int[53] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD52 begin
    D_int[52] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD51 begin
    D_int[51] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD50 begin
    D_int[50] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD49 begin
    D_int[49] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD48 begin
    D_int[48] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD47 begin
    D_int[47] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD46 begin
    D_int[46] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD45 begin
    D_int[45] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD44 begin
    D_int[44] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD43 begin
    D_int[43] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD42 begin
    D_int[42] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD41 begin
    D_int[41] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD40 begin
    D_int[40] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD39 begin
    D_int[39] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD38 begin
    D_int[38] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD37 begin
    D_int[37] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD36 begin
    D_int[36] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD35 begin
    D_int[35] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD34 begin
    D_int[34] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD33 begin
    D_int[33] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD32 begin
    D_int[32] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD31 begin
    D_int[31] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD30 begin
    D_int[30] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD29 begin
    D_int[29] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD28 begin
    D_int[28] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD27 begin
    D_int[27] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD26 begin
    D_int[26] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD25 begin
    D_int[25] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD24 begin
    D_int[24] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD23 begin
    D_int[23] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD22 begin
    D_int[22] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD21 begin
    D_int[21] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD20 begin
    D_int[20] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD19 begin
    D_int[19] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD18 begin
    D_int[18] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD17 begin
    D_int[17] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD16 begin
    D_int[16] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD15 begin
    D_int[15] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD14 begin
    D_int[14] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD13 begin
    D_int[13] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD12 begin
    D_int[12] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD11 begin
    D_int[11] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD10 begin
    D_int[10] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD9 begin
    D_int[9] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD8 begin
    D_int[8] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD7 begin
    D_int[7] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD6 begin
    D_int[6] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD5 begin
    D_int[5] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD4 begin
    D_int[4] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD3 begin
    D_int[3] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD2 begin
    D_int[2] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD1 begin
    D_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TD0 begin
    D_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_GWEN begin
    GWEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_TGWEN begin
    GWEN_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_SI1 begin
    SI_int[1] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_SI0 begin
    SI_int[0] = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_SE begin
    SE_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_DFTRAMBYP begin
    DFTRAMBYP_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_RET1N begin
    RET1N_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end

  always @ NOT_CLK_PER begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINH begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end
  always @ NOT_CLK_MINL begin
    clk0_int = 1'bx;
    if ( globalNotifier0 === 1'b0 ) globalNotifier0 = 1'bx;
  end


  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0;
  wire RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0;
  wire RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0;
  wire RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0;

  wire RET1Neq1aTENeq1, RET1Neq1aTENeq0, RET1Neq1aTENeq1aCENeq0, RET1Neq1aTENeq0aTCENeq0;
  wire RET1Neq1aSEeq1, RET1Neq1;

  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && !EMA[2] && EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && !EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && !EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && !EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && EMAW[1] && !EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && EMA[2] && EMA[1] && EMA[0] && EMAW[1] && EMAW[0] && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[63] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[62] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[61] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[60] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[59] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[58] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[57] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[56] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[55] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[54] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[53] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[52] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[51] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[50] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[49] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[48] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[47] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[46] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[45] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[44] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[43] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[42] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[41] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[40] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[39] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[38] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[37] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[36] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[35] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[34] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[33] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[32] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[31] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[30] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[29] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[28] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[27] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[26] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[25] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[24] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[23] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[22] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[21] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[20] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[19] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[18] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[17] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[16] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[15] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[14] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[13] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[12] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[11] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[10] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[9] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[8] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[7] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[6] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[5] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[4] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[3] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[2] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[1] && !GWEN));
  assign RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0 = 
  RET1N && TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !CEN && !WEN[0] && !GWEN));
  assign RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1 = 
  RET1N && (((TEN && !CEN && !DFTRAMBYP) || (!TEN && !TCEN && !DFTRAMBYP)) || DFTRAMBYP);
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[63] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[62] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[61] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[60] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[59] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[58] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[57] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[56] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[55] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[54] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[53] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[52] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[51] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[50] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[49] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[48] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[47] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[46] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[45] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[44] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[43] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[42] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[41] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[40] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[39] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[38] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[37] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[36] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[35] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[34] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[33] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[32] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[31] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[30] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[29] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[28] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[27] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[26] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[25] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[24] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[23] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[22] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[21] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[20] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[19] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[18] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[17] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[16] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[15] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[14] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[13] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[12] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[11] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[10] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[9] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[8] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[7] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[6] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[5] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[4] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[3] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[2] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[1] && !TGWEN));
  assign RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0 = 
  RET1N && !TEN && ((DFTRAMBYP && !SE) || (!DFTRAMBYP && !TCEN && !TWEN[0] && !TGWEN));


  assign RET1Neq1aTENeq1aCENeq0 = RET1N && TEN && !CEN;
  assign RET1Neq1aTENeq0aTCENeq0 = RET1N && !TEN && !TCEN;

  assign RET1Neq1aTENeq1 = RET1N && TEN;
  assign RET1Neq1aTENeq0 = RET1N && !TEN;
  assign RET1Neq1aSEeq1 = RET1N && SE;
  assign RET1Neq1 = RET1N;

  specify

    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (CEN +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TCEN +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && CEN == 1'b0 && TCEN == 1'b1)
       (TEN -=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && CEN == 1'b1 && TCEN == 1'b0)
       (TEN +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> CENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[63] == 1'b0 && TWEN[63] == 1'b1)
       (TEN -=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[63] == 1'b1 && TWEN[63] == 1'b0)
       (TEN +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[62] == 1'b0 && TWEN[62] == 1'b1)
       (TEN -=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[62] == 1'b1 && TWEN[62] == 1'b0)
       (TEN +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[61] == 1'b0 && TWEN[61] == 1'b1)
       (TEN -=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[61] == 1'b1 && TWEN[61] == 1'b0)
       (TEN +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[60] == 1'b0 && TWEN[60] == 1'b1)
       (TEN -=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[60] == 1'b1 && TWEN[60] == 1'b0)
       (TEN +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[59] == 1'b0 && TWEN[59] == 1'b1)
       (TEN -=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[59] == 1'b1 && TWEN[59] == 1'b0)
       (TEN +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[58] == 1'b0 && TWEN[58] == 1'b1)
       (TEN -=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[58] == 1'b1 && TWEN[58] == 1'b0)
       (TEN +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[57] == 1'b0 && TWEN[57] == 1'b1)
       (TEN -=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[57] == 1'b1 && TWEN[57] == 1'b0)
       (TEN +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[56] == 1'b0 && TWEN[56] == 1'b1)
       (TEN -=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[56] == 1'b1 && TWEN[56] == 1'b0)
       (TEN +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[55] == 1'b0 && TWEN[55] == 1'b1)
       (TEN -=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[55] == 1'b1 && TWEN[55] == 1'b0)
       (TEN +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[54] == 1'b0 && TWEN[54] == 1'b1)
       (TEN -=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[54] == 1'b1 && TWEN[54] == 1'b0)
       (TEN +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[53] == 1'b0 && TWEN[53] == 1'b1)
       (TEN -=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[53] == 1'b1 && TWEN[53] == 1'b0)
       (TEN +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[52] == 1'b0 && TWEN[52] == 1'b1)
       (TEN -=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[52] == 1'b1 && TWEN[52] == 1'b0)
       (TEN +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[51] == 1'b0 && TWEN[51] == 1'b1)
       (TEN -=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[51] == 1'b1 && TWEN[51] == 1'b0)
       (TEN +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[50] == 1'b0 && TWEN[50] == 1'b1)
       (TEN -=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[50] == 1'b1 && TWEN[50] == 1'b0)
       (TEN +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[49] == 1'b0 && TWEN[49] == 1'b1)
       (TEN -=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[49] == 1'b1 && TWEN[49] == 1'b0)
       (TEN +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[48] == 1'b0 && TWEN[48] == 1'b1)
       (TEN -=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[48] == 1'b1 && TWEN[48] == 1'b0)
       (TEN +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[47] == 1'b0 && TWEN[47] == 1'b1)
       (TEN -=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[47] == 1'b1 && TWEN[47] == 1'b0)
       (TEN +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[46] == 1'b0 && TWEN[46] == 1'b1)
       (TEN -=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[46] == 1'b1 && TWEN[46] == 1'b0)
       (TEN +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[45] == 1'b0 && TWEN[45] == 1'b1)
       (TEN -=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[45] == 1'b1 && TWEN[45] == 1'b0)
       (TEN +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[44] == 1'b0 && TWEN[44] == 1'b1)
       (TEN -=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[44] == 1'b1 && TWEN[44] == 1'b0)
       (TEN +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[43] == 1'b0 && TWEN[43] == 1'b1)
       (TEN -=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[43] == 1'b1 && TWEN[43] == 1'b0)
       (TEN +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[42] == 1'b0 && TWEN[42] == 1'b1)
       (TEN -=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[42] == 1'b1 && TWEN[42] == 1'b0)
       (TEN +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[41] == 1'b0 && TWEN[41] == 1'b1)
       (TEN -=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[41] == 1'b1 && TWEN[41] == 1'b0)
       (TEN +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[40] == 1'b0 && TWEN[40] == 1'b1)
       (TEN -=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[40] == 1'b1 && TWEN[40] == 1'b0)
       (TEN +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[39] == 1'b0 && TWEN[39] == 1'b1)
       (TEN -=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[39] == 1'b1 && TWEN[39] == 1'b0)
       (TEN +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[38] == 1'b0 && TWEN[38] == 1'b1)
       (TEN -=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[38] == 1'b1 && TWEN[38] == 1'b0)
       (TEN +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[37] == 1'b0 && TWEN[37] == 1'b1)
       (TEN -=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[37] == 1'b1 && TWEN[37] == 1'b0)
       (TEN +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[36] == 1'b0 && TWEN[36] == 1'b1)
       (TEN -=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[36] == 1'b1 && TWEN[36] == 1'b0)
       (TEN +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[35] == 1'b0 && TWEN[35] == 1'b1)
       (TEN -=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[35] == 1'b1 && TWEN[35] == 1'b0)
       (TEN +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[34] == 1'b0 && TWEN[34] == 1'b1)
       (TEN -=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[34] == 1'b1 && TWEN[34] == 1'b0)
       (TEN +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[33] == 1'b0 && TWEN[33] == 1'b1)
       (TEN -=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[33] == 1'b1 && TWEN[33] == 1'b0)
       (TEN +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[32] == 1'b0 && TWEN[32] == 1'b1)
       (TEN -=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[32] == 1'b1 && TWEN[32] == 1'b0)
       (TEN +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[31] == 1'b0 && TWEN[31] == 1'b1)
       (TEN -=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[31] == 1'b1 && TWEN[31] == 1'b0)
       (TEN +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[30] == 1'b0 && TWEN[30] == 1'b1)
       (TEN -=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[30] == 1'b1 && TWEN[30] == 1'b0)
       (TEN +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[29] == 1'b0 && TWEN[29] == 1'b1)
       (TEN -=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[29] == 1'b1 && TWEN[29] == 1'b0)
       (TEN +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[28] == 1'b0 && TWEN[28] == 1'b1)
       (TEN -=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[28] == 1'b1 && TWEN[28] == 1'b0)
       (TEN +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[27] == 1'b0 && TWEN[27] == 1'b1)
       (TEN -=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[27] == 1'b1 && TWEN[27] == 1'b0)
       (TEN +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[26] == 1'b0 && TWEN[26] == 1'b1)
       (TEN -=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[26] == 1'b1 && TWEN[26] == 1'b0)
       (TEN +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[25] == 1'b0 && TWEN[25] == 1'b1)
       (TEN -=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[25] == 1'b1 && TWEN[25] == 1'b0)
       (TEN +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[24] == 1'b0 && TWEN[24] == 1'b1)
       (TEN -=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[24] == 1'b1 && TWEN[24] == 1'b0)
       (TEN +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[23] == 1'b0 && TWEN[23] == 1'b1)
       (TEN -=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[23] == 1'b1 && TWEN[23] == 1'b0)
       (TEN +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[22] == 1'b0 && TWEN[22] == 1'b1)
       (TEN -=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[22] == 1'b1 && TWEN[22] == 1'b0)
       (TEN +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[21] == 1'b0 && TWEN[21] == 1'b1)
       (TEN -=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[21] == 1'b1 && TWEN[21] == 1'b0)
       (TEN +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[20] == 1'b0 && TWEN[20] == 1'b1)
       (TEN -=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[20] == 1'b1 && TWEN[20] == 1'b0)
       (TEN +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[19] == 1'b0 && TWEN[19] == 1'b1)
       (TEN -=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[19] == 1'b1 && TWEN[19] == 1'b0)
       (TEN +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[18] == 1'b0 && TWEN[18] == 1'b1)
       (TEN -=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[18] == 1'b1 && TWEN[18] == 1'b0)
       (TEN +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[17] == 1'b0 && TWEN[17] == 1'b1)
       (TEN -=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[17] == 1'b1 && TWEN[17] == 1'b0)
       (TEN +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[16] == 1'b0 && TWEN[16] == 1'b1)
       (TEN -=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[16] == 1'b1 && TWEN[16] == 1'b0)
       (TEN +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[15] == 1'b0 && TWEN[15] == 1'b1)
       (TEN -=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[15] == 1'b1 && TWEN[15] == 1'b0)
       (TEN +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[14] == 1'b0 && TWEN[14] == 1'b1)
       (TEN -=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[14] == 1'b1 && TWEN[14] == 1'b0)
       (TEN +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[13] == 1'b0 && TWEN[13] == 1'b1)
       (TEN -=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[13] == 1'b1 && TWEN[13] == 1'b0)
       (TEN +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[12] == 1'b0 && TWEN[12] == 1'b1)
       (TEN -=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[12] == 1'b1 && TWEN[12] == 1'b0)
       (TEN +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[11] == 1'b0 && TWEN[11] == 1'b1)
       (TEN -=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[11] == 1'b1 && TWEN[11] == 1'b0)
       (TEN +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[10] == 1'b0 && TWEN[10] == 1'b1)
       (TEN -=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[10] == 1'b1 && TWEN[10] == 1'b0)
       (TEN +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[9] == 1'b0 && TWEN[9] == 1'b1)
       (TEN -=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[9] == 1'b1 && TWEN[9] == 1'b0)
       (TEN +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[8] == 1'b0 && TWEN[8] == 1'b1)
       (TEN -=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[8] == 1'b1 && TWEN[8] == 1'b0)
       (TEN +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[7] == 1'b0 && TWEN[7] == 1'b1)
       (TEN -=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[7] == 1'b1 && TWEN[7] == 1'b0)
       (TEN +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[6] == 1'b0 && TWEN[6] == 1'b1)
       (TEN -=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[6] == 1'b1 && TWEN[6] == 1'b0)
       (TEN +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[5] == 1'b0 && TWEN[5] == 1'b1)
       (TEN -=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[5] == 1'b1 && TWEN[5] == 1'b0)
       (TEN +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[4] == 1'b0 && TWEN[4] == 1'b1)
       (TEN -=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[4] == 1'b1 && TWEN[4] == 1'b0)
       (TEN +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[3] == 1'b0 && TWEN[3] == 1'b1)
       (TEN -=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[3] == 1'b1 && TWEN[3] == 1'b0)
       (TEN +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[2] == 1'b0 && TWEN[2] == 1'b1)
       (TEN -=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[2] == 1'b1 && TWEN[2] == 1'b0)
       (TEN +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[1] == 1'b0 && TWEN[1] == 1'b1)
       (TEN -=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[1] == 1'b1 && TWEN[1] == 1'b0)
       (TEN +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[0] == 1'b0 && TWEN[0] == 1'b1)
       (TEN -=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && WEN[0] == 1'b1 && TWEN[0] == 1'b0)
       (TEN +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[63] +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[62] +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[61] +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[60] +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[59] +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[58] +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[57] +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[56] +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[55] +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[54] +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[53] +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[52] +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[51] +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[50] +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[49] +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[48] +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[47] +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[46] +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[45] +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[44] +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[43] +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[42] +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[41] +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[40] +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[39] +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[38] +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[37] +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[36] +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[35] +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[34] +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[33] +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[32] +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[31] +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[30] +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[29] +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[28] +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[27] +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[26] +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[25] +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[24] +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[23] +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[22] +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[21] +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[20] +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[19] +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[18] +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[17] +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[16] +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[15] +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[14] +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[13] +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[12] +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[11] +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[10] +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[9] +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[8] +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[7] +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[6] +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[5] +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[4] +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[3] +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[2] +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[1] +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (WEN[0] +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[63] +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[62] +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[61] +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[60] +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[59] +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[58] +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[57] +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[56] +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[55] +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[54] +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[53] +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[52] +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[51] +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[50] +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[49] +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[48] +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[47] +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[46] +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[45] +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[44] +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[43] +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[42] +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[41] +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[40] +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[39] +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[38] +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[37] +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[36] +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[35] +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[34] +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[33] +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[32] +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[31] +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[30] +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[29] +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[28] +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[27] +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[26] +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[25] +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[24] +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[23] +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[22] +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[21] +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[20] +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[19] +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[18] +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[17] +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[16] +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[15] +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[14] +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[13] +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[12] +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[11] +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[10] +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[9] +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[8] +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[7] +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[6] +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[5] +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[4] +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[3] +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[2] +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[1] +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TWEN[0] +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[63]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[62]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[61]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[60]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[59]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[58]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[57]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[56]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[55]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[54]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[53]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[52]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[51]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[50]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[49]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[48]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[47]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[46]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[45]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[44]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[43]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[42]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[41]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[40]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[39]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[38]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[37]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[36]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[35]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[34]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[33]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[32]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[31]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[30]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[29]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[28]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[27]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[26]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[25]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[24]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[23]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[22]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[21]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[20]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[19]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[18]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[17]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[16]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[15]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[14]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[13]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[12]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> WENY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[11] == 1'b0 && TA[11] == 1'b1)
       (TEN -=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[11] == 1'b1 && TA[11] == 1'b0)
       (TEN +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[10] == 1'b0 && TA[10] == 1'b1)
       (TEN -=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[10] == 1'b1 && TA[10] == 1'b0)
       (TEN +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[9] == 1'b0 && TA[9] == 1'b1)
       (TEN -=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[9] == 1'b1 && TA[9] == 1'b0)
       (TEN +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[8] == 1'b0 && TA[8] == 1'b1)
       (TEN -=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[8] == 1'b1 && TA[8] == 1'b0)
       (TEN +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[7] == 1'b0 && TA[7] == 1'b1)
       (TEN -=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[7] == 1'b1 && TA[7] == 1'b0)
       (TEN +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[6] == 1'b0 && TA[6] == 1'b1)
       (TEN -=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[6] == 1'b1 && TA[6] == 1'b0)
       (TEN +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[5] == 1'b0 && TA[5] == 1'b1)
       (TEN -=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[5] == 1'b1 && TA[5] == 1'b0)
       (TEN +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[4] == 1'b0 && TA[4] == 1'b1)
       (TEN -=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[4] == 1'b1 && TA[4] == 1'b0)
       (TEN +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[3] == 1'b0 && TA[3] == 1'b1)
       (TEN -=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[3] == 1'b1 && TA[3] == 1'b0)
       (TEN +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[2] == 1'b0 && TA[2] == 1'b1)
       (TEN -=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[2] == 1'b1 && TA[2] == 1'b0)
       (TEN +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[1] == 1'b0 && TA[1] == 1'b1)
       (TEN -=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[1] == 1'b1 && TA[1] == 1'b0)
       (TEN +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[0] == 1'b0 && TA[0] == 1'b1)
       (TEN -=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && A[0] == 1'b1 && TA[0] == 1'b0)
       (TEN +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[11] +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[10] +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[9] +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[8] +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[7] +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[6] +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[5] +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[4] +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[3] +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[2] +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[1] +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (A[0] +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[11] +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[10] +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[9] +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[8] +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[7] +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[6] +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[5] +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[4] +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[3] +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[2] +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[1] +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TA[0] +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[11]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[10]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[9]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[8]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[7]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[6]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[5]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[4]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[3]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[2]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[1]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> AY[0]) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b1)
       (GWEN +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && TEN == 1'b0)
       (TGWEN +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && GWEN == 1'b0 && TGWEN == 1'b1)
       (TEN -=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (DFTRAMBYP == 1'b1 && GWEN == 1'b1 && TGWEN == 1'b0)
       (TEN +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1)
       (DFTRAMBYP +=> GWENY) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[63] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[62] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[61] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[60] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[59] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[58] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[57] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[56] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[55] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[54] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[53] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[52] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[51] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[50] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[49] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[48] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[47] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[46] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[45] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[44] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[43] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[42] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[41] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[40] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[39] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[38] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[37] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[36] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[35] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[34] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[33] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[32] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[31] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[30] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[29] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[28] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[27] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[26] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[25] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[24] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[23] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[22] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[21] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[20] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[19] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[18] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[17] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[16] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[15] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[14] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[13] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[12] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[11] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[10] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[9] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[8] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[7] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[6] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[5] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[4] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[3] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[2] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (Q[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b0 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b0 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b0 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && EMA[2] == 1'b1 && EMA[1] == 1'b1 && EMA[0] == 1'b1 && DFTRAMBYP == 1'b0 && ((TEN == 1'b1 && GWEN == 1'b1) || (TEN == 1'b0 && TGWEN == 1'b1)))
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (SO[1] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);
    if (RET1N == 1'b1 && DFTRAMBYP == 1'b1)
       (posedge CLK => (SO[0] : 1'b0)) = (`ARM_MEM_PROP, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP, `ARM_MEM_RETAIN, `ARM_MEM_PROP);


   // Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $period(posedge CLK, `ARM_MEM_PERIOD, NOT_CLK_PER);
   `else
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq0aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq0aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq0aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq0aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq0aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
       $period(posedge CLK &&& RET1Neq1aEMA2eq1aEMA1eq1aEMA0eq1aEMAW1eq1aEMAW0eq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, `ARM_MEM_PERIOD, NOT_CLK_PER);
   `endif


   // Define SDTC only if back-annotating SDF file generated by Design Compiler
   `ifdef NO_SDTC
       $width(posedge CLK, `ARM_MEM_WIDTH, 0, NOT_CLK_MINH);
       $width(negedge CLK, `ARM_MEM_WIDTH, 0, NOT_CLK_MINL);
   `else
       $width(posedge CLK &&& RET1Neq1, `ARM_MEM_WIDTH, 0, NOT_CLK_MINH);
       $width(negedge CLK &&& RET1Neq1, `ARM_MEM_WIDTH, 0, NOT_CLK_MINL);
   `endif

    $setuphold(posedge CLK &&& RET1Neq1aTENeq1, posedge CEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_CEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1, negedge CEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_CEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge WEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge WEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_WEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge A[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge A[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_A0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0, posedge D[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN63eq0aGWENeq0, negedge D[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0, posedge D[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN62eq0aGWENeq0, negedge D[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0, posedge D[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN61eq0aGWENeq0, negedge D[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0, posedge D[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN60eq0aGWENeq0, negedge D[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0, posedge D[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN59eq0aGWENeq0, negedge D[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0, posedge D[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN58eq0aGWENeq0, negedge D[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0, posedge D[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN57eq0aGWENeq0, negedge D[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0, posedge D[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN56eq0aGWENeq0, negedge D[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0, posedge D[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN55eq0aGWENeq0, negedge D[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0, posedge D[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN54eq0aGWENeq0, negedge D[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0, posedge D[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN53eq0aGWENeq0, negedge D[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0, posedge D[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN52eq0aGWENeq0, negedge D[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0, posedge D[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN51eq0aGWENeq0, negedge D[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0, posedge D[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN50eq0aGWENeq0, negedge D[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0, posedge D[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN49eq0aGWENeq0, negedge D[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0, posedge D[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN48eq0aGWENeq0, negedge D[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0, posedge D[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN47eq0aGWENeq0, negedge D[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0, posedge D[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN46eq0aGWENeq0, negedge D[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0, posedge D[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN45eq0aGWENeq0, negedge D[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0, posedge D[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN44eq0aGWENeq0, negedge D[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0, posedge D[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN43eq0aGWENeq0, negedge D[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0, posedge D[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN42eq0aGWENeq0, negedge D[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0, posedge D[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN41eq0aGWENeq0, negedge D[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0, posedge D[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN40eq0aGWENeq0, negedge D[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0, posedge D[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN39eq0aGWENeq0, negedge D[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0, posedge D[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN38eq0aGWENeq0, negedge D[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0, posedge D[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN37eq0aGWENeq0, negedge D[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0, posedge D[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN36eq0aGWENeq0, negedge D[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0, posedge D[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN35eq0aGWENeq0, negedge D[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0, posedge D[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN34eq0aGWENeq0, negedge D[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0, posedge D[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN33eq0aGWENeq0, negedge D[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0, posedge D[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN32eq0aGWENeq0, negedge D[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0, posedge D[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN31eq0aGWENeq0, negedge D[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0, posedge D[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN30eq0aGWENeq0, negedge D[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0, posedge D[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN29eq0aGWENeq0, negedge D[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0, posedge D[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN28eq0aGWENeq0, negedge D[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0, posedge D[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN27eq0aGWENeq0, negedge D[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0, posedge D[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN26eq0aGWENeq0, negedge D[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0, posedge D[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN25eq0aGWENeq0, negedge D[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0, posedge D[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN24eq0aGWENeq0, negedge D[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0, posedge D[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN23eq0aGWENeq0, negedge D[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0, posedge D[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN22eq0aGWENeq0, negedge D[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0, posedge D[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN21eq0aGWENeq0, negedge D[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0, posedge D[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN20eq0aGWENeq0, negedge D[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0, posedge D[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN19eq0aGWENeq0, negedge D[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0, posedge D[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN18eq0aGWENeq0, negedge D[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0, posedge D[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN17eq0aGWENeq0, negedge D[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0, posedge D[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN16eq0aGWENeq0, negedge D[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0, posedge D[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN15eq0aGWENeq0, negedge D[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0, posedge D[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN14eq0aGWENeq0, negedge D[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0, posedge D[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN13eq0aGWENeq0, negedge D[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0, posedge D[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN12eq0aGWENeq0, negedge D[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0, posedge D[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN11eq0aGWENeq0, negedge D[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0, posedge D[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN10eq0aGWENeq0, negedge D[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0, posedge D[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN9eq0aGWENeq0, negedge D[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0, posedge D[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN8eq0aGWENeq0, negedge D[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0, posedge D[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN7eq0aGWENeq0, negedge D[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0, posedge D[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN6eq0aGWENeq0, negedge D[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0, posedge D[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN5eq0aGWENeq0, negedge D[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0, posedge D[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN4eq0aGWENeq0, negedge D[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0, posedge D[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN3eq0aGWENeq0, negedge D[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0, posedge D[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN2eq0aGWENeq0, negedge D[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0, posedge D[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN1eq0aGWENeq0, negedge D[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0, posedge D[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aCENeq0aWEN0eq0aGWENeq0, negedge D[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_D0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMAW[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, posedge EMAW[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMAW[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0aDFTRAMBYPeq0oTENeq0aTCENeq0aDFTRAMBYPeq0oDFTRAMBYPeq1, negedge EMAW[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_EMAW0);
    $setuphold(posedge CLK &&& RET1Neq1, posedge TEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TEN);
    $setuphold(posedge CLK &&& RET1Neq1, negedge TEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0, posedge TCEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TCEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0, negedge TCEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TCEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TWEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TWEN[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TWEN0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TA[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TA0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0, posedge TD[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN63eq0aTGWENeq0, negedge TD[63], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD63);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0, posedge TD[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN62eq0aTGWENeq0, negedge TD[62], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD62);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0, posedge TD[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN61eq0aTGWENeq0, negedge TD[61], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD61);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0, posedge TD[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN60eq0aTGWENeq0, negedge TD[60], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD60);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0, posedge TD[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN59eq0aTGWENeq0, negedge TD[59], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD59);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0, posedge TD[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN58eq0aTGWENeq0, negedge TD[58], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD58);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0, posedge TD[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN57eq0aTGWENeq0, negedge TD[57], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD57);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0, posedge TD[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN56eq0aTGWENeq0, negedge TD[56], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD56);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0, posedge TD[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN55eq0aTGWENeq0, negedge TD[55], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD55);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0, posedge TD[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN54eq0aTGWENeq0, negedge TD[54], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD54);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0, posedge TD[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN53eq0aTGWENeq0, negedge TD[53], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD53);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0, posedge TD[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN52eq0aTGWENeq0, negedge TD[52], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD52);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0, posedge TD[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN51eq0aTGWENeq0, negedge TD[51], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD51);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0, posedge TD[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN50eq0aTGWENeq0, negedge TD[50], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD50);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0, posedge TD[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN49eq0aTGWENeq0, negedge TD[49], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD49);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0, posedge TD[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN48eq0aTGWENeq0, negedge TD[48], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD48);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0, posedge TD[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN47eq0aTGWENeq0, negedge TD[47], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD47);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0, posedge TD[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN46eq0aTGWENeq0, negedge TD[46], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD46);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0, posedge TD[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN45eq0aTGWENeq0, negedge TD[45], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD45);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0, posedge TD[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN44eq0aTGWENeq0, negedge TD[44], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD44);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0, posedge TD[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN43eq0aTGWENeq0, negedge TD[43], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD43);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0, posedge TD[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN42eq0aTGWENeq0, negedge TD[42], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD42);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0, posedge TD[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN41eq0aTGWENeq0, negedge TD[41], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD41);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0, posedge TD[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN40eq0aTGWENeq0, negedge TD[40], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD40);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0, posedge TD[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN39eq0aTGWENeq0, negedge TD[39], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD39);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0, posedge TD[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN38eq0aTGWENeq0, negedge TD[38], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD38);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0, posedge TD[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN37eq0aTGWENeq0, negedge TD[37], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD37);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0, posedge TD[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN36eq0aTGWENeq0, negedge TD[36], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD36);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0, posedge TD[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN35eq0aTGWENeq0, negedge TD[35], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD35);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0, posedge TD[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN34eq0aTGWENeq0, negedge TD[34], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD34);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0, posedge TD[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN33eq0aTGWENeq0, negedge TD[33], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD33);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0, posedge TD[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN32eq0aTGWENeq0, negedge TD[32], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD32);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0, posedge TD[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN31eq0aTGWENeq0, negedge TD[31], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD31);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0, posedge TD[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN30eq0aTGWENeq0, negedge TD[30], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD30);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0, posedge TD[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN29eq0aTGWENeq0, negedge TD[29], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD29);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0, posedge TD[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN28eq0aTGWENeq0, negedge TD[28], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD28);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0, posedge TD[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN27eq0aTGWENeq0, negedge TD[27], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD27);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0, posedge TD[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN26eq0aTGWENeq0, negedge TD[26], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD26);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0, posedge TD[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN25eq0aTGWENeq0, negedge TD[25], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD25);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0, posedge TD[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN24eq0aTGWENeq0, negedge TD[24], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD24);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0, posedge TD[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN23eq0aTGWENeq0, negedge TD[23], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD23);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0, posedge TD[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN22eq0aTGWENeq0, negedge TD[22], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD22);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0, posedge TD[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN21eq0aTGWENeq0, negedge TD[21], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD21);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0, posedge TD[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN20eq0aTGWENeq0, negedge TD[20], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD20);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0, posedge TD[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN19eq0aTGWENeq0, negedge TD[19], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD19);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0, posedge TD[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN18eq0aTGWENeq0, negedge TD[18], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD18);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0, posedge TD[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN17eq0aTGWENeq0, negedge TD[17], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD17);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0, posedge TD[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN16eq0aTGWENeq0, negedge TD[16], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD16);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0, posedge TD[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN15eq0aTGWENeq0, negedge TD[15], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD15);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0, posedge TD[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN14eq0aTGWENeq0, negedge TD[14], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD14);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0, posedge TD[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN13eq0aTGWENeq0, negedge TD[13], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD13);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0, posedge TD[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN12eq0aTGWENeq0, negedge TD[12], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD12);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0, posedge TD[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN11eq0aTGWENeq0, negedge TD[11], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD11);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0, posedge TD[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN10eq0aTGWENeq0, negedge TD[10], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD10);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0, posedge TD[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN9eq0aTGWENeq0, negedge TD[9], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD9);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0, posedge TD[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN8eq0aTGWENeq0, negedge TD[8], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD8);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0, posedge TD[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN7eq0aTGWENeq0, negedge TD[7], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD7);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0, posedge TD[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN6eq0aTGWENeq0, negedge TD[6], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD6);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0, posedge TD[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN5eq0aTGWENeq0, negedge TD[5], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD5);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0, posedge TD[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN4eq0aTGWENeq0, negedge TD[4], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD4);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0, posedge TD[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN3eq0aTGWENeq0, negedge TD[3], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD3);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0, posedge TD[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN2eq0aTGWENeq0, negedge TD[2], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD2);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0, posedge TD[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN1eq0aTGWENeq0, negedge TD[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD1);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0, posedge TD[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aDFTRAMBYPeq1aSEeq0oDFTRAMBYPeq0aTCENeq0aTWEN0eq0aTGWENeq0, negedge TD[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TD0);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, posedge GWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_GWEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq1aCENeq0, negedge GWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_GWEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, posedge TGWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TGWEN);
    $setuphold(posedge CLK &&& RET1Neq1aTENeq0aTCENeq0, negedge TGWEN, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_TGWEN);
    $setuphold(posedge CLK, posedge RET1N, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CLK, negedge RET1N, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, posedge SI[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI1);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, posedge SI[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI0);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, negedge SI[1], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI1);
    $setuphold(posedge CLK &&& RET1Neq1aSEeq1, negedge SI[0], `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SI0);
    $setuphold(posedge CLK &&& RET1Neq1, posedge SE, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SE);
    $setuphold(posedge CLK &&& RET1Neq1, negedge SE, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_SE);
    $setuphold(posedge CLK &&& RET1Neq1, posedge DFTRAMBYP, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_DFTRAMBYP);
    $setuphold(posedge CLK &&& RET1Neq1, negedge DFTRAMBYP, `ARM_MEM_SETUP, `ARM_MEM_HOLD, NOT_DFTRAMBYP);
    $setuphold(negedge RET1N, negedge CEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge RET1N, negedge CEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge RET1N, negedge TCEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge RET1N, negedge TCEN, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge DFTRAMBYP, posedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge DFTRAMBYP, negedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CEN, negedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge CEN, posedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge TCEN, negedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge TCEN, posedge RET1N, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(negedge RET1N, posedge DFTRAMBYP, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
    $setuphold(posedge RET1N, posedge DFTRAMBYP, 0.000, `ARM_MEM_HOLD, NOT_RET1N);
  endspecify


endmodule
`endcelldefine
  `endif
`endif
`timescale 1ns/1ps
module ARM_SPSRAM_64X4096_M8_MEM_error_injection (Q_out, Q_in, CLK, A, CEN, DFTRAMBYP, SE, WEN, GWEN);
   output [63:0] Q_out;
   input [63:0] Q_in;
   input CLK;
   input [11:0] A;
   input CEN;
   input DFTRAMBYP;
   input SE;
   input [63:0] WEN;
   input GWEN;
   parameter LEFT_RED_COLUMN_FAULT = 2'd1;
   parameter RIGHT_RED_COLUMN_FAULT = 2'd2;
   parameter NO_RED_FAULT = 2'd0;
   reg [63:0] Q_out;
   reg entry_found;
   reg list_complete;
   reg [22:0] fault_table [511:0];
   reg [22:0] fault_entry;
initial
begin
   `ifdef DUT
      `define pre_pend_path TB.DUT_inst.CHIP
   `else
       `define pre_pend_path TB.CHIP
   `endif
   `ifdef ARM_NONREPAIRABLE_FAULT
      `pre_pend_path.SMARCHCHKBVCD_LVISION_MBISTPG_ASSEMBLY_UNDER_TEST_INST.MEM0_MEM_INST.u1.add_fault(12'd3718,6'd6,2'd1,2'd0);
   `endif
end
   task add_fault;
   //This task injects fault in memory
      input [11:0] address;
      input [5:0] bitPlace;
      input [1:0] fault_type;
      input [1:0] red_fault;
 
      integer i;
      reg done;
   begin
      done = 1'b0;
      i = 0;
      while ((!done) && i < 511)
      begin
         fault_entry = fault_table[i];
         if (fault_entry[0] === 1'b0 || fault_entry[0] === 1'bx)
         begin
            fault_entry[0] = 1'b1;
            fault_entry[2:1] = red_fault;
            fault_entry[4:3] = fault_type;
            fault_entry[10:5] = bitPlace;
            fault_entry[22:11] = address;
            fault_table[i] = fault_entry;
            done = 1'b1;
         end
         i = i+1;
      end
   end
   endtask
//This task removes all fault entries injected by user
task remove_all_faults;
   integer i;
begin
   for (i = 0; i < 512; i=i+1)
   begin
      fault_entry = fault_table[i];
      fault_entry[0] = 1'b0;
      fault_table[i] = fault_entry;
   end
end
endtask
task bit_error;
// This task is used to inject error in memory and should be called
// only from current module.
//
// This task injects error depending upon fault type to particular bit
// of the output
   inout [63:0] q_int;
   input [1:0] fault_type;
   input [5:0] bitLoc;
begin
   if (fault_type === 2'd0)
      q_int[bitLoc] = 1'b0;
   else if (fault_type === 2'd1)
      q_int[bitLoc] = 1'b1;
   else
      q_int[bitLoc] = ~q_int[bitLoc];
end
endtask
task error_injection_on_output;
// This function goes through error injection table for every
// read cycle and corrupts Q output if fault for the particular
// address is present in fault table
//
// If fault is redundant column is detected, this task corrupts
// Q output in read cycle
//
// If fault is repaired using repair bus, this task does not
// courrpt Q output in read cycle
//
   output [63:0] Q_output;
   reg list_complete;
   integer i;
   reg [8:0] row_address;
   reg [2:0] column_address;
   reg [5:0] bitPlace;
   reg [1:0] fault_type;
   reg [1:0] red_fault;
   reg valid;
   reg [4:0] msb_bit_calc;
begin
   entry_found = 1'b0;
   list_complete = 1'b0;
   i = 0;
   Q_output = Q_in;
   while(!list_complete)
   begin
      fault_entry = fault_table[i];
      {row_address, column_address, bitPlace, fault_type, red_fault, valid} = fault_entry;
      i = i + 1;
      if (valid == 1'b1)
      begin
         if (red_fault === NO_RED_FAULT)
         begin
            if (row_address == A[11:3] && column_address == A[2:0])
            begin
               if (bitPlace < 32)
                  bit_error(Q_output,fault_type, bitPlace);
               else if (bitPlace >= 32 )
                  bit_error(Q_output,fault_type, bitPlace);
            end
         end
      end
      else
         list_complete = 1'b1;
      end
   end
   endtask
   always @ (Q_in or CLK or A or CEN or WEN or GWEN)
   begin
   if (CEN === 1'b0 && DFTRAMBYP === 1'b0 && SE === 1'b0)
      error_injection_on_output(Q_out);
   else
      Q_out = Q_in;
   end
endmodule
