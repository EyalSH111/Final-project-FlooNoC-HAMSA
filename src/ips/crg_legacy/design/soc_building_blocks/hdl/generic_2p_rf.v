module generic_2p_rf
  (
   rd_data,
   rd_addr,
   wr_addr,
   wr_data,
   wr_me_en,
   rd_me_en,
   wr_clk,
   rd_clk
   );
  
   
   // ************************************************************ 
   // Parameters
   // ************************************************************
   
   parameter MEM_SIZE  = 1024;
   parameter AW = 10;
   parameter DW = 8;
   
   // ************************************************************
   // I/O Declaration
   // ************************************************************
   
   output [DW-1:0] rd_data;
   input [AW-1:0]       rd_addr;
   input [AW-1:0]       wr_addr;
   input [DW-1:0]  wr_data;
   input                wr_me_en;
   input                rd_me_en;
   input                wr_clk;
   input                rd_clk;
   
   // ************************************************************
   // Internal registers and wirings
   // ************************************************************
   wire [DW-1:0]   rd_data;
   
   reg [AW-1:0]         addr_reg;
   reg [DW-1:0]    mem_core_array[0:MEM_SIZE-1] /* synthesis syn_ramstyle="M9K, no_rw_check"*/;


   // ************************************************************ 
   // implement the rd_addrM
   // ************************************************************   
 
   always @(posedge wr_clk)
        if (wr_me_en)
          mem_core_array[wr_addr] <= wr_data;
     
   always @(posedge rd_clk)
        if (rd_me_en)
          addr_reg <= rd_addr;         
   
   assign rd_data = mem_core_array[addr_reg];
   
endmodule


