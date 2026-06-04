//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2016-02-19 0130 naftalyb>
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

module cbus_slv_if (/*autoarg*/
   // Outputs
   cbus_m_address, cbus_m_align, cbus_m_amode, cbus_m_bytecnt,
   cbus_m_byten, cbus_m_clsize, cbus_m_cmd, cbus_m_first, cbus_m_last,
   cbus_m_mstid, cbus_m_req, cbus_m_wdata, cbus_m_xcnt, dwfifo_rd_op,
   cwfifo_rd_op, rdfifo_datain, rdfifo_wr_op,
   // Inputs
   aclk, areset_n, cbus_m_rdatap, cbus_m_rresp, cbus_m_waccept,
   dwfifo_empty, dwfifo_dataout, cwfifo_empty, cwfifo_dataout,
   rdfifo_empty, rdfifo_full, rdfifo_afull
   );
   
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input                       aclk;
   input                       areset_n;
   
   //----------------------------------------------------------------------------
   // CBUS I/F
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
   // Command & Data FIFO's
   //----------------------------------------------------------------------------
   input                       dwfifo_empty;
   output                      dwfifo_rd_op; 
   input [`A2C_DWFIFO_DW-1:0]  dwfifo_dataout;
   input                       cwfifo_empty;
   output                      cwfifo_rd_op; 
   input [`A2C_CWFIFO_DW-1:0]  cwfifo_dataout;
   input                       rdfifo_empty;
   input                       rdfifo_full;
   input                       rdfifo_afull;
   output [`A2C_RDFIFO_DW-1:0] rdfifo_datain;
   output                      rdfifo_wr_op;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   reg [1:0]                   cbus_slv_sm;
   reg                         cwfifo_rd_op; 
   reg                         rdfifo_wr_op;
   reg                         rdfifo_wr_op_last;
   reg [`A2C_LEN_BITS-1:0]     cbus_m_word_cntr;
   reg [`A2C_LEN_BITS-1:0]     cbus_m_word_count;//noytzach: for wrap_mask
   
   reg [31:0]                  cbus_m_address;
   reg [1:0]                   cbus_m_amode;
   reg [9:0]                   cbus_m_bytecnt;
   reg                         cbus_m_cmd;
   reg                         cbus_m_first;
   reg                         cbus_m_last;
   reg                         cbus_m_req;
   
   wire [3:0]                  cbus_m_byten;
   wire [4:0]                  cbus_m_align;
   wire [2:0]                  cbus_m_clsize;
   wire [7:0]                  cbus_m_mstid;
   wire [31:0]                 cbus_m_wdata;
   wire [2:0]                  cbus_m_xcnt;
   
   wire [9:0]                  cbus_cmd_bytecnt;
   
   wire                        sa_dwfifo_rd_op;
   wire                        sa_dwfifo_wr_op;
   reg                         dwfifo_rd_data_val;
   wire [31:0]                 wrap_mask;

   reg  [`A2C_ID_DW-1:0]       cmd_id;
   reg                         cmd_user;
   
   //----------------------------------------------------------------------------
   // CBUS SM enumration
   //----------------------------------------------------------------------------
   `define CBUS_SIDLE      2'b00
   `define CBUS_SWRITE     2'b01
   `define CBUS_SREAD      2'b10

   /*autoinput*/
   
   /*autoutputs*/
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 sa_dwfifo_afull;        // From I_sa_dwfifo of sc_fifo.v
   wire [`A2C_DWFIFO_DW-1:0] sa_dwfifo_dataout; // From I_sa_dwfifo of sc_fifo.v
   wire                 sa_dwfifo_empty;        // From I_sa_dwfifo of sc_fifo.v
   // End of automatics

   
  /*sc_fifo AUTO_TEMPLATE (
      .clk                              (aclk),
      .reset_n                          (areset_n),
      .dataout                          (sa_dwfifo_dataout[`A2C_DWFIFO_DW-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (sa_dwfifo_empty),
      .full                             (),
      .afull                            (sa_dwfifo_afull),
      .entry_used                       (),
      .datain                           (dwfifo_dataout[`A2C_DWFIFO_DW-1:0]),
      .wr_op                            (sa_dwfifo_wr_op),
      .rd_op                            (sa_dwfifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(`A2C_DWFIFO_DW), .PTRW(3), .AFTHRS_LSB(2'h2)) I_sa_dwfifo
     (/*autoinst*/
      // Outputs
      .dataout                          (sa_dwfifo_dataout[`A2C_DWFIFO_DW-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (sa_dwfifo_empty),       // Templated
      .full                             (),                      // Templated
      .afull                            (sa_dwfifo_afull),       // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (aclk),                  // Templated
      .reset_n                          (areset_n),              // Templated
      .datain                           (dwfifo_dataout[`A2C_DWFIFO_DW-1:0]), // Templated
      .wr_op                            (sa_dwfifo_wr_op),       // Templated
      .rd_op                            (sa_dwfifo_rd_op),       // Templated
      .clr_err                          (1'b0));                  // Templated
   

   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   assign                  cbus_m_align  = 5'h0;
   assign                  cbus_m_clsize = 3'h0;
   assign                  cbus_m_mstid  = 8'h0;
   assign                  cbus_m_wdata  = sa_dwfifo_dataout[`A2C_DWFIFO_WDATA_H:`A2C_DWFIFO_WDATA_L];
   assign                  cbus_m_xcnt[2:0]   = cbus_m_req ? {2'h0,sa_dwfifo_dataout[`A2C_DWFIFO_WSTRB_L+3]} + {2'h0,sa_dwfifo_dataout[`A2C_DWFIFO_WSTRB_L+2]} + {2'h0,sa_dwfifo_dataout[`A2C_DWFIFO_WSTRB_L+1]} + {2'h0,sa_dwfifo_dataout[`A2C_DWFIFO_WSTRB_L+0]} : 3'h0;
   assign                  cbus_cmd_bytecnt = {cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L], 2'b00} + cwfifo_dataout[`A2C_CWFIFO_WSTRB_L+3] + cwfifo_dataout[`A2C_CWFIFO_WSTRB_L+2] + cwfifo_dataout[`A2C_CWFIFO_WSTRB_L+1] + cwfifo_dataout[`A2C_CWFIFO_WSTRB_L+0];
   assign                  cbus_m_byten = cbus_m_cmd ? 4'b1111 : sa_dwfifo_dataout[`A2C_DWFIFO_WSTRB_H:`A2C_DWFIFO_WSTRB_L];

   //assign                  sa_dwfifo_wr_op = (dwfifo_rd_data_val == 1'b1);
   assign                  sa_dwfifo_wr_op = (dwfifo_rd_op == 1'b1);
   assign                  sa_dwfifo_rd_op = (cbus_m_req == 1'b1 && cbus_m_cmd == 1'b0 && cbus_m_waccept == 1'b1);

   assign                  dwfifo_rd_op    = (dwfifo_empty == 1'b0 && sa_dwfifo_afull == 1'b0);

   assign                  rdfifo_datain   = {cmd_user,cmd_id,rdfifo_wr_op_last, 2'b00, cbus_m_rdatap};

   assign                  wrap_mask       = {22'b0, cbus_m_word_count, 2'b11};
   
   always @(posedge aclk or negedge areset_n)
     begin
          if (areset_n == 1'b0) 
            begin
                 cbus_slv_sm <= `CBUS_SIDLE;
                 cwfifo_rd_op <= 1'b0;
                 rdfifo_wr_op <= 1'b0;
                 rdfifo_wr_op_last <= 1'b0;
                 cbus_m_address <= 32'h0;
                 cbus_m_amode <= 2'b00;
                 cbus_m_bytecnt <= 10'h0;
                 cbus_m_word_cntr <= {`A2C_LEN_BITS{1'b0}};
                 cbus_m_word_count <= {`A2C_LEN_BITS{1'b0}};
                 cbus_m_cmd <= 1'b0;
                 cbus_m_first <= 1'b0;
                 cbus_m_last <= 1'b0;
                 cbus_m_req <= 1'b0;
                 dwfifo_rd_data_val <= 1'b0;
                 cmd_id <= {`A2C_ID_DW{1'b0}};
                 cmd_user <= 1'b0;
            end
          else
            begin
                 // Default
                 cwfifo_rd_op <= 1'b0;
                 rdfifo_wr_op <= 1'b0;
                 rdfifo_wr_op_last <= 1'b0;
                 dwfifo_rd_data_val <= dwfifo_rd_op;

                 if (cbus_m_req == 1'b1 && cbus_m_cmd == 1'b1 && cbus_m_rresp == 1'b1)
                   begin
                        rdfifo_wr_op <= 1'b1;
                        rdfifo_wr_op_last <= cbus_m_last;
                   end

                 case (cbus_slv_sm[1:0])
                   `CBUS_SIDLE:
                     begin
                          if (cwfifo_empty == 1'b0)
                            begin
                                 //----------------------------------------------------------------------------
                                 // Command is write (we must make sure that the show-ahead FIFO has at least
                                 // one word!!)
                                 //----------------------------------------------------------------------------
                                 if     (cwfifo_dataout[`A2C_CWFIFO_RWN_C] == 1'b0 && sa_dwfifo_empty == 1'b0)
                                   begin
                                        cbus_slv_sm <= `CBUS_SWRITE;
                                        cbus_m_cmd <= 1'b0;
                                        cbus_m_req <= 1'b1;
                                        cbus_m_address <= cwfifo_dataout[`A2C_CWFIFO_ADDR_H:`A2C_CWFIFO_ADDR_L];
                                        cbus_m_bytecnt <= cbus_cmd_bytecnt;
                                        case (cwfifo_dataout[`A2C_CWFIFO_AXBRST_H:`A2C_CWFIFO_AXBRST_L])
                                          `A2C_FIXED:
                                            begin
                                               cbus_m_amode <= 2'b10;
                                            end
                                          `A2C_INCR:
                                            begin
                                               cbus_m_amode <= 2'b00;
                                            end
                                          `A2C_WRAP:
                                            begin
                                               cbus_m_amode <= 2'b11;
                                            end
                                          default:
                                            begin
                                               cbus_m_amode <= 2'b00;
                                            end
                                        endcase // case (cwfifo_dataout[`A2C_CWFIFO_AXBRST_H:`A2C_CWFIFO_AXBRST_L])
                                        cbus_m_first <= 1'b1;
                                        cbus_m_word_cntr <= cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L];
                                        cbus_m_word_count <= cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L];
                                        cwfifo_rd_op <= 1'b1;
                                        //----------------------------------------------------------------------------
                                        // If burst length equals to 1 (=AXILEN=), we generate "single" CBUS transaction
                                        //----------------------------------------------------------------------------
                                        if (cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L] == {`A2C_LEN_BITS{1'b0}})
                                          begin
                                               cbus_m_last <= 1'b1;
                                               cbus_m_amode <= 2'b00; // reduce to INCR because it is not a burst transaction anyways
                                          end
                                   end
                                 //----------------------------------------------------------------------------
                                 // Command is read
                                 //----------------------------------------------------------------------------
                                 else if (cwfifo_dataout[`A2C_CWFIFO_RWN_C] == 1'b1 && rdfifo_empty == 1'b1)
                                   begin
                                        cbus_slv_sm <= `CBUS_SREAD;
                                        cbus_m_cmd <= 1'b1;
                                        cbus_m_req <= 1'b1;
                                        cbus_m_address <= cwfifo_dataout[`A2C_CWFIFO_ADDR_H:`A2C_CWFIFO_ADDR_L];
                                        cbus_m_bytecnt <= cbus_cmd_bytecnt;
                                        case (cwfifo_dataout[`A2C_CWFIFO_AXBRST_H:`A2C_CWFIFO_AXBRST_L])
                                          `A2C_FIXED:
                                            begin
                                               cbus_m_amode <= 2'b10;
                                            end
                                          `A2C_INCR:
                                            begin
                                               cbus_m_amode <= 2'b00;
                                            end
                                          `A2C_WRAP:
                                            begin
                                               cbus_m_amode <= 2'b11;
                                            end
                                          default:
                                            begin
                                               cbus_m_amode <= 2'b00;
                                            end
                                        endcase // case (cwfifo_dataout[`A2C_CWFIFO_AXBRST_H:`A2C_CWFIFO_AXBRST_L])
                                        cbus_m_first <= 1'b1;
                                        cbus_m_word_cntr <= cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L];
                                        cbus_m_word_count <= cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L];
                                        cwfifo_rd_op <= 1'b1;
                                        //----------------------------------------------------------------------------
                                        // If burst length equals to 1 (=AXILEN=), we generate "single" CBUS transaction
                                        // (first=last=1)
                                        //----------------------------------------------------------------------------
                                        if (cwfifo_dataout[`A2C_CWFIFO_AXLEN_H:`A2C_CWFIFO_AXLEN_L] == {`A2C_LEN_BITS{1'b0}})
                                          begin
                                               cbus_m_last <= 1'b1;
                                               cbus_m_amode <= 2'b00; // reduce to INCR because it is not a burst transaction anyways
                                          end
                                        cmd_id <= cwfifo_dataout[`A2C_CWFIFO_ID_H:`A2C_CWFIFO_ID_L];
                                        cmd_user <= cwfifo_dataout[`A2C_CWFIFO_USER_C];
                                   end
                            end
                     end
                   `CBUS_SWRITE:
                     begin
                          if (cbus_m_waccept == 1'b1)
                            begin
                                 //----------------------------------------------------------------------------
                                 // When we reach the burst word, we assert "cbus_m_last". On the follow cycle
                                 // the CBUS transaction is terminated by de-asserting "cbus_m_req"
                                 //----------------------------------------------------------------------------
                                 if (cbus_m_word_cntr > {`A2C_LEN_BITS{1'b0}})
                                   begin
                                        //----------------------------------------------------------------------------
                                        // When "cbus_m_amode" is asserted the address will be wrapped on cbus_m_word_count*4
                                        //  boundaries, AxSize is assumed to be fixed (4B).
                                        //----------------------------------------------------------------------------
                                        case (cbus_m_amode[1:0])
                                          2'b00:
                                            begin
                                               cbus_m_address <= cbus_m_address + 32'h4;
                                            end
                                          2'b10:
                                            begin
                                               cbus_m_address <= cbus_m_address;
                                            end
                                          2'b11:
                                            begin
                                               cbus_m_address <= 
                                                    wrap_mask  & (cbus_m_address + 32'h4) |
                                                   ~wrap_mask  & (cbus_m_address);
                                            end
                                          default:
                                            begin
                                               cbus_m_address <= cbus_m_address + 32'h4;
                                            end
                                        endcase // case (cbus_m_amode[1:0])
                                        cbus_m_first <= 1'b0;
                                        cbus_m_bytecnt <= cbus_m_bytecnt - 10'h4;
                                        cbus_m_word_cntr <= cbus_m_word_cntr - {{(`A2C_LEN_BITS-1){1'b0}}, 1'b1};
                                        if (cbus_m_word_cntr == {{(`A2C_LEN_BITS-1){1'b0}}, 1'b1})
                                          begin
                                               cbus_m_last <= 1'b1;
                                          end
                                   end
                                 else
                                   begin
                                        cbus_m_req <= 1'b0;
                                        cbus_m_first <= 1'b0;
                                        cbus_m_last <= 1'b0;
                                        cbus_m_cmd <= 1'b0;
                                        cbus_m_address <= 32'h0;
                                        cbus_m_bytecnt <= 10'h0;
                                        cbus_m_amode <= 2'b00;
                                        cbus_slv_sm <= `CBUS_SIDLE;
                                   end
                            end
                     end
                   `CBUS_SREAD:
                     begin
                          if (cbus_m_rresp == 1'b1)
                            begin
                                 //----------------------------------------------------------------------------
                                 // When we reach the burst word, we assert "cbus_m_last". On the follow cycle
                                 // the CBUS transaction is terminated by de-asserting "cbus_m_req"
                                 //----------------------------------------------------------------------------
                                 if (cbus_m_word_cntr > {`A2C_LEN_BITS{1'b0}})
                                   begin
                                        //----------------------------------------------------------------------------
                                        // When "cbus_m_amode" is asserted the address will be wrapped on cbus_m_word_count*4
                                        //  boundaries, AxSize is assumed to be fixed (4B).
                                        //----------------------------------------------------------------------------
                                        case (cbus_m_amode[1:0])
                                          2'b00:
                                            begin
                                               cbus_m_address <= cbus_m_address + 32'h4;
                                            end
                                          2'b10:
                                            begin
                                               cbus_m_address <= cbus_m_address;
                                            end
                                          2'b11:
                                            begin
                                               cbus_m_address <= 
                                                    wrap_mask  & (cbus_m_address + 32'h4) |
                                                   ~wrap_mask  & (cbus_m_address);
                                            end
                                          default:
                                            begin
                                               cbus_m_address <= cbus_m_address + 32'h4;
                                            end
                                        endcase // case (cbus_m_amode[1:0])
                                        cbus_m_first <= 1'b0;
                                        cbus_m_bytecnt <= cbus_m_bytecnt - 10'h4;
                                        cbus_m_word_cntr <= cbus_m_word_cntr - {{(`A2C_LEN_BITS-1){1'b0}}, 1'b1};
                                        if (cbus_m_word_cntr == {{(`A2C_LEN_BITS-1){1'b0}}, 1'b1})
                                          begin
                                               cbus_m_last <= 1'b1;
                                          end
                                   end
                                 else
                                   begin
                                        cbus_m_req <= 1'b0;
                                        cbus_m_first <= 1'b0;
                                        cbus_m_last <= 1'b0;
                                        cbus_m_cmd <= 1'b0;
                                        cbus_m_address <= 32'h0;
                                        cbus_m_bytecnt <= 10'h0;
                                        cbus_m_amode <= 2'b00;
                                        cbus_slv_sm <= `CBUS_SIDLE;
                                   end
                            end
                     end
                   default:
                     begin
                     end
                 endcase // case(cbus_slv_sm[1:0])
            end // always @ (posedge clk)
     end // always @ (posedge aclk)
   
endmodule // cbus_slv_if


// Local Variables:
// verilog-library-directories:("." "$NEGEV_IP/design/crgn/soc_building_blocks/hdl")
// End:
