
// Description: 2clk FIFO Envelope
//              Instantiation of a generic fifo of dual clock domain
//              connects to a compiled memory of type 1r1w - CRF2PA512D36CM1BK1

module generic_2clk_fifo_env_a512d32_ram ( 
                                        wr_clk,
                                        wr_reset_n,
                                        wr_reset_out_n,
                                        wr_op,
                                        wr_data,
                                        wr_mask,
                                        wr_full,
                                        wr_empty,
                                        wr_entry_used,
                                        wr_full_err,
                                        rd_clk,
                                        rd_clk_ram,
                                        rd_reset_n,
                                        rd_op,
                                        rd_data,
                                        rd_full,
                                        rd_empty,
                                        rd_entry_used,
                                        rd_empty_err,
                                        scan_mode,
                                        ram_ctrl_vec
                                        );


   parameter PTR_WIDTH = 8;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 256; // number of rows (can be a non 2^x number only if two_power_n is set)
   parameter DAT_WIDTH = 32;       // data bus width of the fifo
   parameter RAM_CTRL_VEC_SIZE = 7 ;

   input  wr_clk;
   input  wr_reset_n;
   output wr_reset_out_n;
   input  wr_op;
   input  [DAT_WIDTH - 1:0] wr_data;
   input  [DAT_WIDTH - 1:0] wr_mask;
   output wr_full;
   output wr_empty;
   output [PTR_WIDTH :0] wr_entry_used;
   output wr_full_err;
   input  rd_clk;
   input  rd_clk_ram;
   input  rd_reset_n;
   input  rd_op;
   output  [DAT_WIDTH - 1:0] rd_data;
   output rd_full;
   output rd_empty;
   output [PTR_WIDTH :0] rd_entry_used;
   output rd_empty_err;
   input  scan_mode;
   input  [6:0] ram_ctrl_vec;

   wire [PTR_WIDTH - 1:0] wr_addr;
   wire [DAT_WIDTH - 1:0] wr_data;
   wire [DAT_WIDTH - 1:0] wr_mask;
   wire [PTR_WIDTH :0] wr_entry_used;
   
   wire [PTR_WIDTH - 1:0] rd_addr;
   wire [DAT_WIDTH - 1:0] rd_data;
   wire [PTR_WIDTH :0] rd_entry_used;
   wire                rd_reset_n_d;
   wire                rd_reset_n_muxed;

   
   crg_scan_ff  rd_reset_sync (
             .clk(rd_clk),
             .d(rd_reset_n),
             .q(rd_reset_n_d)                            
          );

   crg_clk_mx2
     I_rd_reset_n_clk_mx
       ( // Outputs
        .y                              (rd_reset_n_muxed),
        // Inputs
        .a                              (rd_reset_n_d),
        .b                              (rd_reset_n),
        .s                              (scan_mode));

   
generic_2clk_fifo #(PTR_WIDTH, NUM_OF_ENTRIES) Icrg_2clk_fifo (
   .scan_mode (scan_mode),
   // Port a: Rd
   .clka(rd_clk),
   .reseta_n(rd_reset_n_muxed),
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

CRF2PA256D32CM2C2LBW
     #(.RAM_CTRL_VEC_SIZE(RAM_CTRL_VEC_SIZE))
     Icrg_2clk_fifo_mem_wrap (
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
   .rd_clk    (rd_clk_ram),
   // System  
   .scan_mode (scan_mode),
   .sreset_n  (wr_reset_n),
   // Control
   .rambist_mode(),
   .ram_ctrl_vec(ram_ctrl_vec)
   );

   

endmodule
