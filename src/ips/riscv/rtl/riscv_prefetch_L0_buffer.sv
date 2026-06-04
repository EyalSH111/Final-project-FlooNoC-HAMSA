// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Igor Loi - igor.loi@unibo.it                               //
//                                                                            //
// Additional contributions by:                                               //
//                 Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Design Name:    Prefetcher Buffer for 128 bit memory interface             //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Prefetch Buffer that caches instructions. This cuts overly //
//                 long critical paths to the instruction cache               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module riscv_prefetch_L0_buffer
#(
  parameter                                   RDATA_IN_WIDTH = 128
)
(
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                req_i,

  input  logic                                branch_i,
  input  logic [31:0]                         addr_i,

  input  logic                                hwloop_i,
  input  logic [31:0]                         hwloop_target_i,
  
  input  logic                                ready_i,
  output logic                                valid_o,
  output logic [31:0]                         rdata_o,
  output logic [31:0]                         addr_o,
  output logic                                is_hwlp_o, // is set when the currently served data is from a hwloop

  // goes to instruction memory / instruction cache
  output logic                                instr_req_o,
  output logic [31:0]                         instr_addr_o,
  input  logic                                instr_gnt_i,
  input  logic                                instr_rvalid_i,
  input  logic [RDATA_IN_WIDTH/32-1:0][31:0]  instr_rdata_i,

  // Prefetch Buffer Status
  output logic                                busy_o
  
  `ifdef HAMSA_DI  // Dual-Issue Logic optional pfb (pref-fetch-buffer) interface
  ,di_pfb_interface.pi di_intrfc_pfb
  ,input pi_hwlp_di_prevent_cond 
  `endif
  
  
);

  logic                               busy_L0;

  enum logic [3:0] { IDLE, BRANCHED,
                     HWLP_WAIT_GNT, HWLP_GRANTED, HWLP_GRANTED_WAIT, HWLP_FETCH_DONE,
                     NOT_VALID, NOT_VALID_GRANTED, NOT_VALID_CROSS, NOT_VALID_CROSS_GRANTED,
                     VALID, VALID_CROSS, VALID_GRANTED, VALID_FETCH_DONE } CS, NS;

  logic                               do_fetch;
  logic                               do_hwlp, do_hwlp_int;
  logic                               use_last;
  logic                               save_rdata_last;
  logic                               use_hwlp;
  logic                               save_rdata_hwlp;
  logic                               valid;

  logic                               hwlp_is_crossword;
  logic                               is_crossword;
  logic                               next_is_crossword;
  logic                               next_valid;
  logic                               next_upper_compressed;
  logic                               fetch_possible;
  logic                               upper_is_compressed;

  logic                       [31:0]  addr_q, addr_n, addr_int, addr_aligned_next, addr_real_next;
  logic                               is_hwlp_q, is_hwlp_n;

  logic                       [31:0]  rdata_last_q;
`ifndef L0_BUF_SAMPLED  
  logic                               valid_L0; // Not used anywhere
`endif   
  logic [RDATA_IN_WIDTH/32-1:0][31:0] rdata_L0;
  logic                        [31:0] addr_L0;

  logic                               fetch_valid;
  logic                               fetch_gnt;

  // prepared data for output
  logic                        [31:0] rdata, rdata_unaligned;

  logic                               aligned_is_compressed, unaligned_is_compressed;
  logic                               hwlp_aligned_is_compressed, hwlp_unaligned_is_compressed;


`ifdef HAMSA_DI
   // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case   
  logic do_sample_hwloop_target_for_wait  ; 
  logic [31:0] sampled_hwloop_target_for_wait ; 
`endif

`ifdef L0_BUF_SAMPLED   // No non-sampled path from memory
  riscv_L0_buffer_sampled
`else
  riscv_L0_buffer  // you may yet optionally define for this EN_L0_INBUF 
                   // which does nor block but also does not fetch if instruction is found in buffer
`endif



  #(
    .RDATA_IN_WIDTH ( RDATA_IN_WIDTH )
  )
  L0_buffer_i
  (
    .clk                  ( clk                ),
    .rst_n                ( rst_n              ),

    .prefetch_i           ( do_fetch           ),
    .prefetch_addr_i      ( addr_real_next     ), //addr_aligned_next

    .branch_i             ( branch_i           ),
    .branch_addr_i        ( addr_i             ),

    .hwlp_i               ( do_hwlp | do_hwlp_int ),
        
    `ifndef HAMSA_DI          
    .hwlp_addr_i          ( hwloop_target_i    ),
    `else 
     // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case   
    .hwlp_addr_i          ( do_hwlp_int ? sampled_hwloop_target_for_wait : hwloop_target_i),
    `endif    
   
    .fetch_gnt_o          ( fetch_gnt          ),
    .fetch_valid_o        ( fetch_valid        ),
`ifndef L0_BUF_SAMPLED  
    .valid_o              ( valid_L0           ),  // Not used anywhere
`endif
    .rdata_o              ( rdata_L0           ),
    .addr_o               ( addr_L0            ),

    .instr_req_o          ( instr_req_o        ),
    .instr_addr_o         ( instr_addr_o       ),
    .instr_gnt_i          ( instr_gnt_i        ),
    .instr_rvalid_i       ( instr_rvalid_i     ),
    .instr_rdata_i        ( instr_rdata_i      ),

    .busy_o               ( busy_L0            )
        
  );
  

  assign rdata = (use_last || use_hwlp) ? rdata_last_q : rdata_L0[addr_o[3:2]];
  
  // the lower part of rdata_unaligned is always the higher part of rdata
  assign rdata_unaligned[15:0] = rdata[31:16];

  always_comb
  begin
    case(addr_o[3:2])
       2'b00: begin rdata_unaligned[31:16] = rdata_L0[1][15:0]; end
       2'b01: begin rdata_unaligned[31:16] = rdata_L0[2][15:0]; end
       2'b10: begin rdata_unaligned[31:16] = rdata_L0[3][15:0]; end
       2'b11: begin rdata_unaligned[31:16] = rdata_L0[0][15:0]; end
    endcase // addr_o
  end

  assign unaligned_is_compressed = rdata[17:16] != 2'b11;
  assign aligned_is_compressed   = rdata[1:0] != 2'b11;
  assign upper_is_compressed     = rdata_L0[3][17:16] != 2'b11;
  assign is_crossword            = (addr_o[3:1] == 3'b111) && (~upper_is_compressed);

  logic        next_is_crossword_si ;
  logic        next_upper_compressed_si ;
  logic        next_valid_si ;
  logic        fetch_possible_si ;     
  logic [31:0] addr_aligned_next_si ;
  logic [31:0] addr_real_next_si   ;  


  assign next_is_crossword_si      = ((addr_o[3:1] == 3'b110) && (aligned_is_compressed) && (~upper_is_compressed)) || ((addr_o[3:1] == 3'b101) && (~unaligned_is_compressed) && (~upper_is_compressed));
  assign next_upper_compressed_si  = ((addr_o[3:1] == 3'b110) && (aligned_is_compressed) && upper_is_compressed) || ((addr_o[3:1] == 3'b101) && (~unaligned_is_compressed) && upper_is_compressed);
  assign next_valid_si             = ((addr_o[3:2] != 2'b11) || next_upper_compressed_si) && (~next_is_crossword_si) && valid;
  assign fetch_possible_si         =  (addr_o[3:2] == 2'b11 );  
  assign addr_aligned_next_si      = { addr_o[31:2], 2'b00 } + 32'h4  ;
  assign addr_real_next_si         = next_is_crossword_si ? { addr_o[31:4], 4'b0000 } + 32'd16 : { addr_o[31:2], 2'b00 } + 32'h4 ;
  
 `ifndef HAMSA_DI  

  assign next_is_crossword     = next_is_crossword_si  ; 
  assign next_upper_compressed = next_upper_compressed_si ;
  assign next_valid            = next_valid_si ;      
  assign fetch_possible        = fetch_possible_si ;  
  assign addr_aligned_next     = addr_aligned_next_si ;
  assign addr_real_next        = addr_real_next_si ;   
  
`else // skip instruction in  case issue2 detected a valid instruction for execution ; handle DI cross-line


  logic        next_is_crossword_di     ;
  logic        next_upper_compressed_di ;

  logic        next_potential_is_crossword_di     ;
  logic        next_potential_upper_compressed_di ;
   
  logic        next_valid_di            ;
  logic        fetch_possible_di        ;     
  logic [31:0] addr_aligned_next_di     ;
  logic [31:0] addr_real_next_di        ;  

  logic next_potential_hw_idx_aligned ;


  assign next_potential_is_crossword_di     = (di_intrfc_pfb.next_potential_hw_idx==3'd7) && (~upper_is_compressed) ;  
  assign next_potential_upper_compressed_di = (di_intrfc_pfb.next_potential_hw_idx==3'd7) && (upper_is_compressed) ;

  assign next_potential_hw_idx_aligned = (di_intrfc_pfb.next_potential_hw_idx[2:0]==0); 

  //assign fetch_possible_di = next_potential_hw_idx_aligned // TODO check if ==0 is not limiting cross opportunities
  assign fetch_possible_di  = (addr_o[3:2] == 2'b11) ; // TMP EXPERIMENT , avoid fetch access dependency on rdata_o content, for performance  
  

  assign next_valid_di            = (!next_potential_hw_idx_aligned || next_potential_upper_compressed_di) && (~next_potential_is_crossword_di) && valid;

  assign next_is_crossword_di     = (di_intrfc_pfb.next_hw_idx==3'd7) && (~upper_is_compressed) ;  
  assign next_upper_compressed_di = (di_intrfc_pfb.next_hw_idx==3'd7) && (upper_is_compressed) ;

  assign addr_aligned_next_di     = {addr_o[31:4],4'b0000} + (di_intrfc_pfb.next_hw_idx[2:0]==0 ? 32'd16 : {di_intrfc_pfb.next_hw_idx[2:1],2'b00}) ;   
  
  //assign addr_real_next_di        = (next_is_crossword_di) ? { addr_o[31:4], 4'b0000 } + 32'd16 : addr_aligned_next_di ;
  assign addr_real_next_di        =  { addr_o[31:4], 4'b0000 } + 32'd16 ; // TMP EXPERIMENT - LOOKS OK
  
  


  logic i2_alloc_non_killed ;
    
  assign i2_alloc_non_killed  = di_intrfc_pfb.i2_instr_allocated && !pi_hwlp_di_prevent_cond ;


  assign fetch_possible        = i2_alloc_non_killed ?   fetch_possible_di        :   fetch_possible_si          ;     
  assign next_valid            = i2_alloc_non_killed ?   next_valid_di            :   next_valid_si              ;                                                                                                                     
  assign next_is_crossword     = i2_alloc_non_killed ?   next_is_crossword_di     :   next_is_crossword_si       ;
  assign next_upper_compressed = i2_alloc_non_killed ?   next_upper_compressed_di :   next_upper_compressed_si   ;
  assign addr_aligned_next     = i2_alloc_non_killed ?   addr_aligned_next_di     :   addr_aligned_next_si       ;
  assign addr_real_next        = i2_alloc_non_killed ?   addr_real_next_di        :   addr_real_next_si          ;   
  
`endif

  
  assign hwlp_unaligned_is_compressed = rdata_L0[2][17:16] != 2'b11;
  assign hwlp_aligned_is_compressed   = rdata_L0[3][1:0] != 2'b11;
  assign hwlp_is_crossword            = (hwloop_target_i[3:1] == 3'b111) && (~upper_is_compressed);

  logic [31:0] addr_int_si ;

  always_comb
  begin
    addr_int_si    = addr_o;

    // advance address when pipeline is unstalled
    if (ready_i) begin

      if (addr_o[1]) begin
        // unaligned case
        // always move to next entry in the FIFO

        if (unaligned_is_compressed) begin
          addr_int_si = { addr_aligned_next[31:2], 2'b00};
        end else begin
          addr_int_si = { addr_aligned_next[31:2], 2'b10};
        end

      end else begin
        // aligned case

        if (aligned_is_compressed) begin
          // just increase address, do not move to next entry in the FIFO
          addr_int_si = { addr_o[31:2], 2'b10 };
        end else begin
          // move to next entry in the FIFO
          addr_int_si = { addr_aligned_next[31:2], 2'b00 };
        end
      end

    end
    

    `ifndef HAMSA_DI  
       addr_int = addr_int_si ;
    `else            
        if (i2_alloc_non_killed)       
          //addr_int = (di_intrfc_pfb.next_hw_idx[2:0]==3'b0) ? 
          //         {addr_o[31:4],4'b0000} + 32'd16 : {addr_o[31:4],di_intrfc_pfb.next_hw_idx[2:0],1'b0} ;  
            addr_int = next_potential_hw_idx_aligned ?
                     {addr_o[31:4],4'b0000} + 32'd16 : {addr_o[31:4],di_intrfc_pfb.next_potential_hw_idx[2:0],1'b0} ;          
        else
            addr_int = addr_int_si ;       
    `endif                                                     
  end

  always_comb
  begin
    NS              = CS;
    do_fetch        = 1'b0;
    do_hwlp         = 1'b0;
    do_hwlp_int     = 1'b0;
    use_last        = 1'b0;
    use_hwlp        = 1'b0;
    save_rdata_last = 1'b0;
    save_rdata_hwlp = 1'b0;
    valid           = 1'b0;
    addr_n          = addr_int;
    is_hwlp_n       = is_hwlp_q;
    
   `ifdef HAMSA_DI
   // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case   
    do_sample_hwloop_target_for_wait = 1'b0 ;
   `endif    

    if (ready_i)
      is_hwlp_n = 1'b0;

    case (CS)
      IDLE: begin
        // wait here for something to happen
      end

      BRANCHED: begin
        valid    = 1'b0;
        do_fetch = fetch_possible; 
        
        if (fetch_valid && (~is_crossword)) valid = 1'b1;

        if (ready_i) begin
          if (hwloop_i) begin
            addr_n = addr_o; // keep the old address for now
            NS = HWLP_WAIT_GNT;
            
            `ifdef HAMSA_DI
            // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case   
             do_sample_hwloop_target_for_wait = 1'b1 ; 
            `endif    
            
          end else begin
            if (next_valid) begin
              if (fetch_gnt) begin
                save_rdata_last = 1'b1;
                NS = VALID_GRANTED;
              end else
                NS = VALID;
            end else if (next_is_crossword) begin
              if (fetch_gnt) begin
                save_rdata_last = 1'b1;
                NS = NOT_VALID_CROSS_GRANTED;
              end else begin
                NS = NOT_VALID_CROSS;
              end
            end else begin
              if (fetch_gnt)
                NS = NOT_VALID_GRANTED;
              else
                NS = NOT_VALID;
            end
          end
        end else begin
          if (fetch_valid) begin
            if (is_crossword) begin
              save_rdata_last = 1'b1;
              if (fetch_gnt)
                NS = NOT_VALID_CROSS_GRANTED;
              else
                NS = NOT_VALID_CROSS;
            end else begin
              if (fetch_gnt) begin
                save_rdata_last = 1'b1;
                NS = VALID_GRANTED;
              end else
                NS = VALID;
            end
          end
        end
      end

      NOT_VALID: begin
        do_fetch = 1'b1;

        if (fetch_gnt)
          NS = NOT_VALID_GRANTED;
      end

      NOT_VALID_GRANTED: begin
        valid   = fetch_valid;
        do_hwlp = hwloop_i;

        if (fetch_valid)
          NS = VALID;
      end

      NOT_VALID_CROSS:
      begin
        do_fetch = 1'b1;

        if (fetch_gnt)
        begin
          save_rdata_last = 1'b1;
          NS = NOT_VALID_CROSS_GRANTED;
        end
      end

      NOT_VALID_CROSS_GRANTED:
      begin
        valid    = fetch_valid;
        use_last = 1'b1;
        do_hwlp  = hwloop_i;

        if (fetch_valid)
        begin
          if (ready_i)
            NS = VALID;
          else
            NS = VALID_CROSS;
        end
      end

      VALID: begin
         valid    = 1'b1;
         do_fetch = fetch_possible;  // fetch_possible  =  addr_o[3:2] == 2'b11;
         do_hwlp  = hwloop_i;

         if (ready_i)
         begin
            if (next_is_crossword)
            begin
               do_fetch = 1'b1;

               if (fetch_gnt)
               begin
                  save_rdata_last = 1'b1;
                  NS = NOT_VALID_CROSS_GRANTED;
               end
               else // not fetching
               begin
                  NS = NOT_VALID_CROSS;
               end
            end
            else // Next is not crossword
               if (~next_valid)
               begin
                  if (fetch_gnt)
                     NS = NOT_VALID_GRANTED;
                  else
                     NS = NOT_VALID;
               end
               else // Next is valid
               begin
                  if (fetch_gnt)
                  begin
                     if (next_upper_compressed)
                     begin
                        save_rdata_last = 1'b1;
                        NS = VALID_GRANTED;
                     end
                  end
               end
         end
         else // NOT ready
         begin
            if (fetch_gnt)
               begin
                  save_rdata_last = 1'b1;
                  NS = VALID_GRANTED;
               end
         end
      end

      VALID_CROSS: begin
        valid    = 1'b1;
        use_last = 1'b1;
        do_hwlp  = hwloop_i;

        if (ready_i)
          NS = VALID;
      end

      VALID_GRANTED: begin
        valid    = 1'b1;
        use_last = 1'b1;
        do_hwlp  = hwloop_i;

        if (ready_i) begin
          if (fetch_valid) begin
            if (next_is_crossword)
              NS = VALID_CROSS;
            else if(next_upper_compressed) begin
              NS = VALID_FETCH_DONE;
            end
            else
              NS = VALID;
          end else begin
            if (next_is_crossword)
              NS = NOT_VALID_CROSS_GRANTED;
            else if (next_upper_compressed)
              NS = VALID_GRANTED;
            else
              NS = NOT_VALID_GRANTED;
          end
        end else begin
          if (fetch_valid) begin
            NS = VALID_FETCH_DONE;
          end
        end
      end

      VALID_FETCH_DONE: begin
        valid    = 1'b1;
        use_last = 1'b1;
        do_hwlp  = hwloop_i;

        if (ready_i) begin
          if (next_is_crossword)
            NS = VALID_CROSS;
          else if (next_upper_compressed) begin
            NS = VALID_FETCH_DONE; 
          end
          else
            NS = VALID;
        end
      end

      HWLP_WAIT_GNT: begin
        do_hwlp_int = 1'b1;

        if (fetch_gnt) begin
          is_hwlp_n = 1'b1;

         `ifndef HAMSA_DI          
          addr_n = hwloop_target_i;
         `else 
         // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case   
         addr_n = sampled_hwloop_target_for_wait ;
         `endif    
                    
          NS = BRANCHED;
        end
      end

      HWLP_GRANTED: begin
        valid    = 1'b1;
        use_hwlp = 1'b1;

        if (ready_i) begin
          addr_n = hwloop_target_i;

          if (fetch_valid) begin
            is_hwlp_n = 1'b1;

            if (hwlp_is_crossword) begin
              NS = NOT_VALID_CROSS;
            end else begin
              NS = VALID;
            end
          end else begin
            NS = HWLP_GRANTED_WAIT;
          end
        end else begin
          if (fetch_valid)
            NS = HWLP_FETCH_DONE;
        end
      end

      HWLP_GRANTED_WAIT: begin
        use_hwlp = 1'b1;

        if (fetch_valid) begin
          is_hwlp_n = 1'b1;

          if ( (addr_L0[3:1] == 3'b111) && (~upper_is_compressed)) begin
            NS = NOT_VALID_CROSS;
          end else begin
            NS = VALID;
          end
        end
      end

      HWLP_FETCH_DONE: begin
        valid    = 1'b1;
        use_hwlp = 1'b1;

        if (ready_i) begin
          is_hwlp_n = 1'b1;
          addr_n = hwloop_target_i;

          if (hwlp_is_crossword) begin
            NS = NOT_VALID_CROSS;
          end else begin
            NS = VALID;
          end
        end
      end
    endcase
    
               
    // branches always have priority
    if (branch_i) begin
      is_hwlp_n = 1'b0;
      addr_n    = addr_i;
      NS        = BRANCHED;

    end else if (hwloop_i) begin
      if (do_hwlp) begin
        if (ready_i) begin
          if (fetch_gnt) begin
            is_hwlp_n = 1'b1;
            addr_n = hwloop_target_i;
            NS = BRANCHED;
          end else begin
            addr_n = addr_o; // keep the old address for now
            NS = HWLP_WAIT_GNT;
            
            `ifdef HAMSA_DI
            // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case   
             do_sample_hwloop_target_for_wait = 1'b1 ;
            `endif    
            
          end
        end else begin
          if (fetch_gnt) begin
            save_rdata_hwlp = 1'b1;
            NS = HWLP_GRANTED;
          end
        end
      end
    end

        
  end

  

  //////////////////////////////////////////////////////////////////////////////
  // registers
  //////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n)
    begin
      addr_q         <= '0;
      is_hwlp_q      <= 1'b0;
      CS             <= IDLE;   
      rdata_last_q   <= '0;
    end
    else
    begin
      addr_q    <= addr_n;
      is_hwlp_q <= is_hwlp_n;

      CS <= NS;

      if (save_rdata_hwlp)
        rdata_last_q <= rdata_o;
      else if (save_rdata_last)
           begin
              //rdata_last_q <= rdata_L0[3];
              if(ready_i)
              begin
                   rdata_last_q <= rdata_L0[3];//rdata;
              end
              else
              begin
                   rdata_last_q <= rdata;//rdata;
              end
           end
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // output ports
  //////////////////////////////////////////////////////////////////////////////

  assign rdata_o = ((~addr_o[1]) || use_hwlp) ? rdata : rdata_unaligned;
  assign valid_o = valid & (~branch_i);

  assign addr_o = addr_q;

  assign is_hwlp_o = is_hwlp_q & (~branch_i);

  assign busy_o = busy_L0;

  //////////////////////////////////////////////////////////////////////////////
  // Dual-Issue Interface connections
  //////////////////////////////////////////////////////////////////////////////


  `ifdef HAMSA_DI 
     assign di_intrfc_pfb.instr_buf = rdata_L0 ;     // quad word buffer content
     assign di_intrfc_pfb.pi_hw_idx  = addr_o[3:1] ; // primary issue , instruction half-word index within the buffer
                                                     // Notice there are 8 16bit half-words within the 128 line buffer 
    
     // indexed primary word is valid, currently only simple aligned, non-hwloop setup instr 

     assign di_intrfc_pfb.pi_hw_idx_valid = valid_o && !(use_last || use_hwlp) ;  
          
    // Udi attempt to fix potential bug  , potentially relevant not only in HAMSA_DI case     
    always_ff @(posedge clk, negedge rst_n)
    if (~rst_n) sampled_hwloop_target_for_wait <= 32'b0 ;
    else begin
    if (do_sample_hwloop_target_for_wait) 
      sampled_hwloop_target_for_wait <= hwloop_target_i ; 
    end
    
  `endif


  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------
  `ifndef VERILATOR
    // there should never be a ready_i without valid_o
    assert property (
      @(posedge clk) (ready_i) |-> (valid_o) ) else $warning("IF Stage is ready without prefetcher having valid data");

    // never is_crossword while also next_is_crossword
    assert property (
      @(posedge clk) (next_is_crossword) |-> (~is_crossword) ) else $warning("Cannot have two crossword accesses back-to-back");
    assert property (
      @(posedge clk) (is_crossword) |-> (~next_is_crossword) ) else $warning("Cannot have two crossword accesses back-to-back");
  `endif
endmodule // prefetch_L0_buffer

