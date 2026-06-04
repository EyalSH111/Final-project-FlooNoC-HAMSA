/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////                                                                 ////
////  generic_2port_reg_ram.v                                        ////
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

// this block is a generic 2 port RAM based on FFs


module generic_2port_reg_ram (
                        clk,
                        sreset_n,
                        cs_n,
                        wr,
                        rd_addr,
                        wr_addr,
                        data_in,
                        data_out
                        );

  // ADDITINAL FUNCTIONS
  // ===================
  `include "jupiter_functions.v"

parameter DW = 16;
parameter DEPTH = 8;
parameter LOG_DEPTH = clog2(DEPTH);

input sreset_n;
input clk;
input wr;
input cs_n;
input [DW-1:0] data_in;
input [LOG_DEPTH-1:0] rd_addr;
input [LOG_DEPTH-1:0] wr_addr;
output [DW-1:0] data_out;

reg [0:DEPTH-1][DW-1:0] mem;
wire [DW-1:0] data_out;

integer i;

//Parameter checking
//cadence translate_off
initial begin

 if (DW < 1 || DW > 256) $display("ERROR - Bad parameter, DW=%0d, which not in the legal range of 1 to 256.", DW);
 if (DEPTH < 2 || DEPTH > 256) $display("ERROR - Bad parameter, DEPTH=%0d, which not in the legal range of 2 to 256.", DEPTH);

end
//cadence translate_on


assign data_out[DW-1:0] = (rd_addr > DEPTH - 1) ? {DW{1'b0}} : mem[rd_addr]; // Udi changed {DW{1'bX}} to  {DW{1'b0}} 28/04/11 

always @(posedge clk)
  if(~sreset_n)
     // Reset all memory to zero
    for(i = 0 ; i < DEPTH ; i = i+1)
      mem[i] <= {DW{1'b0}};
  else
    //Note: In Sim model x's are written to Ram for an invalid input to wr (ie. not = 0 or 1)
    if(wr == 1'b1 && cs_n == 1'b0)
      mem[wr_addr] <= data_in[DW-1:0];
//  else if(~(wr == 1'b0 || wr == 1'b1))    // Udi removed 28/04/11   
//    mem[wr_addr] <= {DW{1'bx}};




//Testing for invalid inputs.
//cadence translate_off
always @(sreset_n or cs_n or wr or rd_addr or wr_addr)
begin
if (~(sreset_n == 1'b0 || sreset_n == 1'b1))
  $display("Invalid input sreset_n = %b", sreset_n);

if(~(cs_n == 1'b0 || cs_n == 1'b1))
  $display("Invalid input cs_n = %b", cs_n);

if(~(wr == 1'b0 || wr == 1'b1))
  $display("Invalid input wr = %b", wr);

if(~(^rd_addr == 1'b0 || ^rd_addr == 1'b1))
  $display("Invalid input rd_addr = %h", rd_addr);

if(~(^wr_addr == 1'b0 || ^wr_addr == 1'b1))
  $display("Invalid input wr_addr = %h", wr_addr);

if(wr_addr > DEPTH - 1)
  $display("Write address not within Ram Range = %h", wr_addr);

if(rd_addr > DEPTH - 1)
  $display("Read address not within Ram Range = %h", rd_addr);

end
//cadence translate_on

endmodule // generic_2port_reg_ram



