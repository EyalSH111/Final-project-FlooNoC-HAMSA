//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2015-08-09 2330 naftalyb>
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 3.4.2015 : created
//------------------------------------------------------------------------------

`include "cbus2axi_cfg.v"

module cbus2axi_top (/*autoarg*/
   // Outputs
   cbus_m_rdatap, cbus_m_rresp, cbus_m_waccept, awaddr_o, awlen_o,
   awsize_o, awvalid_o, awlock_o, awburst_o, awcache_o, awprot_o,
   wdata_o, wstrb_o, wlast_o, wvalid_o, bready_o, araddr_o, arlen_o,
   arsize_o, arvalid_o, arlock_o, arburst_o, arcache_o, arprot_o,
   rready_o,
   // Inputs
   aclk, areset_n, cbus_m_address, cbus_m_align, cbus_m_amode,
   cbus_m_bytecnt, cbus_m_byten, cbus_m_clsize, cbus_m_cmd,
   cbus_m_first, cbus_m_last, cbus_m_mstid, cbus_m_req, cbus_m_wdata,
   cbus_m_xcnt, awready_i, wready_i, bresp_i, bvalid_i, arready_i,
   rdata_i, rresp_i, rlast_i, rvalid_i
   );
   
   parameter C2A_DWFIFO_PTRW       = 5;
   parameter C2A_DWFIFO_AFTHRS_LSB = 2'b01;
   parameter C2A_CWFIFO_PTRW       = 5;
   parameter C2A_CWFIFO_AFTHRS_LSB = 2'b01;
   parameter C2A_RDFIFO_PTRW       = 5;
   parameter C2A_RDFIFO_AFTHRS_LSB = 2'b01;
      
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input                       aclk;
   input                       areset_n;
   
   //----------------------------------------------------------------------------
   // 
   //----------------------------------------------------------------------------
   input [31:0]                cbus_m_address;
   input [4:0]                 cbus_m_align;
   input [1:0]                 cbus_m_amode;
   input [9:0]                 cbus_m_bytecnt;
   input [3:0]                 cbus_m_byten;
   input [2:0]                 cbus_m_clsize;
   input                       cbus_m_cmd;
   input                       cbus_m_first;
   input                       cbus_m_last;
   input [7:0]                 cbus_m_mstid;
   input                       cbus_m_req;
   input [31:0]                cbus_m_wdata;
   input [2:0]                 cbus_m_xcnt;
   output [31:0]               cbus_m_rdatap;
   output                      cbus_m_rresp;
   output                      cbus_m_waccept;
   
   //----------------------------------------------------------------------------
   // AXI I/F
   //----------------------------------------------------------------------------
   output [31:0]               awaddr_o;
   output [`C2A_LEN_BITS-1:0]  awlen_o;
   output [`C2A_SIZE_BITS-1:0] awsize_o;
   output                      awvalid_o;
   output                      awlock_o;
   output [1:0]                awburst_o;
   output [3:0]                awcache_o;
   output [2:0]                awprot_o;
   input                       awready_i;
   
   output [31:0]               wdata_o;
   output [3:0]                wstrb_o;
   output                      wlast_o;
   output                      wvalid_o;
   input                       wready_i;
   
   input [1:0]                 bresp_i;
   input                       bvalid_i;
   output                      bready_o;
   
   output [31:0]               araddr_o;
   output [`C2A_LEN_BITS-1:0]  arlen_o;
   output [`C2A_SIZE_BITS-1:0] arsize_o;
   output                      arvalid_o;
   output                      arlock_o;
   output [1:0]                arburst_o;
   output [3:0]                arcache_o;
   output [2:0]                arprot_o;
   input                       arready_i;
   
   input [31:0]                rdata_i;
   input [1:0]                 rresp_i;
   input                       rlast_i;
   input                       rvalid_i;
   output                      rready_o;
   
   //----------------------------------------------------------------------------
   // 
   //----------------------------------------------------------------------------
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   
   /*autoinput*/
   
   /*autoutputs*/
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 cwfifo_afull;           // From I_cmdfifo of sc_fifo.v
   wire [`C2A_CWFIFO_DW-1:0] cwfifo_datain;     // From I_cbus_mstr_if of cbus_mstr_if.v
   wire [`C2A_CWFIFO_DW-1:0] cwfifo_dataout;    // From I_cmdfifo of sc_fifo.v
   wire                 cwfifo_empty;           // From I_cmdfifo of sc_fifo.v
   wire                 cwfifo_full;            // From I_cmdfifo of sc_fifo.v
   wire                 cwfifo_rd_op;           // From I_axi_mstr_if of axi_mstr_if.v
   wire                 cwfifo_wr_op;           // From I_cbus_mstr_if of cbus_mstr_if.v
   wire                 dwfifo_afull;           // From I_wdtfifo of sc_fifo.v
   wire [`C2A_DWFIFO_DW-1:0] dwfifo_datain;     // From I_cbus_mstr_if of cbus_mstr_if.v
   wire [`C2A_DWFIFO_DW-1:0] dwfifo_dataout;    // From I_wdtfifo of sc_fifo.v
   wire                 dwfifo_empty;           // From I_wdtfifo of sc_fifo.v
   wire                 dwfifo_full;            // From I_wdtfifo of sc_fifo.v
   wire                 dwfifo_rd_op;           // From I_axi_mstr_if of axi_mstr_if.v
   wire                 dwfifo_wr_op;           // From I_cbus_mstr_if of cbus_mstr_if.v
   wire                 rdfifo_afull;           // From I_rdfifo of sc_fifo.v
   wire [`C2A_RDFIFO_DW-1:0] rdfifo_datain;     // From I_axi_mstr_if of axi_mstr_if.v
   wire [`C2A_RDFIFO_DW-1:0] rdfifo_dataout;    // From I_rdfifo of sc_fifo.v
   wire                 rdfifo_empty;           // From I_rdfifo of sc_fifo.v
   wire                 rdfifo_full;            // From I_rdfifo of sc_fifo.v
   wire                 rdfifo_rd_op;           // From I_cbus_mstr_if of cbus_mstr_if.v
   wire                 rdfifo_wr_op;           // From I_axi_mstr_if of axi_mstr_if.v
   // End of automatics

   
   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   //first(1),last(1),cmd(1),bcnt(8),byten(4),a(32),d(32)
   
   /*axi_mstr_if AUTO_TEMPLATE (
     ); */
   axi_mstr_if #(.C2A_CWFIFO_PTRW(C2A_CWFIFO_PTRW)) I_axi_mstr_if
     (/*autoinst*/
      // Outputs
      .awaddr_o                         (awaddr_o[31:0]),
      .awlen_o                          (awlen_o[`C2A_LEN_BITS-1:0]),
      .awsize_o                         (awsize_o[`C2A_SIZE_BITS-1:0]),
      .awvalid_o                        (awvalid_o),
      .awlock_o                         (awlock_o),
      .awburst_o                        (awburst_o[1:0]),
      .awcache_o                        (awcache_o[3:0]),
      .awprot_o                         (awprot_o[2:0]),
      .wdata_o                          (wdata_o[31:0]),
      .wstrb_o                          (wstrb_o[3:0]),
      .wlast_o                          (wlast_o),
      .wvalid_o                         (wvalid_o),
      .bready_o                         (bready_o),
      .araddr_o                         (araddr_o[31:0]),
      .arlen_o                          (arlen_o[`C2A_LEN_BITS-1:0]),
      .arsize_o                         (arsize_o[`C2A_SIZE_BITS-1:0]),
      .arvalid_o                        (arvalid_o),
      .arlock_o                         (arlock_o),
      .arburst_o                        (arburst_o[1:0]),
      .arcache_o                        (arcache_o[3:0]),
      .arprot_o                         (arprot_o[2:0]),
      .rready_o                         (rready_o),
      .dwfifo_rd_op                     (dwfifo_rd_op),
      .cwfifo_rd_op                     (cwfifo_rd_op),
      .rdfifo_datain                    (rdfifo_datain[`C2A_RDFIFO_DW-1:0]),
      .rdfifo_wr_op                     (rdfifo_wr_op),
      // Inputs
      .aclk                             (aclk),
      .areset_n                         (areset_n),
      .awready_i                        (awready_i),
      .wready_i                         (wready_i),
      .bresp_i                          (bresp_i[1:0]),
      .bvalid_i                         (bvalid_i),
      .arready_i                        (arready_i),
      .rdata_i                          (rdata_i[31:0]),
      .rresp_i                          (rresp_i[1:0]),
      .rlast_i                          (rlast_i),
      .rvalid_i                         (rvalid_i),
      .dwfifo_empty                     (dwfifo_empty),
      .dwfifo_dataout                   (dwfifo_dataout[`C2A_DWFIFO_DW-1:0]),
      .cwfifo_empty                     (cwfifo_empty),
      .cwfifo_dataout                   (cwfifo_dataout[`C2A_CWFIFO_DW-1:0]),
      .rdfifo_full                      (rdfifo_full),
      .rdfifo_afull                     (rdfifo_afull));

   /*cbus_mstr_if AUTO_TEMPLATE (
     ); */
   cbus_mstr_if I_cbus_mstr_if
     (/*autoinst*/
      // Outputs
      .cbus_m_waccept                   (cbus_m_waccept),
      .cbus_m_rdatap                    (cbus_m_rdatap[31:0]),
      .cbus_m_rresp                     (cbus_m_rresp),
      .dwfifo_datain                    (dwfifo_datain[`C2A_DWFIFO_DW-1:0]),
      .dwfifo_wr_op                     (dwfifo_wr_op),
      .cwfifo_datain                    (cwfifo_datain[`C2A_CWFIFO_DW-1:0]),
      .cwfifo_wr_op                     (cwfifo_wr_op),
      .rdfifo_rd_op                     (rdfifo_rd_op),
      // Inputs
      .aclk                             (aclk),
      .areset_n                         (areset_n),
      .cbus_m_req                       (cbus_m_req),
      .cbus_m_mstid                     (cbus_m_mstid[7:0]),
      .cbus_m_address                   (cbus_m_address[31:0]),
      .cbus_m_xcnt                      (cbus_m_xcnt[2:0]),
      .cbus_m_align                     (cbus_m_align[4:0]),
      .cbus_m_cmd                       (cbus_m_cmd),
      .cbus_m_bytecnt                   (cbus_m_bytecnt[9:0]),
      .cbus_m_byten                     (cbus_m_byten[3:0]),
      .cbus_m_first                     (cbus_m_first),
      .cbus_m_last                      (cbus_m_last),
      .cbus_m_amode                     (cbus_m_amode[1:0]),
      .cbus_m_clsize                    (cbus_m_clsize[2:0]),
      .cbus_m_wdata                     (cbus_m_wdata[31:0]),
      .dwfifo_full                      (dwfifo_full),
      .dwfifo_afull                     (dwfifo_afull),
      .cwfifo_full                      (cwfifo_full),
      .cwfifo_afull                     (cwfifo_afull),
      .rdfifo_dataout                   (rdfifo_dataout[`C2A_RDFIFO_DW-1:0]),
      .rdfifo_empty                     (rdfifo_empty));
   
   /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (cwfifo_dataout[`C2A_CWFIFO_DW-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (cwfifo_empty),
      .full                             (cwfifo_full),
      .afull                            (cwfifo_afull),
      .entry_used                       (),
      .datain                           (cwfifo_datain[`C2A_CWFIFO_DW-1:0]),
      .wr_op                            (cwfifo_wr_op),
      .rd_op                            (cwfifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(`C2A_CWFIFO_DW), .PTRW(C2A_CWFIFO_PTRW), .AFTHRS_LSB(C2A_CWFIFO_AFTHRS_LSB)) I_cmdfifo
     (/*autoinst*/
      // Outputs
      .dataout                          (cwfifo_dataout[`C2A_CWFIFO_DW-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (cwfifo_empty),          // Templated
      .full                             (cwfifo_full),           // Templated
      .afull                            (cwfifo_afull),          // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (aclk),                  // Templated
      .reset_n                          (areset_n),              // Templated
      .datain                           (cwfifo_datain[`C2A_CWFIFO_DW-1:0]), // Templated
      .wr_op                            (cwfifo_wr_op),          // Templated
      .rd_op                            (cwfifo_rd_op),          // Templated
      .clr_err                          (1'b0));                  // Templated
   
   /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (dwfifo_dataout[`C2A_DWFIFO_DW-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (dwfifo_empty),
      .full                             (dwfifo_full),
      .afull                            (dwfifo_afull),
      .entry_used                       (),
      .datain                           (dwfifo_datain[`C2A_DWFIFO_DW-1:0]),
      .wr_op                            (dwfifo_wr_op),
      .rd_op                            (dwfifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(`C2A_DWFIFO_DW), .PTRW(C2A_DWFIFO_PTRW), .AFTHRS_LSB(C2A_DWFIFO_AFTHRS_LSB)) I_wdtfifo
     (/*autoinst*/
      // Outputs
      .dataout                          (dwfifo_dataout[`C2A_DWFIFO_DW-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (dwfifo_empty),          // Templated
      .full                             (dwfifo_full),           // Templated
      .afull                            (dwfifo_afull),          // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (aclk),                  // Templated
      .reset_n                          (areset_n),              // Templated
      .datain                           (dwfifo_datain[`C2A_DWFIFO_DW-1:0]), // Templated
      .wr_op                            (dwfifo_wr_op),          // Templated
      .rd_op                            (dwfifo_rd_op),          // Templated
      .clr_err                          (1'b0));                  // Templated

   /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (rdfifo_dataout[`C2A_RDFIFO_DW-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (rdfifo_empty),
      .full                             (rdfifo_full),
      .afull                            (rdfifo_afull),
      .entry_used                       (),
      .datain                           (rdfifo_datain[`C2A_RDFIFO_DW-1:0]),
      .wr_op                            (rdfifo_wr_op),
      .rd_op                            (rdfifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(`C2A_RDFIFO_DW), .PTRW(C2A_RDFIFO_PTRW), .AFTHRS_LSB(C2A_RDFIFO_AFTHRS_LSB)) I_rdfifo
     (/*autoinst*/
      // Outputs
      .dataout                          (rdfifo_dataout[`C2A_RDFIFO_DW-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (rdfifo_empty),          // Templated
      .full                             (rdfifo_full),           // Templated
      .afull                            (rdfifo_afull),          // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (aclk),                  // Templated
      .reset_n                          (areset_n),              // Templated
      .datain                           (rdfifo_datain[`C2A_RDFIFO_DW-1:0]), // Templated
      .wr_op                            (rdfifo_wr_op),          // Templated
      .rd_op                            (rdfifo_rd_op),          // Templated
      .clr_err                          (1'b0));                  // Templated

endmodule // cbus2axi_top


// Local Variables:
// verilog-library-directories:("." "$NEGEV_IP/design/crgn/soc_building_blocks/hdl")
// End:
