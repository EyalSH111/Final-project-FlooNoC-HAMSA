
`include "apb_bus.sv"
`include "axi_bus.sv"
`include "config.sv"

module Xcore_region
#(
    parameter AXI_ADDR_WIDTH       = 32,
    parameter AXI_DATA_WIDTH       = 64,
    parameter AXI_ID_MASTER_WIDTH  = 10,
    parameter AXI_ID_SLAVE_WIDTH   = 10,
    parameter AXI_USER_WIDTH       = 0,
    parameter DATA_RAM_SIZE        = 32768*2,   // in bytes
    parameter INSTR_RAM_SIZE       = 32768*2, // in bytes (Default Sansa memory configuration)
    parameter RISCY_RV32F          = 0,
     
    `ifdef TSMC16
    parameter INSTR_MEM_CTRL_DW    = 4,
    parameter DATA_MEM_CTRL_DW     = 4,
    `else
    parameter INSTR_MEM_CTRL_DW    = 6,
    parameter DATA_MEM_CTRL_DW     = 5,
    `endif

    parameter IMEM_MASK            = 32'hfff_00000,
    parameter IMEM_BASE            = `MIN_XCORE_IMEM,
    parameter DMEM_MASK            = 32'hfff_00000,
    parameter DMEM_BASE            = `MIN_XCORE_DMEM,

    localparam CORE_MEM_CTR_DW     = DATA_MEM_CTRL_DW + INSTR_MEM_CTRL_DW
  )
  (
    // Clock and Reset
    input logic                        clk,
    input logic                        rst_n,
    input logic                        apor_n,
    input logic                        clk_ref,
    input logic                        regfile_select_i,
    input logic                        instr_ram_sel_i, // 0 - SRAM, 1 - EDRAM
    input logic                        data_ram_sel_i, // 0 - SRAM, 1 - EDRAM

    input logic                        testmode_i,
    input logic                        fetch_enable_i,
    input logic [31:0]                 irq_i,
    output logic                       core_busy_o,
    input logic                        clock_gating_i,
    input logic [31:0]                 boot_addr_i,

    AXI_BUS.Master                     core_master,
    AXI_BUS.Master                     dbg_master,
    AXI_BUS.Slave                      data_slave,
    AXI_BUS.Slave                      instr_slave,
    APB_BUS.Slave                      iedram_apb,
    APB_BUS.Slave                      dedram_apb,
    APB_BUS.Slave                      apb_debug,

    // JTAG signals
    input logic                        jtag_sel,
    input logic                        tck_i,
    input logic                        trstn_i,
    input logic                        tms_i,
    input logic                        tdi_i,
    output logic                       tdo_o,

    output logic                       ndmreset,

    //RAM configuration
    input logic [CORE_MEM_CTR_DW-1:0]  ram_ctrl,

    OPENOCD_JTAG.slave openocd_jtag,
	
	// XBOX mem TCM dmem interface	
	// xbox mem -> core_region
    input                           xbox_dmem_rready,                        
    input  [31:0]                   xbox_dmem_rdata, 
    input                           xbox_dmem_wready,   
    // core region -> xbox mem
    output logic                    xbox_dmem_rvalid,
    output [18:0]                   xbox_dmem_addr,
    output logic                    xbox_dmem_wvalid,
    output [31:0]                   xbox_dmem_wdata,
    output [3:0]                    xbox_dmem_wbe 
  );

 
  localparam MIN_XBOX_TCM_DMEM   = `MIN_XBOX_TCM_DMEM  ;
  localparam MAX_XBOX_TCM_DMEM   = `MAX_XBOX_TCM_DMEM  ;

  `ifdef HAMSA_DIX  // Dual-Issue Logic optional instantiation
  localparam INSTR_RDATA_WIDTH = 128 ; // for DI INSTR_RDATA_WIDTH Must be multiples of 128 (initially 128)
  localparam HAMSA_INSTR_MUX = 4;
  `else
  localparam INSTR_RDATA_WIDTH = 32 ;  // compatible with original hard coded width
  localparam HAMSA_INSTR_MUX = 16;
  `endif

  // Mem Config
 
  localparam DATA_RAM_WIDTH  = 32;
  localparam DATA_RAM_MUX    = 16;

  localparam INSTR_RAM_WIDTH = INSTR_RDATA_WIDTH;
  localparam INSTR_RAM_MUX   = HAMSA_INSTR_MUX;

  localparam INSTR_ADDR_WIDTH = $clog2(INSTR_RAM_SIZE)+1; // extra bit for edram/sram sel. boot rom is obsolete
  localparam DATA_ADDR_WIDTH  = $clog2(DATA_RAM_SIZE)+ 1; // extra_bit for edram/sram sel

  localparam AXI_B_WIDTH      = $clog2(AXI_DATA_WIDTH/8); // AXI "Byte" width
  localparam DATA_CORE_WIDTH  = 32;

  // EDRAM config 
  localparam INSTR_RAM_ADDR_W=$clog2(INSTR_RAM_SIZE);  
  localparam DATA_RAM_ADDR_W =$clog2(DATA_RAM_SIZE);  
  //edram params
  localparam EDRAM_WIDTH=64;
  localparam EDRAM_DEPTH=4096;
  localparam EDRAM_DEPTH_W=$clog2(EDRAM_DEPTH);
  //instr array params
  localparam  INSTR_ARR_INST_WIDTH = 2;
  localparam  INSTR_ARR_INST_DEPTH = INSTR_RAM_SIZE/(INSTR_ARR_INST_WIDTH*EDRAM_DEPTH*EDRAM_WIDTH/8);
  localparam  INSTR_ARR_WIDTH=EDRAM_WIDTH*INSTR_ARR_INST_WIDTH;
  localparam  INSTR_ARR_DEPTH=EDRAM_DEPTH*INSTR_ARR_INST_DEPTH;
  localparam  INSTR_ARR_DEPTH_W=$clog2(INSTR_ARR_DEPTH);
  //data array params
  localparam  DATA_ARR_INST_WIDTH = 2;
  localparam  DATA_ARR_INST_DEPTH = DATA_RAM_SIZE/(DATA_ARR_INST_WIDTH*EDRAM_DEPTH*EDRAM_WIDTH/8);
  localparam  DATA_ARR_WIDTH=EDRAM_WIDTH*DATA_ARR_INST_WIDTH;
  localparam  DATA_ARR_DEPTH=EDRAM_DEPTH*DATA_ARR_INST_DEPTH;
  localparam  DATA_ARR_DEPTH_W=$clog2(DATA_ARR_DEPTH);
  //bist
  parameter HAS_BIST = 0;

  // signals from/to core
  logic         debug_req;

  logic         core_instr_req; //core_instr_* is the core's instruction bus
  logic         core_instr_gnt;
  logic         core_instr_rvalid;
  logic [31:0]  core_instr_addr;
  logic [INSTR_RDATA_WIDTH-1:0]  core_instr_rdata;

  logic         core_imem_req; //core_imem_* is core_instr_* towards internal ICache
  logic         core_imem_gnt;
  logic         core_imem_rvalid;
  logic [31:0]  core_imem_addr;
  logic [INSTR_RDATA_WIDTH-1:0]  core_imem_rdata;

  logic         core_lsu_req; //core_lsu_* is the core's data bus
  logic         core_lsu_gnt;
  logic         core_lsu_rvalid;
  logic [31:0]  core_lsu_addr;
  logic         core_lsu_we;

  logic [(DATA_CORE_WIDTH/8)-1:0] core_lsu_be;
  logic [DATA_CORE_WIDTH-1:0]     core_lsu_rdata;
  logic [DATA_CORE_WIDTH-1:0]     core_lsu_wdata;

  logic         core_data_req; //core_data_* is core_lsu_* towards internal DMEM
  logic         core_data_gnt;
  logic         core_data_rvalid;
  logic [31:0]  core_data_addr;
  logic         core_data_we;
  logic [(DATA_CORE_WIDTH/8)-1:0] core_data_be;
  logic [DATA_CORE_WIDTH-1:0]     core_data_rdata;
  logic [DATA_CORE_WIDTH-1:0]     core_data_wdata;

  // signals for cache and bypass
  logic                           d_cache_ram_req;
  logic [31:0]                    d_cache_ram_addr;
  logic                           d_cache_ram_we;
  logic [(DATA_RAM_WIDTH/8)-1:0]  d_cache_ram_be;
  logic [DATA_RAM_WIDTH-1:0]      d_cache_ram_wdata;
  logic [31:0]                    d_cache_core_rdata;
  logic                           d_cache_core_rvalid;
  logic                           d_cache_core_gnt;

  logic                           i_cache_ram_req;
  logic [31:0]                    i_cache_ram_addr;
  logic                           i_cache_core_rvalid;
  logic                           i_cache_core_gnt;
  logic [INSTR_RAM_WIDTH-1:0]     i_cache_core_rdata;

  logic                           instr_ram_req;
  logic                           instr_ram_gnt;
  logic                           instr_ram_rvalid;
  logic [31:0]                    instr_ram_addr;
  logic [INSTR_RAM_WIDTH-1:0]     instr_ram_rdata;

  logic                           data_ram_req;
  logic                           data_ram_gnt;
  logic                           data_ram_rvalid;
  logic [31:0]                    data_ram_addr;
  logic                           data_ram_we;
  logic [(DATA_RAM_WIDTH/8)-1:0]  data_ram_be;
  logic [DATA_RAM_WIDTH-1:0]      data_ram_wdata;
  logic [DATA_RAM_WIDTH-1:0]      data_ram_rdata;
  // stalls
  logic                           data_req_stall;
  logic                           data_ram_req_force;
  logic                           instr_req_stall;
  logic                           instr_ram_req_force;

  logic                           instr_cache_en_o;
  logic                           data_cache_en_o;
  // signals to/from AXI mem
  logic                        is_axi_addr;
  logic                        axi_mem_grant;
  logic                        axi_mem_req;
  logic [DATA_ADDR_WIDTH-1:0]  axi_mem_addr;
  logic                        axi_mem_we;
  logic [AXI_DATA_WIDTH/8-1:0] axi_mem_be;
  logic [AXI_DATA_WIDTH-1:0]   axi_mem_rdata;
  logic [AXI_DATA_WIDTH-1:0]   axi_mem_wdata;

  // signals to/from AXI instr
  logic                        axi_instr_grant;
  logic                        axi_instr_req;
  logic [INSTR_ADDR_WIDTH-1:0] axi_instr_addr;
  logic                        axi_instr_we;
  logic [AXI_DATA_WIDTH/8-1:0] axi_instr_be;
  logic [AXI_DATA_WIDTH-1:0]   axi_instr_rdata;
  logic [AXI_DATA_WIDTH-1:0]   axi_instr_wdata;

  // signals to/from instr mem
  logic                           instr_mem_en;
  logic [INSTR_ADDR_WIDTH-1:0]    instr_mem_addr;
  logic                           instr_mem_we;
  logic [INSTR_RAM_WIDTH/8-1:0] instr_mem_be;
  logic [INSTR_RAM_WIDTH-1:0]     instr_mem_rdata;
  logic [INSTR_RAM_WIDTH-1:0]     instr_mem_wdata;

  // signals to/from data mem
  logic                           data_mem_en;
  logic [DATA_ADDR_WIDTH-1:0]     data_mem_addr;
  logic                           data_mem_we;
  logic [(DATA_RAM_WIDTH/8)-1:0]  data_mem_be;
  logic [DATA_RAM_WIDTH-1:0]      data_mem_rdata;
  logic [DATA_RAM_WIDTH-1:0]      data_mem_wdata;

  enum logic [0:0] { AXI, RAM } lsu_resp_CS, lsu_resp_NS, instr_resp;

  // signals to/from core2axi
  logic         core_axi_req; //core_axi_* is post-arbitration of core_axi_i_narrow_* and core_axi_d_*
  logic         core_axi_gnt;
  logic         core_axi_rvalid;
  logic [31:0]  core_axi_addr;
  logic         core_axi_we;
  logic [3:0]   core_axi_be;
  logic [31:0]  core_axi_rdata;
  logic [31:0]  core_axi_wdata;

  logic         core_axi_i_wide_req; //core_axi_i_wide_* is core_instr_* towards inst_narrower
  logic         core_axi_i_wide_gnt;
  logic         core_axi_i_wide_rvalid;
  logic [31:0]  core_axi_i_wide_addr;
  logic [INSTR_RDATA_WIDTH-1:0]  core_axi_i_wide_rdata;

  logic         core_axi_i_narrow_req; //core_axi_i_narrow_* is inst_narrower towards AXI master
  logic         core_axi_i_narrow_gnt;
  logic         core_axi_i_narrow_rvalid;
  logic [31:0]  core_axi_i_narrow_addr;
  logic         core_axi_i_narrow_we;
  logic [3:0]   core_axi_i_narrow_be;
  logic [31:0]  core_axi_i_narrow_rdata;
  logic [31:0]  core_axi_i_narrow_wdata;

  logic         core_axi_d_req; //core_axi_d_* is core_lsu_* towards to AXI master
  logic         core_axi_d_gnt;
  logic         core_axi_d_rvalid;
  logic [31:0]  core_axi_d_addr;
  logic         core_axi_d_we;
  logic [3:0]   core_axi_d_be;
  logic [31:0]  core_axi_d_rdata;
  logic [31:0]  core_axi_d_wdata;

  logic         core_axi_sel_data;
  logic         core_axi_sel_data_keep;

  logic [32+32+4+1-1:0] core_axi_d_concat;
  logic [32+32+4+1-1:0] core_axi_i_narrow_concat;
  logic [32+32+4+1-1:0] core_axi_concat;
  
  logic is_xbox_tcm_dmem_addr ;

  assign core_axi_d_concat = {core_axi_d_we, core_axi_d_be, core_axi_d_addr, core_axi_d_wdata};
  assign core_axi_i_narrow_concat = {core_axi_i_narrow_we, core_axi_i_narrow_be, core_axi_i_narrow_addr, core_axi_i_narrow_wdata};
  assign core_axi_d_rdata         = core_axi_rdata;
  assign core_axi_i_narrow_rdata  = core_axi_rdata;
  assign core_axi_d_rvalid        = core_axi_rvalid && core_axi_sel_data_keep;
  assign core_axi_i_narrow_rvalid = core_axi_rvalid && !core_axi_sel_data_keep;
  assign {core_axi_we, core_axi_be, core_axi_addr, core_axi_wdata} = core_axi_concat;

 rr_arb_tree #(.NumIn(2), .DataWidth(32+32+4+1), .FairArb(1'b0)) core_axi_arbiter(
     .clk_i(clk),
     .rst_ni(rst_n),
     .flush_i(1'b0),
     .rr_i(1'b0),

     .req_i  ( {core_axi_d_req,    core_axi_i_narrow_req   } ),
     .gnt_o  ( {core_axi_d_gnt,    core_axi_i_narrow_gnt   } ),
     .data_i ( {core_axi_d_concat, core_axi_i_narrow_concat} ),

     .req_o  ( core_axi_req    ),
     .gnt_i  ( core_axi_gnt    ),
     .data_o ( core_axi_concat ),

     .idx_o(core_axi_sel_data)
 );

 always @(posedge clk)
     if (core_axi_req && core_axi_gnt)
         core_axi_sel_data_keep <= core_axi_sel_data;

  AXI_BUS
  #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH     ( AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH      )
  )
  core_master_int();

  //----------------------------------------------------------------------------//
  // Core Instantiation
  //----------------------------------------------------------------------------//

  logic [4:0] irq_id;
  always_comb begin
    irq_id = '0;
    for (int i = 0; i < 32; i+=1) begin
      if(irq_i[i]) begin
        irq_id = i[4:0];
      end
    end
  end


    //Xriscv_core
    riscv_core // in ddp23_pnx_there is only one core which is riscv_core
    #(
      .INSTR_RDATA_WIDTH   (INSTR_RDATA_WIDTH),
      .IMEM_BASE           (`MIN_XCORE_IMEM), // Added in order to optimally distinguish at hamsa_prefetch between TCM and AXI access  
      .IMEM_MASK           (`MIN_XCORE_IMEM^`MAX_XCORE_IMEM),  
      .N_EXT_PERF_COUNTERS (     0       ),
      .FPU                 ( RISCY_RV32F ),
      .SHARED_FP           (     0       ),
      .SHARED_FP_DIVSQRT   (     2       ),
      .DM_HaltAddress      (`MIN_XCORE_DEBUG+32'h800)
    )
    RISCV_CORE
    (
      .clk_i           ( clk               ),
      .rst_ni          ( rst_n             ),
      //.regfile_select_i( regfile_select_i  ), // Applicable only for Xriscv_core

      .clock_en_i      ( clock_gating_i    ),
      .test_en_i       ( testmode_i        ),

      .boot_addr_i     ( boot_addr_i       ),
      .core_id_i       ( 4'h0              ),
      .cluster_id_i    ( 6'h0              ),

      .instr_addr_o    ( core_instr_addr   ),
      .instr_req_o     ( core_instr_req    ),
      .instr_rdata_i   ( core_instr_rdata  ),
      .instr_gnt_i     ( core_instr_gnt    ),
      .instr_rvalid_i  ( core_instr_rvalid ),

      .data_addr_o     ( core_lsu_addr     ),
      .data_wdata_o    ( core_lsu_wdata    ),
      .data_we_o       ( core_lsu_we       ),
      .data_req_o      ( core_lsu_req      ),
      .data_be_o       ( core_lsu_be       ),
      .data_rdata_i    ( core_lsu_rdata    ),
      .data_gnt_i      ( core_lsu_gnt      ),
      .data_rvalid_i   ( core_lsu_rvalid   ),

      .irq_i           ( (|irq_i)          ),
      .irq_id_i        ( irq_id            ),
      .irq_ack_o       (                   ),
      .irq_id_o        (                   ),
      .irq_sec_i       ( 1'b0              ),
      .sec_lvl_o       (                   ),

      .debug_req_i     ( debug_req         ),

      .fetch_enable_i  ( fetch_enable_i    ),
      .core_busy_o     ( core_busy_o       ),

      // apu-interconnect
      // handshake signals
      .apu_master_req_o      (             ),
      .apu_master_ready_o    (             ),
      .apu_master_gnt_i      ( 1'b1        ),
      // request channel
      .apu_master_operands_o (             ),
      .apu_master_op_o       (             ),
      .apu_master_type_o     (             ),
      .apu_master_flags_o    (             ),
      // response channel
      .apu_master_valid_i    ( '0          ),
      .apu_master_result_i   ( '0          ),
      .apu_master_flags_i    ( '0          ),

      .ext_perf_counters_i   (             ),
      .fregfile_disable_i    ( 1'b1        ),

      // NO DATA/INSTR CACHE IN FPGNIX	
      .data_cache_en_o       (  ),
      .instr_cache_en_o      (  )

      );
	
  // NO DATA/INSTR CACHE IN FPGNIX	
  assign data_cache_en_o = 0 ;  
  assign instr_cache_en_o = 0 ; 

  core2axi_wrap
  #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH     ( AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH      ),
    .REGISTERED_GRANT ( "FALSE"             )
  )
  core2axi_i
  (
    .clk_i         ( clk             ),
    .rst_ni        ( rst_n           ),

    .data_req_i    ( core_axi_req    ),
    .data_gnt_o    ( core_axi_gnt    ),
    .data_rvalid_o ( core_axi_rvalid ),
    .data_addr_i   ( core_axi_addr   ),
    .data_we_i     ( core_axi_we     ),
    .data_be_i     ( core_axi_be     ),
    .data_rdata_o  ( core_axi_rdata  ),
    .data_wdata_i  ( core_axi_wdata  ),

    .master        ( core_master_int ),

    .core_clock_en ( clock_gating_i  )
  );

  //----------------------------------------------------------------------------//
  // AXI Slices
  //----------------------------------------------------------------------------//

  axi_slice_wrap
  #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH       ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH       ),
    .AXI_ID_WIDTH   ( AXI_ID_MASTER_WIDTH  ),
    .SLICE_DEPTH    ( 2                    )
  )
  axi_slice_core2axi
  (
    .clk_i      ( clk             ),
    .rst_ni     ( rst_n           ),

    .test_en_i  ( testmode_i      ),

    .axi_slave  ( core_master_int ),
    .axi_master ( core_master     )
  );


  //----------------------------------------------------------------------------//
  // DATA-DEMUX
  //----------------------------------------------------------------------------//
  
  assign is_xbox_tcm_dmem_addr = (core_lsu_addr >= MIN_XBOX_TCM_DMEM) && (core_lsu_addr <= MAX_XBOX_TCM_DMEM) ;
  
  assign is_axi_addr     = ((core_lsu_addr & DMEM_MASK) != DMEM_BASE) && (!is_xbox_tcm_dmem_addr) ;
  assign core_data_req   = (~is_axi_addr) & core_lsu_req;
  assign core_axi_d_req    =   is_axi_addr  & core_lsu_req;

  assign core_data_addr  = core_lsu_addr;
  assign core_data_we    = core_lsu_we;
  assign core_data_be    = core_lsu_be;
  assign core_data_wdata = core_lsu_wdata;

  assign core_axi_d_addr   = core_lsu_addr;
  assign core_axi_d_we     = core_lsu_we;
  assign core_axi_d_be     = core_lsu_be;
  assign core_axi_d_wdata  = core_lsu_wdata;

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0)
      lsu_resp_CS <= RAM;
    else
      lsu_resp_CS <= lsu_resp_NS;
  end

  // figure out where the next response will be coming from
  always_comb
  begin
    lsu_resp_NS = lsu_resp_CS;
    if (core_axi_d_req && core_axi_d_gnt)
      lsu_resp_NS = AXI;
    else if (core_data_req && core_data_gnt)
      lsu_resp_NS = RAM;
    end
  assign core_lsu_gnt = core_axi_d_req ? core_axi_d_gnt : core_data_gnt;

  // route response back to LSU
  assign core_lsu_rdata  = (lsu_resp_CS == AXI) ? core_axi_d_rdata : core_data_rdata;
  assign core_lsu_rvalid = core_axi_d_rvalid | core_data_rvalid;

  //----------------------------------------------------------------------------//
  // INSTRUCTION-DEMUX
  //----------------------------------------------------------------------------//
  logic is_imem_addr;
  logic core_instr_rvalid_pending;
  assign is_imem_addr   = (core_instr_addr & IMEM_MASK) == IMEM_BASE;
  assign core_imem_req  =      ( is_imem_addr) && core_instr_req && (!core_instr_rvalid_pending || (instr_resp==RAM));
  assign core_axi_i_wide_req = (!is_imem_addr) && core_instr_req && (!core_instr_rvalid_pending || (instr_resp==AXI));

  assign core_axi_i_wide_addr    = core_instr_addr;
  assign core_axi_i_narrow_we      = 1'h0;
  assign core_axi_i_narrow_be      = 4'hf;
  assign core_axi_i_narrow_wdata   = 32'h0;

  assign core_imem_addr    = core_instr_addr;

  assign core_instr_gnt    = (core_axi_i_wide_req)    ? core_axi_i_wide_gnt    : core_imem_gnt;

  always @(posedge clk or negedge rst_n)
      if (!rst_n)
          core_instr_rvalid_pending <= 1'b0;
      else begin
          if (core_instr_req && core_instr_gnt) //assume rvalid of this gnt will arrive later
              core_instr_rvalid_pending <= 1'b1;
          else if (core_instr_rvalid)
              core_instr_rvalid_pending <= 1'b0;
      end


  // figure out where the next response will be coming from
  always @(posedge clk or negedge rst_n)
      if (!rst_n)
          instr_resp <= RAM;
      else begin
          if (core_instr_req && !core_instr_rvalid_pending)
              if (is_imem_addr)
                  instr_resp <= RAM;
              else
                  instr_resp <= AXI;
      end

  assign core_instr_rdata  = (instr_resp == AXI) ? core_axi_i_wide_rdata  : core_imem_rdata;
  assign core_instr_rvalid = (instr_resp == AXI) ? core_axi_i_wide_rvalid : core_imem_rvalid;

  //----------------------------------------------------------------------------//
  // Instruction Narrower
  //----------------------------------------------------------------------------//
  inst_narrower inst_narrower(
      .clk(clk),
      .rst_n(rst_n),
      .core_axi_i_wide_req(core_axi_i_wide_req),
      .core_axi_i_wide_addr(core_axi_i_wide_addr),
      .core_axi_i_wide_gnt(core_axi_i_wide_gnt),
      .core_axi_i_wide_rvalid(core_axi_i_wide_rvalid),
      .core_axi_i_wide_rdata(core_axi_i_wide_rdata),
      .core_axi_i_narrow_req(core_axi_i_narrow_req),
      .core_axi_i_narrow_addr(core_axi_i_narrow_addr),
      .core_axi_i_narrow_gnt(core_axi_i_narrow_gnt),
      .core_axi_i_narrow_rvalid(core_axi_i_narrow_rvalid),
      .core_axi_i_narrow_rdata(core_axi_i_narrow_rdata)
  );

  //----------------------------------------------------------------------------//
  // Instruction RAM
  //----------------------------------------------------------------------------//

  // NO Instr Cache
  // input for ram_mux
  assign instr_ram_req    = core_imem_req;
  assign instr_ram_addr   = core_imem_addr;

  // output from ram_mux
  assign core_imem_gnt    = instr_ram_gnt;
  assign core_imem_rvalid = instr_ram_rvalid;
  assign core_imem_rdata  = instr_ram_rdata;

  typedef enum logic {SRAM=1'b0, XBOX_TCM_DMEM=1'b1} xcore_ram_type_t;

  
  // signals to/from instr mem mux
  logic                          instr_mem_en_mux;
  logic [INSTR_RAM_WIDTH-1:0]    instr_mem_rdata_mux;
  logic                          instr_mem_rready_mux;
  logic                          instr_mem_wready_mux;

  // No instr edram in fpgnix

  assign instr_mem_rready_mux = 1'b1;
  assign instr_mem_wready_mux = 1'b1;
  
  
  assign iedram_apb.prdata  = 0;
  assign iedram_apb.pready  = 1;
  assign iedram_apb.pslverr = 0;
  
  assign instr_mem_en_mux       = instr_mem_en;
  assign instr_mem_rdata_mux    = instr_mem_rdata; 


  instr_ram_wrap
  #(
    .RAM_SIZE    ( INSTR_RAM_SIZE    ),
    .DATA_WIDTH  ( INSTR_RAM_WIDTH   ),
    .MEM_CTRL_DW ( INSTR_MEM_CTRL_DW ),
    .MEM_MUX     ( INSTR_RAM_MUX     )
  )
  instr_mem
  (
    .clk         ( clk             ),
    .rst_n       ( rst_n           ),
    .en_i        ( instr_mem_en_mux),
    .addr_i      ( {1'b0,instr_mem_addr[INSTR_ADDR_WIDTH-2:0]} ),
    .wdata_i     ( instr_mem_wdata ),
    .rdata_o     ( instr_mem_rdata ),
    .we_i        ( instr_mem_we    ),
    .be_i        ( instr_mem_be    ),
    .bypass_en_i ( testmode_i      ),

    .ram_ctrl        ( ram_ctrl[INSTR_MEM_CTRL_DW-1:0] )
  );

  axi_mem_if_SP_async_wrap
  #(
    .AXI_ADDR_WIDTH  ( AXI_ADDR_WIDTH         ),
    .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH         ),
    .AXI_ID_WIDTH    ( AXI_ID_SLAVE_WIDTH     ),
    .AXI_USER_WIDTH  ( AXI_USER_WIDTH         ),
    .MEM_ADDR_WIDTH  ( INSTR_ADDR_WIDTH       )
  )
  instr_mem_axi_if
  (
    .clk         ( clk               ),
    .rst_n       ( rst_n             ),
    .test_en_i   ( testmode_i        ),

    .mem_grant_i ( axi_instr_grant   ),
    .mem_req_o   ( axi_instr_req     ),
    .mem_addr_o  ( axi_instr_addr    ),
    .mem_we_o    ( axi_instr_we      ),
    .mem_be_o    ( axi_instr_be      ),
    .mem_rdata_i ( axi_instr_rdata   ),
    .mem_wdata_o ( axi_instr_wdata   ),

    .slave       ( instr_slave       )
  );

  localparam INSTR_RAM_MUX_OUT_WIDTH = (AXI_DATA_WIDTH>INSTR_RAM_WIDTH) ? AXI_DATA_WIDTH : INSTR_RAM_WIDTH ;

  Xram_mux
  #(
    .ADDR_WIDTH ( INSTR_ADDR_WIDTH ),
    .IN0_WIDTH  ( AXI_DATA_WIDTH   ),
    .IN1_WIDTH  ( INSTR_RAM_WIDTH         ),
    .OUT_WIDTH  ( INSTR_RAM_MUX_OUT_WIDTH )
  )
  instr_ram_mux_i
  (
    .clk            ( clk               ),
    .rst_n          ( rst_n             ),

    .port0_req_i    ( axi_instr_req     ),
    .port0_gnt_o    ( axi_instr_grant   ),
    .port0_rvalid_o (                   ),
    .port0_addr_i   ( {axi_instr_addr[INSTR_ADDR_WIDTH-AXI_B_WIDTH-1:0], {AXI_B_WIDTH{1'b0}}} ),
    .port0_we_i     ( axi_instr_we      ),
    .port0_be_i     ( axi_instr_be      ),
    .port0_rdata_o  ( axi_instr_rdata   ),
    .port0_wdata_i  ( axi_instr_wdata   ),

    .port1_req_i    ( instr_ram_req     ),
    .port1_gnt_o    ( instr_ram_gnt     ),
    .port1_rvalid_o ( instr_ram_rvalid  ),
    .port1_addr_i   ( instr_ram_addr[INSTR_ADDR_WIDTH-1:0] ),
    .port1_we_i     ( 1'b0              ),
    .port1_be_i     ( '1                ),
    .port1_rdata_o  ( instr_ram_rdata   ),
    .port1_wdata_i  ( '0                ),

    .ram_en_o       ( instr_mem_en      ),
    .ram_addr_o     ( instr_mem_addr    ),
    .ram_rready     ( instr_mem_rready_mux ),
    .ram_wready     ( instr_mem_wready_mux ),
    .ram_we_o       ( instr_mem_we      ),
    .ram_be_o       ( instr_mem_be      ),
    .ram_rdata_i    ( instr_mem_rdata_mux  ),
    .ram_wdata_o    ( instr_mem_wdata   ),
    .port1_is_32b   ( 1'b0              )
  );


  //----------------------------------------------------------------------------//
  // Data RAM
  //----------------------------------------------------------------------------//


  // NO DATA CACHE
  // input for ram_mux
  assign data_ram_req     = core_data_req;
  assign data_ram_addr    = core_data_addr;
  assign data_ram_wdata   = core_data_wdata;
  assign data_ram_we      = core_data_we;
  assign data_ram_be      = core_data_be;

  // output from ram_mux
  assign core_data_gnt    = data_ram_gnt;
  assign core_data_rvalid = data_ram_rvalid;
  assign core_data_rdata  = data_ram_rdata;

  xcore_ram_type_t data_ram_sel, data_ram_sel_d;


  assign data_ram_sel = (!is_xbox_tcm_dmem_addr) ? SRAM : XBOX_TCM_DMEM ;

  always @ (posedge clk)
   data_ram_sel_d <= data_ram_sel;
 
  // signals to/from data mem mux
  logic                          data_mem_en_mux;
  logic [DATA_RAM_WIDTH-1:0]     data_mem_rdata_mux;
  logic                          data_mem_rready_mux;
  logic                          data_mem_wready_mux;

  always @ (*) begin : data_mem_type_mux
   case (data_ram_sel)
      SRAM:
      begin
         xbox_dmem_rvalid    = 1'b0; 
         xbox_dmem_wvalid    = 1'b0; 
         data_mem_rready_mux = 1'b1;
         data_mem_wready_mux = 1'b1;
         data_mem_en_mux     = data_mem_en;
      end
      XBOX_TCM_DMEM: 
      begin
         xbox_dmem_rvalid    = data_mem_en & !data_mem_we; 
         xbox_dmem_wvalid    = data_mem_en & data_mem_we; 
         data_mem_rready_mux = xbox_dmem_rready;
         data_mem_wready_mux = xbox_dmem_wready;
         data_mem_en_mux     = 1'b0;

      end
   endcase
  end
  
  always @ (*)
  case (data_ram_sel_d)
     SRAM:
        data_mem_rdata_mux    = data_mem_rdata;
     XBOX_TCM_DMEM:
        data_mem_rdata_mux    = xbox_dmem_rdata[31:0] ;
  endcase

// core region -> xbox mem

assign xbox_dmem_addr[18:0]  = data_mem_addr[18:0] ;
assign xbox_dmem_wdata[31:0] = data_mem_wdata[31:0] ;  // Asuming no Data Cache in ddp/fpgnix data width currently 32
assign xbox_dmem_wbe[3:0]    = data_mem_be[3:0] ;

// No 'edram' APB interfave
assign dedram_apb.prdata  =0;
assign dedram_apb.pready  =1;
assign dedram_apb.pslverr =0;
 
  sp_ram_wrap
  #(
    .RAM_SIZE      ( DATA_RAM_SIZE    ),   // Changed by Udi, for post Sansa, DDP pulpenix2_lite, looking for 64KB RAM  
    .DATA_WIDTH    ( DATA_RAM_WIDTH   ),
    .NUM_WORDS_REG ( 128              ),
    .MEM_CTRL_DW   ( DATA_MEM_CTRL_DW ),
    .MEM_MUX       ( DATA_RAM_MUX     )
  )
  data_mem
  (
    .clk          ( clk            ),
    .rstn_i       ( rst_n          ),
    .en_i         ( data_mem_en_mux),
    .addr_i       ( data_mem_addr[DATA_ADDR_WIDTH-2:$clog2(DATA_RAM_WIDTH/8)]),
    .wdata_i      ( data_mem_wdata ),
    .rdata_o      ( data_mem_rdata ),
    .we_i         ( data_mem_we    ),
    .be_i         ( data_mem_be    ),
    .bypass_en_i  ( testmode_i     ),

    `ifdef TSMC16
    .ram_ctrl        ( ram_ctrl[CORE_MEM_CTR_DW-1:INSTR_MEM_CTRL_DW] )
    `else
    .ram_ctrl        ( ram_ctrl[CORE_MEM_CTR_DW-1:INSTR_MEM_CTRL_DW] )
    `endif
  );

  axi_mem_if_SP_async_wrap
  #(
    .AXI_ADDR_WIDTH  ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH    ( AXI_ID_SLAVE_WIDTH ),
    .AXI_USER_WIDTH  ( AXI_USER_WIDTH     ),
    .MEM_ADDR_WIDTH  ( DATA_ADDR_WIDTH    )
  )
  data_mem_axi_if
  (
    .clk         ( clk               ),
    .rst_n       ( rst_n             ),
    .test_en_i   ( testmode_i        ),

    .mem_grant_i ( axi_mem_grant   ),
    .mem_req_o   ( axi_mem_req       ),
    .mem_addr_o  ( axi_mem_addr      ),
    .mem_we_o    ( axi_mem_we        ),
    .mem_be_o    ( axi_mem_be        ),
    .mem_rdata_i ( axi_mem_rdata     ),
    .mem_wdata_o ( axi_mem_wdata     ),

    .slave       ( data_slave        )
  );

  localparam DATA_RAM_MUX_OUT_WIDTH = (AXI_DATA_WIDTH>DATA_RAM_WIDTH) ? AXI_DATA_WIDTH : DATA_RAM_WIDTH ;
  Xram_mux
  #(
    .ADDR_WIDTH ( DATA_ADDR_WIDTH ),
    .IN0_WIDTH  ( AXI_DATA_WIDTH  ),
    .IN1_WIDTH  ( DATA_RAM_WIDTH         ),
    .OUT_WIDTH  ( DATA_RAM_MUX_OUT_WIDTH )
  )
  data_ram_mux_i
  (
    .clk            ( clk              ),
    .rst_n          ( rst_n            ),

    .port0_req_i    ( axi_mem_req      ),
    .port0_gnt_o    ( axi_mem_grant   ),
    .port0_rvalid_o (                  ),
    .port0_addr_i   ( {axi_mem_addr[DATA_ADDR_WIDTH-AXI_B_WIDTH-1:0], {AXI_B_WIDTH{1'b0}}} ),
    .port0_we_i     ( axi_mem_we       ),
    .port0_be_i     ( axi_mem_be       ),
    .port0_rdata_o  ( axi_mem_rdata    ),
    .port0_wdata_i  ( axi_mem_wdata    ),

    .port1_req_i    ( data_ram_req     ),
    .port1_gnt_o    ( data_ram_gnt     ),
    .port1_rvalid_o ( data_ram_rvalid  ),
    .port1_addr_i   ( data_ram_addr[DATA_ADDR_WIDTH-1:0] ),
    .port1_we_i     ( data_ram_we      ),
    .port1_be_i     ( data_ram_be      ),
    .port1_rdata_o  ( data_ram_rdata   ),
    .port1_wdata_i  ( data_ram_wdata   ),

    .ram_en_o       ( data_mem_en      ),
    .ram_addr_o     ( data_mem_addr    ),
    .ram_rready     ( data_mem_rready_mux ),
    .ram_wready     ( data_mem_wready_mux ),
    .ram_we_o       ( data_mem_we      ),
    .ram_be_o       ( data_mem_be      ),
    .ram_rdata_i    ( data_mem_rdata_mux  ),
    .ram_wdata_o    ( data_mem_wdata   ),
    .port1_is_32b   ( !data_cache_en_o )
  );

  //----------------------------------------------------------------------------//
  // Debug Unit
  //----------------------------------------------------------------------------//

  dm_wrap #(.AXI_USER_WIDTH(AXI_USER_WIDTH), .AXI_ID_WIDTH(AXI_ID_MASTER_WIDTH), .IdcodeValue(32'h549511C3)) dm_wrap
  (
    //clk and reset
    .clk    ( clk    ),
    .rst_n  ( rst_n  ),
    .apor_n ( apor_n ),
    .aclk   ( clk_ref),

    //debug_req
    .debug_req(debug_req),

    .ndmreset(ndmreset),

    //jtag
    .tms          ( tms_i           ),
    .tck          ( tck_i           ),
    .trst         ( trstn_i         ),
    .tdi          ( tdi_i           ),
    .tdo          ( tdo_o           ),
    .openocd_jtag ( openocd_jtag    ),
    .jtag_sel     ( jtag_sel        ),

    //apb slave
    .apb_debug ( apb_debug ),

    //axi master
    .axi_master_aw_valid  ( dbg_master.aw_valid  ),
    .axi_master_aw_addr   ( dbg_master.aw_addr   ),
    .axi_master_aw_prot   ( dbg_master.aw_prot   ),
    .axi_master_aw_region ( dbg_master.aw_region ),
    .axi_master_aw_len    ( dbg_master.aw_len    ),
    .axi_master_aw_size   ( dbg_master.aw_size   ),
    .axi_master_aw_burst  ( dbg_master.aw_burst  ),
    .axi_master_aw_lock   ( dbg_master.aw_lock   ),
    .axi_master_aw_cache  ( dbg_master.aw_cache  ),
    .axi_master_aw_qos    ( dbg_master.aw_qos    ),
    .axi_master_aw_id     ( dbg_master.aw_id     ),
    .axi_master_aw_user   ( dbg_master.aw_user   ),
    .axi_master_aw_ready  ( dbg_master.aw_ready  ),

    .axi_master_ar_valid  ( dbg_master.ar_valid  ),
    .axi_master_ar_addr   ( dbg_master.ar_addr   ),
    .axi_master_ar_prot   ( dbg_master.ar_prot   ),
    .axi_master_ar_region ( dbg_master.ar_region ),
    .axi_master_ar_len    ( dbg_master.ar_len    ),
    .axi_master_ar_size   ( dbg_master.ar_size   ),
    .axi_master_ar_burst  ( dbg_master.ar_burst  ),
    .axi_master_ar_lock   ( dbg_master.ar_lock   ),
    .axi_master_ar_cache  ( dbg_master.ar_cache  ),
    .axi_master_ar_qos    ( dbg_master.ar_qos    ),
    .axi_master_ar_id     ( dbg_master.ar_id     ),
    .axi_master_ar_user   ( dbg_master.ar_user   ),
    .axi_master_ar_ready  ( dbg_master.ar_ready  ),

    .axi_master_w_valid   ( dbg_master.w_valid   ),
    .axi_master_w_data    ( dbg_master.w_data    ),
    .axi_master_w_strb    ( dbg_master.w_strb    ),
    .axi_master_w_user    ( dbg_master.w_user    ),
    .axi_master_w_last    ( dbg_master.w_last    ),
    .axi_master_w_ready   ( dbg_master.w_ready   ),

    .axi_master_r_valid   ( dbg_master.r_valid   ),
    .axi_master_r_data    ( dbg_master.r_data    ),
    .axi_master_r_resp    ( dbg_master.r_resp    ),
    .axi_master_r_last    ( dbg_master.r_last    ),
    .axi_master_r_id      ( dbg_master.r_id      ),
    .axi_master_r_user    ( dbg_master.r_user    ),
    .axi_master_r_ready   ( dbg_master.r_ready   ),

    .axi_master_b_valid   ( dbg_master.b_valid   ),
    .axi_master_b_resp    ( dbg_master.b_resp    ),
    .axi_master_b_id      ( dbg_master.b_id      ),
    .axi_master_b_user    ( dbg_master.b_user    ),
    .axi_master_b_ready   ( dbg_master.b_ready   ));

endmodule
