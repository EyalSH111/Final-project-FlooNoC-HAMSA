// User: avis 
// Date: 22_08_2011-Time 16_39_07
// Version:/main/6
// Description:
// 		 fix bug in sop state machine 
////// 
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////                                                                 ////
////  generic_cbus2fifo_slave_ctl.v                                  ////
////                                                                 ////
////  This file is part of the "cbus" project                        ////
////                                                                 ////
////  Known problems (limits):                                       ////
////  None                                                           ////
////                                                                 ////
////  To Do:                                                         ////
////  Nothing.                                                       ////
////                                                                 ////
////  Author(s):                                                     ////
////      - avis@ceragon.com                                         ////
////      - Avi Shamli                                               ////
////                                                                 ////
////  Created:        24.06.10                                       ////
////  Last Updated:   27.06.11                                       ////
////                                                                 ////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

module generic_cbus2fifo_slave_ctl (
                                    // Clock & Reset
                                    // Inputs
                                    cbus_hrst_n,           // [I] CBUS sync master reset
                                    cbus_clk,              // [I] CBUS input Clock
                                    
                                    // Register Interface
                                    // Inputs
                                    cbus_port_en,          // [I] CBUS port enable. Open ('1') or close ('0') indicator
                                    
                                    // CBUS Slave Interface
                                    // Inputs
                                    cbus_s_req,            // [I] Request the CBUS to issue a tranaction
                                    cbus_s_addr,           // [I] CBUS target address
                                    cbus_s_r_wn,           // [I] CBUS Read ('1') or write ('0') indicator
                                    cbus_s_wdata,          // [I] CBUS write data
                                    cbus_s_start,          // [I] CBUS Start of tranaction
                                    cbus_s_end,            // [I] CBUS End of tranaction
                                    cbus_s_be,             // [I] CBUS byte enable (active only in EOP)
                                    cbus_s_bc,             // [I] CBUS byte count
                                    
                                    // Outputs              
                                    cbus_s_waccept,        // [O] CBUS write has been accepted
                                    
                                    // FIFO Interface
                                    // Inputs
                                    fifo2cbus_ack,         // [I] FIFO write has been accepted
                                    
                                    // Decoder Interface
                                    // Outputs
                                    cbus2fifo_wr,          // [O] FIFO write control
                                    cbus2fifo_addr,        // [O] FIFO address
                                    cbus2fifo_data,        // [O] FIFO data
                                    cbus2fifo_sop,         // [O] FIFO start of packet
                                    cbus2fifo_eop,         // [O] FIFO end of packet
                                    cbus2fifo_be           // [O] FIFO byte enable
                                    );
   
   ///////////////////////////////////////////////////////////////////
         
      parameter REG_ADDR_BIT = 15;
      parameter HEADER_ADDR_BIT = 14;
      parameter DECODE_MSB_ADDR = 18;

   ///////////////////////////////////////////////////////////////////
         
   // Clock & Reset
   input             cbus_hrst_n;
   input             cbus_clk;
   
   input             cbus_port_en;

   // CBUS Slave Interface
   input             cbus_s_req;
   input [31:0]      cbus_s_addr;
   input             cbus_s_r_wn;
   input [31:0]      cbus_s_wdata;
   input             cbus_s_start;
   input             cbus_s_end;
   input [3:0]       cbus_s_be;
   input [9:0]       cbus_s_bc;
                        
   output            cbus_s_waccept;

   input             fifo2cbus_ack;

   output            cbus2fifo_wr;
   output [31:0]     cbus2fifo_addr;
   output [31:0]     cbus2fifo_data;
   output            cbus2fifo_sop;
   output            cbus2fifo_eop;
   output [1:0]      cbus2fifo_be;
   
   ///////////////////////////////////////////////////////////////////

   reg [13:0]        packet_len;

   reg [1:0]         sop_state;

   reg               cbus_s_waccept;
   
   reg               cbus2fifo_wr;
   reg [31:0]        cbus2fifo_addr;
   reg [31:0]        cbus2fifo_data;
   reg               cbus2fifo_sop;
   reg               cbus2fifo_eop;
   reg [1:0]         cbus2fifo_be;

   ///////////////////////////////////////////////////////////////////

   // Sample all CBUS inputs
   always @( posedge cbus_clk )
     if ( !cbus_hrst_n )
       begin
            cbus2fifo_addr <= 32'd0;
            cbus2fifo_data <= 32'd0;
       end
     else
       begin
            cbus2fifo_addr <= cbus_s_addr[31:0];
            cbus2fifo_data <= cbus_s_wdata[31:0];
       end
   
   //////////////////////////////////////////////////////////////////////////////////////////////////
   
   // Creadte SOP when CBUS address bit number HEADER_ADDR_BIT is set to '1'
   `define SOP_IDLE       2'd0
   `define SOP_HEADER     2'd1
   `define SOP_EOP        2'd2

   always @( posedge cbus_clk )
     if ( !cbus_hrst_n )
       begin
            cbus2fifo_sop <= 1'd0;
            cbus2fifo_eop <= 1'd0;
            cbus2fifo_be <= 2'd0;
            cbus2fifo_wr <= 1'd0;
            sop_state <= `SOP_IDLE;
       end
     else
         case ( sop_state )
	   `SOP_IDLE: 
             begin
                  if ( cbus_port_en )
                    begin
                         if ( cbus_s_req & cbus_s_waccept & cbus_s_addr[HEADER_ADDR_BIT] & (cbus_s_bc[9:0] == 10'd8) )
                           begin
                                cbus2fifo_sop <= 1'd1;
                                cbus2fifo_eop <= 1'd0;
                                cbus2fifo_wr <= 1'd1;
                                sop_state <= `SOP_HEADER;
                           end
                         else
                           begin
                                cbus2fifo_sop <= 1'd0;
                                cbus2fifo_eop <= 1'd0;
                                cbus2fifo_be <= 2'd0;
                                cbus2fifo_wr <= 1'd0;
                           end
                    end
                  else
                    begin
                         cbus2fifo_sop <= 1'd0;
                         cbus2fifo_eop <= 1'd0;
                         cbus2fifo_be <= 2'd0;
                         cbus2fifo_wr <= 1'd0;
                    end
             end
	   `SOP_HEADER: 
             begin
                  cbus2fifo_sop <= 1'd0;
                  
                  if ( cbus_s_req & cbus_s_waccept & cbus_s_addr[HEADER_ADDR_BIT] )
                    begin
                         sop_state <= `SOP_EOP;
                         cbus2fifo_wr <= 1'd1;
                    end
                  else
                    cbus2fifo_wr <= 1'd0;
             end
	   `SOP_EOP: 
             begin
                  if ( cbus_s_req & cbus_s_waccept )
                    begin
                         cbus2fifo_wr <= 1'd1;
                         if ( packet_len <= 14'd4 )
                           begin
                                cbus2fifo_eop <= 1'd1;
                                cbus2fifo_be <= packet_len[1:0];
                                sop_state <= `SOP_IDLE;
                           end
                    end
                  else
                    cbus2fifo_wr <= 1'd0;
                  
             end
	   default: 
             begin
                  cbus2fifo_sop <= 1'd0;
                  cbus2fifo_eop <= 1'd0;
                  cbus2fifo_be <= 2'd0;
                  cbus2fifo_wr <= 1'd0;
                  sop_state <= `SOP_IDLE;
             end
         endcase
             

   //////////////////////////////////////////////////////////////////////////////////////////////////
   
   // Count the number of bytes in each packet
   always @( posedge cbus_clk )
     if ( !cbus_hrst_n )
       packet_len <= 14'd0;
     else
       if ( cbus2fifo_sop )
         packet_len <= cbus2fifo_data[13:0];
       else
         if ( cbus_s_req & cbus_s_waccept & (sop_state == `SOP_EOP) )
           if ( packet_len < 14'd4 )
             packet_len <= 14'd0;
           else
             packet_len <= packet_len - 14'd4;


   //////////////////////////////////////////////////////////////////////////////////////////////////
   

   // CBUS write has been accepted
   always @( posedge cbus_clk )
     if ( !cbus_hrst_n )
       cbus_s_waccept <= 1'd0;
     else
       cbus_s_waccept <= cbus_s_req & fifo2cbus_ack;


endmodule
