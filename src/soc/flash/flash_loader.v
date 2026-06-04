`timescale 1 ns/ 1 ps
`include "../system/system_config_defines.vh"
`include "../../pulpenix_defines.v"

module flash_loader (
input 	wire		sys_clk	   		, 
input 	wire		sys_rst	   		,
input	wire		system_mem_rdy	,
output	reg			system_rdy		,
		//Interface to flash controller
output 	reg			flash_cs  		, 
output 	wire		flash_sck		, 
//inout 	wire		flash_si   		,
//inout 	wire		flash_so_io1	,
output 	wire		flash_si   		,
output 	wire		flash_so_io1	,
inout 	reg			flash_hold_io3	, 
inout 	wire		flash_acc_io2	,
		//simple ram if
output 	wire [21:0]	init_ram_addr	,
output 	wire [31:0]	init_ram_data   ,
output 	wire 		init_ram1_wr  	,
output 	wire 		init_ram2_wr  	,
output 	wire 		init_ram3_wr  	,
output 	wire 		init_main_wr  	
		);


reg	 		init_ram1_wr_i  ;
reg	 		init_ram2_wr_i  ;
reg	 		init_ram3_wr_i  ;
reg	 		init_main_wr_i  ;

`include "../system/memory_configuration.vh"

`ifdef SIM
parameter WAIT_CNTR = 8 ;
`else
parameter WAIT_CNTR = 15 ;
`endif

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
assign init_main_wr = init_main_wr_i &&  block_write ;

`ifdef NOFLASH
initial begin
	$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
	$write("Warning: INTERNAL BOOT for simulation is on please remove INTERNAL_BOOT in system_config_defines.vh \n");
	$display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
	end
`endif






reg		 			start_load ;
reg [WAIT_CNTR-1:0]	wait_cntr ;

reg 		clock_enable ;
reg			flash_dir ;
reg	[31:0] 	bits2read ;
reg [39:0]	load_sr ;	
reg [ 4:0]	flash_sm ;
reg [ 5:0]	bit_count ;

always @( posedge sys_clk or posedge sys_rst)
	if (sys_rst) begin
		start_load <=#1 1'b0 ;
		wait_cntr  <=#1 {WAIT_CNTR{1'b1}} ;
		end
	else begin
		if (wait_cntr != 'd0) wait_cntr <=#1 wait_cntr - 1'b1 ;
		start_load <=#1 (wait_cntr == 'd0) ;
		end

//4 last numbers are:
//1) Address Byte Cycles
//2) Mode bit cycles
//3) Dummy Byte cycles
//4) Data Byte cycles
//Read
parameter READ 		= 8'h03 ; //00000011 Read Data bytes 								3 0 0 1 to inf
parameter FAST_READ	= 8'h0B ; //00001011 Read Data bytes at Fast Speed 					3 0 1 1 to inf
parameter DOR 		= 8'h3B ; //00111011 Dual Output Read 								3 0 1 1 to inf
parameter QOR 		= 8'h6B ; //01101011 Quad Output Read 								3 0 1 1 to inf
parameter DIOR 		= 8'hBB ; //10111011 Dual I/O High Performance Read 				3 1 0 1 to inf
parameter QIOR 		= 8'hEB ; //11101011 Quad I/O High Performance Read 				3 1 2 1 to inf
parameter RDID 		= 8'h9F ; //10011111 Read Identification 							0 0 0 1 to 81
parameter READ_ID	= 8'h90 ; //10010000 Read Manufacturer and Device Identification 	3 0 0 1 to inf
//Write Control
parameter WREN 		= 8'h06 ; //00000110 Write Enable 									0 0 0 0
parameter WRDI 		= 8'h04 ; //00000100 Write Disable 									0 0 0 0
//Erase
parameter P4E 		= 8'h20 ; //00100000 4-KB Parameter Sector Erase 					3 0 0 0
parameter P8E 		= 8'h40 ; //01000000 8-KB (two 4KB) Parameter Sector Erase 			3 0 0 0
parameter SE  		= 8'hD8 ; //11011000 64-KB Sector Erase 							3 0 0 0
parameter BE  		= 8'h60 ; //01100000 or (C7h) 1100 0111 Bulk Erase 					0 0 0 0
//Program
parameter PP  		= 8'h02 ; //00000010 Page Programming 								3 0 0 1 to 256
parameter QPP 		= 8'h32 ; //00110010 Quad Page Programming 							3 0 0 1 to 256
//Status & Configuration Register
parameter RDSR 		= 8'h05 ; //00000101 Read Status Register 							0 0 0 1 to inf
parameter WRR  		= 8'h01 ; //00000001 Write (Status & Configuration) Register 		0 0 0 1 to inf
parameter RCR  		= 8'h35 ; //00110101 Read Configuration Register (CFG) 				0 0 0 1 to inf
parameter CLSR 		= 8'h30 ; //00110000 Reset the Erase and Program Fail Flag 
							  //		 (SR5 and SR6) and restore normal operation) 	0 0 0 0
//Power Saving
parameter DP  		= 8'hB9 ; //10111001 Deep Power-Down 								0 0 0 0
parameter RES 		= 8'hAB ; //10101011 Release from Deep Power-Down Mode 				0 0 0 0
							  //      or Release from Deep Power-Down and 
							  //		 Read Electronic Signature 						0 0 3 1 to inf
//OTP
parameter OTPP 		= 8'h42 ; //01000010 Program one byte of data in OTP memory space 	3 0 0 1
parameter OTPR 		= 8'h4B ; //01001011 Read data in the OTP memory space 				3 0 1 1 to inf

parameter START_BOOT= 24'h000000 ; //First read address
//`ifdef SIM
//reg [31:0] BOOT_SIZE = 4095 ; //Last address of each internal ram
//parameter  BOOT_BITS = BOOT_MSB-2   ; //Number of bits per each internal ram. Reducing 2 to transfer worsds to bytes
//parameter  BOOT_MAX  = {{8{1'b0}},{(BOOT_BITS-8){1'b1}}} ;
//`else
parameter  BOOT_SIZE = 4095 ;  //Last address of each internal ram
parameter  BOOT_BITS = BOOT_MSB-1   ; //Number of bits per each internal ram. Reducing 2 to transfer worsds to bytes
parameter  BOOT_MAX  = {BOOT_BITS{1'b1}} ;
parameter  BOOT_FIX_ADDR = 2 ;
//`endif

parameter  MAIN_BITS = MAIN_MSB-1   ; //Number of bits per each internal ram. Reducing 2 to transfer worsds to bytes
parameter  MAIN_FIX_ADDR = 4 ;


parameter RESET_ST				= 5'b0_0000 ;
parameter IDLE_ST   			= 5'b0_0100 ;
parameter BOOT_ST				= 5'b0_0001 ;
parameter BOOT_CMD_ST			= 5'b0_0010 ;
parameter BOOT_RD_ST			= 5'b0_0110 ;
parameter MAIN_RD_ST			= 5'b0_1110 ;
parameter WR_EN_ST				= 5'b0_0011 ;
parameter BULK_ERASE_ST			= 5'b0_0101 ;
parameter CMD_ONLY_ST			= 5'b0_0111 ;
parameter WAIT_FINISH_ST		= 5'b0_1111 ;
parameter FINISH_CMD_ST			= 5'b0_1101 ;
parameter WAIT_FINISH_DONE_ST 	= 5'b0_1100 ;

assign init_ram_addr = bits2read[26:5] - 1'b1;
assign init_ram_data = load_sr[31:0] ;
assign flash_sck = clock_enable ? !sys_clk : 1'b0 ;
//assign flash_si = flash_dir ? 1'bz : load_sr[39] ;
assign flash_si = load_sr[39] ;


always @( posedge sys_clk or posedge sys_rst)
	if (sys_rst) begin
		flash_sm 		<=#1 RESET_ST ;
		bit_count 		<=#1 6'd40 ;
		clock_enable 	<=#1 1'b0  ;
		flash_cs		<=#1 1'b1  ;
		load_sr[39:0]	<=	 40'd0 ;
		bits2read		<=#1 32'd0 ;
		init_ram1_wr_i 	<=#1 1'b0  ;
		init_ram2_wr_i 	<=#1 1'b0  ;
		init_ram3_wr_i 	<=#1 1'b0  ;
		init_main_wr_i	<=#1 1'b0 ;
		flash_dir		<=#1 1'b0  ;
		system_rdy		<=#1 1'b0  ;
		end
	else begin
		case (flash_sm)
			RESET_ST: begin
				if (start_load && system_mem_rdy) flash_sm <=#1 BOOT_ST ;
				end
			IDLE_ST: begin
				bit_count 		<=#1 6'd40 ;
				clock_enable 	<=#1 1'b0  ;
				flash_cs		<=#1 1'b1  ;
				load_sr[39:0]	<=#1 40'd0 ;
				bits2read		<=#1 32'd0 ;
				init_ram1_wr_i	<=#1 1'b0  ;
				init_ram2_wr_i	<=#1 1'b0  ;
				init_ram3_wr_i	<=#1 1'b0  ;
				init_main_wr_i	<=#1 1'b0 ;
				flash_sm 		<=#1 IDLE_ST ;
				flash_dir		<=#1 1'b0  ;
				end
			BOOT_ST: begin
				bit_count 		<=#1 6'd39 ; //1 command, 3 address, 1 dummy
				clock_enable 	<=#1 1'b1 ;
				flash_cs		<=#1 1'b0 ;
				load_sr[39:0]	<=#1 {FAST_READ[7:0],START_BOOT[23:0],8'h55} ;
				`ifdef NOFLASH
				flash_sm		<=#1 IDLE_ST ;
				$display("Booting without flash, not for synthesis");
				system_rdy		<=#1 1'b1  ;
				`else
				flash_sm		<=#1 BOOT_CMD_ST ;
				`endif
				end
			BOOT_CMD_ST: begin
				if (bit_count==0) begin
					bit_count 		<=#1 6'd0 ; //1 command, 3 address, 1 dummy
					clock_enable 	<=#1 1'b1 ;
					flash_cs		<=#1 1'b0 ;
					load_sr			<=#1 {load_sr[38:0],1'b0} ;
					flash_sm		<=#1 BOOT_RD_ST ;
					bits2read		<=#1 32'd0 ;
					flash_dir		<=#1 1'b1 ;
					end
				else begin
					bit_count 		<=#1 bit_count - 1'b1 ; 
					clock_enable 	<=#1 1'b1 ;
					flash_cs		<=#1 1'b0 ;
					load_sr			<=#1 {load_sr[38:0],1'b0} ;
					flash_sm		<=#1 BOOT_CMD_ST ;
					end
				end
			BOOT_RD_ST: begin
				if (bits2read==({2'b10,{BOOT_BITS{1'b1}},5'b11111})) begin	//2 bits for system 1-3, boot_bits for ram and 5 bits for 32bit word
					bits2read		<=#1 'd0 ;
//					clock_enable 	<=#1 1'b0 ;
//					flash_cs		<=#1 1'b1 ;
					//flash_sm		<=#1 IDLE_ST ;
					flash_sm		<=#1 MAIN_RD_ST ;
//					flash_dir		<=#1 1'b0  ;
//					system_rdy		<=#1 1'b1  ;
					end
				else begin
					bits2read		<=#1 bits2read + 1'b1 ;
					clock_enable 	<=#1 1'b1 ;
					flash_cs		<=#1 1'b0 ;
					flash_sm		<=#1 BOOT_RD_ST ;
					load_sr			<=#1 {load_sr[38:0],flash_so_io1} ;
					end
				if (bits2read[4:0]==5'h1f && bits2read[BOOT_BITS+6:BOOT_BITS+5]==2'b00 && bits2read[BOOT_BITS+4:5]<=({BOOT_BITS{1'b1}}-BOOT_FIX_ADDR)) 
					init_ram1_wr_i		<=#1 1'b1 ;
				else
					init_ram1_wr_i		<=#1 1'b0 ;
				if (bits2read[4:0]==5'h1f && bits2read[BOOT_BITS+6:BOOT_BITS+5]==2'b01 && bits2read[BOOT_BITS+4:5]<=({BOOT_BITS{1'b1}}-BOOT_FIX_ADDR)) 
					init_ram2_wr_i		<=#1 1'b1 ;
				else
					init_ram2_wr_i		<=#1 1'b0 ;
				if (bits2read[4:0]==5'h1f && bits2read[BOOT_BITS+6:BOOT_BITS+5]==2'b10 && bits2read[BOOT_BITS+4:5]<=({BOOT_BITS{1'b1}}-BOOT_FIX_ADDR)) 
					init_ram3_wr_i		<=#1 1'b1 ;
				else
					init_ram3_wr_i		<=#1 1'b0 ;
				end
			MAIN_RD_ST: begin
				if (bits2read==({2'b00,{MAIN_BITS{1'b1}},5'b00000})) begin
					bits2read		<=#1 'd0 ;
					clock_enable 	<=#1 1'b0 ;
					flash_cs		<=#1 1'b1 ;
					flash_sm		<=#1 IDLE_ST ;
					flash_dir		<=#1 1'b0  ;
					system_rdy		<=#1 1'b1  ;
					end
				else begin
					bits2read		<=#1 bits2read + 1'b1 ;
					clock_enable 	<=#1 1'b1 ;
					flash_cs		<=#1 1'b0 ;
					flash_sm		<=#1 MAIN_RD_ST ;
					load_sr			<=#1 {load_sr[38:0],flash_so_io1} ;
					end
				if (bits2read[4:0]==5'h1f && bits2read[MAIN_BITS+4:5]<=({MAIN_BITS{1'b1}}-MAIN_FIX_ADDR)) 
					init_main_wr_i		<=#1 1'b1 ;
				else
					init_main_wr_i		<=#1 1'b0 ;
				end
			WR_EN_ST: begin
				bit_count 		<=#1 6'd8 ; //1 command, 3 address, 1 dummy
				clock_enable 	<=#1 1'b1 ;
				flash_cs		<=#1 1'b0 ;
				load_sr[39:0]	<=#1 {WREN[7:0],START_BOOT[23:0],8'h55} ;
				flash_sm		<=#1 CMD_ONLY_ST ;
				end
			BULK_ERASE_ST: begin
				bit_count 		<=#1 6'd8 ; //1 command, 3 address, 1 dummy
				clock_enable 	<=#1 1'b1 ;
				flash_cs		<=#1 1'b0 ;
				load_sr[39:0]	<=#1 {BE[7:0],START_BOOT[23:0],8'h55} ;
				flash_sm		<=#1 CMD_ONLY_ST ;
				end
			CMD_ONLY_ST: begin
				if (bit_count==0) begin
					bit_count		<=#1 'd0 ;
					clock_enable 	<=#1 1'b0 ;
					flash_cs		<=#1 1'b1 ;
					flash_sm		<=#1 WAIT_FINISH_ST ;
				end
				else begin
					bit_count		<=#1 bit_count - 1'b1 ;
					clock_enable 	<=#1 1'b0 ;
					flash_cs		<=#1 1'b1 ;
					flash_sm		<=#1 CMD_ONLY_ST ;
					load_sr			<=#1 {load_sr[38:0],flash_so_io1} ;	//lsb on right has no meaning 
					end
				end
			WAIT_FINISH_ST: begin
				bit_count 		<=#1 6'd8 ; //1 command, 3 address, 1 dummy
				clock_enable 	<=#1 1'b1 ;
				flash_cs		<=#1 1'b0 ;
				load_sr[39:0]	<=#1 {RDSR[7:0],START_BOOT[23:0],8'h55} ;
				flash_sm		<=#1 FINISH_CMD_ST ;
				end
			FINISH_CMD_ST: begin
				bit_count		<=#1 bit_count - 1'b1 ;
				clock_enable 	<=#1 1'b0 ;
				flash_cs		<=#1 1'b1 ;
				load_sr			<=#1 {load_sr[38:0],flash_so_io1} ;
				if (bit_count==0) begin
					flash_sm		<=#1 WAIT_FINISH_DONE_ST ;
					flash_dir		<=#1 1'b1  ;
					end
				end
			WAIT_FINISH_DONE_ST: begin
				bit_count		<=#1 bit_count - 1'b1 ;
				clock_enable 	<=#1 1'b0 ;
				flash_cs		<=#1 1'b1 ;
				load_sr			<=#1 {load_sr[38:0],flash_so_io1} ;
				if (bit_count[2:0]==3'b000) begin
					if (load_sr[0]==1'b0) flash_sm	<=#1 IDLE_ST ;
					flash_dir		<=#1 1'b0  ;
					end
				end
			endcase
			end	


endmodule