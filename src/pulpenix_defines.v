
//In ASIC mode all below 5 defines need to be commented out
`define MSYSTEM_ONLY
//`define ALTERA  
//`define XILINX  

// Altera preloaded RAM not loaded from external flash
`define NOFLASH  
// `define SIM_UART_SPEED_FACTOR 8

//UART defaults remember to update also in SW file
`define DEFAULT_BAUDRATE  115200
`define DEFAULT_PARITY_EN 0
//`define DEFAULT_CLK_PERIOD_NS 40       // 25 MHz
//`define DEFAULT_CLK_PERIOD_NS 25    // 40 MHz
`define DEFAULT_CLK_PERIOD_NS 100    // 10 MHz



//Tests uart interface commands 24_04_19
//    	MSYSTEM_ONLY	ALTERA		NOFLASH		UART_SPEED 	Result 		Comments
//    		0				0			0			X		Pass		Real ASIC
//    		0				0			0			16		Pass
//    		0				0			1			16		Pass
//    		0				1			0			16		Pass		Very Slow flash boot to Altera, Only with: initial force top_i.peripherals_i.apb_uart_sv_i.cfg_div_val=21 ; in pulpenix.sv line:352
//    		0				1			1			16		Pass		Only with: initial force top_i.peripherals_i.apb_uart_sv_i.cfg_div_val=21 ; in pulpenix.sv line:352



//******************   For Simulation only **************************
//Instanciate second processor as well
// `define PULP2
//Second processor boot from its own flash or via SPI bus
//`define PULP2_FLASH

