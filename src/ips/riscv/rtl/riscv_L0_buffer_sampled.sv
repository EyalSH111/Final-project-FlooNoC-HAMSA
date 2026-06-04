
module riscv_L0_buffer_sampled
#(
  parameter                                   RDATA_IN_WIDTH = 128
)
(
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                prefetch_i,
  input  logic [31:0]                         prefetch_addr_i,

  input  logic                                branch_i,
  input  logic [31:0]                         branch_addr_i,

  input  logic                                hwlp_i,
  input  logic [31:0]                         hwlp_addr_i,

  output logic                                fetch_gnt_o,
  output logic                                fetch_valid_o,

  output logic [RDATA_IN_WIDTH/32-1:0][31:0]  rdata_o,
  output logic [31:0]                         addr_o,

  // goes to instruction memory / instruction cache
  output logic                                instr_req_o,
  output logic [31:0]                         instr_addr_o,
  input  logic                                instr_gnt_i,
  input  logic                                instr_rvalid_i,
  input  logic [RDATA_IN_WIDTH/32-1:0][31:0]  instr_rdata_i,

  output logic                                busy_o
);

  enum logic [2:0] { EMPTY, VALID_L0, WAIT_GNT, WAIT_RVALID, ABORTED_BRANCH } CS, NS;

`ifdef L0_QBUF
  logic [1:0] active_buf_idx ;
  logic [1:0] dst_buf_idx;
  logic [3:0][3:0][31:0] L0_buffer;  // 4 line buffers each of 4  31b words
  logic [3:0] fetch_found_at_buf ;
  logic [1:0] fetch_found_at_buf_idx ;  
  logic [3:0][31:0] addr_at_buf ;
`else
  logic        active_buf_idx ;
  logic        dst_buf_idx;
  logic [1:0][3:0][31:0] L0_buffer;  // 2 line buffers each of 4  31b words
  logic [1:0] fetch_found_at_buf ;
  logic fetch_found_at_buf_idx ;  
  logic [1:0][31:0] addr_at_buf ;
`endif


  logic  [31:0]  addr_q, instr_addr, instr_addr_int;

  logic fetch_req ;
  logic instr_rvalid_i_q  ;
  logic inbuf_access_ok ;  

  logic prefetch_q ;
  logic hwlp_q ;
  logic branch_q ;
  logic fetch_req_q ;
  logic fsm_branch_req ;
  logic fsm_hwlp_req ;
  logic fsm_prefch_req ;
  logic fsm_fetch_valid ;
  logic fsm_fetch_req;
  logic fsm_rvalid ;
  logic fsm_instr_gnt;
  logic fsm_instr_req ;
  
  logic hwlp_after_prefetch_req ; 
  logic prefetch_after_hwlp_req ;   
  logic branch_after_prefetch_req ;     
  logic prefetch_after_branch_req ; 
  logic prefetch_after_prefetch_req ;
  
  logic predicted_fetch_req ;
  logic predicted_fetch_pending_gnt ;
    
  logic [31:0] predicted_fetch_addr ;
  logic [31:0] ifstage_instr_addr ; 
 
  logic inbuf_fetch_valid ;   
  
  //logic  kill_predicted_fetch ; <<<<<< needs to be carefully managed sampled propogted ...
   
  localparam REQ_TYPE_QUE_SIZE_L2 = 2 ;
  localparam REQ_TYPE_QUE_SIZE= 2**REQ_TYPE_QUE_SIZE_L2 ;  
  
  logic [REQ_TYPE_QUE_SIZE-1:0]    req_type_que ;
  logic [REQ_TYPE_QUE_SIZE_L2-1:0] req_type_que_in_ptr ;
  logic [REQ_TYPE_QUE_SIZE_L2-1:0] req_type_que_out_ptr ;
  logic                            rvalid_is_of_predicted ; 
  
  logic cs_is_abort_branch ; // not used, added for debug only
  
  logic not_pending_rvalid ; // Condition added to Greentree instr_req_o deassertion upon grant
  
  assign rvalid_is_of_predicted = req_type_que[req_type_que_out_ptr] && instr_rvalid_i ;
  
     
  assign fetch_req = branch_i || hwlp_i || prefetch_i ;
  
  assign ifstage_instr_addr = branch_i   ? branch_addr_i : (
                              hwlp_i     ? hwlp_addr_i   :   
                                           prefetch_addr_i );

  //assign predicted_fetch_addr = predicted_fetch_pending_gnt ? {addr_q[31:4],4'b0000} : 
  //                              (|fetch_found_at_buf[1:0] ? {ifstage_instr_addr[31:4],4'b0000} : 
  //                              {addr_q[31:4],4'b0000}) + 32'd16 ;                                                                              

  assign predicted_fetch_addr = predicted_fetch_pending_gnt ? {addr_q[31:4],4'b0000} : {addr_q[31:4],4'b0000} + 32'd16 ;                                                                              


  assign instr_addr =  fetch_req ? ifstage_instr_addr  : predicted_fetch_addr ;

  always_comb begin 
  
     fetch_found_at_buf = '0 ;
  
     //if  (fetch_req) begin
     
       fetch_found_at_buf[0] = (addr_at_buf[0][31:4]==instr_addr[31:4]) ;
       fetch_found_at_buf[1] = (addr_at_buf[1][31:4]==instr_addr[31:4]) ;  

      `ifdef L0_QBUF
       fetch_found_at_buf[2] = (addr_at_buf[2][31:4]==instr_addr[31:4]) ;
       fetch_found_at_buf[3] = (addr_at_buf[3][31:4]==instr_addr[31:4]) ;         
      `endif
     //end
       if (instr_rvalid_i) fetch_found_at_buf[dst_buf_idx] = (addr_q[31:4]==instr_addr[31:4]) ;
                 
       /// <<<<<<< TODO , KILL prediction strobe on later branch ....... >>>>>>>>>>>>>>                
     //end
  end 
 
`ifdef L0_QBUF 
  assign fetch_found_at_buf_idx = fetch_found_at_buf[0] ? 2'd0 : (
                                  fetch_found_at_buf[1] ? 2'd1 : (
                                  fetch_found_at_buf[2] ? 2'd2 : 2'd3 ));                                   
`else
  assign fetch_found_at_buf_idx = fetch_found_at_buf[1] ; // by default its buf 0 
`endif 

 logic consecutive_req ; 
 assign consecutive_req  =   hwlp_after_prefetch_req 
                          || prefetch_after_hwlp_req
                          || prefetch_after_branch_req 
                          || branch_after_prefetch_req 
                          || prefetch_after_prefetch_req ; 
                          
  assign inbuf_access_ok =    fetch_req   
                           && |fetch_found_at_buf  // |fetch_found_at_buf[1:0] 
                           && (inbuf_fetch_valid || !consecutive_req);
 
  assign fsm_fetch_req =  fetch_req && !inbuf_access_ok     ;   


  //assign predicted_fetch_req = 0 ; // TMP  
  //assign predicted_fetch_req = (fetch_req_q && !fsm_fetch_req && !fsm_instr_req) || predicted_fetch_pending_gnt ;
 
 assign not_pending_rvalid = (CS!=WAIT_RVALID)|| instr_rvalid_i ; // Condition added to Greentree instr_req_o deassertion upon grant

// assign predicted_fetch_req =    predicted_fetch_pending_gnt  
//                              || ( not_pending_rvalid && fetch_req_q && !fsm_fetch_req && !fsm_instr_req) ;

 assign predicted_fetch_req =    predicted_fetch_pending_gnt  
                              || ( not_pending_rvalid && fetch_req_q && !fsm_fetch_req && !fsm_instr_req  &&!(|fetch_found_at_buf)) ;

          
  assign hwlp_after_prefetch_req = prefetch_q && hwlp_i ;         // Both should be executed
  assign prefetch_after_hwlp_req = hwlp_q && prefetch_i ;         // Both should be executed
  assign branch_after_prefetch_req = prefetch_q && branch_i ;     // Both should be executed 
  assign prefetch_after_prefetch_req = prefetch_q && prefetch_i ; // Both should be executed   
  assign prefetch_after_branch_req = branch_q && prefetch_i ;     // Abort prefeth
    
  assign fsm_branch_req = branch_i    && !inbuf_access_ok  ;
  assign fsm_hwlp_req   = hwlp_i      && !inbuf_access_ok  ;
  assign fsm_prefch_req = prefetch_i  && !inbuf_access_ok  ;  
  assign fsm_instr_gnt  = instr_gnt_i && !inbuf_access_ok  &&!predicted_fetch_req ;
    
  assign fsm_rvalid = instr_rvalid_i_q ;
    
  //////////////////////////////////////////////////////////////////////////////
  // FSM
  //////////////////////////////////////////////////////////////////////////////

  always_comb
  begin
        
    instr_addr_int = predicted_fetch_req ? predicted_fetch_addr : ifstage_instr_addr ;

`ifdef L0_QBUF
    dst_buf_idx =  active_buf_idx+1;  
`else
    dst_buf_idx =  ~active_buf_idx  ;  // same as active_buf_idx+1 
`endif 
   
    NS             = CS;
    fsm_instr_req    = 1'b0;
    fsm_fetch_valid  = 1'b0;
    cs_is_abort_branch = 1'b0 ; // not used, added for debug only

    case(CS)

      EMPTY:
      begin
        if (fsm_fetch_req) 
        begin
          fsm_instr_req    = 1'b1;
          NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
          //ns_is_of_predicted = predicted_fetch_req ;
        end
      end //~EMPTY

      WAIT_GNT:
      begin
       fsm_instr_req    = 1'b1;
       NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
      end //~WAIT_GNT

      WAIT_RVALID:
      begin      
        if (fsm_branch_req) begin        
          if (fsm_rvalid) begin            
            fsm_fetch_valid  = 1'b1;
            fsm_instr_req    = 1'b1;
            NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
          end else NS = ABORTED_BRANCH; 
        end else begin
          if (fsm_rvalid) begin
             fsm_fetch_valid = 1'b1;
             if (fsm_prefch_req | fsm_hwlp_req) begin
                 fsm_instr_req = 1'b1;
                 NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
             end else NS = VALID_L0;                         
          end
        end
      end //~WAIT_RVALID

      VALID_L0:
      begin
        if (fsm_fetch_req)
        begin
           fsm_instr_req    = 1'b1;
           NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
           //ns_is_of_predicted = predicted_fetch_req ;
        end
      end //~VALID_L0

      ABORTED_BRANCH:
      begin

        // Udi's ABORTED_BRANCH state understanding ... : 
        // branch request arrived while a previous fetch request is waiting for rvalid which did not arrive
        // In such case we skip the next rvalid once arriving and wait for the latest branch grant/rvalid

        // prepare address even if we don't need it
        // this removes the dependency for instr_addr_o on instr_rvalid_i_q

        cs_is_abort_branch = 1'b1 ; // not used, added for debug only
        
        if (!fsm_branch_req) instr_addr_int = addr_q;

        if (fsm_rvalid)
        begin
          fsm_instr_req    = 1'b1;
          NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
          //ns_is_of_predicted = '0 ; // predicted_fetch_req ;
          //kill_predicted_fetch = 1'b1 ;
        end
      end //~ABORTED_BRANCH

      default:
      begin
         NS = EMPTY;
      end
    endcase //~CS
  end

  logic fsm_fetch_valid_equiv ;
  assign fsm_fetch_valid_equiv = (CS==WAIT_RVALID) & fsm_rvalid ;
  


  //////////////////////////////////////////////////////////////////////////////
  // registers
  //////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n)
    begin
      CS                <= EMPTY;
      L0_buffer         <= '0;
      addr_q            <= '0;
      instr_rvalid_i_q  <= '0;
      addr_at_buf       <= '0; 
      inbuf_fetch_valid <= '0;
      prefetch_q        <= '0;
      hwlp_q            <= '0;
      branch_q          <= '0;
      fetch_req_q       <= '0;
      active_buf_idx    <= '0;      
      predicted_fetch_pending_gnt <= '0 ;

      req_type_que <= '0  ;
      req_type_que_in_ptr <= '0 ;
      req_type_que_out_ptr <= '0 ;
      
    end else begin
     
      CS <= NS;

      if (instr_rvalid_i)  
      begin
        L0_buffer[dst_buf_idx] <= instr_rdata_i;
        addr_at_buf[dst_buf_idx] <= {addr_q[31:4],4'b0000} ;     
      end
            
      if (inbuf_access_ok) active_buf_idx <= fetch_found_at_buf_idx  ;             
      else if (instr_rvalid_i && !rvalid_is_of_predicted) active_buf_idx <= dst_buf_idx ;  
                  
      prefetch_q <= prefetch_i ;
      hwlp_q <= hwlp_i ;      
      branch_q   <= branch_i ;
      fetch_req_q <= fetch_req ;
            
      inbuf_fetch_valid <= inbuf_access_ok ;
      
      if (fetch_req) 
         addr_q <= ifstage_instr_addr ;      
      else if (predicted_fetch_req) 
         addr_q <= predicted_fetch_addr ; 
       
                 
      instr_rvalid_i_q <= instr_rvalid_i && !rvalid_is_of_predicted ; 
            
      if (instr_gnt_i || fsm_fetch_req || fsm_instr_req) // deassert prediction req incase of grant or non predicted req
        predicted_fetch_pending_gnt <= 1'b0 ;
      else if (predicted_fetch_req) 
        predicted_fetch_pending_gnt <= 1'b1 ;    
      //cs_is_of_predicted <= ns_is_of_predicted ;
      
      
      if (instr_req_o && instr_gnt_i) begin
        req_type_que[req_type_que_in_ptr] <= predicted_fetch_req  ;
        req_type_que_in_ptr <= (req_type_que_in_ptr+1) ; 
      end  
      if (instr_rvalid_i) begin
        req_type_que_out_ptr <= (req_type_que_out_ptr+1) ; 
      end  
            
    end
  end

 
  //////////////////////////////////////////////////////////////////////////////
  // output ports
  //////////////////////////////////////////////////////////////////////////////

  assign instr_req_o = fsm_instr_req || predicted_fetch_req;
  assign instr_addr_o = { instr_addr_int[31:4], 4'b0000};
  assign rdata_o = L0_buffer[active_buf_idx];  
  assign addr_o  = addr_q; // Looks as addr_o this is used only for PMP/Security compile option
  assign busy_o = (CS != EMPTY) && (CS != VALID_L0) || instr_req_o;
  assign fetch_gnt_o   = (fsm_instr_gnt || inbuf_access_ok)  ;

  //assign fetch_valid_o = fsm_fetch_valid || inbuf_fetch_valid ; // GOOD
  assign fetch_valid_o = fsm_fetch_valid_equiv || inbuf_fetch_valid ;

  
endmodule