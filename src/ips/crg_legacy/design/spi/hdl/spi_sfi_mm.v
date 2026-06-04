module spi_sfi_mm
  (
    clk,
    rst_n,

    // Config port request
    cfg_req,
    // Memory port requests
    mm_req0,
    mm_req1,
    mm_req2,
    mm_req3,

    // Shared VBUSP slave port
    address,
    first,
    last,
    bytecnt,
    byten,
    cmd,
    wdata,
    waccept,
    rdatap,
    rresp,
    amode,
    clsize,
    rstatus,
    xid,
    mstid,
    done,

    // VBUS write status interface
    sreq,
    sstatus,
    sready,
    sdone,
    sid,
    smstid,

    // Endian Control
    big_endian,

    // SPI Core VBUSP Interface
    spi_cfg_req,
    spi_cfg_address,
    spi_cfg_cmd,
    spi_cfg_byten,
    spi_cfg_wdata,
    spi_cfg_rdatap,
    spi_cfg_rdata,
    spi_cfg_rresp,
    spi_cfg_waccept,
    
    // Signal indicating the SPI divide clock is on
    spi_clk_en,

    // MM CS mode
    mmspi_req_mode_ival,
    mmspi_req_mode,
   
    // Test
    test_mode
  );

	parameter AW = 10;     		// 2^10 bytes = 1KB space
	localparam AWW = AW - 2;	// Address width in words of 4 bytes
	
// SPI core address localparams
localparam SPIPID       = {{(AWW-4){1'b0}},4'b0000};
localparam SPICC        = {{(AWW-4){1'b0}},4'b0001};
localparam SPIDC        = {{(AWW-4){1'b0}},4'b0010};
localparam SPICR        = {{(AWW-4){1'b0}},4'b0011};
localparam SPISR        = {{(AWW-4){1'b0}},4'b0100};
localparam SPIDR        = {{(AWW-4){1'b0}},4'b0101};
// MM SPI address localparams (additions to core)
localparam MMSPI_SETUP0 = {{(AWW-4){1'b0}},4'b0110};
localparam MMSPI_SETUP1 = {{(AWW-4){1'b0}},4'b0111};
localparam MMSPI_SETUP2 = {{(AWW-4){1'b0}},4'b1000};
localparam MMSPI_SETUP3 = {{(AWW-4){1'b0}},4'b1001};
localparam MMSPI_SW     = {{(AWW-4){1'b0}},4'b1010};
localparam MMSPI_CS_MOD = {{(AWW-4){1'b0}},4'b1011};

// MM SPI State Machine States
localparam STATE_IDLE         = 4'd0;
localparam STATE_COMMAND_INIT = 4'd1;
localparam STATE_COMMAND      = 4'd2;
localparam STATE_ADDRESS_INIT = 4'd3;
localparam STATE_ADDRESS      = 4'd4;
localparam STATE_DUMMY_INIT   = 4'd5;
localparam STATE_DUMMY        = 4'd6;
localparam STATE_DATA_INIT    = 4'd7;
localparam STATE_DATA         = 4'd8;
localparam STATE_ABORT_INIT   = 4'd9;
localparam STATE_ABORT        = 4'd10;
localparam STATE_END          = 4'd11;

// XFER State Machine States
localparam STATE_XFER_IDLE    = 3'd0;
localparam STATE_XFER_CR      = 3'd1;
localparam STATE_XFER_INT_CLR = 3'd2;
localparam STATE_XFER_WAIT    = 3'd3;
localparam STATE_XFER_RD      = 3'd4;

// Smart power on defaults for Serial Flash operations
localparam DEFAULT_READ_COMMAND   = 8'd3;
localparam DEFAULT_WRITE_COMMAND  = 8'd2;
localparam DEFAULT_NUM_ADDR_BYTES = 2'd2;
localparam DEFAULT_DUMMY_BYTES    = 2'd0;
localparam DEFAULT_DUAL_READ      = 1'b0;

parameter  SPI_IS_BOOT = 0;

localparam DEFAULT_MMSPI_CONTROL = (SPI_IS_BOOT == 1) ? 1'b1 : 1'b0;

//generate
//   if (SPI_IS_BOOT == 1) begin
//      localparam DEFAULT_MMSPI_CONTROL = 1'b1;
//   end else begin
//      localparam DEFAULT_MMSPI_CONTROL = 1'b0;
//   end
//endgenerate

// Address mode localparams
localparam LINEAR_INCREMENT = 2'd0;
localparam CACHE_LINE_WRAP  = 2'd3;

localparam BAD_ADDRESS_MODE_STATUS  = 3'd5;
localparam GOOD_ADDRESS_MODE_STATUS = 3'd0;	
  
input         clk;
input         rst_n;
// Config port request
input         cfg_req;
// Memory port requests
input         mm_req0;
input         mm_req1;
input         mm_req2;
input         mm_req3;
input [1:0]   mmspi_req_mode_ival;
output [1:0]  mmspi_req_mode;

// Shared VBUSP slave port
input  [31:0] address;
input         first;
input         last;
input  [9:0]  bytecnt;
input  [3:0]  byten;
input         cmd;
input  [31:0] wdata;
output        waccept;
output [31:0] rdatap;
output        rresp;
input  [1:0]  amode;
input  [2:0]  clsize;
output [2:0]  rstatus;
input  [3:0]  xid;
input  [7:0]  mstid;
input         done;

// VBUS write status interface
output        sreq;
output [2:0]  sstatus;
input         sready;
output        sdone;
output [3:0]  sid;
output [7:0]  smstid;

// Endian Control
input         big_endian;

// SPI Core VBUSP Interface
output        spi_cfg_req;
output [AW-1:0] spi_cfg_address;
output        spi_cfg_cmd;
output [3:0]  spi_cfg_byten;
output [31:0] spi_cfg_wdata;
input  [31:0] spi_cfg_rdatap;
input  [31:0] spi_cfg_rdata;
input         spi_cfg_rresp;
input         spi_cfg_waccept;

// Signal indicating the SPI divide clock is on
input         spi_clk_en;

// Test
input         test_mode;

reg   [3:0] current_state;
reg   [3:0] next_state;

reg   [2:0] current_xfer_state;
reg   [2:0] next_xfer_state;

reg  [31:0] rdatap;
reg  [2:0]  sstatus;
reg  [2:0]  rstatus;

reg         spi_cfg_req;
reg  [AW-1:0]  spi_cfg_address;
reg         spi_cfg_cmd;
reg  [3:0]  spi_cfg_byten;
reg  [31:0] spi_cfg_wdata;

reg  [31:0] spimm_cfg_rdatap;
reg  [7:0]  read_command0;
reg  [7:0]  write_command0;
reg  [1:0]  num_addr_bytes0;
reg  [1:0]  num_dummy_bytes0;
reg  [7:0]  read_command1;
reg  [7:0]  write_command1;
reg  [1:0]  num_addr_bytes1;
reg  [1:0]  num_dummy_bytes1;
reg  [7:0]  read_command2;
reg  [7:0]  write_command2;
reg  [1:0]  num_addr_bytes2;
reg  [1:0]  num_dummy_bytes2;
reg  [7:0]  read_command3;
reg  [7:0]  write_command3;
reg  [1:0]  num_addr_bytes3;
reg  [1:0]  num_dummy_bytes3;
reg         dual_read0;
reg         dual_read1;
reg         dual_read2;
reg         dual_read3;
reg         mmspi_control;
reg         mmspi_int_en;
reg         mmspi_rf_mode;
reg [1:0]   mmspi_req_mode;

reg         mmspi_cfg_sel_q;
reg         mm_req_q;

reg         go;
reg         setup;
reg         ixdone;
reg         xdone;
reg  [31:0] dr;
reg  [31:0] cr;
reg  [31:0] mm_rdatap;
reg  [11:0] flen;

reg         mmspi_req;
reg  [AWW-1:0]  mmspi_address;
reg  [3:0]  mmspi_byten;
reg         mmspi_cmd;
reg  [31:0] mmspi_wdata;

reg         isreq;

reg         clwrap;

reg         isreq_set_q;
reg         isdone;
reg  [3:0]  isid;
reg  [7:0]  ismstid;
reg  [2:0]  isstatus;
reg         irresp;
reg         iwaccept;

wire        mmspi_cfg_sel;
wire        spi_cfg_sel;

wire [4:0]  num_addr_bits;
wire [4:0]  num_dummy_bits;
wire [5:0]  num_xfer_bits_last;
wire [5:0]  num_xfer_bits_first;
wire [5:0]  num_xfer_bits_middle;

wire        mm_req;
wire        mm_waccept;
wire        mm_rresp;
wire [1:0]  cs;

wire        xfer_done;
wire [11:0] xfer_cnt;

wire [7:0]  read_command;
wire [7:0]  write_command;
wire [1:0]  num_addr_bytes;
wire [1:0]  num_dummy_bytes;
wire        dual_read;

wire [1:0]  spi_cmd;

wire [3:0]  mm_int_cmd;

wire        immspi_control;

wire        sreq_set;
wire        isreq_set;

wire        bad_amode;

wire        imm_req;
wire        icfg_req;

wire [4:0] command_length;

  // Write Status Interface
  //
  //  Write status interface connections:
  //
  //  sreq = high on : req && last && done
  //         low when sready seen
  //  sstatus when sreq until sready
  //  sdone = done
  //  sid = xid
  //  smstid = mstid

  assign mm_req = mm_req0 || mm_req1 || mm_req2 || mm_req3;

  assign imm_req  = mm_req && !isreq;
  assign icfg_req = cfg_req && !isreq;

  assign bad_amode = ((amode != LINEAR_INCREMENT) && (amode != CACHE_LINE_WRAP));

  assign isreq_set = (icfg_req || imm_req) && !cmd && last && done && iwaccept;
  assign sreq_set  = isreq_set && !isreq_set_q;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      isreq    <= 1'b0;
      isdone   <= 1'b0;
      isid     <= 4'd0;
      ismstid  <= 8'd0;
      isstatus <= GOOD_ADDRESS_MODE_STATUS;
	  isreq_set_q <= 1'b0;   // (New addition due to LINT warning 09.07.15 - Slava)
    end
    else begin
      isreq_set_q <= isreq_set;
      if (sreq_set && !sready) begin
        isreq   <= 1'b1;
        isdone  <= done;
        isid    <= xid;
        ismstid <= mstid;
        if (bad_amode) begin
          isstatus <= BAD_ADDRESS_MODE_STATUS;
        end
        else begin
          isstatus <= GOOD_ADDRESS_MODE_STATUS;
        end
      end // if (sreq_set && !sready)
      else if (sready) begin
        isreq    <= 1'b0;
        isdone   <= 1'b0;
        isid     <= 4'd0;
        ismstid  <= 8'd0;        
        isstatus <= GOOD_ADDRESS_MODE_STATUS;
      end
    end // else: !if(!rst_n)
  end // always @ (posedge clk or negedge rst_n)

  assign sreq = sreq_set || isreq;

  always @(*) 
  begin
    sstatus = isstatus;
    if (sreq_set && bad_amode) begin
      sstatus = BAD_ADDRESS_MODE_STATUS;
    end
  end

  assign sdone  = (sreq_set) ? done  : isdone;
  assign sid    = (sreq_set) ? xid   : isid;
  assign smstid = (sreq_set) ? mstid : ismstid;

  // Read status
  always @(posedge clk or negedge rst_n) 
  begin
    if (!rst_n) begin
      rstatus <= GOOD_ADDRESS_MODE_STATUS;
    end
    else begin
      if ((icfg_req || imm_req) && cmd && irresp) begin
        rstatus <= GOOD_ADDRESS_MODE_STATUS;
        if (bad_amode) begin
          rstatus <= BAD_ADDRESS_MODE_STATUS;
        end
      end
    end // else: !if(!rst_n)
  end // always @ (posedge clk or negedge rst_n)

  // Main design

  assign immspi_control = mmspi_control && spi_clk_en;

  assign mmspi_cfg_sel = icfg_req && ((address[AW-1:2] == MMSPI_CS_MOD) || (address[AW-1:2] == MMSPI_SW) ||
                                      (address[AW-1:2] == MMSPI_SETUP0) || (address[AW-1:2] == MMSPI_SETUP1) ||
                                      (address[AW-1:2] == MMSPI_SETUP2) || (address[AW-1:2] == MMSPI_SETUP3));

  assign spi_cfg_sel = icfg_req && ((address[AW-1:2] == SPIPID) ||
                                    (address[AW-1:2] == SPICC) || (address[AW-1:2] == SPIDC) ||
                                    (address[AW-1:2] == SPICR) || (address[AW-1:2] == SPISR) ||
                                    (address[AW-1:2] == SPIDR));

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      mmspi_cfg_sel_q <= 1'b0;
      mm_req_q        <= 1'b0;
    end
    else begin
      mmspi_cfg_sel_q <= mmspi_cfg_sel;
      mm_req_q        <= imm_req;
    end
  end // always @ (posedge clk or negedge rst_n)

  always @(*)
  begin
    if (!immspi_control) begin
      spi_cfg_req     = spi_cfg_sel;
      spi_cfg_address[AW-1:0] = address[AW-1:0];
      spi_cfg_cmd     = cmd;
      spi_cfg_byten   = byten;
      spi_cfg_wdata   = wdata;

      irresp = (!mmspi_cfg_sel) ? spi_cfg_rresp : 1'b1;
      iwaccept = (!mmspi_cfg_sel) ? spi_cfg_waccept : 1'b1;
      if (rstatus == BAD_ADDRESS_MODE_STATUS) begin
        rdatap = 32'd0;
      end
      else begin
        rdatap = (mmspi_cfg_sel_q) ? spimm_cfg_rdatap : spi_cfg_rdatap; 
      end
    end // if (!immspi_control)
    else begin
      spi_cfg_req     = (imm_req) ? mmspi_req                  : spi_cfg_sel;
      spi_cfg_address[AW-1:0] = (imm_req) ? {mmspi_address[AWW-1:0], 2'd0} : address[AW-1:0];
      spi_cfg_cmd     = (imm_req) ? mmspi_cmd                  : cmd;
      spi_cfg_byten   = (imm_req) ? mmspi_byten                : byten;
      spi_cfg_wdata   = (imm_req) ? mmspi_wdata                : wdata;

      irresp = (imm_req) ? mm_rresp : 
                (!mmspi_cfg_sel) ? spi_cfg_rresp : 1'b1;
      iwaccept = (imm_req) ? mm_waccept : 
                (!mmspi_cfg_sel) ? spi_cfg_waccept : 1'b1;
      if (rstatus == BAD_ADDRESS_MODE_STATUS) begin
        rdatap = 32'd0;
      end
      else begin
        rdatap = (mm_req_q) ? mm_rdatap : 
                 (mmspi_cfg_sel_q) ? spimm_cfg_rdatap : spi_cfg_rdatap;
      end
    end // else: !if(!immspi_control)
  end // always @ (*)

  assign rresp = irresp && !isreq;
  assign waccept = iwaccept && !isreq;

  // Additional CONFIG MMR WRITE registers
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      read_command0    <= DEFAULT_READ_COMMAND;   // Default to slow byte read
      read_command1    <= DEFAULT_READ_COMMAND;   // Default to slow byte read
      read_command2    <= DEFAULT_READ_COMMAND;   // Default to slow byte read
      read_command3    <= DEFAULT_READ_COMMAND;   // Default to slow byte read
      write_command0   <= DEFAULT_WRITE_COMMAND;  // Default to page program
      write_command1   <= DEFAULT_WRITE_COMMAND;  // Default to page program
      write_command2   <= DEFAULT_WRITE_COMMAND;  // Default to page program
      write_command3   <= DEFAULT_WRITE_COMMAND;  // Default to page program
      num_addr_bytes0  <= DEFAULT_NUM_ADDR_BYTES; // Default to 3 address bytes
      num_addr_bytes1  <= DEFAULT_NUM_ADDR_BYTES; // Default to 3 address bytes
      num_addr_bytes2  <= DEFAULT_NUM_ADDR_BYTES; // Default to 3 address bytes
      num_addr_bytes3  <= DEFAULT_NUM_ADDR_BYTES; // Default to 3 address bytes
      num_dummy_bytes0 <= DEFAULT_DUMMY_BYTES;    // Default to 0 dummy bytes (no fast read default)
      num_dummy_bytes1 <= DEFAULT_DUMMY_BYTES;    // Default to 0 dummy bytes (no fast read default)
      num_dummy_bytes2 <= DEFAULT_DUMMY_BYTES;    // Default to 0 dummy bytes (no fast read default)
      num_dummy_bytes3 <= DEFAULT_DUMMY_BYTES;    // Default to 0 dummy bytes (no fast read default)
      dual_read0       <= DEFAULT_DUAL_READ;      // Default to no dual read (no dual read default)
      dual_read1       <= DEFAULT_DUAL_READ;      // Default to no dual read (no dual read default)
      dual_read2       <= DEFAULT_DUAL_READ;      // Default to no dual read (no dual read default)
      dual_read3       <= DEFAULT_DUAL_READ;      // Default to no dual read (no dual read default)
      mmspi_int_en     <= 1'b0;
      mmspi_control    <= DEFAULT_MMSPI_CONTROL;
      mmspi_rf_mode    <= 1'b0;
      mmspi_req_mode   <= mmspi_req_mode_ival; // Initial value latched from strapping resistors
    end // if (!rst_n)
    else begin
      if (icfg_req && !cmd) begin
        case (address[AW-1:2])
          MMSPI_SETUP0 : 
            begin
              if (byten[0]) begin
                read_command0 <= wdata[7:0];
              end
              if (byten[1]) begin
                num_addr_bytes0  <= wdata[9:8];
                num_dummy_bytes0 <= wdata[11:10];
                dual_read0       <= wdata[12];
              end
              if (byten[2]) begin
                write_command0 <= wdata[23:16];
              end
            end // case: MMSPI_SETUP0
          MMSPI_SETUP1 : 
            begin
              if (byten[0]) begin
                read_command1 <= wdata[7:0];
              end
              if (byten[1]) begin
                num_addr_bytes1  <= wdata[9:8];
                num_dummy_bytes1 <= wdata[11:10];
                dual_read1       <= wdata[12];
              end
              if (byten[2]) begin
                write_command1 <= wdata[23:16];
              end
            end // case: MMSPI_SETUP1
          MMSPI_SETUP2 : 
            begin
              if (byten[0]) begin
                read_command2 <= wdata[7:0];
              end
              if (byten[1]) begin
                num_addr_bytes2  <= wdata[9:8];
                num_dummy_bytes2 <= wdata[11:10];
                dual_read2       <= wdata[12];
              end
              if (byten[2]) begin
                write_command2 <= wdata[23:16];
              end
            end // case: MMSPI_SETUP2
          MMSPI_SETUP3 : 
            begin
              if (byten[0]) begin
                read_command3 <= wdata[7:0];
              end
              if (byten[1]) begin
                num_addr_bytes3  <= wdata[9:8];
                num_dummy_bytes3 <= wdata[11:10];
                dual_read3       <= wdata[12];
              end
              if (byten[2]) begin
                write_command3 <= wdata[23:16];
              end
            end // case: MMSPI_SETUP3
          MMSPI_SW :
            begin
              if (byten[0]) begin
                mmspi_rf_mode <= wdata[2];
                mmspi_int_en  <= wdata[1];
                mmspi_control <= wdata[0];
              end
            end
          MMSPI_CS_MOD :
            begin
              if (byten[0]) begin
                mmspi_req_mode <= wdata[1:0];
              end
            end
        endcase // case(address[AW-1:2])
      end // if (icfg_req && !cmd)
    end // else: !if(!rst_n)
  end // always @ (posedge clk or negedge rst_n)

  // Additional CONFIG MMR READ registers
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      spimm_cfg_rdatap <= 32'd0;
    end
    else begin
      if (icfg_req && cmd) begin
        case (address[AW-1:2])
          MMSPI_SETUP0 : 
            begin
              spimm_cfg_rdatap <= {8'd0, write_command0, 3'd0, dual_read0, num_dummy_bytes0, num_addr_bytes0, read_command0};
            end
          MMSPI_SETUP1 : 
            begin
              spimm_cfg_rdatap <= {8'd0, write_command1, 3'd0, dual_read1, num_dummy_bytes1, num_addr_bytes1, read_command1};
            end
          MMSPI_SETUP2 : 
            begin
              spimm_cfg_rdatap <= {8'd0, write_command2, 3'd0, dual_read2, num_dummy_bytes2, num_addr_bytes2, read_command2};
            end
          MMSPI_SETUP3 : 
            begin
              spimm_cfg_rdatap <= {8'd0, write_command3, 3'd0, dual_read3, num_dummy_bytes3, num_addr_bytes3, read_command3};
            end
          MMSPI_SW :
            begin
              spimm_cfg_rdatap <= {24'd0, 4'd0, 1'b0, mmspi_rf_mode, mmspi_int_en, mmspi_control};
            end
          MMSPI_CS_MOD :
            begin
              spimm_cfg_rdatap <= {30'd0, mmspi_req_mode[1:0]};
            end
        endcase // case(address[AW-1:2])
      end // if (icfg_req && cmd)
    end // else: !if(!rst_n)
  end // always @ (posedge clk or negedge rst_n)

  // State register
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      current_state <= STATE_IDLE;
    end
    else begin
      current_state <= next_state;
    end
  end

  // Because clsize only defined for 0, 1, 2, 3 and cache line wrap,
  // current assumption is default to linear increment mode if in
  // cache line wrap mode and clsize > 3.
  always @(*)
  begin
    clwrap = 1'b0;
    if (amode == 2'd3) begin
      case (clsize[2:0]) 
        3'd0    : clwrap = (({1'b0, address[3:0]} + 3'd4) >= 5'd16)  ? 1'b1 : 1'b0;
        3'd1    : clwrap = (({1'b0, address[4:0]} + 3'd4) >= 6'd32)  ? 1'b1 : 1'b0;
        3'd2    : clwrap = (({1'b0, address[5:0]} + 3'd4) >= 7'd64)  ? 1'b1 : 1'b0;
        3'd3    : clwrap = (({1'b0, address[6:0]} + 3'd4) >= 8'd128) ? 1'b1 : 1'b0;
      endcase // case(clsize[2:0])
    end
  end // always @ (*)

  // Next state decoder
  always @(*)
  begin
    next_state = STATE_IDLE;
    case (current_state)
      STATE_IDLE :
        begin
          next_state = STATE_IDLE;
          if (imm_req && immspi_control) begin
            next_state = STATE_COMMAND_INIT;
          end
        end
      STATE_COMMAND_INIT :
        begin
          next_state = STATE_COMMAND;
        end
      STATE_COMMAND :
        begin
          next_state = STATE_COMMAND;
          if (xdone) begin
            next_state = STATE_ADDRESS_INIT;
          end
        end
      STATE_ADDRESS_INIT :
        begin
          next_state = STATE_ADDRESS;
        end
      STATE_ADDRESS :
        begin
          next_state = STATE_ADDRESS;
          if (xdone) begin
            if ((num_dummy_bytes != 2'd0) && (cmd)) begin
              next_state = STATE_DUMMY_INIT;
            end
            else begin
              next_state = STATE_DATA_INIT;
            end
          end
        end // case: STATE_ADDRESS
      STATE_DUMMY_INIT :
        begin
          next_state = STATE_DUMMY;
        end
      STATE_DUMMY :
        begin
          next_state = STATE_DUMMY;
          if (xdone) begin
            next_state = STATE_DATA_INIT;
          end
        end
      STATE_DATA_INIT :
        begin
          next_state = STATE_DATA;
        end
      STATE_DATA :
        begin
          next_state = STATE_DATA;
          if (xdone) begin
            if (last) begin
              next_state = STATE_END;
            end
            else if (!clwrap) begin
              next_state = STATE_DATA_INIT;
            end
            else begin
              next_state = STATE_ABORT_INIT;
            end
          end // if (xdone)
        end // case: STATE_DATA
      STATE_ABORT_INIT :
        begin
          next_state = STATE_ABORT;
        end
      STATE_ABORT :
        begin
          next_state = STATE_ABORT;
          if (xdone) begin
            next_state = STATE_IDLE;
          end
        end
      STATE_END :
        begin
          next_state = STATE_IDLE;
        end
    endcase // case(current_state)
  end // always @ (*)

  assign num_dummy_bytes = (mm_req0) ? num_dummy_bytes0 :
                             (mm_req1) ? num_dummy_bytes1 :
                               (mm_req2) ? num_dummy_bytes2 : num_dummy_bytes3;

  assign num_addr_bytes = (mm_req0) ? num_addr_bytes0 :
                            (mm_req1) ? num_addr_bytes1 :
                              (mm_req2) ? num_addr_bytes2 : num_addr_bytes3;

  assign dual_read      = (mm_req0) ? dual_read0 :
                            (mm_req1) ? dual_read1 :
                              (mm_req2) ? dual_read2 : dual_read3;

  // num_addr_bytes is 2 bits wide
  assign num_addr_bits[4:0]       = (mmspi_rf_mode) ? 5'h4 :
                                                 (({3'b0,num_addr_bytes} + 1'b1) << 2'd3) - 1'b1;

  // num_dummy_bytes is 2 bits wide
  assign num_dummy_bits[4:0]    = ({3'b0,num_dummy_bytes} << 2'd3) - 1'b1;
  
  // bytecnt is 10 bits wide
  assign num_xfer_bits_last[5:0]  = (mmspi_rf_mode && !cmd) ? 6'h10 : 
                               (mmspi_rf_mode &&  cmd) ? 6'h10 :
                                                         (bytecnt << 2'd3) - 1'b1;
  assign num_xfer_bits_first[5:0] = (mmspi_rf_mode && !cmd) ? 6'h10 : 
                               (mmspi_rf_mode &&  cmd) ? 6'h10 :
                                                 ((6'd4 - address[1:0]) << 2'd3) - 1'b1;
  assign num_xfer_bits_middle[5:0] = (mmspi_rf_mode && !cmd) ? 6'h10 :
                               (mmspi_rf_mode &&  cmd) ? 6'h10 : 
                                                         6'h1F;

  assign cs = (mm_req0) ? 2'd0 :
                (mm_req1) ? 2'd1 :
                  (mm_req2) ? 2'd2 :
                    (mm_req3) ? 2'd3 : 2'd0;

  assign read_command = (mm_req0) ? read_command0 :
                          (mm_req1) ? read_command1 :
                            (mm_req2) ? read_command2 : read_command3;

  assign write_command = (mm_req0) ? write_command0 :
                           (mm_req1) ? write_command1 :
                             (mm_req2) ? write_command2 : write_command3;

  // bytecnt is 10 bits wide
  assign xfer_cnt[11:0] = ((({2'b0,bytecnt[9:0]} + address[1:0]) - 1'b1) >> 2'd2) + 1'b1;

  assign spi_cmd = (cmd) ? {dual_read, 1'b1} : 2'b10;

  assign mm_int_cmd = {1'b0, mmspi_int_en, 2'd0};

  assign command_length = (mmspi_rf_mode) ? 5'h0 : 5'h7; 

  // State machine output
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      go        <= 1'b0;
      setup     <= 1'b0;
      dr        <= 32'd0;
      cr        <= 32'd0;
      mm_rdatap <= 32'd0;
      flen      <= 12'd0;
    end
    else begin
      go    <= 1'b0;
      setup <= 1'b0;
      case (current_state)
        STATE_IDLE :
          begin
            if (imm_req && immspi_control) begin
              if ((num_dummy_bytes == 2'd0) || (!cmd)) begin 
                flen <= xfer_cnt + 2'd1;
              end
              else begin
                flen <= xfer_cnt + 2'd2;
              end
            end
          end // case: STATE_IDLE
        STATE_COMMAND_INIT :
          begin
            go    <= 1'b1;
            setup <= 1'b1;
            dr <= (cmd) ? {24'd0, read_command} : {24'd0, write_command};
            if ((num_dummy_bytes == 2'd0) || (!cmd)) begin
              cr <= {2'd0, cs, 4'd0, command_length, 1'b0, 2'b10, mm_int_cmd, flen};
            end
            else begin
              cr <= {2'd0, cs, 4'd0, command_length, 1'b0, 2'b10, mm_int_cmd, flen};
            end
          end // case: STATE_COMMAND_INIT
        STATE_COMMAND :
          begin
            setup <= 1'b1;
          end
        STATE_ADDRESS_INIT :
          begin
            go    <= 1'b1;
            setup <= 1'b1;
            case (num_addr_bytes)
              2'd0 : dr <= (mmspi_rf_mode) ? {26'd0, address[7:2]} : 
                                                {24'd0, address[7:0]};
              2'd1 : dr <= (mmspi_rf_mode) ? {18'd0, address[15:2]} :
                                                {16'd0, address[15:0]};
              2'd2 : dr <= (mmspi_rf_mode) ? {10'd0, address[23:2]} :
                                                {8'd0, address[23:0]};
              2'd3 : dr <= (mmspi_rf_mode) ? {2'd0, address[31:2]} :
                                                address[31:0];
            endcase // case(num_addr_bytes)
            if ((num_dummy_bytes == 2'd0) || (!cmd)) begin
              cr <= {2'd0, cs, 4'd0, num_addr_bits, 1'b0, 2'b10, mm_int_cmd, flen};
            end
            else begin
              cr <= {2'd0, cs, 4'd0, num_addr_bits, 1'b0, 2'b10, mm_int_cmd, flen};
            end
          end // case: STATE_ADDRESS_INIT
        STATE_ADDRESS :
          begin
            setup <= 1'b1;
          end
        STATE_DUMMY_INIT :
          begin
            go    <= 1'b1;
            setup <= 1'b1;
            dr    <= 32'd0;
            cr    <= {2'd0, cs, 4'd0, num_dummy_bits, 1'b0, 2'b10, mm_int_cmd, flen};
          end
        STATE_DUMMY :
          begin
            setup <= 1'b1;
          end
        STATE_DATA_INIT :
          begin
            go <= 1'b1;
            dr <= 32'd0;
            casex ({first, last})
              2'bx1 :
                begin
                  // bytecnt 1, 2, 3, 4 only
                  cr <= {2'd0, cs, 4'd0, num_xfer_bits_last[4:0], 1'b0, spi_cmd, mm_int_cmd, flen};
                  if (!cmd) begin
                    case (bytecnt[2:0])
                      3'd1 : 
                        begin
                          if (!big_endian) begin
                            case (address[1:0])
                              2'd0 : dr <= {24'd0, wdata[7:0]};
                              2'd1 : dr <= {24'd0, wdata[15:8]};
                              2'd2 : dr <= {24'd0, wdata[23:16]};
                              2'd3 : dr <= {24'd0, wdata[31:24]};
                            endcase // case(address[1:0])
                          end
                          else begin
                            case (address[1:0])
                              2'd0 : dr <= {24'd0, wdata[31:24]};
                              2'd1 : dr <= {24'd0, wdata[23:16]};
                              2'd2 : dr <= {24'd0, wdata[15:8]};
                              2'd3 : dr <= {24'd0, wdata[7:0]};
                            endcase // case(address[1:0])
                          end // else: !if(!big_endian)
                        end // case: 3'd1
                      3'd2 : 
                        begin
                          if (mmspi_rf_mode)  begin
                            dr <= {15'h0, wdata[15:0], 1'b0};
                          end
                          else if (!big_endian) begin
                            case (address[1:0])
                              2'd0 : dr <= {16'd0, wdata[7:0],   wdata[15:8]};
                              2'd1 : dr <= {16'd0, wdata[15:8],  wdata[23:16]};
                              2'd2 : dr <= {16'd0, wdata[23:16], wdata[31:24]};
//VCS coverage off
                              2'd3 : dr <= {24'd0, wdata[31:24]};  // invalid
//VCS coverage on
                            endcase // case(address[1:0])
                          end
                          else begin
                            case (address[1:0])
                              2'd0 : dr <= {16'd0, wdata[31:24], wdata[23:16]};
                              2'd1 : dr <= {16'd0, wdata[23:16], wdata[15:8]};
                              2'd2 : dr <= {16'd0, wdata[15:8],  wdata[7:0]};
//VCS coverage off
                              2'd3 : dr <= {24'd0, wdata[7:0]};  // invalid
//VCS coverage on
                            endcase // case(address[1:0])
                          end // else: !if(!big_endian)
                        end // case: 3'd2
                      3'd3 : 
                        begin
                          if (!big_endian) begin
                            case (address[0])
                              1'b0 : dr <= {8'd0, wdata[7:0],  wdata[15:8],  wdata[23:16]};
                              1'b1 : dr <= {8'd0, wdata[15:8], wdata[23:16], wdata[31:24]};
                            endcase // case(address[0])
                          end
                          else begin
                            case (address[0])
                              1'b0 : dr <= {8'd0, wdata[31:24], wdata[23:16], wdata[15:8]};
                              1'b1 : dr <= {8'd0, wdata[23:16], wdata[15:8],  wdata[7:0]};
                            endcase // case(address[0])
                          end // else: !if(!big_endian)
                        end // case: 3'd3
                      3'd4 : 
                        begin
                          if (mmspi_rf_mode)  begin
                            dr <= {15'h0, wdata[15:0], 1'b0};
                          end
                          else if (!big_endian) begin
                            dr <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
                          end
                          else  begin
                            dr <= {wdata[31:24], wdata[23:16], wdata[15:8], wdata[7:0]};
                          end
                        end
//VCS coverage off
                      default :
                        begin
                          if (mmspi_rf_mode)  begin
                            dr <= {15'h0, wdata[15:0], 1'b0};
                          end
                          else if (!big_endian) begin
                            dr <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
                          end
                          else begin
                            dr <= {wdata[31:24], wdata[23:16], wdata[15:8], wdata[7:0]};
                          end
                        end
//VCS coverage on
                    endcase // case(bytecnt[2:0])
                  end // if (!cmd)
                end // case: 2'bx1
              2'b10 :
                begin
                  cr <= {2'd0, cs, 4'd0, num_xfer_bits_first[4:0], 1'b0, spi_cmd, mm_int_cmd, flen};
                  if (!cmd) begin
                    if (mmspi_rf_mode)  begin
                       dr <= {15'h0, wdata[15:0], 1'b0};
                       end
                    else if (!big_endian) begin
                      case (address[1:0])
                        2'd0 : dr <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
                        2'd1 : dr <= {8'd0, wdata[15:8], wdata[23:16], wdata[31:24]};
                        2'd2 : dr <= {16'd0, wdata[23:16], wdata[31:24]};
                        2'd3 : dr <= {24'd0, wdata[31:24]};
                      endcase // case(address[1:0])
                    end
                    else begin
                      case (address[1:0])
                        2'd0 : dr <= {wdata[31:24], wdata[23:16], wdata[15:8], wdata[7:0]};
                        2'd1 : dr <= {8'd0, wdata[23:16], wdata[15:8], wdata[7:0]};
                        2'd2 : dr <= {16'd0, wdata[15:8], wdata[7:0]};
                        2'd3 : dr <= {24'd0, wdata[7:0]};
                      endcase // case(address[1:0])
                    end // else: !if(!big_endian)
                  end // if (!cmd)
                end // case: 2'b10
              2'b00 :
                begin
                  cr <= {2'd0, cs, 3'd0, num_xfer_bits_middle, 1'b0, spi_cmd, mm_int_cmd, flen};
                  if (!cmd) begin
                    if (mmspi_rf_mode)  begin
                       dr <= {15'h0, wdata[15:0], 1'b0};
                       end
                    else if (!big_endian) begin
                      dr <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
                    end
                    else begin
                      dr <= {wdata[31:24], wdata[23:16], wdata[15:8], wdata[7:0]};
                    end
                  end
                end // case: 2'b00
            endcase // casex({first, last})
          end // case: STATE_DATA_INIT
        STATE_DATA :
          begin
            if (ixdone) begin
              if (cmd) begin
                casex ({first, last})
                  2'bx1 : 
                    begin
                      case (bytecnt[2:0])
                        3'd1 : 
                          begin
                            if (!big_endian) begin
                              case (address[1:0])
                                2'd0 : mm_rdatap <= {24'd0,  spi_cfg_rdata[7:0]};
                                2'd1 : mm_rdatap <= {16'd0, spi_cfg_rdata[7:0],  8'd0};
                                2'd2 : mm_rdatap <= {8'd0, spi_cfg_rdata[7:0],  16'd0};
                                2'd3 : mm_rdatap <= {spi_cfg_rdata[7:0],  24'd0};
                              endcase // case(address[1:0])
                            end
                            else begin
                              case (address[1:0])
                                2'd0 : mm_rdatap <= {spi_cfg_rdata[7:0], 24'd0};
                                2'd1 : mm_rdatap <= {8'd0, spi_cfg_rdata[7:0],  16'd0};
                                2'd2 : mm_rdatap <= {16'd0, spi_cfg_rdata[7:0],  8'd0};
                                2'd3 : mm_rdatap <= {24'd0, spi_cfg_rdata[7:0]};
                              endcase // case(address[1:0])
                            end // else: !if(!big_endian)
                          end // case: 3'd1
                        3'd2 : 
                          begin
                            if (!big_endian) begin
                              case (address[1:0])
                                2'd0 : mm_rdatap <= {16'd0,  spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8]};
                                2'd1 : mm_rdatap <= {8'd0, spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8], 8'd0};
                                2'd2 : mm_rdatap <= {spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8], 16'd0};
//VCS coverage off
                                2'd3 : mm_rdatap <= {spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8], 16'd0}; // invalid
//VCS coverage on
                              endcase // case(address[1:0])
                            end
                            else begin
                              case (address[1:0])
                                2'd0 : mm_rdatap <= {spi_cfg_rdata[15:8],  spi_cfg_rdata[7:0], 16'd0};
                                2'd1 : mm_rdatap <= {8'd0, spi_cfg_rdata[15:8],  spi_cfg_rdata[7:0], 8'd0};
                                2'd2 : mm_rdatap <= {16'd0, spi_cfg_rdata[15:8],  spi_cfg_rdata[7:0]};
//VCS coverage off
                                2'd3 : mm_rdatap <= {16'd0, spi_cfg_rdata[15:8],  spi_cfg_rdata[7:0]}; // invalid
//VCS coverage on
                              endcase // case(address[1:0])
                            end // else: !if(!big_endian)
                          end // case: 3'd2
                        3'd3 : 
                          begin
                            if (!big_endian) begin
                              case (address[0])
                                1'b0 : mm_rdatap <= {8'd0,  spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8], spi_cfg_rdata[23:16]};
                                1'b1 : mm_rdatap <= {spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8], spi_cfg_rdata[23:16], 8'd0};
                              endcase // case(address[0])
                            end
                            else begin
                              case (address[0])
                                1'b0 : mm_rdatap <= {spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0], 8'd0};
                                1'b1 : mm_rdatap <= {8'd0, spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                              endcase // case(address[0])
                            end // else: !if(!big_endian)
                          end // case: 3'd3
                        3'd4 : 
                          begin
                            if (!big_endian && !mmspi_rf_mode) begin
                              mm_rdatap <= {spi_cfg_rdata[7:0],   spi_cfg_rdata[15:8],  spi_cfg_rdata[23:16], spi_cfg_rdata[31:24]};
                            end
                            else begin 
                              mm_rdatap <= {spi_cfg_rdata[31:24], spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                            end
                          end
//VCS coverage off
                        default :
                          begin
                            if (!big_endian && !mmspi_rf_mode) begin
                              mm_rdatap <= {spi_cfg_rdata[7:0],   spi_cfg_rdata[15:8],  spi_cfg_rdata[23:16], spi_cfg_rdata[31:24]};
                            end
                            else begin 
                              mm_rdatap <= {spi_cfg_rdata[31:24], spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                            end
                          end
//VCS coverage on
                      endcase // case(bytecnt[2:0])
                    end // case: 2'bx1
                  2'b10 :
                    begin
                      if (!big_endian && !mmspi_rf_mode) begin
                        case (address[1:0])
                          2'd0 : mm_rdatap <= {spi_cfg_rdata[7:0],   spi_cfg_rdata[15:8],  spi_cfg_rdata[23:16], spi_cfg_rdata[31:24]};
                          2'd1 : mm_rdatap <= {spi_cfg_rdata[7:0],  spi_cfg_rdata[15:8], spi_cfg_rdata[23:16], 8'd0};
                          2'd2 : mm_rdatap <= {spi_cfg_rdata[7:0], spi_cfg_rdata[15:8], 16'd0};
                          2'd3 : mm_rdatap <= {spi_cfg_rdata[7:0], 24'd0};
                        endcase // case(address[1:0])
                      end
                      else begin
                        case (address[1:0])
                          2'd0 : mm_rdatap <= {spi_cfg_rdata[31:24], spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                          2'd1 : mm_rdatap <= {8'd0, spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                          2'd2 : mm_rdatap <= {16'd0, spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                          2'd3 : mm_rdatap <= {24'd0, spi_cfg_rdata[7:0]};
                        endcase // case(address[1:0])
                      end // else: !if(!big_endian)
                    end // case: 2'b10
                  2'b00 :
                    begin
                      if (!big_endian && !mmspi_rf_mode) begin
                        mm_rdatap <= {spi_cfg_rdata[7:0],   spi_cfg_rdata[15:8],  spi_cfg_rdata[23:16], spi_cfg_rdata[31:24]};
                      end
                      else begin 
                        mm_rdatap <= {spi_cfg_rdata[31:24], spi_cfg_rdata[23:16],  spi_cfg_rdata[15:8], spi_cfg_rdata[7:0]};
                      end
                    end
                endcase // casex({first, last})
              end // if (cmd)
            end // if (ixdone)
          end // case: STATE_DATA
        STATE_ABORT_INIT :
          begin
            go    <= 1'b1;
            setup <= 1'b1;
            dr    <= 32'd0;
            cr    <= {4'd0, cs[1:0], 4'd0, 5'd0, 1'b0, 2'b00, 2'b00, flen[11:0]};
          end
        STATE_ABORT :
          begin
            setup <= 1'b1;
          end
        STATE_END :
          begin
          end
      endcase // case(current_state)
    end // else: !if(!rst_n)
  end // always @ (posedge clk or negedge rst_n)

  assign mm_waccept = xdone && !cmd && (current_state == STATE_DATA);
  assign mm_rresp = xdone && cmd && (current_state == STATE_DATA);

  // Transfer state machine
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      current_xfer_state <= STATE_XFER_IDLE;
      xdone              <= 1'b0;
    end
    else begin
      current_xfer_state <= next_xfer_state;
      xdone              <= ixdone;
    end
  end // always @ (posedge clk or negedge rst_n)

  assign xfer_done = mmspi_req && (mmspi_address[AWW-1:0] == SPISR) && |(spi_cfg_rdata & 32'h00000006);

  always @(*)
  begin
    mmspi_req       = 1'b0;
    mmspi_address   = SPISR; // AWW'd0; Did this to help conditional coverage above
    mmspi_byten     = 4'h0;
    mmspi_cmd       = 1'b1;
    mmspi_wdata     = 32'd0;
    ixdone          = 1'b0;
    next_xfer_state = STATE_XFER_IDLE;
    case (current_xfer_state)
      STATE_XFER_IDLE :
        begin
          next_xfer_state = STATE_XFER_IDLE;
          if (go) begin
            if (setup) begin
              next_xfer_state = STATE_XFER_CR;
              mmspi_req       = 1'b1;
              mmspi_address   = SPIDR;
              mmspi_byten     = 4'hf;
              mmspi_cmd       = 1'b0;
              mmspi_wdata     = dr;
            end
            else if (!cmd) begin
              next_xfer_state = STATE_XFER_CR;
              mmspi_req       = 1'b1;
              mmspi_address   = SPIDR;
              mmspi_byten     = 4'hf;
              mmspi_cmd       = 1'b0;
              mmspi_wdata     = dr;
            end
            else begin
              next_xfer_state = STATE_XFER_INT_CLR;
              mmspi_req       = 1'b1;
              mmspi_address   = SPICR;
              mmspi_byten     = 4'hf;
              mmspi_cmd       = 1'b0;
              mmspi_wdata     = cr;
            end // else: !if(!cmd)
          end // if (go)
        end // case: STATE_XFER_IDLE
      STATE_XFER_CR :
        begin
          next_xfer_state = STATE_XFER_INT_CLR;
          mmspi_req       = 1'b1;
          mmspi_address   = SPICR;
          mmspi_byten     = 4'hf;
          mmspi_cmd       = 1'b0;
          mmspi_wdata     = cr;
        end
      STATE_XFER_INT_CLR :
        begin
          next_xfer_state = STATE_XFER_INT_CLR;
          mmspi_req       = 1'b1;
          mmspi_address   = SPISR;
          mmspi_byten     = 4'hf;
          mmspi_cmd       = 1'b1;
          if (!xfer_done) begin
            next_xfer_state = STATE_XFER_WAIT;
          end
        end // case: STATE_XFER_INT_CLR
      STATE_XFER_WAIT :
        begin
          next_xfer_state = STATE_XFER_WAIT;
          mmspi_req       = 1'b1;
          mmspi_address   = SPISR;
          mmspi_byten     = 4'hf;
          mmspi_cmd       = 1'b1;
          if (xfer_done) begin
            if (setup) begin
              next_xfer_state = STATE_XFER_IDLE;
              ixdone = 1'b1;
            end
            else if (!cmd) begin
              next_xfer_state = STATE_XFER_IDLE;
              ixdone = 1'b1;
            end
            else begin
              next_xfer_state = STATE_XFER_RD;
            end
          end // if (xfer_done)
        end // case: STATE_XFER_WAIT
      STATE_XFER_RD :
        begin
          next_xfer_state = STATE_XFER_IDLE;
          mmspi_req       = 1'b1;
          mmspi_address   = SPIDR;
          mmspi_byten     = 4'hf;
          mmspi_cmd       = 1'b1;
          ixdone          = 1'b1;
        end
    endcase // case(current_xfer_state)
  end // always @ (*)

endmodule // spi_sfi_mm
