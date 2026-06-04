// Description: FIFO Envelope
//              Instantiation of a generic fifo of dual clock domain
//              connects to a compiled memory of type 1r1w - CRF2PA32D32CM1BK1

module generic_fifo_env_a256d35_ram(clk,
                                  reset_n,
                                  wr_op,
                                  wr_data,
                                  wr_mask,
                                  full,
                                  empty,
                                  entry_used,
                                  wr_full_err,
                                  rd_op,
                                  rd_data,
                                  rd_empty_err,
                                  scan_mode,
                                  sreset_n,
                                  ram_ctrl_vec
                                  );

   parameter PTR_WIDTH = 8;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 256; // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 35;       // data bus width of the fifo
   parameter RAM_CTRL_VEC_SIZE = 7 ;

   input  clk;
   input  reset_n;
   input  wr_op;
   input  [DAT_WIDTH - 1:0] wr_data;
   input  [DAT_WIDTH - 1:0] wr_mask;
   output full;
   output empty;
   output [PTR_WIDTH :0] entry_used;
   output wr_full_err;
   input  rd_op;
   output [DAT_WIDTH - 1:0] rd_data;
   output rd_empty_err;
   input  scan_mode;
   input  sreset_n;
   input  [6:0] ram_ctrl_vec;

   wire [PTR_WIDTH - 1:0] wr_addr;
   wire [DAT_WIDTH - 1:0] wr_data;
   wire [DAT_WIDTH - 1:0] wr_mask;
   wire [PTR_WIDTH :0] entry_used;

   wire [PTR_WIDTH - 1:0] rd_addr;
   wire [DAT_WIDTH - 1:0] rd_data;


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
   .clr(1'b0));

   CRF2PA256D35CM4 Icrg_2clk_fifo_mem_wrap (
   // Wr Ports
   .wr_addr   (wr_addr),
   .wr_data   (wr_data),
   .wr_mask   (wr_mask),
   .wr_me_en  (wr_op),
   .wr_clk    (clk),
   // Rd Ports
   .rd_data   (rd_data),
   .rd_addr   (rd_addr),
   .rd_me_en  (rd_op),
   .rd_clk    (clk),

   // System
   .scan_mode(1'b0),
   .rambist_mode(1'b0),
   .sreset_n(1'b1),
   // Debug

   // ram ctrl b
   .ram_ctrl_vec (ram_ctrl_vec)
   );

endmodule
