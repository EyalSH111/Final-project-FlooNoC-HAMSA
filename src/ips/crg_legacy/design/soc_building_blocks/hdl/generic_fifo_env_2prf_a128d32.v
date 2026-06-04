
// Description: FIFO Envelope for a 2prf based memory block
// connects control logic - FIFO pointers and status indicators and the 
// relevant memory block

module generic_fifo_env_2prf_a128d32(clk,
                                  reset_n,
                                  clr,
                                  wr_op,
                                  wr_data,
                                  full,
                                  empty,
                                  entry_used,
                                  wr_full_err,
                                  rd_op,
                                  rd_data,
                                  rd_empty_err,
                                  ram_ctrl
                                  );

   parameter NUM_OF_ENTRIES = 128; // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 32;       // data bus width of the fifo
   parameter PTR_WIDTH = $clog2(NUM_OF_ENTRIES);        // address bus width of the fifo

   input  clk;
   input  reset_n;
   input  clr;
   input  wr_op;
   input  [DAT_WIDTH - 1:0] wr_data;
   output 		    full;
   output empty;
   output [PTR_WIDTH :0] entry_used;
   output wr_full_err;
   input  rd_op;
   output [DAT_WIDTH - 1:0] rd_data;
   output rd_empty_err;
   input [5:0] ram_ctrl;
  

   wire [PTR_WIDTH - 1:0] wr_addr;
   wire [DAT_WIDTH - 1:0] wr_data;
   wire [PTR_WIDTH :0] 	  entry_used;
   
   wire [PTR_WIDTH - 1:0] rd_addr;
   wire [DAT_WIDTH - 1:0] rd_data;
   
   wire [3:0] rm;
   wire en;
   wire [PTR_WIDTH - 1:0] addr;

generic_fifo_crgn #(PTR_WIDTH, NUM_OF_ENTRIES) Igeneric_fifo (
   .clk(clk),
   .reset_n(reset_n),
   .rd_op(rd_op),
   .rd_addr(rd_addr),
   .wr_op(wr_op),
   .wr_addr(wr_addr),
   .full(full),
   .empty(empty),
   .entry_used(entry_used),
   .err_rdempty(rd_empty_err),
   .err_wrfull(wr_full_err),
   .clr(clr));

twop_rf128x32_i I_twop_rf128x32_i (
    .clk(clk),
    .we_i(wr_op),
    .wr_addr_i(wr_addr),
    .wdata_i(wr_data),
    .re_i(rd_op),
    .rd_addr_i(rd_addr),
    .ram_rdata_o(rd_data),
    .ram_ctrl(ram_ctrl[5:0])
);

endmodule


