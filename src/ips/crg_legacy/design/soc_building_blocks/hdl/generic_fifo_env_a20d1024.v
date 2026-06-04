
// Description: FIFO Envelope
//              Instantiation of a generic fifo of dual clock domain
//              connects to a compiled memory of type 1r1w - CRF2PA1024D20CM4C2LBW

module generic_fifo_env_a20d1024_ram(clk,
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

   parameter PTR_WIDTH = 10;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 1024; // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 20;       // data bus width of the fifo


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
   .clr(1'b0));
// .two_power_n(two_power_n));

CRF2PA1024D20CM4C2LBW 
   #(.RAM_CTRL_VEC_SIZE(7)) 
   Igeneric_2clk_fifo_mem_wrap(
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
   .scan_mode (scan_mode),
   .sreset_n  (sreset_n),
   // control
   .rambist_mode  (),
   .ram_ctrl_vec  (ram_ctrl_vec[6:0])
   );

endmodule


