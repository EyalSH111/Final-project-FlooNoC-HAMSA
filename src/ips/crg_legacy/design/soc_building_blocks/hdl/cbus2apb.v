//-----------------------------------------------------------------------------
// Title         : CBUS2APB (single clock & single transfer only!)
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : cbus2apb.v
// Author        :   <naftalyb@ceragon.com>
// Created       : 6.3.2015
// Last modified : Time-stamp: <2015-07-27 2324 naftalyb>
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

module cbus2apb (/*autoarg*/
   // Outputs
   apbpaddr_i, apbpenable_i, apbpsel_i, apbpwdata_i, apbpwrite_i,
   cbus_m_rdatap, cbus_m_rresp, cbus_m_waccept,
   // Inputs
   apbpreset_no, apbpready_o, apbprdata_o, cbus_m_clk, cbus_m_rst_n,
   cbus_m_address, cbus_m_bytecnt, cbus_m_byten, cbus_m_cmd,
   cbus_m_first, cbus_m_last, cbus_m_req, cbus_m_wdata
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter                      ADDRW = 8;

   //----------------------------------------------------------------------------
   // APB I/F
   //----------------------------------------------------------------------------
   input                          apbpreset_no;
   output [ADDRW-1:0]             apbpaddr_i;
   output                         apbpenable_i;
   output                         apbpsel_i;
   output [31:0]                  apbpwdata_i;
   output                         apbpwrite_i;
   input                          apbpready_o;
   input [31:0]                   apbprdata_o;

   //----------------------------------------------------------------------------
   // CBUS I/O
   //----------------------------------------------------------------------------
   input                          cbus_m_clk;
   input                          cbus_m_rst_n;
   input [ADDRW-1:0]              cbus_m_address;
   input [9:0]                    cbus_m_bytecnt;
   input [3:0]                    cbus_m_byten;
   input                          cbus_m_cmd;
   input                          cbus_m_first;
   input                          cbus_m_last;
   input                          cbus_m_req;
   input [31:0]                   cbus_m_wdata;
   output [31:0]                  cbus_m_rdatap;
   output                         cbus_m_rresp;
   output                         cbus_m_waccept;
   
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   reg [31:0]                     cbus_m_rdatap;
   reg                            apbpenable_i;
   
   /*autowire*/

   //----------------------------------------------------------------------------
   // Assertions
   //----------------------------------------------------------------------------
   //synopsys translate_off
   assert_apb2bus_bc_is_not_4 : assert property (@(posedge cbus_m_clk) !(cbus_m_req === 1'b1 && cbus_m_first === 1'b1 && cbus_m_last === 1'b1 && cbus_m_bytecnt != 10'h4)) else $fatal(2);
   //synopsys translate_on

   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   assign  apbpwdata_i[31:0]     = cbus_m_wdata[31:0];
   assign  apbpaddr_i[ADDRW-1:0] = cbus_m_address[ADDRW-1:0];
   assign  apbpwrite_i           = ~cbus_m_cmd;
   assign  apbpsel_i             = cbus_m_req;
   
   assign  cbus_m_rresp          = (cbus_m_req == 1 && cbus_m_cmd == 1'b1 && apbpenable_i == 1'b1 && apbpready_o == 1'b1);
   assign  cbus_m_waccept        = (cbus_m_req == 1 && cbus_m_cmd == 1'b0 && apbpenable_i == 1'b1 && apbpready_o == 1'b1);
   
   /*autotieoff*/
   
   /*autoinput*/
   /////*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   //----------------------------------------------------------------------------
   // In order to generate the APB enable signal we delay the cbus_req by one cycle.
   // The enable signal is de-asserted while it's high and ready signal is high as well.
   //----------------------------------------------------------------------------
   always @(posedge cbus_m_clk or negedge cbus_m_rst_n)
     begin
          if (cbus_m_rst_n == 1'b0)
            begin
                 apbpenable_i <= 1'b0;
                 cbus_m_rdatap <= 32'h0;
            end
          else
            begin
                 // Default
                 cbus_m_rdatap <= apbprdata_o;
                 if (apbpenable_i == 1'b1)
                   begin
                        if (apbpready_o == 1'b1)
                          begin
                               apbpenable_i <= 1'b0;
                          end
                   end
                 else
                   begin
                        if (cbus_m_req == 1'b1)
                          begin
                               apbpenable_i <= 1'b1;
                          end
                   end
            end // else: !if(cbus_m_rst_n == 1'b0)
     end // always @ (posedge clk)
   
endmodule // cbus2apb

// Local Variables:
// verilog-library-directories:("." ".." "$IP_DIR/crgn/dw_sync/28nm/hdl")
// End: