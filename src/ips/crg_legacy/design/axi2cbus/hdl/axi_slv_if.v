//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2015-11-25 0915 naftalyb>
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

module axi_slv_if (/*autoarg*/
   // Outputs
   awready_i, wready_i, bid_i, buser_i, bresp_i, bvalid_i, arready_i,
   rdata_i, rresp_i, rid_i, ruser_i, rlast_i, rvalid_i, dwfifo_datain,
   dwfifo_wr_op, cwfifo_datain, cwfifo_wr_op, rdfifo_rd_op,
   // Inputs
   aclk, areset_n, awaddr_o, awlen_o, awsize_o, awid_o, awuser_o,
   awvalid_o, awlock_o, awburst_o, awcache_o, awprot_o, awregion_o,
   awqos_o, wdata_o, wstrb_o, wlast_o, wvalid_o, wuser_o, bready_o,
   araddr_o, arlen_o, arsize_o, arid_o, aruser_o, arvalid_o, arlock_o,
   arburst_o, arcache_o, arprot_o, arregion_o, arqos_o, rready_o,
   dwfifo_full, dwfifo_afull, cwfifo_full, cwfifo_afull,
   rdfifo_dataout, rdfifo_empty
   );
   
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input                       aclk;
   input                       areset_n;
   
   //----------------------------------------------------------------------------
   // AXI I/F
   //----------------------------------------------------------------------------
   input [31:0]                awaddr_o;
   input [`A2C_LEN_BITS-1:0]   awlen_o;
   input [`A2C_SIZE_BITS-1:0]  awsize_o;
   input [`A2C_ID_DW-1:0]      awid_o;
   input                       awuser_o;
   input                       awvalid_o;
   input                       awlock_o;
   input [1:0]                 awburst_o;
   input [3:0]                 awcache_o;
   input [2:0]                 awprot_o;
   input [3:0]                 awregion_o;
   input [3:0]                 awqos_o;
   output                      awready_i;
   
   input [31:0]                wdata_o;
   input [32/8-1:0]            wstrb_o;
   input                       wlast_o;
   input                       wvalid_o;
   input                       wuser_o;
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
   input                       aruser_o;
   input                       arvalid_o;
   input                       arlock_o;
   input [1:0]                 arburst_o;
   input [3:0]                 arcache_o;
   input [2:0]                 arprot_o;
   input [3:0]                 arregion_o;
   input [3:0]                 arqos_o;
   output                      arready_i;
   
   output [31:0]               rdata_i;
   output [1:0]                rresp_i;
   output [`A2C_ID_DW-1:0]     rid_i;
   output                      ruser_i;
   output                      rlast_i;
   output                      rvalid_i;
   input                       rready_o;
   
   //----------------------------------------------------------------------------
   // Command & Data FIFO's
   //----------------------------------------------------------------------------
   output [`A2C_DWFIFO_DW-1:0] dwfifo_datain;
   output                      dwfifo_wr_op;
   input                       dwfifo_full;
   input                       dwfifo_afull;
   output [`A2C_CWFIFO_DW-1:0] cwfifo_datain;
   output                      cwfifo_wr_op;
   input                       cwfifo_full;
   input                       cwfifo_afull;
   input [`A2C_RDFIFO_DW-1:0]  rdfifo_dataout;
   output                      rdfifo_rd_op;
   input                       rdfifo_empty;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   reg [`A2C_DWFIFO_DW-1:0]    dwfifo_datain;
   reg                         dwfifo_wr_op;
   reg [`A2C_CWFIFO_DW-1:0]    cwfifo_datain;
   reg                         cwfifo_wr_op;
   reg                         cwfifo_wr_op_axiw_pend;
   reg                         cwfifo_wr_op_axir_pend;
   
   reg [`A2C_ID_DW-1:0]        bid_i;
   reg                         buser_i;
   reg [1:0]                   bresp_i;
   reg                         bvalid_i;
   reg                         axready_i;

   reg                         rdfifo_rd_data_val;

   wire                        sa_rdfifo_rd_op;
   wire                        sa_rdfifo_wr_op;
   
   reg                         wready_ena;
   
   /*autoinput*/
   
   /*autoutputs*/
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 sa_rdfifo_afull;        // From I_sa_rdfifo of sc_fifo.v
   wire [`A2C_RDFIFO_DW-1:0] sa_rdfifo_dataout; // From I_sa_rdfifo of sc_fifo.v
   wire                 sa_rdfifo_empty;        // From I_sa_rdfifo of sc_fifo.v
   // End of automatics

  /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (sa_rdfifo_dataout[`A2C_RDFIFO_DW-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (sa_rdfifo_empty),
      .full                             (),
      .afull                            (sa_rdfifo_afull),
      .entry_used                       (),
      .datain                           (rdfifo_dataout[`A2C_RDFIFO_DW-1:0]),
      .wr_op                            (sa_rdfifo_wr_op),
      .rd_op                            (sa_rdfifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(`A2C_RDFIFO_DW), .PTRW(3), .AFTHRS_LSB(2'h2)) I_sa_rdfifo
     (/*autoinst*/
      // Outputs
      .dataout                          (sa_rdfifo_dataout[`A2C_RDFIFO_DW-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (sa_rdfifo_empty),       // Templated
      .full                             (),                      // Templated
      .afull                            (sa_rdfifo_afull),       // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (aclk),                  // Templated
      .reset_n                          (areset_n),              // Templated
      .datain                           (rdfifo_dataout[`A2C_RDFIFO_DW-1:0]), // Templated
      .wr_op                            (sa_rdfifo_wr_op),       // Templated
      .rd_op                            (sa_rdfifo_rd_op),       // Templated
      .clr_err                          (1'b0));                         // Templated

   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   assign                      awready_i = axready_i;
   assign                      arready_i = axready_i;
   assign                      wready_i  = ~dwfifo_afull & ~cwfifo_afull & wready_ena;

//   assign                      sa_rdfifo_wr_op = (rdfifo_rd_data_val == 1'b1);
   assign                      sa_rdfifo_wr_op = (rdfifo_rd_op == 1'b1);
   assign                      sa_rdfifo_rd_op = (sa_rdfifo_empty == 1'b0 && rready_o == 1'b1);

   assign                      rdfifo_rd_op = (rdfifo_empty == 1'b0 && sa_rdfifo_afull == 1'b0);
   
   assign                      rvalid_i = ~sa_rdfifo_empty;
   assign                      rdata_i  = sa_rdfifo_dataout[`A2C_RDFIFO_RDATA_H:`A2C_RDFIFO_RDATA_L];
   assign                      rresp_i  = sa_rdfifo_dataout[`A2C_RDFIFO_RRESP_H:`A2C_RDFIFO_RRESP_L];
   assign                      rlast_i  = sa_rdfifo_dataout[`A2C_RDFIFO_RLAST_C];
   assign                      rid_i    = sa_rdfifo_dataout[`A2C_RDFIFO_ID_H:`A2C_RDFIFO_ID_L];
   assign                      ruser_i  = sa_rdfifo_dataout[`A2C_RDFIFO_USER_C];
   
   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 dwfifo_datain <= {`A2C_DWFIFO_DW{1'b0}};
                 cwfifo_datain <= {`A2C_CWFIFO_DW{1'b0}};
                 cwfifo_wr_op <= 1'b0;
                 cwfifo_wr_op_axiw_pend <= 1'b0;
                 cwfifo_wr_op_axir_pend <= 1'b0;
                 dwfifo_wr_op <= 1'b0;
                 rdfifo_rd_data_val <= 1'b0;
                 bresp_i <= 2'b00;
                 bvalid_i <= 1'b0;
                 axready_i <= 1'b1;
                 wready_ena <= 1'b0;
                 bid_i      <= {`A2C_ID_DW{1'b0}};
                 buser_i    <= 1'b0;
            end
          else
            begin
                 // Default
                 cwfifo_wr_op <= 1'b0;
                 dwfifo_datain <= {`A2C_DWFIFO_DW{1'b0}};
                 dwfifo_wr_op <= 1'b0;
                 rdfifo_rd_data_val <= rdfifo_rd_op;
                 
                 //----------------------------------------------------------------------------
                 // CBUS in nature doesn't support outstanding transaction therfore, the SGN
                 // AXI port must be configured to 1 outstanding transaction.
                 // This will also guarantee that two, simultaneously write & write requesets
                 // would never occure at the same time.
                 //----------------------------------------------------------------------------
                 //----------------------------------------------------------------------------
                 // Once "cwfifo_wr_op_axiw_pend" is asserted, we wait until the burst payload reaches
                 // the last word, both dwfifo and cwfifo have free space, than we write the
                 // the command word into the command-fifo.
                 //----------------------------------------------------------------------------
                 if (cwfifo_wr_op_axiw_pend == 1'b1)
                   begin
                        if (cwfifo_afull == 1'b0 && wready_i == 1'b1 && wvalid_o == 1'b1 && wlast_o == 1'b1)
                          begin
                               cwfifo_datain[`A2C_CWFIFO_WSTRB_H:`A2C_CWFIFO_WSTRB_L] <= wstrb_o;
                               cwfifo_wr_op <= 1'b1;
                               cwfifo_wr_op_axiw_pend <= 1'b0;
                               axready_i <= 1'b1;
                               wready_ena <= 1'b0;
                          end
                   end
                 else if (cwfifo_wr_op_axir_pend == 1'b1) //  && rdfifo_empty == 1'b1
                   begin
                        if (cwfifo_afull == 1'b0)
                          begin
                               cwfifo_datain[`A2C_CWFIFO_WSTRB_H:`A2C_CWFIFO_WSTRB_L] <= 4'b1111;
                               cwfifo_wr_op <= 1'b1;
                               cwfifo_wr_op_axir_pend <= 1'b0;
                               axready_i <= 1'b1;
                          end
                   end
                 //----------------------------------------------------------------------------
                 // In case of write/read transaction, we load the AXI addr, len and burst
                 // paramters. Also we  assert "cwfifo_wr_op_axiw_pend" and block further
                 // tranasctions by de-asserting "axready_i".
                 //----------------------------------------------------------------------------
                 // $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                 //----------------------------------------------------------------------------
                 // It's important to understand, that the following implementation assumes
                 // that "awvalid_o" and "arvalid_o" are not high at the same time!!
                 // This is true in case of configuring the SGN AXI port as single threaded!
                 //----------------------------------------------------------------------------
                 else
                   begin
                        if      (awvalid_o == 1'b1)
                          begin
                               cwfifo_datain <= {1'b0,{`A2C_ID_DW{1'b0}},1'b0, 4'h0, awburst_o[1:0], awlen_o[`A2C_LEN_BITS-1:0], awaddr_o[31:0]};
                               cwfifo_wr_op_axiw_pend <= 1'b1;
                               axready_i <= 1'b0;
                               wready_ena <= 1'b1;
                               bid_i[`A2C_ID_DW-1:0] <= awid_o[`A2C_ID_DW-1:0];
                               buser_i    <= awuser_o;
                          end
                        else if (arvalid_o == 1'b1)
                          begin
                               cwfifo_datain <= {aruser_o,arid_o[`A2C_ID_DW-1:0],1'b1, 4'h0, arburst_o[1:0], arlen_o[`A2C_LEN_BITS-1:0], araddr_o[31:0]};
                               cwfifo_wr_op_axir_pend <= 1'b1;
                               axready_i <= 1'b0;
                          end
                   end
                 //----------------------------------------------------------------------------
                 // Load the AXI write data into the data-FIFO.
                 //----------------------------------------------------------------------------
                 if (wready_i == 1'b1 && wvalid_o == 1'b1)
                   begin
                        dwfifo_datain <= {wlast_o, wstrb_o[3:0], wdata_o[31:0]};
                        dwfifo_wr_op <= 1'b1;
                   end
                 //----------------------------------------------------------------------------
                 // When the last AXI write data is loaded into the data-FIFO, bvalid_i
                 // is asserted with "OKAY" indication.
                 //----------------------------------------------------------------------------
                 if      (bvalid_i == 1'b1 && bready_o == 1'b1)
                   begin
                        bvalid_i <= 1'b0;
                   end
                 else if (wready_i == 1'b1 && wvalid_o == 1'b1 && wlast_o == 1'b1)
                   begin
                        bvalid_i <= 1'b1;
                        bresp_i <= `A2C_OKAY;
                   end
                 
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)

endmodule // axi_slv_if


// Local Variables:
// verilog-library-directories:("." "$PULP_ENV/src/ips/crg_legacy/design/soc_building_blocks/hdl")
// End:
