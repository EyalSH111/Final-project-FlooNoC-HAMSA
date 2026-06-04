
module xbox_xlr_dmy2 #(parameter NUM_MEMS=1,LOG2_LINES_PER_MEM=4)  (

  // XBOX memories interface

   // System Clock and Reset
   input clk,
   input rst_n, // asserted when 0

   // Accelerator XBOX mastered memories interface

   output logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] xlr_mem_addr,  //  address per memory instance
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance
   output logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   input        [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance

   // Command Status Register Interface
   input  [31:0][31:0] host_regs,                   // regs accelerator write data, reflecting registers content as most recently written by SW over APB
   input        [31:0] host_regs_valid_pulse,       // reg written by host (APB) (one per register)
                                                    
   output logic [31:0][31:0] host_regs_data_out,          // regs accelerator write data,  this is what SW will read when accessing the register
                                                    // provided that the register specific host_regs_valid_out is asserted
   output logic [31:0] host_regs_valid_out,         // reg accelerator (one per register)

   input [18:0]        trig_soc_xmem_wr_addr,       // optional trigger, XBOX memory address accessed by SOC (processor/apb)
   input               trig_soc_xmem_wr             // optional trigger, validate actual SOC xmem wr access   
) ;

// TMP placeholder
assign xlr_mem_addr   = 0 ;
assign xlr_mem_wdata  = 0 ;
assign xlr_mem_be     = 0 ;
assign xlr_mem_rd     = 0 ;
assign xlr_mem_wr     = 0 ;

//--------------------------------------------------------------------------------

logic [5:0] bit_is_one_cnt ;

assign bit_is_one_cnt = 
   host_regs[7][ 0] + host_regs[7][ 1] + host_regs[7][ 2] + host_regs[7][ 3] 
 + host_regs[7][ 4] + host_regs[7][ 5] + host_regs[7][ 6] + host_regs[7][ 7]
 + host_regs[7][ 8] + host_regs[7][ 9] + host_regs[7][10] + host_regs[7][11] 
 + host_regs[7][12] + host_regs[7][13] + host_regs[7][14] + host_regs[7][15] 
 + host_regs[7][16] + host_regs[7][17] + host_regs[7][18] + host_regs[7][19] 
 + host_regs[7][20] + host_regs[7][21] + host_regs[7][22] + host_regs[7][23] 
 + host_regs[7][24] + host_regs[7][25] + host_regs[7][26] + host_regs[7][27] 
 + host_regs[7][28] + host_regs[7][29] + host_regs[7][30] + host_regs[7][31] ;


always @(posedge clk or negedge rst_n)  begin 
  if (!rst_n) begin
      host_regs_data_out[8] <= 0 ;
      host_regs_valid_out[8] <= 0 ;
  end else begin
     if (host_regs_valid_pulse[7]) begin
       host_regs_data_out[8] <= bit_is_one_cnt ;
       host_regs_valid_out[8] <= 1 ;
     end
  end
end


//--------------------------------------------------------------------------------

endmodule