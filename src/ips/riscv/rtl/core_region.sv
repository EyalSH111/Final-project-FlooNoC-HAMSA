// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the ���������License���������); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an ���������AS IS��������� BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


`include "axi_bus.sv"
`include "config.sv"

module core_region
#(
    parameter AXI_ADDR_WIDTH       = 32,
    parameter AXI_DATA_WIDTH       = 64,
    parameter AXI_ID_MASTER_WIDTH  = 10,
    parameter AXI_ID_SLAVE_WIDTH   = 10,
    parameter AXI_USER_WIDTH       = 0,
    parameter DATA_RAM_SIZE        = 32768,   // in bytes
    parameter INSTR_RAM_SIZE       = 32768*2, // in bytes (Default Sansa memory configuration)
    parameter USE_ZERO_RISCY       = 0,
    parameter RISCY_RV32F          = 0,
    parameter ZERO_RV32M           = 1,
    parameter ZERO_RV32E           = 0,
    
    //Hamsa hardware config:
    `ifdef DATA_CACHE
    parameter DATA_CACHE           = 1,
    `else
    parameter DATA_CACHE           = 0,
    `endif
    `ifdef INSTR_CACHE
    parameter INSTR_CACHE          = 1,
    `else
    parameter INSTR_CACHE          = 0,
    `endif
   
    `ifdef TSMC16
    parameter INSTR_MEM_CTRL_DW    = 4,
    parameter DATA_MEM_CTRL_DW     = 4,
    `else
    parameter INSTR_MEM_CTRL_DW    = 6,
    parameter DATA_MEM_CTRL_DW     = 5,
    `endif

    parameter IMEM_MASK            = 32'hfff_00000,
    parameter IMEM_BASE            = `MIN_HAMSA_IMEM,
    parameter DMEM_MASK            = 32'hfff_00000,
    parameter DMEM_BASE            = `MIN_HAMSA_DMEM,

    localparam CORE_MEM_CTR_DW     = DATA_MEM_CTRL_DW + INSTR_MEM_CTRL_DW
  )
  (
    // Clock and Reset
    input logic                        clk,
    input logic                        rst_n,
    input logic                        apor_n,
    input logic                        clk_ref,

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

    OPENOCD_JTAG.slave openocd_jtag

  );

  `ifdef HAMSA_DI  // Dual-Issue Logic optional instantiation
  localparam INSTR_RDATA_WIDTH = 128 ; // for DI INSTR_RDATA_WIDTH Must be multiples of 128 (initially 128)
  localparam HAMSA_INSTR_MUX = 4;
  `else
  localparam INSTR_RDATA_WIDTH = 32 ;  // compatible with original hard coded width
  localparam HAMSA_INSTR_MUX = 16;
  `endif

  localparam INSTR_STALL      = 1'b0;
  localparam DATA_STALL       = 1'b0;

  // Mem Config
 
  localparam DATA_RAM_WIDTH  = (DATA_CACHE == 1)  ? 128 : 32;
  localparam DATA_RAM_MUX    = (DATA_CACHE == 1)  ? 4 : 16;
  localparam INSTR_RAM_WIDTH = (INSTR_CACHE == 1) ? 128 : INSTR_RDATA_WIDTH;
  localparam INSTR_RAM_MUX   = (INSTR_CACHE == 1) ? 4 : HAMSA_INSTR_MUX;

  localparam INSTR_ADDR_WIDTH = $clog2(INSTR_RAM_SIZE)+1; // to make space for the boot rom
  localparam DATA_ADDR_WIDTH  = $clog2(DATA_RAM_SIZE);

  localparam AXI_B_WIDTH      = $clog2(AXI_DATA_WIDTH/8); // AXI "Byte" width
  localparam DATA_CORE_WIDTH  = 32;

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
  logic                        axi_mem_req;
  logic [DATA_ADDR_WIDTH-1:0]  axi_mem_addr;
  logic                        axi_mem_we;
  logic [AXI_DATA_WIDTH/8-1:0] axi_mem_be;
  logic [AXI_DATA_WIDTH-1:0]   axi_mem_rdata;
  logic [AXI_DATA_WIDTH-1:0]   axi_mem_wdata;

  // signals to/from AXI instr
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
  logic                        data_mem_en;
  logic [DATA_ADDR_WIDTH-1:0]  data_mem_addr;
  logic                        data_mem_we;
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

  assign core_axi_d_concat = {core_axi_d_we, core_axi_d_be, core_axi_d_addr, core_axi_d_wdata};
  assign core_axi_i_narrow_concat = {core_axi_i_narrow_we, core_axi_i_narrow_be, core_axi_i_narrow_addr, core_axi_i_narrow_wdata};
  assign core_axi_d_rdata         = core_axi_rdata;
  assign core_axi_i_narrow_rdata  = core_axi_rdata;
  assign core_axi_d_rvalid        = core_axi_rvalid && core_axi_sel_data_keep;
  assign core_axi_i_narrow_rvalid = core_axi_rvalid && !core_axi_sel_data_keep;
  assign {core_axi_we, core_axi_be, core_axi_addr, core_axi_wdata} = core_axi_concat;

  /*
  stream_arbiter core_axi_arbiter(
    .clk_i(clk),
    .rst_ni(rst_n),

    .inp_data_i(   {core_axi_d_concat, core_axi_i_narrow_concat}),
    .inp_valid_i(  {core_axi_d_req,    core_axi_i_narrow_req   }),
    .inp_ready_o(  {core_axi_d_gnt,    core_axi_i_narrow_gnt   }),

    .oup_data_o(  core_axi_concat ),
    .oup_valid_o( core_axi_req    ),
    .oup_ready_i( core_axi_gnt    )
  );
  */
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

  generate   // added by Udi 28/Feb/2019 required by Quartus

  if(USE_ZERO_RISCY) begin: CORE
      zeroriscy_core
      #(
        .N_EXT_PERF_COUNTERS (     0      ),
        .RV32E               ( ZERO_RV32E ),
        .RV32M               ( ZERO_RV32M )
      )
      RISCV_CORE
      (
        .clk_i           ( clk               ),
        .rst_ni          ( rst_n             ),

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

        .debug_req_i     ( debug_req         ),


        .fetch_enable_i  ( fetch_enable_i    ),
        .core_busy_o     ( core_busy_o       ),
        .ext_perf_counters_i (               )
      );
  end else begin: CORE

    riscv_core
    #(
      .INSTR_RDATA_WIDTH   (INSTR_RDATA_WIDTH),
      .N_EXT_PERF_COUNTERS (     0       ),
      .FPU                 ( RISCY_RV32F ),
      .SHARED_FP           (     0       ),
      .SHARED_FP_DIVSQRT   (     2       ),
      .DM_HaltAddress      (`MIN_HAMSA_DEBUG+32'h800 ),
      .IMEM_BASE           ( IMEM_BASE   )
    )
    RISCV_CORE
    (
      .clk_i           ( clk               ),
      .rst_ni          ( rst_n             ),

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

      .data_cache_en_o       ( data_cache_en_o ),
      .instr_cache_en_o      ( instr_cache_en_o )

      );
  end

endgenerate

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
  assign is_axi_addr     = (core_lsu_addr & DMEM_MASK) != DMEM_BASE;
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
  generate
  if(INSTR_CACHE) begin: instr_cache
      instr_cache_L0
      #(
        .RAM_SIZE          ( INSTR_RAM_SIZE    ),
        .CORE_WIDTH        ( INSTR_RDATA_WIDTH )
      )
      cache_L0_instr_i
      (
        .clk               ( clk                 ),
        .rst_n             ( rst_n               ),

        .en_i              ( core_imem_req       ),
        .addr_i            ( core_imem_addr      ),
        .gnt_o             ( i_cache_core_gnt    ),
        .rvalid_o          ( i_cache_core_rvalid ),
        .rdata_o           ( i_cache_core_rdata  ),

        .ram_en_o          ( i_cache_ram_req     ),
        .ram_addr_o        ( i_cache_ram_addr    ),
        .ram_rdata_i       ( instr_ram_rdata     ),
        .ram_data_gnt_i    ( instr_ram_gnt       ),
        .ram_data_rvalid_i ( instr_ram_rvalid    ),

        .bypass_en_i       ( !instr_cache_en_o    )
      );

      // ------------------------- Instruction Cache bypass -----------------------
      // to ram_mux
      assign instr_ram_req     =(instr_cache_en_o == 0)? core_imem_req   :i_cache_ram_req;
      assign instr_ram_addr    =(instr_cache_en_o == 0)? core_imem_addr  :i_cache_ram_addr;

      // to core
      assign core_imem_gnt    =(instr_cache_en_o == 0)? instr_ram_gnt    :i_cache_core_gnt;
      assign core_imem_rvalid =(instr_cache_en_o == 0)? instr_ram_rvalid :i_cache_core_rvalid;
      assign core_imem_rdata  =(instr_cache_en_o == 0)? instr_ram_rdata  :i_cache_core_rdata;

  end else begin: no_instr_cache
      // input for ram_mux
      assign instr_ram_req    = core_imem_req;
      assign instr_ram_addr   = core_imem_addr;

      // output from ram_mux
      assign core_imem_gnt    = instr_ram_gnt;
      assign core_imem_rvalid = instr_ram_rvalid;
      assign core_imem_rdata  = instr_ram_rdata;
  end
  endgenerate

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
    .en_i        ( instr_mem_en    ),
    .addr_i      ( {1'b0,instr_mem_addr[INSTR_ADDR_WIDTH-2:0]}), // disable boot rom
    .wdata_i     ( instr_mem_wdata ),
    .rdata_o     ( instr_mem_rdata ),
    .we_i        ( instr_mem_we    ),
    .be_i        ( instr_mem_be    ),
    .bypass_en_i ( testmode_i      ),

    .ram_ctrl        ( ram_ctrl[INSTR_MEM_CTRL_DW-1:0] )
  );

  axi_mem_if_SP_wrap
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

    .mem_req_o   ( axi_instr_req     ),
    .mem_addr_o  ( axi_instr_addr    ),
    .mem_we_o    ( axi_instr_we      ),
    .mem_be_o    ( axi_instr_be      ),
    .mem_rdata_i ( axi_instr_rdata   ),
    .mem_wdata_o ( axi_instr_wdata   ),

    .slave       ( instr_slave       )
  );

  localparam INSTR_RAM_MUX_OUT_WIDTH = (AXI_DATA_WIDTH>INSTR_RAM_WIDTH) ? AXI_DATA_WIDTH : INSTR_RAM_WIDTH ;

  ram_mux
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
    .port0_gnt_o    (                   ),
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
    .ram_we_o       ( instr_mem_we      ),
    .ram_be_o       ( instr_mem_be      ),
    .ram_rdata_i    ( instr_mem_rdata   ),
    .ram_wdata_o    ( instr_mem_wdata   ),
    .port1_is_32b   ( 1'b0              )
  );


  //----------------------------------------------------------------------------//
  // Data RAM
  //----------------------------------------------------------------------------//
  generate
  if(DATA_CACHE) begin: data_cache
      data_cache_L0
      #(
        .DATA_RAM_WIDTH  ( DATA_RAM_WIDTH  ),
        .DATA_CORE_WIDTH ( DATA_CORE_WIDTH )
      )
      data_cache_i
      (
        .clk            ( clk                 ),
        .rst_n          ( rst_n               ),

        .en_i           ( core_data_req       ),
        .addr_i         ( core_data_addr      ),
        .wdata_i        ( core_data_wdata     ),
        .we_i           ( core_data_we        ),
        .be_i           ( core_data_be        ),
        .rdata_o        ( d_cache_core_rdata  ),
        .rvalid_o       ( d_cache_core_rvalid ),
        .gnt_o          ( d_cache_core_gnt    ),

        .ram_data_gnt_i ( data_ram_gnt        ),
        .ram_rvalid_i   ( data_ram_rvalid     ),
        .ram_rdata_i    ( data_ram_rdata      ),
        .ram_addr_o     ( d_cache_ram_addr    ),
        .ram_wdata_o    ( d_cache_ram_wdata   ),
        .ram_en_o       ( d_cache_ram_req     ),
        .ram_we_o       ( d_cache_ram_we      ),
        .ram_be_o       ( d_cache_ram_be      ),

        .bypass_en_i    ( !data_cache_en_o       )  //testmode_i
      );

      // ------------------------- Data Cache bypass -----------------------
      // to ram_mux
      assign data_ram_req     =(data_cache_en_o == 0)? core_data_req            :d_cache_ram_req;
      assign data_ram_addr    =(data_cache_en_o == 0)? core_data_addr           :d_cache_ram_addr ;
      assign data_ram_we      =(data_cache_en_o == 0)? core_data_we             :d_cache_ram_we;
      assign data_ram_wdata   =(data_cache_en_o == 0)? {96'b0, core_data_wdata} :d_cache_ram_wdata;
      assign data_ram_be      =(data_cache_en_o == 0)? {12'b0, core_data_be   } :d_cache_ram_be;

      // to core
      assign core_data_gnt    =(data_cache_en_o == 0)? data_ram_gnt         :d_cache_core_gnt;
      assign core_data_rvalid =(data_cache_en_o == 0)? data_ram_rvalid      :d_cache_core_rvalid;
      assign core_data_rdata  =(data_cache_en_o == 0)? data_ram_rdata[31:0] :d_cache_core_rdata;

end else begin: no_data_cache
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
  end
  endgenerate




  sp_ram_wrap
  #(
    .RAM_SIZE      ( DATA_RAM_SIZE    ),
    .DATA_WIDTH    ( DATA_RAM_WIDTH   ),
    .NUM_WORDS_REG ( 128              ),
    .MEM_CTRL_DW   ( DATA_MEM_CTRL_DW ),
    .MEM_MUX       ( DATA_RAM_MUX     )
  )
  data_mem
  (
    .clk          ( clk            ),
    .rstn_i       ( rst_n          ),
    .en_i         ( data_mem_en    ),
    .addr_i       ( data_mem_addr[DATA_ADDR_WIDTH-1:$clog2(DATA_RAM_WIDTH/8)] ),
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

  axi_mem_if_SP_wrap
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

    .mem_req_o   ( axi_mem_req       ),
    .mem_addr_o  ( axi_mem_addr      ),
    .mem_we_o    ( axi_mem_we        ),
    .mem_be_o    ( axi_mem_be        ),
    .mem_rdata_i ( axi_mem_rdata     ),
    .mem_wdata_o ( axi_mem_wdata     ),

    .slave       ( data_slave        )
  );

  localparam DATA_RAM_MUX_OUT_WIDTH = (AXI_DATA_WIDTH>DATA_RAM_WIDTH) ? AXI_DATA_WIDTH : DATA_RAM_WIDTH ;
  ram_mux
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
    .port0_gnt_o    (                  ),
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
    .ram_we_o       ( data_mem_we      ),
    .ram_be_o       ( data_mem_be      ),
    .ram_rdata_i    ( data_mem_rdata   ),
    .ram_wdata_o    ( data_mem_wdata   ),
    .port1_is_32b   ( !data_cache_en_o )
  );


  //----------------------------------------------------------------------------//
  // Debug Unit
  //----------------------------------------------------------------------------//

  dm_wrap #(.AXI_USER_WIDTH(AXI_USER_WIDTH), .AXI_ID_WIDTH(AXI_ID_MASTER_WIDTH), .IdcodeValue(32'h649511C3)) dm_wrap
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


  //----------------------------------------------------------------------------//
  // Test Code
  //----------------------------------------------------------------------------//

  // introduce random stalls for data access to stress LSU
generate
if(INSTR_STALL) begin: instr_stall
    initial force instr_ram_mux_i.port1_req_i = instr_ram_req_force;
    always @(posedge clk) instr_req_stall <= instr_ram_req;
    assign instr_ram_req_force = (instr_ram_req == 1)? instr_req_stall: 1'b0;
end

if(DATA_STALL) begin: data_stall
    initial force data_ram_mux_i.port1_req_i = data_ram_req_force;
    always @(posedge clk) data_req_stall <= data_ram_req;
    assign data_ram_req_force = (data_ram_req == 1)? data_req_stall: 1'b0;
end
endgenerate

endmodule
