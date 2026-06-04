//Author Asaf Pollock

module uASLR #(	
	parameter INSTR_ADDR_WIDTH = 32,
	parameter INSTR_RDATA_WIDTH = 32,
	parameter INSTR_WIDTH = 32,
	parameter DATA_ADDR_WIDTH = 32,
	parameter INSTR_ADDR_WIDTH_BEGIN = 0,
	parameter RNG_WIDTH = 32
)
(
	input logic clk,
	input logic rst_n,
	
	input logic [RNG_WIDTH-1:0] uASLR_config,
	
	input logic [DATA_ADDR_WIDTH-1:0] core_data_addr_i,
	input logic [INSTR_ADDR_WIDTH-1:0] core_instr_addr_i,
	input logic [INSTR_RDATA_WIDTH-1:0] core_instr_rdata_i,
	
	
	output logic [DATA_ADDR_WIDTH-1:0] core_data_addr_o,
	output logic [INSTR_ADDR_WIDTH-1:0] core_instr_addr_o,
	output logic [INSTR_RDATA_WIDTH-1:0] core_instr_rdata_o
);

//internal wires
logic [DATA_ADDR_WIDTH-1:0] core_data_addr_m;
logic [INSTR_ADDR_WIDTH-1:0] core_instr_addr_m;
logic [INSTR_RDATA_WIDTH-1:0] core_instr_rdata_m;

//RNG logic
logic [RNG_WIDTH-1:0] rng_i;

//Chicken bit
assign core_data_addr_o = uASLR_config[0] ? core_data_addr_m : core_data_addr_i; 
assign core_instr_addr_o = uASLR_config[0] ? core_instr_addr_m : core_instr_addr_i;
assign core_instr_rdata_o = uASLR_config[0] ? core_instr_rdata_m : core_instr_rdata_i;

assign rng_i = {uASLR_config[RNG_WIDTH-1:2], 2'b00};

//----------------------------------------------------------------------------//
//Main modules
//----------------------------------------------------------------------------//

uASLR_inst #(
	.INSTR_ADDR_WIDTH (INSTR_ADDR_WIDTH),
	.INSTR_RDATA_WIDTH(INSTR_RDATA_WIDTH),
	.INSTR_WIDTH      (INSTR_WIDTH),
	.RNG_WIDTH        (RNG_WIDTH)
)
u_uASLR_inst (
	.clk               (clk),
	// input from core
	.core_instr_addr_i (core_instr_addr_i),
	// output to mux
	.core_instr_addr_o (core_instr_addr_m),
	// input from mux
	.core_instr_rdata_i(core_instr_rdata_i),
	// output to core
	.core_instr_rdata_o(core_instr_rdata_m),
	.rng_i             (rng_i),
	.rst_n             (rst_n)
);
	
uASLR_data #(
	.DATA_ADDR_WIDTH (DATA_ADDR_WIDTH),
	.RNG_WIDTH       (RNG_WIDTH)
)
u_uASLR_data (
	.clk             (clk),
	.core_data_addr_i(core_data_addr_i),
	.core_data_addr_o(core_data_addr_m),
	.rng_i           (rng_i),
	.rst_n           (rst_n)
);

endmodule
