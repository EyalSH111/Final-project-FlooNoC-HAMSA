//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2016-01-17 1606 naftalyb>
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

module axi_mstr_if (/*autoarg*/
   // Outputs
   awaddr_o, awlen_o, awsize_o, awvalid_o, awlock_o, awburst_o,
   awcache_o, awprot_o, wdata_o, wstrb_o, wlast_o, wvalid_o, bready_o,
   araddr_o, arlen_o, arsize_o, arvalid_o, arlock_o, arburst_o,
   arcache_o, arprot_o, rready_o, dwfifo_rd_op, cwfifo_rd_op,
   rdfifo_datain, rdfifo_wr_op,
   // Inputs
   aclk, areset_n, awready_i, wready_i, bresp_i, bvalid_i, arready_i,
   rdata_i, rresp_i, rlast_i, rvalid_i, dwfifo_empty, dwfifo_dataout,
   cwfifo_empty, cwfifo_dataout, rdfifo_full, rdfifo_afull
   );

   parameter C2A_CWFIFO_PTRW = 5;
   
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input                       aclk;
   input                       areset_n;
   
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
   // Command, Wr-data and Rd-data FIFO's
   //----------------------------------------------------------------------------
   input                       dwfifo_empty;
   output                      dwfifo_rd_op; 
   input [`C2A_DWFIFO_DW-1:0]  dwfifo_dataout;
   input                       cwfifo_empty;
   output                      cwfifo_rd_op; 
   input [`C2A_CWFIFO_DW-1:0]  cwfifo_dataout;
   input                       rdfifo_full;
   input                       rdfifo_afull;
   output [`C2A_RDFIFO_DW-1:0] rdfifo_datain;
   output                      rdfifo_wr_op;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   wire [`C2A_SIZE_BITS-1:0]   awsize_o;
   wire                        awlock_o;
   wire [3:0]                  awcache_o;
   wire [2:0]                  awprot_o;
   wire [`C2A_SIZE_BITS-1:0]   arsize_o;
   wire                        arlock_o;
   wire [3:0]                  arcache_o;
   wire [2:0]                  arprot_o;
   
   reg [1:0]                   axi_mstr_sm;
   reg [31:0]                  awaddr_o;
   reg [`C2A_LEN_BITS-1:0]     awlen_o;
   reg                         awvalid_o;
   reg [1:0]                   awburst_o;
   reg [31:0]                  araddr_o;
   reg [`C2A_LEN_BITS-1:0]     arlen_o;
   reg                         arvalid_o;
   reg [1:0]                   arburst_o;
   reg [31:0]                  wdata_o;
   reg [3:0]                   wstrb_o;
   reg                         wlast_o;
   reg                         wvalid_o;

   wire [8:0]                  len16_cnt;
   
   reg [`C2A_RDFIFO_DW-1:0]    rdfifo_datain;
   reg                         rdfifo_wr_op;
   
   reg [C2A_CWFIFO_PTRW:0]    pend_awaddr_cntr;
   
   //----------------------------------------------------------------------------
   // AXI SM enumration
   //----------------------------------------------------------------------------
   `define C2A_AXI_AIDLE       2'b00
   `define C2A_AXI_ARD         2'b01
   `define C2A_AXI_AWR         2'b10
   
   /*autoinput*/
   
   /*autoutputs*/
   
   /*autowire*/

   
   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   assign                  len16_cnt = cwfifo_dataout[`C2A_CWFIFO_WCOUNT_H:`C2A_CWFIFO_WCOUNT_L];

   assign                  cwfifo_rd_op = (axi_mstr_sm[1:0] == `C2A_AXI_AIDLE) & (cwfifo_empty == 1'b0) |
                                          // Back2back read to read or read to write.
                                          (axi_mstr_sm[1:0] == `C2A_AXI_ARD) & (cwfifo_empty == 1'b0) & (arready_i == 1'b1) & (arvalid_o == 1'b1) |
                                          // Back2back write to write only. Write to read goes through idle state.
                                          (axi_mstr_sm[1:0] == `C2A_AXI_AWR) & (cwfifo_empty == 1'b0) & (awready_i == 1'h1) & (awvalid_o == 1'b1) & (cwfifo_dataout[`C2A_CWFIFO_CMD_C] == 1'b0);
   
//@   assign                  dwfifo_rd_op = (dwfifo_empty == 1'b0) & (wready_i == 1'b1);
   
   assign                  dwfifo_rd_op = ((dwfifo_empty == 1'b0) & (wready_i == 1'b1) & (wvalid_o == 1'b1) & (wlast_o == 1'b0) | (dwfifo_empty == 1'b0) & (wvalid_o == 1'b0)) & (pend_awaddr_cntr > {(C2A_CWFIFO_PTRW + 1){1'b0}});

   assign                  rready_o  = ~rdfifo_afull;
   
   assign                  bready_o  = 1'b1;
   assign                  awsize_o  = `C2A_SIZE_4B;
   assign                  awlock_o  = 1'b0;
   assign                  awcache_o = 4'h0;
   assign                  awprot_o  = 3'b010;
   assign                  arsize_o  = `C2A_SIZE_4B;
   assign                  arlock_o  = 1'b0;
   assign                  arcache_o = 4'h0;
   assign                  arprot_o  = 3'b010;
   
   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 axi_mstr_sm <= `C2A_AXI_AIDLE;
                 araddr_o <= 32'h0;
                 arlen_o <= {`C2A_LEN_BITS{1'b0}};
                 arvalid_o <= 1'b0;
                 arburst_o <= 2'b01;
                 awaddr_o <= 32'h0;
                 awlen_o <= {`C2A_LEN_BITS{1'b0}};
                 awvalid_o <= 1'b0;
                 awburst_o <= 2'b01;
            end
          else
            begin
                 // Default
                 case (axi_mstr_sm[1:0])
                   `C2A_AXI_AIDLE:
                     begin
                          if (cwfifo_empty == 1'b0)
                            begin
                                 // read transaction
                                 if (cwfifo_dataout[`C2A_CWFIFO_CMD_C] == 1'b1)
                                   begin
                                        axi_mstr_sm <= `C2A_AXI_ARD;
                                        arvalid_o <= 1'b1;
                                        araddr_o <= cwfifo_dataout[`C2A_CWFIFO_ADDR_H:`C2A_CWFIFO_ADDR_L];
                                        arlen_o <= len16_cnt - 9'h1;
                                        case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                          2'b00:
                                            begin
                                               arburst_o <= 2'b01;
                                            end
                                          2'b10:
                                            begin
                                               arburst_o <= 2'b00;
                                            end
                                          2'b11:
                                            begin
                                               arburst_o <= 2'b10;
                                            end
                                         default:
                                           begin
                                               arburst_o <= 2'b01;
                                           end
                                        endcase // case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                   end
                                 else
                                   begin
                                        axi_mstr_sm <= `C2A_AXI_AWR;
                                        awvalid_o <= 1'b1;
                                        awaddr_o <= cwfifo_dataout[`C2A_CWFIFO_ADDR_H:`C2A_CWFIFO_ADDR_L];
                                        awlen_o <= len16_cnt - 9'h1;
                                        case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                          2'b00:
                                            begin
                                               awburst_o <= 2'b01;
                                            end
                                          2'b10:
                                            begin
                                               awburst_o <= 2'b00;
                                            end
                                          2'b11:
                                            begin
                                               awburst_o <= 2'b10;
                                            end
                                         default:
                                           begin
                                               awburst_o <= 2'b01;
                                           end
                                        endcase // case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                   end
                            end
                     end
                   `C2A_AXI_ARD:
                     begin
                          if (arready_i == 1'b1)
                            begin
                                 if (cwfifo_empty == 1'b0)
                                   begin
                                        // read transaction
                                        if (cwfifo_dataout[`C2A_CWFIFO_CMD_C] == 1'b1)
                                          begin
                                               axi_mstr_sm <= `C2A_AXI_ARD;
                                               arvalid_o <= 1'b1;
                                               araddr_o <= cwfifo_dataout[`C2A_CWFIFO_ADDR_H:`C2A_CWFIFO_ADDR_L];
                                               arlen_o <= len16_cnt - 9'h1;
                                               case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                                 2'b00:
                                                   begin
                                                        arburst_o <= 2'b01;
                                                   end
                                                 2'b10:
                                                   begin
                                                        arburst_o <= 2'b00;
                                                   end
                                                 2'b11:
                                                   begin
                                                        arburst_o <= 2'b10;
                                                   end
                                                 default:
                                                   begin
                                                        arburst_o <= 2'b01;
                                                   end
                                               endcase // case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                          end
                                        else
                                          begin
                                               axi_mstr_sm <= `C2A_AXI_AWR;
                                               awvalid_o <= 1'b1;
                                               arvalid_o <= 1'b0;
                                               awaddr_o <= cwfifo_dataout[`C2A_CWFIFO_ADDR_H:`C2A_CWFIFO_ADDR_L];
                                               awlen_o <= len16_cnt - 9'h1;
                                               case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                                 2'b00:
                                                   begin
                                                        awburst_o <= 2'b01;
                                                   end
                                                 2'b10:
                                                   begin
                                                        awburst_o <= 2'b00;
                                                   end
                                                 2'b11:
                                                   begin
                                                        awburst_o <= 2'b10;
                                                   end
                                                 default:
                                                   begin
                                                        awburst_o <= 2'b01;
                                                   end
                                               endcase // case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                          end // else: !if(cwfifo_dataout[`C2A_CWFIFO_CMD_C] == 1'b1)
                                   end // if (cwfifo_empty == 1'b0)
                                 else
                                   begin
                                        axi_mstr_sm <= `C2A_AXI_AIDLE;
                                        arvalid_o <= 1'b0;
                                   end // else: !if(cwfifo_empty == 1'b0)
                            end // if (arready_i == 1'b1)
                     end // case: `C2A_AXI_ARD
                   `C2A_AXI_AWR:
                     begin
                          if (awready_i == 1'b1)
                            begin
                                 
                                 if (cwfifo_empty == 1'b0)
                                   begin
                                        // read transaction
                                        if (cwfifo_dataout[`C2A_CWFIFO_CMD_C] == 1'b1)
                                          begin
                                               // Transition from burst write to read must goes through idle state.
                                               axi_mstr_sm <= `C2A_AXI_AIDLE;
                                               awvalid_o <= 1'b0;
                                          end
                                        else
                                          begin
                                               axi_mstr_sm <= `C2A_AXI_AWR;
                                               awvalid_o <= 1'b1;
                                               awaddr_o <= cwfifo_dataout[`C2A_CWFIFO_ADDR_H:`C2A_CWFIFO_ADDR_L];
                                               awlen_o <= len16_cnt - 9'h1;
                                               case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                                 2'b00:
                                                   begin
                                                        awburst_o <= 2'b01;
                                                   end
                                                 2'b10:
                                                   begin
                                                        awburst_o <= 2'b00;
                                                   end
                                                 2'b11:
                                                   begin
                                                        awburst_o <= 2'b10;
                                                   end
                                                 default:
                                                   begin
                                                        awburst_o <= 2'b01;
                                                   end
                                               endcase // case (cwfifo_dataout[`C2A_CWFIFO_AMOD_H:`C2A_CWFIFO_AMOD_L])
                                          end // else: !if(cwfifo_dataout[`C2A_CWFIFO_CMD_C] == 1'b1)
                                   end // if (cwfifo_empty == 1'b0)
                                 else
                                   begin
                                        axi_mstr_sm <= `C2A_AXI_AIDLE;
                                        awvalid_o <= 1'b0;
                                   end // else: !if(cwfifo_empty == 1'b0)
                            end // if (awready_i == 1'b1)
                     end // case: `C2A_AXI_AWR
                   default:
                     begin
                     end
                 endcase // case(axi_mstr_sm[2:0])
            end // else: !if(hreset_n == 1'b0)
     end // always @ (posedge clk)


   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 rdfifo_datain <= {`C2A_RDFIFO_DW{1'b0}};
                 rdfifo_wr_op <= 1'b0;
            end
          else
            begin
                 // Default
                 //----------------------------------------------------------------------------
                 // Write respons data into rd-data FIFO
                 //----------------------------------------------------------------------------
                 rdfifo_datain <= {`C2A_RDFIFO_DW{1'b0}};
                 rdfifo_wr_op <= 1'b0;
                 if (rvalid_i == 1'b1 && rready_o == 1'b1)
                   begin
                        rdfifo_datain <= {rlast_i, rdata_i[31:0]};
                        rdfifo_wr_op <= 1'b1;
                   end
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)

   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 pend_awaddr_cntr <= {(C2A_CWFIFO_PTRW + 1){1'b0}};
            end
          else
            begin
                 // Default
                 //----------------------------------------------------------------------------
                 // Track the number of pending write-tracactions. We use this number
                 // to schedule the begnning of the write-data transfer ("write-data after write-address")
                 //----------------------------------------------------------------------------
                 if      ((awready_i == 1'b1 && awvalid_o == 1'b1) && (wready_i == 1'b1 && wvalid_o == 1'b1 && wlast_o == 1'b1))
                   begin
                        pend_awaddr_cntr <= pend_awaddr_cntr;
                   end
                 else if (awready_i == 1'b1 && awvalid_o == 1'b1)
                   begin
                        pend_awaddr_cntr <= pend_awaddr_cntr + {{(C2A_CWFIFO_PTRW){1'b0}}, 1'b1};
                   end
                 else if (wready_i == 1'b1 && wvalid_o == 1'b1 && wlast_o == 1'b1)
//               else if (bready_o == 1'b1 && bvalid_i == 1'b1)
                   begin
                        pend_awaddr_cntr <= pend_awaddr_cntr - {{(C2A_CWFIFO_PTRW){1'b0}}, 1'b1};
                   end
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)

   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 wdata_o <= 32'h0;
                 wstrb_o <= 4'h0;
                 wlast_o <= 1'b0;
                 wvalid_o <= 1'b0;
            end
          else
            begin
                 // Default
                 //----------------------------------------------------------------------------
                 // Only when we have at least one pending write-address we start data writing 
                 //----------------------------------------------------------------------------
                 if (pend_awaddr_cntr > {(C2A_CWFIFO_PTRW + 1){1'b0}})
                   begin
                        if (wvalid_o == 1'b0 && dwfifo_empty == 1'b0)
                          begin
                               wdata_o <= dwfifo_dataout[`C2A_DWFIFO_WDATA_H:`C2A_DWFIFO_WDATA_L];
                               wstrb_o <= dwfifo_dataout[`C2A_DWFIFO_BYTEN_H:`C2A_DWFIFO_BYTEN_L];
                               wlast_o <= dwfifo_dataout[`C2A_DWFIFO_LAST_C];
                               wvalid_o <= 1'b1;
                          end // if (wvalid_o == 1'b0 && dwfifo_empty == 1'b0)
                        else if (wvalid_o == 1'b1 && wready_i == 1'b1)
                          begin
                               if (dwfifo_empty == 1'b0 && wlast_o == 1'b0)
                                 begin
                                      wdata_o <= dwfifo_dataout[`C2A_DWFIFO_WDATA_H:`C2A_DWFIFO_WDATA_L];
                                      wstrb_o <= dwfifo_dataout[`C2A_DWFIFO_BYTEN_H:`C2A_DWFIFO_BYTEN_L];
                                      wlast_o <= dwfifo_dataout[`C2A_DWFIFO_LAST_C];
                                      wvalid_o <= 1'b1;
                                 end
                               else
                                 begin
                                      wdata_o <= 32'h0;
                                      wstrb_o <= 4'h0;
                                      wlast_o <= 1'b0;
                                      wvalid_o <= 1'b0;
                                 end // else: !if(dwfifo_empty == 1'b0 && wlast_o == 1'b0)
                          end // if (wvalid_o == 1'b1 && wready_i == 1'b1)
                   end // if (pend_awaddr_cntr > {(C2A_CWFIFO_PTRW + 1){1'b0}})
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)
   
endmodule // axi_mstr_if


// Local Variables:
// verilog-library-directories:(".")
// End:
