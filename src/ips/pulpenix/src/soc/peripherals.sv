// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "axi_bus.sv"
`include "apb_bus.sv"
`include "config.sv"
`include "remote_access_intrfc.sv"

module peripherals
  #(
    parameter AXI_ADDR_WIDTH       = 32,
    parameter AXI_DATA_WIDTH       = 64,
    parameter AXI_USER_WIDTH       = 6,
    parameter AXI_SLAVE_ID_WIDTH   = 6,
    parameter AXI_MASTER_ID_WIDTH  = 6,
    parameter ROM_START_ADDR       =  32'h0000  // 32'h0080  // 32'h8000 ori edit 17/6/19
                                      // Udi Changed back to 0 on 16/10/2019 , to make it work by  default with out the need to load a boot address over JTAG
  )
  (
    // Clock and Reset

    input logic clk_i,
    input logic rst_n,

    AXI_BUS.Master axi_spi_master,
    AXI_BUS.Master axi_uart_master,   // Added to allow mastering axi from UART port , for debug over UART ,
                                      // consider replacing/merging adv_dbg
    AXI_BUS.Master dma_bus,
                                         
    APB_BUS.Master iedram_apb_bus,
    APB_BUS.Master dedram_apb_bus,
    APB_BUS.Master apb_debug,

    input  logic             spi_clk_i,
    input  logic             testmode_i,
    input  logic             spi_cs_i,
    output logic [1:0]       spi_mode_o,
    output logic             spi_sdo0_o,
    output logic             spi_sdo1_o,
    output logic             spi_sdo2_o,
    output logic             spi_sdo3_o,
    input  logic             spi_sdi0_i,
    input  logic             spi_sdi1_i,
    input  logic             spi_sdi2_i,
    input  logic             spi_sdi3_i,

    AXI_BUS.Slave  slave,

    output logic              uart_tx,
    input logic               uart_rx,

    output logic              uart_rts,
    output logic              uart_dtr,

    input logic               uart_cts,
    input logic               uart_dsr,

    output logic              spi_master_clk,
    output logic              spi_master_csn0,
    output logic              spi_master_csn1,
    output logic              spi_master_csn2,
    output logic              spi_master_csn3,
    output logic [1:0]        spi_master_mode,
    output logic              spi_master_sdo0,
    output logic              spi_master_sdo1,
    output logic              spi_master_sdo2,
    output logic              spi_master_sdo3,
    input logic               spi_master_sdi0,
    input logic               spi_master_sdi1,
    input logic               spi_master_sdi2,
    input logic               spi_master_sdi3,

    input logic               scl_pad_i,
    output logic              scl_pad_o,
    output logic              scl_padoen_o,
    input logic               sda_pad_i,
    output logic              sda_pad_o,
    output logic              sda_padoen_o,

    input logic [31:0]        gpio_in,
    output logic [31:0]       gpio_out,
    output logic [31:0]       gpio_dir,
    output logic [31:0] [5:0] gpio_padcfg,

    input logic               core_busy_i,
    output logic [31:0]       irq_o,
    input logic               fetch_enable_i,
    output logic              fetch_enable_o,
    output logic              clk_gate_core_o,

    output logic [31:0] [5:0] pad_cfg_o,
    output logic [31:0]       pad_mux_o,
    output logic [31:0]       boot_addr_o,

    // APB GPP interface (General Peripheral Port)

    output        gpp_hclk      ,
    output        gpp_hresetn   ,
    output [22:0] gpp_paddr     ,
    output [31:0] gpp_pwdata    ,
    output        gpp_pwrite    ,
    output        gpp_psel      ,
    output        gpp_penable   ,

    input  [31:0] gpp_prdata    ,
    input         gpp_pready    ,
    input         gpp_pslverr   ,

    // GPDMA 
    output [3:0]  gpdma_done_intr,
    
    input  [22:0] gpp_irq_out    ,
    OPENOCD_JTAG.master openocd_jtag

  );

  localparam APB_ADDR_WIDTH  = 32;

  REMOTE_ACCESS_INTRFC  remote_access_bus() ;

  APB_BUS s_apb_bus();

  APB_BUS s_uart_bus();
  APB_BUS s_gpio_bus();
  APB_BUS s_spi_bus();
  APB_BUS s_timer_bus();
  APB_BUS s_event_unit_bus();
  APB_BUS s_i2c_bus();
  APB_BUS s_gpp_bus();
  APB_BUS s_soc_ctrl_bus();
  APB_BUS s_gp_dma_apb_bus();

  logic [1:0]   s_spim_event;
  logic [3:0]   timer_irq;
  logic [31:0]  peripheral_clock_gate_ctrl;
  logic [31:0]  clk_int;
  logic         s_uart_event;
  logic         i2c_event;
  logic         s_gpio_event;

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// Peripheral Clock Gating                                    ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////
  localparam APB_NUM_CG_SLAVES  = 9;
  generate
     genvar i;
       for (i = 0; i < APB_NUM_CG_SLAVES; i = i + 1) begin : ans // label added by Udi 28/Feb/2019 required by Quartus
        cluster_clock_gating core_clock_gate
        (
          .clk_o     ( clk_int[i]                    ),
          .en_i      ( peripheral_clock_gate_ctrl[i] ),
          .test_en_i ( testmode_i                    ),
          .clk_i     ( clk_i                         )
        );
      end
   endgenerate

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// SPI Slave, AXI Master                                      ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  axi_spi_slave_wrap
  #(
    .AXI_ADDRESS_WIDTH  ( AXI_ADDR_WIDTH       ),
    .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH     ( AXI_USER_WIDTH       ),
    .AXI_ID_WIDTH       ( AXI_MASTER_ID_WIDTH  )
  )
  axi_spi_slave_i
  (
    .clk_i      ( clk_int[0]     ),
    .rst_ni     ( rst_n          ),

    .test_mode  ( testmode_i     ),

    .axi_master ( axi_spi_master ),

    .spi_clk    ( spi_clk_i      ),
    .spi_cs     ( spi_cs_i       ),
    .spi_mode   ( spi_mode_o     ),
    .spi_sdo0   ( spi_sdo0_o     ),
    .spi_sdo1   ( spi_sdo1_o     ),
    .spi_sdo2   ( spi_sdo2_o     ),
    .spi_sdo3   ( spi_sdo3_o     ),
    .spi_sdi0   ( spi_sdi0_i     ),
    .spi_sdi1   ( spi_sdi1_i     ),
    .spi_sdi2   ( spi_sdi2_i     ),
    .spi_sdi3   ( spi_sdi3_i     )
  );


  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// Uart interfaced slave, AXI Master                          ///
  /// UART interface is mater on AXI bus                         ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  axi_uart_slave // meaning: UART interface master on AXI (confusing...)
  #(
    .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH       ),
    .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH     ( AXI_USER_WIDTH       ),
    .AXI_ID_WIDTH       ( AXI_MASTER_ID_WIDTH  )
  )
  axi_uart_slave_i
  (
    .clk_i      ( clk_int[1]     ), // Currently using same gater as the APB slave uart, consider a dedicated programmable gate
    .rst_ni     ( rst_n          ),

    .axi_master ( axi_uart_master ),

    .remote_access_intrfc (remote_access_bus.near)

  );



  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// AXI2APB Bridge                                             ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  axi2apb_wrap
  #(
      .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH     ),
      .AXI_ID_WIDTH   ( AXI_SLAVE_ID_WIDTH ),
      .APB_ADDR_WIDTH ( APB_ADDR_WIDTH     )
  )
  axi2apb_i
  (
    .clk_i     ( clk_i      ),
    .rst_ni    ( rst_n      ),
    .test_en_i ( testmode_i ),

    .axi_slave ( slave      ),

    .apb_master( s_apb_bus.Master  )
  );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Bus                                                    ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  periph_bus_wrap
  #(
     .APB_ADDR_WIDTH( APB_ADDR_WIDTH ),
     .APB_DATA_WIDTH( 32             )
  )
  periph_bus_i
  (
     .clk_i             ( clk_i            ),
     .rst_ni            ( rst_n            ),

     .apb_slave         ( s_apb_bus.Slave  ),

     .uart_master       ( s_uart_bus       ),
     .gpio_master       ( s_gpio_bus       ),
     .spi_master        ( s_spi_bus        ),
     .timer_master      ( s_timer_bus      ),
     .event_unit_master ( s_event_unit_bus ),
     .i2c_master        ( s_i2c_bus        ),
     .gpp_master        ( s_gpp_bus        ),
     .soc_ctrl_master   ( s_soc_ctrl_bus   ),
     .debug_master      ( apb_debug        ),
     .iedram_master     ( iedram_apb_bus ),
     .dedram_master     ( dedram_apb_bus ),
     .gpdma_master      ( s_gp_dma_apb_bus )
  );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 0: APB UART interface                            ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  apb_uart_sv
    #(
       .APB_ADDR_WIDTH( 3 )
    )
    apb_uart_sv_i
    (
      .CLK      ( clk_int[1]            ),
      .RSTN     ( rst_n                 ),

      .PSEL     ( s_uart_bus.psel       ),
      .PENABLE  ( s_uart_bus.penable    ),
      .PWRITE   ( s_uart_bus.pwrite     ),
      .PADDR    ( s_uart_bus.paddr[4:2] ),
      .PWDATA   ( s_uart_bus.pwdata     ),
      .PRDATA   ( s_uart_bus.prdata     ),
      .PREADY   ( s_uart_bus.pready     ),
      .PSLVERR  ( s_uart_bus.pslverr    ),

      .rx_i     ( uart_rx               ),
      .tx_o     ( uart_tx               ),
      .event_o  ( s_uart_event          ),

      // The apb UART interface  also side-transport the axi uart stream
      // both share a single uart physical interface.

       .remote_access_intrfc (remote_access_bus.remote),
       .openocd_jtag(openocd_jtag)

    );


  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 1: APB GPIO interface                            ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  apb_gpio apb_gpio_i
  (
    .HCLK       ( clk_int[2]   ),
    .HRESETn    ( rst_n        ),

    .PADDR      ( s_gpio_bus.paddr[11:0]),
    .PWDATA     ( s_gpio_bus.pwdata     ),
    .PWRITE     ( s_gpio_bus.pwrite     ),
    .PSEL       ( s_gpio_bus.psel       ),
    .PENABLE    ( s_gpio_bus.penable    ),
    .PRDATA     ( s_gpio_bus.prdata     ),
    .PREADY     ( s_gpio_bus.pready     ),
    .PSLVERR    ( s_gpio_bus.pslverr    ),

    .gpio_in      ( gpio_in       ),
    .gpio_out     ( gpio_out      ),
    .gpio_dir     ( gpio_dir      ),
    .gpio_padcfg  ( gpio_padcfg   ),
    .interrupt    ( s_gpio_event  ),

    .gpio_in_sync(), // Modified by Udi 28/Feb/2019 Not used, clean compile warnings
    .power_event()   // Modified by Udi 28/Feb/2019 Not used, clean compile warnings

  );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 2: APB SPI Master interface                      ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  apb_spi_master
  #(
      .BUFFER_DEPTH(8)
  )
  apb_spi_master_i
  (
    .HCLK         ( clk_int[3]   ),
    .HRESETn      ( rst_n        ),

    .PADDR        ( s_spi_bus.paddr[11:0]),
    .PWDATA       ( s_spi_bus.pwdata     ),
    .PWRITE       ( s_spi_bus.pwrite     ),
    .PSEL         ( s_spi_bus.psel       ),
    .PENABLE      ( s_spi_bus.penable    ),
    .PRDATA       ( s_spi_bus.prdata     ),
    .PREADY       ( s_spi_bus.pready     ),
    .PSLVERR      ( s_spi_bus.pslverr    ),

    .events_o     ( s_spim_event ),

    .spi_clk      ( spi_master_clk  ),
    .spi_csn0     ( spi_master_csn0 ),
    .spi_csn1     ( spi_master_csn1 ),
    .spi_csn2     ( spi_master_csn2 ),
    .spi_csn3     ( spi_master_csn3 ),
    .spi_mode     ( spi_master_mode ),
    .spi_sdo0     ( spi_master_sdo0 ),
    .spi_sdo1     ( spi_master_sdo1 ),
    .spi_sdo2     ( spi_master_sdo2 ),
    .spi_sdo3     ( spi_master_sdo3 ),
    .spi_sdi0     ( spi_master_sdi0 ),
    .spi_sdi1     ( spi_master_sdi1 ),
    .spi_sdi2     ( spi_master_sdi2 ),
    .spi_sdi3     ( spi_master_sdi3 )
  );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 3: Timer Unit                                    ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  apb_timer
  apb_timer_i
  (
    .HCLK       ( clk_int[4]   ),
    .HRESETn    ( rst_n        ),

    .PADDR      ( s_timer_bus.paddr[11:0]),
    .PWDATA     ( s_timer_bus.pwdata     ),
    .PWRITE     ( s_timer_bus.pwrite     ),
    .PSEL       ( s_timer_bus.psel       ),
    .PENABLE    ( s_timer_bus.penable    ),
    .PRDATA     ( s_timer_bus.prdata     ),
    .PREADY     ( s_timer_bus.pready     ),
    .PSLVERR    ( s_timer_bus.pslverr    ),

    .irq_o      ( timer_irq    )
  );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 4: Event Unit                                    ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  //noytzach: Not all interrupt inputs can be used according to v1.11 spec. 
  //Specifically irq_i[15:12], irq_i[10:8], irq_i[6:4] and irq_i[2:0] shall be tied to 0
  //as they are reserved for future use or U/S modes in the RISC-V Privileged specification.
  //31:24 - gpp
  //23:21 - timer (3/2/0), timer[1] is irq[7]
  //20:19 - spim
  //   18 - gpio
  //   17 - uart
  //   16 - i2c
  //15:12 - disabled (rv spec)
  //   11 - Machine External Interrupt (MEI) (timer/spim/gpio/uart/i2c/gpp)
  //10: 8 - disabled (rv spec) 
  //    7 - Machine Timer Interrupt (MTI) - timer[1]
  // 6: 4 - disabled (rv spec)  
  //    3 - Machine Software Interrupt (MSI) - TODO
  // 2: 0 - disabled (rv spec)
  logic [31:0] irq_i;
  assign irq_i[31:16] = {gpp_irq_out[7:0], timer_irq[3:2], timer_irq[0], s_spim_event[1:0], s_gpio_event, s_uart_event, i2c_event};
  assign irq_i[15:12] = 'h0;
  assign irq_i[11]    = |{timer_irq[3:2], timer_irq[0], s_spim_event, s_gpio_event, s_uart_event, i2c_event, gpp_irq_out};
  assign irq_i[10:8]  = 'h0;
  assign irq_i[7]     = timer_irq[1];
  assign irq_i[6:4]   = 'h0;
  assign irq_i[3]     = 1'b0; //TODO: connect to MSI_int
  assign irq_i[2:0]   = 'h0;

  apb_event_unit
  apb_event_unit_i
  (
    .clk_i            ( clk_i        ),
    .HCLK             ( clk_int[5]   ),
    .HRESETn          ( rst_n        ),

    .PADDR            ( s_event_unit_bus.paddr[11:0]),
    .PWDATA           ( s_event_unit_bus.pwdata     ),
    .PWRITE           ( s_event_unit_bus.pwrite     ),
    .PSEL             ( s_event_unit_bus.psel       ),
    .PENABLE          ( s_event_unit_bus.penable    ),
    .PRDATA           ( s_event_unit_bus.prdata     ),
    .PREADY           ( s_event_unit_bus.pready     ),
    .PSLVERR          ( s_event_unit_bus.pslverr    ),

    .irq_i            ( irq_i ),
    .event_i          ( irq_i ),
    .irq_o            ( irq_o ),

    .fetch_enable_i   ( fetch_enable_i     ),
    .fetch_enable_o   ( fetch_enable_o     ),
    .clk_gate_core_o  ( clk_gate_core_o    ),
    .core_busy_i      ( core_busy_i        )
  );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 5: I2C                                           ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

  apb_i2c
  apb_i2c_i
  (
    .HCLK         ( clk_int[6]    ),
    .HRESETn      ( rst_n         ),

    .PADDR        ( s_i2c_bus.paddr[11:0] ),
    .PWDATA       ( s_i2c_bus.pwdata      ),
    .PWRITE       ( s_i2c_bus.pwrite      ),
    .PSEL         ( s_i2c_bus.psel        ),
    .PENABLE      ( s_i2c_bus.penable     ),
    .PRDATA       ( s_i2c_bus.prdata      ),
    .PREADY       ( s_i2c_bus.pready      ),
    .PSLVERR      ( s_i2c_bus.pslverr     ),
    .interrupt_o  ( i2c_event     ),
    .scl_pad_i    ( scl_pad_i     ),
    .scl_pad_o    ( scl_pad_o     ),
    .scl_padoen_o ( scl_padoen_o  ),
    .sda_pad_i    ( sda_pad_i     ),
    .sda_pad_o    ( sda_pad_o     ),
    .sda_padoen_o ( sda_padoen_o  )
  );


  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  ///  APB Slave 6: GPP Ctrl                                     ///
  ///  General Purpose Port, replaced FLL                        ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

   // Outputs to Slave
   assign gpp_hclk     = clk_int[7]            ;
   assign gpp_hresetn  = rst_n                 ;
   assign gpp_paddr    = s_gpp_bus.paddr[22:0] ;
   assign gpp_pwdata   = s_gpp_bus.pwdata      ;
   assign gpp_pwrite   = s_gpp_bus.pwrite      ;
   assign gpp_psel     = s_gpp_bus.psel        ;
   assign gpp_penable  = s_gpp_bus.penable     ;

   // Inputs from Slave
   assign s_gpp_bus.prdata   = gpp_prdata   ;
   assign s_gpp_bus.pready   = gpp_pready   ;
   assign s_gpp_bus.pslverr  = gpp_pslverr  ;


  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 7: PULPino control                               ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////

    apb_pulpino
`ifndef ALTERA
    #(
      .BOOT_ADDR (32'h0035_0000)  // ( ROM_START_ADDR ) // Udi Currently booting from address 0
    )
`endif	 
    apb_pulpino_i
    (
      .HCLK             ( clk_i                      ),
      .HRESETn          ( rst_n                      ),

      .PADDR            ( s_soc_ctrl_bus.paddr[11:0] ),
      .PWDATA           ( s_soc_ctrl_bus.pwdata      ),
      .PWRITE           ( s_soc_ctrl_bus.pwrite      ),
      .PSEL             ( s_soc_ctrl_bus.psel        ),
      .PENABLE          ( s_soc_ctrl_bus.penable     ),
      .PRDATA           ( s_soc_ctrl_bus.prdata      ),
      .PREADY           ( s_soc_ctrl_bus.pready      ),
      .PSLVERR          ( s_soc_ctrl_bus.pslverr     ),

      .pad_cfg_o        ( pad_cfg_o                  ),
      .clk_gate_o       ( peripheral_clock_gate_ctrl ),
      .pad_mux_o        ( pad_mux_o                  ),
      .boot_addr_o      ( boot_addr_o                )
    );

  //////////////////////////////////////////////////////////////////
  ///                                                            ///
  /// APB Slave 9: GPDMA                                         ///
  ///                                                            ///
  //////////////////////////////////////////////////////////////////
   assign dma_bus.aw_id = 'h0;
   assign dma_bus.ar_id = 'h0;

   gp_dma_top I_gp_dma_top (
                         
                         .gpdma_disable_ack     (),              
                         .gpdma_done_intr       (gpdma_done_intr[3:0]),
                         .gp_dma_axiaraddr_i    (dma_bus.ar_addr[31:0]), 
                         .gp_dma_axiarburst_i   (dma_bus.ar_burst[1:0]), 
                         .gp_dma_axiarcache_i   (dma_bus.ar_cache[3:0]), 
                         .gp_dma_axiarlen_i     (dma_bus.ar_len[7:0]), 
                         .gp_dma_axiarlock_i    (dma_bus.ar_lock), 
                         .gp_dma_axiarprot_i    (dma_bus.ar_prot[2:0]), 
                         .gp_dma_axiarsize_i    (dma_bus.ar_size[2:0]), 
                         .gp_dma_axiarvalid_i   (dma_bus.ar_valid), 
                         .gp_dma_axiawaddr_i    (dma_bus.aw_addr[31:0]), 
                         .gp_dma_axiawburst_i   (dma_bus.aw_burst[1:0]), 
                         .gp_dma_axiawcache_i   (dma_bus.aw_cache[3:0]), 
                         .gp_dma_axiawlen_i     (dma_bus.aw_len[7:0]), 
                         .gp_dma_axiawlock_i    (dma_bus.aw_lock), 
                         .gp_dma_axiawprot_i    (dma_bus.aw_prot[2:0]), 
                         .gp_dma_axiawsize_i    (dma_bus.aw_size[2:0]), 
                         .gp_dma_axiawvalid_i   (dma_bus.aw_valid), 
                         .gp_dma_axibready_i    (dma_bus.b_ready), 
                         .gp_dma_axirready_i    (dma_bus.r_ready), 
                         .gp_dma_axiwdata_i     (dma_bus.w_data[31:0]), 
                         .gp_dma_axiwlast_i     (dma_bus.w_last), 
                         .gp_dma_axiwstrb_i     (dma_bus.w_strb[3:0]), 
                         .gp_dma_axiwvalid_i    (dma_bus.w_valid), 
                         .gp_dma_apbprdata_i    (s_gp_dma_apb_bus.prdata[31:0]), 
                         .gp_dma_apbpready_i    (s_gp_dma_apb_bus.pready), 
                         .gp_dma_apbpslverr_i   (s_gp_dma_apb_bus.pslverr), 
                         
                         .fp_sgn_clk            (clk_int[8]),       
                         .fp_sgn_rst_n          (rst_n),     
                         .gpdma_clk_dis         (1'b0),          
                         .gpdma_clk             (clk_i),       
                         .gpdma_rst_n           (rst_n),     
                         .big_endian            (1'b0),          
                         .gpdma_disable_req     (1'b0),          
                         .gp_dma_axiarready_o   (dma_bus.ar_ready), 
                         .gp_dma_axiawready_o   (dma_bus.aw_ready), 
                         .gp_dma_axibresp_o     (dma_bus.b_resp[1:0]), 
                         .gp_dma_axibvalid_o    (dma_bus.b_valid), 
                         .gp_dma_axirdata_o     (dma_bus.r_data[31:0]), 
                         .gp_dma_axirlast_o     (dma_bus.r_last), 
                         .gp_dma_axirresp_o     (dma_bus.r_resp[1:0]), 
                         .gp_dma_axirvalid_o    (dma_bus.r_valid), 
                         .gp_dma_axiwready_o    (dma_bus.w_ready), 
                         .gp_dma_apbpaddr_o     (s_gp_dma_apb_bus.paddr[7:0]), 
                         .gp_dma_apbpenable_o   (s_gp_dma_apb_bus.penable), 
                         .gp_dma_apbpreset_no   (rst_n),     
                         .gp_dma_apbpsel_o      (s_gp_dma_apb_bus.psel), 
                         .gp_dma_apbpwdata_o    (s_gp_dma_apb_bus.pwdata[31:0]), 
                         .gp_dma_apbpwrite_o    (s_gp_dma_apb_bus.pwrite)); 

  




endmodule
