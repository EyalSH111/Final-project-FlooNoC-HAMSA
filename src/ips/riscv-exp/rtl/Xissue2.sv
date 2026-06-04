// ISSUE2 top module


import riscv_defines::*;

module Xissue2 (

 input clk,
 input rst_n,
 input di_en_i,
 input  logic  test_en_i,     // enable all clock gates for testing


 di_ifstage_interface.i2   di_intrfc_ifstage,
 di_pfb_interface.i2       di_intrfc_pfb,
 di_ctrl_interface.i2      di_intrfc_ctrl,
 di_regfile_interface.i2   di_intrfc_regfile,
 di_reg_xfw_interface.in   di_intrfc_xfw_in,     // Regs cross forwarding input
 di_reg_xfw_interface.out  di_intrfc_xfw_out     // Regs cross forwarding output


 `ifdef TRACE_EXECUTION // Changed by Udi for Rinat Synthesis ramp-up
 // TRACE SYNC - Non-Synthesis
 , input         primary_trace_wb_valid
 , input integer primary_trace_file_id
 , input integer primary_trace_last_printed_cycle
`endif

) ;

//===========================================================================

logic [31:0] i2_instr_word ;
logic i2_instr_word_valid ;

logic [31:0]       pc_if;    // Program counter in IF stage
logic [31:0]       pc_id;    // Program counter in ID stage

// ALU Control
logic        alu_en_ex;
logic [ALU_OP_WIDTH-1:0] alu_operator_ex;
logic [31:0] alu_operand_a_ex;
logic [31:0] alu_operand_b_ex;
logic [31:0] alu_operand_c_ex;
logic [ 4:0] bmask_a_ex;
logic [ 4:0] bmask_b_ex;
logic [ 1:0] imm_vec_ext_ex;
logic [ 1:0] alu_vec_mode_ex;
logic        alu_is_clpx_ex, alu_is_subrot_ex;
logic [ 1:0] alu_clpx_shift_ex;

  // Multiplier Control
  logic [ 2:0] mult_operator_ex;
  logic [31:0] mult_operand_a_ex;
  logic [31:0] mult_operand_b_ex;
  logic [31:0] mult_operand_c_ex;
  logic        mult_en_ex;
  logic        mult_sel_subword_ex;
  logic [ 1:0] mult_signed_mode_ex;
  logic [ 4:0] mult_imm_ex;
  logic [31:0] mult_dot_op_a_ex;
  logic [31:0] mult_dot_op_b_ex;
  logic [31:0] mult_dot_op_c_ex;
  logic [ 1:0] mult_dot_signed_ex;
  logic        mult_is_clpx_ex;
  logic [ 1:0] mult_clpx_shift_ex;
  logic        mult_clpx_img_ex;


// Register Write Control
logic [5:0]  regfile_waddr_ex;
logic        regfile_we_ex;

logic [5:0]  regfile_alu_waddr_ex;
logic        regfile_alu_we_ex;

logic [5:0]  regfile_alu_waddr_fw;
logic [31:0] regfile_alu_wdata_fw;
logic        regfile_alu_we_fw;

logic clear_instr_valid ;

logic id_valid ;
logic ex_valid ;

logic id_ready ;
logic ex_ready ;

logic pi_and_i2_id_ready ;
logic pi_and_i2_ex_ready ;

logic halt_if ;
//logic mult_dot_op_b_ex;


// Connect ISSUE2 regfile interface

// Notice that the the read-ports are cinnected within  id_stage

logic wb_ready ;
logic pi_and_i2_wb_ready ;
assign wb_ready = 1'b1 ; // Currently ISSUE2 wv_ready is always asserted

// Currently we stall i2 in same manner as pi , to prevent dependencies
assign  pi_and_i2_id_ready = id_ready && di_intrfc_ctrl.pi_id_ready ;
assign  pi_and_i2_ex_ready = ex_ready && di_intrfc_ctrl.pi_ex_ready ;
assign  pi_and_i2_wb_ready = wb_ready && di_intrfc_ctrl.pi_wb_ready ;


//===========================================================================


 //////////////////////////////////////////////////
  //   ___ _____   ____ _____  _    ____ _____    //
  //  |_ _|  ___| / ___|_   _|/ \  / ___| ____|   //
  //   | || |_    \___ \ | | / _ \| |  _|  _|     //
  //   | ||  _|    ___) || |/ ___ \ |_| | |___    //
  //  |___|_|     |____/ |_/_/   \_\____|_____|   //
  //                                              //
  //////////////////////////////////////////////////


// Fetch issue2 instruction candidate from buffer
issue2_fetcher i2_fetcher (

 .clk(clk),
 .rst_n(rst_n),

 .di_en_i(di_en_i),

 .i2_instr_word          ( i2_instr_word ),
 .i2_instr_word_valid    ( i2_instr_word_valid ),
 .i2_id_ready_i          ( pi_and_i2_id_ready ),
 .clear_instr_valid_i    ( clear_instr_valid ) ,

 .di_intrfc_ifstage      (di_intrfc_ifstage),
 .di_intrfc_pfb          (di_intrfc_pfb),

 .pi_unusal_state_prevent_di    (di_intrfc_ctrl.pi_unusal_state_prevent_di),
 
 .i2_pc_if (pc_if),
 .i2_pc_id (pc_id)

);


  /////////////////////////////////////////////////
  //   ___ ____    ____ _____  _    ____ _____   //
  //  |_ _|  _ \  / ___|_   _|/ \  / ___| ____|  //
  //   | || | | | \___ \ | | / _ \| |  _|  _|    //
  //   | || |_| |  ___) || |/ ___ \ |_| | |___   //
  //  |___|____/  |____/ |_/_/   \_\____|_____|  //
  //                                             //
  /////////////////////////////////////////////////


  wire PRIV_LVL_U;
  // ???? TBC , NEED TO SOLVE - THERE IS NO REGFILE IN THE ISSUE2 DECODER INSTABCE (use parametrized generate)  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  Xriscv_id_stage #(.ISSUE2_INST(1)) id_stage_i
  (
    .clk                          ( clk                  ),
    .rst_n                        ( rst_n                ),
    .regfile_select_i             ( 1'b0                 ),
    .test_en_i                    ( test_en_i            ),

    .fregfile_disable_i           (1'b1),  // fregfile disabled (not applicable)

    // Processor Enable -- Assumed to be managed by primary issue decoder/control
    .fetch_enable_i               (1'b1),
    .ctrl_busy_o                  (),
    .core_ctrl_firstfetch_o       (),
    .is_decoding_o                (),

    // Interface to instruction memory
    .hwlp_dec_cnt_i               (2'b0),
    .is_hwlp_i                    (1'b0),
    .instr_valid_i                (i2_instr_word_valid),
    .instr_rdata_i                (i2_instr_word),
    .instr_req_o                  (),

    // Jumps and branches  -- CURRENTLY Jump and branch instructions are mapped only to the primary issue

    .branch_in_ex_o               (),
    .branch_decision_i            (1'b0), // Not applicable for issue2
    .jump_target_o                (),

    // IF and ID control signals  -- -- CURRENTLY Control is entirely managed by the primary issue, NEED to handle Issue2 exceptions

    .clear_instr_valid_o          (clear_instr_valid),
    .pc_set_o                     (),
    .pc_mux_o                     (),
    .exc_pc_mux_o                 (),
    .exc_cause_o                  (),
    .trap_addr_mux_o              (),
    .illegal_c_insn_i             (1'b0),
    .is_compressed_i              (1'b0),
    .is_fetch_failed_i            (1'b0),

    .pc_if_i                      ( pc_if                ),
    .pc_id_i                      ( pc_id                ),

    // Stalls  -- Currently assume stall control is is managed by main issue
    .halt_if_o                    ( halt_if              ),

    .id_ready_o                   ( id_ready             ),
    .ex_ready_i                   ( pi_and_i2_ex_ready   ), // Currently pi stalls also i2
    .wb_ready_i                   ( pi_and_i2_wb_ready   ), // Currently pi stalls also i2

    .id_valid_o                   ( id_valid             ),
    .ex_valid_i                   ( ex_valid             ),

    // From the Pipeline ID/EX
    .pc_ex_o                      (                      ), // CSR related , check if needed in Issue2

    .alu_en_ex_o                  ( alu_en_ex            ),
    .alu_operator_ex_o            ( alu_operator_ex      ),
    .alu_operand_a_ex_o           ( alu_operand_a_ex     ),
    .alu_operand_b_ex_o           ( alu_operand_b_ex     ),
    .alu_operand_c_ex_o           ( alu_operand_c_ex     ),
    .bmask_a_ex_o                 ( bmask_a_ex           ),
    .bmask_b_ex_o                 ( bmask_b_ex           ),
    .imm_vec_ext_ex_o             ( imm_vec_ext_ex       ),
    .alu_vec_mode_ex_o            ( alu_vec_mode_ex      ),
    .alu_is_clpx_ex_o             ( alu_is_clpx_ex       ),
    .alu_is_subrot_ex_o           ( alu_is_subrot_ex     ),
    .alu_clpx_shift_ex_o          ( alu_clpx_shift_ex    ),

    .regfile_waddr_ex_o           ( regfile_waddr_ex     ),  // NOT sure if needed in issue2 , CHECK
    .regfile_we_ex_o              ( regfile_we_ex        ),  // NOT sure if needed in issue2 , CHECK

    .regfile_alu_we_ex_o          ( regfile_alu_we_ex    ),  // NOT sure if needed in issue2 , CHECK
    .regfile_alu_waddr_ex_o       ( regfile_alu_waddr_ex ),  // NOT sure if needed in issue2 , CHECK

    // MUL - CURRENTLY supported in I2 (other than multi-cycle) TODO: make it optional


    .mult_operator_ex_o           ( mult_operator_ex     ), // from ID to EX stage
    .mult_en_ex_o                 ( mult_en_ex           ), // from ID to EX stage
    .mult_sel_subword_ex_o        ( mult_sel_subword_ex  ), // from ID to EX stage
    .mult_signed_mode_ex_o        ( mult_signed_mode_ex  ), // from ID to EX stage
    .mult_operand_a_ex_o          ( mult_operand_a_ex    ), // from ID to EX stage
    .mult_operand_b_ex_o          ( mult_operand_b_ex    ), // from ID to EX stage
    .mult_operand_c_ex_o          ( mult_operand_c_ex    ), // from ID to EX stage
    .mult_imm_ex_o                ( mult_imm_ex          ), // from ID to EX stage

    .mult_dot_op_a_ex_o           ( mult_dot_op_a_ex     ), // from ID to EX stage
    .mult_dot_op_b_ex_o           ( mult_dot_op_b_ex     ), // from ID to EX stage
    .mult_dot_op_c_ex_o           ( mult_dot_op_c_ex     ), // from ID to EX stage
    .mult_dot_signed_ex_o         ( mult_dot_signed_ex   ), // from ID to EX stage
    .mult_is_clpx_ex_o            ( mult_is_clpx_ex      ), // from ID to EX stage
    .mult_clpx_shift_ex_o         ( mult_clpx_shift_ex   ), // from ID to EX stage
    .mult_clpx_img_ex_o           ( mult_clpx_img_ex     ), // from ID to EX stage


    // FPU - Not Applicable
    .frm_i                        (3'b0),

    // APU  -- NOT Applicable for Dual-Issue
    .apu_en_ex_o                  (),
    .apu_type_ex_o                (),
    .apu_op_ex_o                  (),
    .apu_lat_ex_o                 (),
    .apu_operands_ex_o            (),
    .apu_flags_ex_o               (),
    .apu_waddr_ex_o               (),

    .apu_read_regs_o              (),
    .apu_read_regs_valid_o        (),
    .apu_read_dep_i               (1'b0),
    .apu_write_regs_o             (),
    .apu_write_regs_valid_o       (),
    .apu_write_dep_i              (1'b0),
    .apu_perf_dep_o               (),
    .apu_busy_i                   (1'b0),

    // CSR ID/EX -- Currently NOT assigned to ISSUE2 instruction

    .csr_access_ex_o              (),
    .csr_op_ex_o                  (),
    .current_priv_lvl_i           (PRIV_LVL_U),
    .csr_irq_sec_o                (),
    .csr_cause_o                  (),
    .csr_save_if_o                (),
    .csr_save_id_o                (),
    .csr_save_ex_o                (),
    .csr_restore_mret_id_o        (),
    .csr_restore_uret_id_o        (),

    .csr_restore_dret_id_o        (),

    .csr_save_cause_o             (),

    // hardware loop signals to IF hwlp controller   -- hwlp Currently NOT assigned to ISSUE2 instruction
    .hwlp_start_o                 (),
    .hwlp_end_o                   (),
    .hwlp_cnt_o                   (),

    // hardware loop signals from CSR                -- hwlp Currently NOT assigned to ISSUE2 instruction

    .csr_hwlp_regid_i             (1'b0),
    .csr_hwlp_we_i                (3'b0),
    .csr_hwlp_data_i              (32'b0),

    // LSU  // CURRENTLY LSU instructions are mapped only to the primary issue

    .data_req_ex_o                (), // to load store unit
    .data_we_ex_o                 (), // to load store unit
    .data_type_ex_o               (), // to load store unit
    .data_sign_ext_ex_o           (), // to load store unit
    .data_reg_offset_ex_o         (), // to load store unit
    .data_load_event_ex_o         (), // to load store unit

    .data_misaligned_ex_o         (), // to load store unit

    .prepost_useincr_ex_o         (),
    .data_misaligned_i            (di_intrfc_ctrl.pi_data_misaligned), // Impact registers FW mechanism (... Not sure this needs to go to I2)
    .data_err_i                   (1'b0),
    .data_err_ack_o               (),

    // Interrupt Signals -- Currently assumed to be handled by the primary Issue - CHECK

    .irq_i                        (1'b0), // incoming interrupts
    .irq_sec_i                    (1'b0),
    .irq_id_i                     (5'b0),
    .m_irq_enable_i               (1'b0),
    .u_irq_enable_i               (1'b0),
    .irq_ack_o                    (),
    .irq_id_o                     (),

    // Debug Signal -- DEBUG NOT SUPPORTED IN Dual-Issue
    .debug_mode_o                 (),
    .debug_cause_o                (),
    .debug_csr_save_o             (),
    .debug_req_i                  (1'b0),
    .debug_single_step_i          (1'b0),
    .debug_ebreakm_i              (1'b0),
    .debug_ebreaku_i              (1'b0),

    // Forward Signals

    // Assumed Applicable only for LSU instructions , currently not applicable for ISSUE2
    .regfile_waddr_wb_i           (6'b0), // Write address ex-wb pipeline
    .regfile_we_wb_i              (1'b0), // write enable for the register file
    .regfile_wdata_wb_i           (32'b0), // write data to commit in the register file

    .regfile_alu_waddr_fw_i       ( regfile_alu_waddr_fw ),
    .regfile_alu_we_fw_i          ( regfile_alu_we_fw    ),
    .regfile_alu_wdata_fw_i       ( regfile_alu_wdata_fw ),

    // from ALU
    .mult_multicycle_i            (1'b0),  // CURRENTLY MULT instructions are mapped only to the primary issue

    // Performance Counters -- Currently NOT SUPPORTED in Dual-Issue

    .perf_jump_o                  (),
    .perf_jr_stall_o              (),
    .perf_ld_stall_o              (),
    .perf_pipeline_stall_o        (),

    .di_intrfc_regfile (di_intrfc_regfile),
    .di_intrfc_xfw_in  (di_intrfc_xfw_in),
    .di_intrfc_xfw_out (di_intrfc_xfw_out),
    .di_intrfc_ctrl    (di_intrfc_ctrl)
  );


  logic kill_i2_on_pi_br_or_unusal ; // in case I2 is allocated and PI is branching
  `ifndef HAMSA_DIX
   assign kill_i2_on_pi_br_or_unusal = 1'b0 ; // NOT APPLICABLE
  `else
    //assign kill_i2_on_pi_br_or_unusal = di_intrfc_ctrl.pi_branch_taken_ex ;
    assign kill_i2_on_pi_br_or_unusal = di_intrfc_ctrl.pi_branch_taken_ex || di_intrfc_ctrl.pi_unusal_state_kill_di ;
  `endif



  /////////////////////////////////////////////////////
  //   _______  __  ____ _____  _    ____ _____      //
  //  | ____\ \/ / / ___|_   _|/ \  / ___| ____|     //
  //  |  _|  \  /  \___ \ | | / _ \| |  _|  _|       //
  //  | |___ /  \   ___) || |/ ___ \ |_| | |___      //
  //  |_____/_/\_\ |____/ |_/_/   \_\____|_____|     //
  //                                                 //
  /////////////////////////////////////////////////////
  riscv_ex_stage ex_stage_i
  (
    // Global signals: Clock and active low asynchronous reset
    .clk                        ( clk                          ),
    .rst_n                      ( rst_n                        ),

    // Alu signals from ID stage
    .alu_en_i                   ( alu_en_ex                    ),
    .alu_operator_i             ( alu_operator_ex              ), // from ID/EX pipe registers
    .alu_operand_a_i            ( alu_operand_a_ex             ), // from ID/EX pipe registers
    .alu_operand_b_i            ( alu_operand_b_ex             ), // from ID/EX pipe registers
    .alu_operand_c_i            ( alu_operand_c_ex             ), // from ID/EX pipe registers
    .bmask_a_i                  ( bmask_a_ex                   ), // from ID/EX pipe registers
    .bmask_b_i                  ( bmask_b_ex                   ), // from ID/EX pipe registers
    .imm_vec_ext_i              ( imm_vec_ext_ex               ), // from ID/EX pipe registers
    .alu_vec_mode_i             ( alu_vec_mode_ex              ), // from ID/EX pipe registers
    .alu_is_clpx_i              ( alu_is_clpx_ex               ), // from ID/EX pipe registers
    .alu_is_subrot_i            ( alu_is_subrot_ex             ), // from ID/Ex pipe registers
    .alu_clpx_shift_i           ( alu_clpx_shift_ex            ), // from ID/EX pipe registers

    // Multiplier -- CURRENTLY not supported in issue2

    .mult_operator_i            ( mult_operator_ex             ), // from ID/EX pipe registers
    .mult_operand_a_i           ( mult_operand_a_ex            ), // from ID/EX pipe registers
    .mult_operand_b_i           ( mult_operand_b_ex            ), // from ID/EX pipe registers
    .mult_operand_c_i           ( mult_operand_c_ex            ), // from ID/EX pipe registers
    .mult_en_i                  ( mult_en_ex                   ), // from ID/EX pipe registers
    .mult_sel_subword_i         ( mult_sel_subword_ex          ), // from ID/EX pipe registers
    .mult_signed_mode_i         ( mult_signed_mode_ex          ), // from ID/EX pipe registers
    .mult_imm_i                 ( mult_imm_ex                  ), // from ID/EX pipe registers
    .mult_dot_op_a_i            ( mult_dot_op_a_ex             ), // from ID/EX pipe registers
    .mult_dot_op_b_i            ( mult_dot_op_b_ex             ), // from ID/EX pipe registers
    .mult_dot_op_c_i            ( mult_dot_op_c_ex             ), // from ID/EX pipe registers
    .mult_dot_signed_i          ( mult_dot_signed_ex           ), // from ID/EX pipe registers
    .mult_is_clpx_i             ( mult_is_clpx_ex              ), // from ID/EX pipe registers
    .mult_clpx_shift_i          ( mult_clpx_shift_ex           ), // from ID/EX pipe registers
    .mult_clpx_img_i            ( mult_clpx_img_ex             ), // from ID/EX pipe registers

    .mult_multicycle_o          ( ),  // CURRENTLY not supported in issue2

    // FPU / -- CURRENTLY not supported in issue2
    .fpu_prec_i                 (5'b0),
    .fpu_fflags_o               (),
    .fpu_fflags_we_o            (),

    // APU  -- CURRENTLY not supported in issue2
    .apu_en_i                   ( 1'b0  ),
    .apu_op_i                   ( 6'b0  ),
    .apu_lat_i                  ( 2'b0  ),
    .apu_operands_i             ( 96'b0 ),
    .apu_waddr_i                ( 6'b0  ),
    .apu_flags_i                ( 15'b0 ),

    .apu_read_regs_i            ( 18'b0 ),
    .apu_read_regs_valid_i      ( 3'b0  ),
    .apu_read_dep_o             ( ),
    .apu_write_regs_i           ( 12'b0 ),
    .apu_write_regs_valid_i     ( 2'b0  ),
    .apu_write_dep_o            (),

    .apu_perf_type_o            (),
    .apu_perf_cont_o            (),
    .apu_perf_wb_o              (),
    .apu_ready_wb_o             (),
    .apu_busy_o                 (),

    // apu-interconnect
    // handshake signals
    .apu_master_req_o           (),
    .apu_master_ready_o         (),
    .apu_master_gnt_i           (1'b0),
    // request channel
    .apu_master_operands_o      (),
    .apu_master_op_o            (),
    // response channel
    .apu_master_valid_i         (1'b0),
    .apu_master_result_i        (32'b0),

    .lsu_en_i                   ( 1'b0 ),
    .lsu_rdata_i                ( 32'b0 ),

    // interface with CSRs -- Assumed Not handled on issue2
    .csr_access_i               ( 1'b0  ),
    .csr_rdata_i                ( 32'b0 ),

    // From ID Stage: Regfile control signals
    .branch_in_ex_i             ( di_intrfc_ctrl.pi_branch_in_ex ),
    .regfile_alu_waddr_i        ( regfile_alu_waddr_ex              ),  // NOT sure if needed in issue2 , CHECK
    .regfile_alu_we_i           ( regfile_alu_we_ex                 ),  // NOT sure if needed in issue2 , CHECK

    .regfile_waddr_i            ( regfile_waddr_ex                  ),  // NOT sure if needed in issue2 , CHECK
    .regfile_we_i               ( regfile_we_ex                     ),  // NOT sure if needed in issue2 , CHECK

    // Output of ex stage pipeline  // Assumed Applicable only for LSU instructions , currently not applicable for ISSUE2
    .regfile_waddr_wb_o         (),
    .regfile_we_wb_o            (),
    .regfile_wdata_wb_o         (),

    // To IF: Jump and branch target and decision -- Assumed Not handled on issue2
    .jump_target_o              (),
    .branch_decision_o          (),

    // To ID stage: Forwarding signals
    .regfile_alu_waddr_fw_o     ( regfile_alu_waddr_fw         ),
    .regfile_alu_we_fw_o        ( regfile_alu_we_fw            ),
    .regfile_alu_wdata_fw_o     ( regfile_alu_wdata_fw         ),

    // stall control -- Currently assumed Not handled on issue2
    .lsu_ready_ex_i             ( 1'b1 ),
    .lsu_err_i                  ( 1'b0 ),

    .ex_ready_o                 ( ex_ready ),
    .ex_valid_o                 ( ex_valid ),
    .wb_ready_i                 ( pi_and_i2_wb_ready),

    .kill_i2_on_pi_br_or_unusal (kill_i2_on_pi_br_or_unusal)
  );


// ************************* I2 TRACER **************************


`ifndef VERILATOR
`ifdef TRACE_EXECUTION

  logic tracer_clk;
  assign tracer_clk = clk;

  riscv_tracer #(.ISSUE2_INST(1)) riscv_tracer_i
  (
    .clk            ( tracer_clk                           ), // always-running clock for tracing
    .rst_n          ( rst_n                                ),

    .fetch_enable   ( 1'b1                                 ), // Assuming not Applicable for I2
    .core_id        ( 1'b0                                 ), // Assuming not Applicable for I2
    .cluster_id     ( 1'b0                                 ), // Assuming not Applicable for I2

    .pc             ( id_stage_i.pc_id_i                   ),
    .instr          ( id_stage_i.instr                     ),
    .compressed     ( id_stage_i.is_compressed_i           ),
    .id_valid       ( id_stage_i.id_valid_o                ),
    .is_decoding    ( id_stage_i.is_decoding_o             ),
    .pipe_flush     ( id_stage_i.controller_i.pipe_flush_i ),
    .mret           ( id_stage_i.controller_i.mret_insn_i  ),
    .uret           ( id_stage_i.controller_i.uret_insn_i  ),
    .dret           ( id_stage_i.controller_i.dret_insn_i  ),
    .ecall          ( id_stage_i.controller_i.ecall_insn_i ),
    .ebreak         ( id_stage_i.controller_i.ebrk_insn_i  ),
    .rs1_value      ( id_stage_i.operand_a_fw_id           ),
    .rs2_value      ( id_stage_i.operand_b_fw_id           ),
    .rs3_value      ( id_stage_i.alu_operand_c             ),
    .rs2_value_vec  ( id_stage_i.alu_operand_b             ),

    .rs1_is_fp      ( id_stage_i.regfile_fp_a              ),
    .rs2_is_fp      ( id_stage_i.regfile_fp_b              ),
    .rs3_is_fp      ( id_stage_i.regfile_fp_c              ),
    .rd_is_fp       ( id_stage_i.regfile_fp_d              ),

    .ex_valid       ( ex_stage_i.ex_valid_o                ),
    .ex_reg_addr    ( regfile_alu_waddr_fw                 ),
    .ex_reg_we      ( regfile_alu_we_fw                    ),
    .ex_reg_wdata   ( regfile_alu_wdata_fw                 ),

    .ex_data_addr   ( 32'b0                                ),  // No memory instructions on issue2
    .ex_data_req    ( 1'b0                                 ),
    .ex_data_gnt    ( 1'b0                                 ),
    .ex_data_we     ( 1'b0                                 ),
    .ex_data_wdata  ( 1'b0                                 ),

    .wb_bypass      ( ex_stage_i.branch_in_ex_i            ),

    .wb_valid       ( primary_trace_wb_valid               ), // SYNC TRACE PRINTS
    .wb_reg_addr    ( 32'b0                                ), // Assuming No WB from memory on Isue2
    .wb_reg_we      ( 1'b0                                 ), // Assuming No WB from memory on Isue2
    .wb_reg_wdata   ( 32'b0                                ), // Assuming No WB from memory on Isue2

    .imm_u_type     ( id_stage_i.imm_u_type                ),
    .imm_uj_type    ( id_stage_i.imm_uj_type               ),
    .imm_i_type     ( id_stage_i.imm_i_type                ),
    .imm_iz_type    ( id_stage_i.imm_iz_type[11:0]         ),
    .imm_z_type     ( id_stage_i.imm_z_type                ),
    .imm_s_type     ( id_stage_i.imm_s_type                ),
    .imm_sb_type    ( id_stage_i.imm_sb_type               ),
    .imm_s2_type    ( id_stage_i.imm_s2_type               ),
    .imm_s3_type    ( id_stage_i.imm_s3_type               ),
    .imm_vs_type    ( id_stage_i.imm_vs_type               ),
    .imm_vu_type    ( id_stage_i.imm_vu_type               ),
    .imm_shuffle_type ( id_stage_i.imm_shuffle_type        ),
    .imm_clip_type  ( id_stage_i.instr_rdata_i[11:7]       ),

    .primary_trace_file_id(primary_trace_file_id),
    .primary_trace_last_printed_cycle(primary_trace_last_printed_cycle)


  );
`endif
`endif

endmodule
