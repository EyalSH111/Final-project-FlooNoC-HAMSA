`timescale 1 ns / 100 ps



module gp_dma_fifo (
  clk, 
  rst_n, 
  big_endian, 
  flush,
  rd_en, 
  wr_en, 
  rd_data, 
  wr_data, 
  rd_baddress, 
  wr_baddress, 
  rd_xcnt, 
  wr_xcnt, 
  empty, 
  full, 
  almost_full, 
  occ
);

input  clk;
input  rst_n;
input  big_endian;
input  rd_en;
input  wr_en;
input  flush;
output [31:0] rd_data;
input  [31:0] wr_data;
input  [1:0]  rd_baddress;
input  [1:0]  wr_baddress;
input  [2:0]  rd_xcnt;
input  [2:0]  wr_xcnt;
output empty;
output full;
output almost_full;
output [4:0] occ;

reg [3:0] rd_ptr, wr_ptr;
reg [4:0] occ;
reg [7:0] data_mem [0:15];

wire full = (occ == 5'd16);
wire almost_full = (occ >= 5'd12);
wire empty = (occ == 5'd0);

wire valid_wr = (wr_en && !full);
wire valid_rd = (rd_en && !empty);

wire [3:0] rd_ptr_p1 = rd_ptr + 4'd1;
wire [3:0] rd_ptr_p2 = rd_ptr + 4'd2;
wire [3:0] rd_ptr_p3 = rd_ptr + 4'd3;

// byte rotate for read data 
reg [3:0] rd_ptr_b0;
always @ (*)
begin
  case (rd_baddress)
    2'b00 : 
      rd_ptr_b0 = (big_endian ? rd_ptr_p3 : rd_ptr);
    2'b01 : 
      rd_ptr_b0 = (big_endian ? rd_ptr_p2 : rd_ptr);
    2'b10 : 
      rd_ptr_b0 = (big_endian ? rd_ptr_p1 : rd_ptr);
    default :
      rd_ptr_b0 = rd_ptr;
  endcase
end

reg [3:0] rd_ptr_b1;
always @ (*)
begin
  case (rd_baddress)
    2'b00 : 
      rd_ptr_b1 = (big_endian ? rd_ptr_p2 : rd_ptr_p1);
    2'b01 : 
      rd_ptr_b1 = (big_endian ? rd_ptr_p1 : rd_ptr);
    2'b10 : 
      rd_ptr_b1 = rd_ptr;
    default :
      rd_ptr_b1 = rd_ptr;
  endcase
end

reg [3:0] rd_ptr_b2;
always @ (*)
begin
  case (rd_baddress)
    2'b00 : 
      rd_ptr_b2 = (big_endian ? rd_ptr_p1 : rd_ptr_p2);
    2'b01 : 
      rd_ptr_b2 = (big_endian ? rd_ptr : rd_ptr_p1);
    2'b10 : 
      rd_ptr_b2 = rd_ptr;
    default :
      rd_ptr_b2 = rd_ptr;
  endcase
end

reg [3:0] rd_ptr_b3;
always @ (*)
begin
  case (rd_baddress)
    2'b00 : 
      rd_ptr_b3 = (big_endian ? rd_ptr : rd_ptr_p3);
    2'b01 : 
      rd_ptr_b3 = (big_endian ? rd_ptr : rd_ptr_p2);
    2'b10 : 
      rd_ptr_b3 = (big_endian ? rd_ptr : rd_ptr_p1);
    default :
      rd_ptr_b3 = rd_ptr;
  endcase
end

assign rd_data[7:0] = data_mem[rd_ptr_b0];
assign rd_data[15:8] = data_mem[rd_ptr_b1];
assign rd_data[23:16] = data_mem[rd_ptr_b2];
assign rd_data[31:24] = data_mem[rd_ptr_b3];

always @ (posedge clk)
begin
  if (!rst_n)
    rd_ptr <= 4'd0;
  else if (flush)
    rd_ptr <= 4'd0;
  else if (valid_rd) 
    rd_ptr <= rd_ptr + rd_xcnt;
end

always @ (posedge clk)
begin
  if (!rst_n)
    wr_ptr <= 4'd0;
  else if (flush)
    wr_ptr <= 4'd0;
  else if (valid_wr)
    wr_ptr <= wr_ptr + wr_xcnt;
end

always @ (posedge clk)
begin
  if (!rst_n)
    occ <= 5'd0;
  else if (flush)
    occ <= 5'd0;
  else if (valid_rd && !valid_wr)
    occ <= occ - rd_xcnt;
  else if (valid_wr && !valid_rd)
    occ <= occ + wr_xcnt;
end

wire [3:0] wr_ptr_p1 = wr_ptr + 4'd1;
wire [3:0] wr_ptr_p2 = wr_ptr + 4'd2;
wire [3:0] wr_ptr_p3 = wr_ptr + 4'd3;

// byte rotate for write data 
reg [7:0] wr_data_b0;
always @ (*)
begin
  case (wr_baddress)
    2'b00 : 
      wr_data_b0 = (big_endian ? wr_data[31:24] : wr_data[ 7: 0]);
    2'b01 : 
      wr_data_b0 = (big_endian ? wr_data[23:16] : wr_data[15: 8]);
    2'b10 : 
      wr_data_b0 = (big_endian ? wr_data[15: 8] : wr_data[23:16]);
    default : 
      wr_data_b0 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
  endcase
end

reg [7:0] wr_data_b1;
always @ (*)
begin
  case (wr_baddress)
    2'b00 : 
      wr_data_b1 = (big_endian ? wr_data[23:16] : wr_data[15: 8]);
    2'b01 : 
      wr_data_b1 = (big_endian ? wr_data[15: 8] : wr_data[23:16]);
    2'b10 : 
      wr_data_b1 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
    default : 
      wr_data_b1 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
  endcase
end

reg [7:0] wr_data_b2;
always @ (*)
begin
  case (wr_baddress)
    2'b00 : 
      wr_data_b2 = (big_endian ? wr_data[15: 8] : wr_data[23:16]);
    2'b01 : 
      wr_data_b2 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
    2'b10 : 
      wr_data_b2 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
    default : 
      wr_data_b2 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
  endcase
end

reg [7:0] wr_data_b3;
always @ (*)
begin
  case (wr_baddress)
    2'b00 : 
      wr_data_b3 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
    2'b01 : 
      wr_data_b3 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
    2'b10 : 
      wr_data_b3 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
    default : 
      wr_data_b3 = (big_endian ? wr_data[ 7: 0] : wr_data[31:24]);
  endcase
end

always @ (posedge clk)
begin
  if (valid_wr) 
    begin
      data_mem[wr_ptr] <= wr_data_b0; 
      if (wr_xcnt > 3'd1)
        data_mem[wr_ptr_p1] <= wr_data_b1; 
      if (wr_xcnt > 3'd2)
        data_mem[wr_ptr_p2] <= wr_data_b2; 
      if (wr_xcnt > 3'd3)
        data_mem[wr_ptr_p3] <= wr_data_b3; 
    end
end

endmodule
