
module hamsa_L0_cache #(parameter L0_CACHE_DEPTH_LOG2=3) (

  // General
  input clk,
  input rst_n,
  
  // Write Port
  input [31:0]  wr_addr_i,
  input [127:0] wr_data_i,
  input wr_enable_i,
  
  // Match Port A
  input [31:0] match_addr_a_i,
  output match_a_o,
  output [127:0] match_data_a_o,
  
  // Match Port B
  input [31:0] match_addr_b_i,
  output match_b_o,
  output [127:0] match_data_b_o,
  
  // Match Port C
  input [31:0] match_addr_c_i,
  output match_c_o,
  output [127:0] match_data_c_o,
  input flush_cache
);

 localparam IDX_W = L0_CACHE_DEPTH_LOG2 ;
 localparam NUM_LINES = 2**IDX_W ; // Number of lines in buffer , each line is 4 X 32b words

 typedef struct packed {
 	logic [127:0] data ; 
 	logic [27-IDX_W:0] tag ;  
 	logic valid ;
 } cache_line_t ;

 cache_line_t  cache [NUM_LINES-1:0] ;  // Prefetch buffer  

 typedef struct packed {
   logic [27-IDX_W:0] tag  ;   
   logic [IDX_W-1:0]  idx  ;     
   logic [3:0]        offset  ;
 } cache_addr_t ;
 
 cache_addr_t wr_addr, match_addr_a, match_addr_b, match_addr_c ;

 // cast to cache_addr_t
 assign wr_addr      = wr_addr_i ;
 assign match_addr_a = match_addr_a_i ; 
 assign match_addr_b = match_addr_b_i ; 
 assign match_addr_c = match_addr_c_i ; 

 // Write
 int i ; // looper
 always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
       for (i=0;i<NUM_LINES;i++) cache[i].valid <= 1'b0 ;      
    end else begin
       if (flush_cache) begin
          for (i=0;i<NUM_LINES;i++) cache[i].valid <= 1'b0 ;                  
       end else if (wr_enable_i) begin
          cache[wr_addr.idx].data   <= wr_data_i ;
          cache[wr_addr.idx].tag    <= wr_addr.tag ;
          cache[wr_addr.idx].valid  <= 1'b1 ;
       end         
    end
 end
 
 // Match Ports
 
 // Check if match
 assign match_a_o = !flush_cache && cache[match_addr_a.idx].valid && (cache[match_addr_a.idx].tag == match_addr_a.tag) ;
 assign match_b_o = !flush_cache && cache[match_addr_b.idx].valid && (cache[match_addr_b.idx].tag == match_addr_b.tag) ;
 assign match_c_o = !flush_cache && cache[match_addr_c.idx].valid && (cache[match_addr_c.idx].tag == match_addr_c.tag) ;

 // match data 
 assign match_data_a_o = cache[match_addr_a.idx].data ;
 assign match_data_b_o = cache[match_addr_b.idx].data ;
 assign match_data_c_o = cache[match_addr_c.idx].data ;

endmodule
 