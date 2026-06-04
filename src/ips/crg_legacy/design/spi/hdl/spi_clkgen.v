module spi_clkgen
  (
    spi_clk,
    rst_n,
    // Parameters
    spi_clk_en,
    spi_clk_div,
    // Output clock
    spi_dclk,
    // Output reset
    spi_rst_n,
    // Test signals
    test_mode
  );

input         spi_clk;
input         rst_n;
// Parameters
input         spi_clk_en;
input  [15:0] spi_clk_div;
// Output clocks
output        spi_dclk;
// Output reset
output        spi_rst_n;

// Test signals
input         test_mode;

reg  [15:0] dclk_div_reg;
reg         spi_dclk_loc;
reg         spi_clk_en_q;
reg         ispi_clk_en;
reg  [15:0] spi_clk_div_q;
reg         spi_div_bypass;

wire        spi_clk_en_sync;
wire        spi_clk_sel;
wire        ispi_clk_rst_n;
wire        spi_clk_rst_n;
wire        ispi_rst_n;

wire        spi_clk_div_en;
wire [15:0] spi_clk_div_g;

  // Input Reset synchronizer
  crg_sync2_arst     Sspi_clk_rst_n
    (
      .clk    (spi_clk),
      .clr_n  (rst_n),
      .d      (1'b1),
      .q      (ispi_clk_rst_n)
    );

  crg_clk_mx2          Sspi_clk_rst_n_mux
    (
      .a (ispi_clk_rst_n),
      .b (rst_n),
      .s (test_mode),
      .y (spi_clk_rst_n)
    );

  // Output Reset synchronizer
  crg_sync2_arst     Sspi_rst_n
    (
      .clk    (spi_dclk),
      .clr_n  (rst_n),
      .d      (1'b1),
      .q      (ispi_rst_n)
    );

  crg_clk_mx2          Sspi_rst_n_mux
    (
      .a (ispi_rst_n),
      .b (rst_n),
      .s (test_mode),
      .y (spi_rst_n)
    );

  crg_sync2_arst     Sdin_flag
    (
      .clk    (spi_clk),
      .clr_n  (spi_clk_rst_n),
      .d      (spi_clk_en),
      .q      (spi_clk_en_sync)
    );

  assign spi_clk_div_en = spi_clk_en_sync && !spi_clk_en_q;

   crg_clk_an2 Ispi_clk_div[15:0]
    (
     .a (spi_clk_div_en), 
     .b (spi_clk_div), 
     .y (spi_clk_div_g)
    );

  always @(posedge spi_clk or negedge spi_clk_rst_n)
  begin
    if (!spi_clk_rst_n) begin
      spi_clk_en_q   <= 1'b0;
      spi_clk_div_q  <= 16'd0;
      spi_div_bypass <= 1'b0;
      ispi_clk_en    <= 1'b0;
    end
    else begin
      spi_clk_en_q <= spi_clk_en_sync;
      ispi_clk_en  <= spi_clk_en_q;
      if (spi_clk_en_sync && !spi_clk_en_q) begin
        spi_clk_div_q  <= spi_clk_div_g;
        spi_div_bypass <= 1'b0;
        if (spi_clk_div_g == 16'd0) begin
          spi_div_bypass <= 1'b1;
        end
        else begin
          spi_div_bypass <= 1'b0;
        end
      end
    end
  end

  always @(posedge spi_clk or negedge spi_clk_rst_n)
  begin
    if (!spi_clk_rst_n) begin
      dclk_div_reg  <= 16'b0;
      spi_dclk_loc  <= 1'b0;
    end
    else begin  
      // Clock enable for divider
      if (!ispi_clk_en) begin
        dclk_div_reg <= spi_clk_div_q;
        spi_dclk_loc <= 1'b0;
      end
      else begin
        if (dclk_div_reg != 16'd0) begin
          dclk_div_reg  <= dclk_div_reg - 1'b1;
        end
        else begin
          dclk_div_reg  <= spi_clk_div_q;
        end
      end           

      // Clock generation
      if (dclk_div_reg <= {1'b0, spi_clk_div_q[15:1]}) begin
        spi_dclk_loc <= 1'b0;
      end
      else begin
        spi_dclk_loc <= 1'b1;
      end

    end
  end

  assign spi_clk_sel = test_mode ? 1'b1 : spi_div_bypass;

  crg_clk_mx2 Cspi_dclk
    (
      .a (spi_dclk_loc),
      .b (spi_clk),
      .s (spi_clk_sel),
      .y (spi_dclk)
    );

endmodule
