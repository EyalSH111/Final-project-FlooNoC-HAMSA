// Time-stamp: <2010-04-14 1100 ronen>
//-----------------------------------------------------------------------------
// Title         : biu_async_if.v
// Project   :<project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : Ronen Daly
// Created       : 13-04-2010
// Last modified : 13-04-2010
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c)  by <company> This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
//-----------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
// Rev.  | Date:    | Revised By:    | Description:
//=================================================================================================
// 1.0   | <moddate>| <author>       |
//       |          |                |
//-------------------------------------------------------------------------------------------------


module cbus_select_if
  (//outputs to master core
   cbus_slv_waccept,     // [O] 1b 
   cbus_slv_rresp,       // [O] 1b 
   cbus_slv_rdatap,      // [O] 32b
   //outputs to units
   cs_to_units,          // [O] Num of Cs
   data_to_units,        // [O] 32b 
   addr_to_units,        // [O] 13b address to units
   wr_rd_n_to_units,     // [O] 1b  read/write# to units
   //inputs general
   clk,                  // [I] 1b  system fast clock
   sreset_n,             // [I] 1b  hardware reset
   //inputs from near core
   cbus_slv_address,     // [I] 16b 
   cbus_slv_cfg_req,     // [I] 1b  
   cbus_slv_cmd,         // [I] 1b  
   cbus_slv_wdata,       // [I] 32b 
   //inputs from units
   data_from_units,  // [I] 32b x Num of Cs
   ack_from_units    // [I] Num of cs unit0 Lsm unit7 Msb  
   );
   
   // ------------------------------------------------------------
   // Parameter Width Definition
   // ------------------------------------------------------------
   parameter DW = 32;
   parameter AW = 16;
   parameter TIM_WID = 8;
   parameter NUM_OF_CS = 8;
   parameter CS_WIDTH = clog2(NUM_OF_CS);
   
   localparam                   IDLE = 3'b000;
   localparam                   WAIT_ACK = 3'b101; 
   localparam                   ACK2CS_DOWN = 3'b111;
   localparam                   ABORT2CS_DOWN = 3'b100;
   localparam                   DELAY_CYC = 3'b110;
   
   // ------------------------------------------------------------
   // I/O Declaration
   // ------------------------------------------------------------
   output                       cbus_slv_waccept;
   output                       cbus_slv_rresp;
   output reg [DW-1:0]          cbus_slv_rdatap;
   output [NUM_OF_CS-1:0]       cs_to_units;
   output reg [DW-1:0]          data_to_units;
   output reg [AW-1-CS_WIDTH:0] addr_to_units;
   output reg                   wr_rd_n_to_units;
   input                        clk;
   input                        sreset_n;
   input [AW-1:0]               cbus_slv_address;
   input                        cbus_slv_cfg_req;
   input                        cbus_slv_cmd;
   input [DW-1:0]               cbus_slv_wdata;
   input [(DW*NUM_OF_CS)-1:0]   data_from_units;
   input [NUM_OF_CS-1:0]        ack_from_units;
   
   // ------------------------------------------------------------
   // Regs and Wires Declarations
   // ------------------------------------------------------------
   reg [CS_WIDTH-1:0]           unit_addr;
   reg [DW-1:0]                 host_rdata_reg;
   reg [NUM_OF_CS-1 :0]         cs_to_units;

   wire [DW*NUM_OF_CS -1:0]     units_data_read; 
   wire                         unit_ack;
   //************************************-
   // Address and data control
   //************************************-
   always @(posedge clk)
     if (~sreset_n)
       begin
	    data_to_units    <= {DW{1'h0}};
	    wr_rd_n_to_units <= 1'b0;
	    unit_addr        <= {CS_WIDTH{1'h0}};
            addr_to_units    <= {(AW-1-CS_WIDTH){1'h0}};
       end
     else 
       begin
	    data_to_units    <= cbus_slv_wdata[DW-1:0];
	    wr_rd_n_to_units <= cbus_slv_cmd;
	    unit_addr        <= cbus_slv_address[AW-1:AW-CS_WIDTH];
            addr_to_units    <= cbus_slv_address[AW-1-CS_WIDTH:0];
       end
   
   //************************************
   // Oring The Acknowledge from units
      //************************************
   assign unit_ack = |ack_from_units[NUM_OF_CS-1:0];
   
   always @(posedge clk)
     if (~sreset_n)
       cs_to_units <= {NUM_OF_CS{1'h0}};
     else if (unit_ack)
       cs_to_units <= {NUM_OF_CS{1'h0}};
          else if (cbus_slv_cfg_req)
            cs_to_units[unit_addr] <= 1'b1;
      
   //************************************************************ 	
   //  mux the 2 ports
   //************************************************************ 
	
   assign cbus_slv_waccept = unit_ack;
   assign cbus_slv_rresp   = unit_ack;
         
   //************************************-
   // Read Data to HOST
   //************************************-

   assign units_data_read[(DW*NUM_OF_CS)-1:0] = data_from_units[(DW*NUM_OF_CS)-1:0] >> (unit_addr*DW);
   
   always @(posedge clk)
     if (~sreset_n)
       cbus_slv_rdatap <= {DW{1'h0}};
     else if (unit_ack)
       cbus_slv_rdatap <= units_data_read[DW-1:0];

   
endmodule


