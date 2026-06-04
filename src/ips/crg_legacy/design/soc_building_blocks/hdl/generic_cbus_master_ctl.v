// ---------------------------------------------------------------------------
// CBUS transfer controller
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Michal: Change to fit CBUS Master write only
//         1) Remove rready and dir signals and logic
//         2) The ctl_address must be aligned to 4 (ctl_address[1:0]==2'b0)
// ---------------------------------------------------------------------------

`timescale 1 ns / 100 ps

module generic_cbus_master_ctl ( 
  // Clock and Reset
  cbus_clk, 
  rst_n, 
  ctl_req, 
  ctl_address, 
  ctl_bytecnt, 
  big_endian_q,
  ctl_ready,
  cbus_req,
  cbus_address, 
  cbus_bytecnt,
  cbus_byten, 
  cbus_first,
  cbus_last,
  cbus_wready
);

input          cbus_clk;        
input          rst_n; 
input          ctl_req;
input   [31:0] ctl_address; 
input    [9:0] ctl_bytecnt; 
input          big_endian_q;
output         ctl_ready;
output         cbus_req;
output  [31:0] cbus_address;
output   [9:0] cbus_bytecnt;
output   [3:0] cbus_byten;
output         cbus_first;
output         cbus_last;
input          cbus_wready;

reg         cbus_req, n_req;
reg  [31:0] cbus_address, n_address;
reg   [9:0] cbus_bytecnt, n_bytecnt;
reg   [3:0] cbus_byten;
wire  [3:0] n_byten;
reg         cbus_first, n_first;
reg         cbus_last;
wire        n_last;
wire        ctl_ready;
wire [31:0] cbus_address_p4;

// CBUS Outputs
always @ (posedge cbus_clk)
begin
  if (~rst_n)
    begin
      cbus_address <= 32'd0;
      cbus_bytecnt <= 10'd0;
      cbus_first   <= 1'b0;
      cbus_last    <= 1'b0;
      cbus_req     <= 1'b0;
      cbus_byten   <= 4'd0;
    end
  else
    begin
      cbus_address <= n_address;
      cbus_bytecnt <= n_bytecnt;
      cbus_first   <= n_first;
      cbus_last    <= n_last;
      cbus_req     <= n_req;
      cbus_byten   <= (big_endian_q) ? {n_byten[0],n_byten[1],n_byten[2],n_byten[3]} : n_byten;
    end
end

assign ctl_ready = ~cbus_req;
assign cbus_address_p4 = cbus_address + 3'd4;

always @ (*)
begin
  n_address = cbus_address;
  n_bytecnt = cbus_bytecnt;
  n_first   = cbus_first;
  n_req     = cbus_req;
  if (ctl_req && ctl_ready) // A new transaction starts
    begin
      n_address[31:0] = ctl_address[31:0];
      n_bytecnt[9:0]  = ctl_bytecnt;
      n_first         = 1'b1;
      n_req           = 1'b1;
    end
  else if (cbus_req && cbus_wready)
    begin
      n_address[31:2] = cbus_address_p4[31:2];
      n_address[1:0]  = 2'b00;
      n_bytecnt[9:0]  = cbus_bytecnt - 10'd4;
      n_first         = 1'b0;
      n_req           = ~cbus_last;
    end
end

wire [9:0] incd_bytecnt = n_bytecnt + 10'd3;
wire [7:0] n_wordcnt = ({2'b0, incd_bytecnt[7:2]}) ;
assign     n_last = (n_wordcnt == 8'd1);

wire bc_ne0 = ~(n_bytecnt==10'd0);
wire bc_ne1 = ~(n_bytecnt==10'd1);
wire bc_ne2 = ~(n_bytecnt==10'd2);
wire bc_ne3 = ~(n_bytecnt==10'd3);

assign n_byten[0] = bc_ne0;
assign n_byten[1] = bc_ne0 && bc_ne1;
assign n_byten[2] = bc_ne0 && bc_ne1 && bc_ne2;
assign n_byten[3] = bc_ne0 && bc_ne1 && bc_ne2 && bc_ne3;

endmodule

