
// Description: FIFO Envelope
//              Instantiation of a generic fifo of dual clock domain
//              connects to a compiled memory of type 1r1w - CRF2PA32D32CM1BK1

module generic_fifo_env_a16d36_rf(clk,
                                  reset_n,
                                  wr_op,
                                  wr_data,
                                  full,
                                  empty,
                                  entry_used,
                                  wr_full_err,
                                  rd_op,
                                  rd_data,
                                  rd_empty_err,
                                  sreset_n,
                                  );

   parameter PTR_WIDTH = 4;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 16; // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 36;       // data bus width of the fifo

   input  clk;
   input  reset_n;
   input  wr_op;
   input  [DAT_WIDTH - 1:0] wr_data;
   output 		    full;
   output empty;
   output [PTR_WIDTH :0] entry_used;
   output wr_full_err;
   input  rd_op;
   output [DAT_WIDTH - 1:0] rd_data;
   output rd_empty_err;
   input  sreset_n;
  

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
   .clr(1'b0));
// .two_power_n(two_power_n));

 generic_2p_rf #(.MEM_SIZE(NUM_OF_ENTRIES), .AW((PTR_WIDTH)), .DW(DAT_WIDTH))  I_generic_2p_rf(
   // Wr Ports
   .wr_addr   (wr_addr),
   .wr_data   (wr_data),
   .wr_me_en  (wr_op),
   .wr_clk    (clk),
   // Rd Ports
   .rd_data   (rd_data),
   .rd_addr   (rd_addr),
   .rd_me_en  (rd_op),
   .rd_clk    (clk)

   );


endmodule


