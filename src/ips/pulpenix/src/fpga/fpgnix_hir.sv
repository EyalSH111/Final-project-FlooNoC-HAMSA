module fpgnix (
    input                 sys_rst,
    input                 altera_clk25mhz,
    
    //Common UART 
    output wire           uart_tx,
    input  wire           uart_rx,
    
    //leds
    output  [3:0]         led,             

    //JTAG
    //  20-pin JTAG HEADER
    //  -----------------------
    //  1 - VTref    NC  - 2
    //  3 - nTRST    GND - 4
    //  5 - TDI      GND - 6
    //  7 - TMS      GND - 8
    //  9 - TCK      GND - 10
    // 11 - RTCK     GND - 12
    // 13 - TDO       *  - 14
    // 15 - nSRST     *  - 16
    // 17 - DBGRQ     *  - 18
    // 19 - 5V-Sply   *  - 20
    //
    // VTref:  Connect to target VDD
    // GND:    connected to GND in J-Link. They should be connected to GND in target system
    // RTCK:   Connect to RTCK if available, otherwise to GND
    // nSRST:  Typically connected to the RESET pin of the target CPU. Active-Low
    // DBGRQ:  Typically connected to DBGRQ if available, otherwise left open
    output VTref,
    input nTRST,
    input TDI,
    input TMS,
    input TCK,
    output RTCK,
    output TDO,
    input nSRST,
    
`ifdef DDR_INTRFC
    output	[1:0]	mem_odt,
	output	[1:0]	mem_cs_n,
	output	[1:0]	mem_cke,
	output	[13:0]	mem_addr,
	output	[2:0]	mem_ba,
	output		    mem_ras_n,
	output		    mem_cas_n,
	output		    mem_we_n,
	output	[7:0]	mem_dm,
	inout	[1:0]	mem_clk,
	inout	[1:0]	mem_clk_n,
	inout	[63:0]	mem_dq,
	inout	[7:0]	mem_dqs,     
`endif

   // SPI Slave interfaces
   
   input  pad_spis_clk,
   input  pad_spis_cs,
   input  pad_spis_di,
   output pad_spis_do
       
);



wire pll_locked;

`ifdef CACHE
    TODO
    defparam fpgnix.vqm_msystem_wrap.msystem.core_region_i.data_mem.init_file = "slm_files/app_data128.mif";
`else
    defparam fpgnix.vqm_msystem_wrap.msystem.core_region_i.data_mem.init_file = "slm_files/app_data32.mif";
`endif

`ifdef HAMSA_DI
    defparam fpgnix.vqm_msystem_wrap.msystem.core_region_i.instr_mem.sp_ram_wrap_i.init_file = "slm_files/app_instr128.mif";
`else    
    defparam fpgnix.vqm_msystem_wrap.msystem.core_region_i.instr_mem.sp_ram_wrap_i.init_file = "slm_files/app_instr32.mif";
`endif
  



// TMP Play leds, just to see board is alive
logic [31:0] cnt25;
logic sec_cnt25;
logic rstn_25;
always @(posedge altera_clk25mhz or negedge rstn_25)
    if (~rstn_25) begin
        cnt25 <= 32'h0; 
        sec_cnt25 <= 1'b0;
    end else if (cnt25 < 12499999) //25M/2-1 - blink every second
        cnt25 <= cnt25 + 1;
    else begin
        cnt25 <= 32'h0;
        sec_cnt25 <= ~sec_cnt25;
    end
//assign led[0] = sec_cnt25;
logic [31:0] cnt10;
logic sec_cnt10;
logic clk10;
logic rstn_10;
logic apor_n;
always @(posedge clk10 or negedge rstn_10)
    if (~rstn_10) begin
        cnt10 <= 32'h0; 
        sec_cnt10 <= 1'b0;
    end else if (cnt10 < 4999999) //10M/2-1 - blink every second
        cnt10 <= cnt10 + 1;
    else begin
        cnt10 <= 32'h0;
        sec_cnt10 <= ~sec_cnt10;
    end
assign led[0] = sec_cnt10 ;

wire [31:0] gpio_out;
assign led[3:1] = gpio_out[2:0];

logic jtag_sel;
logic [1:0] sw_reset;
logic enable_core;
logic ndmreset ;  


logic        s_gpp_master_bus_psel    ;
logic        s_gpp_master_bus_penable ;
logic        s_gpp_master_bus_pwrite  ;
logic [31:0] s_gpp_master_bus_paddr   ;
logic [31:0] s_gpp_master_bus_pwdata  ;
logic [31:0] s_gpp_master_bus_prdata  ;
logic        s_gpp_master_bus_pready  ;
logic        s_gpp_master_bus_pslverr ;


`ifdef DDR_INTRFC  
// SOC DDR interface
logic [31:0] soc_ddr_cmd;          // Command to ddr interface to store or load buffer , inducing DDR memory address
logic        soc_ddr_cmd_valid;    // pulse indicating command is valid.
logic [31:0] soc_ddr_status;       // returned status, zero means not valid, changes to 0 upon sys_ddr_cmd_valid    
logic  [1:0] soc_ddr_data_buf_idx; // 4 X 32b words buffer
logic        soc_ddr_buf_wr;       // Write to buffer pulse
logic        soc_ddr_buf_rd;       // Read from buffer pulse    
logic [31:0] soc_ddr_data_in;      // input to buffer
logic [31:0] soc_ddr_data_out;     // output from buffer
`endif


// XBOX mem TCM dmem interface	
// xbox mem -> core_region
logic                          xbox_dmem_rready;                         
logic [31:0]                   xbox_dmem_rdata;
logic                          xbox_dmem_wready;    
// core region -> xbox mem
logic                          xbox_dmem_rvalid;
logic [18:0]                   xbox_dmem_addr;
logic                          xbox_dmem_wvalid;
logic [31:0]                   xbox_dmem_wdata;
logic [3:0]                    xbox_dmem_wbe;

logic [floo_hamsa_pkg::FlooReqBits-1:0] floo_req_o;
logic [floo_hamsa_pkg::FlooRspBits-1:0] floo_rsp_o;
logic [floo_hamsa_pkg::FlooReqBits-1:0] floo_req_i;
logic [floo_hamsa_pkg::FlooRspBits-1:0] floo_rsp_i;

vqm_msystem_wrap vqm_msystem_wrap (

    .clk_sys      (clk10),
    .rstn_sys     (rstn_10),
    .clk_ref      (clk10), // Propagates to dm debug module, TODO: further investigate.
    .apor_n       (apor_n),
    .enable_core  (enable_core),   
    .ndmreset     (ndmreset),    
    .pad_uart_tx  (uart_tx),
    .pad_uart_rx  (uart_rx),
    .pad_tck      (TCK),
    .pad_trstn    (nTRST),
    .pad_tms      (TMS),
    .pad_tdi      (TDI),
    .pad_tdo      (TDO),
    .jtag_sel     (jtag_sel),
    .gpio_out     (gpio_out[31:0]),

    .gpp_master_psel     (s_gpp_master_bus_psel),  
    .gpp_master_penable  (s_gpp_master_bus_penable),
    .gpp_master_pwrite   (s_gpp_master_bus_pwrite),    
    .gpp_master_paddr    (s_gpp_master_bus_paddr), 
    .gpp_master_pwdata   (s_gpp_master_bus_pwdata),
                                         
    .gpp_master_prdata   (s_gpp_master_bus_prdata),
    .gpp_master_pready   (s_gpp_master_bus_pready),
    .gpp_master_pslverr  (s_gpp_master_bus_pslverr),

   // SPI Slave interfaces

    .pad_spis_clk        (pad_spis_clk),
    .pad_spis_cs         (pad_spis_cs),
    .pad_spis_di         (pad_spis_di),
    .pad_spis_do         (pad_spis_do),
	
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

    .floo_req_o          ( floo_req_o ),
    .floo_rsp_o          ( floo_rsp_o ),
    .floo_req_i          ( floo_req_i ),
    .floo_rsp_i          ( floo_rsp_i )
);

 
assign VTref = 1'b1;             
assign RTCK = 1'b0;             
wire pre_sync_rst_n;
assign pre_sync_rst_n = sys_rst && nSRST && !ndmreset && pll_locked && !sw_reset[0];
rst_sync rst_sync10 (.RI_N(pre_sync_rst_n), .CK(clk10),           .RO_N(rstn_10));
rst_sync rst_sync25 (.RI_N(pre_sync_rst_n), .CK(altera_clk25mhz), .RO_N(rstn_25));
rst_sync rst_sync_apor (.RI_N(sys_rst && nSRST && pll_locked && !sw_reset[1]), .CK(clk10), .RO_N(apor_n));



`ifdef FAKED_FAST_SIM_ALTPLL

faked_fast_sim_altpll #(.CLK_PERIOD(`CLK_PERIOD)) altera_pll (
                   .areset    ( !sys_rst          ),
                   .inclk0    ( altera_clk25mhz   ),
                   .c0        ( clk10             ),
                   .locked    ( pll_locked        )
                   );   

`else
pll altera_pll (
                   .areset    ( !sys_rst          ),
                   .inclk0    ( altera_clk25mhz   ),
                   .c0        ( clk10             ),
                   .locked    ( pll_locked        )
                   );
`endif

// always @(posedge clk10) $display($time," DBG TIME"); 

// GPP Interface

// GPP APB interface is shared xbox (HW accelerator) and generic fpgnix regs etc. 

APB_BUS  s_xbox_master_bus(); 
APB_BUS  s_fpgnix_master_bus();

wire [31:0] gpp_start_addr = `GPP_START_ADDR ; 
wire [31:0] extended_gpp_addr =  {gpp_start_addr[31:23],s_gpp_master_bus_paddr[22:0]};

wire is_gpp_xbox_addr =   (extended_gpp_addr >= `GPP_XBOX_START_ADDR)   && (extended_gpp_addr <= `GPP_XBOX_END_ADDR);                                                                       
wire is_gpp_fpgnix_addr = (extended_gpp_addr >= `GPP_FPGNIX_START_ADDR) && (extended_gpp_addr <= `GPP_FPGNIX_END_ADDR);
                        
assign s_xbox_master_bus.psel   = s_gpp_master_bus_psel && is_gpp_xbox_addr;
assign s_fpgnix_master_bus.psel = s_gpp_master_bus_psel && is_gpp_fpgnix_addr;

assign s_xbox_master_bus.penable   = s_gpp_master_bus_penable && is_gpp_xbox_addr;
assign s_fpgnix_master_bus.penable = s_gpp_master_bus_penable && is_gpp_fpgnix_addr;

assign s_xbox_master_bus.paddr   = s_gpp_master_bus_paddr ;
assign s_fpgnix_master_bus.paddr = s_gpp_master_bus_paddr ;

assign s_xbox_master_bus.pwdata   = s_gpp_master_bus_pwdata ;
assign s_fpgnix_master_bus.pwdata = s_gpp_master_bus_pwdata ;

assign s_xbox_master_bus.pwrite   = s_gpp_master_bus_pwrite ;
assign s_fpgnix_master_bus.pwrite = s_gpp_master_bus_pwrite ;

assign s_gpp_master_bus_pready   = s_xbox_master_bus.psel ? s_xbox_master_bus.pready : s_fpgnix_master_bus.pready ;
assign s_gpp_master_bus_pslverr  = 1'b0; // not applied
assign s_gpp_master_bus_prdata   = s_xbox_master_bus.psel ? s_xbox_master_bus.prdata : s_fpgnix_master_bus.prdata ;  


// HW accelerator interface
xbox xbox ( 
    .clk(clk10),
    .rst_n(rstn_10),
    .apb(s_xbox_master_bus),
	
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
    .xbox_dmem_wbe       ( xbox_dmem_wbe    )	
);

// Fpgnix GPP  regs

fpgnix_gpp fpgnix_gpp(
    .clk(clk10),
    .sys_rst_n(rstn_10), 
    .apb(s_fpgnix_master_bus),

    .jtag_sel(jtag_sel),
    .sw_reset(sw_reset),
    .enable_core(enable_core)
    
`ifdef DDR_INTRFC
   ,.soc_ddr_cmd          ( soc_ddr_cmd          ),  // output  [31:0] 
    .soc_ddr_cmd_valid    ( soc_ddr_cmd_valid    ),  // output         
    .soc_ddr_status       ( soc_ddr_status       ),  // input        
    .soc_ddr_data_buf_idx ( soc_ddr_data_buf_idx ),  // input   [1:0] 
    .soc_ddr_buf_wr       ( soc_ddr_buf_wr       ),  // input        
    .soc_ddr_buf_rd       ( soc_ddr_buf_rd       ),  // input        
    .soc_ddr_data_in      ( soc_ddr_data_in      ),  // input  [31:0] 
    .soc_ddr_data_out     ( soc_ddr_data_out     )   // output [31:0]   
`endif

);

//--------------------------------------------------------------------------------------

`ifdef DDR_INTRFC    

ddr2_sodimm ddr2_sodimm (     // DDR interface unit on FPGNIX side , 
                              // SODIMM stands for "Small Outline Dual In-line Memory Module"
       
       .ref_clk(altera_clk25mhz),
       .ref_rst_n(sys_rst), // Notice that despite its name sys_rst is asserted low by fpgnix_tb.v
 	   
	   .mem_odt    ( mem_odt   ),  // output
	   .mem_cs_n   ( mem_cs_n  ),  // output
	   .mem_cke    ( mem_cke   ),  // output
	   .mem_addr   ( mem_addr  ),  // output
	   .mem_ba     ( mem_ba    ),  // output
	   .mem_ras_n  ( mem_ras_n ),  // output
	   .mem_cas_n  ( mem_cas_n ),  // output
	   .mem_we_n   ( mem_we_n  ),  // output
	   .mem_dm     ( mem_dm    ),  // output
                               
	   .mem_clk    ( mem_clk   ),  // inout
	   .mem_clk_n  ( mem_clk_n ),  // inout
	   .mem_dq     ( mem_dq    ),  // inout
	   .mem_dqs    ( mem_dqs   ),  // inout
	   
	   .led        (ddr_led    ), // output 

       // SOC System Interface
    
       .soc_clk   ( clk10   ),  // input         
       .soc_rst_n ( rstn_10 ),  // input 
       
       .soc_ddr_cmd          ( soc_ddr_cmd          ),  // input  [31:0] 
       .soc_ddr_cmd_valid    ( soc_ddr_cmd_valid    ),  // input         
       .soc_ddr_status       ( soc_ddr_status       ),  // output        
       .soc_ddr_data_buf_idx ( soc_ddr_data_buf_idx ),  // input   [1:0] 
       .soc_ddr_buf_wr       ( soc_ddr_buf_wr       ),  // output        
       .soc_ddr_buf_rd       ( soc_ddr_buf_rd       ),  // output        
       .soc_ddr_data_in      ( soc_ddr_data_in      ),  // input  [31:0] 
       .soc_ddr_data_out     ( soc_ddr_data_out     )   // output [31:0]   
	);

`else

       assign soc_ddr_cmd          = 0 ; 
       assign soc_ddr_cmd_valid    = 0 ;      
       assign soc_ddr_data_buf_idx = 0 ; 
       assign soc_ddr_data_in      = 0 ; 
  
        
`endif

//---------------------------------------------------------------------------------------

endmodule
