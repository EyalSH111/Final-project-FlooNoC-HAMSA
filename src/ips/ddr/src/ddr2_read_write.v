//Author qiu bin 
//Email : chat1@126.dom

module ddr2_read_write # (    
    parameter DDR_ADDR_WIDTH = 26,
    parameter DDR_DATA_WIDTH = 128
) (

// Interface to DDR PHY

input                        phy_clk,
input                        rst_n,
input                        local_init_done,
output [DDR_ADDR_WIDTH-1:0]  local_address,
output                       local_burstbegin,
input                        local_ready,
output                       local_read_req,
input  [DDR_DATA_WIDTH-1:0]  local_rdata,
input                        local_rdata_valid,
output                       local_write_req,
output [DDR_DATA_WIDTH-1:0]  local_wdata,
output                       led,

// SOC System Interface

input         soc_clk,              // soc system clock
input         soc_rst_n,            // soc system reset
    
// Command/Status

input  [31:0] soc_ddr_cmd,          // Command to ddr interface to store or load buffer , inducing DDR memory address
input         soc_ddr_cmd_valid,    // pulse indicating command is valid.
output [31:0] soc_ddr_status,       // returned status, zero means not valid, changes to 0 upon sys_ddr_cmd_valid

// Buffer direct Access
input   [1:0] soc_ddr_data_buf_idx, // 4 X 32b words buffer
input         soc_ddr_buf_wr,       // Write to buffer pulse
input         soc_ddr_buf_rd,       // Read from buffer pulse    
input  [31:0] soc_ddr_data_in,      // input to buffer
output [31:0] soc_ddr_data_out      // output from buffer    
);

 // SOC SIDE BUFFER/STATUS ACCESS 
 
 logic [3:0][31:0] soc_ddr_buf ;
 logic [31:0] soc_ddr_buf_dout ;
  
  wire ddr_rdata_soc_avail_pulse ;
  logic [DDR_DATA_WIDTH-1:0]  ddr_rdata_phy_s ;  // returned local_rdata sampled by phy_clk
  
 // SOC/PHY WRITE TO BUFFER
 always @(posedge soc_clk, negedge soc_rst_n) begin
   if (~soc_rst_n) soc_ddr_buf <= 128'b0 ;
   else begin
     if (ddr_rdata_soc_avail_pulse) soc_ddr_buf <= ddr_rdata_phy_s ;
     else if (soc_ddr_buf_wr) soc_ddr_buf[soc_ddr_data_buf_idx] <= soc_ddr_data_in ;
   end 
 end 
 
 // SOC READ FROM
 always @(posedge soc_clk, negedge soc_rst_n) begin
   if (~soc_rst_n) soc_ddr_buf_dout <= 32'b0 ;
   else if (soc_ddr_buf_rd) soc_ddr_buf_dout <= soc_ddr_buf[soc_ddr_data_buf_idx];
 end 
 
 assign soc_ddr_data_out = soc_ddr_buf_dout ;
 
 // END OF TMP BUFFER/STATUS ACCESS O
 
 //  Should exactly match ddr_lib.c 
 enum logic [3:0] {SOC_CMD_STORE, SOC_CMD_LOAD} soc_cmd ;   
 enum logic [1:0] {DDR_INIT, DDR_IDLE, DDR_WRITE, DDR_READ} state ;
 
 `ifdef DDR_INTRFC
 
 reg  [DDR_ADDR_WIDTH-1:0]  ddr_addr_out;  // external ddr port address out
 reg  [DDR_DATA_WIDTH-1:0]  ddr_data_out;  // external ddr portd ata out
 
 reg  ddr_rdata_phy_avail ;
 reg  ddr_rdata_soc_taken_phy_pulse ;
 reg  ddr_rdata_soc_avail ;
 reg  ddr_rdata_soc_avail_s ;
 reg  ddr_rdata_soc_taken_phy ;
 reg  ddr_rdata_soc_taken_phy_s ;
 
 wire ddr_wr_finished;
 wire ddr_rd_finished;
 
 wire ddr_write_cond ;
 wire ddr_read_cond ;
 
 // Sync returned local_rdata to soc clock (TODO: inefficient full handshake , should be replaced with FIFO or so)
 
 always @(posedge phy_clk or negedge rst_n) 
  if (!rst_n) begin 
    ddr_rdata_phy_s <= {DDR_DATA_WIDTH{1'b0}};
    ddr_rdata_phy_avail <= 0 ;
  end else begin
    if (ddr_rd_finished) begin  
       ddr_rdata_phy_s <= local_rdata ;
       ddr_rdata_phy_avail <= 1 ;
    end
    ddr_rdata_soc_taken_phy <= ddr_rdata_soc_avail ;
    ddr_rdata_soc_taken_phy_s <= ddr_rdata_soc_taken_phy ;
    if (ddr_rdata_soc_taken_phy_pulse) ddr_rdata_phy_avail <= 0 ;
  end
    
 assign ddr_rdata_soc_taken_phy_pulse = !ddr_rdata_soc_taken_phy_s && ddr_rdata_soc_taken_phy ;
  
 always @(posedge soc_clk or negedge soc_rst_n) 
  if (!rst_n) begin  
     ddr_rdata_soc_avail <= 0 ;
     ddr_rdata_soc_avail_s <= 0 ;
  end else begin
     ddr_rdata_soc_avail <= ddr_rdata_phy_avail  ;
     ddr_rdata_soc_avail_s <= ddr_rdata_soc_avail ;    
  end 
 assign ddr_rdata_soc_avail_pulse =!ddr_rdata_soc_avail_s && ddr_rdata_soc_avail ; 

 assign ddr_addr_out = soc_ddr_cmd[DDR_ADDR_WIDTH-1:0] ;
 assign soc_cmd = soc_ddr_cmd[31:28] ;

 // End of Sync returned

 assign soc_ddr_status = {28'b0,state} ; // TODO !!! Need to synchronize between phy_clk and soc_clk domains !


 // Primitive Sync soc_ddr_cmd_valid pulse to phy_clk domain
 // For now Assuming phy_clk is always significantly faster than soc_clk
 
 reg soc_ddr_cmd_valid_sync_phy  ;
 reg soc_ddr_cmd_valid_sync_phy_s ;
 wire soc_ddr_cmd_valid_pulse_phy  ;
 
 always @(posedge phy_clk or negedge rst_n)
 if (rst_n == 0) begin
   soc_ddr_cmd_valid_sync_phy <= 0 ;
   soc_ddr_cmd_valid_sync_phy_s <= 0 ;  
 end else begin
  soc_ddr_cmd_valid_sync_phy <= soc_ddr_cmd_valid ;
  soc_ddr_cmd_valid_sync_phy_s <= soc_ddr_cmd_valid_sync_phy ; 
 end
 assign soc_ddr_cmd_valid_pulse_phy = soc_ddr_cmd_valid_sync_phy && !soc_ddr_cmd_valid_sync_phy_s ; 
  
 assign soc_ddr_status = {28'b0,state} ; 
 assign ddr_write_cond = (state==DDR_IDLE) && soc_ddr_cmd_valid_pulse_phy && (soc_cmd==SOC_CMD_STORE) ;
 assign ddr_read_cond  = (state==DDR_IDLE) && soc_ddr_cmd_valid_pulse_phy && (soc_cmd==SOC_CMD_LOAD) ;
 
 always @(posedge phy_clk or negedge rst_n)
 if (rst_n == 0)
	state <= DDR_INIT;
 else begin
	case (state)
    DDR_INIT : begin
	    if (local_init_done) begin
	    	state <= DDR_IDLE;
            //$display ("ddr2_read_write: state DDR_INIT -> DDR_IDLE") ;  
        end            
    end
	DDR_IDLE : begin
	    if (ddr_write_cond) begin
	    	state <= DDR_WRITE;
            //$display ("ddr2_read_write: state DDR_IDLE -> DDR_WRITE") ;  
        end
	    else if (ddr_read_cond) begin
	    	state <= DDR_READ;
            //$display ("ddr2_read_write: state DDR_IDLE -> DDR_READ") ;  
        end           
	end
	DDR_WRITE : begin
		if (ddr_wr_finished) begin
			state <= DDR_IDLE;
            //$display ("ddr2_read_write: state DDR_WRITE -> DDR_IDLE") ;             
        end
	end
	DDR_READ : begin
		if (ddr_rd_finished) begin
			state <= DDR_IDLE;
            //$display ("ddr2_read_write: state DDR_READ -> DDR_IDLE") ;                      
        end
	end
	default : state <= state;
	endcase
 end // always
 
 assign ddr_wr_finished = (state==DDR_WRITE)  && local_write_req && local_ready;
 assign ddr_rd_finished = (state==DDR_READ)   && local_rdata_valid;
 		
 assign local_address    = ddr_addr_out;
 assign local_burstbegin = ddr_write_cond || ddr_read_cond ;
 assign local_read_req   = (state==DDR_READ);
 assign local_write_req  = (state==DDR_WRITE);
 
 assign ddr_data_out = soc_ddr_buf;
 assign local_wdata  = ddr_data_out;
 
 assign led = 0 ; // Preserved for future use
 
 `else //  DDR_INTRFC not defined
 // Avoid 'X' when DDR Interface is excluded
 assign soc_ddr_status = {28'b0,DDR_IDLE} ; 
 assign ddr_rdata_soc_avail_pulse = 0 ;
 assign ddr_rdata_phy_s = {DDR_DATA_WIDTH{1'b0}} ; 
 `endif

endmodule





