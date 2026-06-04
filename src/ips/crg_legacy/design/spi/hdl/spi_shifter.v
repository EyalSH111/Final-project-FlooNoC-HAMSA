module spi_shifter
  (
    clk,
    rst_n,

    // SPI Interface
    spi_dclk_o,
    spi_dclk_i,
    spi_cs_o,
    spi_din_i,
    spi_dout_o,
    spi_dout_i,
    spi_dout_oe_n,

    // Parameters
    wlen_ot,
    shift_out_data,
    clk_pol,
    cs_pol,
    clk_ph,
    csnum,

    // Control
    shift_on,
    shift_out_load,
    idle,
    cs_n,
    sread,
    dread,
    write_en,

    // Read Data
    shift_in_data,

    // Test signals
    test_mode
  );

input         clk;
input         rst_n;
// SPI Interface
output        spi_dclk_o;
input         spi_dclk_i;
output  [3:0] spi_cs_o;     // Programmable Polarity for Chip Select
input         spi_din_i;
output        spi_dout_o;
input         spi_dout_i;
output        spi_dout_oe_n;  // Enable = 0, output buffers on.
// Parameters
input  [4:0]  wlen_ot;
input  [31:0] shift_out_data;
input         clk_pol;
input  [3:0]  cs_pol;
input         clk_ph;
input  [1:0]  csnum;
// Control
input         shift_on;
input         shift_out_load;
input         idle;
input         cs_n;
input         sread;
input         dread;
input         write_en;
// Read Data
output [31:0] shift_in_data;
// Test signals
input         test_mode;

parameter SEL_CS0 = 2'd0;
parameter SEL_CS1 = 2'd1;
parameter SEL_CS2 = 2'd2;
parameter SEL_CS3 = 2'd3;

reg         ispi_dout_o;
reg         spi_dout_oe_n;
reg  [3:0]  spi_cs_o;
reg         spi_datain;
reg         spi_dataio;
reg  [31:0] dataoutreg;
reg  [31:0] datainreg;
reg         ishift_on;
reg         shift_on_q;
reg         shift_on_q1;

wire        inv_clk;
// wire        iinv_clk;
wire        ispi_datain;
wire        ispi_dataio;
wire        spi_dataout;

wire        mode0_clk;
wire        mode1_clk;
// wire        mode2_clk;
// wire        mode3_clk;
wire        mode01_clk;
// wire        mode23_clk;
wire [31:0] shift_out_data_g;

wire        spi_dclk_inv;
wire        ispi_dclk_c;
wire        spi_dclk_c;
wire        spi_dclk_rst_n;
wire        cap_neg;
wire        shift_in_en;

  // Inverted spi_dclk_i
 crg_clk_inv Cspi_dclk_inv
    (
      .a (spi_dclk_i),
      .y (spi_dclk_inv)
    );

  assign cap_neg = !clk_pol; //!(clk_pol ^ clk_ph);

  crg_clk_mx2 Cispi_dclk_c
    (
      .a (spi_dclk_i),
      .b (spi_dclk_inv),
      .s (cap_neg),
      .y (ispi_dclk_c)
    );

  // DFT mux
  crg_clk_mx2 Cspi_dclk_c
    (
      .a (ispi_dclk_c),
      .b (clk),
      .s (test_mode),
      .y (spi_dclk_c)
    );

  // Inverted SPI clock
  crg_clk_inv Cinv_clk
    (
      .a (clk),
      .y (inv_clk)
    );

  // Half clock delay of shift_on
  //assign inv_clk = (test_mode) ? clk : iinv_clk;

//  crg_clk_mx2 Ctm_clk
//    (
//      .a (iinv_clk),
//      .b (clk),
//      .s (test_mode),
//      .y (inv_clk)
//    );

  //  Read capture register
  //  First: sync the rst_n
  crg_reset_sync Cspi_dclk_rstn
    (
      .arst_n    (rst_n), 
      .clk       (spi_dclk_c),
      .scan_mode (test_mode),
      .rst_out_n (spi_dclk_rst_n)
    );

  always @(posedge spi_dclk_c or negedge spi_dclk_rst_n)
  begin
    if (!spi_dclk_rst_n) begin
      spi_datain <= 1'b0;
      spi_dataio <= 1'b0;
    end
    else begin
      spi_datain <= spi_din_i;
      spi_dataio <= spi_dout_i;
    end
  end

  assign ispi_datain = (!clk_ph) ? spi_datain : spi_din_i;
  assign ispi_dataio = (!clk_ph) ? spi_dataio : spi_dout_i;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      ispi_dout_o   <= 1'b0;
      spi_dout_oe_n <= 1'b1;
      spi_cs_o      <= 4'hf;
    end
    else begin
      ispi_dout_o   <= spi_dataout;
      spi_dout_oe_n <= (idle || !write_en) ? 1'b1 : 1'b0;
      spi_cs_o[0]   <= (csnum != SEL_CS0) ? !cs_pol[0] : (cs_n ^ cs_pol[0]);
      spi_cs_o[1]   <= (csnum != SEL_CS1) ? !cs_pol[1] : (cs_n ^ cs_pol[1]);
      spi_cs_o[2]   <= (csnum != SEL_CS2) ? !cs_pol[2] : (cs_n ^ cs_pol[2]);
      spi_cs_o[3]   <= (csnum != SEL_CS3) ? !cs_pol[3] : (cs_n ^ cs_pol[3]);
    end
  end

  crg_clk_an2 Ishift_out_data[31:0]
    (
     .a (shift_out_load), 
     .b (shift_out_data), 
     .y (shift_out_data_g)
    );

  // Output Shifter (write)
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      dataoutreg  <= 32'd0;
    end
    else begin
      if (shift_out_load) begin
        dataoutreg  <= shift_out_data_g;
      end
      else if (shift_on) begin
        dataoutreg  <= {dataoutreg[30:0], 1'b0};
      end
    end
  end

  assign spi_dataout = dataoutreg[wlen_ot];
  assign spi_dout_o  = ispi_dout_o;

  assign shift_in_en = (!clk_ph) ? shift_on_q1 : shift_on_q;

  // Input Shifter (read)
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      datainreg   <= 32'd0;
      shift_on_q  <= 1'b0;
      shift_on_q1 <= 1'b0;
    end
    else begin
      shift_on_q  <= shift_on;
      shift_on_q1 <= shift_on_q;
      if (shift_out_load) begin
        datainreg <= 32'd0;
      end
      else if (shift_in_en) begin
        if (sread) begin
          datainreg <= {datainreg[30:0], ispi_dataio};
        end
        else if (dread) begin
          datainreg <= {datainreg[29:0], {ispi_datain, ispi_dataio}};
        end
        else begin
          datainreg <= {datainreg[30:0], ispi_datain};
        end
      end
    end
  end

  assign shift_in_data = datainreg;

  // SPI output clock generation
  // Delay shift_on by 1/2 clock
  always @(posedge inv_clk or negedge rst_n)
  begin
    if (!rst_n) begin
      ishift_on <= 1'b0;
    end
    else begin
      ishift_on <= shift_on;
    end
  end

   // Mode 0 clock
   crg_clk_clockgate Cmode0_clk
     (
      .clk     (inv_clk), 
      .en      (ishift_on), 
      .ten     (test_mode), 
      .out_clk (mode0_clk)
      );
   
   
  // Mode 1 clock
  crg_clk_clockgate Cmode1_clk
    (
      .clk     (clk), 
      .en      (shift_on), 
      .ten     (test_mode), 
      .out_clk (mode1_clk)
    );
   
//  // Mode 2 clock
//  // Inverted SPI clock
//  crg_clk_inv Cmode2_clk
//    (
//      .a (mode0_clk),
//      .y (mode2_clk)
//    );
//
//  // Mode 3 clock
//  crg_clk_inv Cmode3_clk
//    (
//      .a (mode1_clk),
//      .y (mode3_clk)
//    );

  // Output clock select
  crg_clk_mx2 Cmode01_clk
    (
      .a (mode0_clk),
      .b (mode1_clk),
      .s (clk_ph || test_mode),
      .y (mode01_clk)
    );

  crg_clk_xor2 Cspi_dclk_o 
    (
      .a (mode01_clk), 
      .b (clk_pol),
      .y (spi_dclk_o)
    );

//  crg_clk_mx2 Cmode23_clk
//    (
//      .a (mode2_clk),
//      .b (mode3_clk),
//      .s (clk_ph),
//      .y (mode23_clk)
//    );
//
//  crg_clk_mx2 Cspi_dclk_o
//    (
//      .a (mode01_clk),
//      .b (mode23_clk),
//      .s (clk_pol),
//      .y (spi_dclk_o)
//    );

endmodule
