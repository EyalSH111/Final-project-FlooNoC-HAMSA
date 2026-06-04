// Copyright 2015 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
`default_nettype wire

`include "axi_bus.sv"
`include "apb_bus.sv"
`include "pulpenix_defines.v"

`define AXI_ADDR_WIDTH         32
`define AXI_DATA_WIDTH         32
`define AXI_ID_MASTER_WIDTH     2
`define AXI_ID_SLAVE_WIDTH      5
`define AXI_USER_WIDTH          1

`ifdef TSMC_65
  `define DATA_MEM_CTRL_VEC_DW 5   // High density sp_ram has 5 bits
  `define INSTR_MEM_CTRL_VEC_DW 12 // 2 High speed sp_rams, with 6 bits each => Toatl = 12
`elsif TSMC16
  `define DATA_MEM_CTRL_VEC_DW 4
  `define INSTR_MEM_CTRL_VEC_DW 4
`else
  `define DATA_MEM_CTRL_VEC_DW 16
  `define INSTR_MEM_CTRL_VEC_DW 16
`endif

`define CORE_MEM_CTRL_VEC_DW `DATA_MEM_CTRL_VEC_DW + `INSTR_MEM_CTRL_VEC_DW

`define CORE_REGION_PARAMS #(                                                 \
                             .AXI_ADDR_WIDTH      ( `AXI_ADDR_WIDTH        ), \
                             .AXI_DATA_WIDTH      ( `AXI_DATA_WIDTH        ), \
                             .AXI_ID_MASTER_WIDTH ( `AXI_ID_MASTER_WIDTH   ), \
                             .AXI_ID_SLAVE_WIDTH  ( `AXI_ID_SLAVE_WIDTH    ), \
                             .AXI_USER_WIDTH      ( `AXI_USER_WIDTH        ), \
                             .DATA_RAM_SIZE       ( DATA_RAM_SIZE          ), \
                             .INSTR_RAM_SIZE      ( INSTR_RAM_SIZE         ), \
                             .DATA_MEM_CTRL_DW    ( `DATA_MEM_CTRL_VEC_DW  ), \
                             .INSTR_MEM_CTRL_DW   ( `INSTR_MEM_CTRL_VEC_DW )  \
                             )


//Defined above
//`define MSYSTEM_ONLY
//`define NOFLASH
//Defined locally

module msystem #(parameter MEM_CTRL_VEC_DW = 32)
   (
    // Clock and Reset
    input logic                 clk_sys,
    input logic                 rstn_sys ,
    input logic                 apor_n ,
    input logic                 clk_ref ,
    // Boot straps
    input logic                 regfile_select_i,
    input logic                 instr_ram_sel_i, // 0 - SRAM, 1 - EDRAM
    input logic                 data_ram_sel_i, // 0 - SRAM, 1 - EDRAM    
    input logic                 enable_core , // Boot-strap dependent core enable
    // End boot straps

    output logic                ndmreset ,

    // External GPP APB master I/F towards the SoC extension modules:
    APB_BUS.Master              gpp_master ,

    // North mesh port (names avoid XRUN resolving chimney floo_req_o to parent)
    output floo_hamsa_pkg::floo_req_t floo_north_req_o,
    output floo_hamsa_pkg::floo_rsp_t floo_north_rsp_o,
    input  floo_hamsa_pkg::floo_req_t floo_north_req_i,
    input  floo_hamsa_pkg::floo_rsp_t floo_north_rsp_i,

    input logic                 pad_testmode_i ,
    input logic                 pad_scan_enable_i ,
    input logic                 pad_master_slave , //1=master 0=slave chip

    // MMSPI pads
    input logic                 mmspi_d_clk, // spi clock from RCG
    input logic                 pad_mmspi_dclk_i, // clock loopback from pad
    input logic                 pad_mmspi_din_i, // data in from external slave (MISO)
    input logic                 pad_mmspi_dout_i, // data out loopback from pad
    output logic [3:0]          pad_mmspi_cs_o, // CS out to slave
    output logic                pad_mmspi_dclk_o, // master clock out to slave
    output logic                pad_mmspi_dout_o, // master data out to slave (MOSI)
    output logic                pad_mmspi_dout_oe_n, // Output enable to pad

    output logic                pad_spim_cs1 ,
    output logic                pad_spim_cs2 ,
    output logic                pad_spim_cs3 ,
    output logic                pad_spim_cs4 ,
    input logic                 pad_spim_din1 ,
    input logic                 pad_spim_din2_spis_clk ,
    input logic                 pad_spim_din3_spis_di ,
    input logic                 pad_spim_din4 ,
    output logic                pad_spim_clk ,
    output logic                pad_spim_do_spis_do ,
    input logic                 pad_spis_cs ,
    output logic                pad_uart_tx ,
    input logic                 pad_uart_rx ,
    input logic                 pad_tck,
    input logic                 pad_trstn,
    input logic                 pad_tms,
    input logic                 pad_tdi,
    output logic                pad_tdo,
    input logic                 jtag_sel,

    // I2C pads:
    input                       pad_scl_i ,
    input                       pad_sda_i ,
    output logic                pad_scl_o ,
    output logic                pad_sda_o ,
    output logic                pad_scl_oen_o ,
    output logic                pad_sda_oen_o,

    // GPIO pads:
    input [31:0]                gpio_in,
    output logic [31:0]         gpio_out,
    output logic [31:0]         gpio_dir,

    // Interrupts

    // Memory control vector:
    input [MEM_CTRL_VEC_DW-1:0] ram_ctrl,
	
	// XBOX mem TCM dmem interface	
	// xbox mem -> core_region
    input                         xbox_dmem_rready,                          
    input  [31:0]                 xbox_dmem_rdata,  
    input                         xbox_dmem_wready,     
    // core region -> xbox mem
    output                        xbox_dmem_rvalid,
    output [18:0]                 xbox_dmem_addr,
    output                        xbox_dmem_wvalid,
    output [31:0]                 xbox_dmem_wdata,
    output [3:0]                  xbox_dmem_wbe  
	
   );

   import floo_hamsa_pkg::*;

    // wire                           fetch_enable_i    = 1'b1 ;
   wire                           spi_master_sdi1_i ;//= 1'b0 ;
   wire                           spi_master_sdi2_i ;//= 1'b0 ;
   wire                           spi_master_sdi3_i ;//= 1'b0 ;
   wire                           spi_sdi1_i        = 1'b0 ;
   wire                           spi_sdi2_i        = 1'b0 ;
   wire                           spi_sdi3_i        = 1'b0 ;
   // wire                           scl_pad_i         = 1'b0 ;
   // wire                           sda_pad_i         = 1'b0 ;
   wire                           uart_cts          = 1'b0 ;
   wire                           uart_dsr          = 1'b0 ;
   logic [31:0] [5:0]             gpio_padcfg;
   logic [31:0] [5:0]             pad_cfg_o;
   logic [31:0]                   pad_mux_o;


   // gpp interconnect
   logic [22:0]                   gpp_paddr     ;
   logic [31:0]                   gpp_pwdata    ;
   logic                          gpp_pwrite    ;
   logic                          gpp_psel      ;
   logic                          gpp_penable   ;
   logic [31:0]                   gpp_prdata    ;
   logic                          gpp_pready    ;
   logic                          gpp_pslverr   ;

   APB_BUS           s_gpp_master();

   assign   s_gpp_master.paddr   = {9'h0,gpp_paddr};
   assign   s_gpp_master.pwdata  = gpp_pwdata    ;
   assign   s_gpp_master.pwrite  = gpp_pwrite    ;
   assign   s_gpp_master.psel    = gpp_psel      ;
   assign   s_gpp_master.penable = gpp_penable   ;
   assign   gpp_prdata           = s_gpp_master.prdata    ;
   assign   gpp_pready           = s_gpp_master.pready    ;
   assign   gpp_pslverr          = s_gpp_master.pslverr   ;

   `APB_ASSIGN_MASTER (s_gpp_master, gpp_master)

   logic [22:0]                   o_gpp_irq_out   ;

   logic [3:0]                    gpdma_done_intr;
   assign o_gpp_irq_out[0] = gpdma_done_intr;


   logic                          fetch_enable_int ;
   logic                          core_busy_int    ;
   logic                          clk_gate_core_int;
   logic [31:0]                   irq_to_core_int  ;

   logic [31:0]                   boot_addr_int    ;

   // wire                           enable_core = 1 ;

   AXI_BUS
     #(
       .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH     ),
       .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH     ),
       .AXI_ID_WIDTH   ( `AXI_ID_SLAVE_WIDTH ),
       .AXI_USER_WIDTH ( `AXI_USER_WIDTH     )
       ) slaves[4:0]();

   AXI_BUS
     #(
       .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH      ),
       .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH      ),
       .AXI_ID_WIDTH   ( `AXI_ID_MASTER_WIDTH ),
       .AXI_USER_WIDTH ( `AXI_USER_WIDTH      )
       ) masters[5:0]();

   APB_BUS s_iedram_apb_bus();
   APB_BUS s_dedram_apb_bus();
   APB_BUS apb_debug();
   OPENOCD_JTAG openocd_jtag();
 
   parameter DATA_RAM_SIZE        = 192*1024 ; // in bytes (192KB)
   parameter INSTR_RAM_SIZE       = 120*1024 ; // in bytes (120KB)

   localparam INSTR_ADDR_WIDTH = $clog2(INSTR_RAM_SIZE)+1; // to make space for the boot ROM
   localparam DATA_ADDR_WIDTH  = $clog2(DATA_RAM_SIZE);

   //----------------------------------------------------------------------------//
   // Standard core region
   //----------------------------------------------------------------------------//

`ifdef PNR_CORE_REGION
   Xcore_region
`else
   Xcore_region `CORE_REGION_PARAMS

`endif // !`ifdef PNR_CORE_REGION

  core_region_i (
                                   .clk                ( clk_sys                             ),
                                   .rst_n              ( rstn_sys                            ),
                                   .apor_n             ( apor_n                              ),
                                   .clk_ref            ( clk_ref                             ),
                                   .regfile_select_i   ( regfile_select_i                    ), // Applicable only for Xcore_region
                                   .instr_ram_sel_i    ( instr_ram_sel_i                     ), // Applicable only for Xcore_region
                                   .data_ram_sel_i     ( data_ram_sel_i                      ), // Applicable only for Xcore_region
                                   .ndmreset           ( ndmreset                            ),

                                   .testmode_i         ( pad_testmode_i                      ),
                                   .fetch_enable_i     ( fetch_enable_int & enable_core ),
                                   .irq_i              ( irq_to_core_int                     ),
                                   .core_busy_o        ( core_busy_int                       ),
                                   .clock_gating_i     ( clk_gate_core_int ),
                                   .boot_addr_i        ( boot_addr_int                       ),

                                   .core_master        ( masters[0]                          ),
                                   .dbg_master         ( masters[1]                          ),
                                   .data_slave         ( slaves[1]                           ),
                                   .instr_slave        ( slaves[0]                           ),
                                   .iedram_apb       ( s_iedram_apb_bus                      ), // Applicable only for Xcore_region
                                   .dedram_apb       ( s_dedram_apb_bus                      ), // Applicable only for Xcore_region
                                   .apb_debug          ( apb_debug                           ),

                                   .tck_i              ( pad_tck                             ),
                                   .trstn_i            ( pad_trstn                           ),
                                   .tms_i              ( pad_tms                             ),
                                   .tdi_i              ( pad_tdi                             ),
                                   .tdo_o              ( pad_tdo                             ),
                                   .jtag_sel           ( jtag_sel                            ),
                                   .openocd_jtag       ( openocd_jtag                        ),
                                   .ram_ctrl           ( ram_ctrl[`CORE_MEM_CTRL_VEC_DW-1:0] ),
								   
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
                                   .xbox_dmem_wbe      ( xbox_dmem_wbe    )
								   
                                   );

   //----------------------------------------------------------------------------//
   // Peripherals
   //----------------------------------------------------------------------------//
   wire [1:0]                     spi_mode_o ;
   wire [1:0]                     spi_master_mode_o ;

   wire                           spi_clk_i;
   wire                           spi_cs_i;
   wire                           spi_sdo0_o;
   wire                           spi_sdo1_o;
   wire                           spi_sdo2_o;
   wire                           spi_sdo3_o;
   wire                           spi_sdi0_i;

   wire                           spi_master_clk_o ;
   wire                           spi_master_csn0_o;
   wire                           spi_master_csn1_o;
   wire                           spi_master_csn2_o;
   wire                           spi_master_csn3_o;
   wire                           spi_master_sdo0_o;
   wire                           spi_master_sdo1_o;
   wire                           spi_master_sdo2_o;
   wire                           spi_master_sdo3_o;
   wire                           spi_master_sdi0_i;

   wire                           uart_rts;
   wire                           uart_dtr;

   peripherals  #(
                  .AXI_ADDR_WIDTH      ( `AXI_ADDR_WIDTH      ),
                  .AXI_DATA_WIDTH      ( `AXI_DATA_WIDTH      ),
                  .AXI_SLAVE_ID_WIDTH  ( `AXI_ID_SLAVE_WIDTH  ),
                  .AXI_MASTER_ID_WIDTH ( `AXI_ID_MASTER_WIDTH ),
                  .AXI_USER_WIDTH      ( `AXI_USER_WIDTH      )
                  )
   peripherals_i (
                  /////////////////////////////
                  .clk_i            ( clk_sys            ),
                  .rst_n            ( rstn_sys           ),

                  .axi_spi_master   ( masters[2]         ),
                  .axi_uart_master  ( masters[3]       ),   // Added to allow mastering axi from UART port , for debug over UART ,
                  // consider replacing/merging adv_dbg

                  .iedram_apb_bus   ( s_iedram_apb_bus   ),
                  .dedram_apb_bus   ( s_dedram_apb_bus   ),
                  .apb_debug        ( apb_debug          ),

                  .spi_clk_i        ( spi_clk_i          ),
                  .testmode_i       ( pad_testmode_i     ),
                  .spi_cs_i         ( spi_cs_i           ),
                  .spi_mode_o       ( spi_mode_o         ),
                  .spi_sdo0_o       ( spi_sdo0_o         ),
                  .spi_sdo1_o       ( spi_sdo1_o         ),
                  .spi_sdo2_o       ( spi_sdo2_o         ),
                  .spi_sdo3_o       ( spi_sdo3_o         ),
                  .spi_sdi0_i       ( spi_sdi0_i         ),
                  .spi_sdi1_i       ( spi_sdi1_i         ),
                  .spi_sdi2_i       ( spi_sdi2_i         ),
                  .spi_sdi3_i       ( spi_sdi3_i         ),

                  .slave            ( slaves[2]          ),

                  .uart_tx          ( pad_uart_tx        ),
                  .uart_rx          ( pad_uart_rx        ),
                  .uart_rts         ( uart_rts           ),
                  .uart_dtr         ( uart_dtr           ),
                  .uart_cts         ( uart_cts           ),
                  .uart_dsr         ( uart_dsr           ),

                  .spi_master_clk   ( spi_master_clk_o   ),
                  .spi_master_csn0  ( spi_master_csn0_o  ),
                  .spi_master_csn1  ( spi_master_csn1_o  ),
                  .spi_master_csn2  ( spi_master_csn2_o  ),
                  .spi_master_csn3  ( spi_master_csn3_o  ),
                  .spi_master_mode  ( spi_master_mode_o  ),
                  .spi_master_sdo0  ( spi_master_sdo0_o  ),
                  .spi_master_sdo1  ( spi_master_sdo1_o  ),
                  .spi_master_sdo2  ( spi_master_sdo2_o  ),
                  .spi_master_sdo3  ( spi_master_sdo3_o  ),
                  .spi_master_sdi0  ( spi_master_sdi0_i  ),
                  .spi_master_sdi1  ( spi_master_sdi1_i  ),
                  .spi_master_sdi2  ( spi_master_sdi2_i  ),
                  .spi_master_sdi3  ( spi_master_sdi3_i  ),

                  .scl_pad_i        ( pad_scl_i          ),
                  .scl_pad_o        ( pad_scl_o          ),
                  .scl_padoen_o     ( pad_scl_oen_o      ),
                  .sda_pad_i        ( pad_sda_i          ),
                  .sda_pad_o        ( pad_sda_o          ),
                  .sda_padoen_o     ( pad_sda_oen_o      ),

                  .gpio_in          ( gpio_in            ),
                  .gpio_out         ( gpio_out           ),
                  .gpio_dir         ( gpio_dir           ),
                  .gpio_padcfg      ( gpio_padcfg        ),

                  .core_busy_i      ( core_busy_int      ),
                  .irq_o            ( irq_to_core_int    ),
                  .fetch_enable_i   ( enable_core        ),
                  .fetch_enable_o   ( fetch_enable_int   ),
                  .clk_gate_core_o  ( clk_gate_core_int  ),

                  .pad_cfg_o        ( pad_cfg_o          ),
                  .pad_mux_o        ( pad_mux_o          ),
                  .boot_addr_o      ( boot_addr_int      ),

                  // GPP Interface (General Purpose Peripherals)

                  .gpp_hclk         ( ),
                  .gpp_hresetn      ( ),

                  .gpp_paddr        ( gpp_paddr          ),
                  .gpp_pwdata       ( gpp_pwdata         ),
                  .gpp_pwrite       ( gpp_pwrite         ),
                  .gpp_psel         ( gpp_psel           ),
                  .gpp_penable      ( gpp_penable        ),
                  .gpp_prdata       ( gpp_prdata         ),
                  .gpp_pready       ( gpp_pready         ),
                  .gpp_pslverr      ( gpp_pslverr        ),

                  .dma_bus          (masters[5]          ), // DMA master on AXI
                  .gpdma_done_intr  (gpdma_done_intr     ), 

                  .gpp_irq_out      ( o_gpp_irq_out      ),

                  .openocd_jtag     ( openocd_jtag       )
                  );

   //Mux SPI interfaces out
   //Output pads

   logic                          spi_master_sdo ;
   assign pad_spim_cs1        = spi_master_csn0_o  ;
   assign pad_spim_cs2        = spi_master_csn1_o  ;
   assign pad_spim_cs3        = spi_master_csn2_o  ;
   assign pad_spim_cs4        = spi_master_csn3_o  ;
   assign pad_spim_clk        = spi_master_clk_o ;   //Master
   assign spi_master_sdo      = !spi_master_csn0_o ? spi_master_sdo0_o :
                                !spi_master_csn1_o ? spi_master_sdo1_o :
                                !spi_master_csn2_o ? spi_master_sdo2_o : spi_master_sdo3_o ;
   assign pad_spim_do_spis_do = pad_spis_cs            ? spi_master_sdo    :  //Master if not cs of slave
                                spi_sdo0_o                             ;  //Slave meand cs of slave is down

   //Input pads
   assign spi_master_sdi0_i =  pad_spim_din1 ;
   assign spi_master_sdi1_i =  pad_spim_din2_spis_clk ;
   assign spi_master_sdi2_i =  pad_spim_din3_spis_di ;
   assign spi_master_sdi3_i =  pad_spim_din4 ;
   assign spi_cs_i          =  pad_spis_cs ; //Slave
   assign spi_clk_i         =  pad_spim_din2_spis_clk;
   assign spi_sdi0_i        =  pad_spim_din3_spis_di ;


   parameter APB_ADDR_WIDTH = 12; //APB slaves are 4KB by default

   //----------------------------------------------------------------------------//
   // Axi node
   //----------------------------------------------------------------------------//

`ifndef FLOO_CHIMNEY_DISABLED
   // xtrn (masters[4]/slaves[4]) is owned by Floo glue only — stub node port 4.
   AXI_BUS #(
     .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH      ),
     .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH      ),
     .AXI_ID_WIDTH   ( `AXI_ID_MASTER_WIDTH ),
     .AXI_USER_WIDTH ( `AXI_USER_WIDTH      )
   ) axi_xtrn_mst_stub ();

   AXI_BUS #(
     .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH     ),
     .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH     ),
     .AXI_ID_WIDTH   ( `AXI_ID_SLAVE_WIDTH ),
     .AXI_USER_WIDTH ( `AXI_USER_WIDTH     )
   ) axi_xtrn_slv_stub ();

   AXI_BUS #(
     .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH      ),
     .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH      ),
     .AXI_ID_WIDTH   ( `AXI_ID_MASTER_WIDTH ),
     .AXI_USER_WIDTH ( `AXI_USER_WIDTH      )
   ) axi_node_slaves[5:0]();

   AXI_BUS #(
     .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH     ),
     .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH     ),
     .AXI_ID_WIDTH   ( `AXI_ID_SLAVE_WIDTH ),
     .AXI_USER_WIDTH ( `AXI_USER_WIDTH     )
   ) axi_node_masters[4:0]();

   `AXI_DEGENERATE_MASTER(axi_xtrn_mst_stub)
   `AXI_DEGENERATE_SLAVE(axi_xtrn_slv_stub)

   `AXI_ASSIGN_SLAVE(axi_node_slaves[0], masters[0])
   `AXI_ASSIGN_SLAVE(axi_node_slaves[1], masters[1])
   `AXI_ASSIGN_SLAVE(axi_node_slaves[2], masters[2])
   `AXI_ASSIGN_SLAVE(axi_node_slaves[3], masters[3])
   `AXI_ASSIGN_SLAVE(axi_node_slaves[4], axi_xtrn_mst_stub)
   `AXI_ASSIGN_SLAVE(axi_node_slaves[5], masters[5])

   `AXI_ASSIGN_MASTER(axi_node_masters[0], slaves[0])
   `AXI_ASSIGN_MASTER(axi_node_masters[1], slaves[1])
   `AXI_ASSIGN_MASTER(axi_node_masters[2], slaves[2])
   `AXI_ASSIGN_MASTER(axi_node_masters[3], slaves[3])
   `AXI_ASSIGN_MASTER(axi_node_masters[4], axi_xtrn_slv_stub)
`endif

   axi_node_intf_wrap #(
                        .NB_MASTER      ( 5                    ),
                        .NB_SLAVE       ( 6                    ),
                        .AXI_ADDR_WIDTH ( `AXI_ADDR_WIDTH      ),
                        .AXI_DATA_WIDTH ( `AXI_DATA_WIDTH      ),
                        .AXI_ID_WIDTH   ( `AXI_ID_SLAVE_WIDTH  ),
                        .AXI_USER_WIDTH ( `AXI_USER_WIDTH      )
                        )
   axi_interconnect_i (
                       .clk       ( clk_sys           ),
                       .rst_n     ( rstn_sys         ),
                       .test_en_i ( pad_testmode_i   ),

`ifdef FLOO_CHIMNEY_DISABLED
                       .master    ( slaves           ),
                       .slave     ( masters          ),
`else
                       .master    ( axi_node_masters ),
                       .slave     ( axi_node_slaves  ),
`endif

                       .start_addr_i ( { 32'h1AC0_0000, 32'h1A80_0000, 32'h1A10_0000, 32'h0010_0000, 32'h0000_0000 } ),
                       .end_addr_i   ( { 32'hFFFF_FFFF, 32'h1ABF_FFFF, 32'h1A4F_FFFF, 32'h001F_FFFF, 32'h000F_FFFF } )
                       );

   //----------------------------------------------------------------------------//
   // Stage-1 FlooNoC: xtrn only (masters[4]/slaves[4]) through chimney + router
   //----------------------------------------------------------------------------//

   axi_in_req_t  chimney_mgr_req;
   axi_in_rsp_t  chimney_mgr_rsp;
   axi_out_req_t chimney_slv_req;
   axi_out_rsp_t chimney_slv_rsp;

   floo_req_t chimney_floo_req_o, chimney_floo_req_i;
   floo_rsp_t chimney_floo_rsp_o, chimney_floo_rsp_i;

   floo_req_t floo_north_req_in;
   floo_rsp_t floo_north_rsp_in;

   floo_req_t router_req_in [NumRoutes-1:0], router_req_out [NumRoutes-1:0];
   floo_rsp_t router_rsp_in [NumRoutes-1:0], router_rsp_out [NumRoutes-1:0];

`ifndef FLOO_CHIMNEY_DISABLED
   hamsa_floo_xtrn_glue #(
     .HAMSA_MGR_ID_WIDTH (`AXI_ID_MASTER_WIDTH),
     .HAMSA_SLV_ID_WIDTH (`AXI_ID_SLAVE_WIDTH)
   ) i_hamsa_floo_xtrn_glue (
     .xtrn_initiator ( masters[4]        ),
     .xtrn_target    ( slaves[4]         ),
     .chimney_mgr_req_o ( chimney_mgr_req ),
     .chimney_mgr_rsp_i ( chimney_mgr_rsp ),
     .chimney_slv_req_i ( chimney_slv_req ),
     .chimney_slv_rsp_o ( chimney_slv_rsp )
   );

   // axi_node target port 4 is stubbed; chimney axi_out still uses slaves[4] and needs ready.
   assign slaves[4].aw_ready = 1'b1;
   assign slaves[4].ar_ready = 1'b1;
   assign slaves[4].w_ready  = 1'b1;

   hamsa_floo_chimney_wrap #(
     .AxiCfg        ( AxiCfg        ),
     .ChimneyCfg    ( ChimneyCfg    ),
     .RouteCfg      ( RouteCfg      ),
     .AtopSupport   ( AtopSupport   ),
     .MaxAtomicTxns ( MaxAtomicTxns ),
     .id_t          ( id_t          ),
     .hdr_t         ( hdr_t         ),
     .axi_in_req_t  ( axi_in_req_t  ),
     .axi_in_rsp_t  ( axi_in_rsp_t  ),
     .axi_out_req_t ( axi_out_req_t ),
     .axi_out_rsp_t ( axi_out_rsp_t ),
     .floo_req_t    ( floo_req_t    ),
     .floo_rsp_t    ( floo_rsp_t    )
   ) u_hamsa_chimney (
     .clk_i           ( clk_sys              ),
     .rst_ni          ( rstn_sys             ),
     .test_enable_i   ( pad_testmode_i       ),
     .axi_in_req_i    ( chimney_mgr_req      ),
     .axi_in_rsp_o    ( chimney_mgr_rsp      ),
     .axi_out_req_o   ( chimney_slv_req      ),
     .axi_out_rsp_i   ( chimney_slv_rsp      ),
     .id_i            ( TileId               ),
     .flit_req_out_o  ( chimney_floo_req_o   ),
     .flit_rsp_out_o  ( chimney_floo_rsp_o   ),
     .flit_req_in_i   ( chimney_floo_req_i   ),
     .flit_rsp_in_i   ( chimney_floo_rsp_i   )
   );

   floo_axi_router #(
     .AxiCfg       ( AxiCfg       ),
     .RouteAlgo    ( floo_pkg::XYRouting ),
     .NumRoutes    ( NumRoutes    ),
     .NumInputs    ( NumRoutes    ),
     .NumOutputs   ( NumRoutes    ),
     .InFifoDepth  ( 2            ),
     .OutFifoDepth ( 2            ),
     .NoLoopback   ( 1'b0         ), // eject<->eject for local (0,0) tile
     .id_t         ( id_t         ),
     .hdr_t        ( hdr_t        ),
     .floo_req_t   ( floo_req_t   ),
     .floo_rsp_t   ( floo_rsp_t   )
   ) i_floo_axi_router (
     .clk_i         ( clk_sys        ),
     .rst_ni        ( rstn_sys       ),
     .test_enable_i ( pad_testmode_i ),
     .id_i          ( TileId         ),
     .id_route_map_i( '0             ),
     .floo_req_i    ( router_req_in  ),
     .floo_rsp_o    ( router_rsp_out ),
     .floo_req_o    ( router_req_out ),
     .floo_rsp_i    ( router_rsp_in  )
   );

   localparam int unsigned PortNorth = 0;
   localparam int unsigned PortEast  = 1;
   localparam int unsigned PortSouth = 2;
   localparam int unsigned PortWest  = 3;
   localparam int unsigned PortEject = 4;

   assign floo_north_req_in.req   = floo_north_req_i.req;
   assign floo_north_req_in.valid = floo_north_req_i.valid;
   assign floo_north_req_in.ready = 1'b1;
   assign floo_north_rsp_in.rsp   = floo_north_rsp_i.rsp;
   assign floo_north_rsp_in.valid = floo_north_rsp_i.valid;
   assign floo_north_rsp_in.ready = 1'b1;

   assign router_req_in[PortNorth]  = floo_north_req_in;
   assign floo_north_req_o          = router_req_out[PortNorth];
   assign floo_north_rsp_o          = router_rsp_out[PortNorth];
   assign router_rsp_in[PortNorth]  = floo_north_rsp_in;

   assign router_req_in[PortEast]  = '0;
   assign router_req_in[PortSouth] = '0;
   assign router_req_in[PortWest]  = '0;
   assign router_rsp_out[PortEast]  = '0;
   assign router_rsp_out[PortSouth] = '0;
   assign router_rsp_out[PortWest]  = '0;

   // Stage-1 single tile: comb eject loopback (router eject path still unused for North mesh)
   assign router_req_in[PortEject]  = '0;
   assign router_rsp_out[PortEject] = '0;
   assign router_rsp_in[PortEject]  = '0;

   assign chimney_floo_req_i.valid = chimney_floo_req_o.valid;
   assign chimney_floo_req_i.req   = chimney_floo_req_o.req;
   assign chimney_floo_req_i.ready = 1'b1;

   assign chimney_floo_rsp_i.valid = chimney_floo_rsp_o.valid;
   assign chimney_floo_rsp_i.rsp   = chimney_floo_rsp_o.rsp;
   assign chimney_floo_rsp_i.ready = 1'b1;

`else // FLOO_CHIMNEY_DISABLED — break test: xtrn isolated from NoC

   assign floo_north_req_o = '0;
   assign floo_north_rsp_o = '0;

`endif


   spi_top
    #(      // Parameters
      .SPI_NUM_OF_CS_EQ_4               (1'b0),
      .SPI_MEM_BASE                     (32'h1A80_0000),
      .SPI_CFG_BASE                     (32'h1AC0_0000),
      .SPI_MEM_CS_SIZE                  (22),
      .SPI_CFG_CS_SIZE                  (10),
      .SPI_IS_BOOT                      (1))
   I_mmspi_top (
                // Outputs
                .mmspi_axiarready_i     (slaves[3].ar_ready),
                .mmspi_axiawready_i     (slaves[3].aw_ready),
                .mmspi_axibresp_i       (slaves[3].b_resp[1:0]),
                .mmspi_axibvalid_i      (slaves[3].b_valid),
                .mmspi_axirdata_i       (slaves[3].r_data[31:0]),
                .mmspi_axirlast_i       (slaves[3].r_last),
                .mmspi_axirresp_i       (slaves[3].r_resp[1:0]),
                .mmspi_axirvalid_i      (slaves[3].r_valid),
                .mmspi_axiwready_i      (slaves[3].w_ready),
                .mmspi_axibid_i         (slaves[3].b_id[4:0]),
                .mmspi_axibuser_i       (slaves[3].b_user),
                .mmspi_axirid_i         (slaves[3].r_id[4:0]),
                .mmspi_axiruser_i       (slaves[3].r_user),
                .mmspi_bad_addr_irq     (),
                .mmspi_bad_addr_unmsk_irq(),
                .mmspi_intr_o           (),
                .mmspi_cs_o             (pad_mmspi_cs_o[3:0]),
                .mmspi_dclk_o           (pad_mmspi_dclk_o),
                .mmspi_dout_o           (pad_mmspi_dout_o),
                .mmspi_dout_oe_n        (pad_mmspi_dout_oe_n),
                .mmspi_disable_ack      (),
                // Inputs
                .big_endian             (1'b0),
                .test_mode              (1'b0),
                .scan_mode              (1'b0),
                .dft_clk_en             (1'b0),
                .phy_cg_sel             (2'b00),
                .scan_enable            (1'b0),
                .mmspi_clk              (clk_sys),
                .mmspi_rst_n            (rstn_sys),
                .mmspi_axiaraddr_o      (slaves[3].ar_addr[31:0]),
                .mmspi_axiarburst_o     (slaves[3].ar_burst[1:0]),
                .mmspi_axiarcache_o     (slaves[3].ar_cache[3:0]),
                .mmspi_axiarlen_o       (slaves[3].ar_len[7:0]),
                .mmspi_axiarlock_o      (slaves[3].ar_lock),
                .mmspi_axiarprot_o      (slaves[3].ar_prot[2:0]),
                .mmspi_axiarsize_o      (slaves[3].ar_size[2:0]),
                .mmspi_axiarvalid_o     (slaves[3].ar_valid),
                .mmspi_axiarid_o        (slaves[3].ar_id[4:0]),
                .mmspi_axiarqos_o       (slaves[3].ar_qos[3:0]),
                .mmspi_axiarregion_o    (slaves[3].ar_region[3:0]),
                .mmspi_axiaruser_o      (slaves[3].ar_user),
                .mmspi_axiawaddr_o      (slaves[3].aw_addr[31:0]),
                .mmspi_axiawburst_o     (slaves[3].aw_burst[1:0]),
                .mmspi_axiawcache_o     (slaves[3].aw_cache[3:0]),
                .mmspi_axiawlen_o       (slaves[3].aw_len[7:0]),
                .mmspi_axiawlock_o      (slaves[3].aw_lock),
                .mmspi_axiawprot_o      (slaves[3].aw_prot[2:0]),
                .mmspi_axiawsize_o      (slaves[3].aw_size[2:0]),
                .mmspi_axiawvalid_o     (slaves[3].aw_valid),
                .mmspi_axibready_o      (slaves[3].b_ready),
                .mmspi_axirready_o      (slaves[3].r_ready),
                .mmspi_axiwdata_o       (slaves[3].w_data[31:0]),
                .mmspi_axiwlast_o       (slaves[3].w_last),
                .mmspi_axiwstrb_o       (slaves[3].w_strb[3:0]),
                .mmspi_axiwvalid_o      (slaves[3].w_valid),
                .mmspi_axiawid_o        (slaves[3].aw_id[4:0]),
                .mmspi_axiawqos_o       (slaves[3].aw_qos[3:0]),
                .mmspi_axiawregion_o    (slaves[3].aw_region[3:0]),
                .mmspi_axiawuser_o      (slaves[3].aw_user),
                .mmspi_axiwuser_o       (slaves[3].w_user),
                .mmspi_req_mode_ival    (2'b00),
                .mmspi_d_clk            (mmspi_d_clk),
                .mmspi_dclk_i           (pad_mmspi_dclk_i),
                .mmspi_din_i            (pad_mmspi_din_i),
                .mmspi_dout_i           (pad_mmspi_dout_i),
                .mmspi_disable_req      (1'b0));


endmodule
