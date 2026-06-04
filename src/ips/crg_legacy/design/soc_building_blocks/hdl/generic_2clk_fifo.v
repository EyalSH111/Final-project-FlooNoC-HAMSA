// Description: generic fifo of dual clock domain
//              connects to a compiled memory of type 1r1w
//              supports any size
// Changes:     1) 11.10.10 - Reflect full inddication in entry_used msb (thus making two_power_n redundant)
//              2) 03.11.10 - Comment out two_power_n for it is an unused signal
//              3) 22.09.11 - Synchronize the rd_reset to the wr domain to
//                            prevent false used condtion on the rd domain.
//                            The modification requires a scan logic addition
//                            with a new input to the module
//              4) 03.10.11 - Add crg_scan_ff instantiation before synchronizing the reset,
//                            to eliminate possible glitches due to combinatorical cells on the
//                            read domain reset input
//                            Add a new reset output - required for phy fifos
//              5) 28.03.13 - Replace the synchronisation logic of the gray code pointers to a 
//                            Ceragon building block synchronisers, using genvar.

module generic_2clk_fifo(scan_mode,
                         clka,
                         clkb,
                         reseta_n,
                         resetb_out_n,
                         wr_op,
                         rd_op,
                         wr_addr,
                         rd_addr,
                         fulla,
                         fullb,
                         emptya,
                         emptyb,
                         entry_useda,
                         entry_usedb,
                         err_rdemptya,
                         err_wrfullb
                         );

/* The memory is connected according the following:
   CLKA - clka
   CLKB - clkb
   AA - rd_addr
   AB - wr_addr
   CENA - rd_op
   CENB - wr_op
   Other signals come directly from logic in the unit that instantiates the fifo
*/

   parameter PTR_WIDTH = 8;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 256; // number of rows, must be a 2^x value

   input  scan_mode;
   input  clka;
   input  clkb;
   input  reseta_n;
   output resetb_out_n;
   input  wr_op;
   input  rd_op;
   output [PTR_WIDTH - 1:0] rd_addr;
   output [PTR_WIDTH - 1:0] wr_addr;
   output fulla;
   output fullb;
   output emptya;
   output emptyb;
   output [PTR_WIDTH :0] entry_useda;
   output [PTR_WIDTH :0] entry_usedb;
   output err_rdemptya;
   output err_wrfullb;

   reg    [PTR_WIDTH    :0] rd_pointer;
   reg    [PTR_WIDTH    :0] rd_pointer_gray_comb;
   reg    [PTR_WIDTH    :0] rd_pointer_gray;
   wire   [PTR_WIDTH    :0] rd_pointer_gray_s2;
   reg    [PTR_WIDTH    :0] rd_pointer_sync;
   reg    [PTR_WIDTH    :0] wr_pointer;
   reg    [PTR_WIDTH    :0] wr_pointer_gray_comb;
   reg    [PTR_WIDTH    :0] wr_pointer_gray;
   wire   [PTR_WIDTH    :0] wr_pointer_gray_s2;
   reg    [PTR_WIDTH    :0] wr_pointer_sync;
   wire   [PTR_WIDTH - 1:0] rd_addr;
   wire   [PTR_WIDTH - 1:0] wr_addr;

   wire   resetb_n;
   wire   fulla;
   wire   fullb;
   wire   emptya;
   wire   emptyb;
   wire   [PTR_WIDTH - 1:0] n1_minus_n2_a;
   wire   [PTR_WIDTH    :0] n1_minus_n3_a;
   wire   [PTR_WIDTH - 1:0] n1_minus_n2_b;
   wire   [PTR_WIDTH    :0] n1_minus_n3_b;
   wire   [PTR_WIDTH - 1:0] entry_useda_int;
   wire   [PTR_WIDTH - 1:0] entry_usedb_int;
   wire   [PTR_WIDTH    :0] entry_useda;
   wire   [PTR_WIDTH    :0] entry_usedb;
   wire   [PTR_WIDTH - 1:0] last_entry;
   wire   [PTR_WIDTH - 1:0] first_entry;
   reg    err_rdemptya;
   reg    err_wrfullb;

   integer i;
   integer j;
   integer k;
   integer m;

   crg_reset_cross
           Isync_rw_reset(
                          .clka          (clka),
                          .clka_sreset_n  (reseta_n),           
                          .clkb          (clkb),   
                          .scan_mode      (scan_mode),
                          .clkb_sreset_n  (resetb_n));
  //crg_reset_sync Isync_rw_reset(
  //               .arst_n(reseta_n), 
  //               .clk(clkb), 
  //               .scan_mode(scan_mode),
  //               .rst_out_n(resetb_n)); // async rd_reset, wr_clk, output is synced wr_reset

   assign resetb_out_n = resetb_n;

   assign last_entry = NUM_OF_ENTRIES - 1;
   assign first_entry = 0;

   always @(posedge clka)
      if (!reseta_n)
         rd_pointer <= 'd0;
      else if (rd_op && !emptya && (rd_pointer == {1'b0,last_entry}))
         rd_pointer <= {1'b1,first_entry};
      else if (rd_op && !emptya && (rd_pointer == {1'b1,last_entry}))
         rd_pointer <= {1'b0,first_entry};
      else if (rd_op && !emptya)
         rd_pointer <= rd_pointer + {{PTR_WIDTH{1'b0}},1'b1};

   assign rd_addr = rd_pointer[PTR_WIDTH-1:0];

   always @(posedge clka)
      if (!reseta_n)
         err_rdemptya <= 1'd0;
      else 
         err_rdemptya <= (rd_op && emptya);

   always @(posedge clkb)
      if (!resetb_n)
         wr_pointer <= 'd0;
      else if (wr_op && !fullb && (wr_pointer == {1'b0,last_entry}))
         wr_pointer <= {1'b1,first_entry};
      else if (wr_op && !fullb && (wr_pointer == {1'b1,last_entry}))
         wr_pointer <= {1'b0,first_entry};
      else if (wr_op && !fullb)
         wr_pointer <= wr_pointer + {{PTR_WIDTH{1'b0}},1'b1};

   assign wr_addr =  wr_pointer[PTR_WIDTH-1:0];

   always @(posedge clkb)
      if (!resetb_n)
         err_wrfullb <= 1'd0;
      else 
         err_wrfullb <= (wr_op && fullb);

   // gray pointers generation
   always @(*)
      begin
      rd_pointer_gray_comb[PTR_WIDTH] = rd_pointer[PTR_WIDTH];
      for (i=PTR_WIDTH-1; i>=0; i=i-1)
         begin
         rd_pointer_gray_comb[i] = rd_pointer[i] ^ rd_pointer[i+1];
         end
      end

   always @(*)
      begin
      wr_pointer_gray_comb[PTR_WIDTH] = wr_pointer[PTR_WIDTH];
      for (j=PTR_WIDTH-1; j>=0; j=j-1)
         begin
         wr_pointer_gray_comb[j] = wr_pointer[j] ^ wr_pointer[j+1];
         end
      end

   // pointers sinchronization
   always @(posedge clkb)
      if (!resetb_n)
         wr_pointer_gray    <= 'd0;
      else
         wr_pointer_gray    <= wr_pointer_gray_comb;

   always @(posedge clka)
      if (!reseta_n)
         rd_pointer_gray    <= 'd0;
      else
         rd_pointer_gray    <= rd_pointer_gray_comb;

   genvar v;
   generate
      for (v=0; v<PTR_WIDTH+1; v=v+1) begin: crg_buf_gen
      crg_sync2 Icrg_sync2_rd_ptr (
         // Inputs
         .clk(clkb),
         .d(rd_pointer_gray[v]),
         // Outputs
         .q(rd_pointer_gray_s2[v]));
      crg_sync2 Icrg_sync2_wr_ptr (
         // Inputs
         .clk(clka),
         .d(wr_pointer_gray[v]),
         // Outputs
         .q(wr_pointer_gray_s2[v]));
      end
   endgenerate

   // synched binary pointers generation
   always @(*)
      begin
      rd_pointer_sync[PTR_WIDTH] = rd_pointer_gray_s2[PTR_WIDTH];
      for (k=PTR_WIDTH-1; k>=0; k=k-1)
         begin
         rd_pointer_sync[k] = rd_pointer_gray_s2[k] ^ rd_pointer_sync[k+1];
         end
      end

   always @(*)
      begin
      wr_pointer_sync[PTR_WIDTH] = wr_pointer_gray_s2[PTR_WIDTH];
      for (m=PTR_WIDTH-1; m>=0; m=m-1)
         begin
         wr_pointer_sync[m] = wr_pointer_gray_s2[m] ^ wr_pointer_sync[m+1];
         end
      end

   // empty on clk domain; full on clka domain
   assign fulla  = (rd_pointer[PTR_WIDTH-1:0] == wr_pointer_sync[PTR_WIDTH-1:0]) &&
                   (rd_pointer[PTR_WIDTH] == !wr_pointer_sync[PTR_WIDTH]);
   assign fullb  = (rd_pointer_sync[PTR_WIDTH-1:0] == wr_pointer[PTR_WIDTH-1:0]) &&
                   (rd_pointer_sync[PTR_WIDTH] == !wr_pointer[PTR_WIDTH]);
   assign emptya = (rd_pointer[PTR_WIDTH:0] == wr_pointer_sync[PTR_WIDTH:0]);
   assign emptyb = (rd_pointer_sync[PTR_WIDTH:0] == wr_pointer[PTR_WIDTH:0]);

   // entry used calculation
   assign n1_minus_n2_a = (wr_pointer_sync[PTR_WIDTH-1:0] - rd_pointer[PTR_WIDTH-1:0]);
   assign n1_minus_n3_a = (wr_pointer_sync[PTR_WIDTH-1:0] + last_entry + {{(PTR_WIDTH-1){1'b0}},1'b1} - rd_pointer[PTR_WIDTH-1:0]);
   assign entry_useda_int = (!(wr_pointer_sync[PTR_WIDTH] ^ rd_pointer[PTR_WIDTH])) ?
                            n1_minus_n2_a : n1_minus_n3_a[PTR_WIDTH-1:0];

   assign n1_minus_n2_b = (wr_pointer[PTR_WIDTH-1:0] - rd_pointer_sync[PTR_WIDTH-1:0]);
   assign n1_minus_n3_b = (wr_pointer[PTR_WIDTH-1:0] + last_entry + {{(PTR_WIDTH-1){1'b0}},1'b1} - rd_pointer_sync[PTR_WIDTH-1:0]);
   assign entry_usedb_int = (!(wr_pointer[PTR_WIDTH] ^ rd_pointer_sync[PTR_WIDTH])) ?
                            n1_minus_n2_b : n1_minus_n3_b[PTR_WIDTH-1:0];

   assign entry_useda = {fulla,entry_useda_int};
   assign entry_usedb = {fullb,entry_usedb_int};

endmodule // generic_2clk_fifo
