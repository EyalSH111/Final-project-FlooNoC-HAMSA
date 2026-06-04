// empty edram implementation for fpga
module edram_ss(/*autoarg*/
   // Outputs
   rready, rdata, wready, apb_PRDATA, apb_PREADY, apb_PSLVERR,
   edram_ss_rd_wr_irq_clear_p,
   // Inputs
   clk, rst_n, rvalid, raddr, wvalid, waddr, wdata, wbe, apb_PADDR,
   apb_PENABLE, apb_PSEL, apb_PSTRB, apb_PWDATA, apb_PWRITE,
   dft_clk_en, edram_ss_rd_wr_irq_out, edram_ss_rd_wr_irq_out_unmsk,
   scan_enable, scan_mode
   );
//edram params
localparam EDRAM_WIDTH=64;
localparam EDRAM_DEPTH=4096;
localparam EDRAM_DEPTH_W=$clog2(EDRAM_DEPTH);
//array params
parameter ARR_INST_DEPTH = 1; // <--- parameter
localparam ARR_INST_WIDTH = 2;
localparam ARR_WIDTH=EDRAM_WIDTH*ARR_INST_WIDTH;
localparam ARR_DEPTH=EDRAM_DEPTH*ARR_INST_DEPTH;
localparam ARR_DEPTH_W=$clog2(ARR_DEPTH);
//bist
parameter HAS_BIST = 0; // <-- parameter

//rf params
localparam ADD_DW=8;

//apb params
localparam APB_ADDR_W = 12;
localparam APB_DATA_W = 32;


//general
input clk;
input rst_n;


//mem i/f
input                    rvalid;
input [ARR_DEPTH_W-1:0]  raddr; 
output                   rready;
output [ARR_WIDTH-1:0]   rdata; 
input                    wvalid;
input [ARR_DEPTH_W-1:0]  waddr; 
input [ARR_WIDTH-1:0]    wdata; 
input [ARR_WIDTH/8-1:0]  wbe;   
output                   wready;

//apb i/f
input [APB_ADDR_W-1:0]   apb_PADDR;  
input                    apb_PENABLE;
input                    apb_PSEL;   
input [APB_DATA_W/8-1:0] apb_PSTRB;  
input [APB_DATA_W-1:0]   apb_PWDATA; 
input                    apb_PWRITE; 
output [APB_DATA_W-1:0]  apb_PRDATA; 
output                   apb_PREADY; 
output                   apb_PSLVERR;

//rf shit
input                   dft_clk_en;
input [1:0]             edram_ss_rd_wr_irq_out;
input [1:0]             edram_ss_rd_wr_irq_out_unmsk;
input                   scan_enable;
input                   scan_mode;
output [1:0]            edram_ss_rd_wr_irq_clear_p;

assign rready=1;
assign rdata=0; 
assign wready=1;
assign apb_PRDATA=0; 
assign apb_PREADY=1; 
assign apb_PSLVERR=0;
assign edram_ss_rd_wr_irq_clear_p=0;
endmodule
// Local Variables:
// verilog-library-directories:("." "$PULP_ENV/src/ips/edram_bist/rtl")
// verilog-auto-inst-param-value:t
// End:
