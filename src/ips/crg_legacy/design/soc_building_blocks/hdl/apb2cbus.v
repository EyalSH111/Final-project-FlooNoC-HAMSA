//-----------------------------------------------------------------------------
// Title         : 
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : apb2cbus.v
// Author        :   <naftalyb@ceragon.com>
// Created       : 6.3.2015
// Last Modified : 2021-01-10 14:36
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 6.3.2015 : created
//------------------------------------------------------------------------------

module apb2cbus (/*autoarg*/
   // Outputs
   apbpready_i, apbpslverr_i, apbprdata_i, cbus_s_address,
   cbus_s_bytecnt, cbus_s_byten, cbus_s_cmd, cbus_s_first,
   cbus_s_last, cbus_s_req, cbus_s_wdata,
   // Inputs
   apbpaddr_o, apbpenable_o, apbpreset_no, apbpsel_o, apbpwdata_o,
   apbpwrite_o, cbus_s_sgn_clk, cbus_s_sgn_rst_n, cbus_s_clk,
   cbus_s_rst_n, cbus_s_clk_dis, cbus_s_rdatap, cbus_s_rresp,
   cbus_s_waccept
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter                      ADDRW = 8;

   //----------------------------------------------------------------------------
   // APB I/F
   //----------------------------------------------------------------------------
   input [ADDRW-1:0]              apbpaddr_o;
   input                          apbpenable_o;
   input                          apbpreset_no;
   input                          apbpsel_o;
   input [31:0]                   apbpwdata_o;
   input                          apbpwrite_o;
   output                         apbpready_i;
   output                         apbpslverr_i;
   output [31:0]                  apbprdata_i;

   //----------------------------------------------------------------------------
   // CBUS I/O SGN clock/rst
   //----------------------------------------------------------------------------
   input                          cbus_s_sgn_clk;
   input                          cbus_s_sgn_rst_n;

   //----------------------------------------------------------------------------
   // CBUS I/O
   //----------------------------------------------------------------------------
   input                          cbus_s_clk;
   input                          cbus_s_rst_n;
   input                          cbus_s_clk_dis;
   output [ADDRW-1:0]             cbus_s_address;
   output [9:0]                   cbus_s_bytecnt;
   output [3:0]                   cbus_s_byten;
   output                         cbus_s_cmd;
   output                         cbus_s_first;
   output                         cbus_s_last;
   output                         cbus_s_req;
   output [31:0]                  cbus_s_wdata;
   input [31:0]                   cbus_s_rdatap;
   input                          cbus_s_rresp;
   input                          cbus_s_waccept;

   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   reg                            cbus_s_rresp_s0;
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 cbus_s_clk_dis_sync2;   // From I_cbus_s_clk_dis_sync2 of crg_sync2_arst.v
   // End of automatics

   //----------------------------------------------------------------------------
   // Assertions (needed when apbpready_i is not used!!!!!!!)
   //----------------------------------------------------------------------------
   //synopsys translate_off
   //assert_apb2cbus_non_rresp : assert property ( @(posedge cbus_s_clk) ((cbus_s_req === 1'b1 && cbus_s_cmd === 1'b1) |-> (cbus_s_rresp === 1))) else $fatal(2);
   //assert_apb2cbus_non_waccept : assert property ( @(posedge cbus_s_clk) ((cbus_s_req === 1'b1 && cbus_s_cmd === 1'b0) |-> (cbus_s_waccept === 1))) else $fatal(2);
   //synopsys translate_on

   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   assign       cbus_s_first              = 1'h1;
   assign       cbus_s_last               = 1'h1;
   assign       cbus_s_bytecnt[9:0]       = 10'h4;
   assign       cbus_s_byten[3:0]         = 4'hf;
   assign       cbus_s_wdata[31:0]        = apbpwdata_o[31:0];
   assign       cbus_s_address[ADDRW-1:0] = apbpaddr_o[ADDRW-1:0];
   assign       cbus_s_cmd                = ~apbpwrite_o;
   assign       cbus_s_req                = apbpwrite_o ? (apbpsel_o & apbpenable_o) : (apbpsel_o & ~cbus_s_rresp_s0);
   assign       apbprdata_i[31:0]         = cbus_s_rdatap[31:0];
   assign       apbpready_i               = cbus_s_clk_dis_sync2 ? 1'b1 : (apbpwrite_o ? cbus_s_waccept : cbus_s_rresp_s0);
   assign       apbpslverr_i              = cbus_s_clk_dis_sync2;
   
   /*autotieoff*/
   
   /*autoinput*/
   /////*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   sync_2ff_arst  I_cbus_s_clk_dis_2ff
   (
      .rstn(cbus_s_sgn_rst_n),
      .clk(cbus_s_sgn_clk),
      .in(cbus_s_clk_dis),
      .out(cbus_s_clk_dis_sync2)
   );
   
   //----------------------------------------------------------------------------
   // We need to delay the CBUS "rresp" by one cycle to aligen it to the APB
   // 3.0 protocol.
   // During reset, we block the "apbpready_i" signal to prevent the SGN from
   // being acknoleged for a transcating from peripheral under reset. 
   //----------------------------------------------------------------------------
   always @(posedge cbus_s_clk or negedge cbus_s_rst_n)
     begin
          if (cbus_s_rst_n == 1'b0)
            begin
                 cbus_s_rresp_s0 <= 1'b0;
            end
          else
            begin
                 // Default
                 if (cbus_s_req == 1'b1 && cbus_s_cmd == 1'b1)
                   cbus_s_rresp_s0 <= cbus_s_rresp;
                 else
                   cbus_s_rresp_s0 <= 1'b0;
            end // else: !if(cbus_s_rst_n == 1'b0)
     end // always @ (posedge clk)
   
endmodule // apb2cbus

// Local Variables:
// verilog-library-directories:("." ".." "$IP_DIR/crgn/dw_sync/28nm/hdl")
// End:
