// This module wraps msystem mainly to avoid systemverilog interfaces at FPGA flow VQM level.

import floo_hamsa_pkg::*;

module vqm_msystem_wrap  (

    input  logic         clk_sys,
    input  logic         rstn_sys ,
    input  logic         apor_n ,
    input  logic         clk_ref,
    input  logic         enable_core ,    
    output logic         ndmreset ,    
    output logic         pad_uart_tx ,
    input  logic         pad_uart_rx ,
    input  logic         pad_tck,
    input  logic         pad_trstn,
    input  logic         pad_tms,
    input  logic         pad_tdi,
    output logic         pad_tdo,
    input  logic         jtag_sel,
    output logic [31:0]  gpio_out,
    
    output logic         gpp_master_psel,   
    output logic         gpp_master_penable,
    output logic         gpp_master_pwrite,    
    output logic [31:0]  gpp_master_paddr, 
    output logic [31:0]  gpp_master_pwdata,
    
    input  logic [31:0]  gpp_master_prdata,
    input  logic         gpp_master_pready,
    input  logic         gpp_master_pslverr,

   // SPI Slave interfaces
   
   input  pad_spis_clk,
   input  pad_spis_cs,
   input  pad_spis_di,
   output pad_spis_do,
   
   // XBOX mem TCM dmem interface	
   // xbox mem -> core_region
   input             xbox_dmem_rready,                         
   input [31:0]      xbox_dmem_rdata,
   input             xbox_dmem_wready,    
   // core region -> xbox mem
   output            xbox_dmem_rvalid,
   output [18:0]     xbox_dmem_addr,
   output            xbox_dmem_wvalid,
   output [31:0]     xbox_dmem_wdata,
   output [3:0]      xbox_dmem_wbe,

   output logic [FlooReqBits-1:0] floo_req_o,
   output logic [FlooRspBits-1:0] floo_rsp_o,
   input  logic [FlooReqBits-1:0] floo_req_i,
   input  logic [FlooRspBits-1:0] floo_rsp_i
);

APB_BUS     s_gpp_master_bus();

floo_req_t floo_req_o_s;
floo_rsp_t floo_rsp_o_s;
floo_req_t floo_req_i_s;
floo_rsp_t floo_rsp_i_s;

assign floo_req_o = floo_req_o_s;
assign floo_rsp_o = floo_rsp_o_s;
assign floo_req_i_s = floo_req_i;
assign floo_rsp_i_s = floo_rsp_i;

`ifdef CACHE
    TODO
    defparam vqm_msystem_wrap.msystem.core_region_i.data_mem.init_file = "slm_files/app_data128.mif";
`else
    defparam vqm_msystem_wrap.msystem.core_region_i.data_mem.init_file = "slm_files/app_data32.mif";
`endif

`ifdef HAMSA_DI
    defparam vqm_msystem_wrap.msystem.core_region_i.instr_mem.sp_ram_wrap_i.init_file = "slm_files/app_instr128.mif";
`else    
    defparam vqm_msystem_wrap.core_region_i.instr_mem.sp_ram_wrap_i.init_file = "slm_files/app_instr32.mif";
`endif


assign gpp_master_psel    = s_gpp_master_bus.psel     ; 
assign gpp_master_penable = s_gpp_master_bus.penable  ; 
assign gpp_master_pwrite  = s_gpp_master_bus.pwrite   ; 
assign gpp_master_paddr   = s_gpp_master_bus.paddr    ; 
assign gpp_master_pwdata  = s_gpp_master_bus.pwdata   ; 

assign s_gpp_master_bus.prdata  = gpp_master_prdata  ;
assign s_gpp_master_bus.pready  = gpp_master_pready  ;
assign s_gpp_master_bus.pslverr = gpp_master_pslverr ;   
   
msystem msystem (
                 .gpp_master            (s_gpp_master_bus),
                 .floo_north_req_o      (floo_req_o_s),
                 .floo_north_rsp_o      (floo_rsp_o_s),
                 .floo_north_req_i      (floo_req_i_s),
                 .floo_north_rsp_i      (floo_rsp_i_s),

                 .ndmreset              (ndmreset),             
                 .pad_mmspi_cs_o        (),                     
                 .pad_mmspi_dclk_o      (),                     
                 .pad_mmspi_dout_o      (),                     
                 .pad_mmspi_dout_oe_n   (),                     
                 .pad_spim_cs1          (),                     
                 .pad_spim_cs2          (),                     
                 .pad_spim_cs3          (),                     
                 .pad_spim_cs4          (),                     
                 .pad_spim_clk          (),                     
                 .pad_spim_do_spis_do   (pad_spis_do),   // The .pad_spim_* name is obsolete muxing leftover                    
                 .pad_uart_tx           (pad_uart_tx),              
                 .pad_tdo               (pad_tdo),                  
                 .pad_scl_o             (),                     
                 .pad_sda_o             (),                     
                 .pad_scl_oen_o         (),                     
                 .pad_sda_oen_o         (),                     
                 .gpio_out              (gpio_out[31:0]),       
                 .gpio_dir              (),                     
                 // Inputs
                 .clk_sys               (clk_sys),                
                 .rstn_sys              (rstn_sys),              
                 .apor_n                (apor_n),               
                 .clk_ref               (clk_ref),                
                 .regfile_select_i      ('h1),                  
                 .instr_ram_sel_i       ('h0),                  
                 .data_ram_sel_i        ('h0),                  
                 .enable_core           (enable_core),          
                 .pad_testmode_i        ('h0),                  
                 .pad_scan_enable_i     ('h0),                  
                 .pad_master_slave      ('h0),                  
                 .mmspi_d_clk           ('h0),                  
                 .pad_mmspi_dclk_i      ('h0),                  
                 .pad_mmspi_din_i       ('h0),                  
                 .pad_mmspi_dout_i      ('h0),                  
                 .pad_spim_din1         ('h0),                  
                 .pad_spim_din2_spis_clk(pad_spis_clk),  // The .pad_spim_* name is obsolete muxing leftover                
                 .pad_spim_din3_spis_di (pad_spis_di),   // The .pad_spim_* name is obsolete muxing leftover                
                 .pad_spim_din4         ('h0),                  
                 .pad_spis_cs           (pad_spis_cs),                  
                 .pad_uart_rx           (pad_uart_rx),              
                 .pad_tck               (pad_tck),                  
                 .pad_trstn             (pad_trstn),                
                 .pad_tms               (pad_tms),                  
                 .pad_tdi               (pad_tdi),                  
                 .jtag_sel              (jtag_sel),             
                 .pad_scl_i             ('h0),                  
                 .pad_sda_i             ('h0),                  
                 .gpio_in               ('h0),                  
                 .ram_ctrl              (),                    

								   
	             // XBOX mem TCM dmem interface	
	             // xbox mem -> core_region
                 .xbox_dmem_rready   ( xbox_dmem_rready ),                          
                 .xbox_dmem_rdata    ( xbox_dmem_rdata  ),  
                 .xbox_dmem_wready   ( xbox_dmem_wready ),     
                 // core_region -> xbox_mem
                 .xbox_dmem_rvalid   ( xbox_dmem_rvalid ),
                 .xbox_dmem_addr     ( xbox_dmem_addr   ),
                 .xbox_dmem_wvalid   ( xbox_dmem_wvalid ),
                 .xbox_dmem_wdata    ( xbox_dmem_wdata  ),
                 .xbox_dmem_wbe      ( xbox_dmem_wbe    ));

endmodule



