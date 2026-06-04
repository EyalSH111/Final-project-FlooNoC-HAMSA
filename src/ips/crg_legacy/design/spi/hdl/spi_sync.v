module spi_sync
  (
    din_clk,
    din_rst_n,
    dout_clk,
    dout_rst_n,
    
    din,
    dout,

    din_flag,
    dout_flag
  );

input  din_clk;
input  din_rst_n;
input  dout_clk;
input  dout_rst_n;

input  din;
output dout;

output din_flag;
output dout_flag;

reg    din_q;
reg    din_flag;
reg    dout_flag_sync_q;
reg    dout_q;
reg    dout_flag;

wire   idin_flag;
wire   din_flag_set;
wire   din_flag_clr;
wire   din_flag_sync;
wire   dout_flag_set;
wire   dout_flag_clr;
wire   dout_flag_sync;

  always @(posedge din_clk or negedge din_rst_n)
  begin
    if (!din_rst_n) begin
      din_q            <= 1'b0;
      din_flag         <= 1'b0;
      dout_flag_sync_q <= 1'b0;
    end
    else begin
      din_q            <= din;
      dout_flag_sync_q <= dout_flag_sync;
      if (din_flag_set) begin
        din_flag <= 1'b1;
      end
      else if (din_flag_clr) begin
        din_flag <= 1'b0;
      end
    end
  end

  assign din_flag_set = din && !din_q;
  assign din_flag_clr = dout_flag_sync && !dout_flag_sync_q;
  assign idin_flag    = din_flag;

   crg_sync2_arst    Sdin_flag
    (
      .clk    (dout_clk),
      .clr_n  (dout_rst_n),
      .d      (idin_flag),
      .q      (din_flag_sync)
    );

  always @(posedge dout_clk or negedge dout_rst_n)
  begin
    if (!dout_rst_n) begin
      dout_q    <= 1'b0;
      dout_flag <= 1'b0;
    end
    else begin
      dout_q <= din_flag_sync;
      if (dout_flag_set) begin
        dout_flag <= 1'b1;
      end
      else if (dout_flag_clr) begin
        dout_flag <= 1'b0;
      end
    end
  end

  assign dout_flag_set = din_flag_sync && !dout_q;
  assign dout_flag_clr = !din_flag_sync && dout_q;

  assign dout = dout_flag_set;

  crg_sync2_arst     Sdout_flag
    (
      .clk    (din_clk),
      .clr_n  (din_rst_n),
      .d      (dout_flag),
      .q      (dout_flag_sync)
    );
  
endmodule
