
`timescale 1ps/1ps
import floo_hamsa_pkg::*;

module fpgnix_tb();

reg clk_ref;
reg rst_n;

// CLOCK
`ifdef ALTERA
    localparam REF_CLK_PERIOD = 40;
`else
    localparam REF_CLK_PERIOD = 100;
`endif
localparam REF_CLK_PERIOD_PS = (REF_CLK_PERIOD*1000);

parameter time TIMEOUT = 1000000000;

initial begin
    clk_ref = 1'b0;
    forever #(REF_CLK_PERIOD_PS/2) clk_ref = ~clk_ref;
end

// RESET
initial begin
    rst_n = 1'b0;
    #1
    @(posedge clk_ref)
    rst_n = 1'b1;
end

wire uart_tx;
logic uart_rx;
logic [3:0] led;
//jtag
wire VTref;
wire RTCK;
wire TDO;
wire TRSTn;
wire TDI;
wire TMS;
wire TCK;
wire nSRST;
assign nSRST = 1'b1;


// DDR memory instance
`ifdef DDR_INTRFC
`ifndef PSD_DDR

	wire [1:0]	mem_odt;
	wire [1:0]	mem_cs_n;
	wire [1:0]	mem_cke;
	wire [13:0]	mem_addr;
	wire [2:0]	mem_ba;
	wire 	    mem_ras_n;
	wire 	    mem_cas_n;
	wire 	    mem_we_n;
	wire [7:0]	mem_dm;
	wire [1:0]	mem_clk;
	wire [1:0]	mem_clk_n;
	wire [63:0]	mem_dq;
	wire [7:0]	mem_dqs;
	wire 	    ddr_led;
    
    wire pad_spis_clk;
    wire pad_spis_cs;
    wire pad_spis_di;
    wire pad_spis_do;     
    
    
ddr2_dimm ddr2_dimm (     // ddr2 actual DIMM
	   
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
	   .mem_dqs    ( mem_dqs   )   // inout	         
	);
        

`endif // DDR_INTRFC
`endif // ndef PSD_DDR


fpgnix fpgnix (
              // Outputs
              .uart_tx                  (uart_tx),
              .led                      (led[3:0]),
              .VTref                    (VTref),
              .RTCK                     (RTCK),
              .TDO                      (TDO),
              // Inputs
              .sys_rst                  (rst_n), 
              .altera_clk25mhz          (clk_ref),
              .uart_rx                  (uart_rx),
              .nTRST                    (TRSTn),
              .TDI                      (TDI),
              .TMS                      (TMS),
              .TCK                      (TCK),
              .nSRST                    (nSRST),
              
              `ifdef DDR_INTRFC
              `ifndef PSD_DDR             
               
              .mem_odt    ( mem_odt   ),  // output [1:0]	
	          .mem_cs_n   ( mem_cs_n  ),  // output [1:0]	
	          .mem_cke    ( mem_cke   ),  // output [1:0]	
	          .mem_addr   ( mem_addr  ),  // output [13:0]	
	          .mem_ba     ( mem_ba    ),  // output [2:0]	
	          .mem_ras_n  ( mem_ras_n ),  // output		    
	          .mem_cas_n  ( mem_cas_n ),  // output		    
	          .mem_we_n   ( mem_we_n  ),  // output		    
	          .mem_dm     ( mem_dm    ),  // output [7:0]	
	          .mem_clk    ( mem_clk   ),  // inout  [1:0]	
	          .mem_clk_n  ( mem_clk_n ),  // inout  [1:0]	
	          .mem_dq     ( mem_dq    ),  // inout  [63:0]	
	          .mem_dqs    ( mem_dqs   ),  // inout  [7:0]
                           
              `endif // DDR_INTRFC
              `endif // ndef PSD_DDR

              .pad_spis_clk        (pad_spis_clk),
              .pad_spis_cs         (pad_spis_cs),
              .pad_spis_di         (pad_spis_di),
              .pad_spis_do         (pad_spis_do)              
              
            );


`ifdef ENABLE_SPI_PY_TB
py_spi_tb py_spi_tb (
    .spi_sdi(pad_spis_do),
    .spi_csn(pad_spis_cs),    
    .spi_sck(pad_spis_clk),    
    .spi_sdo(pad_spis_di)    
) ;
`else

assign pad_spis_clk = 1'b0 ; 
assign pad_spis_cs  = 1'b0 ;
assign pad_spis_di  = 1'b0 ;
    
`endif



               
// ======
//  UART
// ======
`define R2D2_OPTION (0)
`ifdef R2D2_TELNET
    `define R2D2_OPTION (1)
`endif

`ifdef R2D2_PYSHELL
    `define R2D2_OPTION (2)
`endif

`ifdef R2D2_TXONLY
    `define R2D2_OPTION (3)
`endif

`ifdef R2D2_JTAG
    `define R2D2_OPTION (4)
`endif

wire clk_sys;
assign clk_sys = fpgnix.vqm_msystem_wrap.msystem.clk_sys;


`ifdef SMART_UART_TB_NON_R2D2
  
// Smart uart tb including file access from running C code but without R2D2 support
// Also compliant with FPGA/DDP pyshell terminal and file access SW interface.
// This means same compiled code images with file access can run both in this mode and in the FPGA.
// Alternatively uart_vip currently also support most to all of above

uart_bus #(

    .BAUDRATE(`BAUD_RATE),    
    .PARITY_EN(0),
    .NUM_SELECTABLE_UARTS(1) 
  )    
  i_uart_bus (  
    .uart_rx(uart_tx),
    .uart_tx(uart_rx),
    .rx_en('1)
  );


`else


uart_vip
  #(
    .BAUD_RATE(`BAUD_RATE),
    .PARITY_EN(0),
    .R2D2_OPTION(`R2D2_OPTION)

    `ifdef USE_SOCKET
        , .USE_SOCKET(1)
    `endif

  )
  uart_vip
  (
    .rx         ( uart_tx ),
    .tx         ( uart_rx ),
    .rx_en      ( 1'b1    ),
    .clk        ( clk_sys )
  );
  
`endif  
  
  pulldown uart_pulldown (uart_tx);

// jtag calls from dpi
// based on riscv/tb/dm/tb_test_env.sv
`ifdef JTAG_BITBANG
logic sim_jtag_exit;
logic sim_jtag_enable;
initial begin
    sim_jtag_enable = 1'b0;
    #1000
    sim_jtag_enable = 1'b1;
end
localparam OPENOCD_PORT=8989;

SimJTAG #(
        .TICK_DELAY (300),
        .PORT(OPENOCD_PORT))
        i_sim_jtag (
                    //.clock                (clk_sys),
                    .reset                (~rst_n),
                    .enable               (sim_jtag_enable),
                    .init_done            (rst_n),
                    .jtag_TCK             (TCK),
                    .jtag_TMS             (TMS),
                    .jtag_TDI             (TDI),
                    .jtag_TRSTn           (TRSTn),
                    .jtag_TDO_data        (TDO),
                    .jtag_TDO_driven      (1'b1),
                    .exit                 (sim_jtag_exit));

    always @(*) begin : jtag_exit_handler
        if (sim_jtag_exit) begin
            sim_jtag_enable = 1'b0;
            $stop(2); // allow user to continue running the simulation after jtag disconnect
        end
    end
`else //!JTAG_BITBANG
    assign TCK   = 1'b0;
    assign TRSTn = 1'b0;
    assign TMS   = 1'b0;
    assign TDI   = 1'b0;
`endif //JTAG_BITBANG

// ---------------------------------------------------------------------------
// Stage-1 FlooNoC: North-port loopback + chimney activity monitor
// (skipped when FLOO_UART_BISECT_C — do not drive masters[4] from TB)
// ---------------------------------------------------------------------------
wire floo_tb_clk;
wire floo_rstn;
assign floo_tb_clk = fpgnix.vqm_msystem_wrap.msystem.clk_sys;
assign floo_rstn   = fpgnix.vqm_msystem_wrap.rstn_sys;

`ifdef RTL_SIM
`ifndef FLOO_UART_BISECT_C
// APB UART clock is gated until SW writes CGREG; testmode ungates all peripheral clocks.
initial begin : floo_periph_clk_bypass
    wait (fpgnix.vqm_msystem_wrap.rstn_sys === 1'b1);
    force fpgnix.vqm_msystem_wrap.msystem.peripherals_i.peripheral_clock_gate_ctrl = 32'hFFFF_FFFF;
    $display("[FLOO_TB] RTL_SIM: forced peripheral_clock_gate_ctrl=all1 (UART/APB clocks)");
end
`else
initial $display("[FLOO_TB] FLOO_UART_BISECT_C: no force on peripheral_clock_gate_ctrl, pad_testmode=0");
`endif

// Pinpoint CPU vs AXI vs APB for uart_set_cfg() stall @ CGREG (0x1A107004).
initial $display("[UART_DBG] monitor enabled (RTL_SIM)");

logic        uart_dbg_ar_pending;
logic [31:0] uart_dbg_ar_addr;
integer      uart_dbg_apb_soc_ctrl_hits;
integer      uart_dbg_periph_ar_hits;
integer      uart_dbg_periph_r_hits;

function automatic bit uart_dbg_is_periph_addr(input logic [31:0] addr);
    return (addr >= 32'h1A10_0000) && (addr < 32'h1A50_0000);
endfunction

initial begin
    uart_dbg_apb_soc_ctrl_hits = 0;
    uart_dbg_periph_ar_hits    = 0;
    uart_dbg_periph_r_hits     = 0;
end

always @(posedge floo_tb_clk) begin
    if (fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.psel &&
        fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.penable &&
        uart_dbg_apb_soc_ctrl_hits < 8) begin
        $display("[UART_DBG] APB soc_ctrl access paddr=0x%03x pwrite=%b prdata=0x%08x @ %0t",
                 fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.paddr[11:0],
                 fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.pwrite,
                 fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.prdata,
                 $time);
        uart_dbg_apb_soc_ctrl_hits = uart_dbg_apb_soc_ctrl_hits + 1;
    end
    if (fpgnix.vqm_msystem_wrap.msystem.slaves[2].ar_valid &&
        fpgnix.vqm_msystem_wrap.msystem.slaves[2].ar_ready &&
        uart_dbg_periph_ar_hits < 8) begin
        $display("[UART_DBG] periph slaves[2] AR accepted addr=0x%08x ar_id=0x%02x @ %0t",
                 fpgnix.vqm_msystem_wrap.msystem.slaves[2].ar_addr,
                 fpgnix.vqm_msystem_wrap.msystem.slaves[2].ar_id,
                 $time);
        uart_dbg_periph_ar_hits = uart_dbg_periph_ar_hits + 1;
    end
    if (fpgnix.vqm_msystem_wrap.msystem.slaves[2].r_valid &&
        uart_dbg_periph_r_hits < 8) begin
        $display("[UART_DBG] periph slaves[2] r_valid=1 r_ready=%b r_data=0x%08x r_id=0x%02x @ %0t",
                 fpgnix.vqm_msystem_wrap.msystem.slaves[2].r_ready,
                 fpgnix.vqm_msystem_wrap.msystem.slaves[2].r_data,
                 fpgnix.vqm_msystem_wrap.msystem.slaves[2].r_id,
                 $time);
        uart_dbg_periph_r_hits = uart_dbg_periph_r_hits + 1;
    end
end

always_ff @(posedge floo_tb_clk or negedge floo_rstn) begin
    if (!floo_rstn) begin
        uart_dbg_ar_pending <= 1'b0;
        uart_dbg_ar_addr    <= '0;
    end else begin
        if (fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_valid &&
            fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_ready &&
            uart_dbg_is_periph_addr(fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_addr)) begin
            uart_dbg_ar_pending <= 1'b1;
            uart_dbg_ar_addr    <= fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_addr;
            $display("[UART_DBG] core AR accepted addr=0x%08x @ %0t",
                     fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_addr, $time);
        end
        if (uart_dbg_ar_pending &&
            fpgnix.vqm_msystem_wrap.msystem.masters[0].r_valid &&
            fpgnix.vqm_msystem_wrap.msystem.masters[0].r_ready) begin
            uart_dbg_ar_pending <= 1'b0;
            $display("[UART_DBG] core R done data=0x%016x (pending addr was 0x%08x) @ %0t",
                     fpgnix.vqm_msystem_wrap.msystem.masters[0].r_data, uart_dbg_ar_addr, $time);
        end
    end
end

initial begin : uart_dbg_stall_report
    #500_000; // 500 us — core stalls ~7 us (trace cycle 68)
    $display("[UART_DBG] --- snapshot @ 500us ---");
    $display("[UART_DBG] core masters[0] ar_valid=%b ar_ready=%b ar_addr=0x%08x",
             fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_valid,
             fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_ready,
             fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_addr);
    $display("[UART_DBG] core masters[0] r_valid=%b r_ready=%b ar_pending=%b pending_addr=0x%08x",
             fpgnix.vqm_msystem_wrap.msystem.masters[0].r_valid,
             fpgnix.vqm_msystem_wrap.msystem.masters[0].r_ready,
             uart_dbg_ar_pending, uart_dbg_ar_addr);
    $display("[UART_DBG] periph slaves[2] ar_valid=%b ar_ready=%b r_valid=%b",
             fpgnix.vqm_msystem_wrap.msystem.slaves[2].ar_valid,
             fpgnix.vqm_msystem_wrap.msystem.slaves[2].ar_ready,
             fpgnix.vqm_msystem_wrap.msystem.slaves[2].r_valid);
    $display("[UART_DBG] soc_ctrl psel=%b penable=%b pready=%b apb_hits=%0d",
             fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.psel,
             fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.penable,
             fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.pready,
             uart_dbg_apb_soc_ctrl_hits);
    if (uart_dbg_ar_pending)
        $display("[UART_DBG] STALL: core LSU waiting for AXI read (likely CGREG) - not an APB PREADY issue");
    else if (uart_dbg_apb_soc_ctrl_hits == 0 &&
             (fpgnix.vqm_msystem_wrap.msystem.masters[0].ar_valid ||
              fpgnix.vqm_msystem_wrap.msystem.masters[0].aw_valid))
        $display("[UART_DBG] STALL: core issued AXI to periph but APB soc_ctrl never selected - check axi_node decode / axi2apb");
    else if (uart_dbg_apb_soc_ctrl_hits > 0 && uart_dbg_ar_pending) begin
        if (uart_dbg_periph_r_hits > 0)
            $display("[UART_DBG] STALL: slaves[2].r_valid seen but masters[0] R missing — axi_node return / ID");
        else if (uart_dbg_periph_ar_hits > 0)
            $display("[UART_DBG] STALL: slaves[2] AR ok, APB ok, no slaves[2].r_valid — axi2apb read FSM");
        else
            $display("[UART_DBG] STALL: APB ok but slaves[2] AR never accepted — axi_node forward path");
    end
end
`endif // RTL_SIM

integer floo_uart_tx_edges;
initial floo_uart_tx_edges = 0;
always @(posedge uart_tx) floo_uart_tx_edges++;

initial begin : floo_boot_diag
    #10_000_000; // 10 ms after time 0
    $display("[FLOO_BOOT] enable_core=%b ndmreset=%b rstn_sys=%b fetch_int=%b clk_gate=%b boot_addr=0x%08x",
             fpgnix.vqm_msystem_wrap.enable_core,
             fpgnix.vqm_msystem_wrap.ndmreset,
             fpgnix.vqm_msystem_wrap.rstn_sys,
             fpgnix.vqm_msystem_wrap.msystem.fetch_enable_int,
             fpgnix.vqm_msystem_wrap.msystem.clk_gate_core_int,
             fpgnix.vqm_msystem_wrap.msystem.boot_addr_int);
    #10_000_000; // 20 ms total
    $display("[FLOO_UART] uart_tx_edges=%0d by 20ms (0 => core not driving UART)", floo_uart_tx_edges);
end

`ifndef FLOO_UART_BISECT_C

logic floo_remote_req_valid;
logic floo_remote_rsp_valid;
floo_req_chan_t floo_remote_req;
floo_rsp_chan_t floo_remote_rsp;
floo_req_t floo_remote_req_i;
floo_rsp_t floo_remote_rsp_i;

hamsa_floo_remote_mem_endpoint i_hamsa_floo_remote_mem_endpoint (
    .clk_i            ( floo_tb_clk           ),
    .rst_ni           ( floo_rstn             ),
    .test_enable_i    ( 1'b0                  ),
    .floo_req_i       ( fpgnix.floo_req_o     ),
    .floo_rsp_i       ( fpgnix.floo_rsp_o     ),
    .floo_req_valid_o ( floo_remote_req_valid ),
    .floo_req_o       ( floo_remote_req       ),
    .floo_req_ready_i ( 1'b1                  ),
    .floo_rsp_valid_o ( floo_remote_rsp_valid ),
    .floo_rsp_o       ( floo_remote_rsp       ),
    .floo_rsp_ready_i ( 1'b1                  )
);

assign floo_remote_req_i.valid = floo_remote_req_valid;
assign floo_remote_req_i.req   = floo_remote_req;
assign floo_remote_req_i.ready = 1'b1;
assign floo_remote_rsp_i.valid = floo_remote_rsp_valid;
assign floo_remote_rsp_i.rsp   = floo_remote_rsp;
assign floo_remote_rsp_i.ready = 1'b1;

assign fpgnix.floo_req_i = floo_remote_req_i;
assign fpgnix.floo_rsp_i = floo_remote_rsp_i;

// End-to-end proof: drive AXI writes through HAMSA xtrn into remote FlooNoC RAM,
// then read the same words back through the reverse path.
typedef enum logic [3:0] {
    FLOO_ST_IDLE       = 4'd0,
    FLOO_ST_AW         = 4'd1,
    FLOO_ST_W          = 4'd2,
    FLOO_ST_B          = 4'd3,
    FLOO_ST_NEXT_WRITE = 4'd4,
    FLOO_ST_NEXT_READ  = 4'd5,
    FLOO_ST_AR         = 4'd6,
    FLOO_ST_R          = 4'd7,
    FLOO_ST_DONE       = 4'd8
} floo_stim_e;

floo_stim_e        floo_stim_state;
integer            floo_stim_cycles;
integer            floo_stim_start_delay;
integer            floo_stim_max_cycles;
integer            floo_remote_idx;
integer            floo_remote_words;
integer            floo_txn_idx;
integer            floo_pass_count;
integer            floo_fail_count;
integer            floo_axi_cycle;
integer            floo_write_start_cycle [0:3];
integer            floo_read_start_cycle  [0:3];
integer            floo_reset_idx;
logic [31:0]       floo_remote_base_addr;
logic [31:0]       floo_remote_data;
logic [7:0]        floo_current_word;
logic [31:0]       floo_current_addr;
logic [31:0]       floo_current_data;

assign floo_current_word = (floo_remote_idx + floo_txn_idx) & 8'hff;
assign floo_current_addr = {floo_remote_base_addr[31:10], floo_current_word, 2'b00};
assign floo_current_data = floo_remote_data + floo_txn_idx;

initial begin
    floo_stim_start_delay = 500;
    floo_stim_max_cycles  = 50000;
    floo_remote_idx       = 0;
    floo_remote_words     = 4;
    floo_remote_base_addr = 32'h0010_0000;
    floo_remote_data      = 32'hF100_F100;
    void'($value$plusargs("FLOO_STIM_DELAY=%d", floo_stim_start_delay));
    void'($value$plusargs("FLOO_STIM_MAX_CYCLES=%d", floo_stim_max_cycles));
    void'($value$plusargs("FLOO_REMOTE_IDX=%d", floo_remote_idx));
    void'($value$plusargs("FLOO_REMOTE_WORDS=%d", floo_remote_words));
    void'($value$plusargs("FLOO_REMOTE_ADDR=%h", floo_remote_base_addr));
    void'($value$plusargs("FLOO_REMOTE_DATA=%h", floo_remote_data));
    if (floo_remote_idx < 0)
        floo_remote_idx = 0;
    if (floo_remote_idx > 255)
        floo_remote_idx = 255;
    if (floo_remote_words < 1)
        floo_remote_words = 1;
    if (floo_remote_words > 4)
        floo_remote_words = 4;
    if ((floo_remote_idx + floo_remote_words) > 256)
        floo_remote_words = 256 - floo_remote_idx;
    $display("[FLOO_STIM] remote RAM target base=0x%08x first_word=%0d words=%0d first_data=0x%08x",
             floo_remote_base_addr, floo_remote_idx, floo_remote_words, floo_remote_data);
end

always_ff @(posedge floo_tb_clk or negedge floo_rstn) begin : floo_axi_stim
    if (!floo_rstn) begin
        floo_stim_state  <= FLOO_ST_IDLE;
        floo_stim_cycles <= 0;
        floo_txn_idx     <= 0;
        floo_pass_count  <= 0;
        floo_fail_count  <= 0;
        floo_axi_cycle   <= 0;
        for (floo_reset_idx = 0; floo_reset_idx < 4; floo_reset_idx = floo_reset_idx + 1) begin
            floo_write_start_cycle[floo_reset_idx] <= 0;
            floo_read_start_cycle[floo_reset_idx]  <= 0;
        end
        fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid  <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_valid  <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid   <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready   <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].r_ready   <= 1'b0;
    end else begin
        floo_axi_cycle <= floo_axi_cycle + 1;
        case (floo_stim_state)
            FLOO_ST_IDLE: begin
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_valid <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid  <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready  <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].r_ready  <= 1'b0;
                if (floo_stim_cycles == floo_stim_start_delay) begin
                    floo_txn_idx <= 0;
                    floo_write_start_cycle[0] <= floo_axi_cycle;
                    $display("[FLOO_STIM] driving AXI RAM write word=%0d addr=0x%08x data=0x%08x",
                             floo_current_word, floo_current_addr, floo_current_data);
                    // XYAddrOffsetY=20 routes to remote tile (0,1); bits [9:2] select a RAM word.
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_addr   <= floo_current_addr;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_id     <= 2'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_len    <= 8'h0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_size   <= 3'b010;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_burst <= 2'b01;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_lock  <= 1'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_cache <= 4'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_prot  <= 3'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_qos   <= 4'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_region<= 4'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_user  <= 1'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid <= 1'b1;
                    floo_stim_state  <= FLOO_ST_AW;
                    floo_stim_cycles <= 0;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            FLOO_ST_AW: begin
                if (fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_ready) begin
                    $display("[FLOO_STIM] aw_ready word=%0d @ time %0t",
                             floo_current_word, $time);
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid <= 1'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid  <= 1'b1;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_data   <= floo_current_data;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_strb    <= 4'hF;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_last   <= 1'b1;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_user    <= 1'b0;
                    floo_stim_state  <= FLOO_ST_W;
                    floo_stim_cycles <= 0;
                end else if (floo_stim_cycles >= floo_stim_max_cycles) begin
                    $display("[FLOO_STIM] TIMEOUT waiting for aw_ready (rstn_sys=%b ndmreset=%b)",
                             floo_rstn, fpgnix.vqm_msystem_wrap.ndmreset);
                    $display("[FLOO_STIM] dbg mgr aw_valid=%b aw_ready=%b rstn_sys=%b",
                             fpgnix.vqm_msystem_wrap.msystem.chimney_mgr_req.aw_valid,
                             fpgnix.vqm_msystem_wrap.msystem.chimney_mgr_rsp.aw_ready,
                             fpgnix.vqm_msystem_wrap.rstn_sys);
                    floo_stim_state <= FLOO_ST_DONE;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            FLOO_ST_W: begin
                if (fpgnix.vqm_msystem_wrap.msystem.masters[4].w_ready) begin
                    $display("[FLOO_STIM] w_ready word=%0d @ time %0t",
                             floo_current_word, $time);
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid <= 1'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready <= 1'b1;
                    floo_stim_state  <= FLOO_ST_B;
                    floo_stim_cycles <= 0;
                end else if (floo_stim_cycles >= floo_stim_max_cycles) begin
                    $display("[FLOO_STIM] TIMEOUT waiting for w_ready");
                    floo_stim_state <= FLOO_ST_DONE;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            FLOO_ST_B: begin
                if (fpgnix.vqm_msystem_wrap.msystem.masters[4].b_valid) begin
                    $display("[FLOO_STIM] write response word=%0d latency_cycles=%0d @ time %0t",
                             floo_current_word,
                             floo_axi_cycle - floo_write_start_cycle[floo_txn_idx], $time);
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready <= 1'b0;
                    if ((floo_txn_idx + 1) < floo_remote_words) begin
                        floo_txn_idx     <= floo_txn_idx + 1;
                        floo_stim_state  <= FLOO_ST_NEXT_WRITE;
                    end else begin
                        floo_txn_idx     <= 0;
                        floo_stim_state  <= FLOO_ST_NEXT_READ;
                    end
                    floo_stim_cycles <= 0;
                end else if (floo_stim_cycles >= floo_stim_max_cycles) begin
                    $display("[FLOO_STIM] TIMEOUT waiting for b_valid");
                    floo_stim_state <= FLOO_ST_DONE;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            FLOO_ST_NEXT_WRITE: begin
                floo_write_start_cycle[floo_txn_idx] <= floo_axi_cycle;
                $display("[FLOO_STIM] driving AXI RAM write word=%0d addr=0x%08x data=0x%08x",
                         floo_current_word, floo_current_addr, floo_current_data);
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_addr   <= floo_current_addr;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_id     <= 2'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_len    <= 8'h0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_size   <= 3'b010;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_burst  <= 2'b01;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_lock   <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_cache  <= 4'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_prot   <= 3'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_qos    <= 4'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_region <= 4'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_user   <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid  <= 1'b1;
                floo_stim_state  <= FLOO_ST_AW;
                floo_stim_cycles <= 0;
            end

            FLOO_ST_NEXT_READ: begin
                floo_read_start_cycle[floo_txn_idx] <= floo_axi_cycle;
                $display("[FLOO_STIM] driving AXI RAM read word=%0d addr=0x%08x expected=0x%08x @ time %0t",
                         floo_current_word, floo_current_addr, floo_current_data, $time);
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_addr   <= floo_current_addr;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_id     <= 2'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_len    <= 8'h0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_size   <= 3'b010;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_burst  <= 2'b01;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_lock   <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_cache  <= 4'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_prot   <= 3'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_qos    <= 4'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_region <= 4'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_user   <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_valid  <= 1'b1;
                floo_stim_state  <= FLOO_ST_AR;
                floo_stim_cycles <= 0;
            end

            FLOO_ST_AR: begin
                if (fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_ready) begin
                    $display("[FLOO_STIM] ar_ready word=%0d @ time %0t",
                             floo_current_word, $time);
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_valid <= 1'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].r_ready  <= 1'b1;
                    floo_stim_state  <= FLOO_ST_R;
                    floo_stim_cycles <= 0;
                end else if (floo_stim_cycles >= floo_stim_max_cycles) begin
                    $display("[FLOO_STIM] TIMEOUT waiting for ar_ready");
                    floo_stim_state <= FLOO_ST_DONE;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            FLOO_ST_R: begin
                if (fpgnix.vqm_msystem_wrap.msystem.masters[4].r_valid) begin
                    $display("[FLOO_STIM] read response word=%0d data=0x%08x latency_cycles=%0d @ time %0t",
                             floo_current_word,
                             fpgnix.vqm_msystem_wrap.msystem.masters[4].r_data,
                             floo_axi_cycle - floo_read_start_cycle[floo_txn_idx], $time);
                    if (fpgnix.vqm_msystem_wrap.msystem.masters[4].r_data == floo_current_data) begin
                        floo_pass_count <= floo_pass_count + 1;
                        $display("[FLOO_2X2] PASS: remote RAM readback word=%0d data=0x%08x",
                                 floo_current_word, floo_current_data);
                    end else begin
                        floo_fail_count <= floo_fail_count + 1;
                        $display("[FLOO_2X2] FAIL: remote RAM readback word=%0d expected=0x%08x got=0x%08x",
                                 floo_current_word, floo_current_data,
                                 fpgnix.vqm_msystem_wrap.msystem.masters[4].r_data);
                    end
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].r_ready <= 1'b0;
                    if ((floo_txn_idx + 1) < floo_remote_words) begin
                        floo_txn_idx     <= floo_txn_idx + 1;
                        floo_stim_state  <= FLOO_ST_NEXT_READ;
                    end else begin
                        $display("[FLOO_2X2] SUMMARY: remote RAM readbacks pass=%0d fail=%0d total=%0d",
                                 floo_pass_count +
                                 (fpgnix.vqm_msystem_wrap.msystem.masters[4].r_data == floo_current_data),
                                 floo_fail_count +
                                 (fpgnix.vqm_msystem_wrap.msystem.masters[4].r_data != floo_current_data),
                                 floo_remote_words);
                        if ((floo_fail_count == 0) &&
                            (fpgnix.vqm_msystem_wrap.msystem.masters[4].r_data == floo_current_data))
                            $display("[FLOO_2X2] PASS: %0d/%0d remote RAM readbacks matched",
                                     floo_remote_words, floo_remote_words);
                        else
                            $display("[FLOO_2X2] FAIL: remote RAM readback test had mismatches");
                        floo_stim_state <= FLOO_ST_DONE;
                    end
                    floo_stim_cycles <= 0;
                end else if (floo_stim_cycles >= floo_stim_max_cycles) begin
                    $display("[FLOO_STIM] TIMEOUT waiting for r_valid");
                    floo_stim_state <= FLOO_ST_DONE;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            default: ; // FLOO_ST_DONE - hold
        endcase
    end
end

integer floo_flit_count;
integer floo_north_req_count;
integer floo_north_rsp_count;
reg     floo_mon_reported;
initial begin
    floo_flit_count = 0;
    floo_north_req_count = 0;
    floo_north_rsp_count = 0;
    floo_mon_reported = 1'b0;
end

task floo_mon_report;
    begin
        if (!floo_mon_reported) begin
            floo_mon_reported = 1'b1;
            $display("[FLOO_MON] SUMMARY: cumulative flits=%0d", floo_flit_count);
            $display("[FLOO_2X2] SUMMARY: north_req=%0d north_rsp=%0d",
                     floo_north_req_count, floo_north_rsp_count);
            if (floo_flit_count == 0)
                $display("[FLOO_MON] FAIL: zero flits on msystem.chimney_floo_req_o");
            else begin
                $display("[FLOO_MON] PASS: non-zero tile0 chimney flit activity");
                $display("[FLOO_TB] 2x2 check: grep -E \"FLOO_2X2|FLOO_STIM|FLOO_MON|Hey|FINISH\" helloworld/xrun.log");
            end
        end
    end
endtask

// Tile0 chimney request monitor. Remote endpoint logs prove the flits cross the top-level north link.
floo_req_t floo_chimney_req_mon;
floo_req_t floo_north_req_mon;
floo_rsp_t floo_north_rsp_mon;
assign floo_chimney_req_mon = fpgnix.vqm_msystem_wrap.msystem.chimney_floo_req_o;
assign floo_north_req_mon = fpgnix.floo_req_o;
assign floo_north_rsp_mon = fpgnix.floo_rsp_i;

always @(posedge floo_tb_clk) begin
    if (floo_rstn && floo_chimney_req_mon.valid) begin
        floo_flit_count <= floo_flit_count + 1;
        $display("[FLOO_MON] time=%0t chimney_floo_req_o.valid flit_count=%0d",
                 $time, floo_flit_count + 1);
    end
    if (floo_rstn && floo_north_req_mon.valid && floo_north_req_mon.ready) begin
        floo_north_req_count <= floo_north_req_count + 1;
        $display("[FLOO_2X2] tile0 north req handshake count=%0d @ time %0t",
                 floo_north_req_count + 1, $time);
    end
    if (floo_rstn && floo_north_rsp_mon.valid && floo_north_rsp_mon.ready) begin
        floo_north_rsp_count <= floo_north_rsp_count + 1;
        $display("[FLOO_2X2] tile0 north rsp handshake count=%0d @ time %0t",
                 floo_north_rsp_count + 1, $time);
    end
end

// Safety stop so xrun does not hang forever.
// Prefer +FLOO_SIM_TIMEOUT_S=<sec> (e.g. 60). +FLOO_SIM_TIMEOUT_NS=<ns> must fit in 32-bit int (max ~2147 ms).
initial begin : floo_sim_timeout
    longint tout_ns;
    int     tout_s;
    tout_ns = 60_000_000_000;
    if ($value$plusargs("FLOO_SIM_TIMEOUT_S=%d", tout_s))
        tout_ns = tout_s * 1_000_000_000;
    else if ($value$plusargs("FLOO_SIM_TIMEOUT_NS=%d", tout_s))
        tout_ns = tout_s;
    #(tout_ns);
    floo_mon_report();
    $display("[FLOO_TB] safety timeout %0d ns — $finish (grep FINISH / Hey in xrun.log)", tout_ns);
    $finish(2);
end

// XRUN often skips `final` when the testbench calls $finish; schedule an explicit report too.
initial begin : floo_mon_watchdog
    longint delay_ns;
    delay_ns = 500_000_000; // 500 ms — allow TB AXI stim + core UART (override: +FLOO_MON_DELAY=<ns>)
    begin
        int delay_ns_i;
        if ($value$plusargs("FLOO_MON_DELAY=%d", delay_ns_i))
            delay_ns = delay_ns_i;
    end
    #(delay_ns);
    floo_mon_report();
end

// XRUN: final blocks cannot call tasks (BADTFB); initial watchdog above is sufficient

`else // FLOO_UART_BISECT_C

assign fpgnix.floo_req_i = '0;
assign fpgnix.floo_rsp_i = '0;

initial begin : floo_sim_timeout_bisect
    longint tout_ns;
    int     tout_s;
    tout_ns = 60_000_000_000;
    if ($value$plusargs("FLOO_SIM_TIMEOUT_S=%d", tout_s))
        tout_ns = tout_s * 1_000_000_000;
    #(tout_ns);
    $display("[FLOO_TB] FLOO_UART_BISECT_C: safety timeout %0d ns — $finish", tout_ns);
    $finish(2);
end

`endif // FLOO_UART_BISECT_C

endmodule
