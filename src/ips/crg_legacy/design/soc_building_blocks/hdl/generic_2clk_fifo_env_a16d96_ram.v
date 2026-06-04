
// Description: 2clk FIFO Envelope
//              Instantiation of a generic fifo of dual clock domain
//              connects to a compiled memory of type 1r1w - CRF2PA8D50CM1BK1

module generic_2clk_fifo_env_a16d96_ram(/*AUTOARG*/
   // Outputs
   wr_reset_out_n, wr_full, wr_empty, wr_entry_used, wr_full_err,
   rd_data, rd_full, rd_empty, rd_entry_used, rd_empty_err,
   // Inputs
   wr_clk, wr_op, wr_data, wr_mask, rd_clk, rd_reset_n, rd_op,
   scan_mode, ram_ctrl_vec
   );


   parameter PTR_WIDTH = 4;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 16; // number of rows // (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 96;       // data bus width of the fifo

   input  wr_clk;
   output wr_reset_out_n;
   input  wr_op;
   input  [DAT_WIDTH - 1:0] wr_data;
   input  [DAT_WIDTH - 1:0] wr_mask;
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
   input  scan_mode;
   input [6:0] ram_ctrl_vec;

   wire [PTR_WIDTH - 1:0] wr_addr;
   wire [DAT_WIDTH - 1:0] wr_data;
   wire [DAT_WIDTH - 1:0] wr_mask;
   wire [PTR_WIDTH :0] wr_entry_used;
   
   wire [PTR_WIDTH - 1:0] rd_addr;
   wire [DAT_WIDTH - 1:0] rd_data;
   wire [PTR_WIDTH :0] rd_entry_used;
   
   wire [3:0] rm;

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
// .two_power_n(two_power_n));


/* CRF2PA16D96CM1C2L AUTO_TEMPLATE (
   // Wr Ports
   .wr_addr   (wr_addr),
   .wr_data   (wr_data),
   .wr_mask   (wr_mask),
   .wr_me_en  (wr_op),
   .wr_clk    (wr_clk),
   // Rd Ports
   .rd_data   (rd_data),
   .rd_addr   (rd_addr),
   .rd_me_en  (rd_op),
   // System
   .scan_mode (scan_mode),
   .sreset_n  (wr_reset_out_n),
   .rambist_mode(1'b0),
   .ram_ctrl_vec	(ram_ctrl_vec[6:0]),
    );*/

CRF2PA16D96CM1C2L #(.RAM_CTRL_VEC_SIZE(7))
     I_generic_2clk_fifo_mem_wrap(/*AUTOINST*/
				  // Outputs
				  .rd_data		(rd_data),	 // Templated
				  // Inputs
				  .wr_addr		(wr_addr),	 // Templated
				  .wr_data		(wr_data),	 // Templated
				  .wr_mask		(wr_mask),	 // Templated
				  .wr_me_en		(wr_op),	 // Templated
				  .wr_clk		(wr_clk),	 // Templated
				  .rd_addr		(rd_addr),	 // Templated
				  .rd_me_en		(rd_op),	 // Templated
				  .rd_clk		(rd_clk),
				  .scan_mode		(scan_mode),	 // Templated
				  .rambist_mode		(1'b0),		 // Templated
				  .sreset_n		(wr_reset_out_n), // Templated
				  .ram_ctrl_vec		(ram_ctrl_vec[6:0])); // Templated

endmodule

// Local Variables:
// verilog-library-directories:("." "$NEGEV_IP/design/crgn/soc_building_blocks/hdl/" "$$NEGEV_IP/design/arm/rams/28nm/wrappers/hdl")
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h" ".sv" ".vhd")
// End:
