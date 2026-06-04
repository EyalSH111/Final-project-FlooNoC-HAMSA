
// ********************************************************************************
// Roy's flash interface
// Instr/Data direct flash boot interface
// ********************************************************************************
//Defined above
//`define MSYSTEM_ONLY
//`define ALTERA  
//`define XILINX  
//`define NOFLASH 


module boot_flash_direct_intrfc 

  #( parameter DATA_RAM_SIZE        = 32768, // in bytes
     parameter INSTR_RAM_SIZE       = 32768 // in bytes
   ) (
   
    input               clk_int	,
    input               rstn_int ,
    
    output	wire [3:0]  o_qspi_dat ,
    input	wire [3:0]  i_qspi_dat ,
    output	wire	    o_qspi_cs_n ,
    output	wire 		o_qspi_sck	,
    output	wire [1:0]	o_qspi_mod ,

    output 	wire [21:0] init_ram_addr ,
    output 	wire [31:0] init_ram_data ,   
    output 	wire	    init_ram1_wr  ,
    output 	wire	    init_ram2_wr  ,
    output 	wire	    init_ram3_wr  ,
    output 	wire	    init_ram4_wr  ,
    output 	wire	    init_ram5_wr  ,
    output 	wire	    init_ram6_wr  ,
    output 	wire	    init_ram7_wr  ,
    output 	wire	    init_ram8_wr  ,
    output 	wire	    init_ram9_wr  ,
    
    input	wire [31:0]	i_wb_adr	  ,
    input	wire		    i_wb_cyc	  ,
    input	wire 		    i_wb_we		  ,
    input	wire [31:0]	i_wb_data_in  ,
    output wire [31:0] o_wb_data_out ,
    output wire	    	o_wb_ack 	  ,
    
    input	wire		i_system_mem_rdy,
    output  wire		o_system_rdy     
) ;  
  


localparam INSTR_ADDR_WIDTH = $clog2(INSTR_RAM_SIZE)+1; // to make space for the boot rom
localparam DATA_ADDR_WIDTH  = $clog2(DATA_RAM_SIZE);

//wire 	[31:0] 	o_wb_adr1 ;
//wire 	[31:0] 	o_wb_adr2 ;
//wire 	[31:0] 	o_wb_adr3 ;
//wire 	[31:0] 	o_wb_dat1 ;
//wire 	[31:0] 	o_wb_dat2 ;
//wire 	[31:0] 	o_wb_dat3 ;
//wire 	 	    o_wb_we1 ;
//wire 	 	    o_wb_we2 ;
//wire 	     	o_wb_we3 ;

//Roy Flash Loader and access

//wire			init_ram3_wr ;
//wire			init_main_wr ;
//wire			init_ram4_wr ;
//wire			init_ram5_wr ;
//wire			init_ram6_wr ;
//wire			init_ram7_wr ;
//wire			init_ram8_wr ;
//wire			init_ram9_wr ;
//wire			system_mem_rdy ;//,system1_mem_rdy,system2_mem_rdy,system3_mem_rdy ;


//wire	[31:0]	i_wb_dat1_flash ;
//wire			i_wb_ack_flash ;
//wire			i_wb_ack1_flash ;
//wire			i_wb_ack2_flash ;
//wire			i_wb_ack3_flash ;
wire			boot_flash_cycle	;
wire			flash_cycle	;
wire	[31:0]	boot_flash_addr	;
wire			flash_data_stb ;
wire			flash_ctrl_stb ;
wire	[31:0]	flash_addr ;
wire			flash_cyc ;
//wire			flash_cyc1        	  ;
//wire			flash_cyc2        	  ;
//wire			flash_cyc3        	  ;
//wire			flash_data_access1	  ;
//wire			flash_data_access2	  ;
//wire			flash_data_access3	  ;
//wire			flash_ctrl_access1	  ;
//wire			flash_ctrl_access2	  ;
//wire			flash_ctrl_access3	  ;
//wire 			flash_we     		  ;
wire [31:0]		flash_data_in  		  ;	
wire [31:0]		flash_data_out		  ;
wire			flash_ack			  ;
wire           flash_we;
wire           init_main_wr;
//wire 			tmp_mdm_tx_data		  ;

//wire keep_sig ;
//assign 	system_mem_rdy = 1'b1 ; //system1_mem_rdy && system2_mem_rdy && system3_mem_rdy ;

//assign flash_cyc1         = 1'b0 ; //flash_data_access1 || flash_ctrl_access1 ; 
//assign flash_cyc2         = 1'b0 ; //flash_data_access2 || flash_ctrl_access2 ; 
//assign flash_cyc3         = 1'b0 ; //flash_data_access3 || flash_ctrl_access3 ; 
//assign flash_data_access1 = 1'b0 ; //(o_wb_cyc1 && (o_wb_adr1[31:30]==2'b10)) ; 
//assign flash_data_access2 = 1'b0 ; //(o_wb_cyc2 && (o_wb_adr2[31:30]==2'b10)) ; 
//assign flash_data_access3 = 1'b0 ; //(o_wb_cyc3 && (o_wb_adr3[31:30]==2'b10)) ; 
//assign flash_ctrl_access1 = 1'b0 ; //(o_wb_cyc1 && (o_wb_adr1[31:30]==2'b11)) ; 
//assign flash_ctrl_access2 = 1'b0 ; //(o_wb_cyc2 && (o_wb_adr2[31:30]==2'b11)) ; 
//assign flash_ctrl_access3 = 1'b0 ; //(o_wb_cyc3 && (o_wb_adr3[31:30]==2'b11)) ; 

wire flash_data_access ;
wire flash_ctrl_access ;
assign flash_data_access = (i_wb_cyc && (i_wb_adr[19]==1'b0)) ;
assign flash_ctrl_access = (i_wb_cyc && (i_wb_adr[19]==1'b1)) ;

assign flash_data_stb  	=  flash_data_access || boot_flash_cycle ; 
assign flash_ctrl_stb  	=  flash_ctrl_access ; 
assign flash_cyc       	=  flash_data_stb || flash_ctrl_stb ; 
assign flash_addr  		  =  boot_flash_cycle ? boot_flash_addr : flash_ctrl_stb ? (i_wb_adr & 32'h0000_000f) : i_wb_adr ;
assign o_wb_ack 		    =  flash_ack ;
assign flash_we         =  i_wb_we ;
assign flash_data_in   	=  i_wb_data_in ;
assign o_wb_data_out 	  =  flash_data_out ;


wbqspiflash wbqspi_i (
		.i_clk				    (clk_int		            ),
		.i_rst				    (!rstn_int		          ),
		// Internal wishbone connections
		.i_wb_cyc			    (flash_cyc		          ), 
		.i_wb_data_stb		(flash_data_stb	        ), 
		.i_wb_ctrl_stb		(flash_ctrl_stb	        ), 
		.i_wb_we			    (flash_we		            ),
		.i_wb_addr			  ({3'b000,flash_addr[18:2]}), 
		.i_wb_data			  (flash_data_in	        ),
		// Wishbone return values
		.o_wb_ack			    (flash_ack   	          ), 
		.o_wb_stall			  (                       ), 
		.o_wb_data			  (flash_data_out         ),
		// Quad Spi connections to the external device
		.o_qspi_sck			  (o_qspi_sck	            ), 
		.o_qspi_cs_n		  (o_qspi_cs_n	          ), 
		.o_qspi_mod			  (o_qspi_mod		          ), 
		.o_qspi_dat			  (o_qspi_dat		          ), 
		.i_qspi_dat			  (i_qspi_dat		          ),
		.o_interrupt		  (                       )
	);


flash_boot flash_boot_i (
		.sys_clk			(clk_int		), 
		.sys_rst			(!rstn_int		),
		.system_mem_rdy		(i_system_mem_rdy), //input
		.system_rdy			(o_system_rdy	), //output
		//Interface to flash controller
		.o_flash_cycle		(boot_flash_cycle),
		.o_flash_addr		(boot_flash_addr ),
		.i_flash_ack		(boot_flash_cycle && flash_ack),
		.i_flash_data		(flash_data_out ),
		//simple ram if
		.init_ram_addr		( init_ram_addr	), //21:0
		.init_ram_data		( init_ram_data	), //31:0
		.init_ram1_wr		( init_ram1_wr	),
		.init_ram2_wr		( init_ram2_wr	),
		.init_ram3_wr		( init_ram3_wr	),
		.init_ram4_wr		( init_ram4_wr	),
		.init_ram5_wr		( init_ram5_wr	),
		.init_ram6_wr		( init_ram6_wr	),
		.init_ram7_wr		( init_ram7_wr	),
		.init_ram8_wr		( init_ram8_wr	),
		.init_ram9_wr		( init_ram9_wr	),
		.init_main_wr		( init_main_wr	)
	);  	


endmodule

