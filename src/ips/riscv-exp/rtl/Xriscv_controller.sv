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
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                 Robert Balas - balasr@iis.ee.ethz.ch                       //
//                                                                            //
// Design Name:    Main controller                                            //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Main CPU controller of the processor                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import riscv_defines::*;

module Xriscv_controller
#(
  parameter FPU          = 0 ,
  parameter ISSUE2_INST  = 0   // Value of '1' indicate that the this module is instantiated in ISSUE2 and not in the primary issue
)
(
  input  logic        clk,
  input  logic        rst_n,

  input  logic        fetch_enable_i,             // Start the decoding
  output logic        ctrl_busy_o,                // Core is busy processing instructions
  output logic        first_fetch_o,              // Core is at the FIRST FETCH stage
  output logic        is_decoding_o,              // Core is in decoding state
  input  logic        is_fetch_failed_i,

  // decoder related signals
  output logic        deassert_we_o,              // deassert write enable for next instruction

  input  logic        illegal_insn_i,             // decoder encountered an invalid instruction
  input  logic        ecall_insn_i,               // ecall encountered an mret instruction
  input  logic        mret_insn_i,                // decoder encountered an mret instruction
  input  logic        uret_insn_i,                // decoder encountered an uret instruction

  input  logic        dret_insn_i,                // decoder encountered an dret instruction

  input  logic        mret_dec_i,
  input  logic        uret_dec_i,
  input  logic        dret_dec_i,

  input  logic        pipe_flush_i,               // decoder wants to do a pipe flush
  input  logic        ebrk_insn_i,                // decoder encountered an ebreak instruction
  input  logic        fencei_insn_i,              // decoder encountered an fence.i instruction
  input  logic        csr_status_i,               // decoder encountered an csr status instruction
  input  logic        instr_multicycle_i,         // true when multiple cycles are decoded

  // from IF/ID pipeline
  input  logic        instr_valid_i,              // instruction coming from IF/ID pipeline is valid

  // from prefetcher
  output logic        instr_req_o,                // Start fetching instructions

  // to prefetcher
  output logic        pc_set_o,                   // jump to address set by pc_mux
  output logic [2:0]  pc_mux_o,                   // Selector in the Fetch stage to select the rigth PC (normal, jump ...)
  output logic [2:0]  exc_pc_mux_o,               // Selects target PC for exception
  output logic        trap_addr_mux_o,            // Selects trap address base

  // LSU
  input  logic        data_req_ex_i,              // data memory access is currently performed in EX stage
  input  logic        data_we_ex_i,
  input  logic        data_misaligned_i,
  input  logic        data_load_event_i,
  input  logic        data_err_i,
  output logic        data_err_ack_o,

  // from ALU
  input  logic        mult_multicycle_i,          // multiplier is taken multiple cycles and uses op c as storage

  // APU dependency checks
  input  logic        apu_en_i,
  input  logic        apu_read_dep_i,
  input  logic        apu_write_dep_i,

  output logic        apu_stall_o,

  // jump/branch signals
  input  logic        branch_taken_ex_i,          // branch taken signal from EX ALU
  input  logic [1:0]  jump_in_id_i,               // jump is being calculated in ALU
  input  logic [1:0]  jump_in_dec_i,              // jump is being calculated in ALU

  // Interrupt Controller Signals
  input  logic        irq_i,
  input  logic        irq_req_ctrl_i,
  input  logic        irq_sec_ctrl_i,
  input  logic [4:0]  irq_id_ctrl_i,
  input  logic        m_IE_i,                     // interrupt enable bit from CSR (M mode)
  input  logic        u_IE_i,                     // interrupt enable bit from CSR (U mode)
  input  PrivLvl_t    current_priv_lvl_i,

  output logic        irq_ack_o,
  output logic [4:0]  irq_id_o,

  output logic [5:0]  exc_cause_o,
  output logic        exc_ack_o,
  output logic        exc_kill_o,

  // Debug Signal
  output logic         debug_mode_o,
  output logic [2:0]   debug_cause_o,
  output logic         debug_csr_save_o,
  input  logic         debug_req_i,
  input  logic         debug_single_step_i,
  input  logic         debug_ebreakm_i,
  input  logic         debug_ebreaku_i,


  output logic        csr_save_if_o,
  output logic        csr_save_id_o,
  output logic        csr_save_ex_o,
  output logic [5:0]  csr_cause_o,
  output logic        csr_irq_sec_o,
  output logic        csr_restore_mret_id_o,
  output logic        csr_restore_uret_id_o,

  output logic        csr_restore_dret_id_o,

  output logic        csr_save_cause_o,


  // Regfile target
  input  logic        regfile_we_id_i,            // currently decoded we enable
  input  logic [5:0]  regfile_alu_waddr_id_i,     // currently decoded target address

  // Forwarding signals from regfile
  input  logic        regfile_we_ex_i,            // FW: write enable from  EX stage
  input  logic [5:0]  regfile_waddr_ex_i,         // FW: write address from EX stage
  input  logic        regfile_we_wb_i,            // FW: write enable from  WB stage
  input  logic        regfile_alu_we_fw_i,        // FW: ALU/MUL write enable from  EX stage

  // forwarding signals
  output logic [1:0]  operand_a_fw_mux_sel_o,     // regfile ra data selector form ID stage
  output logic [1:0]  operand_b_fw_mux_sel_o,     // regfile rb data selector form ID stage
  output logic [1:0]  operand_c_fw_mux_sel_o,     // regfile rc data selector form ID stage

 `ifdef HAMSA_DIX  // Dual-Issue cross-forwarding control from other issue (oi)
 
  input  oi_regfile_we_wb_i,            
  input  oi_regfile_alu_we_fw_i, 

  input oi_reg_d_ex_is_reg_a_i  ,  
  input oi_reg_d_ex_is_reg_b_i  ,
  input oi_reg_d_ex_is_reg_c_i  ,
  input oi_reg_d_wb_is_reg_a_i  ,
  input oi_reg_d_wb_is_reg_b_i  ,
  input oi_reg_d_wb_is_reg_c_i  ,
  input oi_reg_d_alu_is_reg_a_i ,
  input oi_reg_d_alu_is_reg_b_i ,
  input oi_reg_d_alu_is_reg_c_i ,
   
  output logic oi_fw_to_op_a_o,
  output logic oi_fw_to_op_b_o,
  output logic oi_fw_to_op_c_o,
  
  input oi_regfile_waddr_ex_i,
  
  di_ctrl_interface  di_intrfc_ctrl,
  
 `endif

  // forwarding detection signals
  input logic         reg_d_ex_is_reg_a_i,
  input logic         reg_d_ex_is_reg_b_i,
  input logic         reg_d_ex_is_reg_c_i,
  input logic         reg_d_wb_is_reg_a_i,
  input logic         reg_d_wb_is_reg_b_i,
  input logic         reg_d_wb_is_reg_c_i,
  input logic         reg_d_alu_is_reg_a_i,
  input logic         reg_d_alu_is_reg_b_i,
  input logic         reg_d_alu_is_reg_c_i,

  // stall signals
  output logic        halt_if_o,
  output logic        halt_id_o,

  output logic        misaligned_stall_o,
  output logic        jr_stall_o,
  output logic        load_stall_o,

  input  logic        id_ready_i,                 // ID stage is ready

  input  logic        ex_valid_i,                 // EX stage is done

  input  logic        wb_ready_i,                 // WB stage is ready

  // Performance Counters
  output logic        perf_jump_o,                // we are executing a jump instruction   (j, jr, jal, jalr)
  output logic        perf_jr_stall_o,            // stall due to jump-register-hazard
  output logic        perf_ld_stall_o,            // stall due to load-use-hazard
  output logic        perf_pipeline_stall_o       // stall due to elw extra cycles
 
);

 `ifndef HAMSA_DIX  // Define as constant deassrted if not in DI mode 
 logic oi_regfile_we_wb_i       ;            
 logic oi_regfile_alu_we_fw_i   ;
 logic oi_reg_d_ex_is_reg_a_i   ;  
 logic oi_reg_d_ex_is_reg_b_i   ;
 logic oi_reg_d_ex_is_reg_c_i   ;
 logic oi_reg_d_wb_is_reg_a_i   ;
 logic oi_reg_d_wb_is_reg_b_i   ;
 logic oi_reg_d_wb_is_reg_c_i   ;
 logic oi_reg_d_alu_is_reg_a_i  ;
 logic oi_reg_d_alu_is_reg_b_i  ;
 logic oi_reg_d_alu_is_reg_c_i  ;


 assign oi_regfile_we_wb_i      = 1'b0 ;        
 assign oi_regfile_alu_we_fw_i  = 1'b0 ;
 assign oi_reg_d_ex_is_reg_a_i  = 1'b0 ;  
 assign oi_reg_d_ex_is_reg_b_i  = 1'b0 ;
 assign oi_reg_d_ex_is_reg_c_i  = 1'b0 ;
 assign oi_reg_d_wb_is_reg_a_i  = 1'b0 ;
 assign oi_reg_d_wb_is_reg_b_i  = 1'b0 ;
 assign oi_reg_d_wb_is_reg_c_i  = 1'b0 ;
 assign oi_reg_d_alu_is_reg_a_i = 1'b0 ;
 assign oi_reg_d_alu_is_reg_b_i = 1'b0 ;
 assign oi_reg_d_alu_is_reg_c_i = 1'b0 ;

`endif 
  
 logic ti_i2_fw_to_op_a ; // This issue is issue2 and it is forwarding to register a  ;
 logic ti_i2_fw_to_op_b ; // This issue is issue2 and it is forwarding to register b  ;
 logic ti_i2_fw_to_op_c ; // This issue is issue2 and it is forwarding to register c  ;
 
  // FSM state encoding
  enum  logic [4:0] { RESET, BOOT_SET, SLEEP, WAIT_SLEEP, FIRST_FETCH,
                      DECODE,
                      IRQ_TAKEN_ID, IRQ_TAKEN_IF, IRQ_FLUSH, ELW_EXE,
                      FLUSH_EX, FLUSH_WB, XRET_JUMP,
                      DBG_TAKEN_ID, DBG_TAKEN_IF, DBG_FLUSH, DBG_WAIT_BRANCH } ctrl_fsm_cs, ctrl_fsm_ns;

  logic jump_done, jump_done_q, jump_in_dec, branch_in_id;
  logic boot_done, boot_done_q;
  logic irq_enable_int;
  logic data_err_q;

  logic debug_mode_q, debug_mode_n;
  logic ebrk_force_debug_mode;

  logic illegal_insn_q, illegal_insn_n;

`ifndef SYNTHESIS
  // synopsys translate_off
  // make sure we are called later so that we do not generate messages for
  // glitches
  always_ff @(negedge clk)
  begin
    // print warning in case of decoding errors
    if (is_decoding_o && illegal_insn_i) begin
    `ifndef HAMSA_DIX
      $display("%t: Illegal instruction (core %0d) at PC 0x%h:", $time, riscv_core.core_id_i,
               Xriscv_id_stage.pc_id_i);
     `else
       if (ISSUE2_INST==0) $display("%t: Illegal instruction on Primary Issue at PC 0x%h:", $time,Xriscv_id_stage.pc_id_i);
       else $display("%t: Illegal instruction on Issue2 at PC 0x%h:", $time,Xriscv_id_stage.pc_id_i);
     `endif
    end
  end
  // synopsys translate_on
`endif


  ////////////////////////////////////////////////////////////////////////////////////////////
  //   ____ ___  ____  _____    ____ ___  _   _ _____ ____   ___  _     _     _____ ____    //
  //  / ___/ _ \|  _ \| ____|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |   | |   | ____|  _ \   //
  // | |  | | | | |_) |  _|   | |  | | | |  \| | | | | |_) | | | | |   | |   |  _| | |_) |  //
  // | |__| |_| |  _ <| |___  | |__| |_| | |\  | | | |  _ <| |_| | |___| |___| |___|  _ <   //
  //  \____\___/|_| \_\_____|  \____\___/|_| \_| |_| |_| \_\\___/|_____|_____|_____|_| \_\  //
  //                                                                                        //
  ////////////////////////////////////////////////////////////////////////////////////////////

  always_comb
  begin
    // Default values
    instr_req_o            = 1'b1;

    exc_ack_o              = 1'b0;
    exc_kill_o             = 1'b0;
    data_err_ack_o         = 1'b0;

    csr_save_if_o          = 1'b0;
    csr_save_id_o          = 1'b0;
    csr_save_ex_o          = 1'b0;
    csr_restore_mret_id_o  = 1'b0;
    csr_restore_uret_id_o  = 1'b0;

    csr_restore_dret_id_o  = 1'b0;

    csr_save_cause_o       = 1'b0;

    exc_cause_o            = '0;
    exc_pc_mux_o           = EXC_PC_IRQ;
    trap_addr_mux_o        = TRAP_MACHINE;

    csr_cause_o            = '0;
    csr_irq_sec_o          = 1'b0;

    pc_mux_o               = PC_BOOT;
    pc_set_o               = 1'b0;
    jump_done              = jump_done_q;

    ctrl_fsm_ns            = ctrl_fsm_cs;

    ctrl_busy_o            = 1'b1;
    first_fetch_o          = 1'b0;

    halt_if_o              = 1'b0;
    halt_id_o              = 1'b0;
    irq_ack_o              = 1'b0;
    irq_id_o               = irq_id_ctrl_i;
    boot_done              = 1'b0;
    jump_in_dec            = jump_in_dec_i == BRANCH_JALR || jump_in_dec_i == BRANCH_JAL;
    branch_in_id           = jump_in_id_i == BRANCH_COND;
    irq_enable_int         =  ((u_IE_i | irq_sec_ctrl_i) & current_priv_lvl_i == PRIV_LVL_U) | (m_IE_i & current_priv_lvl_i == PRIV_LVL_M);

    ebrk_force_debug_mode  = (debug_ebreakm_i && current_priv_lvl_i == PRIV_LVL_M) ||
                             (debug_ebreaku_i && current_priv_lvl_i == PRIV_LVL_U);
    debug_csr_save_o       = 1'b0;
    debug_cause_o          = DBG_CAUSE_EBREAK;
    debug_mode_n           = debug_mode_q;

    illegal_insn_n         = illegal_insn_q;
    // a trap towards the debug unit is generated when one of the
    // following conditions are true:
    // - ebreak instruction encountered
    // - single-stepping mode enabled
    // - illegal instruction exception and IIE bit is set
    // - IRQ and INTE bit is set and no exception is currently running
    // - Debuger requests halt

    perf_pipeline_stall_o  = 1'b0;

    unique case (ctrl_fsm_cs)
      // We were just reset, wait for fetch_enable
      RESET:
      begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b0;
        if (fetch_enable_i == 1'b1)
        begin
          ctrl_fsm_ns = BOOT_SET;
        end
      end

      // copy boot address to instr fetch address
      BOOT_SET:
      begin
        is_decoding_o = 1'b0;
        instr_req_o   = 1'b1;
        pc_mux_o      = PC_BOOT;
        pc_set_o      = 1'b1;
        boot_done     = 1'b1;
        ctrl_fsm_ns   = FIRST_FETCH;
      end

      WAIT_SLEEP:
      begin
        is_decoding_o = 1'b0;
        ctrl_busy_o   = 1'b0;
        instr_req_o   = 1'b0;
        halt_if_o     = 1'b1;
        halt_id_o     = 1'b1;
        ctrl_fsm_ns   = SLEEP;
      end

      // instruction in if_stage is already valid
      SLEEP:
      begin
        // we begin execution when an
        // interrupt has arrived
        is_decoding_o = 1'b0;
        ctrl_busy_o   = 1'b0;
        instr_req_o   = 1'b0;
        halt_if_o     = 1'b1;
        halt_id_o     = 1'b1;


        // normal execution flow
        // in debug mode or single step mode we leave immediately (wfi=nop)
        if (irq_i || (debug_req_i || debug_mode_q || debug_single_step_i)) begin
          ctrl_fsm_ns  = FIRST_FETCH;
        end

      end

      FIRST_FETCH:
      begin
        is_decoding_o = 1'b0;
        first_fetch_o = 1'b1;
        // Stall because of IF miss
        if ((id_ready_i == 1'b1) )
        begin
          ctrl_fsm_ns = DECODE;
        end

        // handle interrupts
        if (irq_req_ctrl_i & irq_enable_int) begin
          // This assumes that the pipeline is always flushed before
          // going to sleep.
          ctrl_fsm_ns = IRQ_TAKEN_IF;
          halt_if_o   = 1'b1;
          halt_id_o   = 1'b1;
        end

        if (debug_req_i & (~debug_mode_q))
        begin
          ctrl_fsm_ns = DBG_TAKEN_IF;
          halt_if_o   = 1'b1;
          halt_id_o   = 1'b1;
        end

      end

      DECODE:
      begin

          if (branch_taken_ex_i)
          begin //taken branch
            // there is a branch in the EX stage that is taken

            is_decoding_o = 1'b0;

            pc_mux_o      = PC_BRANCH;
            pc_set_o      = 1'b1;

            // if we want to debug, flush the pipeline
            // the current_pc_if will take the value of the next instruction to
            // be executed (NPC)

          end  //taken branch

          else if (data_err_i)
          begin //data error
            // the current LW or SW have been blocked by the PMP

            is_decoding_o     = 1'b0;
            halt_if_o         = 1'b1;
            halt_id_o         = 1'b1;
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode

            csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
            ctrl_fsm_ns       = FLUSH_WB;

          end  //data error

          else if (is_fetch_failed_i)
          begin

            // the current instruction has been blocked by the PMP

            is_decoding_o     = 1'b0;
            halt_id_o         = 1'b1;
            halt_if_o         = 1'b1;
            csr_save_if_o     = 1'b1;
            csr_save_cause_o  = 1'b1;

            //no jump in this stage as we have to wait one cycle to go to Machine Mode

            csr_cause_o       = EXC_CAUSE_INSTR_FAULT;
            ctrl_fsm_ns       = FLUSH_WB;


          end
          // decode and execute instructions only if the current conditional
          // branch in the EX stage is either not taken, or there is no
          // conditional branch in the EX stage
          else if (instr_valid_i) //valid block or replay after interrupt speculation
          begin // now analyze the current instruction in the ID stage

            is_decoding_o = 1'b1;

            unique case(1'b1)

              //irq_req_ctrl_i comes from a FF in the interrupt controller
              //irq_enable_int: check again irq_enable_int because xIE could have changed
              //don't serve in debug mode
              irq_req_ctrl_i & irq_enable_int & (~debug_req_i) & (~debug_mode_q):
              begin
                //Serving the external interrupt
                halt_if_o     = 1'b1;
                halt_id_o     = 1'b1;
                ctrl_fsm_ns   = IRQ_FLUSH;

              end


              debug_req_i & (~debug_mode_q):
              begin
                //Serving the debug
                halt_if_o     = 1'b1;
                halt_id_o     = 1'b1;
                ctrl_fsm_ns   = DBG_FLUSH;
              end


              default:
              begin

                exc_kill_o    = irq_req_ctrl_i ? 1'b1 : 1'b0;

                if(illegal_insn_i) begin

                  halt_if_o         = 1'b1;
                  halt_id_o         = 1'b1;
                  csr_save_id_o     = 1'b1;
                  csr_save_cause_o  = 1'b1;
                  csr_cause_o       = EXC_CAUSE_ILLEGAL_INSN;
                  ctrl_fsm_ns       = FLUSH_EX;
                  illegal_insn_n    = 1'b1;
                end else begin

                  //decoding block
                  unique case (1'b1)

                    jump_in_dec: begin
                    // handle unconditional jumps
                    // we can jump directly since we know the address already
                    // we don't need to worry about conditional branches here as they
                    // will be evaluated in the EX stage
                      pc_mux_o = PC_JUMP;
                      // if there is a jr stall, wait for it to be gone
                      if ((~jr_stall_o) && (~jump_done_q)) begin
                        pc_set_o    = 1'b1;
                        jump_done   = 1'b1;
                      end

                    end
                    ebrk_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b1;

                      if (debug_mode_q)
                        // we got back to the park loop in the debug rom
                        ctrl_fsm_ns = DBG_FLUSH;

                      else if (ebrk_force_debug_mode)
                        // debug module commands us to enter debug mode anyway
                        ctrl_fsm_ns  = DBG_FLUSH;

                      else begin
                        // otherwise just a normal ebreak exception
                        csr_save_id_o     = 1'b1;
                        csr_save_cause_o  = 1'b1;

                        ctrl_fsm_ns = FLUSH_EX;
                        csr_cause_o = EXC_CAUSE_BREAKPOINT;
                      end

                    end
                    pipe_flush_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b1;
                      ctrl_fsm_ns   = FLUSH_EX;
                    end
                    ecall_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b1;
                      csr_save_id_o     = 1'b1;
                      csr_save_cause_o  = 1'b1;
                      csr_cause_o   = current_priv_lvl_i == PRIV_LVL_U ? EXC_CAUSE_ECALL_UMODE : EXC_CAUSE_ECALL_MMODE;
                      ctrl_fsm_ns   = FLUSH_EX;
                    end
                    fencei_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b1;
                      ctrl_fsm_ns   = FLUSH_EX;
                    end
                    mret_insn_i | uret_insn_i | dret_insn_i: begin
                      halt_if_o     = 1'b1;
                      halt_id_o     = 1'b1;
                      ctrl_fsm_ns   = FLUSH_EX;
                    end
                    csr_status_i: begin
                      halt_if_o     = 1'b1;
                      ctrl_fsm_ns   = id_ready_i ? FLUSH_EX : DECODE;
                    end
                    data_load_event_i: begin
                      ctrl_fsm_ns   = id_ready_i ? ELW_EXE : DECODE;
                      halt_if_o     = 1'b1;
                    end
                    default:;

                  endcase // unique case (1'b1)
                end

                if (debug_single_step_i & ~debug_mode_q) begin
                    // prevent any more instructions from executing
                    halt_if_o = 1'b1;

                    // we don't handle dret here because its should be illegal
                    // anyway in this context

                    // illegal, ecall, ebrk and xrettransition to later to a DBG
                    // state since we need the return address which is
                    // determined later

                    // TODO: handle ebrk_force_debug_mode plus single stepping over ebreak
                    if (id_ready_i) begin
                    // make sure the current instruction has been executed
                        unique case(1'b1)
                        illegal_insn_i | ecall_insn_i:
                            ctrl_fsm_ns = FLUSH_EX; // TODO: flush ex
                        (~ebrk_force_debug_mode & ebrk_insn_i):
                            ctrl_fsm_ns = FLUSH_EX;
                        mret_insn_i | uret_insn_i:
                            ctrl_fsm_ns = FLUSH_EX;
                        branch_in_id:
                            ctrl_fsm_ns = DBG_WAIT_BRANCH;
                        default:
                            // regular instruction
                            ctrl_fsm_ns = DBG_FLUSH;
                        endcase // unique case (1'b1)
                    end
                end

              end //decoding block
            endcase
          end  //valid block
          else begin
            is_decoding_o         = 1'b0;
            perf_pipeline_stall_o = data_load_event_i;
          end
      end


      // flush the pipeline, insert NOP into EX stage
      FLUSH_EX:
      begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        if (data_err_i)
        begin //data error
            // the current LW or SW have been blocked by the PMP
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode
            csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
            ctrl_fsm_ns       = FLUSH_WB;
            //putting illegal to 0 as if it was 1, the core is going to jump to the exception of the EX stage,
            //so the illegal was never executed
            illegal_insn_n    = 1'b0;
        end  //data erro
        else if (ex_valid_i)
          //check done to prevent data harzard in the CSR registers
          ctrl_fsm_ns = FLUSH_WB;
      end


      IRQ_FLUSH:
      begin
        is_decoding_o = 1'b0;

        halt_if_o   = 1'b1;
        halt_id_o   = 1'b1;

        perf_pipeline_stall_o = data_load_event_i;

        if (data_err_i)
        begin //data error
            // the current LW or SW have been blocked by the PMP
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode
            csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
            ctrl_fsm_ns       = FLUSH_WB;

        end  //data error
        else begin
          if(irq_i & irq_enable_int) begin
            ctrl_fsm_ns = IRQ_TAKEN_ID;
          end else begin
            // we can go back to decode in case the IRQ is not taken (no ELW REPLAY)
            exc_kill_o   = 1'b1;
            ctrl_fsm_ns  = DECODE;
          end
        end
      end


      ELW_EXE:
      begin
        is_decoding_o = 1'b0;

        halt_if_o   = 1'b1;
        halt_id_o   = 1'b1;


        //if we are here, a elw is executing now in the EX stage
        //or if an interrupt has been received
        //the ID stage contains the PC_ID of the elw, therefore halt_id is set to invalid the instruction
        //If an interrupt occurs, we replay the ELW
        //No needs to check irq_int_req_i since in the EX stage there is only the elw, no CSR pendings
        if(id_ready_i)
          ctrl_fsm_ns = (debug_req_i & ~debug_mode_q) ? DBG_FLUSH : IRQ_FLUSH;
          // if from the ELW EXE we go to IRQ_FLUSH, it is assumed that if there was an IRQ req together with the grant and IE was valid, then
          // there must be no hazard due to xIE
        else
          ctrl_fsm_ns = ELW_EXE;

        perf_pipeline_stall_o = data_load_event_i;
      end

      IRQ_TAKEN_ID:
      begin
        is_decoding_o = 1'b0;

        pc_set_o          = 1'b1;
        pc_mux_o          = PC_EXCEPTION;
        exc_pc_mux_o      = EXC_PC_IRQ;
        exc_cause_o       = {1'b0,irq_id_ctrl_i};

        csr_irq_sec_o     = irq_sec_ctrl_i;
        csr_save_cause_o  = 1'b1;
        csr_cause_o       = {1'b1,irq_id_ctrl_i};

        csr_save_id_o     = 1'b1;

        if(irq_sec_ctrl_i)
          trap_addr_mux_o  = TRAP_MACHINE;
        else
          trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

        irq_ack_o         = 1'b1;
        exc_ack_o         = 1'b1;
        ctrl_fsm_ns       = DECODE;
      end


      IRQ_TAKEN_IF:
      begin
        is_decoding_o = 1'b0;

        pc_set_o          = 1'b1;
        pc_mux_o          = PC_EXCEPTION;
        exc_pc_mux_o      = EXC_PC_IRQ;
        exc_cause_o       = {1'b0,irq_id_ctrl_i};

        csr_irq_sec_o     = irq_sec_ctrl_i;
        csr_save_cause_o  = 1'b1;
        csr_cause_o       = {1'b1,irq_id_ctrl_i};

        csr_save_if_o     = 1'b1;

        if(irq_sec_ctrl_i)
          trap_addr_mux_o  = TRAP_MACHINE;
        else
          trap_addr_mux_o  = current_priv_lvl_i == PRIV_LVL_U ? TRAP_USER : TRAP_MACHINE;

        irq_ack_o         = 1'b1;
        exc_ack_o         = 1'b1;
        ctrl_fsm_ns       = DECODE;
      end


      // flush the pipeline, insert NOP into EX and WB stage
      FLUSH_WB:
      begin
        is_decoding_o = 1'b0;

        halt_if_o = 1'b1;
        halt_id_o = 1'b1;

        ctrl_fsm_ns = DECODE;

        if(data_err_q) begin
            //data_error
            pc_mux_o              = PC_EXCEPTION;
            pc_set_o              = 1'b1;
            trap_addr_mux_o       = TRAP_MACHINE;
            //little hack during testing
            exc_pc_mux_o          = EXC_PC_EXCEPTION;
            exc_cause_o           = data_we_ex_i ? EXC_CAUSE_LOAD_FAULT : EXC_CAUSE_STORE_FAULT;

        end
        else if (is_fetch_failed_i) begin
            //data_error
            pc_mux_o              = PC_EXCEPTION;
            pc_set_o              = 1'b1;
            trap_addr_mux_o       = TRAP_MACHINE;
            exc_pc_mux_o          = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
            exc_cause_o           = EXC_CAUSE_INSTR_FAULT;

        end
        else begin
          if(illegal_insn_q) begin
              //exceptions
              pc_mux_o              = PC_EXCEPTION;
              pc_set_o              = 1'b1;
              trap_addr_mux_o       = TRAP_MACHINE;
              exc_pc_mux_o          = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
              illegal_insn_n        = 1'b0;
              if (debug_single_step_i && ~debug_mode_q)
                  ctrl_fsm_ns = DBG_TAKEN_IF;
          end else begin
            unique case(1'b1)
              ebrk_insn_i: begin
                  //ebreak
                  pc_mux_o              = PC_EXCEPTION;
                  pc_set_o              = 1'b1;
                  trap_addr_mux_o       = TRAP_MACHINE;
                  exc_pc_mux_o          = EXC_PC_EXCEPTION;

                  if (debug_single_step_i && ~debug_mode_q)
                      ctrl_fsm_ns = DBG_TAKEN_IF;
              end
              ecall_insn_i: begin
                  //ecall
                  pc_mux_o              = PC_EXCEPTION;
                  pc_set_o              = 1'b1;
                  trap_addr_mux_o       = TRAP_MACHINE;
                  exc_pc_mux_o          = debug_mode_q ? EXC_PC_DBE : EXC_PC_EXCEPTION;
                  // TODO: why is this here, signal only needed for async exceptions
                  exc_cause_o           = EXC_CAUSE_ECALL_MMODE;

                  if (debug_single_step_i && ~debug_mode_q)
                      ctrl_fsm_ns = DBG_TAKEN_IF;
              end

              mret_insn_i: begin
                 csr_restore_mret_id_o =  1'b1;
                 ctrl_fsm_ns           = XRET_JUMP;
              end
              uret_insn_i: begin
                 csr_restore_uret_id_o =  1'b1;
                 ctrl_fsm_ns           = XRET_JUMP;
              end
              dret_insn_i: begin
                  csr_restore_dret_id_o = 1'b1;
                  ctrl_fsm_ns           = XRET_JUMP;
              end

              csr_status_i: begin

              end
              pipe_flush_i: begin
                  ctrl_fsm_ns = WAIT_SLEEP;
              end
              fencei_insn_i: begin
                  // we just jump to instruction after the fence.i since that
                  // forces the instruction cache to refetch
                  pc_mux_o              = PC_FENCEI;
                  pc_set_o              = 1'b1;
              end
              default:;
            endcase
          end
        end

      end

      XRET_JUMP:
      begin
        is_decoding_o = 1'b0;
        ctrl_fsm_ns   = DECODE;
        unique case(1'b1)
          mret_dec_i: begin
              //mret
              pc_mux_o              = debug_mode_q ? PC_EXCEPTION : PC_MRET;
              pc_set_o              = 1'b1;
              exc_pc_mux_o          = EXC_PC_DBE;
          end
          uret_dec_i: begin
              //uret
              pc_mux_o              = debug_mode_q ? PC_EXCEPTION : PC_URET;
              pc_set_o              = 1'b1;
              exc_pc_mux_o          = EXC_PC_DBE;
          end
          dret_dec_i: begin
              //dret
              //TODO: is illegal when not in debug mode
              pc_mux_o              = PC_DRET;
              pc_set_o              = 1'b1;
              debug_mode_n          = 1'b0;
          end
          default:;
        endcase

        if (debug_single_step_i && ~debug_mode_q) begin
          ctrl_fsm_ns = DBG_TAKEN_IF;
        end
      end

      // a branch was in ID when a trying to go to debug rom wait until we can
      // determine branch target address (for saving into dpc) before proceeding
      DBG_WAIT_BRANCH:
      begin
        is_decoding_o = 1'b0;
        halt_if_o = 1'b1;

        if (branch_taken_ex_i) begin
          // there is a branch in the EX stage that is taken
          pc_mux_o = PC_BRANCH;
          pc_set_o = 1'b1;
        end

        ctrl_fsm_ns = DBG_FLUSH;
      end

      // We enter this state when we encounter
      // 1. ebreak during debug mode
      // 2. ebreak with forced entry into debug mode (ebreakm or ebreaku set).
      // 3. halt request during decode
      // Regular ebreak's go through FLUSH_EX and FLUSH_WB.
      // For 1. we don't update dcsr and dpc while for 2. and 3. we do
      // (debug-spec p.39). Critically dpc is set to the address of ebreak and
      // not to the next instruction's (which is why we save the pc in id).
      DBG_TAKEN_ID:
      begin
        is_decoding_o     = 1'b0;
        pc_set_o          = 1'b1;
        pc_mux_o          = PC_EXCEPTION;
        exc_pc_mux_o      = EXC_PC_DBD;
        if ((debug_req_i && (~debug_mode_q)) ||
            (ebrk_insn_i && ebrk_force_debug_mode && (~debug_mode_q))) begin
            csr_save_cause_o = 1'b1;
            csr_save_id_o    = 1'b1;
            debug_csr_save_o = 1'b1;
            if (debug_req_i)
                debug_cause_o = DBG_CAUSE_HALTREQ;
            if (ebrk_insn_i)
                debug_cause_o = DBG_CAUSE_EBREAK;
        end
        ctrl_fsm_ns  = DECODE;
        debug_mode_n = 1'b1;
      end

      DBG_TAKEN_IF:
      begin
        is_decoding_o     = 1'b0;
        pc_set_o          = 1'b1;
        pc_mux_o          = PC_EXCEPTION;
        exc_pc_mux_o      = EXC_PC_DBD;
        csr_save_cause_o  = 1'b1;
        debug_csr_save_o  = 1'b1;
        if (debug_single_step_i)
            debug_cause_o = DBG_CAUSE_STEP;
        if (debug_req_i)
            debug_cause_o = DBG_CAUSE_HALTREQ;
        if (ebrk_insn_i)
            debug_cause_o = DBG_CAUSE_EBREAK;
        csr_save_if_o   = 1'b1;
        ctrl_fsm_ns     = DECODE;
        debug_mode_n    = 1'b1;
      end

      DBG_FLUSH:
      begin
        is_decoding_o = 1'b0;

        halt_if_o   = 1'b1;
        halt_id_o   = 1'b1;

        perf_pipeline_stall_o = data_load_event_i;

        if (data_err_i)
        begin //data error
            // the current LW or SW have been blocked by the PMP
            csr_save_ex_o     = 1'b1;
            csr_save_cause_o  = 1'b1;
            data_err_ack_o    = 1'b1;
            //no jump in this stage as we have to wait one cycle to go to Machine Mode
            csr_cause_o       = data_we_ex_i ? EXC_CAUSE_STORE_FAULT : EXC_CAUSE_LOAD_FAULT;
            ctrl_fsm_ns       = FLUSH_WB;

        end  //data error
        else begin
          if(debug_mode_q) begin //ebreak in debug rom
            ctrl_fsm_ns = DBG_TAKEN_ID;
          end else if(data_load_event_i) begin
            ctrl_fsm_ns = DBG_TAKEN_ID;
          end else if (debug_single_step_i) begin
            // save the next instruction when single stepping regular insn
            ctrl_fsm_ns  = DBG_TAKEN_IF;
          end else begin
            ctrl_fsm_ns  = DBG_TAKEN_ID;
          end
        end
      end
      // Debug end

      default: begin
        is_decoding_o = 1'b0;
        instr_req_o = 1'b0;
        ctrl_fsm_ns = RESET;
      end
    endcase
  end

  /////////////////////////////////////////////////////////////
  //  ____  _        _ _    ____            _             _  //
  // / ___|| |_ __ _| | |  / ___|___  _ __ | |_ _ __ ___ | | //
  // \___ \| __/ _` | | | | |   / _ \| '_ \| __| '__/ _ \| | //
  //  ___) | || (_| | | | | |__| (_) | | | | |_| | | (_) | | //
  // |____/ \__\__,_|_|_|  \____\___/|_| |_|\__|_|  \___/|_| //
  //                                                         //
  /////////////////////////////////////////////////////////////
  

  logic load_stall_oi_reg_cond ; // load-stall of other issue register condition

  logic jr_fw_from_this_issue ;  // detected forward from this issue to this issue  jump register of jr
  logic jr_fw_from_other_issue ; // detected forward from other issue to this issue jump register of jr

  `ifdef HAMSA_DIX  // Dual-Issue regfile interface
  generate
  if (ISSUE2_INST==0) begin :gb1  // PI
    assign load_stall_oi_reg_cond = di_intrfc_ctrl.i2_load_stall_cond  ; 
    assign di_intrfc_ctrl.pi_load_stall = load_stall_o ;


   // Prevent DI in any 'special transition.
   // Notice DECODE is the common state other than special transitions few cycles such as when entering interrupt.  
   // Probably not all-non DECODE states should prevent DI (if at all any) 
   // however since states other than DECODE are very rare we prevent DI for all of them to be on the sage side.
   // Applying both current and next state to be safe.
    assign di_intrfc_ctrl.pi_unusal_state_prevent_di = (ctrl_fsm_cs != DECODE) || (ctrl_fsm_ns != DECODE) ; 
    // Kill I2 in progress due to unusual redirect on PI.    
    //assign di_intrfc_ctrl.pi_unusal_state_kill_di = (ctrl_fsm_cs==IRQ_FLUSH)||(ctrl_fsm_cs==DBG_FLUSH) ;  
    // Not needed any more as we are propogating the halt condition    
    assign di_intrfc_ctrl.pi_unusal_state_kill_di = 0 ;

        
  end else begin :gb2             // I2
    assign di_intrfc_ctrl.i2_load_stall_cond = instr_valid_i && (oi_reg_d_ex_is_reg_a_i || oi_reg_d_ex_is_reg_b_i || oi_reg_d_ex_is_reg_c_i) ;   
     // || (is_decoding_o && regfile_we_id_i && (oi_regfile_waddr_ex_i == regfile_alu_waddr_id_i))  ; //  NEED TO CHECK IF NEEDED !!! XXX

    assign load_stall_oi_reg_cond = 1'b0 ; // Eventuelly PI stall apply to both PI and SI
  end
  endgenerate
     
  `else
   assign load_stall_oi_reg_cond = 1'b0 ;
  `endif 
 
  always_comb
  begin
    load_stall_o   = 1'b0;
    jr_stall_o     = 1'b0;
    deassert_we_o  = 1'b0;
    jr_fw_from_this_issue = 1'b0;
    jr_fw_from_other_issue = 1'b0;    

    // deassert WE when the core is not decoding instructions
    if (~is_decoding_o)
      deassert_we_o = 1'b1;

    // deassert WE in case of illegal instruction
    if (illegal_insn_i)
      deassert_we_o = 1'b1;
       

    // Stall because of load operation
    if (
          ( (data_req_ex_i == 1'b1) && (regfile_we_ex_i == 1'b1) ||
           (wb_ready_i == 1'b0) && (regfile_we_wb_i == 1'b1)
          ) &&
          ( (reg_d_ex_is_reg_a_i == 1'b1) || (reg_d_ex_is_reg_b_i == 1'b1) || (reg_d_ex_is_reg_c_i == 1'b1) ||
            (is_decoding_o && regfile_we_id_i && (regfile_waddr_ex_i == regfile_alu_waddr_id_i)) ||
             load_stall_oi_reg_cond 
           )
       )
    begin
      deassert_we_o   = 1'b1;
      load_stall_o    = 1'b1;
    end
    
     // Propogate load-stall from PI to I2
    `ifdef HAMSA_DIX  
      if ((ISSUE2_INST==1) && di_intrfc_ctrl.pi_load_stall)
      begin
       deassert_we_o   = 1'b1;
       load_stall_o    = 1'b1;
      end
    `endif


    // Stall because of jr path
    // - always stall if a result is to be forwarded to the PC
    // we don't care about in which state the ctrl_fsm is as we deassert_we
    // anyway when we are not in DECODE
    
    jr_fw_from_this_issue =    (regfile_we_wb_i     && reg_d_wb_is_reg_a_i) 
                            || (regfile_we_ex_i     && reg_d_ex_is_reg_a_i)
                            || (regfile_alu_we_fw_i && reg_d_alu_is_reg_a_i) ;
    
    jr_fw_from_other_issue =   (oi_regfile_we_wb_i     && oi_reg_d_wb_is_reg_a_i) 
                            || (oi_regfile_alu_we_fw_i && oi_reg_d_alu_is_reg_a_i) ;

 
    if ((jump_in_dec_i==BRANCH_JALR) && (jr_fw_from_this_issue || jr_fw_from_other_issue))    
    begin
      jr_stall_o      = 1'b1;
      deassert_we_o   = 1'b1;
    end

  end


  // stall because of misaligned data access
  assign misaligned_stall_o = data_misaligned_i;

  // APU dependency stalls (data hazards)
  assign apu_stall_o = apu_read_dep_i | (apu_write_dep_i & ~apu_en_i);

  // Forwarding control unit
  always_comb
  begin
  
    // default assignments

   `ifdef HAMSA_DIX  // Dual-Issue regfile interface
    oi_fw_to_op_a_o = 1'b0 ;
    oi_fw_to_op_b_o = 1'b0 ; 
    oi_fw_to_op_c_o = 1'b0 ;
   `endif 
   
    ti_i2_fw_to_op_a = 0 ;
    ti_i2_fw_to_op_b = 0 ;
    ti_i2_fw_to_op_c = 0 ;
    
    
    operand_a_fw_mux_sel_o = SEL_REGFILE;
    operand_b_fw_mux_sel_o = SEL_REGFILE;
    operand_c_fw_mux_sel_o = SEL_REGFILE;

    // Forwarding WB -> ID
    if (regfile_we_wb_i == 1'b1)
    begin
      if (reg_d_wb_is_reg_a_i == 1'b1) begin
       ti_i2_fw_to_op_a = (ISSUE2_INST==1);
        operand_a_fw_mux_sel_o = SEL_FW_WB;
      end
      if (reg_d_wb_is_reg_b_i == 1'b1) begin
        ti_i2_fw_to_op_b = (ISSUE2_INST==1);
        operand_b_fw_mux_sel_o = SEL_FW_WB;
      end
      if (reg_d_wb_is_reg_c_i == 1'b1) begin
       ti_i2_fw_to_op_c = (ISSUE2_INST==1);
        operand_c_fw_mux_sel_o = SEL_FW_WB;
      end
    end
    

    // Forwarding EX -> ID
    if (regfile_alu_we_fw_i == 1'b1)
    begin
     if (reg_d_alu_is_reg_a_i == 1'b1) begin
       ti_i2_fw_to_op_a = (ISSUE2_INST==1);
       operand_a_fw_mux_sel_o = SEL_FW_EX;
     end
     if (reg_d_alu_is_reg_b_i == 1'b1) begin
       ti_i2_fw_to_op_b = (ISSUE2_INST==1);
       operand_b_fw_mux_sel_o = SEL_FW_EX;
     end
     if (reg_d_alu_is_reg_c_i == 1'b1) begin
       ti_i2_fw_to_op_c = (ISSUE2_INST==1);
       operand_c_fw_mux_sel_o = SEL_FW_EX;
     end
    end

   `ifdef HAMSA_DIX  // HAMSA_DIX Forwarding control 
   
    oi_fw_to_op_a_o = 1'b0 ;
    oi_fw_to_op_b_o = 1'b0 ; 
    oi_fw_to_op_c_o = 1'b0 ;
    
                                                                
    if (oi_regfile_we_wb_i == 1'b1)
    begin    
    // Notice issue2 has priority in case of conflict because it has the later instruction.
    

      if ((oi_reg_d_wb_is_reg_a_i == 1'b1)  && !ti_i2_fw_to_op_a)  begin
        oi_fw_to_op_a_o = 1'b1 ;
        operand_a_fw_mux_sel_o = SEL_FW_WB;
      end
      if ((oi_reg_d_wb_is_reg_b_i == 1'b1)  && !ti_i2_fw_to_op_b) begin
        oi_fw_to_op_b_o = 1'b1 ;           
        operand_b_fw_mux_sel_o = SEL_FW_WB;
      end                                   
      if ((oi_reg_d_wb_is_reg_c_i == 1'b1)  && !ti_i2_fw_to_op_c) begin    
        oi_fw_to_op_c_o = 1'b1 ;
        operand_c_fw_mux_sel_o = SEL_FW_WB;
      end
    end
        
    
    // Forwarding EX -> ID
    if ((oi_regfile_alu_we_fw_i == 1'b1)  && !data_misaligned_i)     
          // Notice that on misaligned memory access , 
          // the ID/EX-ALU stages recalculate the memory address for the second access. 
          // Thus forwarding from other issue should be avoided on the misaligned second access            
    begin


     if ((oi_reg_d_alu_is_reg_a_i == 1'b1) && !ti_i2_fw_to_op_a) begin
       oi_fw_to_op_a_o = 1'b1 ;
       operand_a_fw_mux_sel_o = SEL_FW_EX;
     end
     if ((oi_reg_d_alu_is_reg_b_i == 1'b1) && !ti_i2_fw_to_op_b) begin
       oi_fw_to_op_b_o = 1'b1 ;
       operand_b_fw_mux_sel_o = SEL_FW_EX;
     end
     if ((oi_reg_d_alu_is_reg_c_i == 1'b1) && !ti_i2_fw_to_op_c) begin
       oi_fw_to_op_c_o = 1'b1 ;
       operand_c_fw_mux_sel_o = SEL_FW_EX;       
     end
    end    
    
   `endif 

    // for misaligned memory accesses
    if (data_misaligned_i)
    begin
      operand_a_fw_mux_sel_o  = SEL_FW_EX;
      operand_b_fw_mux_sel_o  = SEL_REGFILE;
    end else if (mult_multicycle_i) begin
      operand_c_fw_mux_sel_o  = SEL_FW_EX;
    end
  end    // always_comb - Forwarding control

  // update registers
  always_ff @(posedge clk , negedge rst_n)
  begin : UPDATE_REGS
    if ( rst_n == 1'b0 )
    begin
      ctrl_fsm_cs    <= RESET;
      jump_done_q    <= 1'b0;
      boot_done_q    <= 1'b0;
      data_err_q     <= 1'b0;

      debug_mode_q   <= 1'b0;
      illegal_insn_q <= 1'b0;

    end
    else
    begin
      ctrl_fsm_cs    <= ctrl_fsm_ns;
      boot_done_q    <= boot_done | (~boot_done & boot_done_q);
      // clear when id is valid (no instruction incoming)
      jump_done_q    <= jump_done & (~id_ready_i);

      data_err_q     <= data_err_i;

      debug_mode_q   <= debug_mode_n;

      illegal_insn_q <= illegal_insn_n;

    end
  end

  // Performance Counters
  assign perf_jump_o      = (jump_in_id_i == BRANCH_JAL || jump_in_id_i == BRANCH_JALR);
  assign perf_jr_stall_o  = jr_stall_o;
  assign perf_ld_stall_o  = load_stall_o;

  // debug mode
  assign debug_mode_o = debug_mode_q;


  //----------------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------------
  // make sure that taken branches do not happen back-to-back, as this is not
  // possible without branch prediction in the IF stage
  `ifndef VERILATOR
  assert property (
    @(posedge clk) (branch_taken_ex_i) |=> (~branch_taken_ex_i) ) else $warning("Two branches back-to-back are taken");
  assert property (
    @(posedge clk) (~('0 & irq_req_ctrl_i)) ) else $warning("Both dbg_req_i and irq_req_ctrl_i are active");
  `endif
endmodule // controller
