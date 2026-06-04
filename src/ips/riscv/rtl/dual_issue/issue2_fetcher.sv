
// Fetch issue2 instruction candidate from buffer

module issue2_fetcher (

 input clk,
 input rst_n,
 
 output logic [31:0]    i2_instr_word,       // sampled input to decode stage
 output logic           i2_instr_word_valid, // sampled input to decode stage

 input 						di_en_i,
 input                  i2_id_ready_i, 
 input                  clear_instr_valid_i,
  
 output logic [31:0] i2_pc_if, 
 output logic [31:0] i2_pc_id,
 input               pi_unusal_state_prevent_di,
 
 di_ifstage_interface.i2 di_intrfc_ifstage,
 di_pfb_interface.i2     di_intrfc_pfb
);

   logic              i2_instr_allocated;  // feedback to primary pre fetcher to skip an instruction   
   logic [3:0][31:0]  instr_buf;
   logic [2:0]        pi_hw_idx;
   logic              pi_hw_idx_valid;
   logic              primary_if_valid;
   logic [31:0]       pi_pc_if;
   
   assign instr_buf          = di_intrfc_pfb.instr_buf        ; 
   assign pi_hw_idx          = di_intrfc_pfb.pi_hw_idx        ; 
   assign pi_hw_idx_valid    = di_intrfc_pfb.pi_hw_idx_valid  ; 
   assign primary_if_valid   = di_intrfc_ifstage.primary_if_valid ;  
   assign pi_pc_if           = di_intrfc_ifstage.pi_fetch_addr    ; 

   logic [31:0] primary_instr_word ;
   logic  pi_instr_is_not_compressed ;
   logic  i2_instr_is_not_compressed ;  

   // Pre-Sampled
   logic [31:0] i2_instr_word_fetched ;   
   
   logic primary_valid ;
   
   logic  [7:0][15:0] instr_buf_hw ; // same instruction buffer represented by 8 x halfwords, for a more convenient access
   
   logic [2:0] i2_hw_idx ; // half-word index of u2 instruction within the buffer
   
   assign instr_buf_hw = instr_buf ; 
   
   assign primary_valid = pi_hw_idx_valid && primary_if_valid ; // TODO check avoiding IF stall from ID dependency
   
   logic [2:0] pi_hw_idx_plus1 ;
   logic [2:0] pi_hw_idx_plus2 ;
   
   assign pi_hw_idx_plus1 = pi_hw_idx + 1 ;
   assign pi_hw_idx_plus2 = pi_hw_idx + 2 ;
   
   assign primary_instr_word = {instr_buf_hw[pi_hw_idx_plus1],instr_buf_hw[pi_hw_idx] };

   //assign  pi_instr_is_not_compressed = (primary_instr_word[1:0] == 2'b11) ;   
   assign  pi_instr_is_not_compressed = primary_valid && (primary_instr_word[1:0] == 2'b11) ;  // avoid X propagate incase primary is not valid
     
   assign i2_hw_idx = pi_instr_is_not_compressed ? pi_hw_idx_plus2 : pi_hw_idx_plus1 ;
   
   logic [2:0] i2_hw_idx_plus1 ;
   assign i2_hw_idx_plus1 = i2_hw_idx+1 ;
   
   assign i2_instr_word_fetched = {instr_buf_hw[i2_hw_idx_plus1],instr_buf_hw[i2_hw_idx]};
                                                         
   assign i2_instr_is_not_compressed = (i2_instr_word_fetched[1:0] == 2'b11) ;  

   logic [2:0] di_num_hw ; // Total number of half-words occupied by pi and i2 instructions with in the 128 bits line.                          
   assign di_num_hw = 3'd2 + {2'd0,pi_instr_is_not_compressed} + {2'd0,i2_instr_is_not_compressed} ; // relevant only in case of allocation.

   // Notice issue2 candidate instr word, currently applied only if within same 128b line   
   logic in_line_ok ; // both i2 and di are within the line.
   
   logic [3:0] next_hw_idx_potential ; // Next potential half-word index in case of allocation
   assign next_hw_idx_potential  = {1'b0,pi_hw_idx} + {1'b0,di_num_hw} ; // extra bit to avoid miscalculate on overflow
   assign in_line_ok =  next_hw_idx_potential <= 4'd8 ;
          
   assign i2_pc_if = pi_pc_if + (pi_instr_is_not_compressed ? 4 : 2) ; 

  // I2 decompression
   logic [31:0] i2_instr_word_decomp ; // i2 instruction decompressed  (for either originally compressed or non non-compressed)           
   logic instr_compressed_int ;        // Calculated separately, used in primary issue case for performance counter , TODO need to support also in issue2
   logic illegal_c_insn       ;        // Currently not handled in issue2 (other than assertion)
  
  
  riscv_compressed_decoder compressed_decoder_i (
     .instr_i         ( i2_instr_word_fetched ),
     .instr_o         ( i2_instr_word_decomp  ),
     .is_compressed_o ( instr_compressed_int ),
     .illegal_instr_o ( illegal_c_insn       )
   );

   // issue2 allocation
   
  logic i2_instr_allocate_ok ;  
  
   issue2_allocator i_alloc ( 
	 .di_en_i(di_en_i),
    .in_line_ok(in_line_ok),
    .pi_instr(di_intrfc_ifstage.pi_instr_decomp),
    .i2_instr(i2_instr_word_decomp),
    .pi_unusal_state_prevent_di(pi_unusal_state_prevent_di),
    .i2_instr_allocate_ok(i2_instr_allocate_ok) 
   );
   
   
  assign i2_instr_allocated = primary_valid && i2_instr_allocate_ok ;
   
  assign di_intrfc_pfb.i2_instr_allocated = i2_instr_allocated ;
  assign di_intrfc_pfb.i2_instr_allocate_ok = i2_instr_allocate_ok ; 
  
  assign di_intrfc_ifstage.i2_instr_allocated = i2_instr_allocated; 
  
  logic i2_alloc_non_killed ;
  assign i2_alloc_non_killed =    i2_instr_allocated 
                               && !di_intrfc_ifstage.pi_hwlp_di_prevent_cond 
                               && !pi_unusal_state_prevent_di ;

  assign di_intrfc_pfb.next_potential_hw_idx = next_hw_idx_potential[2:0] ;
  assign di_intrfc_pfb.next_hw_idx = i2_alloc_non_killed ? next_hw_idx_potential[2:0] : pi_hw_idx + (pi_instr_is_not_compressed ? 2 : 1) ;

 // ISSUE2 IF-ID sampling
 
  logic  i2_instr_word_valid_cond ; 
  
  assign i2_instr_word_valid_cond = i2_id_ready_i && i2_alloc_non_killed ;

 always_ff @(posedge clk, negedge rst_n)
 
    if (rst_n == 1'b0) begin
     i2_instr_word <= 32'b0 ;       
     i2_instr_word_valid <= 1'b0 ;
     i2_pc_id <= 0 ;
    end else begin               
       if (i2_instr_word_valid_cond) begin  
        i2_instr_word_valid <= 1 ;
        i2_instr_word <= i2_instr_word_decomp ;
        i2_pc_id <= i2_pc_if ;
       end 
       else if (clear_instr_valid_i) 
       begin
         i2_instr_word_valid <= 0 ; 
       end       
    end

endmodule
