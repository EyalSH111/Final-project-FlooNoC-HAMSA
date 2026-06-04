// Time-stamp: <2010-04-14 0949 ronen>
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
   cbus_slv_near_waccept,     // [O] 1b 
   cbus_slv_near_rresp,       // [O] 1b 
   cbus_slv_near_rdatap,      // [O] 32b
   cbus_slv_far_waccept,      // [O] 1b 
   cbus_slv_far_rresp,        // [O] 1b 
   cbus_slv_far_rdatap,       // [O] 32b 
   //outputs to units
   cs_to_units,      // [O] Num of Cs
   data_to_units,    // [O] 32b 
   addr_to_units,    // [O] 13b address to units
   r_wn_to_units,    // [O] 1b  read/write# to units
   //inputs general
   clk,              // [I] 1b  system fast clock
   sreset_n,         // [I] 1b  hardware reset
   //inputs from near core
   cbus_slv_near_address,     // [I] 16b 
   cbus_slv_near_cfg_req,     // [I] 1b  
   cbus_slv_near_cmd,         // [I] 1b  
   cbus_slv_near_wdata,       // [I] 32b 
   //inputs from far core
   cbus_slv_far_address,      // [I] 16b
   cbus_slv_far_cfg_req,      // [I] 1b 
   cbus_slv_far_cmd,          // [I] 1b 
   cbus_slv_far_wdata,        // [I] 32b
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
   output                       cbus_slv_near_waccept;
   output                       cbus_slv_near_rresp;
   output [DW-1:0]              cbus_slv_near_rdatap;
   output                       cbus_slv_far_waccept;
   output                       cbus_slv_far_rresp;
   output [DW-1:0]              cbus_slv_far_rdatap;
   output [NUM_OF_CS-1:0]       cs_to_units;
   output [DW-1:0]              data_to_units;
   output reg [AW-1-CS_WIDTH:0] addr_to_units;
   output                       r_wn_to_units;
   input                        clk;
   input                        sreset_n;
   input [AW-1:0]               cbus_slv_near_address;
   input                        cbus_slv_near_cfg_req;
   input                        cbus_slv_near_cmd;
   input [DW-1:0]               cbus_slv_near_wdata;
   input [AW-1:0]               cbus_slv_far_address;
   input                        cbus_slv_far_cfg_req;
   input                        cbus_slv_far_cmd;
   input [DW-1:0]               cbus_slv_far_wdata;
   input [(DW*NUM_OF_CS)-1:0]   data_from_units;
   input [NUM_OF_CS-1:0]        ack_from_units;
   
   // ------------------------------------------------------------
   // Regs and Wires Declarations
   // ------------------------------------------------------------
   reg                          cbus_slv_far_cfg_req_d1;
   reg                          cbus_slv_far_cmd_d1;
   reg [AW-1:0]                 cbus_slv_far_address_d1;
   reg [DW-1:0]                 cbus_slv_far_wdata_d1;
   reg                          near_access_d;
   reg                          far_access_d;
   reg [TIM_WID-1:0]            abort_count;
   reg                          host_prio_grant;
   reg [2:0]                    host_stm;
   reg [DW-1:0]                 data_to_units;
   reg                          r_wn_to_units;
   reg [CS_WIDTH-1:0]           unit_addr;
   reg [DW-1:0]                 host_rdata_reg;
   reg [NUM_OF_CS-1 :0]         cs_to_units;

   wire [DW-1:0]                 units_data_read; 
   
   wire                         host_cs;
   wire                         near_access;
   wire                         far_access;
   wire [AW-1:0]                host_addr;
   wire [DW-1:0]                host_write;
   wire [DW-1:0]                host_wdata;
   wire                         unit_ack;
   wire                         abort;
   wire                         host_ack;
   wire                         cs_en;
   wire [DW*NUM_OF_CS -1:0]     units_data_read_tmp;


   //sample Far inputs for Timing Improvments
   always @(posedge clk)
     if (~sreset_n) begin
	  cbus_slv_far_cfg_req_d1 <= 1'b0 ;
	  cbus_slv_far_cmd_d1     <= 1'b0 ;   
	  cbus_slv_far_address_d1 <= {AW{1'b0}} ;
	  cbus_slv_far_wdata_d1   <= {DW{1'b0}} ;
     end else begin
	  cbus_slv_far_cfg_req_d1 <= cbus_slv_far_cfg_req ;
	  cbus_slv_far_cmd_d1     <= cbus_slv_far_cmd;   
          cbus_slv_far_address_d1 <= cbus_slv_far_address[AW-1:0];
          cbus_slv_far_wdata_d1   <= cbus_slv_far_wdata[DW-1:0];
     end
   
   //************************************************************ 	
   //  mux the 2 ports
   //************************************************************ 
	
   // port near has priority over port far
   assign host_cs     = near_access | far_access;
   assign near_access = cbus_slv_near_cfg_req   & ~far_access_d;
   assign far_access  = cbus_slv_far_cfg_req_d1 & ((~cbus_slv_near_cfg_req & ~near_access_d) | far_access_d); 

   always @(posedge clk)
     if (~sreset_n)
       near_access_d <= 1'b0;
     else
       near_access_d <= near_access;
   
   always @(posedge clk)
     if (~sreset_n)
       far_access_d <= 1'b0;
     else
       far_access_d <= far_access;
   
   assign host_addr[AW-1:0]  = far_access ? cbus_slv_far_address_d1[AW-1:0] : cbus_slv_near_address[AW-1:0];
   assign host_wdata[DW-1:0] = far_access ? cbus_slv_far_wdata_d1[DW-1:0]   : cbus_slv_near_wdata[DW-1:0];
   assign host_write         = far_access ? cbus_slv_far_cmd_d1             : cbus_slv_near_cmd;

   assign cbus_slv_near_waccept = host_ack & near_access_d;
   assign cbus_slv_near_rresp   = cbus_slv_near_waccept;   
   assign cbus_slv_far_waccept  = host_ack & far_access_d;
   assign cbus_slv_far_rresp    = cbus_slv_far_waccept;   
   
   assign cbus_slv_near_rdatap  = host_rdata_reg;
   assign cbus_slv_far_rdatap   = host_rdata_reg;
   
   //************************************
   // Oring The Acknowledge from units
   //************************************
   assign unit_ack = |ack_from_units[NUM_OF_CS-1:0];
   
   //************************************
   // Abort Counter
   //************************************   
   always @(posedge clk)
     if (~sreset_n)
       abort_count <= {TIM_WID{1'b0}};
     else
       abort_count <= (~host_prio_grant) ? {TIM_WID{1'b0}} : abort_count + 1'b1;
   
   assign  abort = (abort_count == {TIM_WID{1'b1}});
   
   //************************************
   // Was riority handler
   //************************************   
   always @(posedge clk)
     if (~sreset_n)
       host_prio_grant <= 1'b0 ;
     else if ((host_stm == DELAY_CYC) & host_prio_grant)
       host_prio_grant <= 1'b0 ;
     else if (host_stm == WAIT_ACK)
       host_prio_grant <= 1'b1 ;
	      
   //************************************      
   // HOST Access State Machine
   //************************************
   assign  host_ack = ((host_stm == ACK2CS_DOWN) & ((near_access_d & cbus_slv_near_cfg_req) | (far_access_d & cbus_slv_far_cfg_req)));

   always @(posedge clk)
     if (~sreset_n)
       host_stm <= IDLE;
     else
       case (host_stm) // synopsys parallel_case
         IDLE          : host_stm <= host_cs ? WAIT_ACK : IDLE;
         WAIT_ACK      : host_stm <= unit_ack & host_prio_grant ? ACK2CS_DOWN : abort & host_prio_grant ? ABORT2CS_DOWN : host_cs ? WAIT_ACK : DELAY_CYC;
         ACK2CS_DOWN   : host_stm <= host_cs ? ACK2CS_DOWN : DELAY_CYC;
	 ABORT2CS_DOWN : host_stm <= host_cs ? ABORT2CS_DOWN : DELAY_CYC;
	 DELAY_CYC     : host_stm <= IDLE;
	 default       : host_stm <= IDLE;
       endcase // case(stm)
   
   //************************************-
   // Address and data control
   //************************************-
   always @(posedge clk)
     if (~sreset_n)
       begin
	 data_to_units              <= {DW{1'h0}};
	 r_wn_to_units              <= 1'b0;
	 {unit_addr, addr_to_units} <= {AW{1'h0}};
       end
     else if (host_stm == WAIT_ACK)
       begin
	 data_to_units              <=  host_wdata;
	 r_wn_to_units              <= ~host_write;
	 {unit_addr, addr_to_units} <=  host_addr;
       end

   //************************************-
   // Read Data to HOST
   //************************************-

   assign units_data_read_tmp[(DW*NUM_OF_CS)-1:0] = data_from_units[(DW*NUM_OF_CS)-1:0] >> (unit_addr*DW);
   assign units_data_read[DW-1:0] =units_data_read_tmp[DW-1:0];
   
   always @(posedge clk)
     if (~sreset_n)
       host_rdata_reg <= {DW{1'h0}};
     else if (host_stm == WAIT_ACK & unit_ack & host_prio_grant & r_wn_to_units)
       host_rdata_reg <= units_data_read[DW-1:0];
   
   assign cs_en = (host_stm   == WAIT_ACK & host_prio_grant);
   
   always @(posedge clk)
     if (~sreset_n)
       cs_to_units <= {NUM_OF_CS{1'h0}};
     else if (unit_ack | (host_stm!=WAIT_ACK))
       cs_to_units <= {NUM_OF_CS{1'h0}};
          else if (host_prio_grant & cs_en)
            cs_to_units[unit_addr] <= 1'b1;

   
endmodule


