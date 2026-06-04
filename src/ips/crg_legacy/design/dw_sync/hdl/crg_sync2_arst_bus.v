//                              Copyright (C) 2015-2018 by EnICS Labs

//                          01
//                        01 10
//                       1 10 010101010              1010     0101010    1010101
//                       1 10         0              1  0    10     0   0      1
//                       1   1010101010              1  0   01  01010  1   10101
//                        010                        1  0   0  10      1  0
//                      01  01            01010101   1  0  1  01       1  01
//                     10 01 1010101010  10       0  1  0  1  0        10  10
//                     1  01          0  1   10   0  1  0  1  0         0    1
//                     10   01010101010  1  01 1  0  1  0  1  0          10   0
//                      01010            1  0  1  0  1  0  1  0           01   1
//                      0101             1  0  1  0  1  0  1  01           10  1
//                     1    0            1  0  1  0  1  0   0  10           0  1
//                    0  10 01010101010  1  0  1  0  1  0   01  01010  10101   1
//                    0 0 0           0  1  0  1  0  1  0    10     0  1      01
//                    0 01  01010101010  1010  1010  1010     0101010  10101010
//                    0    1
//                     1010
//                               ------<< System-on-Chip Lab >>-------
//
//           This module is confidential and proprietary property of EnICS Labs and the possession or use
//                          of this file requires a written license from EnICS Labs.


// Title          : Array of 2DFF synchronizers
// Project        : negev
// Created by     : Yonatan Shoshan (yonatan.shoshan@biu.ac.il)
// Created        : December 17 2018 at 14:42:46
// Description    : 
// ----------------------------------------------------------------------------------------------------------- 



module crg_sync2_arst_bus (//Output
                 datasync_r,
                 //Input
                 datain,clk,areset);

   /****************************** parameters ******************************/

   parameter WIDTH = 16;

   /****************************************** OUTPUTS **********************************/

   output [WIDTH-1:0] datasync_r; //The output signal, synchronize to the new clock domain

   /******************************************  INPUTS **********************************/

   input [WIDTH-1:0]  datain ;   //The input signal to the synchronizer
   input              clk;       //The clock to be synchronize to
   input              areset;    //ASync RESET signal

   /************************************** Wire DECLARATIONS ****************************/

   //No wire in that design
   //wire   [WIDTH-1:0] datasync_r;

   /*************************************** Reg DECLARATIONS ****************************/

   // reg [WIDTH-1:0]    sample_r;    //The first stage in synchronization
   // reg [WIDTH-1:0]    datasync_r;  //The second stage in synchronization

   /*************************************************************************************/
   /*
   ----areset-------+---------------------+
                    +                     +
                 +--o--+               +--o--+
                 +     +               +     +
   ----datain--->+ FF1 +---sample_r--->+ FF2 +---datasync_r--->
                 +     +               +     +
                 +--^--+               +--^--+
                    |                     |
                    |                     |
                   clk                   clk
                                                                                         */
    /*************************************************************************************/

   // ----------------------------------------------------------------------------------------------------- //
   // Original CEVA's RTL model                                                                             //
   // ----------------------------------------------------------------------------------------------------- //

   // // First sample
   // always @(posedge clk or negedge areset)
   //   if (~areset)
   //     sample_r <= {WIDTH{1'b0}};
   //   else
   //     sample_r <= datain;

   // // Second sample
   // always @(posedge clk or negedge areset)
   //   if (~areset)
   //     datasync_r <= {WIDTH{1'b0}};
   //   else
   //     datasync_r <= sample_r;

   // ----------------------------------------------------------------------------------------------------- //
   // Equivalent mapping to Ceragon DW cells                                                                //
   // ----------------------------------------------------------------------------------------------------- //

   //assign datasync_r[WIDTH-1:0] = datasync_w[WIDTH-1:0];

   genvar gi;

   generate
      for (gi=0; gi<WIDTH; gi=gi+1) begin : gen_sync_bit
         crg_sync2_arst I_gen_sync2 (
                                     // Outputs
                                     .q     (datasync_r[gi]),
                                     // Inputs
                                     .clr_n (areset),
                                     .d     (datain[gi]),
                                     .clk   (clk));
      end
   endgenerate

endmodule // gsync_ar
