

module ddr2_dimm (
	
	mem_odt,
	mem_cs_n,
	mem_cke,
	mem_addr,
	mem_ba,
	mem_ras_n,
	mem_cas_n,
	mem_we_n,
	mem_dm,
	mem_clk,
	mem_clk_n,
	mem_dq,
	mem_dqs,
	
	);
		
input	[1:0]	mem_odt;
input	[1:0]	mem_cs_n;
input	[1:0]	mem_cke;
input	[13:0]	mem_addr;
input	[2:0]	mem_ba;
input		    mem_ras_n;
input		    mem_cas_n;
input		    mem_we_n;
input	[7:0]	mem_dm;

inout	[1:0]	mem_clk;
inout	[1:0]	mem_clk_n;
inout	[63:0]	mem_dq;
inout	[7:0]	mem_dqs;
    

    // << START MEGAWIZARD INSERT PARAMS
    
    parameter gMEM_CHIPSELS     = 2;
    parameter gMEM_CS_PER_RANK  = 1;
    parameter gMEM_NUM_RANKS    = 2 / 1;
    parameter gMEM_BANK_BITS    = 2;
    parameter gMEM_ROW_BITS     = 14;
    parameter gMEM_COL_BITS     = 10;
    parameter gMEM_ADDR_BITS    = 14;
    parameter gMEM_DQ_PER_DQS   = 8;
    parameter DM_DQS_WIDTH	= 8;
    parameter gLOCAL_DATA_BITS  = 128;
    parameter gLOCAL_IF_DWIDTH_AFTER_ECC  = 128;
    parameter gNUM_CLOCK_PAIRS  = 2;
    parameter RTL_ROUNDTRIP_CLOCKS  = 0.0;
    parameter CLOCK_TICK_IN_PS  = 6666;
    parameter REGISTERED_DIMM   = 1'b0;
    parameter BOARD_DQS_DELAY   = 0;
    parameter BOARD_CLK_DELAY   = 0;
    parameter DWIDTH_RATIO      = 2;
    parameter TINIT_CLOCKS  = 30004;
    parameter REF_CLOCK_TICK_IN_PS  = 40000; 
    
    // Parameters below are for generic memory model
    parameter gMEM_TQHS_PS	    =	300;
    parameter gMEM_TAC_PS	    =	400;
    parameter gMEM_TDQSQ_PS 	=	200;
    parameter gMEM_IF_TRCD_NS	=	15.0;
    parameter gMEM_IF_TWTR_CK	=	2;
    parameter gMEM_TDSS_CK	    =	0.2;
    parameter gMEM_IF_TRFC_NS   =   127.5;
    parameter gMEM_IF_TRP_NS    =   15.0;
        
    parameter gMEM_IF_TRCD_PS	= 	gMEM_IF_TRCD_NS * 1000.0;
    parameter gMEM_IF_TWTR_PS	=	gMEM_IF_TWTR_CK * CLOCK_TICK_IN_PS;
    parameter gMEM_IF_TRFC_PS   =   gMEM_IF_TRFC_NS * 1000.0;
    parameter gMEM_IF_TRP_PS    =   gMEM_IF_TRP_NS * 1000.0;
    parameter CLOCK_TICK_IN_NS  =   CLOCK_TICK_IN_PS / 1000.0;
    parameter gMEM_TDQSQ_NS	    =	gMEM_TDQSQ_PS / 1000.0;
    parameter gMEM_TDSS_NS	    =	gMEM_TDSS_CK * CLOCK_TICK_IN_NS;
    

    // << END MEGAWIZARD INSERT PARAMS
    
    // set to zero for Gatelevel
    parameter RTL_DELAYS = 1;
    parameter USE_GENERIC_MEMORY_MODEL  = 1'b0;

    // The round trip delay is now modeled inside the datapath (<your core name>_auk_ddr_dqs_group.v/vhd) for RTL simulation.
    parameter D90_DEG_DELAY = 0; //RTL only

    parameter GATE_BOARD_DQS_DELAY = BOARD_DQS_DELAY * (RTL_DELAYS ? 0 : 1); // Gate level timing only
    parameter GATE_BOARD_CLK_DELAY = BOARD_CLK_DELAY * (RTL_DELAYS ? 0 : 1); // Gate level timing only
 
    // Below 5 lines for SPR272543: 
    // Testbench workaround for tests with "dedicated memory clock phase shift" failing, 
    // because dqs delay isnt' being modelled in simulations
    parameter gMEM_CLK_PHASE_EN = "false";
    parameter real gMEM_CLK_PHASE = 0;
    parameter real MEM_CLK_RATIO = ((360.0-gMEM_CLK_PHASE)/360.0);
    parameter MEM_CLK_DELAY = MEM_CLK_RATIO*CLOCK_TICK_IN_PS * ((gMEM_CLK_PHASE_EN=="true") ? 1 : 0);
    wire clk_to_ram0, clk_to_ram1, clk_to_ram2;
  
    wire cmd_bus_watcher_enabled;
    

    //wire stratix_dqs_ref_clk;   // only used on stratix to provide external dll reference clock
    // wire[gNUM_CLOCK_PAIRS - 1:0] clk_to_sdram;
    wire[gNUM_CLOCK_PAIRS - 1:0] clk_to_sdram_n;
    wire #(GATE_BOARD_CLK_DELAY * 1) clk_to_ram;
    wire clk_to_ram_n;
    wire[gMEM_ROW_BITS - 1:0] #(GATE_BOARD_CLK_DELAY * 1 + 1) a_delayed;
    wire[gMEM_BANK_BITS - 1:0] #(GATE_BOARD_CLK_DELAY * 1 + 1) ba_delayed;
    wire[gMEM_NUM_RANKS - 1:0] #(GATE_BOARD_CLK_DELAY * 1 + 1) cke_delayed;
    wire[gMEM_NUM_RANKS - 1:0] #(GATE_BOARD_CLK_DELAY * 1 + 1) odt_delayed;  //DDR2 only
    wire[gMEM_NUM_RANKS - 1:0] #(GATE_BOARD_CLK_DELAY * 1 + 1) cs_n_delayed;
    wire #(GATE_BOARD_CLK_DELAY * 1 + 1) ras_n_delayed;
    wire #(GATE_BOARD_CLK_DELAY * 1 + 1) cas_n_delayed;
    wire #(GATE_BOARD_CLK_DELAY * 1 + 1) we_n_delayed;
    wire[gLOCAL_DATA_BITS / DWIDTH_RATIO / gMEM_DQ_PER_DQS - 1:0] dm_delayed;
    
    // DDR3 parity only
    wire ac_parity;
    wire mem_err_out_n;
    assign mem_err_out_n = 1'b1;

    // pulldown (dm);
    assign (weak1, weak0) mem_dm = 0;

    tri [gLOCAL_DATA_BITS / DWIDTH_RATIO - 1:0] mem_dq = 100'bz;
    tri [gLOCAL_DATA_BITS / DWIDTH_RATIO / gMEM_DQ_PER_DQS - 1:0] mem_dqs = 100'bz;
    tri [gLOCAL_DATA_BITS / DWIDTH_RATIO / gMEM_DQ_PER_DQS - 1:0] mem_dqs_n = 100'bz;
	assign (weak1, weak0) mem_dq = 0;
	assign (weak1, weak0) mem_dqs = 0;
	assign (weak1, weak0) mem_dqs_n = 1;

    wire [gMEM_BANK_BITS - 1:0] zero_one; //"01";
    assign zero_one = 1;
    
    wire test_complete;
    wire [7:0] test_status;
    // counter to count the number of sucessful read and write loops
    integer test_complete_count;
    wire pnf;
    wire [gLOCAL_IF_DWIDTH_AFTER_ECC / 8 - 1:0] pnf_per_byte;


    assign cmd_bus_watcher_enabled = 1'b0;

    // Below 5 lines for SPR272543: 
    // Testbench workaround for tests with "dedicated memory clock phase shift" failing, 
    // because dqs delay isnt' being modelled in simulations
    assign #(MEM_CLK_DELAY/4.0) clk_to_ram2 = mem_clk[0];// clk_to_sdram[0];
    assign #(MEM_CLK_DELAY/4.0) clk_to_ram1 = clk_to_ram2;
    assign #(MEM_CLK_DELAY/4.0) clk_to_ram0 = clk_to_ram1;
    assign #((MEM_CLK_DELAY/4.0)) clk_to_ram = clk_to_ram0;
    assign clk_to_ram_n = ~clk_to_ram ; // mem model ignores clk_n ?

   	// ddr sdram interface

   // control and data lines = 3 inches
    assign a_delayed = mem_addr[gMEM_ROW_BITS - 1:0] ;
    assign ba_delayed = mem_ba ;
    assign cke_delayed = mem_cke ;
    assign odt_delayed = mem_odt ;
    assign cs_n_delayed = mem_cs_n ;
    assign ras_n_delayed = mem_ras_n ;
    assign cas_n_delayed = mem_cas_n ;
    assign we_n_delayed = mem_we_n ;
    assign dm_delayed = mem_dm ;

    
    ddr2_64bit_mem_model mem (
    	.mem_dq      (mem_dq),
        .mem_dqs     (mem_dqs),
        .mem_dqs_n   (mem_dqs_n),
        .mem_addr    (a_delayed),
        .mem_ba      (ba_delayed),
        .mem_clk     (clk_to_ram),
        .mem_clk_n   (clk_to_ram_n),
        .mem_cke     (cke_delayed),
        .mem_cs_n    (cs_n_delayed),
        .mem_ras_n   (ras_n_delayed),
        .mem_cas_n   (cas_n_delayed),
        .mem_we_n    (we_n_delayed),
        .mem_dm      (dm_delayed),
        .mem_odt     (odt_delayed)
    );

     
endmodule    
    
