//Author: Tzachi Noy
//Based on connectivity in https://github.com/pulp-platform/pulp_soc/blob/e35adcaf440e37e0843ab9bf09728345d5a6fe6c/rtl/pulp_soc/pulp_soc.sv
`include "apb_bus.sv"
module dm_wrap(apb_debug, /*auto-arg*/
   // Outputs
   axi_master_aw_addr, axi_master_aw_burst, axi_master_aw_cache,
   axi_master_aw_id, axi_master_aw_len, axi_master_aw_lock,
   axi_master_aw_prot, axi_master_aw_qos, axi_master_aw_region,
   axi_master_aw_size, axi_master_aw_user, axi_master_aw_valid,
   axi_master_b_ready, axi_master_r_ready, axi_master_w_data,
   axi_master_w_last, axi_master_w_strb, axi_master_w_user,
   axi_master_w_valid, axi_master_ar_addr, axi_master_ar_burst,
   axi_master_ar_cache, axi_master_ar_id, axi_master_ar_len,
   axi_master_ar_lock, axi_master_ar_prot, axi_master_ar_qos,
   axi_master_ar_region, axi_master_ar_size, axi_master_ar_user,
   axi_master_ar_valid, tdo, debug_req, ndmreset,
   // Inputs
   clk, rst_n, apor_n, aclk, axi_master_aw_ready, axi_master_w_ready,
   axi_master_b_id, axi_master_b_resp, axi_master_b_valid,
   axi_master_b_user, axi_master_ar_ready, axi_master_r_id,
   axi_master_r_data, axi_master_r_resp, axi_master_r_last,
   axi_master_r_user, axi_master_r_valid, tck, trst, tdi, tms, jtag_sel,
   // Interface
   openocd_jtag
   );
localparam NrHarts = 1;
localparam BusWidth = 32;
localparam BE_WIDTH = BusWidth/8;
localparam PER_ADDR_WIDTH = 32;
localparam APB_ADDR_WIDTH = 32;

parameter AXI_ADDR_WIDTH = 32;
localparam ADDR_WIDTH = AXI_ADDR_WIDTH;
parameter AXI_DATA_WIDTH = 32;
localparam DATA_WIDTH = AXI_DATA_WIDTH;
parameter AXI_USER_WIDTH = 5;
localparam USER_WIDTH = AXI_USER_WIDTH;
parameter AXI_ID_WIDTH   = 5;
localparam ID_WIDTH = AXI_ID_WIDTH;
localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH/8;

localparam AUX_WIDTH = 10;

parameter IdcodeValue = 32'h349511C3;
// --== CLOCK and RESET ==--
input logic              clk;    //core clock
input logic              rst_n;  //reset for APB and AXI interfaces
input logic              apor_n; //POR reset for debug modules
input logic              aclk;//on ndmreset - the main clock is blocked, so debug module switches to the always on clock

// --== APB SLAVE ==--
APB_BUS.Slave            apb_debug;
//input logic              PSEL,             // To apb2per of apb2per.v
//input logic              PENABLE,          // To apb2per of apb2per.v
//input logic              PWRITE,           // To apb2per of apb2per.v
//input logic [31:0]       PADDR,            // To apb2per of apb2per.v
//input logic [31:0]       PWDATA,           // To apb2per of apb2per.v
//output logic [31:0]      PRDATA;           // From apb2per of apb2per.v
//output logic             PREADY;           // From apb2per of apb2per.v
//output logic             PSLVERR;          // From apb2per of apb2per.v

// --== AXI MASTER ==--
input                    axi_master_aw_ready;
input                    axi_master_w_ready;
input [AXI_ID_WIDTH-1:0] axi_master_b_id;
input [1:0]              axi_master_b_resp;
input                    axi_master_b_valid;
input [USER_WIDTH-1:0]   axi_master_b_user;
input                    axi_master_ar_ready;
input [AXI_ID_WIDTH-1:0] axi_master_r_id;
input [DATA_WIDTH-1:0]   axi_master_r_data;
input [1:0]              axi_master_r_resp;
input                    axi_master_r_last;
input [USER_WIDTH-1:0]   axi_master_r_user;
input                    axi_master_r_valid;
output [ADDR_WIDTH-1:0]  axi_master_aw_addr;   // From lint_2_axi of lint_2_axi.v
output [1:0]             axi_master_aw_burst;  // From lint_2_axi of lint_2_axi.v
output [3:0]             axi_master_aw_cache;  // From lint_2_axi of lint_2_axi.v
output [AXI_ID_WIDTH-1:0] axi_master_aw_id;    // From lint_2_axi of lint_2_axi.v
output [7:0]             axi_master_aw_len;    // From lint_2_axi of lint_2_axi.v
output                   axi_master_aw_lock;   // From lint_2_axi of lint_2_axi.v
output [2:0]             axi_master_aw_prot;   // From lint_2_axi of lint_2_axi.v
output [3:0]             axi_master_aw_qos;    // From lint_2_axi of lint_2_axi.v
output [3:0]             axi_master_aw_region; // From lint_2_axi of lint_2_axi.v
output [2:0]             axi_master_aw_size;   // From lint_2_axi of lint_2_axi.v
output [USER_WIDTH-1:0]  axi_master_aw_user;   // From lint_2_axi of lint_2_axi.v
output                   axi_master_aw_valid;  // From lint_2_axi of lint_2_axi.v
output                   axi_master_b_ready;   // From lint_2_axi of lint_2_axi.v
output                   axi_master_r_ready;   // From lint_2_axi of lint_2_axi.v
output [DATA_WIDTH-1:0]  axi_master_w_data;    // From lint_2_axi of lint_2_axi.v
output                   axi_master_w_last;    // From lint_2_axi of lint_2_axi.v
output [AXI_STRB_WIDTH-1:0] axi_master_w_strb; // From lint_2_axi of lint_2_axi.v
output [USER_WIDTH-1:0]  axi_master_w_user;    // From lint_2_axi of lint_2_axi.v
output                   axi_master_w_valid;   // From lint_2_axi of lint_2_axi.v
output [ADDR_WIDTH-1:0]  axi_master_ar_addr;   // From lint_2_axi of lint_2_axi.v
output [1:0]             axi_master_ar_burst;  // From lint_2_axi of lint_2_axi.v
output [3:0]             axi_master_ar_cache;  // From lint_2_axi of lint_2_axi.v
output [AXI_ID_WIDTH-1:0] axi_master_ar_id;    // From lint_2_axi of lint_2_axi.v
output [7:0]             axi_master_ar_len;    // From lint_2_axi of lint_2_axi.v
output                   axi_master_ar_lock;   // From lint_2_axi of lint_2_axi.v
output [2:0]             axi_master_ar_prot;   // From lint_2_axi of lint_2_axi.v
output [3:0]             axi_master_ar_qos;    // From lint_2_axi of lint_2_axi.v
output [3:0]             axi_master_ar_region; // From lint_2_axi of lint_2_axi.v
output [2:0]             axi_master_ar_size;   // From lint_2_axi of lint_2_axi.v
output [USER_WIDTH-1:0]  axi_master_ar_user;   // From lint_2_axi of lint_2_axi.v
output                   axi_master_ar_valid;  // From lint_2_axi of lint_2_axi.v

// --== JTAG ==--
input logic              jtag_sel;
input logic              tck;              // To dmi_jtag of dmi_jtag.v
input logic              trst;             // To dmi_jtag of dmi_jtag.v
input logic              tdi;              // To dmi_jtag of dmi_jtag.v
input logic              tms;              // To dmi_jtag of dmi_jtag.v
output logic             tdo;              // From dmi_jtag of dmi_jtag.v
OPENOCD_JTAG.slave    openocd_jtag;

// --== debug_req to core(s) ==--
output logic [NrHarts-1:0]    debug_req;        // From dm_top of dm_top.v
output logic                  ndmreset;    // NOTE: this is in aclk domain

/*autowire*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
logic                   dm_master_gnt;          // From lint_2_axi of lint_2_axi.v
logic [ID_WIDTH-1:0]    dm_master_rID;          // From lint_2_axi of lint_2_axi.v
logic [AUX_WIDTH-1:0]   dm_master_raux;         // From lint_2_axi of lint_2_axi.v
logic [31:0]            dm_master_rdata;        // From lint_2_axi of lint_2_axi.v
logic                   dm_master_ropc;         // From lint_2_axi of lint_2_axi.v
logic                   dm_master_rvalid;       // From lint_2_axi of lint_2_axi.v
logic                   dmi_req_valid;          // From dmi_jtag of dmi_jtag.v
logic                   dmi_resp_ready;         // From dmi_jtag of dmi_jtag.v
logic [PER_ADDR_WIDTH-1:0] slave_addr;          // From apb2per of apb2per.v
logic [3:0]             slave_be;               // From apb2per of apb2per.v
logic                   slave_req;              // From apb2per of apb2per.v
logic [31:0]            slave_wdata;            // From apb2per of apb2per.v
logic                   slave_we;               // From apb2per of apb2per.v
// End of automatics
logic [31:0]            slave_rdata;            // From apb2per of apb2per.v
logic                   slave_r_valid;
logic                   dm_master_req;
logic [ADDR_WIDTH-1:0]  dm_master_addr;
logic                   dm_master_we;
logic [31:0]            dm_master_wdata;
logic [7:0]             dm_master_be;
logic [ID_WIDTH-1:0]    dm_master_ID;
logic [AUX_WIDTH-1:0]   dm_master_aux;

logic dmi_req_ready;
logic dmi_resp_valid;
logic tck_muxed;
logic tms_muxed;
logic trst_muxed;
logic tdi_muxed;

dm::dmi_req_t          dmi_req;
dm::dmi_resp_t         dmi_resp;
dm::hartinfo_t /*[NrHarts-1:0]*/ hartinfo;
assign hartinfo/*[nhart_var]*/ = '{
                                   zero1:        '0,
                                   nscratch:      2, // Debug module needs at least two scratch regs
                                   zero0:        '0,
                                   dataaccess: 1'b1, // data registers are memory mapped in the debugger
                                   datasize: dm::DataCount,
                                   dataaddr: dm::DataAddr};

// clocking for ndmreset
// ---------------------
// the debug module asserts/deasserts ndmreset_clk (in clk domain)
// it is synced to ndmreset_aclk (aclk domain)
// ndmreset_aclk is used to change clk_dbg to aclk/clk
// once the switching is done - ndmreset (output) is asserted/deasserted
// * NOTE: clk_dbg is synchronous to clk during normal operation
//         when ndmreset_aclk goes high - we first switch to aclk, and only
//         after the switch is done - assert ndmreset towards the reset controller
//         when ndmreset_aclk goes low - we deassert ndmreset and start the
//         clock switch at the same time
//         
//         IDLE-(dm.ndmreset)->ACLK-(switching done)->NDM_HI-(!dm.ndmreset)->IDLE
localparam IDLE = 2'b00;
localparam ACLK = 2'b01; //bit [0] controls the clock mux
localparam NDMR = 2'b11; //bit [1] is ndmreset
logic clk_dbg;                               
logic clk_dbg_switching;
logic clk_dbg_switching_s;
logic clk_dbg_finished_switching;
logic ndmreset_clk;
logic ndmreset_aclk;

//3 state - state machin
logic [1:0] state;
logic [1:0] next_state;
always @(posedge aclk or negedge apor_n)
    if (!apor_n)
        state <= IDLE;
    else
        state <= next_state;
always @(*) begin    
    next_state = state;

    if (state==IDLE && ndmreset_aclk)
        next_state = ACLK;

    if (state==ACLK && clk_dbg_finished_switching)
        next_state = NDMR;

    if (state==NDMR && !ndmreset_aclk)
        next_state = IDLE;
end

assign ndmreset = state[1];

//clock switching finished mechanism
always @(posedge aclk or negedge apor_n)
    if (!apor_n) 
        clk_dbg_switching_s <= 1'b1;
    else
        clk_dbg_switching_s <= clk_dbg_switching;
assign clk_dbg_finished_switching = !clk_dbg_switching && clk_dbg_switching_s;

//sync ndmreset from clk domain to aclk domian
sync_2ff_arst sync_ndmreset(.clk(aclk), .rstn(apor_n), .in(ndmreset_clk), .out(ndmreset_aclk));

//clock mux
m_glitch_free_clock_mux mx_clk_dbg (
    .clk_cntrl(aclk),
    .rst_cntrl_n(apor_n),
    .sel(state[0]),
    .switch_in_progress(clk_dbg_switching),
    .clock_enable(1'b1),
    .clock_enabled(),
   
    //other domains
    .clk0(clk),
    .clk1(aclk),
    .clk_out(clk_dbg),

    .test_mode(1'b0),
    .opcg_mode(1'b0)
);


/*
dmi_jtag AUTO_TEMPLATE(
    .\(.*\)_[io] (\1[]),
    .clk_i(clk_dbg),
    .rst_ni(apor_n),
    .trst_ni(trst_muxed),
    .td_i(tdi_muxed),
    .tck_i(tck_muxed),
    .tms_i(tms_muxed),
    .td_o(tdo),
    .testmode_i(1'b0),

    .dmi_rst_no(),
    .tdo_oe_o(),
);*/
dmi_jtag #(
           .IdcodeValue (IdcodeValue))
         dmi_jtag(/*autoinst*/
                  // Interfaces
                  .dmi_req_o            (dmi_req),               // Templated
                  .dmi_resp_i           (dmi_resp),              // Templated
                  // Outputs
                  .dmi_rst_no           (),                      // Templated
                  .dmi_req_valid_o      (dmi_req_valid),         // Templated
                  .dmi_resp_ready_o     (dmi_resp_ready),        // Templated
                  .td_o                 (tdo),                   // Templated
                  .tdo_oe_o             (),                      // Templated
                  // Inputs
                  .clk_i                (clk_dbg),               // Templated
                  .rst_ni               (apor_n),                // Templated
                  .testmode_i           (1'b0),                  // Templated
                  .dmi_req_ready_i      (dmi_req_ready),         // Templated
                  .dmi_resp_valid_i     (dmi_resp_valid),        // Templated
                  .tck_i                (tck_muxed),             // Templated
                  .tms_i                (tms_muxed),             // Templated
                  .trst_ni              (trst_muxed),            // Templated
                  .td_i                 (tdi_muxed));            // Templated

wire unavailable;
m_ff_aset unavailable_ff (.CK(clk), .SN(rst_n), .D(1'b0), .Q(unavailable));
/*dm_top AUTO_TEMPLATE(
    .master_r_valid_i         (dm_master_rvalid),
    .master_r_rdata_i         (dm_master_rdata[]),
    .master_add_o (dm_master_addr[]),
    .master_\(.*\)_[io] (dm_master_\1[]),
    .\(.*\)_[io] (\1[]),
    .clk_i(clk_dbg),
    ..*rst_ni(apor_n),
    .testmode_i(1'b0),
    .unavailable_i({NrHarts{unavailable}}),

    .dmactive_o(),
);*/
dm_top #(
         .NrHarts(NrHarts),
         .BusWidth(BusWidth),
         .SelectableHarts({NrHarts{1'b1}}/*SELECTABLE_HARTS*/))
       dm_top(/*auto-inst*/
              // Interfaces
              .dmi_req_i                (dmi_req),
              .dmi_resp_o               (dmi_resp),
              // Outputs
              .ndmreset_o               (ndmreset_clk),
              .dmactive_o               (),
              .debug_req_o              (debug_req[NrHarts-1:0]),
              .slave_rdata_o            (slave_rdata[BusWidth-1:0]),
              .master_req_o             (dm_master_req),
              .master_add_o             (dm_master_addr[BusWidth-1:0]),
              .master_we_o              (dm_master_we),
              .master_wdata_o           (dm_master_wdata[BusWidth-1:0]),
              .master_be_o              (dm_master_be[BusWidth/8-1:0]),
              .dmi_req_ready_o          (dmi_req_ready),
              .dmi_resp_valid_o         (dmi_resp_valid),
              // Inputs
              .clk_i                    (clk_dbg),
              .rst_ni                   (apor_n),
              .testmode_i               (1'b0),
              .unavailable_i            ({NrHarts{unavailable}}),
              //.dm::hartinfo_t           (dm::hartinfo_t/*[NrHarts-1:0].[NrHarts-1:0]*/),
              .hartinfo_i               (hartinfo),
              .slave_req_i              (slave_req),
              .slave_we_i               (slave_we),
              .slave_addr_i             (slave_addr[BusWidth-1:0]),
              .slave_be_i               (slave_be[BusWidth/8-1:0]),
              .slave_wdata_i            (slave_wdata[BusWidth-1:0]),
              .master_gnt_i             (dm_master_gnt),
              .master_r_valid_i         (dm_master_rvalid),
              .master_r_rdata_i         (dm_master_rdata[BusWidth-1:0]),
              .dmi_rst_ni               (apor_n),
              .dmi_req_valid_i          (dmi_req_valid),
              .dmi_resp_ready_i         (dmi_resp_ready));

/*apb2per AUTO_TEMPLATE (
    .clk_i(clk),
    .rst_ni(rst_n),
    .per_master_\(.*\)_[io] (slave_\1[]),
    .per_master_add_o(slave_addr[]),
    .per_master_r_rdata_i(slave_rdata[]),
    .per_master_gnt_i(slave_req),
    .per_master_r_opc_i(1'b0),
    .\(P.*\) (apb_debug.@"(downcase \\"\1\\")"[]),
);*/
apb2per #(
        .PER_ADDR_WIDTH (32),
        .APB_ADDR_WIDTH (32))
        apb2per (/*autoinst*/
                 // Outputs
                 .PRDATA                (apb_debug.prdata[31:0]), // Templated
                 .PREADY                (apb_debug.pready),      // Templated
                 .PSLVERR               (apb_debug.pslverr),     // Templated
                 .per_master_req_o      (slave_req),             // Templated
                 .per_master_add_o      (slave_addr[PER_ADDR_WIDTH-1:0]), // Templated
                 .per_master_we_o       (slave_we),              // Templated
                 .per_master_wdata_o    (slave_wdata[31:0]),     // Templated
                 .per_master_be_o       (slave_be[3:0]),         // Templated
                 // Inputs
                 .clk_i                 (clk),                   // Templated
                 .rst_ni                (rst_n),                 // Templated
                 .PADDR                 (apb_debug.paddr[APB_ADDR_WIDTH-1:0]), // Templated
                 .PWDATA                (apb_debug.pwdata[31:0]), // Templated
                 .PWRITE                (apb_debug.pwrite),      // Templated
                 .PSEL                  (apb_debug.psel),        // Templated
                 .PENABLE               (apb_debug.penable),     // Templated
                 .per_master_gnt_i      (slave_req),             // Templated
                 .per_master_r_valid_i  (slave_r_valid),         // Templated
                 .per_master_r_opc_i    (1'b0),                  // Templated
                 .per_master_r_rdata_i  (slave_rdata[31:0]));    // Templated
always_ff @(posedge clk or negedge rst_n) begin : apb2per_valid
         if(~rst_n) begin
             slave_r_valid <= 0;
         end else begin
             slave_r_valid <= slave_req;
         end
     end

/*lint_2_axi AUTO_TEMPLATE (
    .clk_i(clk),
    .rst_ni(rst_n),
    .data_\(.*\)_[io] (dm_master_\1[]),
    .\([abrw].*\)_[io] (axi_master_\1[]),
);*/
lint_2_axi 
    #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .BE_WIDTH(BE_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .AUX_WIDTH(AUX_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .AXI_STRB_WIDTH(AXI_STRB_WIDTH),
    .REGISTERED_GRANT("FALSE")
    )
lint_2_axi(/*autoinst*/
           // Outputs
           .data_gnt_o                  (dm_master_gnt),         // Templated
           .data_rvalid_o               (dm_master_rvalid),      // Templated
           .data_rdata_o                (dm_master_rdata[31:0]), // Templated
           .data_ropc_o                 (dm_master_ropc),        // Templated
           .data_raux_o                 (dm_master_raux[AUX_WIDTH-1:0]), // Templated
           .data_rID_o                  (dm_master_rID[ID_WIDTH-1:0]), // Templated
           .aw_id_o                     (axi_master_aw_id[AXI_ID_WIDTH-1:0]), // Templated
           .aw_addr_o                   (axi_master_aw_addr[ADDR_WIDTH-1:0]), // Templated
           .aw_len_o                    (axi_master_aw_len[7:0]), // Templated
           .aw_size_o                   (axi_master_aw_size[2:0]), // Templated
           .aw_burst_o                  (axi_master_aw_burst[1:0]), // Templated
           .aw_lock_o                   (axi_master_aw_lock),    // Templated
           .aw_cache_o                  (axi_master_aw_cache[3:0]), // Templated
           .aw_prot_o                   (axi_master_aw_prot[2:0]), // Templated
           .aw_region_o                 (axi_master_aw_region[3:0]), // Templated
           .aw_user_o                   (axi_master_aw_user[USER_WIDTH-1:0]), // Templated
           .aw_qos_o                    (axi_master_aw_qos[3:0]), // Templated
           .aw_valid_o                  (axi_master_aw_valid),   // Templated
           .w_data_o                    (axi_master_w_data[DATA_WIDTH-1:0]), // Templated
           .w_strb_o                    (axi_master_w_strb[AXI_STRB_WIDTH-1:0]), // Templated
           .w_last_o                    (axi_master_w_last),     // Templated
           .w_user_o                    (axi_master_w_user[USER_WIDTH-1:0]), // Templated
           .w_valid_o                   (axi_master_w_valid),    // Templated
           .b_ready_o                   (axi_master_b_ready),    // Templated
           .ar_id_o                     (axi_master_ar_id[AXI_ID_WIDTH-1:0]), // Templated
           .ar_addr_o                   (axi_master_ar_addr[ADDR_WIDTH-1:0]), // Templated
           .ar_len_o                    (axi_master_ar_len[7:0]), // Templated
           .ar_size_o                   (axi_master_ar_size[2:0]), // Templated
           .ar_burst_o                  (axi_master_ar_burst[1:0]), // Templated
           .ar_lock_o                   (axi_master_ar_lock),    // Templated
           .ar_cache_o                  (axi_master_ar_cache[3:0]), // Templated
           .ar_prot_o                   (axi_master_ar_prot[2:0]), // Templated
           .ar_region_o                 (axi_master_ar_region[3:0]), // Templated
           .ar_user_o                   (axi_master_ar_user[USER_WIDTH-1:0]), // Templated
           .ar_qos_o                    (axi_master_ar_qos[3:0]), // Templated
           .ar_valid_o                  (axi_master_ar_valid),   // Templated
           .r_ready_o                   (axi_master_r_ready),    // Templated
           // Inputs
           .clk_i                       (clk),                   // Templated
           .rst_ni                      (rst_n),                 // Templated
           .data_req_i                  (dm_master_req),         // Templated
           .data_addr_i                 (dm_master_addr[ADDR_WIDTH-1:0]), // Templated
           .data_we_i                   (dm_master_we),          // Templated
           .data_wdata_i                (dm_master_wdata[31:0]), // Templated
           .data_be_i                   (dm_master_be[BE_WIDTH-1:0]), // Templated
           .data_ID_i                   (dm_master_ID[ID_WIDTH-1:0]), // Templated
           .data_aux_i                  (dm_master_aux[AUX_WIDTH-1:0]), // Templated
           .aw_ready_i                  (axi_master_aw_ready),   // Templated
           .w_ready_i                   (axi_master_w_ready),    // Templated
           .b_id_i                      (axi_master_b_id[AXI_ID_WIDTH-1:0]), // Templated
           .b_resp_i                    (axi_master_b_resp[1:0]), // Templated
           .b_valid_i                   (axi_master_b_valid),    // Templated
           .b_user_i                    (axi_master_b_user[USER_WIDTH-1:0]), // Templated
           .ar_ready_i                  (axi_master_ar_ready),   // Templated
           .r_id_i                      (axi_master_r_id[AXI_ID_WIDTH-1:0]), // Templated
           .r_data_i                    (axi_master_r_data[DATA_WIDTH-1:0]), // Templated
           .r_resp_i                    (axi_master_r_resp[1:0]), // Templated
           .r_last_i                    (axi_master_r_last),     // Templated
           .r_user_i                    (axi_master_r_user[USER_WIDTH-1:0]), // Templated
           .r_valid_i                   (axi_master_r_valid));   // Templated

m_mx2 mx_trst ( .Z(trst_muxed), .S(jtag_sel), .B(trst), .A(!openocd_jtag.trst) );
m_mx2 mx_tck  ( .Z(tck_muxed),  .S(jtag_sel), .B(tck),  .A(openocd_jtag.tck)   );
m_mx2 mx_tms  ( .Z(tms_muxed),  .S(jtag_sel), .B(tms),  .A(openocd_jtag.tms)   );
m_mx2 mx_tdi  ( .Z(tdi_muxed),  .S(jtag_sel), .B(tdi),  .A(openocd_jtag.tdi)   );

always @(tdo) //make unknowns --> 0
    if (tdo)
        openocd_jtag.tdo = 1;
    else
        openocd_jtag.tdo = 0;
endmodule

//Local Variables:
//verilog-auto-input-ignore-regexp: "hartinfo"
// verilog-library-files:( "../../apb/apb2per/apb2per.sv" "../../interco/RTL/lint_2_axi.sv")
//END:
