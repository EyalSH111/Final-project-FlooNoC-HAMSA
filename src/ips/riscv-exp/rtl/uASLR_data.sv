module uASLR_data #(
	parameter DATA_ADDR_WIDTH = 32,
	parameter RNG_WIDTH = 32	
)
(
 input logic clk,
 input logic rst_n,
 input logic [RNG_WIDTH-1:0] rng_i, 
 input logic [DATA_ADDR_WIDTH-1:0] core_data_addr_i,
 
 output logic [DATA_ADDR_WIDTH-1:0] core_data_addr_o
);

assign core_data_addr_o = core_data_addr_i - rng_i;

endmodule
