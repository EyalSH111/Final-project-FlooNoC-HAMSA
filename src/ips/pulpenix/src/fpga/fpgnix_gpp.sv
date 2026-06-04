


module fpgnix_gpp(
    input clk,
    input sys_rst_n,
    APB_BUS.Slave apb,

    output logic jtag_sel,
    output logic [1:0] sw_reset,
    output logic enable_core

`ifdef DDR_INTRFC    
    // SOC System Interface       
    // Command/Status    
   ,output logic [31:0] soc_ddr_cmd,          // Command to ddr interface to store or load buffer , inducing DDR memory address
    output logic        soc_ddr_cmd_valid,    // pulse indicating command is valid.
    input        [31:0] soc_ddr_status,       // returned status, zero means not valid, changes to 0 upon sys_ddr_cmd_valid
    
    // Buffer direct Access
    output logic [1:0]  soc_ddr_data_buf_idx, // 4 X 32b words buffer
    output logic        soc_ddr_buf_wr,       // Write to buffer pulse
    output logic        soc_ddr_buf_rd,       // Read from buffer pulse    
    output logic [31:0] soc_ddr_data_in,      // input to buffer
    input        [31:0] soc_ddr_data_out      // output from buffer
`endif        
    );
 
    
   // fpgnix_gpp regs address map  
  
   localparam GPP_FPGNIX_CTL_REG_ADDR_OFST   = 0  ; 
   localparam GPP_DDR_CMD_REG_ADDR_OFST      = 4  ;    
   localparam GPP_DDR_STATUS_REG_ADDR_OFST   = 8  ;      
   localparam GPP_DDR_BUF_ADDR_OFST          = 32'h1000 ; 
   localparam GPP_DDR_BUF_START_ADDR = `GPP_FPGNIX_START_ADDR + GPP_DDR_BUF_ADDR_OFST ;

//////////////////////////////////////////////////////////////////////////////////////////////////////


 logic [3:0][31:0] gpp_regs ;
 logic [31:0] regs_rd_data_out ;
 logic ready ;
 logic [13:0] gpp_addr ; // Relative GPP address
 logic is_gpp_reg_addr ;
 logic is_gpp_ddr_buf_addr;
 logic [5:0] reg_idx ;
 logic [18:0] soc_ddr_buf_addr  ; 
 logic apb_setup_wr   ;    
 logic apb_setup_rd  ;     
 logic apb_access ;
 logic regs_rd_access ;
 logic is_regs_data_out ;
 logic[31:0] gpp_start_addr ; 
 logic [31:0] extended_gpp_addr ;

// Accelerator registers access
 logic [3:0]       host_regs_valid_pulse ;    // reg written by host (APB) (one per register)
 logic [3:0]       host_regs_valid_pulse_d ;  // pre-sample
 logic [3:0][31:0] gpp_regs_data_out ;        // regs accelerator write data
 logic [3:0]       gpp_regs_valid_out ;       // reg written by accelerator (one per register)
 logic apb_wr_reg ;

 assign gpp_addr = apb.paddr[13:0] ; // Relative GPP address
 
 assign gpp_start_addr = `GPP_START_ADDR ; 
 assign extended_gpp_addr   = {gpp_start_addr[31:23],apb.paddr[22:0]};
 assign is_gpp_reg_addr     = {extended_gpp_addr[31:8],8'b0} == `GPP_FPGNIX_START_ADDR ; 
 assign is_gpp_ddr_buf_addr = {extended_gpp_addr[31:12],12'b0} == GPP_DDR_BUF_START_ADDR ; 


 assign reg_idx = gpp_addr[3:2];
 assign soc_ddr_buf_addr = gpp_addr[11:0] ; // currently up to 4K
 assign soc_ddr_data_buf_idx = soc_ddr_buf_addr[3:2] ; // currently only 4 words in buffer 
 assign apb_setup_wr = apb.psel &&  apb.pwrite  ;    
 assign apb_setup_rd = apb.psel && !apb.pwrite  ;    
 assign apb_access = apb.psel && apb.penable ;
 assign apb_wr_reg = apb_setup_wr && is_gpp_reg_addr && !ready ;


 // REGS WRITE 
 always @(posedge clk, negedge sys_rst_n)
     if(~sys_rst_n) 
       for (int i=0;i<4;i++) gpp_regs[i] <= 0 ;
     else
       if (apb_wr_reg) gpp_regs[reg_idx] <= apb.pwdata  ;     // write only once 

     
 // REGS WRITE VALID PULSE
 always_comb begin
  host_regs_valid_pulse_d[3:0] = 32'b0 ;  
  if (apb_wr_reg) host_regs_valid_pulse_d[reg_idx] = 1'b1 ;
 end
        
 always @(posedge clk, negedge sys_rst_n)
     if(~sys_rst_n) host_regs_valid_pulse <= 32'b0 ;
     else host_regs_valid_pulse <= host_regs_valid_pulse_d ;
     
 // REGS SYNCHRONOUS READ
 assign regs_rd_access = apb_setup_rd && is_gpp_reg_addr && !ready ;
 always @(posedge clk)
   if  (regs_rd_access) begin // As long as valid is asserted the provided value is read, otherwise the APB recent written value.
     if (gpp_regs_valid_out[reg_idx]) regs_rd_data_out <= gpp_regs_data_out[reg_idx] ;
     else regs_rd_data_out <= gpp_regs[reg_idx] ; 
   end 
        
 // indicate regs read output  
 always @(posedge clk, negedge sys_rst_n) 
     if (~sys_rst_n) is_regs_data_out <= 0 ;
     else is_regs_data_out <= regs_rd_access ;
       
 //=====================================================
 
 // APB Memory access 

assign soc_ddr_buf_rd  = apb_setup_rd && is_gpp_ddr_buf_addr && !ready; 
assign soc_ddr_buf_wr  = apb_setup_wr && is_gpp_ddr_buf_addr && !ready;

assign soc_ddr_data_in = apb.pwdata ; 
  
//=====================================================

// apb.prdata output mux 
`ifdef DDR_INTRFC  
assign apb.prdata = is_regs_data_out ? regs_rd_data_out : soc_ddr_data_out ;
`else
assign apb.prdata = is_regs_data_out ? regs_rd_data_out : 0 ;
`endif


//====================================================

// READY HANDLING
always @(posedge clk, negedge sys_rst_n) 
    if(~sys_rst_n) 
      ready <= 0 ;
    else 
      ready <= apb.psel ;
      
assign apb.pready = ready && apb.penable ;

// ERROR HANDLING
assign apb.pslverr = 1'b0; // not supporting transfer failure

//========================================================
 
// Regs NOT provided from GPP side

assign gpp_regs_valid_out[1] = 0 ; // ddr cmd
assign gpp_regs_valid_out[3] = 0 ; // currently unused

//========================================================
 
// Hook SOC-DDR control status registers

assign soc_ddr_cmd = gpp_regs[1] ; 
assign soc_ddr_cmd_valid = host_regs_valid_pulse[1] ;

`ifdef DDR_INTRFC
 assign gpp_regs_data_out[2] = soc_ddr_status ;
`else
 assign gpp_regs_data_out[2] = 0 ;
`endif

assign gpp_regs_valid_out[2] = 1 ; //  soc_ddr_status permanently valid for read
  

  
  
//========================================================= 
  
//FPGNIX General Control reg

logic [1:0] sw_reset_trig_pulse; 
logic msys_sw_rst; 
logic [15:0] rst_dly_cyc_cnt ; 
logic rst_dly_cnt_active ; 


logic [31:0] gpp_fpgnix_ctl_reg; 
logic gpp_fpgnix_ctl_reg_valid_pulse ;
assign gpp_fpgnix_ctl_reg  = gpp_regs[0] ; 
assign gpp_fpgnix_ctl_reg_valid_pulse = host_regs_valid_pulse[0] ;    


// Handle FPGNIX control reg
always @(posedge clk or negedge sys_rst_n)
    if (!sys_rst_n) begin
        jtag_sel <= 1'b1; // 0 - uart ; 1 - jtag
        sw_reset_trig_pulse <= 2'b0;
        enable_core <= 1'b1;
    end else if (gpp_fpgnix_ctl_reg_valid_pulse) begin
        jtag_sel <= gpp_fpgnix_ctl_reg[0];
        sw_reset_trig_pulse <= gpp_fpgnix_ctl_reg[5:4];
        enable_core <= gpp_fpgnix_ctl_reg[8];
    end else begin
        sw_reset_trig_pulse <= 2'b0; //sw_reset_trig_pulse is pulse - goes high during write cycle only
    end
    
logic [31:0] fpgnix_ctrl_reg_dout ; 
assign fpgnix_ctrl_reg_dout = {4'b0, 4'b0, 4'b0, 4'b0, 4'b0, {3'b0, enable_core}, {2'b0, sw_reset_trig_pulse}, {3'b0, jtag_sel}};    
assign gpp_regs_data_out[0] = fpgnix_ctrl_reg_dout ;
assign gpp_regs_valid_out[0] = 1 ; // fpgnix_ctrl_reg_dout permanently valid for read

assign sw_reset[1] = sw_reset_trig_pulse[1] ; // No delayed reset on sw_rst[1] , assumed debug interface related
    
// postponed sw_reset such the the smart uart transaction is well accomplished before the assertion.

localparam SW_DLY_NUM_CYC = 16'd50000 ; // TODO provide as a parameter over the gpp control reg.

always @(posedge clk or negedge sys_rst_n)
    if (!sys_rst_n) begin
       msys_sw_rst <= 0 ;
       rst_dly_cyc_cnt <= 16'b0 ;
       rst_dly_cnt_active <= 0 ;           
    end else begin
       if (sw_reset_trig_pulse[0]) rst_dly_cnt_active <= 1 ;
       else if (rst_dly_cyc_cnt==SW_DLY_NUM_CYC) begin
         rst_dly_cnt_active <= 0 ;
         rst_dly_cyc_cnt <= 16'b0 ;
         msys_sw_rst <= 1 ;
       end else if (rst_dly_cnt_active) rst_dly_cyc_cnt <= rst_dly_cyc_cnt + 1 ;
       else msys_sw_rst <= 0 ;             
    end

assign sw_reset[0] = msys_sw_rst ;


endmodule

