module spi
  (/*autoarg*/
   // Outputs
   mmspi_req_mode, waccept, rdatap, rresp, rstatus, sreq, sstatus,
   sdone, sid, smstid, spi_intr_o, spi_dclk_o, spi_cs_o, spi_dout_o,
   spi_dout_oe_n, spi_bad_addr_irq, spi_bad_addr_unmsk_irq,
   // Inputs
   clk, spi_clk, rst_n, cfg_req, mm_req0, mm_req1, mm_req2, mm_req3,
   mmspi_req_mode_ival, address, first, last, bytecnt, byten, cmd,
   wdata, amode, clsize, xid, mstid, done, sready, big_endian,
   spi_dclk_i, spi_din_i, spi_dout_i, test_mode, dft_clk_en,
   phy_cg_sel, scan_enable
   );

   parameter SPI_IS_BOOT = 0;
   parameter AW = 10;     		// 2^10 bytes = 1KB space
   
   input         clk;
   input         spi_clk;
   input         rst_n;
   
   // Config port request
   input         cfg_req;
   // Memory port requests
   input         mm_req0;
   input         mm_req1;
   input         mm_req2;
   input         mm_req3;
   input [1:0]   mmspi_req_mode_ival;
   output [1:0]  mmspi_req_mode;
   
   // Shared CBUSP slave port
   input [31:0]  address;
   input         first;
   input         last;
   input [9:0]   bytecnt;
   input [3:0]   byten;
   input         cmd;
   input [31:0]  wdata;
   output        waccept;
   output [31:0] rdatap;
   output        rresp;
   input [1:0]   amode;
   input [2:0]   clsize;
   output [2:0]  rstatus;
   input [3:0]   xid;
   input [7:0]   mstid;
   input         done;
   
   // CBUS write status interface
   output        sreq;
   output [2:0]  sstatus;
   input         sready;
   output        sdone;
   output [3:0]  sid;
   output [7:0]  smstid;
   
   // Endian Control
   input         big_endian;
   
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
   
   // Test Signals
   input         test_mode;

   input                dft_clk_en;             // To Ispi_core of spi_core.v
   input [1:0]          phy_cg_sel;             // To Ispi_core of spi_core.v
   input                scan_enable;            // To Ispi_core of spi_core.v   

   /*autoinput*/

   output               spi_bad_addr_irq;       // From Ispi_core of spi_core.v
   output               spi_bad_addr_unmsk_irq; // From Ispi_core of spi_core.v
   
   //*autooutput*/ 
   
   // SPI Core CBUSP Interface
   wire          spi_cfg_req;
   wire [AW-1:0] spi_cfg_address;
   wire          spi_cfg_cmd;
   wire [3:0]    spi_cfg_byten;
   wire [31:0]   spi_cfg_wdata;
   wire [31:0]   spi_cfg_rdatap;
   wire [31:0]   spi_cfg_rdata;
   wire          spi_cfg_rresp;
   wire          spi_cfg_waccept;
   
   // CLK synchronized reset
   wire          sync_rst_n;
   
   // Output indicating the SPI divide clock is on
   wire          spi_clk_en;

   /*autowire*/    

   spi_sfi_mm #(.SPI_IS_BOOT(SPI_IS_BOOT), .AW(AW)) Ispi_sfi_mm
     (
      .rst_n (sync_rst_n),
  
      // Config port request
      .spi_cfg_address (spi_cfg_address[AW-1:0]),
      /*AUTOINST*/
      // Outputs
      .mmspi_req_mode                   (mmspi_req_mode[1:0]),
      .waccept                          (waccept),
      .rdatap                           (rdatap[31:0]),
      .rresp                            (rresp),
      .rstatus                          (rstatus[2:0]),
      .sreq                             (sreq),
      .sstatus                          (sstatus[2:0]),
      .sdone                            (sdone),
      .sid                              (sid[3:0]),
      .smstid                           (smstid[7:0]),
      .spi_cfg_req                      (spi_cfg_req),
      .spi_cfg_cmd                      (spi_cfg_cmd),
      .spi_cfg_byten                    (spi_cfg_byten[3:0]),
      .spi_cfg_wdata                    (spi_cfg_wdata[31:0]),
      // Inputs
      .clk                              (clk),
      .cfg_req                          (cfg_req),
      .mm_req0                          (mm_req0),
      .mm_req1                          (mm_req1),
      .mm_req2                          (mm_req2),
      .mm_req3                          (mm_req3),
      .mmspi_req_mode_ival              (mmspi_req_mode_ival[1:0]),
      .address                          (address[31:0]),
      .first                            (first),
      .last                             (last),
      .bytecnt                          (bytecnt[9:0]),
      .byten                            (byten[3:0]),
      .cmd                              (cmd),
      .wdata                            (wdata[31:0]),
      .amode                            (amode[1:0]),
      .clsize                           (clsize[2:0]),
      .xid                              (xid[3:0]),
      .mstid                            (mstid[7:0]),
      .done                             (done),
      .sready                           (sready),
      .big_endian                       (big_endian),
      .spi_cfg_rdatap                   (spi_cfg_rdatap[31:0]),
      .spi_cfg_rdata                    (spi_cfg_rdata[31:0]),
      .spi_cfg_rresp                    (spi_cfg_rresp),
      .spi_cfg_waccept                  (spi_cfg_waccept),
      .spi_clk_en                       (spi_clk_en),
      .test_mode                        (test_mode));
  
   spi_core #(.SPI_IS_BOOT(SPI_IS_BOOT), .AW(AW-2)) Ispi_core
     (
      .req     (spi_cfg_req),
      .address (spi_cfg_address[AW-1:2]),
      .cmd     (spi_cfg_cmd),
      .byten   (spi_cfg_byten),
      .wdata   (spi_cfg_wdata),
      .rdata   (spi_cfg_rdata),
      .rdatap  (spi_cfg_rdatap),
      .rresp  (spi_cfg_rresp),
      .waccept  (spi_cfg_waccept),
  
      // SPI interrupt
      /*AUTOINST*/
      // Outputs
      .spi_intr_o                       (spi_intr_o),
      .spi_dclk_o                       (spi_dclk_o),
      .spi_cs_o                         (spi_cs_o[3:0]),
      .spi_dout_o                       (spi_dout_o),
      .spi_dout_oe_n                    (spi_dout_oe_n),
      .sync_rst_n                       (sync_rst_n),
      .spi_clk_en                       (spi_clk_en),
      .spi_bad_addr_irq                 (spi_bad_addr_irq),
      .spi_bad_addr_unmsk_irq           (spi_bad_addr_unmsk_irq),
      // Inputs
      .clk                              (clk),
      .spi_clk                          (spi_clk),
      .rst_n                            (rst_n),
      .spi_dclk_i                       (spi_dclk_i),
      .spi_din_i                        (spi_din_i),
      .spi_dout_i                       (spi_dout_i),
      .test_mode                        (test_mode),
      .dft_clk_en                       (dft_clk_en),
      .phy_cg_sel                       (phy_cg_sel[1:0]),
      .scan_enable                      (scan_enable));

endmodule  
