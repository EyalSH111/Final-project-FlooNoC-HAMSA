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
// Engineer:       Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    hwloop controller                                          //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Hardware loop controller unit. This unit is responsible to //
//                 handle hardware loops. Tasks are:                          //
//                 a) compare PC to all stored end addresses                  //
//                 b) jump to the right start address if counter =/ 0         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module riscv_hwloop_controller
#(
  parameter N_REGS = 2
)
(
  // from id stage
  input  logic [31:0]              current_pc_i,

  // from hwloop_regs
  input  logic [N_REGS-1:0] [31:0] hwlp_start_addr_i,
  input  logic [N_REGS-1:0] [31:0] hwlp_end_addr_i,
  input  logic [N_REGS-1:0] [31:0] hwlp_counter_i,

  // to hwloop_regs
  output logic [N_REGS-1:0]        hwlp_dec_cnt_o,

  // from pipeline stages
  input  logic [N_REGS-1:0]        hwlp_dec_cnt_id_i,

  // to id stage
  output logic                     hwlp_jump_o,
  output logic [31:0]              hwlp_targ_addr_o
  
  `ifdef HAMSA_DI  // Dual-Issue Logic optional interface
  ,input current_is_compressed_i
  ,input  i2_instr_allocated
  ,output pi_hwlp_di_prevent_cond          
  `endif   
);

  logic [N_REGS-1:0] pc_is_end_addr;  

  // DI support
  logic [N_REGS-1:0] i2_pc_is_end_addr ;   // allocated I2 PC actually equal to the indexed hwloop end address

 `ifdef HAMSA_DI  
   logic [31:0] consecutive_pc ; 
   assign consecutive_pc = current_pc_i + (current_is_compressed_i ? 2:4) ;    
   logic [N_REGS-1:0] consecutive_pc_eql_hwlp_end_addr ;  // consecutive pc equals hwlp end address
   logic [N_REGS-1:0] i2_pc_is_end_addr_incase_alloc ;    // I2 PC potentially  equal to the indexed hwloop end address
 
  `else
   assign i2_pc_is_end_addr = '0 ;  /// Applicable only in DI  
  `endif

  // generate comparators. check for end address and the loop counter
  genvar i;
  generate

    for (i = 0; i < N_REGS; i++) begin  : nr    

    `ifdef HAMSA_DI     
      assign consecutive_pc_eql_hwlp_end_addr[i] = (consecutive_pc==hwlp_end_addr_i[i]) ;   
    `endif
    
    // Handle Primary Issue
      always @(*)
      begin
       pc_is_end_addr[i] = 1'b0;        
       if (current_pc_i == hwlp_end_addr_i[i]) begin
            if (hwlp_counter_i[i][31:2] != 30'h0) begin
              pc_is_end_addr[i] = 1'b1;
            end else begin
              case (hwlp_counter_i[i][1:0])
                2'b11:        pc_is_end_addr[i] = 1'b1;
                2'b10:        pc_is_end_addr[i] = ~hwlp_dec_cnt_id_i[i]; // only when there is nothing in flight
                2'b01, 2'b00: pc_is_end_addr[i] = 1'b0;
              endcase
            end
       end
      end // always

  `ifdef HAMSA_DI    // Handle I2
       always @(*)
       begin 
        i2_pc_is_end_addr_incase_alloc[i] = 1'b0; 
        if (consecutive_pc_eql_hwlp_end_addr[i]) begin
             if (hwlp_counter_i[i][31:2] != 30'h0) begin
               i2_pc_is_end_addr_incase_alloc[i] = 1'b1;
             end else begin
               case (hwlp_counter_i[i][1:0])
                 2'b11:        i2_pc_is_end_addr_incase_alloc[i] = 1'b1;
                 2'b10:        i2_pc_is_end_addr_incase_alloc[i] = ~hwlp_dec_cnt_id_i[i]; // only when there is nothing in flight
                 2'b01, 2'b00: i2_pc_is_end_addr_incase_alloc[i] = 1'b0;
               endcase            
             end
        end
        i2_pc_is_end_addr[i] = i2_instr_allocated && i2_pc_is_end_addr_incase_alloc[i] ;
       end 
   `endif            
           
    end
  endgenerate

  integer j;

  // select corresponding start address and decrement counter
  always_comb
  begin
    hwlp_targ_addr_o = '0;
    hwlp_dec_cnt_o   = '0;

    for (j = 0; j < N_REGS; j++) begin
      if (pc_is_end_addr[j] || i2_pc_is_end_addr[j]) begin
        hwlp_targ_addr_o  = hwlp_start_addr_i[j];
        hwlp_dec_cnt_o[j] = 1'b1;
        break;
      end
    end
  end

  // output signal for ID stage
  assign hwlp_jump_o = (|pc_is_end_addr) || (|i2_pc_is_end_addr) ;

  `ifdef HAMSA_DI 
    //logic hwlp_jump_incase_alloc ;
    //assign hwlp_jump_incase_alloc = (|i2_pc_is_end_addr_incase_alloc);   
    assign pi_hwlp_di_prevent_cond = (|pc_is_end_addr) ; // || (|i2_pc_is_end_addr_incase_alloc) ; // || !hwlp_jump_incase_alloc  ; 
  `endif
                               
endmodule
