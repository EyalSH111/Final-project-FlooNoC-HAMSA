`timescale 1 ns/ 1 ps


//`include "../system/system_config_defines.vh"
//Defined above
//`define MSYSTEM_ONLY
//`define ALTERA  
//`define XILINX  
//`define NOFLASH 

module flash_boot (
input 	wire		sys_clk	   		, 
input 	wire		sys_rst	   		,
input	wire		system_mem_rdy	,
output	reg			system_rdy		,
		//Interface to flash controller
output	reg			o_flash_cycle	,
output	reg	[31:0]	o_flash_addr	,
input	wire		i_flash_ack		,
input	wire [31:0]	i_flash_data	,
		//simple ram if
output 	reg  [21:0]	init_ram_addr	,
output 	reg  [31:0]	init_ram_data   ,
output 	wire 		init_ram1_wr  	,
output 	wire 		init_ram2_wr  	,
output 	wire 		init_ram3_wr  	,
output 	wire 		init_ram4_wr	,
output 	wire 		init_ram5_wr	,
output 	wire 		init_ram6_wr	,
output 	wire 		init_ram7_wr	,
output 	wire 		init_ram8_wr	,
output 	wire 		init_ram9_wr	,

output 	wire 		init_main_wr  	
		);

//`include "../system/memory_configuration.vh"

`ifdef SIM
parameter WAIT_CNTR = 8 ;
`else
parameter WAIT_CNTR = 15 ;
`endif

reg [1:0]			flash_sm ;
reg		 			start_load ;
reg [WAIT_CNTR-1:0]	wait_cntr ;

reg	 		init_ram1_wr_i  ;
reg	 		init_ram2_wr_i  ;
reg	 		init_ram3_wr_i  ;
reg	 		init_ram4_wr_i  ;
reg	 		init_ram5_wr_i  ;
reg	 		init_ram6_wr_i  ;
reg	 		init_ram7_wr_i  ;
reg	 		init_ram8_wr_i  ;
reg	 		init_ram9_wr_i  ;
reg	 		init_main_wr_i  ;

wire block_write ;
`ifdef NOFLASH
	assign block_write = 1'b0 ;
	initial begin
		$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		$write("Warning: Flash boot is disabled for simulation please remove BLOCK_FLASH_LOAD in system_config_defines.vh \n");
		$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		end
`else
	assign block_write = 1'b1 ;
`endif

//No block writes if skipping flash load
assign init_ram1_wr = init_ram1_wr_i &&  block_write ;
assign init_ram2_wr = init_ram2_wr_i &&  block_write ;
assign init_ram3_wr = init_ram3_wr_i &&  block_write ;
assign init_ram4_wr = init_ram4_wr_i &&  block_write ;
assign init_ram5_wr = init_ram5_wr_i &&  block_write ;
assign init_ram6_wr = init_ram6_wr_i &&  block_write ;
assign init_ram7_wr = init_ram7_wr_i &&  block_write ;
assign init_ram8_wr = init_ram8_wr_i &&  block_write ;
assign init_ram9_wr = init_ram9_wr_i &&  block_write ;
assign init_main_wr = init_main_wr_i &&  block_write ;

parameter START_BOOT1= 32'h0000_0000 ; //0000-8000 32 KBytes   256Kbit
parameter END_BOOT1  = 32'h0000_3ffc ; //0000-3fff shrink to end after 16 KBytes 128Kbit
parameter START_BOOT2= 32'h0000_8000 ; //8000-a000 8  KBytes   64Kbit
parameter END_BOOT2  = 32'h0000_8ffc ; //8000-8fff shrink to end after 4  KBytes   32Kbit
parameter START_BOOT3= 32'h0000_a000 ; //a000-c000 8  KBytes   64Kbit
parameter END_BOOT3  = 32'h0000_a004 ; //8000-a000 8  KBytes   64Kbit
parameter START_MAIN = 32'h0000_c000 ; //c000-d000 4  KBytes   32Kbit
parameter END_MAIN   = 32'h0000_c004 ; //8000-a000 8  KBytes   64Kbit
//parameter END_MAIN   = 32'h0001_e000 ;
parameter START_CO1  = 32'h0000_d000 ; //d000-d100 256 Bytes   2Kbit
parameter START_CO2  = 32'h0000_d100 ; //d000-d100 256 Bytes   2Kbit
parameter START_CO3  = 32'h0000_d200 ; //d000-d100 256 Bytes   2Kbit
parameter START_CO4  = 32'h0000_d300 ; //d000-d100 256 Bytes   2Kbit
parameter START_CO5  = 32'h0000_d400 ; //d000-d100 256 Bytes   2Kbit
parameter START_CO6  = 32'h0000_d500 ; //d000-d100 256 Bytes   2Kbit
parameter ENO_ALL    = 32'h0000_d600 ; 
                                       // Total 53.5KBytes     428Kbit      

parameter RESET_ST	= 2'b00 ;
parameter IDLE_ST   = 2'b01 ;
parameter WAIT_ACK	= 2'b11 ;
parameter DONE_ST	= 2'b10 ;



always @( posedge sys_clk or posedge sys_rst)
	if (sys_rst) begin
		start_load <=#1 1'b0 ;
		wait_cntr  <=#1 {WAIT_CNTR{1'b1}} ;
		end
	else begin
		if (wait_cntr != 'd0) wait_cntr <=#1 wait_cntr - 1'b1 ; 
		start_load <=#1 (wait_cntr == 'd0) ;    
		end


always @( posedge sys_clk or posedge sys_rst)
	if (sys_rst) begin
		flash_sm 		<=#1 RESET_ST ;
		o_flash_addr 	<=#1 'd0 ;
		o_flash_cycle	<=#1 'd0 ;
		init_ram1_wr_i 	<=#1 1'b0 ;
		init_ram2_wr_i 	<=#1 1'b0 ;
		init_ram3_wr_i 	<=#1 1'b0 ;
		init_ram4_wr_i 	<=#1 1'b0 ;
		init_ram5_wr_i 	<=#1 1'b0 ;
		init_ram6_wr_i 	<=#1 1'b0 ;
		init_ram7_wr_i 	<=#1 1'b0 ;
		init_ram8_wr_i 	<=#1 1'b0 ;
		init_ram9_wr_i 	<=#1 1'b0 ;
		init_main_wr_i 	<=#1 1'b0 ;
		init_ram_addr   <=#1 'd0 ;
		init_ram_data	<=#1 'd0 ;
		system_rdy		<=#1 1'b0 ;
		end
	else begin
		case (flash_sm)
			RESET_ST: begin
				if (start_load && system_mem_rdy) flash_sm <=#1 IDLE_ST ;
				o_flash_addr 	<=#1 'd0 ;
				end
			IDLE_ST: begin
				o_flash_cycle	<=#1 1'b1 ;
				init_ram1_wr_i 	<=#1 1'b0 ;
				init_ram2_wr_i 	<=#1 1'b0 ;
				init_ram3_wr_i 	<=#1 1'b0 ;
				init_ram4_wr_i 	<=#1 1'b0 ;
				init_ram5_wr_i 	<=#1 1'b0 ;
				init_ram6_wr_i 	<=#1 1'b0 ;
				init_ram7_wr_i 	<=#1 1'b0 ;
				init_ram8_wr_i 	<=#1 1'b0 ;
				init_ram9_wr_i 	<=#1 1'b0 ;
				init_main_wr_i 	<=#1 1'b0 ;
				`ifdef NOFLASH
					flash_sm		<=#1 DONE_ST ;
					$display("Booting without flash, not for synthesis");
				`else
					flash_sm 		<=#1 WAIT_ACK ;
				`endif
				end
			WAIT_ACK: begin
				if (i_flash_ack) begin
					o_flash_cycle	<=#1 1'b0 ;
          if (o_flash_addr==END_BOOT1) o_flash_addr <=#1 START_BOOT2 ;
          else if (o_flash_addr==END_BOOT2) o_flash_addr <=#1 START_BOOT3 ;
          else if (o_flash_addr==END_BOOT3) o_flash_addr <=#1 START_MAIN ;
          else if (o_flash_addr==END_MAIN)  o_flash_addr <=#1 START_CO1 ;
          else o_flash_addr 	<=#1 o_flash_addr + 'd4 ;
					init_ram_data   <=#1 i_flash_data ;
					if (o_flash_addr<START_BOOT2) begin
						init_ram1_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] ;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_BOOT3) begin
						init_ram2_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] ;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_MAIN) begin
						init_ram3_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] ;
						flash_sm 		<=#1 IDLE_ST ;
						//system_rdy 		<=#1 1'b1 ;
						end      
					else if (o_flash_addr<START_CO1) begin  //Write main
						init_main_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 (o_flash_addr[23:2] - START_MAIN[23:2]) ;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_CO2) begin  //Write Coprocessor 1
						init_ram4_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] & 22'h00007f;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_CO3) begin  //Write Coprocessor 2
						init_ram5_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] & 22'h00007f;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_CO4) begin  //Write Coprocessor 3
						init_ram6_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] & 22'h00007f;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_CO5) begin  //Write Coprocessor 4
						init_ram7_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] & 22'h00007f;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<START_CO6) begin  //Write Coprocessor 5
						init_ram8_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] & 22'h00007f;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else if (o_flash_addr<ENO_ALL) begin  //Write Coprocessor 6
						init_ram9_wr_i  <=#1 1'b1 ;
						init_ram_addr   <=#1 o_flash_addr[23:2] & 22'h00007f;
						flash_sm 		<=#1 IDLE_ST ;
						end      
					else begin
						flash_sm 		<=#1 DONE_ST ;
						end
					end
				else flash_sm	<=#1 WAIT_ACK ;
				end
			DONE_ST: begin
				o_flash_cycle	<=#1 1'b0 ;
				flash_sm 		<=#1 DONE_ST ;
				init_ram1_wr_i 	<=#1 1'b0 ;
				init_ram2_wr_i 	<=#1 1'b0 ;
				init_ram3_wr_i 	<=#1 1'b0 ;
				init_ram4_wr_i 	<=#1 1'b0 ;
				init_ram5_wr_i 	<=#1 1'b0 ;
				init_ram6_wr_i 	<=#1 1'b0 ;
				init_ram7_wr_i 	<=#1 1'b0 ;
				init_ram8_wr_i 	<=#1 1'b0 ;
				init_ram9_wr_i 	<=#1 1'b0 ;
				init_main_wr_i	<=#1 1'b0 ;
				system_rdy 		<=#1 1'b1 ;
				end
			endcase
			end	

endmodule
