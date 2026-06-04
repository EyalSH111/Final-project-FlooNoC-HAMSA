//   Description: generic fifo of single clock domain
//                connects to a compiled memory of type 1r1w
//                supports any size
//   Changes:     1) 02.08.10 - Add clear option to reset the FIFO's pointers
//                2) 11.10.10 - Reflect full inddication in entry_used msb (thus making two_power_n redundant)
//                3) 03.11.10 - Comment out two_power_n for it is an unused signal

module generic_fifo_crgn(clk,
                    reset_n,
//                  two_power_n,
                    wr_op,
                    rd_op,
                    clr,
                    wr_addr,
                    rd_addr,
                    full,
                    empty,
                    entry_used,
                    err_rdempty,
                    err_wrfull
                    );

   parameter PTR_WIDTH = 8;        // address bus width of the fifo
   parameter NUM_OF_ENTRIES = 256; // number of rows // (can be a non 2^x number only if two_power_n is set)
   
   input  clk;
   input  reset_n;
// input  two_power_n; // Related logic is now common for mode ~two_power_n so it is not relevant anymore
   input  wr_op;
   input  rd_op;
   input  clr;
   output [PTR_WIDTH - 1:0] wr_addr;
   output [PTR_WIDTH - 1:0] rd_addr;
   output full;
   output empty;
   output [PTR_WIDTH    :0] entry_used;
   output err_rdempty;
   output err_wrfull;
   
   reg    [PTR_WIDTH    :0] rd_pointer;
   reg    [PTR_WIDTH    :0] wr_pointer;
   
   wire   empty;
   wire   full;
   wire   [PTR_WIDTH - 1:0] a_minus_b;
   wire   [PTR_WIDTH    :0] a_minus_c;
   wire   [PTR_WIDTH - 1:0] entry_used_int;
   wire   [PTR_WIDTH - 1:0] last_entry;
   wire   [PTR_WIDTH - 1:0] first_entry;
   reg    err_rdempty;
   reg    err_wrfull;
   
   assign last_entry = NUM_OF_ENTRIES - 1;
   assign first_entry = 0;
   
   always @(posedge clk)
      if (!reset_n)
         rd_pointer <= {1'b0,first_entry};
      else if (clr)
         rd_pointer <= {1'b0,first_entry};
      else if (rd_op && !empty && (rd_pointer == {1'b0,last_entry}))
         rd_pointer <= {1'b1,first_entry}; 
      else if (rd_op && !empty && (rd_pointer == {1'b1,last_entry}))
         rd_pointer <= {1'b0,first_entry}; 
      else if (rd_op && !empty)
         rd_pointer <= rd_pointer + {{PTR_WIDTH{1'b0}},1'b1};
   
   assign rd_addr = rd_pointer[PTR_WIDTH-1:0];
   
   always @(posedge clk)
      if (!reset_n)
         err_rdempty <= 1'd0;
      else if (clr)
         err_rdempty <= 1'd0;
      else 
         err_rdempty <= (rd_op && empty);

   always @(posedge clk)
      if (!reset_n)
         wr_pointer <= {1'b0,first_entry};
      else if (clr)
         wr_pointer <= {1'b0,first_entry};
      else if (wr_op && !full && (wr_pointer == {1'b0,last_entry}))
         wr_pointer <= {1'b1,first_entry}; 
      else if (wr_op && !full && (wr_pointer == {1'b1,last_entry}))
         wr_pointer <= {1'b0,first_entry}; 
      else if (wr_op && !full)
         wr_pointer <= wr_pointer + {{PTR_WIDTH{1'b0}},1'b1};
   
   assign wr_addr = wr_pointer[PTR_WIDTH-1:0];
   
   always @(posedge clk)
      if (!reset_n)
         err_wrfull <= 1'd0;
      else if (clr)
         err_wrfull <= 1'd0;
      else 
         err_wrfull <= (wr_op && full);

   assign empty = (rd_pointer[PTR_WIDTH:0] == wr_pointer[PTR_WIDTH:0]);
   assign full  = (rd_pointer[PTR_WIDTH-1:0] == wr_pointer[PTR_WIDTH-1:0]) &&
                  (rd_pointer[PTR_WIDTH] == !wr_pointer[PTR_WIDTH]);
   
   assign a_minus_b = (wr_pointer[PTR_WIDTH-1:0] - rd_pointer[PTR_WIDTH-1:0]);
   assign a_minus_c = (wr_pointer[PTR_WIDTH-1:0] + last_entry + {{(PTR_WIDTH-1){1'b0}},1'b1} - rd_pointer[PTR_WIDTH-1:0]);
   assign entry_used_int = (!(rd_pointer[PTR_WIDTH] ^ wr_pointer[PTR_WIDTH])) ?
                           a_minus_b : a_minus_c[PTR_WIDTH-1:0];
   
   assign entry_used = {full,entry_used_int};

endmodule
