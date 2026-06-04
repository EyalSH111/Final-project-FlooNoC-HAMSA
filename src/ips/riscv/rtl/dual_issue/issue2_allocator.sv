
// Check primary instruction and potential  issue2 candidate and determines if issue2 allocation is allowed
// Notice this is currently performed in the Prefetch stage and utilizes a reduced decoder instantiation for both instructions for early decoding
// Notice currently only uncompressed instructions are allowed
// Notice this module is pure combinatorial.


module issue2_allocator (
 input		  di_en_i,
 input        in_line_ok,
 input [31:0] pi_instr,  // Primary Issue instruction
 input [31:0] i2_instr,
 input        pi_unusal_state_prevent_di,
 output       i2_instr_allocate_ok 
);


logic        pi_rega_used_dec               ;  
logic        pi_regb_used_dec               ;
logic        pi_regc_used_dec               ;
logic [5:0]  pi_regfile_addr_ra_id          ;
logic [5:0]  pi_regfile_addr_rb_id          ;
logic [5:0]  pi_regfile_addr_rc_id          ;
logic [5:0]  pi_regfile_waddr_id            ;
logic        pi_regfile_mem_we_dec          ;
logic        pi_regfile_alu_we_dec          ;
logic        pi_addr_ra_is_also_dst         ;
  

logic        i2_rega_used_dec               ;  
logic        i2_regb_used_dec               ;
logic        i2_regc_used_dec               ;
logic [5:0]  i2_regfile_addr_ra_id          ;
logic [5:0]  i2_regfile_addr_rb_id          ;
logic [5:0]  i2_regfile_addr_rc_id          ;
logic [5:0]  i2_regfile_waddr_id            ;
logic        i2_regfile_mem_we_dec          ;
logic        i2_regfile_alu_we_dec          ;
logic        i2_addr_ra_is_also_dst         ;

logic pi_regfile_std_dst_we ;
logic dual_issue_pi_legal_op ;
logic dual_issue_i2_legal_op ;


// Standard destination regs check
logic i2_src_rega_vs_pi_std_dst_ok ;
logic i2_src_regb_vs_pi_std_dst_ok ;
logic i2_src_regc_vs_pi_std_dst_ok ;

// Pulp extention post increment destination , using source reg-a also as a destination
logic i2_src_rega_vs_pi_pst_dst_ok ;
logic i2_src_regb_vs_pi_pst_dst_ok ;
logic i2_src_regc_vs_pi_pst_dst_ok ;

issue2_fetch_alloc_mini_decode pi_mini_decode ( 

  .instr                     ( pi_instr                    ), 
  .fregfile_disable_i        ( 1'b1                        ),
  .rega_used_dec             ( pi_rega_used_dec            ),
  .regb_used_dec             ( pi_regb_used_dec            ),
  .regc_used_dec             ( pi_regc_used_dec            ),
  .regfile_addr_ra_id        ( pi_regfile_addr_ra_id       ),
  .regfile_addr_rb_id        ( pi_regfile_addr_rb_id       ),
  .regfile_addr_rc_id        ( pi_regfile_addr_rc_id       ),
  .regfile_waddr_id          ( pi_regfile_waddr_id         ),
  .regfile_mem_we_dec        ( pi_regfile_mem_we_dec       ),
  .regfile_alu_we_dec        ( pi_regfile_alu_we_dec       ),
  .addr_ra_is_also_dst       ( pi_addr_ra_is_also_dst      ),
  .dual_issue_pi_legal_op_o  ( dual_issue_pi_legal_op      ),  
  .dual_issue_i2_legal_op_o  (                             )
);

issue2_fetch_alloc_mini_decode i2_mini_decode ( 

  .instr                     ( i2_instr                    ), 
  .fregfile_disable_i        ( 1'b1                        ),
  .rega_used_dec             ( i2_rega_used_dec            ),
  .regb_used_dec             ( i2_regb_used_dec            ),
  .regc_used_dec             ( i2_regc_used_dec            ),
  .regfile_addr_ra_id        ( i2_regfile_addr_ra_id       ),
  .regfile_addr_rb_id        ( i2_regfile_addr_rb_id       ),
  .regfile_addr_rc_id        ( i2_regfile_addr_rc_id       ),
  .regfile_waddr_id          ( i2_regfile_waddr_id         ),
  .regfile_mem_we_dec        ( i2_regfile_mem_we_dec       ),
  .regfile_alu_we_dec        ( i2_regfile_alu_we_dec       ),
  .addr_ra_is_also_dst       ( i2_addr_ra_is_also_dst      ),
  .dual_issue_pi_legal_op_o  (                             ), 
  .dual_issue_i2_legal_op_o  ( dual_issue_i2_legal_op      )  
);

assign pi_regfile_std_dst_we = pi_regfile_alu_we_dec || pi_regfile_mem_we_dec ; 

                                                    // ix_src_reg_id         , ix_src_reg_used ,  iy_dst_reg_id       , iy_dst_reg_used
assign i2_src_rega_vs_pi_std_dst_ok = reg_pair_is_ok ( i2_regfile_addr_ra_id , i2_rega_used_dec , pi_regfile_waddr_id , pi_regfile_std_dst_we  );
assign i2_src_regb_vs_pi_std_dst_ok = reg_pair_is_ok ( i2_regfile_addr_rb_id , i2_regb_used_dec , pi_regfile_waddr_id , pi_regfile_std_dst_we  );

// assign i2_src_regc_vs_pi_std_dst_ok = reg_pair_is_ok ( i2_regfile_addr_rc_id , i2_regc_used_dec , pi_regfile_waddr_id , pi_regfile_std_dst_we  );
assign i2_src_regc_vs_pi_std_dst_ok = 1'b1 ; // Currently I2 does not execute ISA extensions with 3 operands
                                                                                                                                                  
assign i2_src_rega_vs_pi_pst_dst_ok = reg_pair_is_ok ( i2_regfile_addr_ra_id , i2_rega_used_dec , pi_regfile_addr_ra_id , pi_addr_ra_is_also_dst );
assign i2_src_regb_vs_pi_pst_dst_ok = reg_pair_is_ok ( i2_regfile_addr_rb_id , i2_regb_used_dec , pi_regfile_addr_ra_id , pi_addr_ra_is_also_dst );

// assign i2_src_regc_vs_pi_pst_dst_ok = reg_pair_is_ok ( i2_regfile_addr_rc_id , i2_regc_used_dec , pi_regfile_waddr_id , pi_addr_ra_is_also_dst );
assign i2_src_regc_vs_pi_pst_dst_ok = 1'b1 ; // Currently I2 does not execute ISA extensions with 3 operands                                                                                                                                               

// it is mostly useless but yet legal to have two consecutive instructions with the same destination, 
// since the the first instruction can apparently be dropped (unless its some kind of forced IO address access or so)
// DI can prioritize the second instruction destination update if both are ALU operations
// However if the first instruction is a memory access operation, then prioretizing the second instruction is complex 
// as the memory write-back is delayed by one cycle and a stall is involved 
// Therefor we avoid DI allocation in such case  
 
logic  i2_dst_pi_std_dst_ok ;
//                                             ix_src_reg_id         , ix_src_reg_used       ,  iy_dst_reg_id       , iy_dst_reg_used
assign i2_dst_pi_std_dst_ok =  reg_pair_is_ok ( i2_regfile_waddr_id   , i2_regfile_alu_we_dec , pi_regfile_waddr_id  , pi_regfile_mem_we_dec  );


// Notice that memory-access post-incr/dec second destination is not applicable for i2                       
                      
  
assign i2_instr_allocate_ok  =    in_line_ok
                               && (!i2_regc_used_dec)       // Currently I2 does not execute ISA extensions with 3 operands
                               && dual_issue_pi_legal_op  
                               && dual_issue_i2_legal_op                               
                               && i2_src_rega_vs_pi_std_dst_ok 
                               && i2_src_regb_vs_pi_std_dst_ok 
                               && i2_src_regc_vs_pi_std_dst_ok 
                               && i2_src_rega_vs_pi_pst_dst_ok 
                               && i2_src_regb_vs_pi_pst_dst_ok 
                               && i2_src_regc_vs_pi_pst_dst_ok 
                               && i2_dst_pi_std_dst_ok 
                               && di_en_i
                               && !pi_unusal_state_prevent_di ; 


 // Check validity of accessing issue 'x' source reg vs issue 'y' dst reg 
 function reg_pair_is_ok(input [5:0] ix_src_reg_id , ix_src_reg_used , [5:0] iy_dst_reg_id , iy_dst_reg_used);
   logic reg_pair_conflict ;
   reg_pair_conflict = (ix_src_reg_used && iy_dst_reg_used)  &&  (ix_src_reg_id == iy_dst_reg_id) ;
   reg_pair_is_ok = ! reg_pair_conflict ;
 endfunction

endmodule
