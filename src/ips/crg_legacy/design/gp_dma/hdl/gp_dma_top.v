//-----------------------------------------------------------------------------
// Title         : DMA Wrapper
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : gp_dma_wrap.v
// Author        : 
// Created       : 22.06.2015
// Last modified : 22.06.2015
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by Ceragon This model is the confidential and
// proprietary property of Ceragon and the possession or use of this
// file requires a written license from Ceragon.
//------------------------------------------------------------------------------
// Modification history :
// 22.06.2015 : created
//-----------------------------------------------------------------------------


module gp_dma_top(/*autoarg*/
   // Outputs
   gpdma_disable_ack, gpdma_done_intr, gp_dma_axiaraddr_i,
   gp_dma_axiarburst_i, gp_dma_axiarcache_i, gp_dma_axiarlen_i,
   gp_dma_axiarlock_i, gp_dma_axiarprot_i, gp_dma_axiarsize_i,
   gp_dma_axiarvalid_i, gp_dma_axiawaddr_i, gp_dma_axiawburst_i,
   gp_dma_axiawcache_i, gp_dma_axiawlen_i, gp_dma_axiawlock_i,
   gp_dma_axiawprot_i, gp_dma_axiawsize_i, gp_dma_axiawvalid_i,
   gp_dma_axibready_i, gp_dma_axirready_i, gp_dma_axiwdata_i,
   gp_dma_axiwlast_i, gp_dma_axiwstrb_i, gp_dma_axiwvalid_i,
   gp_dma_apbprdata_i, gp_dma_apbpready_i, gp_dma_apbpslverr_i,
   // Inputs
   fp_sgn_clk, fp_sgn_rst_n, gpdma_clk_dis, gpdma_clk, gpdma_rst_n,
   big_endian, gpdma_disable_req, gp_dma_axiarready_o,
   gp_dma_axiawready_o, gp_dma_axibresp_o, gp_dma_axibvalid_o,
   gp_dma_axirdata_o, gp_dma_axirlast_o, gp_dma_axirresp_o,
   gp_dma_axirvalid_o, gp_dma_axiwready_o, gp_dma_apbpaddr_o,
   gp_dma_apbpenable_o, gp_dma_apbpreset_no, gp_dma_apbpsel_o,
   gp_dma_apbpwdata_o, gp_dma_apbpwrite_o
   );

   //----------------------------------------------------------------------------
   // Clock & Reset
   //----------------------------------------------------------------------------
   input                fp_sgn_clk;
   input                fp_sgn_rst_n;
   input                gpdma_clk_dis;
   input                gpdma_clk;
   input                gpdma_rst_n;
   input                big_endian;
   output               gpdma_disable_ack;
   input                gpdma_disable_req;
   // DMA interrupts
   output [3:0]         gpdma_done_intr;
   
   //----------------------------------------------------------------------------
   // AXI Master port
   //----------------------------------------------------------------------------
   input                gp_dma_axiarready_o;
   input                gp_dma_axiawready_o;
   input [1:0]          gp_dma_axibresp_o;
   input                gp_dma_axibvalid_o;
   input [31:0]         gp_dma_axirdata_o;
   input                gp_dma_axirlast_o;
   input [1:0]          gp_dma_axirresp_o;
   input                gp_dma_axirvalid_o;
   input                gp_dma_axiwready_o;
   output [31:0]        gp_dma_axiaraddr_i;
   output [1:0]         gp_dma_axiarburst_i;
   output [3:0]         gp_dma_axiarcache_i;
   output [7:0]         gp_dma_axiarlen_i;
   output               gp_dma_axiarlock_i;
   output [2:0]         gp_dma_axiarprot_i;
   output [2:0]         gp_dma_axiarsize_i;
   output               gp_dma_axiarvalid_i;
   output [31:0]        gp_dma_axiawaddr_i;
   output [1:0]         gp_dma_axiawburst_i;
   output [3:0]         gp_dma_axiawcache_i;
   output [7:0]         gp_dma_axiawlen_i;
   output               gp_dma_axiawlock_i;
   output [2:0]         gp_dma_axiawprot_i;
   output [2:0]         gp_dma_axiawsize_i;
   output               gp_dma_axiawvalid_i;
   output               gp_dma_axibready_i;
   output               gp_dma_axirready_i;
   output [31:0]        gp_dma_axiwdata_i;
   output               gp_dma_axiwlast_i;
   output [3:0]         gp_dma_axiwstrb_i;
   output               gp_dma_axiwvalid_i;

   //----------------------------------------------------------------------------
   // APB Slave Port
   //----------------------------------------------------------------------------
   input [7:0]          gp_dma_apbpaddr_o;
   input                gp_dma_apbpenable_o;
   input                gp_dma_apbpreset_no;
   input                gp_dma_apbpsel_o;
   input [31:0]         gp_dma_apbpwdata_o;
   input                gp_dma_apbpwrite_o;
   output [31:0]        gp_dma_apbprdata_i;
   output               gp_dma_apbpready_i;
   output               gp_dma_apbpslverr_i;
    
   /*autoinput*/
   
   ////*autooutput*/
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]          gp_dma_m_address;       // From I_gp_dma of gp_dma.v
   wire [4:0]           gp_dma_m_align;         // From I_gp_dma of gp_dma.v
   wire [1:0]           gp_dma_m_amode;         // From I_gp_dma of gp_dma.v
   wire [9:0]           gp_dma_m_bytecnt;       // From I_gp_dma of gp_dma.v
   wire [3:0]           gp_dma_m_byten;         // From I_gp_dma of gp_dma.v
   wire [1:0]           gp_dma_m_clsize_tmp;    // From I_gp_dma of gp_dma.v
   wire                 gp_dma_m_cmd;           // From I_gp_dma of gp_dma.v
   wire                 gp_dma_m_first;         // From I_gp_dma of gp_dma.v
   wire                 gp_dma_m_last;          // From I_gp_dma of gp_dma.v
   wire [31:0]          gp_dma_m_rdatap;        // From I_cbus2axi_top of cbus2axi_top.v
   wire                 gp_dma_m_req;           // From I_gp_dma of gp_dma.v
   wire                 gp_dma_m_rresp;         // From I_cbus2axi_top of cbus2axi_top.v
   wire                 gp_dma_m_waccept;       // From I_cbus2axi_top of cbus2axi_top.v
   wire [31:0]          gp_dma_m_wdata;         // From I_gp_dma of gp_dma.v
   wire [2:0]           gp_dma_m_xcnt;          // From I_gp_dma of gp_dma.v
   wire [7:0]           gp_dma_s_address;       // From I_sem_apb2cbus of apb2cbus.v
   wire [9:0]           gp_dma_s_bytecnt;       // From I_sem_apb2cbus of apb2cbus.v
   wire [3:0]           gp_dma_s_byten;         // From I_sem_apb2cbus of apb2cbus.v
   wire                 gp_dma_s_cmd;           // From I_sem_apb2cbus of apb2cbus.v
   wire [31:0]          gp_dma_s_rdatap;        // From I_gp_dma of gp_dma.v
   wire                 gp_dma_s_req;           // From I_sem_apb2cbus of apb2cbus.v
   wire                 gp_dma_s_rresp;         // From I_gp_dma of gp_dma.v
   wire                 gp_dma_s_waccept;       // From I_gp_dma of gp_dma.v
   wire [31:0]          gp_dma_s_wdata;         // From I_sem_apb2cbus of apb2cbus.v
   // End of automatics
   
   wire [2:0]           gp_dma_m_clsize = {1'b0,gp_dma_m_clsize_tmp[1:0]};

   //==================================================================
   // Clock stop logic
   //==================================================================
      
   reg                  gpdma_disable_ack;
   wire                 gpdma_disable_req;
   always @ (posedge gpdma_clk)
     begin
        if (!gpdma_rst_n)
          gpdma_disable_ack <= 1'd0;
        else
          gpdma_disable_ack <= (~gp_dma_s_req & gpdma_disable_req);
     end // always @ (posedge cbus_clk)
   
   wire         gp_dma_m_rresp_t     = (gp_dma_m_rresp);
   wire         gp_dma_m_waccept_t   = (gp_dma_m_waccept);
      
   /*apb2cbus AUTO_TEMPLATE (
      .cbus_s_clk                       (gpdma_clk),
      .cbus_s_rst_n                     (gpdma_rst_n),
      .cbus_s_address                   (gp_dma_s_address[]),
      .cbus_s_bytecnt                   (gp_dma_s_bytecnt[]),
      .cbus_s_byten                     (gp_dma_s_byten[]),
      .cbus_s_cmd                       (gp_dma_s_cmd),
      .cbus_s_first                     (),
      .cbus_s_last                      (),
      .cbus_s_req                       (gp_dma_s_req),
      .cbus_s_wdata                     (gp_dma_s_wdata[]),
      .cbus_s_rdatap                    (gp_dma_s_rdatap[]),
      .cbus_s_rresp                     (gp_dma_s_rresp),
      .cbus_s_waccept                   (gp_dma_s_waccept),
      .cbus_s_sgn_clk                   (fp_sgn_clk),
      .cbus_s_sgn_rst_n                 (fp_sgn_rst_n),
      .cbus_s_clk_dis                   (gpdma_clk_dis),
      .\(apb.*\)                        (gp_dma_\1[]),
     ); */
   apb2cbus #(.ADDRW(8)) I_sem_apb2cbus
     (/*autoinst*/
      // Outputs
      .apbpready_i                      (gp_dma_apbpready_i),    // Templated
      .apbpslverr_i                     (gp_dma_apbpslverr_i),   // Templated
      .apbprdata_i                      (gp_dma_apbprdata_i[31:0]), // Templated
      .cbus_s_address                   (gp_dma_s_address[7:0]), // Templated
      .cbus_s_bytecnt                   (gp_dma_s_bytecnt[9:0]), // Templated
      .cbus_s_byten                     (gp_dma_s_byten[3:0]),   // Templated
      .cbus_s_cmd                       (gp_dma_s_cmd),          // Templated
      .cbus_s_first                     (),                      // Templated
      .cbus_s_last                      (),                      // Templated
      .cbus_s_req                       (gp_dma_s_req),          // Templated
      .cbus_s_wdata                     (gp_dma_s_wdata[31:0]),  // Templated
      // Inputs
      .apbpaddr_o                       (gp_dma_apbpaddr_o[7:0]), // Templated
      .apbpenable_o                     (gp_dma_apbpenable_o),   // Templated
      .apbpreset_no                     (gp_dma_apbpreset_no),   // Templated
      .apbpsel_o                        (gp_dma_apbpsel_o),      // Templated
      .apbpwdata_o                      (gp_dma_apbpwdata_o[31:0]), // Templated
      .apbpwrite_o                      (gp_dma_apbpwrite_o),    // Templated
      .cbus_s_sgn_clk                   (fp_sgn_clk),            // Templated
      .cbus_s_sgn_rst_n                 (fp_sgn_rst_n),          // Templated
      .cbus_s_clk                       (gpdma_clk),             // Templated
      .cbus_s_rst_n                     (gpdma_rst_n),           // Templated
      .cbus_s_clk_dis                   (gpdma_clk_dis),         // Templated
      .cbus_s_rdatap                    (gp_dma_s_rdatap[31:0]), // Templated
      .cbus_s_rresp                     (gp_dma_s_rresp),        // Templated
      .cbus_s_waccept                   (gp_dma_s_waccept));     // Templated

   `define GP_DMA_C2A_DWFIFO_PTRW        2
   `define GP_DMA_C2A_DWFIFO_AFTHRS_LSB  2'b01
   `define GP_DMA_C2A_CWFIFO_PTRW        2
   `define GP_DMA_C2A_CWFIFO_AFTHRS_LSB  2'b01
   `define GP_DMA_C2A_RDFIFO_PTRW        2
   `define GP_DMA_C2A_RDFIFO_AFTHRS_LSB  2'b01

   /*cbus2axi_top AUTO_TEMPLATE (
      .aclk                             (gpdma_clk),
      .areset_n                         (gpdma_rst_n),
      .awlen_o                          (gp_dma_axiawlen_i[7:0]),
      .awsize_o                         (gp_dma_axiawsize_i[2:0]),
      .arlen_o                          (gp_dma_axiarlen_i[7:0]),
      .arsize_o                         (gp_dma_axiarsize_i[2:0]),
      .cbus_m_mstid                     (8'h0),
      .\(.*\)\(_i\)                     (gp_dma_axi\1_o[]),
      .\(.*\)\(_o\)                     (gp_dma_axi\1_i[]),
      .\(cbus_m\)\(.*\)                 (gp_dma_m\2[]),
     ); */
   cbus2axi_top 
     #(
       // Parameters
      .C2A_DWFIFO_PTRW                  (`GP_DMA_C2A_DWFIFO_PTRW),
      .C2A_DWFIFO_AFTHRS_LSB            (`GP_DMA_C2A_DWFIFO_AFTHRS_LSB),
      .C2A_CWFIFO_PTRW                  (`GP_DMA_C2A_CWFIFO_PTRW),
      .C2A_CWFIFO_AFTHRS_LSB            (`GP_DMA_C2A_CWFIFO_AFTHRS_LSB),
      .C2A_RDFIFO_PTRW                  (`GP_DMA_C2A_RDFIFO_PTRW),
      .C2A_RDFIFO_AFTHRS_LSB            (`GP_DMA_C2A_RDFIFO_AFTHRS_LSB)) I_cbus2axi_top
     (/*autoinst*/
      // Outputs
      .cbus_m_rdatap                    (gp_dma_m_rdatap[31:0]), // Templated
      .cbus_m_rresp                     (gp_dma_m_rresp),        // Templated
      .cbus_m_waccept                   (gp_dma_m_waccept),      // Templated
      .awaddr_o                         (gp_dma_axiawaddr_i[31:0]), // Templated
      .awlen_o                          (gp_dma_axiawlen_i[7:0]), // Templated
      .awsize_o                         (gp_dma_axiawsize_i[2:0]), // Templated
      .awvalid_o                        (gp_dma_axiawvalid_i),   // Templated
      .awlock_o                         (gp_dma_axiawlock_i),    // Templated
      .awburst_o                        (gp_dma_axiawburst_i[1:0]), // Templated
      .awcache_o                        (gp_dma_axiawcache_i[3:0]), // Templated
      .awprot_o                         (gp_dma_axiawprot_i[2:0]), // Templated
      .wdata_o                          (gp_dma_axiwdata_i[31:0]), // Templated
      .wstrb_o                          (gp_dma_axiwstrb_i[3:0]), // Templated
      .wlast_o                          (gp_dma_axiwlast_i),     // Templated
      .wvalid_o                         (gp_dma_axiwvalid_i),    // Templated
      .bready_o                         (gp_dma_axibready_i),    // Templated
      .araddr_o                         (gp_dma_axiaraddr_i[31:0]), // Templated
      .arlen_o                          (gp_dma_axiarlen_i[7:0]), // Templated
      .arsize_o                         (gp_dma_axiarsize_i[2:0]), // Templated
      .arvalid_o                        (gp_dma_axiarvalid_i),   // Templated
      .arlock_o                         (gp_dma_axiarlock_i),    // Templated
      .arburst_o                        (gp_dma_axiarburst_i[1:0]), // Templated
      .arcache_o                        (gp_dma_axiarcache_i[3:0]), // Templated
      .arprot_o                         (gp_dma_axiarprot_i[2:0]), // Templated
      .rready_o                         (gp_dma_axirready_i),    // Templated
      // Inputs
      .aclk                             (gpdma_clk),             // Templated
      .areset_n                         (gpdma_rst_n),           // Templated
      .cbus_m_address                   (gp_dma_m_address[31:0]), // Templated
      .cbus_m_align                     (gp_dma_m_align[4:0]),   // Templated
      .cbus_m_amode                     (gp_dma_m_amode[1:0]),   // Templated
      .cbus_m_bytecnt                   (gp_dma_m_bytecnt[9:0]), // Templated
      .cbus_m_byten                     (gp_dma_m_byten[3:0]),   // Templated
      .cbus_m_clsize                    (gp_dma_m_clsize[2:0]),  // Templated
      .cbus_m_cmd                       (gp_dma_m_cmd),          // Templated
      .cbus_m_first                     (gp_dma_m_first),        // Templated
      .cbus_m_last                      (gp_dma_m_last),         // Templated
      .cbus_m_mstid                     (8'h0),                  // Templated
      .cbus_m_req                       (gp_dma_m_req),          // Templated
      .cbus_m_wdata                     (gp_dma_m_wdata[31:0]),  // Templated
      .cbus_m_xcnt                      (gp_dma_m_xcnt[2:0]),    // Templated
      .awready_i                        (gp_dma_axiawready_o),   // Templated
      .wready_i                         (gp_dma_axiwready_o),    // Templated
      .bresp_i                          (gp_dma_axibresp_o[1:0]), // Templated
      .bvalid_i                         (gp_dma_axibvalid_o),    // Templated
      .arready_i                        (gp_dma_axiarready_o),   // Templated
      .rdata_i                          (gp_dma_axirdata_o[31:0]), // Templated
      .rresp_i                          (gp_dma_axirresp_o[1:0]), // Templated
      .rlast_i                          (gp_dma_axirlast_o),     // Templated
      .rvalid_i                         (gp_dma_axirvalid_o));   // Templated

   /*gp_dma  AUTO_TEMPLATE (
      .clk                              (gpdma_clk),
      .rst_n                            (gpdma_rst_n),
      .gpdmas_rdata                     (),
      .gpdmas_rdatap                    (gp_dma_s_rdatap[31:0]),
      .gpdmas_waccept                   (gp_dma_s_waccept),
      .gpdmas_rresp                     (gp_dma_s_rresp),
      .gpdmas_aerror                    (),
      .gpdmas_address                   (gp_dma_s_address[7:2]),
      .gpdmas_wdata                     (gp_dma_s_wdata[31:0]),
      .gpdmas_byten                     (gp_dma_s_byten[3:0]),
      .gpdmas_cmd                       (gp_dma_s_cmd),
      .gpdmas_req                       (gp_dma_s_req),
      .scan_in                          (32'b0),
      .scan_enable                      (1'b0),
      .scan_mode                        (1'b0),
      .gpdmam_address                   (gp_dma_m_address[31:0]),
      .gpdmam_align                     (gp_dma_m_align[4:0]),
      .gpdmam_wdata                     (gp_dma_m_wdata[31:0]),
      .gpdmam_xcnt                      (gp_dma_m_xcnt[2:0]),
      .gpdmam_byten                     (gp_dma_m_byten[3:0]),
      .gpdmam_bytecnt                   (gp_dma_m_bytecnt[9:0]),
      .gpdmam_cmd                       (gp_dma_m_cmd),
      .gpdmam_first                     (gp_dma_m_first),
      .gpdmam_last                      (gp_dma_m_last),
      .gpdmam_req                       (gp_dma_m_req),
      .gpdmam_amode                     (gp_dma_m_amode[1:0]),
      .gpdmam_clsize                    (gp_dma_m_clsize_tmp[1:0]),
      .gpdmam_epriority                 (),
      .gpdmam_rdatap                    (gp_dma_m_rdatap[31:0]),
      .gpdmam_waccept                   (gp_dma_m_waccept_t),
      .gpdmam_rresp                     (gp_dma_m_rresp_t),
      .scan_out                         (),
    )*/
   gp_dma I_gp_dma
     (/*autoinst*/
      // Outputs
      .scan_out                         (),                      // Templated
      .gpdmas_rdata                     (),                      // Templated
      .gpdmas_rdatap                    (gp_dma_s_rdatap[31:0]), // Templated
      .gpdmas_waccept                   (gp_dma_s_waccept),      // Templated
      .gpdmas_rresp                     (gp_dma_s_rresp),        // Templated
      .gpdmas_aerror                    (),                      // Templated
      .gpdmam_address                   (gp_dma_m_address[31:0]), // Templated
      .gpdmam_align                     (gp_dma_m_align[4:0]),   // Templated
      .gpdmam_wdata                     (gp_dma_m_wdata[31:0]),  // Templated
      .gpdmam_xcnt                      (gp_dma_m_xcnt[2:0]),    // Templated
      .gpdmam_byten                     (gp_dma_m_byten[3:0]),   // Templated
      .gpdmam_bytecnt                   (gp_dma_m_bytecnt[9:0]), // Templated
      .gpdmam_cmd                       (gp_dma_m_cmd),          // Templated
      .gpdmam_first                     (gp_dma_m_first),        // Templated
      .gpdmam_last                      (gp_dma_m_last),         // Templated
      .gpdmam_req                       (gp_dma_m_req),          // Templated
      .gpdmam_amode                     (gp_dma_m_amode[1:0]),   // Templated
      .gpdmam_clsize                    (gp_dma_m_clsize_tmp[1:0]), // Templated
      .gpdmam_epriority                 (),                      // Templated
      .gpdma_done_intr                  (gpdma_done_intr[3:0]),
      // Inputs
      .scan_in                          (32'b0),                 // Templated
      .scan_enable                      (1'b0),                  // Templated
      .scan_mode                        (1'b0),                  // Templated
      .clk                              (gpdma_clk),             // Templated
      .rst_n                            (gpdma_rst_n),           // Templated
      .big_endian                       (big_endian),
      .gpdmas_address                   (gp_dma_s_address[7:2]), // Templated
      .gpdmas_wdata                     (gp_dma_s_wdata[31:0]),  // Templated
      .gpdmas_byten                     (gp_dma_s_byten[3:0]),   // Templated
      .gpdmas_cmd                       (gp_dma_s_cmd),          // Templated
      .gpdmas_req                       (gp_dma_s_req),          // Templated
      .gpdmam_rdatap                    (gp_dma_m_rdatap[31:0]), // Templated
      .gpdmam_waccept                   (gp_dma_m_waccept_t),    // Templated
      .gpdmam_rresp                     (gp_dma_m_rresp_t));     // Templated

endmodule // cp_gpdma_wrap


// Local Variables:
// verilog-library-directories:("." "../../cbus2axi/hdl" "$PULP_ENV/src/ips/crg_legacy/design/soc_building_blocks/hdl")
// verilog-library-files:()
// verilog-library-extensions:(".v")
// verilog-auto-inst-param-value: t
// End:



