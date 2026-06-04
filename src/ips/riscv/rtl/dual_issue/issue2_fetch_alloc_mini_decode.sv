
// Perform minimal decoding of instructions for issue2 fetcher allocator  decision making

import riscv_defines::*;


// Source/Destination register instruction index
`define REG_S1 19:15
`define REG_S2 24:20
`define REG_S4 31:27
`define REG_D  11:07

module  issue2_fetch_alloc_mini_decode

#(
  parameter FPU               =  0,
  parameter Zfinx             =  0
)

( 

  input [31:0] instr,
  input        fregfile_disable_i,   // Indicate id primary issue FPU is applied
     
  output        rega_used_dec,
  output        regb_used_dec,
  output        regc_used_dec,

  output       [5:0]  regfile_addr_ra_id,
  output       [5:0]  regfile_addr_rb_id,
  output logic [5:0]  regfile_addr_rc_id,

  
  output [5:0]  regfile_waddr_id,
  output        regfile_mem_we_dec,
  output        regfile_alu_we_dec,
   
  output        addr_ra_is_also_dst,  // for post load/store incr/dec destination
  output dual_issue_pi_legal_op_o,   
  output dual_issue_i2_legal_op_o  
  
);
  
  logic        regfile_alu_we_id, regfile_alu_we_dec_id;
  
  logic        regfile_fp_a;
  logic        regfile_fp_b;
  logic        regfile_fp_c;
  logic        regfile_fp_d;

  logic [1:0]  regc_mux;
  logic regfile_alu_waddr_mux_sel;
  logic fregfile_ena;
  

  // ALU Operator
  logic                    alu_en;
  logic [ALU_OP_WIDTH-1:0] alu_operator;
   
  assign fregfile_ena = FPU && !Zfinx ? ~fregfile_disable_i : '0;
  
  assign regfile_addr_ra_id = {fregfile_ena & regfile_fp_a, instr[`REG_S1]};
  assign regfile_addr_rb_id = {fregfile_ena & regfile_fp_b, instr[`REG_S2]};

  // register C mux
  always_comb begin
    unique case (regc_mux)
      REGC_ZERO:  regfile_addr_rc_id = '0;
      REGC_RD:    regfile_addr_rc_id = {fregfile_ena & regfile_fp_c, instr[`REG_D]};
      REGC_S1:    regfile_addr_rc_id = {fregfile_ena & regfile_fp_c, instr[`REG_S1]};
      REGC_S4:    regfile_addr_rc_id = {fregfile_ena & regfile_fp_c, instr[`REG_S4]};
      default:    regfile_addr_rc_id = '0;
    endcase
  end

  assign regfile_waddr_id = {fregfile_ena & regfile_fp_d, instr[`REG_D]};

  wire PRIV_LVL_U;
  riscv_decoder decoder_i (
  
    // controller related signals
    .deassert_we_i                   (1'b0),
    .data_misaligned_i               (1'b0),
    .mult_multicycle_i               (1'b0),
    .instr_multicycle_o              (),

    .illegal_insn_o                  (),
    .ebrk_insn_o                     (),

    .mret_insn_o                     (),
    .uret_insn_o                     (),
    .dret_insn_o                     (),

    .mret_dec_o                      (),
    .uret_dec_o                      (),
    .dret_dec_o                      (),

    .ecall_insn_o                    (),
    .pipe_flush_o                    (),

    .fencei_insn_o                   (),

    .rega_used_o                     ( rega_used_dec ),
    .regb_used_o                     ( regb_used_dec ),
    .regc_used_o                     ( regc_used_dec ),

    .reg_fp_a_o                      (regfile_fp_a),
    .reg_fp_b_o                      (regfile_fp_b),
    .reg_fp_c_o                      (regfile_fp_c),
    .reg_fp_d_o                      (regfile_fp_d),

    .bmask_a_mux_o                   (),
    .bmask_b_mux_o                   (),
    .alu_bmask_a_mux_sel_o           (),
    .alu_bmask_b_mux_sel_o           (),

    // from IF/ID pipeline
    .instr_rdata_i                   ( instr ),
    .illegal_c_insn_i                (1'b0),          // <<<<<<<<<<<<<<<< CHECK IF NEEDED 

    // ALU signals
    .alu_en_o                        ( alu_en       ),
    .alu_operator_o                  ( alu_operator ),
    .alu_op_a_mux_sel_o              (),
    .alu_op_b_mux_sel_o              (),
    .alu_op_c_mux_sel_o              (),
    .alu_vec_mode_o                  (),
    .scalar_replication_o            (),
    .scalar_replication_c_o          (),
    .imm_a_mux_sel_o                 (),
    .imm_b_mux_sel_o                 (),
    .regc_mux_o                      ( regc_mux ),
    .is_clpx_o                       (),
    .is_subrot_o                     (),

    // MUL signals
    .mult_operator_o                 (),
    .mult_int_en_o                   (),
    .mult_sel_subword_o              (),
    .mult_signed_mode_o              (),
    .mult_imm_mux_o                  (),
    .mult_dot_en_o                   (),
    .mult_dot_signed_o               (),

    // FPU / APU signals
    .frm_i                           (3'b0),
    .fpu_src_fmt_o                   (),
    .fpu_dst_fmt_o                   (),
    .fpu_int_fmt_o                   (),
    .apu_en_o                        (),
    .apu_type_o                      (),
    .apu_op_o                        (),
    .apu_lat_o                       (),
    .apu_flags_src_o                 (),
    .fp_rnd_mode_o                   (),

    // Register file control signals
    .regfile_mem_we_o                (),
    .regfile_alu_we_o                (),                              // qualified by stall - Assumed not applicable for mini_decode
    .regfile_alu_we_dec_o            (regfile_alu_we_dec),            // as detected by decoded 
    .regfile_alu_waddr_sel_o         (regfile_alu_waddr_mux_sel),

    // CSR control signals
    .csr_access_o                    (),
    .csr_status_o                    (),
    .csr_op_o                        (),
    .current_priv_lvl_i              (PRIV_LVL_U),

    // Data bus interface
    .data_req_o                      (),
    .data_we_o                       (),
    .prepost_useincr_o               (),
    .data_type_o                     (),
    .data_sign_extension_o           (),
    .data_reg_offset_o               (),
    .data_load_event_o               (),

    // hwloop signals
    .hwloop_we_o                     (),
    .hwloop_target_mux_sel_o         (),
    .hwloop_start_mux_sel_o          (),
    .hwloop_cnt_mux_sel_o            (),

    // jump/branches
    .jump_in_dec_o                   (),
    .jump_in_id_o                    (),
    .jump_target_mux_sel_o           (),
    
    .regfile_mem_we_dec_o            (regfile_mem_we_dec) ,
    .dual_issue_pi_legal_op_o        (dual_issue_pi_legal_op_o),
    .dual_issue_i2_legal_op_o        (dual_issue_i2_legal_op_o),
    .addr_ra_is_also_dst_o           (addr_ra_is_also_dst)
  );
  

endmodule
