

// XBOX hardware accelerator

module xbox(
 input clk,
 input rst_n,
 APB_BUS.Slave apb,

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
 input [3:0]      xbox_dmem_wbe        
);
 
 // Subject to definition at apb_bus.sv the absolute 32b XBOX addresses are as follow
 // XBOX 32 X 32b (4 bytes) Regs: 0x1A40_0000 to 0x1A40_0000+(31*4) = 0x1a40007c
 // Open for Future use:0x1a400080 to 0x1a480000-1
 // XBOX MEM Address space 0x1a480000 to 0x1a500000-1 (0.5 MB space)

 localparam LOG2_LINES_PER_MEM = 8 ;    // Currently only 10 and 8 supported !!!  Default is 10 for 1K lines per instance
                                        // Notice this requires adjusting xbox_mem.sv
 localparam NUM_MEMS = 2 ;

 logic [31:0][31:0] xbox_regs ;
 logic [31:0] regs_rd_data_out ;
 logic ready ;
 logic [21:0] xbox_addr ; // Relative XBOX address
 logic is_xbox_reg_addr ;
 logic is_xbox_mem_addr;
 logic [4:0] reg_idx ;
 logic [18:0] xbox_mem_addr  ; 
 logic apb_setup_wr   ;    
 logic apb_setup_rd  ;     
 logic apb_access ;
 logic regs_rd_access ;
 logic is_regs_data_out ;

 
 // xbox_mem interface signals
 logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] xlr_mem_addr;
 logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata;
 logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be;
 logic [NUM_MEMS-1:0]             xlr_mem_rd;
 logic [NUM_MEMS-1:0]             xlr_mem_wr;
 logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata;

// Accelerator registers access
 logic [31:0] host_regs_valid_pulse ;      // reg written by host (APB) (one per register)
 logic [31:0]  host_regs_valid_pulse_d ;   // pre-sample
 logic [31:0][31:0] host_regs_data_out ;   // regs accelerator write data
 logic [31:0] host_regs_valid_out ;        // reg written by accelerator (one per register)
 logic apb_wr_reg ;


 assign xbox_addr = apb.paddr[21:0] ; // Relative XBOX address
 assign is_xbox_reg_addr = apb.psel && ~xbox_addr[19] ;
 assign is_xbox_mem_addr = apb.psel &&  xbox_addr[19] ;
 assign reg_idx = xbox_addr[6:2];
 assign xbox_mem_addr = xbox_addr[18:0] ;
 assign apb_setup_wr = apb.psel &&  apb.pwrite  ;    
 assign apb_setup_rd = apb.psel && !apb.pwrite  ;    
 assign apb_access = apb.psel && apb.penable ;
 assign apb_wr_reg = apb_setup_wr && is_xbox_reg_addr && !ready ;


 // REGS WRITE 
 always @(posedge clk, negedge rst_n)
     if(~rst_n) 
       for (int i=0;i<32;i++) xbox_regs[i] <= 0 ;
     else
       if (apb_wr_reg) xbox_regs[reg_idx] <= apb.pwdata  ;     // write only once 

     
 // REGS WRITE VALID PULSE
 always_comb begin
  host_regs_valid_pulse_d[31:0] = 32'b0 ;  
  if (apb_wr_reg) host_regs_valid_pulse_d[reg_idx] = 1'b1 ;
 end
        
 always @(posedge clk, negedge rst_n)
     if(~rst_n) host_regs_valid_pulse <= 32'b0 ;
     else host_regs_valid_pulse <= host_regs_valid_pulse_d ;
     
 // REGS SYNCHRONOUS READ
 assign regs_rd_access = apb_setup_rd && is_xbox_reg_addr && !ready ;
 always @(posedge clk)
   if  (regs_rd_access) begin // As long as valid is asserted the XBOX value is read, otherwise the APB recent written value.
     if (host_regs_valid_out[reg_idx]) regs_rd_data_out <= host_regs_data_out[reg_idx] ;
     else regs_rd_data_out <= xbox_regs[reg_idx] ; 
   end 
        
 // indicate regs read output  
 always @(posedge clk, negedge rst_n) 
     if (~rst_n) is_regs_data_out <= 0 ;
     else is_regs_data_out <= regs_rd_access ;
       
 //=====================================================
 
 // APB Memory access 

logic mem_rden ;
logic mem_wren ;
logic [31:0] p_mem_data_out ;

logic soc_xmem_wr ;
logic [18:0] soc_xmem_addr ;

assign mem_rden  = apb_setup_rd && is_xbox_mem_addr && !ready; 
assign mem_wren  = apb_setup_wr && is_xbox_mem_addr && !ready; 
  
xbox_mfarm #(.NUM_MEMS(NUM_MEMS),                        // Number of  memory instances,  maximum value is 16
          .LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM))  // Determine each INST depth
          xbox_mfarm (   

   .clk   (clk),
   .rst_n (rst_n),
   
   // Host (APB) port interface  --- TODO: CONSIDER REMOVING APB ACCESS
   .apb_addr     (apb.paddr[19:0]),
   .apb_data_in  (apb.pwdata[31:0]),
   .apb_rd       (mem_rden),
   .apb_wr       (mem_wren),
   .apb_data_out (p_mem_data_out),
   .p_done     (), // TMP NOT YET IN USE
   
   // XBOX mem TCM dmem interface	
   // xbox mem -> core_region
   .xbox_dmem_rready    ( xbox_dmem_rready ),                          
   .xbox_dmem_rdata     ( xbox_dmem_rdata  ),  
   .xbox_dmem_wready    ( xbox_dmem_wready ),     
   // core_region -> xbox_mem
   .xbox_dmem_rvalid    ( xbox_dmem_rvalid ),
   .xbox_dmem_addr      ( xbox_dmem_addr   ),
   .xbox_dmem_wvalid    ( xbox_dmem_wvalid ),
   .xbox_dmem_wdata     ( xbox_dmem_wdata  ),
   .xbox_dmem_wbe       ( xbox_dmem_wbe    ),
     
   // XBOX HW accelerator interface 
   
   .xlr_mem_addr(xlr_mem_addr),
   .xlr_mem_wdata(xlr_mem_wdata),
   .xlr_mem_be(xlr_mem_be),
   .xlr_mem_rd(xlr_mem_rd),
   .xlr_mem_wr(xlr_mem_wr),
   .xlr_mem_rdata(xlr_mem_rdata) ,

   .soc_xmem_wr(soc_xmem_wr),
   .soc_xmem_addr(soc_xmem_addr)
   
 );

 
 //======================================================
 
  // apb.prdata output mux 
 
  assign apb.prdata = is_regs_data_out ? regs_rd_data_out : p_mem_data_out ;
  
  //====================================================
 
  // READY HANDLING
  always @(posedge clk, negedge rst_n) 
     if(~rst_n) 
       ready <= 0 ;
     else 
       ready <= apb.psel ;
       
  assign apb.pready = ready && apb.penable ;

  // ERROR HANDLING
  assign apb.pslverr = 1'b0; // not supporting transfer failure

 
 //========================================================

 // Accelerators farm
     
   xbox_xfarm #(.NUM_MEMS(NUM_MEMS),                  // Number of  memory instances,  maximum value is 16
          .LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM))  // Determine each INST depth
          xbox_xfarm (   

    .clk   (clk),
    .rst_n (rst_n),
 
    .xlr_mem_addr            (xlr_mem_addr), 
    .xlr_mem_wdata           (xlr_mem_wdata),  
    .xlr_mem_be              (xlr_mem_be),    
    .xlr_mem_rd              (xlr_mem_rd), 
    .xlr_mem_wr              (xlr_mem_wr),
    .xlr_mem_rdata           (xlr_mem_rdata),

    .soc_xmem_wr_addr        (soc_xmem_addr),
    .soc_xmem_wr             (soc_xmem_wr),

    .host_regs               (xbox_regs),
    .host_regs_valid_pulse   (host_regs_valid_pulse), 
    .host_regs_data_out      (host_regs_data_out),
    .host_regs_valid_out     (host_regs_valid_out)  
  ) ;
  

 //=========================================================
 
 
 // Verilog debug assistance Messages
 
 logic [19:0] addr_s ;
 logic [31:0] wr_data_s ;
 logic write_s ;
 logic is_xbox_reg_addr_s ;

 
 always @(posedge clk) begin
 
       addr_s <= apb.paddr[19:0] ;
       wr_data_s <= apb.pwdata ;
       write_s <= apb.pwrite;
       is_xbox_reg_addr_s <= is_xbox_reg_addr ;
     
       if (apb.pready) begin
          if (is_xbox_reg_addr_s) begin
             if (write_s) $display($time," VERILOG MSG: GPP XBOX APB Writing %x to xbox_regs[%02d]",wr_data_s,addr_s[6:2]) ;
             else         $display($time," VERILOG MSG: GPP XBOX APB Reading %x from (xbox_regs[%02d])",apb.prdata,addr_s[6:2]) ;
          end
       end          

 end

endmodule
