
module generic_2clk_fifo_env_a16d20_rf (/*autoarg*/
   // Outputs
   wr_full, wr_empty, wr_entry_used, wr_full_err, rd_data, rd_full,
   rd_empty, rd_entry_used, rd_empty_err, wr_reset_out_n,
   // Inputs
   wr_clk, wr_op, scan_mode, wr_data, rd_clk, rd_reset_n, rd_op
   );


   parameter PTR_WIDTH = 4;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 16; // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 20;       // data bus width of the fifo
   
   input  wr_clk;
   input  wr_op;
   input  scan_mode;
   
   input  [DAT_WIDTH - 1:0] wr_data;
   output wr_full;
   output wr_empty;
   output [PTR_WIDTH :0] wr_entry_used;
   output wr_full_err;
   input  rd_clk;
   input  rd_reset_n;
   input  rd_op;
   output [DAT_WIDTH - 1:0] rd_data;
   output rd_full;
   output rd_empty;
   output [PTR_WIDTH :0] rd_entry_used;
   output rd_empty_err;
   output wr_reset_out_n;
  

   wire [PTR_WIDTH - 1:0] wr_addr;
   wire [DAT_WIDTH - 1:0] wr_data;
   wire [PTR_WIDTH :0] wr_entry_used;
   
   wire [PTR_WIDTH - 1:0] rd_addr;
   wire [DAT_WIDTH - 1:0] rd_data;
   wire [PTR_WIDTH :0] rd_entry_used;
   

   generic_2clk_fifo #(PTR_WIDTH, NUM_OF_ENTRIES) Igeneric_2clk_fifo (
   .scan_mode (scan_mode),
   // Port a: Rd
   .clka(rd_clk),
   .reseta_n(rd_reset_n),
   .rd_op(rd_op),
   .rd_addr(rd_addr),
   .fulla(rd_full),
   .emptya(rd_empty),
   .entry_useda(rd_entry_used),
   .err_rdemptya(rd_empty_err),
   // Port b: Wr
   .clkb(wr_clk),
   .resetb_out_n(wr_reset_out_n),
   .wr_op(wr_op),
   .wr_addr(wr_addr),
   .fullb(wr_full),
   .emptyb(wr_empty),
   .entry_usedb(wr_entry_used),
   .err_wrfullb(wr_full_err));


  
   


   generic_2p_rf #(.MEM_SIZE(NUM_OF_ENTRIES), .AW((PTR_WIDTH)), .DW(DAT_WIDTH))  I_generic_2p_rf(
   // Wr Ports
   .wr_addr   (wr_addr),
   .wr_data   (wr_data), 
   .wr_me_en  (wr_op),
   .wr_clk    (wr_clk),     
   // Rd Ports
   .rd_data   (rd_data),
   .rd_addr   (rd_addr),
   .rd_me_en  (rd_op),
   .rd_clk    (rd_clk)
   
   );

endmodule
// Local Variables:
// verilog-library-directories:("." "$DB_DIR/mars/common/general/dw_cells" "/vobs/mars/common/rams/hdl/" )
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h" ".sv")
// End:

