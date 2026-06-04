
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
assign floo_tb_clk = fpgnix.vqm_msystem_wrap.msystem.clk_sys;

reg [FlooReqBits-1:0] floo_req_i_lb;
reg [FlooRspBits-1:0] floo_rsp_i_lb;

always @(posedge floo_tb_clk or negedge rst_n) begin
    if (!rst_n) begin
        floo_req_i_lb <= '0;
        floo_rsp_i_lb <= '0;
    end else begin
        floo_req_i_lb <= fpgnix.floo_req_o;
        floo_rsp_i_lb <= fpgnix.floo_rsp_o;
    end
end

assign fpgnix.floo_req_i = floo_req_i_lb;
assign fpgnix.floo_rsp_i = floo_rsp_i_lb;

// Stage-1: axi_node port 4 is stubbed; drive one AXI write on masters[4] into the chimney.
initial begin : floo_axi_stim
    integer timeout;
    wait (rst_n === 1'b1);
    repeat (500) @(posedge floo_tb_clk);
    $display("[FLOO_STIM] driving AXI write on masters[4]");

    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid  <= 1'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].ar_valid  <= 1'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid   <= 1'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready   <= 1'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].r_ready   <= 1'b0;

    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid  <= 1'b1;
    // XY decode uses addr[16]=x, addr[20]=y; tile is (0,0) — use local address so flits eject to chimney
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_addr   <= 32'h0000_0000;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_id     <= 2'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_len    <= 8'h0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_size  <= 3'b010;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_burst <= 2'b01;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_lock   <= 1'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_cache  <= 4'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_prot   <= 3'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_qos    <= 4'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_region <= 4'b0;
    fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_user   <= 1'b0;

    timeout = 0;
    do begin
        @(posedge floo_tb_clk);
        timeout = timeout + 1;
    end while (!fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_ready && timeout < 50000);
    if (timeout >= 50000)
        $display("[FLOO_STIM] TIMEOUT waiting for aw_ready");
    else begin
        $display("[FLOO_STIM] aw_ready @ time %0t", $time);
        fpgnix.vqm_msystem_wrap.msystem.masters[4].aw_valid <= 1'b0;

        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid  <= 1'b1;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_data  <= 32'hF100_F100;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_strb   <= 4'hF;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_last   <= 1'b1;
        fpgnix.vqm_msystem_wrap.msystem.masters[4].w_user   <= 1'b0;
        timeout = 0;
        do begin
            @(posedge floo_tb_clk);
            timeout = timeout + 1;
        end while (!fpgnix.vqm_msystem_wrap.msystem.masters[4].w_ready && timeout < 50000);
        if (timeout >= 50000)
            $display("[FLOO_STIM] TIMEOUT waiting for w_ready");
        else begin
            $display("[FLOO_STIM] w_ready @ time %0t", $time);
            fpgnix.vqm_msystem_wrap.msystem.masters[4].w_valid <= 1'b0;
            fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready <= 1'b1;
            timeout = 0;
            do begin
                @(posedge floo_tb_clk);
                timeout = timeout + 1;
            end while (!fpgnix.vqm_msystem_wrap.msystem.masters[4].b_valid && timeout < 500000);
            if (timeout >= 500000)
                $display("[FLOO_STIM] TIMEOUT waiting for b_valid");
            else
                $display("[FLOO_STIM] write response @ time %0t", $time);
            fpgnix.vqm_msystem_wrap.msystem.masters[4].b_ready <= 1'b0;
        end
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
                $display("[FLOO_MON] FAIL: zero flits observed on u_hamsa_chimney.flit_req_out_o");
            else
                $display("[FLOO_MON] PASS: non-zero flit activity through FlooNoC chimney");
        end
    end
endtask

always @(posedge floo_tb_clk) begin
    if (fpgnix.vqm_msystem_wrap.msystem.u_hamsa_chimney.flit_req_out_o.valid) begin
        floo_flit_count <= floo_flit_count + 1;
        $display("[FLOO_MON] time=%0t chimney floo_req_o.valid flit_count=%0d",
                 $time, floo_flit_count + 1);
    end
end

// XRUN often skips `final` when the testbench calls $finish; schedule an explicit report too.
initial begin : floo_mon_watchdog
    integer delay_ns;
    delay_ns = 500_000_000; // 500 ms — allow TB AXI stim + core UART (override: +FLOO_MON_DELAY=<ns>)
    void'($value$plusargs("FLOO_MON_DELAY=%d", delay_ns));
    #(delay_ns);
    floo_mon_report();
end

// XRUN: final blocks cannot call tasks (BADTFB); initial watchdog above is sufficient

endmodule
