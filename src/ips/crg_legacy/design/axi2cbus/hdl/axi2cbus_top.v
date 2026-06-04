//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2015-12-14 2253 naftalyb>
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

`include "axi2cbus_cfg.v"

module axi2cbus_top (/*autoarg*/
   // Outputs
   cbus_m_address, cbus_m_align, cbus_m_amode, cbus_m_bytecnt,
   cbus_m_byten, cbus_m_clsize, cbus_m_cmd, cbus_m_first, cbus_m_last,
   cbus_m_mstid, cbus_m_req, cbus_m_wdata, cbus_m_xcnt, awready_i,
   wready_i, bid_i, buser_i, bresp_i, bvalid_i, arready_i, rdata_i,
   rresp_i, rlast_i, rid_i, ruser_i, rvalid_i,
   // Inputs
   aclk, areset_n, scan_mode, cbus_m_rdatap, cbus_m_rresp,
   cbus_m_waccept, awaddr_o, awlen_o, awsize_o, awid_o, awqos_o,
   awregion_o, awuser_o, awvalid_o, awlock_o, awburst_o, awcache_o,
   awprot_o, wdata_o, wstrb_o, wlast_o, wuser_o, wvalid_o, bready_o,
   araddr_o, arlen_o, arsize_o, arid_o, arqos_o, arregion_o, aruser_o,
   arvalid_o, arlock_o, arburst_o, arcache_o, arprot_o, rready_o
   );
   
   parameter A2C_DWFIFO_PTRW       = 5;
   parameter A2C_CWFIFO_PTRW       = 5;
   parameter A2C_RDFIFO_PTRW       = 5;
   
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input                       aclk;
   input                       areset_n;
   input                       scan_mode;
   
   //----------------------------------------------------------------------------
   // CBUS Master I/F
   //----------------------------------------------------------------------------
   output [31:0]               cbus_m_address;
   output [4:0]                cbus_m_align;
   output [1:0]                cbus_m_amode;
   output [9:0]                cbus_m_bytecnt;
   output [3:0]                cbus_m_byten;
   output [2:0]                cbus_m_clsize;
   output                      cbus_m_cmd;
   output                      cbus_m_first;
   output                      cbus_m_last;
   output [7:0]                cbus_m_mstid;
   output                      cbus_m_req;
   output [31:0]               cbus_m_wdata;
   output [2:0]                cbus_m_xcnt;
   input [31:0]                cbus_m_rdatap;
   input                       cbus_m_rresp;
   input                       cbus_m_waccept;
   
   //----------------------------------------------------------------------------
   // AXI I/F
   //----------------------------------------------------------------------------
   input [31:0]                awaddr_o;
   input [`A2C_LEN_BITS-1:0]   awlen_o;
   input [`A2C_SIZE_BITS-1:0]  awsize_o;
   input [`A2C_ID_DW-1:0]      awid_o;    
   input [3:0]                 awqos_o;   
   input [3:0]                 awregion_o;
   input                       awuser_o;  
   input                       awvalid_o;
   input                       awlock_o;
   input [1:0]                 awburst_o;
   input [3:0]                 awcache_o;
   input [2:0]                 awprot_o;
   output                      awready_i;
   
   input [31:0]                wdata_o;
   input [32/8-1:0]            wstrb_o;
   input                       wlast_o;
   input                       wuser_o;   
   input                       wvalid_o;
   output                      wready_i;
   
   output [`A2C_ID_DW-1:0]     bid_i;  
   output                      buser_i;
   output [1:0]                bresp_i;
   output                      bvalid_i;
   input                       bready_o;
   
   input [31:0]                araddr_o;
   input [`A2C_LEN_BITS-1:0]   arlen_o;
   input [`A2C_SIZE_BITS-1:0]  arsize_o;
   input [`A2C_ID_DW-1:0]      arid_o;    
   input [3:0]                 arqos_o;   
   input [3:0]                 arregion_o;
   input                       aruser_o;  
   input                       arvalid_o;
   input                       arlock_o;
   input [1:0]                 arburst_o;
   input [3:0]                 arcache_o;
   input [2:0]                 arprot_o;
   output                      arready_i;
   
   output [31:0]               rdata_i;
   output [1:0]                rresp_i;
   output                      rlast_i;
   output [`A2C_ID_DW-1:0]     rid_i;   
   output                      ruser_i; 
   output                      rvalid_i;
   input                       rready_o;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   wire                 dwfifo_afull;           // From I_wdtfifo of sc_fifo.v
   wire [`A2C_DWFIFO_DW-1:0] dwfifo_datain;     // From I_axi_slv_if of axi_slv_if.v
   wire [`A2C_DWFIFO_DW-1:0] dwfifo_dataout;    // From I_wdtfifo of sc_fifo.v
   wire                 dwfifo_empty;           // From I_wdtfifo of sc_fifo.v
   wire                 dwfifo_full;            // From I_wdtfifo of sc_fifo.v
   wire                 dwfifo_rd_op;           // From I_cbus_slv_if of cbus_slv_if.v
   wire                 dwfifo_wr_op;           // From I_axi_slv_if of axi_slv_if.v
   wire                 rdfifo_afull;           // From I_rdfifo of sc_fifo.v
   wire [`A2C_RDFIFO_DW-1:0] rdfifo_datain;     // From I_cbus_slv_if of cbus_slv_if.v
   wire [`A2C_RDFIFO_DW-1:0] rdfifo_dataout;    // From I_rdfifo of sc_fifo.v
   wire                 rdfifo_empty;           // From I_rdfifo of sc_fifo.v
   wire                 rdfifo_full;            // From I_rdfifo of sc_fifo.v
   wire                 rdfifo_rd_op;           // From I_axi_slv_if of axi_slv_if.v
   wire                 rdfifo_wr_op;           // From I_cbus_slv_if of cbus_slv_if.v
   
   /*autoinput*/
   
   /*autooutput*/
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 cwfifo_afull;           // From I_cmdfifo of sc_fifo.v
   wire [`A2C_CWFIFO_DW-1:0] cwfifo_datain;     // From I_axi_slv_if of axi_slv_if.v
   wire [`A2C_CWFIFO_DW-1:0] cwfifo_dataout;    // From I_cmdfifo of sc_fifo.v
   wire                 cwfifo_empty;           // From I_cmdfifo of sc_fifo.v
   wire                 cwfifo_full;            // From I_cmdfifo of sc_fifo.v
   wire                 cwfifo_rd_op;           // From I_cbus_slv_if of cbus_slv_if.v
   wire                 cwfifo_wr_op;           // From I_axi_slv_if of axi_slv_if.v
   // End of automatics

   
   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
//   assign dwfifo_afull = (dwfifo_entry_used >= (2**A2C_DWFIFO_PTRW - A2C_DWFIFO_AFTHRS_LSB)) ? 1'b1 : 1'b0;
//   assign rdfifo_afull = (rdfifo_entry_used >= (2**A2C_RDFIFO_PTRW - A2C_RDFIFO_AFTHRS_LSB)) ? 1'b1 : 1'b0;
   
   /*axi_mstr_core AUTO_TEMPLATE (
     ); */
   axi_slv_if I_axi_slv_if
     (/*autoinst*/
      // Outputs
      .awready_i                        (awready_i),
      .wready_i                         (wready_i),
      .bid_i                            (bid_i[`A2C_ID_DW-1:0]),
      .buser_i                          (buser_i),
      .bresp_i                          (bresp_i[1:0]),
      .bvalid_i                         (bvalid_i),
      .arready_i                        (arready_i),
      .rdata_i                          (rdata_i[31:0]),
      .rresp_i                          (rresp_i[1:0]),
      .rid_i                            (rid_i[`A2C_ID_DW-1:0]),
      .ruser_i                          (ruser_i),
      .rlast_i                          (rlast_i),
      .rvalid_i                         (rvalid_i),
      .dwfifo_datain                    (dwfifo_datain[`A2C_DWFIFO_DW-1:0]),
      .dwfifo_wr_op                     (dwfifo_wr_op),
      .cwfifo_datain                    (cwfifo_datain[`A2C_CWFIFO_DW-1:0]),
      .cwfifo_wr_op                     (cwfifo_wr_op),
      .rdfifo_rd_op                     (rdfifo_rd_op),
      // Inputs
      .aclk                             (aclk),
      .areset_n                         (areset_n),
      .awaddr_o                         (awaddr_o[31:0]),
      .awlen_o                          (awlen_o[`A2C_LEN_BITS-1:0]),
      .awsize_o                         (awsize_o[`A2C_SIZE_BITS-1:0]),
      .awid_o                           (awid_o[`A2C_ID_DW-1:0]),
      .awuser_o                         (awuser_o),
      .awvalid_o                        (awvalid_o),
      .awlock_o                         (awlock_o),
      .awburst_o                        (awburst_o[1:0]),
      .awcache_o                        (awcache_o[3:0]),
      .awprot_o                         (awprot_o[2:0]),
      .awregion_o                       (awregion_o[3:0]),
      .awqos_o                          (awqos_o[3:0]),
      .wdata_o                          (wdata_o[31:0]),
      .wstrb_o                          (wstrb_o[32/8-1:0]),
      .wlast_o                          (wlast_o),
      .wvalid_o                         (wvalid_o),
      .wuser_o                          (wuser_o),
      .bready_o                         (bready_o),
      .araddr_o                         (araddr_o[31:0]),
      .arlen_o                          (arlen_o[`A2C_LEN_BITS-1:0]),
      .arsize_o                         (arsize_o[`A2C_SIZE_BITS-1:0]),
      .arid_o                           (arid_o[`A2C_ID_DW-1:0]),
      .aruser_o                         (aruser_o),
      .arvalid_o                        (arvalid_o),
      .arlock_o                         (arlock_o),
      .arburst_o                        (arburst_o[1:0]),
      .arcache_o                        (arcache_o[3:0]),
      .arprot_o                         (arprot_o[2:0]),
      .arregion_o                       (arregion_o[3:0]),
      .arqos_o                          (arqos_o[3:0]),
      .rready_o                         (rready_o),
      .dwfifo_full                      (dwfifo_full),
      .dwfifo_afull                     (dwfifo_afull),
      .cwfifo_full                      (cwfifo_full),
      .cwfifo_afull                     (cwfifo_afull),
      .rdfifo_dataout                   (rdfifo_dataout[`A2C_RDFIFO_DW-1:0]),
      .rdfifo_empty                     (rdfifo_empty));

   /*cbus_mstr_core AUTO_TEMPLATE (
     ); */
   cbus_slv_if I_cbus_slv_if
     (/*autoinst*/
      // Outputs
      .cbus_m_address                   (cbus_m_address[31:0]),
      .cbus_m_align                     (cbus_m_align[4:0]),
      .cbus_m_amode                     (cbus_m_amode[1:0]),
      .cbus_m_bytecnt                   (cbus_m_bytecnt[9:0]),
      .cbus_m_byten                     (cbus_m_byten[3:0]),
      .cbus_m_clsize                    (cbus_m_clsize[2:0]),
      .cbus_m_cmd                       (cbus_m_cmd),
      .cbus_m_first                     (cbus_m_first),
      .cbus_m_last                      (cbus_m_last),
      .cbus_m_mstid                     (cbus_m_mstid[7:0]),
      .cbus_m_req                       (cbus_m_req),
      .cbus_m_wdata                     (cbus_m_wdata[31:0]),
      .cbus_m_xcnt                      (cbus_m_xcnt[2:0]),
      .dwfifo_rd_op                     (dwfifo_rd_op),
      .cwfifo_rd_op                     (cwfifo_rd_op),
      .rdfifo_datain                    (rdfifo_datain[`A2C_RDFIFO_DW-1:0]),
      .rdfifo_wr_op                     (rdfifo_wr_op),
      // Inputs
      .aclk                             (aclk),
      .areset_n                         (areset_n),
      .cbus_m_rdatap                    (cbus_m_rdatap[31:0]),
      .cbus_m_rresp                     (cbus_m_rresp),
      .cbus_m_waccept                   (cbus_m_waccept),
      .dwfifo_empty                     (dwfifo_empty),
      .dwfifo_dataout                   (dwfifo_dataout[`A2C_DWFIFO_DW-1:0]),
      .cwfifo_empty                     (cwfifo_empty),
      .cwfifo_dataout                   (cwfifo_dataout[`A2C_CWFIFO_DW-1:0]),
      .rdfifo_empty                     (rdfifo_empty),
      .rdfifo_full                      (rdfifo_full),
      .rdfifo_afull                     (rdfifo_afull));
   
   /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (cwfifo_dataout[`A2C_CWFIFO_DW-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (cwfifo_empty),
      .full                             (cwfifo_full),
      .afull                            (cwfifo_afull),
      .entry_used                       (),
      .datain                           (cwfifo_datain[`A2C_CWFIFO_DW-1:0]),
      .wr_op                            (cwfifo_wr_op),
      .rd_op                            (cwfifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(`A2C_CWFIFO_DW), .PTRW(A2C_CWFIFO_PTRW)) I_cmdfifo
     (/*autoinst*/
      // Outputs
      .dataout                          (cwfifo_dataout[`A2C_CWFIFO_DW-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (cwfifo_empty),          // Templated
      .full                             (cwfifo_full),           // Templated
      .afull                            (cwfifo_afull),          // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (aclk),                  // Templated
      .reset_n                          (areset_n),              // Templated
      .datain                           (cwfifo_datain[`A2C_CWFIFO_DW-1:0]), // Templated
      .wr_op                            (cwfifo_wr_op),          // Templated
      .rd_op                            (cwfifo_rd_op),          // Templated
      .clr_err                          (1'b0));                         // Templated

   /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (dwfifo_dataout[]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (dwfifo_empty),
      .full                             (dwfifo_full),
      .afull                            (dwfifo_afull),
      .entry_used                       (),
      .datain                           (dwfifo_datain[]),
      .wr_op                            (dwfifo_wr_op),
      .rd_op                            (dwfifo_rd_op),
      .clr_err                          (1'b0),
     ); */

   sc_fifo #(.DW(`A2C_DWFIFO_DW), .PTRW(A2C_DWFIFO_PTRW)) I_wdtfifo
   (/*autoinst*/
    // Outputs
    .dataout                            (dwfifo_dataout[(`A2C_DWFIFO_DW)-1:0]), // Templated
    .wr_full_err                        (),                      // Templated
    .rd_empty_err                       (),                      // Templated
    .empty                              (dwfifo_empty),          // Templated
    .full                               (dwfifo_full),           // Templated
    .afull                              (dwfifo_afull),          // Templated
    .entry_used                         (),                      // Templated
    // Inputs
    .clk                                (aclk),                  // Templated
    .reset_n                            (areset_n),              // Templated
    .datain                             (dwfifo_datain[(`A2C_DWFIFO_DW)-1:0]), // Templated
    .wr_op                              (dwfifo_wr_op),          // Templated
    .rd_op                              (dwfifo_rd_op),          // Templated
    .clr_err                            (1'b0));                         // Templated

//   /*generic_fifo_env_a256d37_ram AUTO_TEMPLATE (
//      .full                             (dwfifo_full),
//      .empty                            (dwfifo_empty),
//      .entry_used                       (dwfifo_entry_used[]),
//      .wr_full_err                      (),
//      .rd_data                          (dwfifo_dataout[]),
//      .rd_empty_err                     (),
//      .clk                              (aclk),
//      .reset_n                          (areset_n),
//      .wr_op                            (dwfifo_wr_op),
//      .wr_data                          (dwfifo_datain[]),
//      .wr_mask                          ({@"vl-width"{1'b1}}),
//      .rd_op                            (dwfifo_rd_op),
//      .sreset_n                         (areset_n),
//     ); */
//   generic_fifo_env_a256d37_ram #(.DAT_WIDTH(`A2C_DWFIFO_DW), .PTR_WIDTH(A2C_DWFIFO_PTRW)) I_wdtfifo
//     (/*autoinst*/
//      // Outputs
//      .full                             (dwfifo_full),
//      .empty                            (dwfifo_empty),
//      .entry_used                       (dwfifo_entry_used[A2C_DWFIFO_PTRW:0]),
//      .wr_full_err                      (),
//      .rd_data                          (dwfifo_dataout[(`A2C_DWFIFO_DW)-1:0]),
//      .rd_empty_err                     (),
//      // Inputs
//      .clk                              (aclk),
//      .reset_n                          (areset_n),
//      .wr_op                            (dwfifo_wr_op),
//      .wr_data                          (dwfifo_datain[(`A2C_DWFIFO_DW)-1:0]),
//      .wr_mask                          ({(1+((`A2C_DWFIFO_DW)-1)){1'b1}}),
//      .rd_op                            (dwfifo_rd_op),
//      .scan_mode                        (scan_mode),
//      .sreset_n                         (areset_n),
//      .ram_ctrl_vec                     (ram_ctrl_vec[6:0]));
//

   /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (rdfifo_dataout[]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (rdfifo_empty),
      .full                             (rdfifo_full),
      .afull                            (rdfifo_afull),
      .entry_used                       (),
      .datain                           (rdfifo_datain[]),
      .wr_op                            (rdfifo_wr_op),
      .rd_op                            (rdfifo_rd_op),
      .clr_err                          (1'b0),
     ); */

   sc_fifo #(.DW(`A2C_RDFIFO_DW), .PTRW(A2C_RDFIFO_PTRW)) I_rdfifo
   (/*autoinst*/
    // Outputs
    .dataout                            (rdfifo_dataout[(`A2C_RDFIFO_DW)-1:0]), // Templated
    .wr_full_err                        (),                      // Templated
    .rd_empty_err                       (),                      // Templated
    .empty                              (rdfifo_empty),          // Templated
    .full                               (rdfifo_full),           // Templated
    .afull                              (rdfifo_afull),          // Templated
    .entry_used                         (),                      // Templated
    // Inputs
    .clk                                (aclk),                  // Templated
    .reset_n                            (areset_n),              // Templated
    .datain                             (rdfifo_datain[(`A2C_RDFIFO_DW)-1:0]), // Templated
    .wr_op                              (rdfifo_wr_op),          // Templated
    .rd_op                              (rdfifo_rd_op),          // Templated
    .clr_err                            (1'b0));                         // Templated


//
//
//   /*generic_fifo_env_a256d35_ram AUTO_TEMPLATE (
//      .full                             (rdfifo_full),
//      .empty                            (rdfifo_empty),
//      .entry_used                       (rdfifo_entry_used[]),
//      .wr_full_err                      (),
//      .rd_data                          (rdfifo_dataout[]),
//      .rd_empty_err                     (),
//      .clk                              (aclk),
//      .reset_n                          (areset_n),
//      .wr_op                            (rdfifo_wr_op),
//      .wr_data                          (rdfifo_datain[]),
//      .wr_mask                          ({@"vl-width"{1'b1}}),
//      .rd_op                            (rdfifo_rd_op),
//      .sreset_n                         (areset_n),
//     ); */
//   generic_fifo_env_a256d35_ram #(.DAT_WIDTH(`A2C_RDFIFO_DW), .PTR_WIDTH(A2C_RDFIFO_PTRW)) I_rdfifo
//     (/*autoinst*/
//      // Outputs
//      .full                             (rdfifo_full),
//      .empty                            (rdfifo_empty),
//      .entry_used                       (rdfifo_entry_used[A2C_RDFIFO_PTRW:0]),
//      .wr_full_err                      (),
//      .rd_data                          (rdfifo_dataout[(`A2C_RDFIFO_DW)-1:0]),
//      .rd_empty_err                     (),
//      // Inputs
//      .clk                              (aclk),
//      .reset_n                          (areset_n),
//      .wr_op                            (rdfifo_wr_op),
//      .wr_data                          (rdfifo_datain[(`A2C_RDFIFO_DW)-1:0]),
//      .wr_mask                          ({(1+((`A2C_RDFIFO_DW)-1)){1'b1}}),
//      .rd_op                            (rdfifo_rd_op),
//      .scan_mode                        (scan_mode),
//      .sreset_n                         (areset_n),
//      .ram_ctrl_vec                     (ram_ctrl_vec[6:0]));

endmodule // axi2cbus_top


// Local Variables:
// verilog-library-directories:("." "$PULP_ENV/src/ips/crg_legacy/design/soc_building_blocks/hdl")
// verilog-auto-inst-param-value:t
// End:
