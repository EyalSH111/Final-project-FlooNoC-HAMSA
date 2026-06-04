//-----------------------------------------------------------------------------
// Title         : SRAM OCP I/F
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : 
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2016-03-01 1600 naftalyb>
//-----------------------------------------------------------------------------
// Description :
// SRAM OCP I/F;
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 3.4.2015 : created
//------------------------------------------------------------------------------

module sram_ocp_if (/*autoarg*/
   // Outputs
   sram_ocp_scmdaccept_i, sram_ocp_sdataaccept_i, sram_ocp_sresp_i,
   sram_ocp_sdata_i, sram_ocp_sresplast_i, ram_addr, ram_wr_en,
   ram_en, ram_wr_mask, ram_wdata,
   // Inputs
   sram_ocp_clk, sram_ocp_mreset_no, sram_ocp_mcmd_o,
   sram_ocp_maddr_o, sram_ocp_mbyteen_o, sram_ocp_mburstlength_o,
   sram_ocp_mburstseq_o, sram_ocp_mdata_o, sram_ocp_mdatavalid_o,
   sram_ocp_mdatabyteen_o, sram_ocp_mrespaccept_o, ram_rdata
   );
   
   //----------------------------------------------------------------------------
   // Parameters
   //----------------------------------------------------------------------------
   parameter  ADDRW      = 24;
   parameter  BURSTLEN   = 8;
   parameter  DATAW      = 32;
   parameter  PIPE_READ  = 0;

   localparam BYTEEN     = DATAW/8;
   localparam BYTEEN_LOG = $clog2(BYTEEN);
   localparam RAM_ADDRW  = ADDRW-BYTEEN_LOG;
   
   //----------------------------------------------------------------------------
   // Wrap bursts mask
   //----------------------------------------------------------------------------
   localparam WBURST4_MASK =   {{(ADDRW-BYTEEN_LOG-2){1'b1}}, 2'b00};
   localparam WBURST4_MASK_N = {{(ADDRW-BYTEEN_LOG-2){1'b0}}, 2'b11};
   
   //----------------------------------------------------------------------------
   // SRAM OCP I/F
   //----------------------------------------------------------------------------
   input                  sram_ocp_clk;
   input                  sram_ocp_mreset_no;
   input [2:0]            sram_ocp_mcmd_o;
   input [ADDRW-1:0]      sram_ocp_maddr_o;
   input [BYTEEN-1:0]     sram_ocp_mbyteen_o;
   input [BURSTLEN-1:0]   sram_ocp_mburstlength_o;
   input [2:0]            sram_ocp_mburstseq_o;
   output                 sram_ocp_scmdaccept_i;
   input [DATAW-1:0]      sram_ocp_mdata_o;
   input                  sram_ocp_mdatavalid_o;
   input [BYTEEN-1:0]     sram_ocp_mdatabyteen_o;
   output                 sram_ocp_sdataaccept_i;
   output [1:0]           sram_ocp_sresp_i;
   output [DATAW-1:0]     sram_ocp_sdata_i;
   output                 sram_ocp_sresplast_i;
   input                  sram_ocp_mrespaccept_o;
   
   //----------------------------------------------------------------------------
   // SRAM I/F
   //----------------------------------------------------------------------------
   output [RAM_ADDRW-1:0] ram_addr;
   output                 ram_wr_en;
   output                 ram_en;
   output [BYTEEN-1:0]    ram_wr_mask;
   output [DATAW-1:0]     ram_wdata;
   input [DATAW-1:0]      ram_rdata;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   reg [2:0]              sram_ocp_sm;
   reg [BURSTLEN-1:0]     mburstlen_cntr;
   
   reg [RAM_ADDRW-1:0]    ram_addr;
   reg                    ram_wr_en;
   reg                    ram_en;
   reg                    ram_en_last;
   reg [BYTEEN-1:0]       ram_wr_mask;

   wire [DATAW-1:0]       ram_rdata;
   reg [DATAW-1:0]        ram_wdata;

   reg                    ram_rd_data_valid_s0;
   reg                    ram_rd_data_last_s0;
   
   reg [1:0]              ocp_sresp_i;
   reg                    ocp_sresplast_i;

   reg                    ocp_if_ena;
   
   wire                   rd_fifo_rd_op;
   wire                   rd_fifo_wr_op;
   wire [DATAW:0]         rd_fifo_din;
   
   wire                   cmd_fifo_rd_op;
   wire                   cmd_fifo_wr_op;
   wire [ADDRW+BURSTLEN+5:0] cmd_fifo_din;

   wire                   wr_fifo_rd_op;
   wire                   wr_fifo_wr_op;
   wire [DATAW+BYTEEN-1:0] wr_fifo_din;
      
   wire [2:0]             cmd_fifo_mem_ocp_mburstseq_o;
   wire [BURSTLEN-1:0]    cmd_fifo_mem_ocp_mburstlength_o;
   wire [2:0]             cmd_fifo_mem_ocp_mcmd_o;
   wire [ADDRW-1:0]       cmd_fifo_mem_ocp_maddr_o;
   
   wire [DATAW-1:0]       wr_fifo_mem_ocp_mdata_o;
   wire [BYTEEN-1:0]      wr_fifo_mem_ocp_mdatabyteen_o;

   //----------------------------------------------------------------------------
   // SM States
   //----------------------------------------------------------------------------
   `define SRAM_SM_IDLE       3'b000
   `define SRAM_SM_INCRR      3'b001
   `define SRAM_SM_INCRW      3'b010
   `define SRAM_SM_WRAPR      3'b011
   `define SRAM_SM_WRAPW      3'b100
  
   //----------------------------------------------------------------------------
   // OCP Commands encoding
   //----------------------------------------------------------------------------
   `define IDLE              3'b000
   `define READ              3'b010
   `define WRITE             3'b001

   //----------------------------------------------------------------------------
   // OCP Burst type encoding
   //----------------------------------------------------------------------------
   `define BTINCR            3'b000
   `define BTWRAP            3'b010

   //----------------------------------------------------------------------------
   // Response signaling
   //----------------------------------------------------------------------------
   `define DVA               2'b01
   
   /*autoinput*/
   
   /*autoutputs*/
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 cmd_fifo_afull;         // From I_cmd_sc_fifo of sc_fifo.v
   wire [ADDRW+BURSTLEN+5:0] cmd_fifo_dout;     // From I_cmd_sc_fifo of sc_fifo.v
   wire                 cmd_fifo_empy;          // From I_cmd_sc_fifo of sc_fifo.v
   wire                 rd_fifo_afull;          // From I_rd_sc_fifo of sc_fifo.v, ...
   wire [DATAW:0]       rd_fifo_dout;           // From I_rd_sc_fifo of sc_fifo.v, ...
   wire                 rd_fifo_empy;           // From I_rd_sc_fifo of sc_fifo.v, ...
   wire                 wr_fifo_afull;          // From I_wr_sc_fifo of sc_fifo.v
   wire [DATAW+BYTEEN-1:0] wr_fifo_dout;        // From I_wr_sc_fifo of sc_fifo.v
   wire                 wr_fifo_empy;           // From I_wr_sc_fifo of sc_fifo.v
   // End of automatics

   

   generate
   //----------------------------------------------------------------------------
   // If "PIPE_READ" is 1, we set the AF threshold to 3 instead of 2 due the fact
   // that the "breaking distance" is increasing when rd latency is higher.
   //----------------------------------------------------------------------------
   if (PIPE_READ == 0) begin : pipe_read_rd_sc_fifo_false
   /*sc_fifo AUTO_TEMPLATE (
      .dataout                          (rd_fifo_dout[DATAW:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (rd_fifo_empy),
      .full                             (),
      .afull                            (rd_fifo_afull),
      .entry_used                       (),
      // Inputs
      .clk                              (sram_ocp_clk),
      .reset_n                          (sram_ocp_mreset_no),
      .datain                           (rd_fifo_din[DATAW:0]),
      .wr_op                            (rd_fifo_wr_op),
      .rd_op                            (rd_fifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(DATAW+1), .PTRW(3), .AFTHRS_LSB(2'h2)) I_rd_sc_fifo
     (/*autoinst*/
      // Outputs
      .dataout                          (rd_fifo_dout[DATAW:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (rd_fifo_empy),          // Templated
      .full                             (),                      // Templated
      .afull                            (rd_fifo_afull),         // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (sram_ocp_clk),          // Templated
      .reset_n                          (sram_ocp_mreset_no),    // Templated
      .datain                           (rd_fifo_din[DATAW:0]),  // Templated
      .wr_op                            (rd_fifo_wr_op),         // Templated
      .rd_op                            (rd_fifo_rd_op),         // Templated
      .clr_err                          (1'b0));                  // Templated
   end
   else begin : pipe_read_rd_sc_fifo_true
   /*sc_fifo AUTO_TEMPLATE (
      .dataout                          (rd_fifo_dout[DATAW:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (rd_fifo_empy),
      .full                             (),
      .afull                            (rd_fifo_afull),
      .entry_used                       (),
      // Inputs
      .clk                              (sram_ocp_clk),
      .reset_n                          (sram_ocp_mreset_no),
      .datain                           (rd_fifo_din[DATAW:0]),
      .wr_op                            (rd_fifo_wr_op),
      .rd_op                            (rd_fifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(DATAW+1), .PTRW(3), .AFTHRS_LSB(2'h3)) I_rd_sc_fifo
     (/*autoinst*/
      // Outputs
      .dataout                          (rd_fifo_dout[DATAW:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (rd_fifo_empy),          // Templated
      .full                             (),                      // Templated
      .afull                            (rd_fifo_afull),         // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (sram_ocp_clk),          // Templated
      .reset_n                          (sram_ocp_mreset_no),    // Templated
      .datain                           (rd_fifo_din[DATAW:0]),  // Templated
      .wr_op                            (rd_fifo_wr_op),         // Templated
      .rd_op                            (rd_fifo_rd_op),         // Templated
      .clr_err                          (1'b0));                  // Templated
   end
   endgenerate
   
   /*sc_fifo AUTO_TEMPLATE (
      .dataout                          (cmd_fifo_dout[ADDRW+BURSTLEN+5:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (cmd_fifo_empy),
      .full                             (),
      .afull                            (cmd_fifo_afull),
      .entry_used                       (),
      // Inputs
      .clk                              (sram_ocp_clk),
      .reset_n                          (sram_ocp_mreset_no),
      .datain                           (cmd_fifo_din[ADDRW+BURSTLEN+5:0]),
      .wr_op                            (cmd_fifo_wr_op),
      .rd_op                            (cmd_fifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(ADDRW+BURSTLEN+6), .PTRW(2), .AFTHRS_LSB(2'h1)) I_cmd_sc_fifo
     (/*autoinst*/
      // Outputs
      .dataout                          (cmd_fifo_dout[ADDRW+BURSTLEN+5:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (cmd_fifo_empy),         // Templated
      .full                             (),                      // Templated
      .afull                            (cmd_fifo_afull),        // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (sram_ocp_clk),          // Templated
      .reset_n                          (sram_ocp_mreset_no),    // Templated
      .datain                           (cmd_fifo_din[ADDRW+BURSTLEN+5:0]), // Templated
      .wr_op                            (cmd_fifo_wr_op),        // Templated
      .rd_op                            (cmd_fifo_rd_op),        // Templated
      .clr_err                          (1'b0));                  // Templated

   /*sc_fifo AUTO_TEMPLATE (
      .dataout                          (wr_fifo_dout[DATAW+BYTEEN-1:0]),
      .wr_full_err                      (),
      .rd_empty_err                     (),
      .empty                            (wr_fifo_empy),
      .full                             (),
      .afull                            (wr_fifo_afull),
      .entry_used                       (),
      // Inputs
      .clk                              (sram_ocp_clk),
      .reset_n                          (sram_ocp_mreset_no),
      .datain                           (wr_fifo_din[DATAW+BYTEEN-1:0]),
      .wr_op                            (wr_fifo_wr_op),
      .rd_op                            (wr_fifo_rd_op),
      .clr_err                          (1'b0),
     ); */
   sc_fifo #(.DW(DATAW+BYTEEN), .PTRW(2), .AFTHRS_LSB(2'h1)) I_wr_sc_fifo
     (/*autoinst*/
      // Outputs
      .dataout                          (wr_fifo_dout[DATAW+BYTEEN-1:0]), // Templated
      .wr_full_err                      (),                      // Templated
      .rd_empty_err                     (),                      // Templated
      .empty                            (wr_fifo_empy),          // Templated
      .full                             (),                      // Templated
      .afull                            (wr_fifo_afull),         // Templated
      .entry_used                       (),                      // Templated
      // Inputs
      .clk                              (sram_ocp_clk),          // Templated
      .reset_n                          (sram_ocp_mreset_no),    // Templated
      .datain                           (wr_fifo_din[DATAW+BYTEEN-1:0]), // Templated
      .wr_op                            (wr_fifo_wr_op),         // Templated
      .rd_op                            (wr_fifo_rd_op),         // Templated
      .clr_err                          (1'b0));                  // Templated

   //----------------------------------------------------------------------------
   // Since the the ram has read latency of one, and the OPC MRespAccept need to
   // be honored on the same cycles it de-assert (master ask slave to stop sending
   // data), the extracted ram data is written into shallow show-ahead FIFO.
   // The read-side of the FIFO is acknoledge when the FIFO is not empty
   // and MRespAccept is high.
   //----------------------------------------------------------------------------
   assign     rd_fifo_rd_op = (rd_fifo_empy == 1'b0) && (sram_ocp_mrespaccept_o == 1'b1);

   generate
   //----------------------------------------------------------------------------
   // If "PIPE_READ" <> 0, the "ram_rdata" is valid after two cycles, therfore
   // addtional delay cycle is added to both "ram_rd_data_last" and "ram_rd_data_valid"
   //----------------------------------------------------------------------------
   if (PIPE_READ == 0) begin : pipe_read_rd_fifo_wr_op_false
        assign     rd_fifo_din   = {ram_rd_data_last_s0, ram_rdata};
        assign     rd_fifo_wr_op = ram_rd_data_valid_s0;
   end
   else begin : pipe_read_rd_fifo_wr_op_true

      reg ram_rd_data_valid_s1;
      reg ram_rd_data_last_s1;

        always @(posedge sram_ocp_clk or negedge sram_ocp_mreset_no)
          begin
               if (sram_ocp_mreset_no == 1'b0) 
                 begin
                      ram_rd_data_valid_s1 <= 1'b0;
                      ram_rd_data_last_s1 <= 1'b0;
                 end
               else
                 begin
                      ram_rd_data_valid_s1 <= ram_rd_data_valid_s0;
                      ram_rd_data_last_s1 <= ram_rd_data_last_s0;
                 end
          end // always @ (posedge sram_ocp_clk or negedge sram_ocp_mreset_no)
        assign     rd_fifo_din   = {ram_rd_data_last_s1, ram_rdata};
        assign     rd_fifo_wr_op = ram_rd_data_valid_s1;
   end
   endgenerate
   
   
   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   
   assign     sram_ocp_sdata_i       = rd_fifo_dout[DATAW-1:0];
   assign     sram_ocp_scmdaccept_i  = ~cmd_fifo_afull & ocp_if_ena;
   assign     sram_ocp_sdataaccept_i = ~wr_fifo_afull & ocp_if_ena;
   assign     sram_ocp_sresplast_i   = rd_fifo_dout[DATAW];
   assign     sram_ocp_sresp_i       = rd_fifo_rd_op ? `DVA : 2'b00;
   
   assign     cmd_fifo_rd_op = (sram_ocp_sm[2:0] == `SRAM_SM_IDLE) & ((cmd_fifo_mem_ocp_mcmd_o == `WRITE & cmd_fifo_empy == 1'b0 & wr_fifo_empy == 1'b0) | (cmd_fifo_mem_ocp_mcmd_o == `READ & cmd_fifo_empy == 1'b0));
   assign     cmd_fifo_wr_op = (sram_ocp_mcmd_o == `WRITE | sram_ocp_mcmd_o == `READ) & (sram_ocp_scmdaccept_i == 1'b1);
   assign     cmd_fifo_din   = {sram_ocp_mburstseq_o, sram_ocp_mburstlength_o, sram_ocp_mcmd_o, sram_ocp_maddr_o};
   
   assign     wr_fifo_rd_op  = ((sram_ocp_sm[2:0] == `SRAM_SM_INCRW | sram_ocp_sm[2:0] == `SRAM_SM_WRAPW) & (wr_fifo_empy == 1'b0) & ~(mburstlen_cntr == {{(BURSTLEN-1){1'b0}}, 1'b1})) | ((sram_ocp_sm[2:0] == `SRAM_SM_IDLE) & (cmd_fifo_mem_ocp_mcmd_o == `WRITE & cmd_fifo_empy == 1'b0 & wr_fifo_empy == 1'b0));
   assign     wr_fifo_wr_op  = (sram_ocp_mdatavalid_o == 1'b1) & (sram_ocp_sdataaccept_i == 1'b1);
   assign     wr_fifo_din    = {sram_ocp_mdatabyteen_o, sram_ocp_mdata_o};

   assign     cmd_fifo_mem_ocp_mburstseq_o    = cmd_fifo_dout[ADDRW+BURSTLEN+5:ADDRW+BURSTLEN+3];
   assign     cmd_fifo_mem_ocp_mburstlength_o = cmd_fifo_dout[ADDRW+BURSTLEN+2:ADDRW+3];
   assign     cmd_fifo_mem_ocp_mcmd_o         = cmd_fifo_dout[ADDRW+2:ADDRW];
   assign     cmd_fifo_mem_ocp_maddr_o        = cmd_fifo_dout[ADDRW-1:0];
   
   assign     wr_fifo_mem_ocp_mdatabyteen_o   = wr_fifo_dout[DATAW+BYTEEN-1:DATAW];
   assign     wr_fifo_mem_ocp_mdata_o         = wr_fifo_dout[DATAW-1:0];
   
     
   //synopsys translate_off
   generate
        if (DATAW == 32) begin : check_wrap_dw32
             check_wrap_write_size_is_4 : assert property (@(posedge sram_ocp_clk) ((sram_ocp_sm[2:0] == `SRAM_SM_IDLE && sram_ocp_mcmd_o == `WRITE && sram_ocp_mdatavalid_o == 1'b1 && sram_ocp_mburstseq_o == `BTWRAP) 
                                                                                      |=> (sram_ocp_mburstlength_o == {{(BURSTLEN-BYTEEN_LOG-1){1'b0}}, 3'b100}))) else $fatal(2);
             check_wrap_read_size_is_4 : assert property (@(posedge sram_ocp_clk) ((sram_ocp_sm[2:0] == `SRAM_SM_IDLE && sram_ocp_mcmd_o == `READ && sram_ocp_mburstseq_o == `BTWRAP) 
                                                                                      |=> (sram_ocp_mburstlength_o == {{(BURSTLEN-BYTEEN_LOG-1){1'b0}}, 3'b100}))) else $fatal(2);
        end // block: dw32
        else if (DATAW == 64) begin : check_wrap_dw32_dw64
             check_wrap_write_size_is_4 : assert property (@(posedge sram_ocp_clk) ((sram_ocp_sm[2:0] == `SRAM_SM_IDLE && sram_ocp_mcmd_o == `WRITE && sram_ocp_mdatavalid_o == 1'b1 && sram_ocp_mburstseq_o == `BTWRAP) 
                                                                                      |=> (sram_ocp_mburstlength_o == {{(BURSTLEN-BYTEEN_LOG-1){1'b0}}, 3'b010}))) else $fatal(2);
             check_wrap_read_size_is_4 : assert property (@(posedge sram_ocp_clk) ((sram_ocp_sm[2:0] == `SRAM_SM_IDLE && sram_ocp_mcmd_o == `READ && sram_ocp_mburstseq_o == `BTWRAP) 
                                                                                      |=> (sram_ocp_mburstlength_o == {{(BURSTLEN-BYTEEN_LOG-1){1'b0}}, 3'b010}))) else $fatal(2);
        end
   endgenerate
   //synopsys translate_on

   always @(posedge sram_ocp_clk or negedge sram_ocp_mreset_no)
     begin
          if (sram_ocp_mreset_no == 1'b0) 
            begin
                 sram_ocp_sm <= `SRAM_SM_IDLE;
                 ram_addr <= {RAM_ADDRW{1'b0}};
                 ram_wr_en <= 1'b0;
                 ram_en <= 1'b0;
                 ram_en_last <= 1'b0;
                 ram_wr_mask <= {BYTEEN{1'b0}};
                 ram_wdata <= {DATAW{1'b0}};
                 mburstlen_cntr <= {BURSTLEN{1'b0}};
                 ocp_sresp_i <= 2'h0;
                 ocp_sresplast_i <= 1'b0;
                 ram_rd_data_valid_s0 <= 1'b0;
                 ram_rd_data_last_s0 <= 1'b0;
                 ocp_if_ena <= 1'b0;
            end
          else
            begin
                 // Default
                 ram_wr_en <= 1'b0;
                 ram_en <= 1'b0;
                 ram_en_last <= 1'b0;
                 ram_wr_mask <= {BYTEEN{1'b0}};
                 ram_wdata <= {DATAW{1'b0}};
                 ram_rd_data_last_s0 <= ram_en_last;
                 ocp_if_ena <= 1'b1;
                 //----------------------------------------------------------------------------
                 // "ram_rd_data_valid_s0" indicates the read-data from the ram is valid
                 // It will be asserted when ram is read (en=1/wr_en=0).
                 //----------------------------------------------------------------------------
                 if (ram_en == 1'b1 && ram_wr_en == 1'b0)
                   begin
                        ram_rd_data_valid_s0 <= 1'b1;
                   end
                 else
                   begin
                        ram_rd_data_valid_s0 <= 1'b0;
                   end
                 
                 case (sram_ocp_sm[2:0])
                   `SRAM_SM_IDLE:
                     begin
                          //----------------------------------------------------------------------------
                          // If the pending command in the FIFO is write and both CMD and WR FIFO's
                          // are not empty (which means that we have the corresponding write command data ready), 
                          // we start a write transaction.
                          //----------------------------------------------------------------------------
                          if      (cmd_fifo_mem_ocp_mcmd_o == `WRITE && cmd_fifo_empy == 1'b0 && wr_fifo_empy == 1'b0)
                            begin
                                 ram_addr <= cmd_fifo_mem_ocp_maddr_o[(ADDRW-1):BYTEEN_LOG];
                                 ram_wr_en <= 1'b1;
                                 ram_en <= 1'b1;
                                 ram_wr_mask <= wr_fifo_mem_ocp_mdatabyteen_o;
                                 ram_wdata <= wr_fifo_mem_ocp_mdata_o;
                                 mburstlen_cntr <= cmd_fifo_mem_ocp_mburstlength_o;
                                 //----------------------------------------------------------------------------
                                 // Select between INCR and WRAP burst transactions
                                 //----------------------------------------------------------------------------
                                 if      (cmd_fifo_mem_ocp_mburstseq_o == `BTINCR) //`BTINCR
                                   begin
                                        sram_ocp_sm <= `SRAM_SM_INCRW;
                                   end
                                 else if (cmd_fifo_mem_ocp_mburstseq_o == `BTWRAP) //`BTWRAP
                                   begin
                                        sram_ocp_sm <= `SRAM_SM_WRAPW;
                                   end
                            end // if (sram_ocp_mcmd_o == `WRITE)
                          //----------------------------------------------------------------------------
                          // If the pending command in the FIFO is read, and the CMD FIFO is not empty,
                          // we start a read transaction.
                          //----------------------------------------------------------------------------
                          else if (cmd_fifo_mem_ocp_mcmd_o == `READ && cmd_fifo_empy == 1'b0)
                            begin
                                 ram_addr <= cmd_fifo_mem_ocp_maddr_o[(ADDRW-1):BYTEEN_LOG];
                                 ram_wr_en <= 1'b0;
                                 ram_en <= 1'b1;
                                 ram_wr_mask <= wr_fifo_mem_ocp_mdatabyteen_o;
                                 ram_wdata <= wr_fifo_mem_ocp_mdata_o;
                                 mburstlen_cntr <= cmd_fifo_mem_ocp_mburstlength_o;
                                 //----------------------------------------------------------------------------
                                 // Select between INCR and WRAP burst transactions
                                 //----------------------------------------------------------------------------
                                 if (cmd_fifo_mem_ocp_mburstlength_o == {{(BURSTLEN-1){1'b0}}, 1'b1})
                                   begin
                                        ram_en_last <= 1'b1;
                                   end
                                 if      (cmd_fifo_mem_ocp_mburstseq_o == `BTINCR) //`BTINCR
                                   begin
                                        sram_ocp_sm <= `SRAM_SM_INCRR;
                                   end
                                 else if (cmd_fifo_mem_ocp_mburstseq_o == `BTWRAP) //`BTWRAP
                                   begin
                                        sram_ocp_sm <= `SRAM_SM_WRAPR;
                                   end
                            end // if (sram_ocp_mcmd_o == `READ)
                     end
                   `SRAM_SM_INCRR:
                     begin
                          //----------------------------------------------------------------------------
                          // INCR burst read. Ram is keep exterted when the rd_fifo has at-least
                          // one free space (rd_fifo_afull=0). 
                          //----------------------------------------------------------------------------
                          if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b0)
                            begin
                                 ram_addr <= ram_addr + {{(ADDRW-1){1'b0}}, 1'b1};
                                 ram_wr_en <= 1'b0;
                                 ram_en <= 1'b1;
                                 mburstlen_cntr <= mburstlen_cntr - {{(BURSTLEN-1){1'b0}}, 1'b1};
                                 if (mburstlen_cntr == {{(BURSTLEN-2){1'b0}}, 2'b10})
                                   begin
                                        ram_en_last <= 1'b1;
                                   end
                            end // if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b0)
                          else if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b1)
                            begin
                                 ram_addr <= ram_addr;
                                 ram_wr_en <= 1'b0;
                                 ram_en <= 1'b1;
                                 mburstlen_cntr <= mburstlen_cntr;
                            end // if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b1)
                          else if (mburstlen_cntr == {{(BURSTLEN-1){1'b0}}, 1'b1})
                            begin
                                 sram_ocp_sm <= `SRAM_SM_IDLE;
                                 mburstlen_cntr <= {BURSTLEN{1'b0}};
                            end
                     end
                   `SRAM_SM_INCRW:
                     begin
                          //----------------------------------------------------------------------------
                          // INCR burst write. Ram is keep writing only when the when the WR FIFO has valid
                          // data for writing (wr_fifo_empy=0=FIFO not empty).
                          //----------------------------------------------------------------------------
                          if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && wr_fifo_empy == 1'b0)
                            begin
                                 ram_addr <= ram_addr + {{(ADDRW-1){1'b0}}, 1'b1};
                                 ram_wr_en <= 1'b1;
                                 ram_en <= 1'b1;
                                 ram_wr_mask <= wr_fifo_mem_ocp_mdatabyteen_o;
                                 ram_wdata <= wr_fifo_mem_ocp_mdata_o;
                                 mburstlen_cntr <= mburstlen_cntr - {{(BURSTLEN-1){1'b0}}, 1'b1};
                            end // if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && wr_fifo_empy == 1'b0)
                          else if (mburstlen_cntr == {{(BURSTLEN-1){1'b0}}, 1'b1})
                            begin
                                 sram_ocp_sm <= `SRAM_SM_IDLE;
                                 mburstlen_cntr <= {BURSTLEN{1'b0}};
                            end
                     end
                   `SRAM_SM_WRAPR:
                     begin
                          //----------------------------------------------------------------------------
                          // WRAP burst read. Ram is keep exterted when the rd_fifo has at-least
                          // one free space (rd_fifo_afull=0). The address will be wrapped around
                          // the boundries of 4 addresses.
                          //----------------------------------------------------------------------------
                          if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b0)
                            begin
                                 if ((WBURST4_MASK_N & ram_addr[(BURSTLEN-1):0]) == {{(BURSTLEN-2){1'b0}}, 2'b11})
                                   ram_addr <= WBURST4_MASK & ram_addr;
                                 else
                                   ram_addr <= ram_addr + {{(ADDRW-1){1'b0}}, 1'b1};

                                 ram_wr_en <= 1'b0;
                                 ram_en <= 1'b1;
                                 mburstlen_cntr <= mburstlen_cntr - {{(BURSTLEN-1){1'b0}}, 1'b1};
                                 if (mburstlen_cntr == {{(BURSTLEN-2){1'b0}}, 2'b10})
                                   begin
                                        ram_en_last <= 1'b1;
                                   end
                            end // if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b0)
                          else if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b1)
                            begin
                                 ram_addr <= ram_addr;
                                 ram_wr_en <= 1'b0;
                                 ram_en <= 1'b1;
                                 mburstlen_cntr <= mburstlen_cntr;
                            end // if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && rd_fifo_afull == 1'b1)
                          else if (mburstlen_cntr == {{(BURSTLEN-1){1'b0}}, 1'b1})
                            begin
                                 sram_ocp_sm <= `SRAM_SM_IDLE;
                                 mburstlen_cntr <= {BURSTLEN{1'b0}};
                            end
                     end
                   `SRAM_SM_WRAPW:
                     begin
                          //----------------------------------------------------------------------------
                          // WRAP burst write. Ram is keep writing only when the when the WR FIFO has valid
                          // data for writing (wr_fifo_empy=0=FIFO not empty). The address will be 
                          // wrapped around the boundries of 4 addresses.
                          //----------------------------------------------------------------------------
                          if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && wr_fifo_empy == 1'b0)
                            begin
                                 if ((WBURST4_MASK_N & ram_addr[(BURSTLEN-1):0]) == {{(BURSTLEN-2){1'b0}}, 2'b11})
                                   ram_addr <= WBURST4_MASK & ram_addr;
                                 else
                                   ram_addr <= ram_addr + {{(ADDRW-1){1'b0}}, 1'b1};

                                 ram_wr_en <= 1'b1;
                                 ram_en <= 1'b1;
                                 ram_wr_mask <= wr_fifo_mem_ocp_mdatabyteen_o;
                                 ram_wdata <= wr_fifo_mem_ocp_mdata_o;
                                 mburstlen_cntr <= mburstlen_cntr - {{(BURSTLEN-1){1'b0}}, 1'b1};
                            end // if (mburstlen_cntr > {{(BURSTLEN-1){1'b0}}, 1'b1} && wr_fifo_empy == 1'b0)
                          else if (mburstlen_cntr == {{(BURSTLEN-1){1'b0}}, 1'b1})
                            begin
                                 sram_ocp_sm <= `SRAM_SM_IDLE;
                                 mburstlen_cntr <= {BURSTLEN{1'b0}};
                            end
                     end
                   default:
                     begin
                     end
                 endcase // case(axi_mstr_sm[2:0])
            end // else: !if(hreset_n == 1'b0)
     end // always @ (posedge sram_ocp_clk)

endmodule // sram_ocp_if


// Local Variables:
// verilog-library-directories:("." "$IP_DIR/crgn/soc_building_blocks/hdl")
// End:
