module ddr2_sodimm (

	input ref_clk,
	input ref_rst_n,
	
	output		    led,	
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
    
    //--------------------------
    
    // SOC System Interface
    
    input soc_clk, // soc system clock
    input soc_rst_n, // soc system reset
        
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
	
localparam DDR_ADDR_WIDTH  = 26 ;
localparam DDR_DATA_WIDTH  = 128 ;


wire               local_init_done;
wire   [25 :0]     local_address;
wire               local_burstbegin;
wire               local_ready;
wire               local_read_req;
wire   [127 :0]    local_rdata;
wire               local_rdata_valid;
wire               local_write_req;
wire   [127 :0]    local_wdata;
wire               phy_clk;


`ifndef PSD_DDR // Not pseudo DDR
	
	ddr2_64bit ddr2_64bit (
	.local_address(local_address),
	.local_write_req(local_write_req),
	.local_read_req(local_read_req),
	.local_burstbegin(local_burstbegin),
	.local_wdata(local_wdata),
	.local_be(16'hffff),
	.local_size(1),
	.global_reset_n(ref_rst_n),
	.pll_ref_clk(ref_clk),
	.soft_reset_n(ref_rst_n),  // TMP should be Software register driven.
	.local_ready(local_ready),
	.local_rdata(local_rdata),
	.local_rdata_valid(local_rdata_valid),
	.local_refresh_ack(),
	.local_init_done(local_init_done),
	.reset_phy_clk_n(),
	.mem_odt(mem_odt),
	.mem_cs_n(mem_cs_n),
	.mem_cke(mem_cke),
	.mem_addr(mem_addr),
	.mem_ba(mem_ba),
	.mem_ras_n(mem_ras_n),
	.mem_cas_n(mem_cas_n),
	.mem_we_n(mem_we_n),
	.mem_dm(mem_dm),
	.phy_clk(phy_clk),
	.aux_full_rate_clk(),
	.aux_half_rate_clk(),
	.reset_request_n(),
	.mem_clk(mem_clk),
	.mem_clk_n(mem_clk_n),
	.mem_dq(mem_dq),
	.mem_dqs(mem_dqs));

`else // Pseudo DDR interface for supporting for fast simulation. (Altera DDR model is heavy)
   
    assign phy_clk = ref_clk ; // For simplicity we initially assume that in the pseudo mode they are the same ;
                               // TODO make phy_clk as DDR rate range 

    sim_psd_ddr_intrfc #(        
     .DDR_ADDR_WIDTH ( DDR_ADDR_WIDTH ),
     .DDR_DATA_WIDTH ( DDR_DATA_WIDTH )         
    ) sim_psd_ddr_intrfc (
    
     .phy_clk           (phy_clk),
     .rst_n             (ref_rst_n),
     .local_address     (local_address),
     .local_burstbegin  (local_burstbegin),
     .local_init_done   (local_init_done),
     .local_rdata       (local_rdata),
     .local_rdata_valid (local_rdata_valid),
     .local_read_req    (local_read_req),
     .local_ready       (local_ready),
     .local_wdata       (local_wdata),
     .local_write_req   (local_write_req)) ;
     
`endif	

ddr2_read_write #(        
         .DDR_ADDR_WIDTH ( DDR_ADDR_WIDTH ),
         .DDR_DATA_WIDTH ( DDR_DATA_WIDTH )         
        ) ddr2_read_write (
        
        
  .phy_clk (phy_clk),
  .rst_n (ref_rst_n),
  .local_address (local_address),
  .local_burstbegin (local_burstbegin),
  .local_init_done (local_init_done),
  .local_rdata (local_rdata),
  .local_rdata_valid (local_rdata_valid),
  .local_read_req (local_read_req),
  .local_ready (local_ready),
  .local_wdata (local_wdata),
  .local_write_req (local_write_req),
  .led(led),
  
         // SOC System Interface
    
  .soc_clk   ( soc_clk   ),  // input         
  .soc_rst_n ( soc_rst_n ),  // input 
  
  .soc_ddr_cmd          ( soc_ddr_cmd          ),  // input  [31:0] 
  .soc_ddr_cmd_valid    ( soc_ddr_cmd_valid    ),  // input         
  .soc_ddr_status       ( soc_ddr_status       ),  // output        
  .soc_ddr_data_buf_idx ( soc_ddr_data_buf_idx ),  // input   [1:0] 
  .soc_ddr_buf_wr       ( soc_ddr_buf_wr       ),  // output        
  .soc_ddr_buf_rd       ( soc_ddr_buf_rd       ),  // output        
  .soc_ddr_data_in      ( soc_ddr_data_in      ),  // input  [31:0] 
  .soc_ddr_data_out     ( soc_ddr_data_out     )   // output [31:0]   

  
);

	
endmodule
