
// ===============================================================================
// Copyright(c)
// <Need to get official wording>
// ===============================================================================
//
// counter.v
// Micha Stern
// 28/12/2009
//
// This module is a programmable counter with step, clear and compare options
//
// ===============================================================================
// Revision History:
// 0.0        , Initial implementation
// 0.1        , Add explanations
// 0.2        , TBD

module counter (sreset_n,
                clk,
                clken,
                clear,
                clear_value,
                step,
                cnt_type,
                enable_compare,
                limit,
                count_value);

  // PARAMETERS
  parameter WIDTH = 10; // Counter width

  // IOS
  output [WIDTH-1:0] count_value;

  input              sreset_n;
  input              clk;
  input              clken;
  input              clear;          // When asserted, clear_value is assumed
  input  [WIDTH-1:0] clear_value;
  input  [WIDTH-1:0] step;           // For negative jumps treat this value as regular
                                     // 2's complement value
  input              cnt_type;       // If asserted, counter stuck at limit when reached
  input              enable_compare; // If enabled, assumed clear_value if:
                                     // count_value==limit
  input  [WIDTH-1:0] limit;          // When reaching exactly this value, clear_value
                                     // is assumed unless cnt_type is asserted

  // REGISTERS
  reg    [WIDTH-1:0] count_value;

  // WIRES
  reg    [WIDTH-1:0] next_value; // Wire
  wire               comp_res;
  wire   [WIDTH-1:0] next_add;

  // WIRES

  // LOGIC
  // Temporary logic
  assign comp_res = ((count_value == limit)) & enable_compare;
  assign next_add = count_value[WIDTH-1:0] + step[WIDTH-1:0];

  // Counter mux (next value)
  always @(*)
    case ({comp_res, cnt_type})
      2'b00:   next_value[WIDTH-1:0] = next_add[WIDTH-1:0];
      2'b01:   next_value[WIDTH-1:0] = next_add[WIDTH-1:0];
      2'b10:   next_value[WIDTH-1:0] = clear_value[WIDTH-1:0];
      2'b11:   next_value[WIDTH-1:0] = count_value[WIDTH-1:0];
    endcase

  // Counter register
  always @(posedge clk)
    if (~sreset_n)
      count_value[WIDTH-1:0] <= {WIDTH{1'b0}};
    else if (clken) begin
      if (clear)
        count_value[WIDTH-1:0] <= clear_value[WIDTH-1:0];
      else
        count_value[WIDTH-1:0] <= next_value[WIDTH-1:0];
    end

endmodule // counter

