

// XBOX hardware accelerator

module xbox_mfarm #(parameter NUM_MEMS=2,       // Number of memory instances,  maximum value is 16
                  LOG2_LINES_PER_MEM=8) (   

   input clk,
   input rst_n,
   
   // Host (APB) port interface --- TODO: CONSIDER REMOVING  ONCE TCM MODE WORKS
   input  [18:0] apb_addr,
   input  [31:0] apb_data_in,
   input  apb_rd,
   input  apb_wr,
   output [31:0] apb_data_out,
   
   output p_done, // port write/read transaction done (not stalled due to accelerator prioritized access) --- NOT YET SUPPORTED

   // XBOX mem TCM dmem interface	
   // xbox mem -> core_region
   output           xbox_dmem_rready,                         
   output [31:0]    xbox_dmem_rdata,
   output           xbox_dmem_wready,    
   // core region -> xbox mem
   input            xbox_dmem_rvalid,
   input [18:0]     xbox_dmem_addr,
   input            xbox_dmem_wvalid,
   input [31:0]     xbox_dmem_wdata,
   input [3:0]      xbox_dmem_wbe,       
   
   
   // XBOX HW accelerator interface
   input  logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] xlr_mem_addr,  //  address per memory instance  
   input  logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance
   input  logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   input  logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   input  logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance


   // Use for SW to optionally trigger an accelerator upon memory update
   output [18:0] soc_xmem_addr,   
   output        soc_xmem_wr        
 );

localparam LINES_PER_MEM = 2**LOG2_LINES_PER_MEM ;


logic [18:0] soc_addr;
logic [31:0] soc_data_in;
logic        soc_rd;
logic        soc_wr;
logic [31:0] soc_data_out;

logic [NUM_MEMS-1:0] soc_wr_mem_ok ; // Indicate vald soc write aceess per memory (no xlr access to that memory)
logic [NUM_MEMS-1:0] soc_rd_mem_ok ; // Indicate vald soc read  aceess per memory (no xlr access to that memory)
logic                soc_xmem_rd ;   // Indicate actual soc read access.

logic [NUM_MEMS-1:0][7:0][31:0] mem_inst_data_out ;
logic [3:0] p_mem_inst_idx ;
logic [2:0] p_word_out_mux_idx ;
logic       tcm_access ;


logic [31:0] apb_mem_be ; // apb port byte enable
logic  [3:0] soc_be ;

assign tcm_access = xbox_dmem_wvalid || xbox_dmem_rvalid ;

 // TODO ,  STALL SUPPORT
assign xbox_dmem_rready = soc_xmem_rd ; // ??? =1 ;      
assign xbox_dmem_wready = soc_xmem_wr ; // ??? =1 ;    

			
assign soc_be = tcm_access ? xbox_dmem_wbe : 4'b1111 ;

assign soc_addr       = tcm_access ?  xbox_dmem_addr   : apb_addr      ;
assign soc_data_in    = tcm_access ?  xbox_dmem_wdata  : apb_data_in   ;
assign soc_rd         = tcm_access ?  xbox_dmem_rvalid : apb_rd        ;
assign soc_wr         = tcm_access ?  xbox_dmem_wvalid : apb_wr        ;

assign apb_data_out    = soc_data_out  ;
assign xbox_dmem_rdata = soc_data_out  ;


 generate
     genvar i;
       for (i = 0; i < NUM_MEMS; i = i + 1) begin : mem_inst 

            logic [LOG2_LINES_PER_MEM-1:0]  m_addr ;
            logic  [7:0][31:0]               m_8x32_data_in ;
            logic [31:0]                     m_be ;
            logic  [7:0][31:0]               m_8x32_data_out ;
                      
            logic m_wr_en ;
            logic m_rd_en ;
            logic m_clken ;
            logic xlr_mem_access ; // Prioritized accelerator memory instance access
            logic [31:0] soc_mem_be ;

            logic soc_access_ok ;
			logic soc_addr_this_mem ;
            
            assign soc_addr_this_mem = (soc_addr[18:15]==i);
          
            assign xlr_mem_access = xlr_mem_wr[i] || xlr_mem_rd[i] ;
                       
            assign m_addr[LOG2_LINES_PER_MEM-1:0] = xlr_mem_access ?  xlr_mem_addr[i] : soc_addr[(LOG2_LINES_PER_MEM+4):5] ;
            assign m_8x32_data_in = xlr_mem_access ? xlr_mem_wdata[i] : {8{soc_data_in[31:0]}} ;
            
            assign soc_mem_be = 32'b0 | (soc_be[3:0] <<  (4*soc_addr[4:2])) ;			
            assign m_be = xlr_mem_access ? xlr_mem_be[i] : soc_mem_be ;
             
            assign soc_access_ok = soc_addr_this_mem && !(xlr_mem_wr[i] || xlr_mem_rd[i]) ;
            
            assign soc_wr_mem_ok[i] =  soc_wr &&  soc_access_ok ;            
            assign m_wr_en = xlr_mem_wr[i] || (soc_wr && soc_addr_this_mem); 

            assign soc_rd_mem_ok[i] =  soc_rd &&  soc_access_ok ;                            
            assign m_rd_en = xlr_mem_rd[i] || (soc_rd && soc_addr_this_mem); 
            assign m_clken = m_wr_en | m_rd_en ;
                       
            if (LINES_PER_MEM==1024)  begin : lpi
            
            altera_sp_ram_1024x256_be sp_ram_be (            
               .address(m_addr[LOG2_LINES_PER_MEM-1:0]),  
               .byteena(m_be[31:0]), 
               .clken(m_clken),     
               .clock(clk),  
               .data(m_8x32_data_in),
               .wren(m_wr_en),     
               .q(m_8x32_data_out)); 
               
            end else if (LINES_PER_MEM==256)  begin  : lpi
            
            altera_sp_ram_256x256_be sp_ram_be (            
               .address(m_addr[LOG2_LINES_PER_MEM-1:0]),  
               .byteena(m_be[31:0]), 
               .clken(m_clken),     
               .clock(clk),  
               .data(m_8x32_data_in),
               .wren(m_wr_en),     
               .q(m_8x32_data_out)); 
			   
            end 
            
            assign mem_inst_data_out[i] = m_8x32_data_out ;
 
      end
 endgenerate

 assign soc_xmem_wr =  |soc_wr_mem_ok[NUM_MEMS-1:0]  ;
 assign soc_xmem_rd =  |soc_rd_mem_ok[NUM_MEMS-1:0]  ;
 assign soc_xmem_addr = soc_addr ;

 always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
	  p_word_out_mux_idx <= 3'b0 ;
	  p_mem_inst_idx     <= 4'b0 ;
	end else begin
	  p_word_out_mux_idx <= soc_addr[4:2] ;
	  p_mem_inst_idx     <= soc_addr[18:15] ; // Regardless of LOG2_LINES_PER_MEM , instances are spaced 1KB apart
    end
 end

 assign soc_data_out  = mem_inst_data_out[p_mem_inst_idx][p_word_out_mux_idx] ;
 assign xlr_mem_rdata = mem_inst_data_out ;

//--------------------------------------------------------------------------------------

`ifdef XBOX_MEM_DBG_PRINT
 // Verilog debug assistance Messages

 logic [18:0] soc_addr_s ;
 logic [31:0] soc_wr_data_s ; 
 logic soc_wr_s  ;
 logic soc_rd_s  ;


 always @(posedge clk) begin
 
       soc_addr_s <= soc_addr[18:0] ;
       soc_wr_data_s <= soc_data_in ;
       soc_wr_s <= soc_wr ;
     
       if (soc_wr_s) $display($time," VERILOG MSG: GPP XBOX APB Writing %x to xbox mem addr[18:0]=%x",soc_wr_data_s,soc_addr_s[18:0]) ;                                     
       if (soc_rd_s) $display($time," VERILOG MSG: GPP XBOX APB Reading %x from xbox mem addr[18:0]=%x",soc_data_out,soc_addr_s[18:0]) ;
 end 
`endif

endmodule
