/*
*   HAMSA 128bit Instruction-Fetch 
*   Interface compatible to riscv_prefetch_L0_buffer
*   Assumes HAMSA_DI configuration and availability of DI interfaces
*/

module hamsa_prefetch 

#(parameter L0_CACHE_DEPTH_LOG2=3,
  parameter IMEM_MASK          = 32'hfff_00000, // Added in-order to optimally distinguish between TCM and AXI access (eventually not used)
  parameter IMEM_BASE          = 32'h000_00000
)
(
  // General
  input  logic                                clk,
  input  logic                                rst_n,

  //  Instruction core interface level instr_* port , referred as here iport(See RI5CY spec for definition, same as LSU protocol)
  output logic                                iport_req_o,
  output logic [31:0]                         iport_addr_o,
  input  logic                                iport_gnt_i,
  input  logic                                iport_rvalid_i,
  input  logic [127:0]                        iport_rdata_i,  
  input                                       fence_flush_prefetch_i,
      
  input                                       misal_wr_inp_i, // Issue #4 fix, Udi 2-Feb-21, block fence re-fetch while LSU misalign write in progress.
  
  // Core's Instruction-Fetch stage interface , referred as ifs_*
  input  logic                                branch_i,           // Request to branch to addr_i
  input  logic [31:0]                         addr_i,             // requested branch address 
  input  logic                                hwloop_i,           // Request to branch to hwloop_target_i
  input  logic [31:0]                         hwloop_target_i,    // hwloop target address
  input  logic                                ready_i,            // IF stage is ready for fetching
  output logic                                valid_o,            // rdata_o is valid
  output logic [31:0]                         rdata_o,            // instr. data
  output logic [31:0]                         addr_o,             // address of the fetched rdata_o (qualified by valid_o)
  output logic                                is_hwlp_o,          // is set when the currently served rdata_o is from a hwloop
  output logic                                busy_o              // prefetcher is busy.
    
  // Dual-Issue Logic pfb (pref-fetch-buffer) interface
  ,di_pfb_interface.pi di_intrfc_pfb
  ,input pi_hwlp_di_prevent_cond 
);

 // Declarations
 localparam IDX_W = L0_CACHE_DEPTH_LOG2 ;
 localparam PF_BUF_NUM_LINES = 2**IDX_W ; // Number of lines in buffer , each line is 4 X 32b words
 
  typedef struct packed {
   logic [27-IDX_W:0] tag  ;   
   logic [IDX_W-1:0]  idx  ;     
   logic [3:0]        offset  ;
 } addr_t ;
 
 
 addr_t ifs_play_addr, ifs_addr_s, iport_addr_o_s, redirect_addr, cnsctv_line_addr, cnsctv_line_addr_d  ; 
 
 logic [31:0] ifs_instr_addr ;
 logic [31:0] iport_requested_addr ; 
 logic cnsctv_must_do_prefetch ;
 //logic do_prefetch_instr ; 
 logic ifs_hit ;
 logic match ;
 logic ifs_miss;
 logic ifs_get_instr ;
 logic ifs_fetch_consecutive  ;
 logic [7:0][15:0] line_data , line_data_d ;
 logic [31:0] ifs_cnsctv_instr_addr , ifs_instr_addr_di ;
 logic ifs_pend_iport_get_instr , ifs_pend_iport_get_instr_d  ;
 logic pending_gnt   ,  pending_gnt_d ;
 logic ifs_access_enable ; 
 logic iport_get_line ;
 logic rvalid_at_ifs_pending ;
 logic cnsctv_fetch_is_same_line ;
 logic redirect_at_rvalid_prefetch ;
 logic iport_pend_rvalid ;
 logic ifs_addr_is_xln;
 logic ifs_xln_not_avail , ifs_xln_not_avail_s ;
 logic ifs_xln_avail , ifs_xln_avail_s ;
 logic [15:0] prefetch_head_halfword  , prefetch_head_halfword_d ;
 logic [127:0] line_data_shift ;
 logic potential_valid_d , potential_valid ;
 logic ifs_addr_avail ;
 logic prefetch_avail ;
 logic rvalid_at_prefetch_pend ;
 logic ifs_pending_xln , ifs_pending_xln_d ;
 logic cnsctv_addr_at_rvalid_pref ;
 logic rdata_avail_at_rvalid ;
 logic prefetch_is_imem_addr ;
 logic ms_halfword_psbly_non_cmprs ;
 logic ms_halfword_addressed ;
 logic redirect_pend_avail  ;
 logic redirect_avail ;
 logic redirect_not_avail ; 
 logic redirected_to_xln ;
 logic di_idx_wrap ;
 logic sel_line_data_from_iport ;
 logic valid_but_stalled ;
 logic avoid_prefetch ;
 logic hit_at_branch ;   
 logic hit_at_redirect ;      
 logic rvalid_at_pend_xln  ;  
 logic iport_addr_atmpt_at_rvalid ;
 logic miss_at_redirect ;
 logic en_smp_line_data ;
 //logic ifs_access_pref_word_idx ;
 logic redirect ;
 logic match_redirect_addr ;      
 logic match_ifs_addr_s  ;  
 logic match_cnsctv_line_addr  ; 
 logic hwloop_pending , hwloop_pending_d ;
 logic hwlp_valid_sbjct_to_br ;
 logic hwloop_req_while_stalled ;
 logic cache_wr_en ;

 
 logic [7:0][15:0] match_current_addr_line_data ; 
 logic [7:0][15:0] match_redirect_addr_line_data ;  
 logic [7:0][15:0] match_cnsctv_addr_line_data ;
 logic [7:0][15:0] match_line_data ;
 logic not_first_ever_rvalid ;
 logic prior_first_branch ;

 logic redirected_hit_while_pend_prefetch , redirected_hit_while_pend_prefetch_d ;
 logic redirected_miss_while_pend_prefetch , redirected_miss_while_pend_prefetch_d ; 
 logic redirected_while_pend_prefetch ;
 
 logic current_line_valid ; // subject to fence
 logic ifs_rvalid ;
 logic hwlooped_while_pend_prefetch,hwlooped_while_pend_prefetch_d ;  
 logic [31:0] iport_atmpt_addr ; 
 logic hwloop_redirect_stalled , hwloop_redirect_stalled_s ; // TODO Check if similar mechanism is needed also for branch_i


 int i ; // general purpose finite index for looper
 
 //---------------------------------------------------------------------------------------------------------------------

 logic rvalid_at_pend_redirect_miss ;
 assign rvalid_at_pend_redirect_miss = redirected_miss_while_pend_prefetch && iport_rvalid_i ;

 logic rvalid_at_pend_hwlooped ;
 assign rvalid_at_pend_hwlooped = hwlooped_while_pend_prefetch && redirected_miss_while_pend_prefetch && iport_rvalid_i ;

 logic branched_while_pend_prefetch_d , branched_while_pend_prefetch ;
 logic branch_fetch_while_pend_prefetch_d , branch_fetch_while_pend_prefetch ;
 
 assign hwloop_redirect_stalled = hwloop_i && !ready_i ;
 always @(posedge clk,negedge rst_n) if (!rst_n) hwloop_redirect_stalled_s <= '0 ; else hwloop_redirect_stalled_s <= hwloop_redirect_stalled ;
 
 always_comb begin
   branched_while_pend_prefetch_d = branched_while_pend_prefetch ;
   branch_fetch_while_pend_prefetch_d = branch_fetch_while_pend_prefetch ;
   if (branch_i && iport_pend_rvalid) begin
      branched_while_pend_prefetch_d = 1 ;  
      if (!hit_at_branch) branch_fetch_while_pend_prefetch_d = 1 ; 
   end   
   if (iport_rvalid_i) begin
      branched_while_pend_prefetch_d = 0 ; 
      branch_fetch_while_pend_prefetch_d = 0 ; 
   end
 end 

 always @ (posedge clk, negedge rst_n) begin
   if (!rst_n)  begin
      branched_while_pend_prefetch <= 0 ;
      branch_fetch_while_pend_prefetch <= 0 ;   
   end else begin
      branched_while_pend_prefetch <= branched_while_pend_prefetch_d ;
      branch_fetch_while_pend_prefetch <= branch_fetch_while_pend_prefetch_d ;
   end
 end

 //---------------------------------------------------------------------------------------------------------------------
  
 // Buffer-Cache Instance
  
 //assign cache_wr_en = (iport_rvalid_i && (!branch_i || redirect_at_rvalid_prefetch)) && !fence_flush_prefetch_i ;  // TO DO SIMPLIFY  
 assign cache_wr_en = iport_rvalid_i && !fence_flush_prefetch_i ;  // TO DO CHECK IF AND WHY ABOVE PREVIOSLY NEEDED 

 hamsa_L0_cache #(.L0_CACHE_DEPTH_LOG2(L0_CACHE_DEPTH_LOG2)) i_hamsa_L0_cache (
 
   .clk(clk),
   .rst_n(rst_n),
   
   .wr_addr_i      (iport_addr_o_s),
   .wr_data_i      (iport_rdata_i),    
   .wr_enable_i    (cache_wr_en), // Per Udi's issue 40 fix
   
   .match_addr_a_i (ifs_addr_s),
   .match_a_o      (match_ifs_addr_s),
   .match_data_a_o (match_current_addr_line_data),
   
   .match_addr_b_i ({redirect_addr}),
   .match_b_o      ({match_redirect_addr}),
   .match_data_b_o ({match_redirect_addr_line_data}),
   
   .match_addr_c_i (cnsctv_line_addr),
   .match_c_o      (match_cnsctv_line_addr),
   .match_data_c_o (match_cnsctv_addr_line_data),
   
   .flush_cache    (fence_flush_prefetch_i)
 );


 assign {cnsctv_line_addr_d} = {ifs_play_addr[31:4]+28'd1,4'b0000} ; // calculated before sampling for better timing

 assign redirect_addr        = branch_i ? addr_i : hwloop_target_i ; // branch arriving at ID has priority over hwloop arriving at IF
  

 // Notice that though buffer match address selection are exclusive, for best synthesis outcome timing results
 // we check in parallel a match for all options and mux the result after DI fetcher in parallel determined next address
 
 enum logic [1:0] {MATCH_SEL_CURRENT, MATCH_REDIRECT_LINE, MATCH_CNSCTV_LINE} match_sel ; // For debug assistance only 
 
 always_comb begin
 
     match_sel = MATCH_SEL_CURRENT ; // default
     match = match_ifs_addr_s ;      // default
     match_line_data = match_current_addr_line_data ;
     
     if (redirect) begin
        match_sel = MATCH_REDIRECT_LINE ;
        match = match_redirect_addr ; 
        match_line_data = match_redirect_addr_line_data ;       
     end
     else if (ifs_xln_avail_s || di_idx_wrap) begin
        match_sel = MATCH_CNSCTV_LINE  ;
        match = match_cnsctv_line_addr ;
        match_line_data = match_cnsctv_addr_line_data ;
     end
 end
 
 assign ifs_hit   = ifs_get_instr &&  match ;
 assign ifs_miss  = ifs_get_instr && !match ;

 // redirect case Mainly separated for timing optimization, to avoid di dependent cache access path to instr memory (as above ifs_hit/ifs_miss do not propagate to memory with out sample)
 assign hit_at_branch    = branch_i &&  match_redirect_addr ;
 assign hit_at_redirect  = redirect &&  match_redirect_addr ;
 assign miss_at_redirect = redirect && !match_redirect_addr ;
 

 assign prefetch_is_imem_addr = (cnsctv_line_addr & IMEM_MASK) == IMEM_BASE;  // Prevent Prefetch over AXI in order to avoid abort in of branch prior to Prefetch completion.

 // Control Logic
 
 // Udi fix 21/Jan/21
 // assign redirect = branch_i || hwloop_i ;
 assign redirect = branch_i || (hwloop_i && ready_i) ; // hwloop_i is starched by if_stage logic if not ready, we redirect on hwloop only when ready
                                                       // This is especially required in cases of hwloop coming after branch 
 

 // notice that on branch we abandon a non ready access oppose to hwloop_i where we have to accomplish current access
 assign ifs_get_instr                = branch_i || ready_i  ;
 assign ifs_fetch_consecutive        = ready_i && !redirect ; // advance address as long as pipeline is not stalled or redirected  
 assign cnsctv_must_do_prefetch      = ifs_xln_not_avail || redirected_to_xln ;
 
 assign redirected_while_pend_prefetch = redirected_hit_while_pend_prefetch || redirected_miss_while_pend_prefetch ;
 
 assign rvalid_at_prefetch_pend      = iport_pend_rvalid && iport_rvalid_i && !fence_flush_prefetch_i ;                              

// Fix by Udi 20/Jan/21 , for hang detected by selfie5+interrupts rv32imxpulpv3 SI at riscv tag master_to_v0.8_hpf_fix
// assign redirect_at_rvalid_prefetch  = redirect && (addr_i==iport_addr_o_s) && rvalid_at_prefetch_pend ; 
assign redirect_at_rvalid_prefetch  = redirect && ({redirect_addr[31:4],4'b0000}==iport_addr_o_s) && rvalid_at_prefetch_pend ; 

   
 assign iport_addr_atmpt_at_rvalid = (iport_atmpt_addr==iport_addr_o_s) && iport_rvalid_i && !branch_i && !fence_flush_prefetch_i ;      

 logic force_redirect_fetch ;
 logic iport_access_in_progress ;
 
 always_comb begin    
   iport_access_in_progress = iport_pend_rvalid && !iport_rvalid_i ;
       
   avoid_prefetch =     ifs_pending_xln 
                     || redirect 
                     || match_cnsctv_line_addr                                      
                     || iport_addr_atmpt_at_rvalid                                               
                     || hwlooped_while_pend_prefetch 
                     || prior_first_branch ;

   // Udi: 20/Jan/21
   // hwloop_redirect_stalled_s condition noe longer needed as we redirect on hwloop_i onlt when ready
   //force_redirect_fetch = ((miss_at_redirect && !redirect_at_rvalid_prefetch) || rvalid_at_pend_redirect_miss || redirected_miss_while_pend_prefetch) !hwloop_redirect_stalled_s ;                     
   //force_redirect_fetch = ((miss_at_redirect && !redirect_at_rvalid_prefetch) || rvalid_at_pend_redirect_miss || redirected_miss_while_pend_prefetch) ;//&& !hwloop_redirect_stalled_s ; 
   // Udi 12/Feb/21 Simplified equivalent
   force_redirect_fetch = (miss_at_redirect && !redirect_at_rvalid_prefetch) || redirected_miss_while_pend_prefetch ;

   
   iport_get_line = !(iport_access_in_progress ||  iport_addr_atmpt_at_rvalid) && (force_redirect_fetch || !avoid_prefetch) ; 
 end
 

 assign ifs_rvalid  = iport_rvalid_i && !branch_i && !(redirected_while_pend_prefetch  && !hwloop_i && !iport_addr_atmpt_at_rvalid) ; 

 assign rvalid_at_ifs_pending        = ifs_pend_iport_get_instr && ifs_rvalid ;
 
 // Udi: 20/Jan/21 potential bug fix (by review) notice iport_addr_o_s is always line aligned
 // assign cnsctv_addr_at_rvalid_pref   = (ifs_cnsctv_instr_addr==iport_addr_o_s) && iport_rvalid_i && !branch_i && !hwloop_i && not_first_ever_rvalid && !fence_flush_prefetch_i  ; 
 assign cnsctv_addr_at_rvalid_pref   = ({ifs_cnsctv_instr_addr[31:4],4'b0000}==iport_addr_o_s) && iport_rvalid_i && !redirect && not_first_ever_rvalid && !fence_flush_prefetch_i  ; 
 
 assign rdata_avail_at_rvalid        = redirect_at_rvalid_prefetch || cnsctv_addr_at_rvalid_pref || rvalid_at_ifs_pending ;                                        
 assign redirect_avail               = redirect_pend_avail && potential_valid ;
 assign redirect_not_avail           = miss_at_redirect && !redirect_at_rvalid_prefetch ;
 assign ms_halfword_psbly_non_cmprs  = (line_data[7][1:0]==2'b11) ;
 assign ms_halfword_addressed        = (addr_o[3:1]==7) ;
 assign redirected_to_xln            = (redirect_avail && ms_halfword_psbly_non_cmprs && ms_halfword_addressed) && !branch_i ;  // kill active redirected on new branch

 // Udi: 20/Jan/21 fix
 //assign ifs_addr_is_xln = ifs_pending_xln || (valid_o && (di_intrfc_pfb.next_hw_idx==7) && ms_halfword_psbly_non_cmprs) ;
  assign ifs_addr_is_xln = ifs_pending_xln || (valid_o && (di_intrfc_pfb.next_hw_idx==7) && ms_halfword_psbly_non_cmprs && !redirect) ;

 assign prefetch_avail               = match_cnsctv_line_addr || rvalid_at_prefetch_pend  ;
 assign ifs_xln_not_avail            = ifs_addr_is_xln && !((match_cnsctv_line_addr || iport_addr_atmpt_at_rvalid)) && !branch_i ;  // TODO check if need to exclude also hwloop redirect.
 assign ifs_xln_avail                = ifs_addr_is_xln &&   (match_cnsctv_line_addr || iport_addr_atmpt_at_rvalid)  ; 

 
 logic redirect_to_ms_hw_not_avail ;
 assign redirect_to_ms_hw_not_avail = redirect_not_avail && (redirect_addr[3:0]==4'he) ;
 
 always_comb begin
  ifs_pending_xln_d = ifs_pending_xln ;

       if (branch_i)                                     ifs_pending_xln_d = 1'b0 ;   
  else if (ifs_xln_not_avail || redirected_to_xln)       ifs_pending_xln_d = 1'b1 ;
  else if (prefetch_avail)                               ifs_pending_xln_d = 1'b0 ;                                                              
 end
  
 // TODO LOCATE CODE PROPERLY
 always_comb begin
   hwlooped_while_pend_prefetch_d = hwlooped_while_pend_prefetch ;
   if (hwloop_i && iport_pend_rvalid) hwlooped_while_pend_prefetch_d = 1 ; 
   if (iport_rvalid_i) hwlooped_while_pend_prefetch_d = 0 ; 
 end 

 always @ (posedge clk, negedge rst_n) if (!rst_n)  hwlooped_while_pend_prefetch <= 0 ; else hwlooped_while_pend_prefetch <= hwlooped_while_pend_prefetch_d ;

 logic hwlooped_while_ifs_pend_iport,hwlooped_while_ifs_pend_iport_d ;

 always_comb begin
   hwlooped_while_ifs_pend_iport_d = hwlooped_while_ifs_pend_iport ;
   if (hwloop_i && ifs_pend_iport_get_instr) hwlooped_while_ifs_pend_iport_d = 1 ;  
   if (iport_rvalid_i) hwlooped_while_ifs_pend_iport_d = 0 ;
 end 

 always @ (posedge clk, negedge rst_n) if (!rst_n)  hwlooped_while_ifs_pend_iport <= 0 ; else hwlooped_while_ifs_pend_iport <= hwlooped_while_ifs_pend_iport_d ; 
 // END TODO LOCATE CODE PROPERLY
 
 logic valid_but_stalled_s;
 always @ (posedge clk, negedge rst_n) if (!rst_n)  valid_but_stalled_s <= 0 ; else valid_but_stalled_s <= valid_but_stalled ; 

 // TODO: justify why condition_valid_o by hwlooped_while_pend_prefetch and not hwlooped_while_ifs_pend_iport / 'redirected_while_pend_prefetch'
  
 //assign valid_o = (valid_but_stalled_s && !branch_i) || (potential_valid  && !branch_i && !ifs_pending_xln  && !redirected_to_xln && !hwlooped_while_pend_prefetch) ;  // ok ref
 // NOTICE! To avoid complexity we currently prevent redirected_while_pend_prefetch to further progress till rvalid even if the instructions following redirected are in cache.
 assign valid_o = (valid_but_stalled_s && !branch_i) || (potential_valid  && !branch_i && !ifs_pending_xln  && !redirected_to_xln && !redirected_while_pend_prefetch) ;  
  
 // Control Outputs
 
 // Issue #4 fix, Udi 2-Feb-21, block fence re-fetch while LSU misalign write in progress.
 logic fence_redirect_at_lsu_misal_wr ;
 logic pending_fence_redirect ;
 logic relase_pending_fence_redirect ;
 logic [31:0] pending_fence_redirect_addr ;

 assign fence_redirect_at_lsu_misal_wr = fence_flush_prefetch_i && branch_i && misal_wr_inp_i ;
 assign relase_pending_fence_redirect = pending_fence_redirect && !misal_wr_inp_i ;
 
 always @ (posedge clk, negedge rst_n) begin
   if (!rst_n) begin
      pending_fence_redirect <= 0 ; 
      pending_fence_redirect_addr <= '0 ;      
   end
   else begin
     if (fence_redirect_at_lsu_misal_wr) begin
        pending_fence_redirect <= 1 ; 
        pending_fence_redirect_addr <= addr_i ; 
     end        
     if (relase_pending_fence_redirect) pending_fence_redirect <= 0 ;
   end  
 end 
 
 
 //assign iport_req_o = pending_gnt || iport_get_line  ;
 assign iport_req_o = pending_gnt || (iport_get_line && !fence_redirect_at_lsu_misal_wr) || relase_pending_fence_redirect ;
 
 assign busy_o      = iport_req_o || ifs_pend_iport_get_instr ;
 
 
 // Control pre-Sample logic


 assign ifs_pend_iport_get_instr_d = !hit_at_branch  && !cnsctv_addr_at_rvalid_pref 
                                        && (ifs_miss || (hwlooped_while_pend_prefetch && iport_rvalid_i)
                                            || (ifs_pend_iport_get_instr && !(iport_rvalid_i && !branched_while_pend_prefetch))) ;                                     

 
 assign pending_gnt_d = iport_req_o && !iport_gnt_i; 

 // Notice hwloop_i is issued at IF stage oppose to branch_i issued at ID stage
 // Therefor we do not prevent valid_o on hwloop_i
 // Also notice that in-case of hwloop_i we do validate ad execute current instruction, 
 // while in the case of branch_i we block it.

 assign hwlp_valid_sbjct_to_br  = valid_o && !valid_but_stalled && hwloop_pending ;

 always_comb begin
  hwloop_pending_d = hwloop_pending ;
  if (hwloop_i && ready_i) hwloop_pending_d = '1 ; 
  else if (branch_i || (ready_i && hwloop_pending)) hwloop_pending_d =  '0 ;
 end
 
 assign is_hwlp_o   = hwlp_valid_sbjct_to_br && (~branch_i);  

 logic branch_not_avail ;
 logic abort_ifs_access_due_to_hwloop ;
 logic ifs_access_avail ;
 logic abort_ifs_access ;
 logic cnsctv_at_same_line_avail ;
 
 always_comb begin 
    cnsctv_at_same_line_avail = cnsctv_fetch_is_same_line && current_line_valid && !fence_flush_prefetch_i ;
    ifs_addr_avail = (ifs_hit || rdata_avail_at_rvalid || cnsctv_at_same_line_avail) && !ifs_xln_not_avail ;
    rvalid_at_pend_xln = ifs_pending_xln && rvalid_at_prefetch_pend  && !branch_i ;
    branch_not_avail = redirect_not_avail && branch_i ;  // TODO reduce to root signals

    abort_ifs_access_due_to_hwloop = hwlooped_while_pend_prefetch && !hwlooped_while_ifs_pend_iport ; // TODO reduce to root signals
  
    ifs_access_avail = ifs_addr_avail || rvalid_at_pend_xln || ifs_xln_avail_s || (iport_addr_atmpt_at_rvalid && rvalid_at_pend_redirect_miss);
    
    abort_ifs_access = branch_not_avail || abort_ifs_access_due_to_hwloop  ;
    ifs_access_enable = hit_at_redirect || (!abort_ifs_access && ifs_access_avail) ;   
 end
 
 assign potential_valid_d = ifs_access_enable ? 1'b1 : ((ready_i || redirect) ? 0 : potential_valid) ; 
 assign hwloop_req_while_stalled =  hwloop_i && !ready_i ; 
 
 always_comb begin
   redirected_hit_while_pend_prefetch_d = redirected_hit_while_pend_prefetch ;
   if (hit_at_redirect && iport_pend_rvalid) redirected_hit_while_pend_prefetch_d = 1 ; // OK
   if (iport_rvalid_i) redirected_hit_while_pend_prefetch_d = 0 ; 
 end 
 
 always_comb begin
   redirected_miss_while_pend_prefetch_d = redirected_miss_while_pend_prefetch ;
   if (miss_at_redirect && iport_pend_rvalid) redirected_miss_while_pend_prefetch_d = 1 ; // OK
   if (iport_rvalid_i) redirected_miss_while_pend_prefetch_d = 0 ; 
 end 
  
 // Rearranged by Udi 21/Jan/21
 logic redirect_pend_avail_d ;
 always_comb begin
     redirect_pend_avail_d = redirect_pend_avail ;
     //if (redirect_avail) redirect_pend_avail_d  = '0 ; else if (redirect &&!hwloop_req_while_stalled ) redirect_pend_avail_d = '1 ; 
     if (redirect &&!hwloop_req_while_stalled ) redirect_pend_avail_d = '1 ; else if (redirect_avail) redirect_pend_avail_d  = '0 ;  
 end
  
 // Control Sequential 
 always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      pending_gnt                  <= '0 ;
      ifs_pend_iport_get_instr     <= '0 ;
      iport_pend_rvalid         <= '0 ;
      ifs_xln_avail_s              <= '0 ;
      ifs_xln_not_avail_s          <= '0 ;      
      potential_valid              <= '0 ;
      ifs_pending_xln              <= '0 ; 
      redirect_pend_avail          <= '0 ;  
      hwloop_pending               <= '0 ;
      not_first_ever_rvalid        <= '0 ;
      prior_first_branch           <= '1 ;
      redirected_hit_while_pend_prefetch <= 0 ;
      redirected_miss_while_pend_prefetch <= 0 ;      
      
    end else begin 
      ifs_pend_iport_get_instr     <= ifs_pend_iport_get_instr_d ;
      pending_gnt                  <= pending_gnt_d ;
      potential_valid              <= potential_valid_d ;
      
      if (!valid_but_stalled) begin
        ifs_xln_not_avail_s          <= ifs_xln_not_avail ;
        ifs_pending_xln              <= ifs_pending_xln_d ;
      end
      
      hwloop_pending               <= hwloop_pending_d ; 
      redirected_hit_while_pend_prefetch <= redirected_hit_while_pend_prefetch_d ; 
      redirected_miss_while_pend_prefetch <= redirected_miss_while_pend_prefetch_d ;       
            
      if (iport_rvalid_i) not_first_ever_rvalid   <= '1 ;
      if (branch_i) prior_first_branch            <= '0 ;

      if (iport_get_line) iport_pend_rvalid <= 1 ; else if (iport_rvalid_i && !iport_get_line) iport_pend_rvalid  <= '0 ; 

      redirect_pend_avail <= redirect_pend_avail_d ;    
      if (!valid_but_stalled) ifs_xln_avail_s   <= ifs_xln_avail ;         
    end
 end
 
 // Data/Address paths logic
 
 // Next fetch address (non-redirect) 
 assign di_idx_wrap = ({di_intrfc_pfb.next_hw_idx[2:0],1'b0} < ifs_addr_s[3:0]);
 
 assign ifs_instr_addr_di = di_idx_wrap ? {ifs_addr_s[31:4]+1,di_intrfc_pfb.next_hw_idx,1'b0} 
                                             : {ifs_addr_s[31:4]  ,di_intrfc_pfb.next_hw_idx,1'b0} ;
 
 always_comb begin 
    if (ifs_xln_avail_s && !redirect_avail) begin
        ifs_cnsctv_instr_addr  =  {ifs_addr_s[31:4]+28'd1,4'b0010} ;
        cnsctv_fetch_is_same_line = '0 ;
    end else if  (ifs_xln_not_avail_s || ~valid_o) begin
        ifs_cnsctv_instr_addr  = ifs_addr_s ;  // REPLAY till availability
        cnsctv_fetch_is_same_line = '0 ;
    end else begin
       ifs_cnsctv_instr_addr = ifs_instr_addr_di ; // Notice currently DI is not applied at cross-line
       cnsctv_fetch_is_same_line = ifs_fetch_consecutive && !di_idx_wrap  ; 
    end      
 end
 
  
 assign ifs_instr_addr = redirect ? redirect_addr : ifs_cnsctv_instr_addr ;

 assign {ifs_play_addr}        = ifs_get_instr  ? ifs_instr_addr : {ifs_addr_s} ; 

 
 assign iport_atmpt_addr = relase_pending_fence_redirect ? {pending_fence_redirect_addr[31:4],4'b0000} :
                           (miss_at_redirect ?  {redirect_addr[31:4],4'b0000} :  
                           ((redirected_while_pend_prefetch && ifs_pend_iport_get_instr) ? {ifs_addr_s[31:4],4'b0000}  : cnsctv_line_addr))  ;  

 assign iport_addr_o  = (pending_gnt) ? iport_requested_addr : iport_atmpt_addr ; // attempt 


// Data/Address outputs
 assign addr_o          = ifs_addr_s ;
 assign line_data_shift = line_data >> ifs_addr_s.offset*8  ; // shift to select and pad zeros (for top compressed case)

 assign rdata_o = (ifs_xln_avail_s && !redirect_avail) ? {prefetch_head_halfword,line_data[7]} : line_data_shift[31:0] ;
 
 // Data/Address pre-sample logic // TODO - Consider changing default to iport
 //assign sel_line_data_from_iport   = rvalid_at_ifs_pending || redirect_at_rvalid_prefetch || cnsctv_addr_at_rvalid_pref || iport_addr_atmpt_at_rvalid ;         
 assign sel_line_data_from_iport   = rvalid_at_ifs_pending || redirect_at_rvalid_prefetch || cnsctv_addr_at_rvalid_pref || (iport_addr_atmpt_at_rvalid && ifs_pend_iport_get_instr) ;         




 assign line_data_d                = sel_line_data_from_iport ? iport_rdata_i : match_line_data  ; 

 assign prefetch_head_halfword_d   = match_cnsctv_line_addr ? match_cnsctv_addr_line_data[0] : iport_rdata_i[15:0] ;
 assign valid_but_stalled          = valid_o && !ready_i ;

 assign en_smp_line_data = !(valid_but_stalled  || cnsctv_fetch_is_same_line || ifs_xln_avail || redirected_to_xln || (ifs_pending_xln && !branch_i) || (redirected_hit_while_pend_prefetch && !redirect && !ifs_hit)) ;

 
 // Data/Addr Sequential 
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      iport_requested_addr   <= '0 ;
      iport_addr_o_s         <= '0 ;       
      ifs_addr_s             <= '0 ; 
      cnsctv_line_addr       <= '0 ;
      prefetch_head_halfword <= '0 ;
      line_data              <= '0 ;
      current_line_valid     <= '0 ;         
    end else begin 
      ifs_addr_s       <= ifs_play_addr ; 
      
      cnsctv_line_addr <= cnsctv_line_addr_d ; // calculated before sampling for better timing

      if (iport_req_o)       iport_requested_addr    <= iport_addr_o ;       
      if (iport_req_o && iport_gnt_i) iport_addr_o_s <= iport_addr_o ;  // most recent granted address (Tzachi's issue #39 fix)  
      if (ifs_xln_avail) prefetch_head_halfword      <= prefetch_head_halfword_d ;

      if (en_smp_line_data)  begin
          line_data <= line_data_d ;
          current_line_valid <= '1 ;
      end
      
      if (fence_flush_prefetch_i) current_line_valid <= '0 ;
      
    end
  end
 
 // DI Interface
 assign di_intrfc_pfb.instr_buf       = line_data ;   // quad word buffer content
 assign di_intrfc_pfb.pi_hw_idx       = addr_o[3:1] ; // primary issue , instruction half-word index within the buffer
 assign di_intrfc_pfb.pi_hw_idx_valid = valid_o ;     // Notice there are 8 16bit half-words within the 128 line buffer 
       
endmodule 
