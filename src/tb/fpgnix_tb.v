
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
// ---------------------------------------------------------------------------
wire floo_tb_clk;
wire floo_rstn;
assign floo_tb_clk = fpgnix.vqm_msystem_wrap.msystem.clk_sys;
assign floo_rstn   = fpgnix.vqm_msystem_wrap.rstn_sys;

reg [FlooReqBits-1:0] floo_req_i_lb;
reg [FlooRspBits-1:0] floo_rsp_i_lb;

always @(posedge floo_tb_clk or negedge floo_rstn) begin
    if (!floo_rstn) begin
        floo_req_i_lb <= '0;
        floo_rsp_i_lb <= '0;
    end else begin
        floo_req_i_lb <= fpgnix.floo_req_o;
        floo_rsp_i_lb <= fpgnix.floo_rsp_o;
    end
end

assign fpgnix.floo_req_i = floo_req_i_lb;
assign fpgnix.floo_rsp_i = floo_rsp_i_lb;

// Stage-1: drive one AXI write on masters[4] (sync to clk_sys / rstn_sys).
typedef enum logic [2:0] {
    FLOO_ST_IDLE = 3'd0,
    FLOO_ST_AW   = 3'd1,
    FLOO_ST_W    = 3'd2,
    FLOO_ST_B    = 3'd3,
    FLOO_ST_DONE = 3'd4
} floo_stim_e;

floo_stim_e        floo_stim_state;
integer            floo_stim_cycles;
integer            floo_stim_start_delay;
integer            floo_stim_max_cycles;

`ifdef RTL_SIM
// APB UART clock is gated until SW writes CGREG; testmode ungates all peripheral clocks.
initial begin : floo_periph_clk_bypass
    wait (fpgnix.vqm_msystem_wrap.rstn_sys === 1'b1);
    force fpgnix.vqm_msystem_wrap.msystem.peripherals_i.peripheral_clock_gate_ctrl = 32'hFFFF_FFFF;
    $display("[FLOO_TB] RTL_SIM: forced peripheral_clock_gate_ctrl=all1 (UART/APB clocks)");
end

// Pinpoint CPU vs AXI vs APB for uart_set_cfg() stall @ CGREG (0x1A107004).
initial $display("[UART_DBG] monitor enabled (RTL_SIM)");

logic        uart_dbg_ar_pending;
logic [31:0] uart_dbg_ar_addr;
integer      uart_dbg_apb_soc_ctrl_hits;

function automatic bit uart_dbg_is_periph_addr(input logic [31:0] addr);
    return (addr >= 32'h1A10_0000) && (addr < 32'h1A50_0000);
endfunction

initial uart_dbg_apb_soc_ctrl_hits = 0;

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

always_ff @(posedge floo_tb_clk) begin
    if (fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.psel &&
        fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.penable &&
        uart_dbg_apb_soc_ctrl_hits < 8) begin
        uart_dbg_apb_soc_ctrl_hits++;
        $display("[UART_DBG] APB soc_ctrl access paddr=0x%03x pwrite=%b prdata=0x%08x @ %0t",
                 fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.paddr[11:0],
                 fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.pwrite,
                 fpgnix.vqm_msystem_wrap.msystem.peripherals_i.s_soc_ctrl_bus.prdata,
                 $time);
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
        $display("[UART_DBG] STALL: core issued AXI to periph but APB soc_ctrl never selected — check axi_node decode / axi2apb");
    else if (uart_dbg_apb_soc_ctrl_hits > 0 && uart_dbg_ar_pending)
        $display("[UART_DBG] STALL: APB saw soc_ctrl but AXI R not returned — check axi2apb read path");
end
`endif

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

initial begin
    floo_stim_start_delay = 500;
    floo_stim_max_cycles  = 50000;
    void'($value$plusargs("FLOO_STIM_DELAY=%d", floo_stim_start_delay));
    void'($value$plusargs("FLOO_STIM_MAX_CYCLES=%d", floo_stim_max_cycles));
end

always_ff @(posedge floo_tb_clk or negedge floo_rstn) begin : floo_axi_stim
    if (!floo_rstn) begin
        floo_stim_state  <= FLOO_ST_IDLE;
        floo_stim_cycles <= 0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid  <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_valid  <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid   <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready   <= 1'b0;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].r_ready   <= 1'b0;
    end else begin
        case (floo_stim_state)
            FLOO_ST_IDLE: begin
                fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid  <= 1'b0;
                fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready  <= 1'b0;
                if (floo_stim_cycles == floo_stim_start_delay) begin
                    $display("[FLOO_STIM] driving AXI write on masters[4] (rstn_sys=1)");
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_addr   <= 32'h0000_0000;
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
                    $display("[FLOO_STIM] aw_ready @ time %0t", $time);
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid <= 1'b0;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid  <= 1'b1;
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_data   <= 32'hF100_F100;
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
                    $display("[FLOO_STIM] w_ready @ time %0t", $time);
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
                    $display("[FLOO_STIM] write response @ time %0t", $time);
                    fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready <= 1'b0;
                    floo_stim_state <= FLOO_ST_DONE;
                end else if (floo_stim_cycles >= floo_stim_max_cycles) begin
                    $display("[FLOO_STIM] TIMEOUT waiting for b_valid");
                    floo_stim_state <= FLOO_ST_DONE;
                end else
                    floo_stim_cycles <= floo_stim_cycles + 1;
            end

            default: ; // FLOO_ST_DONE — hold
        endcase
    end
end

integer floo_flit_count;
reg     floo_mon_reported;
initial begin
    floo_flit_count = 0;
    floo_mon_reported = 1'b0;
end

task floo_mon_report;
    begin
        if (!floo_mon_reported) begin
            floo_mon_reported = 1'b1;
            $display("[FLOO_MON] SUMMARY: cumulative flits=%0d", floo_flit_count);
            if (floo_flit_count == 0)
                $display("[FLOO_MON] FAIL: zero flits on msystem.chimney_floo_req_o");
            else begin
                $display("[FLOO_MON] PASS: non-zero flit activity through FlooNoC chimney");
                $display("[FLOO_TB] UART check: grep -E \"Hey|FINISH\" helloworld/xrun.log after sim ends");
            end
        end
    end
endtask

// Stage-1 loops chimney flits internally; north port (fpgnix.floo_req_o) may stay quiet.
floo_req_t floo_chimney_req_mon;
assign floo_chimney_req_mon = fpgnix.vqm_msystem_wrap.msystem.chimney_floo_req_o;

always @(posedge floo_tb_clk) begin
    if (floo_rstn && floo_chimney_req_mon.valid) begin
        floo_flit_count <= floo_flit_count + 1;
        $display("[FLOO_MON] time=%0t chimney_floo_req_o.valid flit_count=%0d",
                 $time, floo_flit_count + 1);
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

endmodule
