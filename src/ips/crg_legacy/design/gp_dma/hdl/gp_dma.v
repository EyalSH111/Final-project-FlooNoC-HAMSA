`timescale 1ns / 100 ps

module gp_dma (
  // Test Interface
  scan_in,
  scan_out,
  scan_enable,
  scan_mode,
  // CBUS Slave Interface
  clk,
  rst_n,
  big_endian,
  // CBUS Slave Interface
  gpdmas_address,
  gpdmas_wdata,
  gpdmas_byten,
  gpdmas_cmd,
  gpdmas_req,
  gpdmas_rdata,
  gpdmas_rdatap,
  gpdmas_waccept,
  gpdmas_rresp,
  gpdmas_aerror,
  // CBUS Master Interface
  gpdmam_address,
  gpdmam_align, 
  gpdmam_wdata,
  gpdmam_xcnt,
  gpdmam_byten,
  gpdmam_bytecnt,
  gpdmam_cmd,
  gpdmam_first,
  gpdmam_last,
  gpdmam_req,
  gpdmam_rdatap,
  gpdmam_waccept,
  gpdmam_rresp,
  gpdmam_amode,
  gpdmam_clsize,
  gpdmam_epriority,
  // Interrupt Out
  gpdma_done_intr
);

input  [31:0] scan_in;
output [31:0] scan_out;
input         scan_enable;
input         scan_mode;
   
input         clk;
input         rst_n;
input         big_endian;
   
input   [5:0] gpdmas_address;
input  [31:0] gpdmas_wdata;
input   [3:0] gpdmas_byten;
input         gpdmas_cmd;
input          gpdmas_req;
output [31:0] gpdmas_rdata;
output [31:0] gpdmas_rdatap;
output        gpdmas_waccept;
output        gpdmas_rresp;
output        gpdmas_aerror;

output [31:0] gpdmam_address;
output  [4:0] gpdmam_align;
output [31:0] gpdmam_wdata;
output  [2:0] gpdmam_xcnt;
output [3:0]  gpdmam_byten;
output [9:0]  gpdmam_bytecnt;
output        gpdmam_cmd;
output        gpdmam_first;
output        gpdmam_last;
output        gpdmam_req;
input  [31:0] gpdmam_rdatap;
input          gpdmam_waccept;
input          gpdmam_rresp;
output  [1:0] gpdmam_amode; 
output  [1:0] gpdmam_clsize; 
output  [2:0] gpdmam_epriority; 

output  [3:0] gpdma_done_intr;

parameter AM_INCR   = 2'd0,
          AM_DECR   = 2'd1,
          AM_FIXED  = 2'd2,
          AM_CLWRAP = 2'd3;  

parameter BM_SINGLE = 2'd0,
          BM_DUAL   = 2'd1,
          BM_QUAD   = 2'd2;

parameter  DMA_IDLE   = 5'b000_1_0,
            DMA_READ4   = 5'b100_1_1,
            DMA_READ3   = 5'b011_1_1,
            DMA_READ2   = 5'b010_1_1,
            DMA_READ1   = 5'b001_1_1,
           DMA_WAIT   = 5'b000_0_0,
            DMA_WRITE4 = 5'b100_0_1,
            DMA_WRITE3 = 5'b011_0_1,
            DMA_WRITE2 = 5'b010_0_1,
            DMA_WRITE1 = 5'b001_0_1;

reg   [4:0] state;
reg   [4:0] n_state;

wire        write_xfer              = gpdmam_req && !gpdmam_cmd && gpdmam_waccept;
wire        read_xfer               = gpdmam_req && gpdmam_cmd && gpdmam_rresp;
reg         d1_read_xfer;
wire [31:0] fifo_rd_data;
wire [31:0] fifo_wr_data             = gpdmam_rdatap;
reg   [2:0] pri;

wire        gpdmam_req         = state[0];
wire        gpdmam_cmd         = state[1];
reg  [31:0] gpdmam_address;
reg   [2:0] gpdmam_xcnt;
reg   [9:0] gpdmam_bytecnt;
reg   [3:0] gpdmam_byten;
reg          gpdmam_first;
reg         gpdmam_last;
wire  [4:0] gpdmam_align = gpdmam_address[4:0];
reg   [1:0] gpdmam_amode;
wire  [1:0] gpdmam_clsize      = 2'd0;
wire [31:0] gpdmam_wdata       = fifo_rd_data;
wire  [2:0] gpdmam_epriority   = pri;

reg  [31:0] gpdmas_rdata;
reg  [31:0] gpdmas_rdatap;
wire        gpdmas_waccept         = 1'b1;
wire        gpdmas_rresp         = 1'b1;
reg          gpdmas_aerror;
   
wire [31:0] write_data;
   
reg  [31:0] source_address;
reg  [31:0] dest_address;
reg  [17:0] byte_count;
wire [17:0] byte_count_m1      = byte_count - gpdmam_xcnt;
reg   [9:0] burst_size;
wire         any_dma_pending;
   
reg          dma_done;
reg         cycle_start;
reg         cycle_done;
reg   [1:0] source_amode;
reg   [1:0] dest_amode;
reg   [1:0] burst_mode;

wire        inc_source_address = read_xfer && (source_amode == AM_INCR);
wire         inc_dest_address   = write_xfer && (dest_amode == AM_INCR);
wire        dec_byte_count     = write_xfer;

wire        active             = (state != DMA_IDLE);

reg         load_source_address;
reg         load_dest_address;

wire [31:0] address_p4 = gpdmam_address + gpdmam_xcnt;
wire [9:0]  n_bytecnt = gpdmam_bytecnt - gpdmam_xcnt;

wire [3:0]  src_bc_byten     = {(burst_size > 10'd3), (burst_size > 10'd2),
                                (burst_size > 10'd1), 1'b1};
wire [3:0]  src_preend_byten = src_bc_byten << source_address[1:0];
wire [3:0]  src_bigend_byten = {src_preend_byten[0], src_preend_byten[1],
                                src_preend_byten[2], src_preend_byten[3]};
wire [3:0]  source_byten     = (big_endian ? src_bigend_byten : src_preend_byten);
wire [3:0]  dest_bc_byten    = {(burst_size > 10'd3), (burst_size > 10'd2),
                                (burst_size > 10'd1), 1'b1};
wire [3:0]  dst_preend_byten = dest_bc_byten << dest_address[1:0];
wire [3:0]  dst_bigend_byten = {dst_preend_byten[0], dst_preend_byten[1],
                                dst_preend_byten[2], dst_preend_byten[3]};
wire [3:0]  dest_byten       = (big_endian ? dst_bigend_byten : dst_preend_byten);

wire [3:0]  preend_byten = {(n_bytecnt > 10'd3), (n_bytecnt > 10'd2),
                            (n_bytecnt > 10'd1), 1'b1};
wire [3:0]  bigend_byten   = {preend_byten[0], preend_byten[1],
                              preend_byten[2], preend_byten[3]};
wire [3:0]  n_byten        = (big_endian ? bigend_byten : preend_byten);
//==================================================================
// Register Master CBUS Outputs
//==================================================================
always @ (posedge clk)
begin
  if (!rst_n)
    begin
      gpdmam_address <= 32'h00000000;
      gpdmam_bytecnt <= 10'd0;
      gpdmam_xcnt    <= 3'd0;
      gpdmam_byten   <= 4'd0;
      gpdmam_amode   <= AM_INCR;
      gpdmam_first   <= 1'b0;
      gpdmam_last    <= 1'b0;
    end
  else if (load_source_address)
    begin
      gpdmam_address <= source_address;
      gpdmam_bytecnt <= burst_size;
      gpdmam_xcnt    <= (burst_size < (10'd4 - source_address[1:0])) ?
                                 burst_size[2:0] : (3'd4 - source_address[1:0]);
      gpdmam_byten   <= source_byten;
      gpdmam_amode   <= source_amode;
      gpdmam_first   <= 1'b1;
      gpdmam_last    <= (burst_size <= (10'd4 - source_address[1:0]));
    end
  else if (load_dest_address)
    begin
      gpdmam_address <= dest_address;
      gpdmam_bytecnt <= burst_size;
      gpdmam_xcnt    <= (burst_size < (10'd4 - dest_address[1:0])) ?
                                 burst_size[2:0] : (3'd4 - dest_address[1:0]);
      gpdmam_byten   <= dest_byten;
      gpdmam_amode   <= dest_amode;
      gpdmam_first   <= 1'b1;
      gpdmam_last    <= (burst_size <= (10'd4 - dest_address[1:0]));
    end
  else if (read_xfer || write_xfer)
    begin
      gpdmam_address <= ((inc_source_address || inc_dest_address) ? address_p4 : gpdmam_address);
      gpdmam_bytecnt <= n_bytecnt;
      gpdmam_xcnt    <= ((n_bytecnt > 10'd4) ? 3'd4 : n_bytecnt[2:0]);
      gpdmam_byten   <= n_byten;
      gpdmam_first   <= 1'b0;
      gpdmam_last    <= (n_bytecnt <= 10'd4);
    end
end

//==================================================================
// Register State Variable
//==================================================================
always @ (posedge clk)
begin
  if (!rst_n)
    begin
      state <= DMA_IDLE;
      d1_read_xfer <= 1'b0;
    end
  else
    begin
      state <= n_state;
      d1_read_xfer <= read_xfer;
    end
end
   
//==================================================================
// State Steering Logic
//==================================================================
always @ (state or byte_count or any_dma_pending or 
          gpdmam_last or gpdmam_rresp or
          gpdmam_waccept or gpdmam_xcnt)
begin
  n_state = state;
  load_source_address = 1'b0;
  load_dest_address = 1'b0;
  cycle_start = 1'b0;
  cycle_done = 1'b0;
  dma_done = 1'b0;
  case (state)
    DMA_IDLE:
      begin
        if (any_dma_pending) 
          begin   
            load_source_address = 1'b1;
            cycle_start = 1'b1;
            n_state = DMA_READ1;
          end
      end
    DMA_READ1:
        if (gpdmam_last && gpdmam_rresp)
          n_state = DMA_WAIT;
    DMA_WAIT:
      begin
        load_dest_address = 1'b1;
        n_state = DMA_WRITE1;
      end
    DMA_WRITE1:
      begin
        if (gpdmam_last && gpdmam_waccept)
          begin
            cycle_done = 1'b1;
            n_state = DMA_IDLE;
            if (byte_count == {15'd0, gpdmam_xcnt})
              dma_done = 1'b1;
          end
      end
    default: ; // For verilint happiness
  endcase
end


//==================================================================
// CBUS Read Data and Ready Multiplexing Logic
//==================================================================
wire  [1:0] gpdmas_select = gpdmas_address[5:4];

reg         gpdmas_req0;
reg         gpdmas_req1;
reg         gpdmas_req2;
reg         gpdmas_req3;

wire [31:0] gpdmas_rdata0;
wire        gpdmas_aerror0;
wire [31:0] gpdmas_rdata1;
wire        gpdmas_aerror1;
wire [31:0] gpdmas_rdata2;
wire        gpdmas_aerror2;
wire [31:0] gpdmas_rdata3;
wire        gpdmas_aerror3;

always @ (gpdmas_select or gpdmas_req or 
          gpdmas_rdata0 or gpdmas_aerror0 or
          gpdmas_rdata1 or gpdmas_aerror1 or
          gpdmas_rdata2 or gpdmas_aerror2 or
          gpdmas_rdata3 or gpdmas_aerror3)
begin
  gpdmas_req0 = 1'b0;
  gpdmas_req1 = 1'b0;
  gpdmas_req2 = 1'b0;
  gpdmas_req3 = 1'b0;
  case (gpdmas_select)
    2'd0:
      begin
        gpdmas_rdata  = gpdmas_rdata0;
        gpdmas_aerror = gpdmas_aerror0;
        gpdmas_req0   = gpdmas_req;
      end
    2'd1:
      begin
        gpdmas_rdata  = gpdmas_rdata1;
        gpdmas_aerror = gpdmas_aerror1;
        gpdmas_req1   = gpdmas_req;
      end
    2'd2:
      begin
        gpdmas_rdata  = gpdmas_rdata2;
        gpdmas_aerror = gpdmas_aerror2;
        gpdmas_req2   = gpdmas_req;
      end
    2'd3:
      begin
        gpdmas_rdata  = gpdmas_rdata3;
        gpdmas_aerror = gpdmas_aerror3;
        gpdmas_req3   = gpdmas_req;
      end
  endcase
end

//==================================================================
// Register Slave Read Data Outputs
//==================================================================
always @ (posedge clk)
begin
  if (!rst_n)
    gpdmas_rdatap <= 32'd0;
  else
    gpdmas_rdatap <= gpdmas_rdata;
end

//==================================================================
// DMA Channel Arbitration and Control Multiplexing Logic
//==================================================================
wire  [1:0] owner;
wire  [3:0] owner_oh;

wire  [3:0] int_dma_done           = (dma_done)           ? owner_oh : 4'd0;
wire  [3:0] int_inc_source_address = (inc_source_address) ? owner_oh : 4'd0;
wire  [3:0] int_inc_dest_address   = (inc_dest_address)   ? owner_oh : 4'd0;
wire  [3:0] int_dec_byte_count     = (dec_byte_count)     ? owner_oh : 4'd0;
wire  [3:0] int_active             = (active)             ? owner_oh : 4'd0;

wire   [3:0] dma_pending;

wire  [31:0] source_address0;
wire   [1:0] source_amode0;
wire  [31:0] dest_address0;
wire   [1:0] dest_amode0;
wire   [1:0] burst_mode0;
wire   [2:0] priority0;
wire  [17:0] byte_count0;

wire  [31:0] source_address1;
wire   [1:0] source_amode1;
wire  [31:0] dest_address1;
wire   [1:0] dest_amode1;
wire   [1:0] burst_mode1;
wire   [2:0] priority1;
wire  [17:0] byte_count1;

wire  [31:0] source_address2;
wire   [1:0] source_amode2;
wire  [31:0] dest_address2;
wire   [1:0] dest_amode2;
wire   [1:0] burst_mode2;
wire   [2:0] priority2;
wire  [17:0] byte_count2;

wire  [31:0] source_address3;
wire   [1:0] source_amode3;
wire  [31:0] dest_address3;
wire   [1:0] dest_amode3;
wire   [1:0] burst_mode3;
wire   [2:0] priority3;
wire  [17:0] byte_count3;

assign any_dma_pending = |(dma_pending & owner_oh);

always @ (owner or 
          source_address0 or source_amode0 or dest_address0 or dest_amode0 or burst_mode0 or byte_count0 or priority0 or
          source_address1 or source_amode1 or dest_address1 or dest_amode1 or burst_mode1 or byte_count1 or priority1 or
          source_address2 or source_amode2 or dest_address2 or dest_amode2 or burst_mode2 or byte_count2 or priority2 or
          source_address3 or source_amode3 or dest_address3 or dest_amode3 or burst_mode3 or byte_count3 or priority3)
begin
  case (owner)
    2'd0:
      begin
        source_address  = source_address0;
        source_amode    = source_amode0;
        dest_address    = dest_address0;
        dest_amode      = dest_amode0;
        burst_mode      = burst_mode0;
        byte_count      = byte_count0;
        pri             = priority0;
      end
    2'd1:
      begin
        source_address  = source_address1;
        source_amode    = source_amode1;
        dest_address    = dest_address1;
        dest_amode      = dest_amode1;
        burst_mode      = burst_mode1;
        byte_count      = byte_count1;
        pri             = priority1;
      end
    2'd2:
      begin
        source_address  = source_address2;
        source_amode    = source_amode2;
        dest_address    = dest_address2;
        dest_amode      = dest_amode2;
        burst_mode      = burst_mode2;
        byte_count      = byte_count2;
        pri             = priority2;
      end
    2'd3:
      begin
        source_address  = source_address3;
        source_amode    = source_amode3;
        dest_address    = dest_address3;
        dest_amode      = dest_amode3;
        burst_mode      = burst_mode3;
        byte_count      = byte_count3;
        pri             = priority3;
      end
   endcase
end
always @ (burst_mode or byte_count)
begin
  case(burst_mode)
    BM_SINGLE :
      burst_size = ((byte_count > 18'd4) ? 10'd4 : byte_count[9:0]);
    BM_DUAL :
      burst_size = ((byte_count > 18'd8) ? 10'd8 : byte_count[9:0]);
    default :
      burst_size = ((byte_count > 18'd16) ? 10'd16 : byte_count[9:0]);
  endcase
end

gp_dma_arb I_arb (
  .cbus_clk(clk),
  .cbus_rst_n(rst_n),
  .cycle_start(cycle_start),
  .dma_pending(dma_pending),
  .priority0(priority0),
  .priority1(priority1),
  .priority2(priority2),
  .priority3(priority3),
  .owner(owner),
  .owner_oh(owner_oh),
  .active(active)
);

gp_dma_regs I_regs0 (
  .cbus_clk(clk),
  .cbus_rst_n(rst_n),
  .slave_cbus_address(gpdmas_address[3:0]),
  .slave_cbus_wdata(gpdmas_wdata),
  .slave_cbus_byten(gpdmas_byten),
  .slave_cbus_cmd(gpdmas_cmd),
  .slave_cbus_req(gpdmas_req0),
  .slave_cbus_rdata(gpdmas_rdata0),
  .slave_cbus_aerror(gpdmas_aerror0),
  .active(int_active[0]),
  .dma_done(int_dma_done[0]),
  .inc_source_address(int_inc_source_address[0]),
  .inc_dest_address(int_inc_dest_address[0]),
  .dec_byte_count(int_dec_byte_count[0]),
  .address_p4(address_p4),
  .byte_count_m1(byte_count_m1),
  .source_address(source_address0),
  .source_amode(source_amode0),
  .dest_address(dest_address0),
  .dest_amode(dest_amode0),
  .burst_mode(burst_mode0),
  .pri(priority0),
  .byte_count(byte_count0),
  .dma_pending(dma_pending[0]),
  .done_intr(gpdma_done_intr[0])
);

gp_dma_regs I_regs1 (
  .cbus_clk(clk),
  .cbus_rst_n(rst_n),
  .slave_cbus_address(gpdmas_address[3:0]),
  .slave_cbus_wdata(gpdmas_wdata),
  .slave_cbus_byten(gpdmas_byten),
  .slave_cbus_cmd(gpdmas_cmd),
  .slave_cbus_req(gpdmas_req1),
  .slave_cbus_rdata(gpdmas_rdata1),
  .slave_cbus_aerror(gpdmas_aerror1),
  .active(int_active[1]),
  .dma_done(int_dma_done[1]),
  .inc_source_address(int_inc_source_address[1]),
  .inc_dest_address(int_inc_dest_address[1]),
  .dec_byte_count(int_dec_byte_count[1]),
  .address_p4(address_p4),
  .byte_count_m1(byte_count_m1),
  .source_address(source_address1),
  .source_amode(source_amode1),
  .dest_address(dest_address1),
  .dest_amode(dest_amode1),
  .burst_mode(burst_mode1),
  .pri(priority1),
  .byte_count(byte_count1),
  .dma_pending(dma_pending[1]),
  .done_intr(gpdma_done_intr[1])
);

gp_dma_regs I_regs2 (
  .cbus_clk(clk),
  .cbus_rst_n(rst_n),
  .slave_cbus_address(gpdmas_address[3:0]),
  .slave_cbus_wdata(gpdmas_wdata),
  .slave_cbus_byten(gpdmas_byten),
  .slave_cbus_cmd(gpdmas_cmd),
  .slave_cbus_req(gpdmas_req2),
  .slave_cbus_rdata(gpdmas_rdata2),
  .slave_cbus_aerror(gpdmas_aerror2),
  .active(int_active[2]),
  .dma_done(int_dma_done[2]),
  .inc_source_address(int_inc_source_address[2]),
  .inc_dest_address(int_inc_dest_address[2]),
  .dec_byte_count(int_dec_byte_count[2]),
  .address_p4(address_p4),
  .byte_count_m1(byte_count_m1),
  .source_address(source_address2),
  .source_amode(source_amode2),
  .dest_address(dest_address2),
  .dest_amode(dest_amode2),
  .burst_mode(burst_mode2),
  .pri(priority2),
  .byte_count(byte_count2),
  .dma_pending(dma_pending[2]),
  .done_intr(gpdma_done_intr[2])
);

gp_dma_regs I_regs3 (
  .cbus_clk(clk),
  .cbus_rst_n(rst_n),
  .slave_cbus_address(gpdmas_address[3:0]),
  .slave_cbus_wdata(gpdmas_wdata),
  .slave_cbus_byten(gpdmas_byten),
  .slave_cbus_cmd(gpdmas_cmd),
  .slave_cbus_req(gpdmas_req3),
  .slave_cbus_rdata(gpdmas_rdata3),
  .slave_cbus_aerror(gpdmas_aerror3),
  .active(int_active[3]),
  .dma_done(int_dma_done[3]),
  .inc_source_address(int_inc_source_address[3]),
  .inc_dest_address(int_inc_dest_address[3]),
  .dec_byte_count(int_dec_byte_count[3]),
  .address_p4(address_p4),
  .byte_count_m1(byte_count_m1),
  .source_address(source_address3),
  .source_amode(source_amode3),
  .dest_address(dest_address3),
  .dest_amode(dest_amode3),
  .burst_mode(burst_mode3),
  .pri(priority3),
  .byte_count(byte_count3),
  .dma_pending(dma_pending[3]),
  .done_intr(gpdma_done_intr[3])
);

wire        fifo_empty;
wire        fifo_full;
wire        fifo_almost_full;
wire  [4:0] fifo_occ;

reg   [1:0] d1_gpdmam_baddress;
reg   [2:0] d1_gpdmam_xcnt;

always @ (posedge clk)
begin
  if (!rst_n)
    begin
      d1_gpdmam_baddress <= 2'd0;
      d1_gpdmam_xcnt <= 3'd0;
    end
  else if (gpdmam_req)
    begin
      d1_gpdmam_baddress <= gpdmam_address[1:0];
      d1_gpdmam_xcnt <= gpdmam_xcnt;
    end
end

gp_dma_fifo I_fifo (
  .clk(clk),
  .rst_n(rst_n),
  .big_endian(big_endian),
  .flush(cycle_start),
  .rd_en(write_xfer),
  .wr_en(d1_read_xfer),
  .rd_data(fifo_rd_data),
  .wr_data(fifo_wr_data),
  .rd_baddress(gpdmam_address[1:0]),
  .wr_baddress(d1_gpdmam_baddress),
  .rd_xcnt(gpdmam_xcnt),
  .wr_xcnt(d1_gpdmam_xcnt),
  .empty(fifo_empty),
  .full(fifo_full),
  .almost_full(fifo_almost_full),
  .occ(fifo_occ)
);

endmodule
