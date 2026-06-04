//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2015-12-31 2312 naftalyb>
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

module cbus_mstr_if (/*autoarg*/
   // Outputs
   cbus_m_waccept, cbus_m_rdatap, cbus_m_rresp, dwfifo_datain,
   dwfifo_wr_op, cwfifo_datain, cwfifo_wr_op, rdfifo_rd_op,
   // Inputs
   aclk, areset_n, cbus_m_req, cbus_m_mstid, cbus_m_address,
   cbus_m_xcnt, cbus_m_align, cbus_m_cmd, cbus_m_bytecnt,
   cbus_m_byten, cbus_m_first, cbus_m_last, cbus_m_amode,
   cbus_m_clsize, cbus_m_wdata, dwfifo_full, dwfifo_afull,
   cwfifo_full, cwfifo_afull, rdfifo_dataout, rdfifo_empty
   );
   
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input                       aclk;
   input                       areset_n;
   
   //----------------------------------------------------------------------------
   // CBUS Master I/F
   //----------------------------------------------------------------------------
   input                       cbus_m_req;
   input [7:0]                 cbus_m_mstid;
   input [31:0]                cbus_m_address;
   input [2:0]                 cbus_m_xcnt;
   input [4:0]                 cbus_m_align;
   input                       cbus_m_cmd;
   input [9:0]                 cbus_m_bytecnt;
   input [3:0]                 cbus_m_byten;
   input                       cbus_m_first;
   input                       cbus_m_last;
   input [1:0]                 cbus_m_amode;
   input [2:0]                 cbus_m_clsize;
   input [31:0]                cbus_m_wdata;
   output                      cbus_m_waccept;
   output [31:0]               cbus_m_rdatap;
   output                      cbus_m_rresp;
   
   //----------------------------------------------------------------------------
   // Command & Data FIFO's
   //----------------------------------------------------------------------------
   output [`C2A_DWFIFO_DW-1:0] dwfifo_datain;
   output                      dwfifo_wr_op;
   input                       dwfifo_full;
   input                       dwfifo_afull;
   output [`C2A_CWFIFO_DW-1:0] cwfifo_datain;
   output                      cwfifo_wr_op;
   input                       cwfifo_full;
   input                       cwfifo_afull;
   input [`C2A_RDFIFO_DW-1:0]  rdfifo_dataout;
   output                      rdfifo_rd_op;
   input                       rdfifo_empty;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   wire [8:0]                  cbus_m_bytecnt_w;
   reg [`C2A_DWFIFO_DW-1:0]    dwfifo_datain;
   reg                         dwfifo_wr_op;
   reg [`C2A_CWFIFO_DW-1:0]    cwfifo_datain;
   reg                         cwfifo_wr_op;
   reg [31:0]                  cbus_m_rdatap;
   reg                         cbus_rd_cmd_pend;
   reg                         cbus_wr_cmd_pend;
   reg [3:0]                   cbus_wdata_cntr;
   wire                        cbus_m_last_m;
   wire [9:0]                  cbus_m_bytecnt_adj;
   
   /*autoinput*/
   
   /*autoutputs*/
   
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   //----------------------------------------------------------------------------
   // When access to non-DWORD aligned word is made, we adjust the byte-count
   // by adding cbus_m_address[1:0] to the incoming byte-count value.
   //----------------------------------------------------------------------------
   assign                  cbus_m_bytecnt_adj  = cbus_m_bytecnt[9:0] + {8'h0, cbus_m_address[1:0]};
   assign                  cbus_m_bytecnt_w    = (cbus_m_bytecnt_adj[1:0] == 2'b00) ? {1'b0, cbus_m_bytecnt_adj[9:2]} : {1'b0, cbus_m_bytecnt_adj[9:2]} + 9'h1;
   assign                  cbus_m_waccept      = ~dwfifo_afull;
   
   assign                  rdfifo_rd_op  = (cbus_m_req == 1'b1 && cbus_m_cmd == 1'b1) ? ~rdfifo_empty : 1'b0;
   assign                  cbus_m_rresp  = rdfifo_rd_op;
   assign                  cbus_m_last_m = cbus_m_last;
   
   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 cbus_wdata_cntr <= 4'h0;
            end
          else
            begin
                 // Default
                 if (cbus_m_req == 1'b1 && cbus_m_cmd == 1'b0 && cbus_m_waccept == 1'b1)
                   begin
                        if (cbus_m_last == 1'b1)
                          begin
                               cbus_wdata_cntr <= 4'h0;
                          end
                        else
                          begin
                               cbus_wdata_cntr <= cbus_wdata_cntr + 4'h1;
                          end
                   end
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)

   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 dwfifo_datain <= {`C2A_DWFIFO_DW{1'b0}};
                 dwfifo_wr_op <= 1'b0;
                 cwfifo_datain <= {`C2A_CWFIFO_DW{1'b0}};
                 cwfifo_wr_op <= 1'b0;
                 cbus_rd_cmd_pend <= 1'b0;
                 cbus_wr_cmd_pend <= 1'b0;
            end
          else
            begin
                 // Default
                 cwfifo_datain <= {`C2A_CWFIFO_DW{1'b0}};
                 cwfifo_wr_op <= 1'b0;
                 dwfifo_datain <= {`C2A_DWFIFO_DW{1'b0}};
                 dwfifo_wr_op <= 1'b0;
                 //----------------------------------------------------------------------------
                 // Write command: write is post in nature. We write the entire cbus and send 
                 // "waccept" as long as the FIFO is not almost-full.&& cbus_m_waccept == 1'b1
                 //----------------------------------------------------------------------------
                 if      (cbus_m_req == 1'b1 && cbus_m_cmd == 1'b0)
                   begin
                        if (cbus_m_waccept == 1'b1 && cbus_wr_cmd_pend == 1'b1)
                          begin
                               cbus_wr_cmd_pend <= 1'b0;
                          end
                        else if (cbus_m_first == 1'b1 && cbus_wr_cmd_pend == 1'b0)
                          begin
                               cwfifo_datain <= {cbus_m_amode, cbus_m_first, cbus_m_last_m, cbus_m_cmd, cbus_m_bytecnt_w[8:0], cbus_m_address[31:0]};
                               cwfifo_wr_op <= 1'b1;
                               //----------------------------------------------------------------------------
                               // If we're receiving a burst, we asssert "cbus_wr_cmd_pend" signal (which
                               // will be cleared on the following cycles)
                               //----------------------------------------------------------------------------
                               if (cbus_m_last == 1'b0)
                                 begin
                                      cbus_wr_cmd_pend <= 1'b1;
                                 end
                          end // else: !if(cbus_m_rresp == 1'b1)
                        dwfifo_datain <= {cbus_m_last_m, cbus_m_byten[3:0], cbus_m_wdata[31:0]};
                        dwfifo_wr_op <= 1'b1;
                   end
                 //----------------------------------------------------------------------------
                 // Read command: read command is blocking. We write the first state of CBUS
                 // into the FIFO and block further iterations until first "cbus_m_rresp" is arrive.
                 // The AXI side will reconstruct the transaction by using the first address and size.
                 //----------------------------------------------------------------------------
                 else if (cbus_m_req == 1'b1 && cbus_m_cmd == 1'b1)
                   begin
                        if (cbus_m_rresp == 1'b1 && cbus_rd_cmd_pend == 1'b1)
                          begin
                               cbus_rd_cmd_pend <= 1'b0;
                          end
                        else if (cbus_m_first == 1'b1 && cbus_rd_cmd_pend == 1'b0)
                          begin
                               cwfifo_datain <= {cbus_m_amode, cbus_m_first, cbus_m_last, cbus_m_cmd, cbus_m_bytecnt_w[8:0], cbus_m_address[31:0]};
                               cwfifo_wr_op <= 1'b1;
                               cbus_rd_cmd_pend <= 1'b1;
                          end // else: !if(cbus_m_rresp == 1'b1)
                   end
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)
   
   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 cbus_m_rdatap <= 32'h0;
            end
          else
            begin
                 // Default
                 if (cbus_m_rresp == 1'b1)
                   begin
                        cbus_m_rdatap <= rdfifo_dataout[`C2A_RDFIFO_RDATA_H:`C2A_RDFIFO_RDATA_L];
                   end
            end // else: !if(areset_n == 1'b0)
     end // always @ (posedge clk)


endmodule // cbus_mstr_if


// Local Variables:
// verilog-library-directories:(".")
// End:
