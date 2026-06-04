module spi_core
  (
    clk,
    spi_clk,
    rst_n,

    // CBUS Interface
    req,
    address,
    cmd,
    byten,
    wdata,
    rdata,
    rdatap,
    rresp,
    waccept,

    // SPI interrupt
    spi_intr_o,

    // SPI external signals
    spi_dclk_o,
    spi_dclk_i,
    spi_cs_o,
    spi_din_i,
    spi_dout_o,
    spi_dout_i,
    spi_dout_oe_n,

    // CLK synchronized rst_n signal
    sync_rst_n,

    // Output indicating the SPI divide clock is on
    spi_clk_en,

    // Test Signals
    test_mode,
        
        // DFT
        scan_enable,
        dft_clk_en,
        
        phy_cg_sel,
        
        // Address monitoring interrupts
        spi_bad_addr_irq,
        spi_bad_addr_unmsk_irq
  );

   parameter SPI_IS_BOOT = 0;
   parameter AW = 8;     // 2^8 words = 1KB space
   localparam DW = 32;
   
   input         clk;
   input         spi_clk;
   input         rst_n;
   // CBUS Interface
   input         req;
   input [AW-1:0] address;
   input         cmd;    // (0=WRITE; 1=READ)
   input [3:0]   byten;
   input [31:0]  wdata;
   output [31:0] rdata;
   output [31:0] rdatap;
   output        rresp;
   output        waccept;
   
   // SPI Interrupt
   output        spi_intr_o;
   
   // SPI External Signals
   output        spi_dclk_o;
   input         spi_dclk_i;
   output [3:0]  spi_cs_o;     // Programmable Polarity for Chip Select
   input         spi_din_i;
   output        spi_dout_o;
   input         spi_dout_i;
   output        spi_dout_oe_n;  // Enable = 0, output buffers on.
   
   // CLK synchronized rst_n signal
   output        sync_rst_n;
   
   // Output indicating the SPI divide clock is on
   output        spi_clk_en;
   
   // Test Signals
   input         test_mode;
   
   input                dft_clk_en;             // To Ispi_cntif of spi_cntif.v
   input [1:0]          phy_cg_sel;             // To Ispi_cntif of spi_cntif.v
   input                scan_enable;            // To Ispi_cntif of spi_cntif.v

   /*autoinput*/

   output               spi_bad_addr_irq;       // From Ispi_cntif of spi_cntif.v
   output               spi_bad_addr_unmsk_irq; // From Ispi_cntif of spi_cntif.v

   //*autooutput*/
   
   wire          spi_dclk;
   wire          spi_rst_n;
   wire [4:0]    wlen;
   wire [4:0]    wlen_ot;
   wire [11:0]   flen;
   wire [1:0]    csnum;
   wire [1:0]    dat_dly;
   wire          clk_pol;
   wire          clk_ph;
   wire [3:0]    cs_pol;
   wire [15:0]   spi_clk_div;
   wire          dr_load;
   wire          read_cmd;
   wire          sread_cmd;
   wire          dread_cmd;
   wire          sread;
   wire          dread;
   wire          write_en;
   wire          write_cmd;
   wire          bad_cmd;
   wire          busy;
   wire          wc;
   wire          fc;
   wire [11:0]   wdcnt;
   wire          cs_n;
   wire          shift_on;
   wire          shift_out_load;
   wire [31:0]   shift_out_data;
   wire [31:0]   shift_in_data;
   wire          idle;

   /*autowire*/
   
   spi_cntif #(/*AUTOINSTPARAM*/
               // Parameters
               .SPI_IS_BOOT             (SPI_IS_BOOT),
               .AW                      (AW))
   Ispi_cntif (
               .spi_clk   (spi_dclk),
               .interrupt (spi_intr_o),
               
               // Parameters
               /*AUTOINST*/
               // Outputs
               .sync_rst_n              (sync_rst_n),
               .rdata                   (rdata[DW-1:0]),
               .rdatap                  (rdatap[DW-1:0]),
               .rresp                   (rresp),
               .waccept                 (waccept),
               .shift_out_data          (shift_out_data[31:0]),
               .wlen                    (wlen[4:0]),
               .wlen_ot                 (wlen_ot[4:0]),
               .flen                    (flen[11:0]),
               .csnum                   (csnum[1:0]),
               .dat_dly                 (dat_dly[1:0]),
               .clk_pol                 (clk_pol),
               .cs_pol                  (cs_pol[3:0]),
               .clk_ph                  (clk_ph),
               .spi_clk_en              (spi_clk_en),
               .spi_clk_div             (spi_clk_div[15:0]),
               .read_cmd                (read_cmd),
               .sread_cmd               (sread_cmd),
               .dread_cmd               (dread_cmd),
               .write_cmd               (write_cmd),
               .bad_cmd                 (bad_cmd),
               .spi_bad_addr_irq        (spi_bad_addr_irq),
               .spi_bad_addr_unmsk_irq  (spi_bad_addr_unmsk_irq),
               // Inputs
               .clk                     (clk),
               .rst_n                   (rst_n),
               .spi_rst_n               (spi_rst_n),
               .req                     (req),
               .address                 (address[AW-1:0]),
               .cmd                     (cmd),
               .byten                   (byten[3:0]),
               .wdata                   (wdata[DW-1:0]),
               .dr_load                 (dr_load),
               .shift_in_data           (shift_in_data[31:0]),
               .busy                    (busy),
               .wc                      (wc),
               .fc                      (fc),
               .wdcnt                   (wdcnt[11:0]),
               .test_mode               (test_mode),
               .scan_enable             (scan_enable),
               .dft_clk_en              (dft_clk_en),
               .phy_cg_sel              (phy_cg_sel[1:0]));

  spi_clkgen Ispi_clkgen
    (
     /*AUTOINST*/
     // Outputs
     .spi_dclk                          (spi_dclk),
     .spi_rst_n                         (spi_rst_n),
     // Inputs
     .spi_clk                           (spi_clk),
     .rst_n                             (rst_n),
     .spi_clk_en                        (spi_clk_en),
     .spi_clk_div                       (spi_clk_div[15:0]),
     .test_mode                         (test_mode));

  spi_machine Ispi_machine
    (
      .clk   (spi_dclk),
      .rst_n (spi_rst_n),

      // Parameters
     /*AUTOINST*/
     // Outputs
     .cs_n                              (cs_n),
     .sread                             (sread),
     .dread                             (dread),
     .write_en                          (write_en),
     .dr_load                           (dr_load),
     .shift_on                          (shift_on),
     .shift_out_load                    (shift_out_load),
     .idle                              (idle),
     .busy                              (busy),
     .wc                                (wc),
     .fc                                (fc),
     .wdcnt                             (wdcnt[11:0]),
     // Inputs
     .wlen                              (wlen[4:0]),
     .flen                              (flen[11:0]),
     .dat_dly                           (dat_dly[1:0]),
     .read_cmd                          (read_cmd),
     .sread_cmd                         (sread_cmd),
     .dread_cmd                         (dread_cmd),
     .write_cmd                         (write_cmd),
     .bad_cmd                           (bad_cmd));

  spi_shifter Ispi_shifter
    (
      .clk   (spi_dclk),
      .rst_n (spi_rst_n),

      // SPI Interface
     /*AUTOINST*/
     // Outputs
     .spi_dclk_o                        (spi_dclk_o),
     .spi_cs_o                          (spi_cs_o[3:0]),
     .spi_dout_o                        (spi_dout_o),
     .spi_dout_oe_n                     (spi_dout_oe_n),
     .shift_in_data                     (shift_in_data[31:0]),
     // Inputs
     .spi_dclk_i                        (spi_dclk_i),
     .spi_din_i                         (spi_din_i),
     .spi_dout_i                        (spi_dout_i),
     .wlen_ot                           (wlen_ot[4:0]),
     .shift_out_data                    (shift_out_data[31:0]),
     .clk_pol                           (clk_pol),
     .cs_pol                            (cs_pol[3:0]),
     .clk_ph                            (clk_ph),
     .csnum                             (csnum[1:0]),
     .shift_on                          (shift_on),
     .shift_out_load                    (shift_out_load),
     .idle                              (idle),
     .cs_n                              (cs_n),
     .sread                             (sread),
     .dread                             (dread),
     .write_en                          (write_en),
     .test_mode                         (test_mode));

endmodule

// Local Variables:
// verilog-library-directories:("." )
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
