/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////                                                                 ////
////  intc.v                                                         ////
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
////  Created:        23.02.10                                       ////
////  Last Updated:   23.02.10                                       ////
////                                                                 ////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////


// This module implements an interrupt controller. It's purpose is to latch the various strobe-interrupts that go to the uc to a constant '1' until
// the uc can read them. Once read, the uc should update the clear_data input that tells the block which latches to reset, and then send a pulse
// in the clear_p input that will perform the reset.
// The enable_strbs can, if not (all '1'), tell the block to mask some of the interrupts

//`timescale 1ns/10ps

module intc (
             // Inputs
             // Clock & Reset
             sreset_n,           // [I] intc sync reset - Active low
             clk,                // [I] intc input Clock

             // from HW
             strbs_in_p, // [I] [DW-1:0] intc strbs_in_p - the interrupts from HW that we latch and send to SW. active high
                         //     We assume that all the interrupts are strobes (i.e they rise only for 1 clock)

             // from SW
             clear_data_p, // [I] [DW-1:0] intc clear_data_p - tells the block which to clear latches - Active high
             enable_strbs, // [I] [DW-1:0] intc enable_strbs - tells the block which strobes should be masked (to SW) - Active high

             // Outputs
             // to SW
             data_out,                        // [O] [DW-1:0] intc latched interrupts to SW - masked, Active high
             data_out_unmasked,               // [O] [DW-1:0] intc latched interrupts to SW - unmasked, Active high
             any_data_out,                    // [O] intc any_data_out the OR of all bits in data_out
             any_data_out_unmasked            // [O] intc any_data_out_unmasked the OR of all bits in data_out_unmasked
             );


   ///////////////////////////////////////////////////////////////////

  parameter DW = 8;  // interrupt bus width - i.e number of interrupts
  // Clock & Reset
  input           sreset_n;
  input           clk;

  // from HW
  input [DW-1:0]  strbs_in_p;

  // from SW
  input [DW-1:0]  clear_data_p;
  input [DW-1:0]  enable_strbs;

  // Outputs
  // to SW
  output [DW-1:0] data_out_unmasked;
  output [DW-1:0] data_out;
  output          any_data_out;
  output          any_data_out_unmasked;

  reg    [DW-1:0]  data_out_unmasked;

  //comb_regs
  reg    [DW-1:0]  data_out;              //wired
  reg              any_data_out;          //wired
  reg              any_data_out_unmasked; //wired


  ///////////////////////////////////////////////////////////////////


  always @(posedge clk)
    if (~sreset_n)
      data_out_unmasked[DW-1:0] <= {DW{1'b0}};   // reset all latched interrupts
    else // if SW wants to clear the interrupts: we leave
      // only the interrupts that the SW DOESN'T want to clear on, while remembering to monitor the incoming interrupts
      data_out_unmasked[DW-1:0] <= (data_out_unmasked[DW-1:0] & (~clear_data_p[DW-1:0])) | strbs_in_p[DW-1:0];

  always @(*) begin
    //the masked interrupts are handled the same as the unmasked - but are AND-ed with enable_strbs
    data_out[DW-1:0] = data_out_unmasked[DW-1:0] & enable_strbs[DW-1:0];
    any_data_out = |(data_out);                   // any_data_out is the OR of all the data_out bits
    any_data_out_unmasked = |(data_out_unmasked); // any_data_out_unmasked is the OR of all the data_out bits
  end

   ///////////////////////////////////////////////////////////////////


endmodule // intc
