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
// Engineer:       Francesco Conti - f.conti@unibo.it                         //
//                                                                            //
// Additional contributions by:                                               //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    RISC-V register file                                       //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Register file with 31x 32 bit wide registers. Register 0   //
//                 is fixed to 0. This register file is based on flip-flops.  //
//                 Also supports the fp-register file now if FPU=1            //
//                 If Zfinx is 1, floating point operations take values from  //
//                 the X register file                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module riscv_register_file
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32,
    parameter FPU           = 0,
    parameter Zfinx         = 0
)
(
    // Clock and Reset
    input  logic         clk,
    input  logic         rst_n,

    input  logic         test_en_i,

    //Read port R1
    input  logic [ADDR_WIDTH-1:0]  raddr_a_i,
    output logic [DATA_WIDTH-1:0]  rdata_a_o,

    //Read port R2
    input  logic [ADDR_WIDTH-1:0]  raddr_b_i,
    output logic [DATA_WIDTH-1:0]  rdata_b_o,

    //Read port R3
    input  logic [ADDR_WIDTH-1:0]  raddr_c_i,
    output logic [DATA_WIDTH-1:0]  rdata_c_o,

    // Write port W1
    input logic [ADDR_WIDTH-1:0]   waddr_a_i,
    input logic [DATA_WIDTH-1:0]   wdata_a_i,
    input logic                    we_a_i,

    // Write port W2
    input logic [ADDR_WIDTH-1:0]   waddr_b_i,
    input logic [DATA_WIDTH-1:0]   wdata_b_i,
    input logic                    we_b_i
    
   `ifdef HAMSA_DI  // Dual-Issue regfile interface
    ,di_regfile_interface.pi di_intrfc_regfile   // Notice regfile exists only in the primary issue
   `endif
    
);

  // number of integer registers
  localparam    NUM_WORDS     = 2**(ADDR_WIDTH-1);
  // number of floating point registers
  localparam    NUM_FP_WORDS  = 2**(ADDR_WIDTH-1);
  localparam    NUM_TOT_WORDS = FPU ? ( Zfinx ? NUM_WORDS : NUM_WORDS + NUM_FP_WORDS ) : NUM_WORDS;

  // integer register file
  logic [NUM_WORDS-1:0][DATA_WIDTH-1:0]     mem;

  // fp register file
  logic [NUM_FP_WORDS-1:0][DATA_WIDTH-1:0]  mem_fp;

  // masked write addresses
  logic [ADDR_WIDTH-1:0]                    waddr_a;
  logic [ADDR_WIDTH-1:0]                    waddr_b;

  // write enable signals for all registers
  logic [NUM_TOT_WORDS-1:0]                 we_a_dec;
  logic [NUM_TOT_WORDS-1:0]                 we_b_dec;
  
`ifdef HAMSA_DI  // DI declarations
   
   logic [4:0]               waddr_b2   ;
   logic [31:0]              wdata_b2   ;
   logic                     we_b2      ;   
   logic [NUM_TOT_WORDS-1:0] we_b2_dec  ;

`endif
    

   //-----------------------------------------------------------------------------
   //-- READ : Read address decoder RAD
   //-----------------------------------------------------------------------------
generate  // added by Udi 28/Feb/2019 required by Quartus
   if (FPU == 1) begin : fpu1 // label added by Udi 28/Feb/2019 required by Quartus
      assign rdata_a_o = raddr_a_i[5] ? mem_fp[raddr_a_i[4:0]] : mem[raddr_a_i[4:0]];
      assign rdata_b_o = raddr_b_i[5] ? mem_fp[raddr_b_i[4:0]] : mem[raddr_b_i[4:0]];
      assign rdata_c_o = raddr_c_i[5] ? mem_fp[raddr_c_i[4:0]] : mem[raddr_c_i[4:0]];
   end else begin : fpu0 // label added by Udi 28/Feb/2019 required by Quartus
      assign rdata_a_o = mem[raddr_a_i[4:0]];
      assign rdata_b_o = mem[raddr_b_i[4:0]];
      assign rdata_c_o = mem[raddr_c_i[4:0]];
   end
endgenerate 
  
  //-----------------------------------------------------------------------------
  //-- WRITE : Write Address Decoder (WAD), combinatorial process
  //-----------------------------------------------------------------------------

  // Mask top bit of write address to disable fp regfile
  assign waddr_a = waddr_a_i;
  assign waddr_b = waddr_b_i;

  always_comb
  begin : we_a_decoder
    for (int i = 0; i < NUM_TOT_WORDS; i++) begin
      if (waddr_a == i)
        we_a_dec[i] = we_a_i;
      else
        we_a_dec[i] = 1'b0;
    end
  end

  always_comb
  begin : we_b_decoder
    for (int i=0; i<NUM_TOT_WORDS; i++) begin
      if (waddr_b == i)
        we_b_dec[i] = we_b_i;
      else
        we_b_dec[i] = 1'b0;
    end
  end

  genvar i,l;
  generate

    //-----------------------------------------------------------------------------
    //-- WRITE : Write operation
    //-----------------------------------------------------------------------------
    // R0 is nil
    always_ff @(posedge clk or negedge rst_n) begin
      if(~rst_n) begin
        // R0 is nil
        mem[0] <= 32'b0;
      end else begin
        // R0 is nil
        mem[0] <= 32'b0;
      end
    end

    // loop from 1 to NUM_WORDS-1 as R0 is nil
    for (i = 1; i < NUM_WORDS; i++)
    begin : rf_gen

      always_ff @(posedge clk, negedge rst_n)
      begin : register_write_behavioral
        if (rst_n==1'b0) begin
          mem[i] <= 32'b0;
        end else begin

`ifdef HAMSA_DI                      // I2 Port Writing        
          if(we_b2_dec[i] == 1'b1)
            mem[i] <= wdata_b2 ;             
          else 
`endif
               if(we_b_dec[i] == 1'b1)         
            mem[i] <= wdata_b_i;
          else if(we_a_dec[i] == 1'b1)
            mem[i] <= wdata_a_i;
        end
      end

    end

    if (FPU == 1) begin
      // Floating point registers
      for(l = 0; l < NUM_FP_WORDS; l++) begin : gb1
        always_ff @(posedge clk, negedge rst_n)
        begin : fp_regs
          if (rst_n==1'b0)
            mem_fp[l] <= '0;
          else if(we_b_dec[l+NUM_WORDS] == 1'b1)
            mem_fp[l] <= wdata_b_i;
          else if(we_a_dec[l+NUM_WORDS] == 1'b1)
            mem_fp[l] <= wdata_a_i;
        end
      end
    end

  endgenerate
  
 // ************************* DUAL ISSUE OPTIONAL SUPPORT ******************************************************** 
  
`ifdef HAMSA_DI 
 
   // issue2 Read port a2   
   assign di_intrfc_regfile.rdata_a2 = mem[di_intrfc_regfile.raddr_a2] ;
   
   // issue2 Read port b2
   assign di_intrfc_regfile.rdata_b2 = mem[di_intrfc_regfile.raddr_b2] ;
    
   // issue port Write port b2
      
   assign waddr_b2 = di_intrfc_regfile.waddr_b2  ;
   assign wdata_b2 = di_intrfc_regfile.wdata_b2  ;
   assign we_b2    = di_intrfc_regfile.we_b2 ;
      
   // I2 WRITE address decode
   
   always_comb
    begin : we_b2_decoder
      for (int i=0; i<NUM_TOT_WORDS; i++) begin
        if (waddr_b2 == i)
          we_b2_dec[i] = we_b2 ;
        else
          we_b2_dec[i] = 1'b0;
      end
    end
 
`endif
  
 
endmodule
