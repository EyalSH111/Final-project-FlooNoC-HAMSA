// Dummy RAM till we have the LIBs
module sp_ram_dumm
  #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_WORDS  = 256
  )(
    // Clock and Reset
    input  logic                    clk,
    input  logic                    en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output reg   [DATA_WIDTH-1:0]   rdata_o,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i
  );

wire xor0 = ^{en_i, we_i, be_i, wdata_i[1:0]};
wire xor1 = ^addr_i;

always @(posedge clk) 
  rdata_o <= {wdata_i[DATA_WIDTH-1:2], xor1, xor0};

endmodule
