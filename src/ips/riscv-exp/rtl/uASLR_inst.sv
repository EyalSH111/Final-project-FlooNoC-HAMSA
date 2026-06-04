//added by asaf pollock on 23/12/19
//Refreshed by Asaf Pollock 4/7/20

module uASLR_inst #(
   parameter INSTR_ADDR_WIDTH = 32, //TODO: double check about edge case using 2,3,4 as start
   parameter INSTR_RDATA_WIDTH = 32,
   parameter INSTR_WIDTH = 32,
   parameter RNG_WIDTH = 32
) 
(
   input clk,
   input rst_n,

   input [RNG_WIDTH-1:0] rng_i,

   //input from core
   input [INSTR_ADDR_WIDTH-1:0] core_instr_addr_i,

   //input from mux
   input [INSTR_RDATA_WIDTH-1:0] core_instr_rdata_i,

   //output to mux
   output [INSTR_ADDR_WIDTH-1:0] core_instr_addr_o,

   //output to core
   output [INSTR_RDATA_WIDTH-1:0] core_instr_rdata_o

);

logic [INSTR_RDATA_WIDTH-1:0] jmp_opcode;
logic [INSTR_ADDR_WIDTH-1:0] jmp_target_addr_q, jmp_target_addr_n;
logic [INSTR_ADDR_WIDTH-1:0] core_instr_addr;
logic [INSTR_RDATA_WIDTH-1:0] core_instr_rdata;
//Begin jumping FSM
enum {PRE, JUMP, WAIT, POST} CS, NS;

assign core_instr_addr_o = core_instr_addr;
assign core_instr_rdata_o = core_instr_rdata;
assign jmp_opcode = {rng_i[20], rng_i[10:1], rng_i[11], rng_i[19:12], 12'h06f};

always_ff @(posedge clk or negedge rst_n) begin: jump_state_refresh
   if(!rst_n) begin
      CS <= PRE;
      jmp_target_addr_q <= 0;
   end else begin 
      CS <= NS;
      jmp_target_addr_q <= jmp_target_addr_n;
   end
end

always_comb begin: jump_fsm
   jmp_target_addr_n = jmp_target_addr_q;
   core_instr_rdata = 0;
   core_instr_addr = 0;
   NS = CS;
   case(CS)
      PRE: begin
         core_instr_rdata = core_instr_rdata_i;
         core_instr_addr = core_instr_addr_i;
         if(rng_i != 0) begin
            core_instr_rdata = jmp_opcode;
            NS = JUMP;
         end
      end
      JUMP: begin
         core_instr_rdata = jmp_opcode;
         core_instr_addr = core_instr_addr_i;
         jmp_target_addr_n = core_instr_addr_i+rng_i;
         NS = WAIT;
      end
      WAIT: begin
         core_instr_rdata = core_instr_rdata_i;
         core_instr_addr = core_instr_addr_i;
         if(core_instr_addr_i == jmp_target_addr_q+'h10) begin
            core_instr_addr = core_instr_addr_i-rng_i;
            NS = POST;
         end
      end
      POST: begin
         core_instr_rdata = core_instr_rdata_i;
         core_instr_addr = core_instr_addr_i-rng_i;
         NS = POST;
      end
      default: begin
         core_instr_rdata = core_instr_rdata_i;
         core_instr_addr = core_instr_addr_i;
         NS = PRE;
      end
   endcase
end

endmodule
