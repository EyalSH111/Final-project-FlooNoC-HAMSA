//==================================================================================
//  Module Name: generic_fifo2cbus_master_ctl
//  Description: FIFO I/F With CBUS transfer controller
//               
//  Designed By: Michal Shmueli
//  Date Created: 1 July 2010
//  Designed for: Ceragon
//
//  Functional Description: Master logic over both the FIFO side and the CBUS side.
//                          When a request for a burst is detected (only when
//                          ctl2fifo_ready is high), the burst parameters - 
//                          address and bytecnt - are saved. Data read request
//                          is sent to the FIFO, according to the waccept signal
//                          behaviour. Data is expected on the following
//                          clock cycle. There is a prefetch of 3 data words
//                          (data read is set high regardless of the waccept
//                          value for the first 3 words). Supported burst size
//                          of 1 byte to 64 bytes (16 words).
//
//  Change History: Original CBUS Master logic changed to fit CBUS Master write only
//                  1) Remove rready and dir signals and logic
//                  2) The ctl_address must be aligned to 4 (ctl_address[1:0]==2'b0)
//                  3) The ctl_address must be valid 2 cycles after fifo2ctl_req is 
//                     given, the same timing as the 1st data word of fifo2ctl_data
//                     Previously, it was required immediately (with fifo2ctl_req)
//                  4) Add internal rd indication for data sample, required for
//                     a toggeling waccept support
//                  5) Add address continuity option - new input fifo2ctl_latch_addr
//                     with timing same as of the address validity.
//                  5) Add System header & Packet address continuity option - 
//                     new input fifo2ctl_mem_access_dbg_mode which is a static
//                     configuration mode. If set, bit 14 and 15 of the cbus address
//                     is cleared.
//                  6) Add parameter that will used only by the QUEUING block -
//                     parameter EXT_SYS_HDR_INDICATION
//                     It will allow nested packets over the CBUS (system
//                     header indication (bit 14) is passed by the module)
//
//==================================================================================

module generic_fifo2cbus_master_ctl ( 
   // Clock and Reset
   cbus_clk, 
   rst_n, 
   fifo2ctl_req, 
   fifo2ctl_address, // burst address
   fifo2ctl_bytecnt, // burst size
   fifo2ctl_big_endian,
   ctl2fifo_fifo_rd,
   fifo2ctl_data,    // burst data
   ctl2fifo_ready,
   fifo2ctl_latch_addr,
   fifo2ctl_mem_access_dbg_mode,
   cbus_req,
   cbus_address, 
   cbus_bytecnt,
   cbus_byten, 
   cbus_first,
   cbus_last,
   cbus_data,
   cbus_waccept
   );

   // General
   input          cbus_clk;        
   input          rst_n; 
   // Internal logic I/F
   input          fifo2ctl_req;
   output         ctl2fifo_fifo_rd;
   input   [31:0] fifo2ctl_data; 
   input   [31:0] fifo2ctl_address; 
   input    [9:0] fifo2ctl_bytecnt; 
   input          fifo2ctl_big_endian;
   output         ctl2fifo_ready;
   input          fifo2ctl_latch_addr;
   input          fifo2ctl_mem_access_dbg_mode;
   // CBUS Master I/F
   output         cbus_req;
   output  [31:0] cbus_data;
   output  [31:0] cbus_address;
   output   [9:0] cbus_bytecnt;
   output   [3:0] cbus_byten;
   output         cbus_first;
   output         cbus_last;
   input          cbus_waccept;

   //================================================================================
   // PARAMETERS 
   //================================================================================
   parameter EXT_SYS_HDR_INDICATION = 1'b0;

   //================================================================================
   // Wires
   //================================================================================
   wire        ctl2fifo_fifo_rd;
   wire        ctl_fifo_rd_d0;
   wire        int_fifo_rd_d0;
   wire        ctl_req_d0;
   wire        ctl_waccept_d0;
   wire [31:0] ctl_data_d0;
   wire        ctl_req;
   wire        wa0wa1wa2;
   wire        wa0wa1wa2n;
   wire        wa0wa1nwa2;
   wire        wa0wa1nwa2n;
   wire        ext_sys_hdr_indication;
   wire  [3:0] n_byten;
   wire        n_last;
   wire        ctl2fifo_ready;
   wire        fifo2ctl_latch_addr;
   wire        fifo2ctl_mem_access_dbg_mode;
   wire [31:0] cbus_address_p4;
   wire  [9:0] incd_bytecnt;
   wire  [7:0] n_wordcnt;
   wire        bc_ne0;
   wire        bc_ne1;
   wire        bc_ne2;
   wire        bc_ne3;

   //================================================================================
   // Registers / Nets
   //================================================================================
   reg        ctl_req_d1;
   reg        ctl_req_d2;
   reg        ctl_fifo_rd_d1;
   reg        int_fifo_rd_d1;
   reg        int_fifo_rd_d2;
   reg        ctl_waccept_d1;
   reg        ctl_waccept_d2;
   reg [31:0] ctl_data_d1;
   reg [31:0] ctl_data_d2;
   reg [31:0] cbus_data, n_data;
   reg        cbus_req, n_req;
   reg [31:0] cbus_address, n_address;
   reg  [9:0] cbus_bytecnt, n_bytecnt;
   reg  [3:0] cbus_byten;
   reg        cbus_first, n_first;
   reg        cbus_last;
   
   //================================================================================
   // FIFO Read I/F
   //================================================================================

   // Combinational assignments:
   //--------------------------------------------------------------------------------
   assign ctl_fifo_rd_d0 = ctl_req_d0 | 
                          (ctl_req_d1 & (cbus_bytecnt>10'd4)) | 
                          (ctl_req_d2 & (cbus_bytecnt>10'd8)) | 
                          (cbus_waccept & cbus_req & (cbus_bytecnt>10'd12));

   //     int_fifo_rd_d0 - used for data latching on the cbus_data
   assign int_fifo_rd_d0 = ctl_req_d0 | ctl_req_d1 | ctl_req_d2 | 
                           (cbus_waccept & cbus_req);

   assign ctl2fifo_ready = ~(ctl_req_d1 | ctl_req_d2 | cbus_req);
   assign ctl_req_d0 = fifo2ctl_req & ctl2fifo_ready;
   assign ctl_waccept_d0 = ~cbus_req | cbus_waccept;
   assign ctl_data_d0 = fifo2ctl_data;
   assign ctl_req = ctl_req_d2;
   assign ctl2fifo_fifo_rd = ctl_fifo_rd_d1;
   
   // Edge triggered ffs
   //--------------------------------------------------------------------------------
   always @ (posedge cbus_clk)
      begin
      if (~rst_n)
         begin
         ctl_req_d1     <= 1'b0;
         ctl_req_d2     <= 1'b0;
         ctl_fifo_rd_d1 <= 1'b0;
         int_fifo_rd_d1 <= 1'b0;
         int_fifo_rd_d2 <= 1'b0;
         ctl_waccept_d1 <= 1'b0;
         ctl_waccept_d2 <= 1'b0;
         ctl_data_d1    <= 32'b0;
         ctl_data_d2    <= 32'b0;
         end
      else
         begin
         ctl_req_d1     <= ctl_req_d0;
         ctl_req_d2     <= ctl_req_d1;
         ctl_fifo_rd_d1 <= ctl_fifo_rd_d0;
         int_fifo_rd_d1 <= int_fifo_rd_d0;
         int_fifo_rd_d2 <= int_fifo_rd_d1;
         ctl_waccept_d1 <= ctl_waccept_d0;
         ctl_waccept_d2 <= ctl_waccept_d1;
         ctl_data_d1    <= int_fifo_rd_d2 ? ctl_data_d0 : ctl_data_d1;
         ctl_data_d2    <= int_fifo_rd_d2 ? ctl_data_d1 : ctl_data_d2;
         end
      end
      
   //================================================================================
   // CBUS Outputs
   //================================================================================

   // Combinational assignments:
   //--------------------------------------------------------------------------------
   assign wa0wa1wa2   = ctl_waccept_d0 &  ctl_waccept_d1 &  ctl_waccept_d2;
   assign wa0wa1wa2n  = ctl_waccept_d0 &  ctl_waccept_d1 & ~ctl_waccept_d2;
   assign wa0wa1nwa2  = ctl_waccept_d0 & ~ctl_waccept_d1 &  ctl_waccept_d2;
   assign wa0wa1nwa2n = ctl_waccept_d0 & ~ctl_waccept_d1 & ~ctl_waccept_d2;

   assign ext_sys_hdr_indication = EXT_SYS_HDR_INDICATION;

   always @(*)
      begin
      n_data = cbus_data;
      if (wa0wa1wa2)
         n_data[31:0] = ctl_data_d0[31:0];
      else if (wa0wa1wa2n | wa0wa1nwa2)
         n_data[31:0] = ctl_data_d1[31:0];
      else if (wa0wa1nwa2n)
         n_data[31:0] = ctl_data_d2[31:0];
      end
   
   assign cbus_address_p4 = cbus_address + 3'd4;
   
   always @(*)
      begin
      n_bytecnt = cbus_bytecnt;
      if (ctl_req_d0) // A new transaction starts
         begin
         n_bytecnt[9:0]  = fifo2ctl_bytecnt;
         end
      else if (cbus_req & cbus_waccept)
         begin
         n_bytecnt[9:0]  = cbus_bytecnt - 10'd4;
         end
      end
   
   always @(*)
      begin
      n_address = cbus_address;

      if (ctl_req)
         begin
         if (fifo2ctl_latch_addr) // Sample the address as late as possible
            begin
            n_address[31:16] = fifo2ctl_address[31:16];
            n_address[15] = fifo2ctl_address[15] & ~fifo2ctl_mem_access_dbg_mode;
            n_address[14] = (fifo2ctl_address[14] | ~ext_sys_hdr_indication) & ~fifo2ctl_mem_access_dbg_mode; // System header over the first burst
            n_address[13:2] = fifo2ctl_address[13:2];
            n_address[1:0]  = 2'b00;
            end
         else
            n_address[14] = 1'b0; // System header over the first burst
         end
      else if (cbus_req & cbus_waccept)
         begin
         n_address[13:2] = cbus_address_p4[13:2];
         n_address[1:0]  = 2'b00;
         end

      end
   
   always @(*)
      begin
      n_first = cbus_first;
      n_req   = cbus_req;
      if (ctl_req) // A new transaction starts
         begin
         n_first = 1'b1;
         n_req   = 1'b1;
         end
      else if (cbus_req & cbus_waccept)
         begin
         n_first  = 1'b0;
         n_req    = ~cbus_last;
         end
      end

   assign incd_bytecnt[9:0] = n_bytecnt + 10'd3;
   assign n_wordcnt[7:0] = {2'b0, incd_bytecnt[7:2]};
   assign n_last = (n_wordcnt == 8'd1);
   
   assign bc_ne0 = ~(n_bytecnt==10'd0);
   assign bc_ne1 = ~(n_bytecnt==10'd1);
   assign bc_ne2 = ~(n_bytecnt==10'd2);
   assign bc_ne3 = ~(n_bytecnt==10'd3);
   
   assign n_byten[0] = bc_ne0;
   assign n_byten[1] = bc_ne0 & bc_ne1;
   assign n_byten[2] = bc_ne0 & bc_ne1 & bc_ne2;
   assign n_byten[3] = bc_ne0 & bc_ne1 & bc_ne2 & bc_ne3;

   // Edge triggered ffs
   //--------------------------------------------------------------------------------
   always @ (posedge cbus_clk)
      begin
      if (~rst_n)
         begin
         cbus_address <= 32'b0;
         cbus_bytecnt <= 10'b0;
         cbus_first   <= 1'b0;
         cbus_last    <= 1'b0;
         cbus_req     <= 1'b0;
         cbus_byten   <= 4'b0;
         cbus_data    <= 32'b0;
         end
      else
         begin
         cbus_address <= n_address;
         cbus_bytecnt <= n_bytecnt;
         cbus_first   <= n_first;
         cbus_last    <= n_last;
         cbus_req     <= n_req;
         cbus_byten   <= fifo2ctl_big_endian ? {n_byten[0],n_byten[1],n_byten[2],n_byten[3]} : n_byten;
         cbus_data    <= n_data;
         end
      end
   
endmodule
