//
//                        Copyright (C) 2015-2020 by EnICS Labs
//                         01
//                       01 10
//                      1 10 010101010              1010     0101010    1010101
//                      1 10         0              1  0    10     0   0      1
//                      1   1010101010              1  0   01  01010  1   10101
//                       010                        1  0   0  10      1  0
//                     01  01            01010101   1  0  1  01       1  01
//                    10 01 1010101010  10       0  1  0  1  0        10  10
//                    1  01          0  1   10   0  1  0  1  0         0    1
//                    10   01010101010  1  01 1  0  1  0  1  0          10   0
//                     01010            1  0  1  0  1  0  1  0           01   1
//                     0101             1  0  1  0  1  0  1  01           10  1
//                    1    0            1  0  1  0  1  0   0  10           0  1
//                   0  10 01010101010  1  0  1  0  1  0   01  01010  10101   1
//                   0 0 0           0  1  0  1  0  1  0    10     0  1      01
//                   0 01  01010101010  1010  1010  1010     0101010  10101010
//                   0    1
//                    1010
//                            ------<< System-on-Chip Lab >>-------
//
// This module is confidential and proprietary property of EnICS Labs and the possession or use
// of this file requires a written license from EnICS Labs.
//
//
// Note: This header template is automatically generated with EMACS template defined in:
//    (1) ~$USER/.emacs.d/handy_functions.el
//    (2) ~$USER/.emacs.d/init.el
// -------------------------------------------------------------------------------------------------------- //
//
// Category    : Design (Verilog)
// Title       : [FILL ME]
// Project     : Leo_I
// Filename    : arm_modular_128x4096_sram.sv
// Author      : Slava Yuzhaninov (Slava.Yuzhaninov@biu.ac.il)
// Created     : Mon Mar 16 23:28:41 2020 (+0200)
// Last-Updated: Sat Mar 28 23:47:42 2020 (+0300)
//           By: Slava Yuzhaninov
//     Update #: 18
//
// Description : [FILL ME]
//
// -------------------------------------------------------------------------------------------------------- //

`define SPRAM_COMMON_INPUT_PORTS .CLK       (CLK),         \
                                 .CEN       (CEN),         \
                                 .GWEN      (GWEN),        \
                                 .A         (A),           \
                                 .EMA       (3'b010),      \
                                 .EMAW      (2'b00),       \
                                 .RET1N     (1'b1)


module arm_modular_128x4096_sram_hd (
                                  output [127:0] Q,
                                  input          CLK,
                                  input          CEN,
                                  input [127:0]  WEN,
                                  input          GWEN,
                                  input [11:0]   A,
                                  input [127:0]  D,
			                      input [2:0]    EMA,
 				                  input [1:0]    EMAW,
 				                  input          TEN,
 				                  input          TCEN,
 				                  input [127:0]  TWEN,
 				                  input [11:0]   TA,
 				                  input [127:0]  TD,
		                          input          TGWEN,
  				                  input          RET1N,
  				                  input [1:0]    SI,
 				                  input          SE,
 			                      input          DFTRAMBYP,
                                  output         CENY,
                                  output [127:0] WENY,
                                  output         GWENY,               
                                  output [11:0]  AY,
                                  output [1:0]   SO                                
                                  );

   // High density memories:

   ARM_SPSRAM_64X4096_M8_MEM i_mem_lo (
                                       .Q         (Q[63:0]),
                                       .WEN       (WEN[63:0]),
                                       .D         (D[63:0]),
                                       .CENY      (),
                                       .WENY      (),
                                       .GWENY     (),
                                       .AY        (),
                                       .SO        (),
                                       .TEN       (1'b1),
                                       .TCEN      (1'b0),
                                       .TWEN      (64'b0),
                                       .TGWEN     (1'b0),
                                       .TA        (12'b0),
                                       .TD        (64'b0),
                                       .SI        (2'b00),
                                       .SE        (1'b0),
                                       .DFTRAMBYP (1'b0),
                                       `SPRAM_COMMON_INPUT_PORTS
                                       );

   ARM_SPSRAM_64X4096_M8_MEM i_mem_hi (
                                       .Q         (Q[127:64]),
                                       .WEN       (WEN[127:64]),
                                       .D         (D[127:64]),
                                       .CENY      (),
                                       .WENY      (),
                                       .GWENY     (),
                                       .AY        (),
                                       .SO        (),
                                       .TEN       (1'b1),
                                       .TCEN      (1'b0),
                                       .TWEN      (64'b0),
                                       .TGWEN     (1'b0),
                                       .TA        (12'b0),
                                       .TD        (64'b0),
                                       .SI        (2'b00),
                                       .SE        (1'b0),
                                       .DFTRAMBYP (1'b0),
                                       `SPRAM_COMMON_INPUT_PORTS
                                       );


endmodule
