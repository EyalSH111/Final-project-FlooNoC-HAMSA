//-----------------------------------------------------------------------------
// Modification history :
// ??.??.???? : created
// [Slava] 21.10.2015 : Addition of address monitoring mechanism of RegFile
//-----------------------------------------------------------------------------

module spi_cntif
  (
    clk,
    rst_n,
    spi_clk,
    spi_rst_n,
    // CLK synchronized reset output
    sync_rst_n,
    // VBUS Interface
    req,
    address,
    cmd,
    byten,
    wdata,
    rdata,
    rdatap,
    rresp,
    waccept,
    interrupt,
    // Parameters
    shift_out_data,
    wlen,
    wlen_ot,
    flen,
    csnum,
    dat_dly,
    clk_pol,
    cs_pol,
    clk_ph,
    spi_clk_en,
    spi_clk_div,
    // Controls
    dr_load,        // Not internally used
    read_cmd,
    sread_cmd,
    dread_cmd,
    write_cmd,
    bad_cmd,
    // Read data
    shift_in_data,
    // Status
    busy,           // Not internally used
    wc,
    fc,
    wdcnt,
    // Test signal
    test_mode,
	
	// DFT
	scan_enable,
	dft_clk_en,
	
	phy_cg_sel,
	
	// Address monitoring interrupts
	spi_bad_addr_irq,
	spi_bad_addr_unmsk_irq
  );

   parameter  SPI_IS_BOOT = 0;

   parameter 	AW = 8;    // 2^8 words = 1KB space
   localparam   DW = 32;   

   // VBUS Register Addresses
   localparam SEL_SPIPID = {{(AW-3){1'b0}},3'h0};
   localparam SEL_SPICC  = {{(AW-3){1'b0}},3'h1};
   localparam SEL_SPIDC  = {{(AW-3){1'b0}},3'h2};
   localparam SEL_SPICR  = {{(AW-3){1'b0}},3'h3};
   localparam SEL_SPISR  = {{(AW-3){1'b0}},3'h4};
   localparam SEL_SPIDR  = {{(AW-3){1'b0}},3'h5};
   
   localparam MAX_SLV_ADDR = SEL_SPIDR;
   localparam [AW-1:0] ONE_WORD = {{(AW-1){1'b0}},1'b1};    // AW-wide one vector

//--------------------------------------------- Address monitoring registers --------------------------------------------//

   // The last legal address of the SPI slave is SEL_SPIDR = 8b'00000101, so next address allocated to BAD_RD_ADDR
   localparam BAD_RD_ADDR = MAX_SLV_ADDR + ONE_WORD; // 8b'00000110 bytes ==> 0x18

   // Next address of 0x24 allocated to BAD_WR_ADDR
   localparam BAD_WR_ADDR = BAD_RD_ADDR + ONE_WORD;                   // 8b'00000111 bytes ==> 0x1C
   
   // Next address of 0x28 allocated to IRQ_SIG_MASK (internal)
   localparam IRQ_SIG_MASK = BAD_WR_ADDR + ONE_WORD;                  // 8b'00001000 bytes ==> 0x20

   // Next address of 0x2C allocated to IRQ_SIG_CLR_P
   localparam IRQ_SIG_CLR_P = IRQ_SIG_MASK + ONE_WORD;                // 8b'00001001 bytes ==> 0x24

   // Next address of 0x30 allocated to IRQ_SIG_OUT - maskable interrupt
   localparam IRQ_SIG_OUT = IRQ_SIG_CLR_P + ONE_WORD;                 // 8b'00001010 bytes ==> 0x28

   // Next address of 0x34 allocated to IRQ_SIG_OUT_UNMSK - unmaskable interrupt
   localparam IRQ_SIG_OUT_UNMSK = IRQ_SIG_OUT + ONE_WORD;             // 8b'00001011 bytes ==> 0x2C  
   
   localparam MAX_VAL_ADDR = IRQ_SIG_OUT_UNMSK;
   
//-----------------------------------------------------------------------------------------------------------------------//    
   // SPI Clock Selection Parameters
   localparam SEL_CS0 = 2'b00;
   localparam SEL_CS1 = 2'b01;
   localparam SEL_CS2 = 2'b10;
   localparam SEL_CS3 = 2'b11;

   localparam SPICC_RST_VAL = SPI_IS_BOOT ? 32'h8000_0000 : 32'h0000_0000;
   localparam SPIDC_RST_VAL = SPI_IS_BOOT ? 32'h0000_0018 : 32'h0000_0000;
   
   input         clk;
   input         rst_n;
   input      spi_clk;
   input      spi_rst_n;
   
   // CLK synchronized reset
   output     sync_rst_n;
   
   // VBUS Interface
   input      req;
   input [AW-1:0] address;
   input 	  cmd;    // (0=WRITE; 1=READ)
   input [3:0] 	  byten;
   input [DW-1:0]   wdata;
   output [DW-1:0]  rdata;
   output [DW-1:0]  rdatap;
   output 	  rresp;
   output 	  waccept;
   output 	  interrupt;
   
   // Parameters
   output [31:0]  shift_out_data;
   output [4:0]   wlen;
   output [4:0]   wlen_ot;
   output [11:0]  flen;
   output [1:0]   csnum;
   output [1:0]   dat_dly;
   output 	  clk_pol;
   output [3:0]   cs_pol;
   output 	  clk_ph;
   output 	  spi_clk_en;
   output [15:0]  spi_clk_div;
   
   // Controls
   input 	  dr_load;
   output 	  read_cmd;
   output 	  sread_cmd;
   output 	  dread_cmd;
   output 	  write_cmd;
   output 	  bad_cmd;
   
   // Address monitoring interrupts
   output reg      spi_bad_addr_irq;   
   output reg      spi_bad_addr_unmsk_irq; 
   
   // Read data
   input [31:0]   shift_in_data;
   
   // Status
   input 	  busy;
   input 	  wc;
   input 	  fc;
   input [11:0]   wdcnt;
   
   // Test Signal
   input 	  test_mode;
   
   // DFT signals
   input           scan_enable;
   input           dft_clk_en;
   
   input [1:0]     phy_cg_sel;   
   
   reg [DW-1:0] 	  rdatap;
   reg 		  i_interrupt;
   reg 		  interrupt;
   
   reg [DW-1:0] 	  muxed_data;
   
   reg 		  isread_cmd;
   reg 		  iread_cmd;
   reg 		  idread_cmd;
   reg 		  iwrite_cmd;
   reg 		  ibad_cmd;
   
   reg [31:0] 	  spicc;
   reg [31:0] 	  spidc;
   reg [31:0] 	  spicr;
   reg [31:0] 	  spidr;
   
   reg 		  iclk_pol;
   reg 		  iclk_ph;
   reg [1:0] 	  idat_dly;
   
   reg 		  sr_wc;
   reg 		  sr_fc;
   reg 		  sr_busy;
   reg 		  sr_read;
   
   reg 		  clk_pol;
   reg 		  clk_ph;
   reg [1:0] 	  dat_dly;
   reg [1:0] 	  csnum;
   reg [3:0] 	  cs_pol;
   reg [4:0] 	  wlen_ot;
   
   reg 		  p_read;
   
   reg 		  idr_load_q;
   
   wire [31:0] 	  spisr;
   wire 	  ibusy;
   wire 	  wc_sync;
   wire 	  fc_sync;
   wire 	  isr_fc;
   wire 	  isr_wc;
   wire 	  isync_rst_n;
   
   wire 	  inew_cmd;
   wire 	  new_cmd;
   wire [31:0] 	  shift_in_data_g;
   
   wire [1:0] 	  icsnum;
   wire [3:0] 	  ics_pol;
   
   wire [1:0] 	  dat_dly_g;
   wire 	  clk_ph_g;
   wire 	  clk_pol_g;
   wire [1:0] 	  csnum_g;
   wire [3:0] 	  cs_pol_g;
   wire [4:0] 	  wlen_g;
   
   wire 	  idr_load;
   
   wire [11:0] 	  wdcnt_g;
   
   wire [31:0] 	  spipid;  // 32'h4e780001;
   wire [31:0] 	  hi;
   wire [31:0] 	  lo;
   
   // SPIPID is instantiated from 32 tie off cells so that each bit can be
   // modified individually in an ECO
   crg_tieoff Irevid[DW-1:0] 
     (
      .hi (hi),
      .lo (lo)
      );
   
   assign spipid = {
                    lo[31], hi[30], lo[29], lo[28],
                    hi[27], hi[26], hi[25], lo[24],
                    lo[23], hi[22], hi[21], hi[20],
                    hi[19], lo[18], lo[17], lo[16],
                    lo[15], lo[14], lo[13], lo[12],
                    lo[11], lo[10], lo[9],  lo[8],
                    lo[7],  lo[6],  lo[5],  lo[4],
                    lo[3],  lo[2],  lo[1],  hi[0]
                  };

  assign rresp = 1'b1;
  assign waccept = 1'b1;

  // Reset synchronizer
  crg_sync2_arst  Sspi_rst_n
    (
      .clk    (clk),
      .clr_n  (rst_n),
      .d      (1'b1),
      .q      (isync_rst_n)
    );

  crg_clk_mx2          Sspi_rst_n_mux
    (
      .a (isync_rst_n),
      .b (rst_n),
      .s (test_mode),
      .y (sync_rst_n)
    );

  // wc synchronization
  spi_sync Iwc_load_sync
    (
      .din_clk    (spi_clk),
      .din_rst_n  (spi_rst_n),
      .dout_clk   (clk),
      .dout_rst_n (sync_rst_n),
    
      .din        (wc),
      .dout       (wc_sync),

      .din_flag   (),
      .dout_flag  ()
    );

  // fc synchronization
  spi_sync Ifc_load_sync
    (
      .din_clk    (spi_clk),
      .din_rst_n  (spi_rst_n),
      .dout_clk   (clk),
      .dout_rst_n (sync_rst_n),
    
      .din        (fc),
      .dout       (fc_sync),

      .din_flag   (),
      .dout_flag  ()
    );

  ///////////////////////////////////////////////////////
  // VBUSP READ Section
  ///////////////////////////////////////////////////////


  assign ibusy = inew_cmd || (sr_busy && !(wc_sync || fc_sync));

  assign isr_fc = fc_sync || sr_fc;
  assign isr_wc = wc_sync || sr_wc;

  crg_clk_an2 Iwdcnt[11:0]
    (
     .a (sr_read), 
     .b (wdcnt), 
     .y (wdcnt_g)
    );

  assign spisr = {4'd0, wdcnt_g, 12'd0, 1'b0, isr_fc, isr_wc, ibusy};
  
//--------------------------- Address monitoring expansion - part I (START) ----------------------------//

   wire                 gclk_en;
   wire                 gclk;                
   wire [1:0]           irq_sig_clr_p;
   wire [1:0]           irq_sig_out;   
   wire [1:0]           irq_sig_out_unmsk;
   
   wire                 sig_out_irq_net;
   wire                 sig_out_unmsk_irq_net;

   reg [(AW+2)-1:0]     bad_rd_addr;
   reg [(AW+2)-1:0]     bad_wr_addr;
   reg                  rd_err_p_irq_sig;
   reg                  wr_err_p_irq_sig;
   reg                  rd_err_p_irq_sig_reg;
   reg                  wr_err_p_irq_sig_reg;
   
   wire write_trans;
   assign write_trans = req & (!cmd);
   
   reg				rd_err_p_irq_sig_t;
   reg	[AW-1:0]	bad_rd_addr_t;
    
//--------------------------- Address monitoring expansion - part I (END) -----------------------------//  
  
  //Pipelined data output
  always @(posedge clk or negedge sync_rst_n)
  begin
    if (!sync_rst_n) begin
      sr_wc   <= 1'b0;
      sr_fc   <= 1'b0;
      sr_busy <= 1'b0;
      rdatap  <= {DW{1'b0}};
	  bad_rd_addr[(AW+2)-1:0] <= {(AW+2){1'b0}};
      rd_err_p_irq_sig <= 1'b0;
    end
    else begin
      if (p_read) begin
        rdatap <= muxed_data[DW-1:0];
		bad_rd_addr[(AW+2)-1:0] <= {bad_rd_addr_t[AW-1:0],2'b00};
		rd_err_p_irq_sig <= rd_err_p_irq_sig_t;
      end
      if (wc_sync && !sr_read) begin
        sr_wc <= 1'b1;
      end
      else if (sr_read) begin
        sr_wc <= 1'b0;
      end
      if (fc_sync && !sr_read) begin
        sr_fc <= 1'b1;
      end
      else if (sr_read) begin
        sr_fc <= 1'b0;
      end
      if (inew_cmd) begin
        sr_busy <= 1'b1;
      end
      else if (wc_sync || fc_sync) begin
        sr_busy <= 1'b0;
      end
    end
  end

  // wc_sync and fc_sync are outputs of synchronizers.  Although
  // they both technically drive a single signal which will feed
  // a register, the muxing scheme below will keep them from
  // both going active at the same time
  
  always @(*)
  begin
    case (spicr[15:14])
      2'b00   : i_interrupt = 1'b0;
      2'b01   : i_interrupt = wc_sync;
      2'b10   : i_interrupt = fc_sync;
      2'b11   : i_interrupt = wc_sync;
//VCS coverage off
      default : i_interrupt = 1'b0;
//VCS coverage on
    endcase
  end

  always @(posedge clk or negedge sync_rst_n)
  begin
    if (!sync_rst_n) begin
        interrupt <= 1'b0;
    end
    else begin
        interrupt <= i_interrupt;
    end
  end
 
  //Non-pipelined data output
  assign rdata = muxed_data[DW-1:0];

  ///////////////////////////////////////////////////////
  // VBUSP READ Section
  ///////////////////////////////////////////////////////
  always @(*)
  begin
    sr_read    = 1'b0;
    p_read     = 1'b0;
    muxed_data = {DW{1'b0}};	// To prevent latching
	rd_err_p_irq_sig_t = 1'b0;	// Default RD interrupt indicator turned OFF
	bad_rd_addr_t[AW-1:0] = {AW{1'b0}};	
    if (req) begin
      case (address[AW-1:0])
        SEL_SPIPID :
          begin
            muxed_data = spipid[DW-1:0];
            p_read     = 1'b1;
          end
        SEL_SPICC : 
          begin 
            muxed_data = {spicc[31], 15'd0, spicc[15:0]}; 
            p_read     = 1'b1;
          end
        SEL_SPIDC : 
          begin 
            muxed_data = {3'd0, spidc[28:24], 3'd0, spidc[20:16], 3'd0, spidc[12:8], 3'd0, spidc[4:0]}; 
            p_read     = 1'b1;
          end
        SEL_SPICR : 
          begin 
            muxed_data = {2'd0, spicr[29:28], 4'd0, spicr[23:14], 2'd0, spicr[11:0]}; 
            p_read     = 1'b1;
          end
        SEL_SPISR : 
          begin 
            muxed_data = {4'd0, spisr[27:16], 13'd0, spisr[2:0]}; 
            sr_read    = 1'b1;
            p_read     = 1'b1;
          end
        SEL_SPIDR : 
          begin 
            muxed_data = spidr[DW-1:0]; 
            p_read     = 1'b1;
          end
		BAD_RD_ADDR :
			begin
				muxed_data[(AW+2)-1:0] = bad_rd_addr[(AW+2)-1:0];
				p_read     = 1'b1;
			end
		BAD_WR_ADDR :
			begin
				muxed_data[(AW+2)-1:0] = bad_wr_addr[(AW+2)-1:0];
				p_read     = 1'b1;
			end	
		IRQ_SIG_MASK :
			begin
				muxed_data[1:0] = {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg};
				p_read     = 1'b1;
			end	 
		IRQ_SIG_OUT :
			begin
				muxed_data[1:0] = irq_sig_out[1:0];
				p_read     = 1'b1;
			end	
		IRQ_SIG_OUT_UNMSK :
			begin
				muxed_data[1:0] = irq_sig_out_unmsk[1:0];
				p_read     = 1'b1;
			end				
        default:   
          begin 
            muxed_data = 32'h BABADBAD; 
            sr_read    = 1'b0;
            p_read     = 1'b0;
			rd_err_p_irq_sig_t = 1'b1;	// RD interrupt indicator turned ON
			bad_rd_addr_t[AW-1:0] = address[AW-1:0]; // Save the exceeding address
          end
      endcase
    end
  end
  
  ///////////////////////////////////////////////////////
  // VBUSP WRITE Section
  ///////////////////////////////////////////////////////

  always @(posedge clk or negedge sync_rst_n)
  begin
    if (!sync_rst_n) begin
      spicc      <= SPICC_RST_VAL;
      spidc      <= SPIDC_RST_VAL;
      spicr      <= 32'b0;
      isread_cmd <= 1'b0;
      iread_cmd  <= 1'b0;
      idread_cmd <= 1'b0;
      iwrite_cmd <= 1'b0;
      ibad_cmd   <= 1'b0;
    end
    else begin
      isread_cmd <= 1'b0;
      iread_cmd  <= 1'b0;
      idread_cmd <= 1'b0;
      iwrite_cmd <= 1'b0;
      ibad_cmd   <= 1'b0;
      if (!cmd && req) begin
        case (address[AW-1:0])
          SEL_SPICC: // Clock Configuration Register
            begin
              if (!sr_busy) begin
                if (byten[0]) spicc[7:0]   <= wdata[7:0];
                if (byten[1]) spicc[15:8]  <= wdata[15:8];
                if (byten[2]) spicc[23:16] <= wdata[23:16];
                if (byten[3]) spicc[31:24] <= wdata[31:24];
              end
            end
          SEL_SPIDC: // Device Configuration Register
            begin  
              if (!sr_busy) begin
                if (byten[0]) spidc[7:0]   <= wdata[7:0];
                if (byten[1]) spidc[15:8]  <= wdata[15:8];
                if (byten[2]) spidc[23:16] <= wdata[23:16];
                if (byten[3]) spidc[31:24] <= wdata[31:24];
              end
            end
          SEL_SPICR: // Command Register
            begin
              if (!sr_busy) begin  
                if (byten[0]) spicr[7:0]   <= wdata[7:0];
                if (byten[1]) spicr[15:8]  <= wdata[15:8];
                if (byten[2]) begin
                  spicr[23:16] <= wdata[23:16];
                  // Dual pin mode
                  if (spi_clk_en) begin
                    if (!wdata[18]) begin 
                      isread_cmd   <= 1'b0;
                      iread_cmd    <= !wdata[17] && wdata[16];
                      idread_cmd   <= wdata[17] && wdata[16];
                      iwrite_cmd   <= wdata[17] && !wdata[16];
                      ibad_cmd     <= !wdata[17] && !wdata[16];
                    end
                    // Single pin mode
                    else begin
                      isread_cmd   <= !wdata[17] && wdata[16];
                      iread_cmd    <= 1'b0;
                      idread_cmd   <= 1'b0;
                      iwrite_cmd   <= wdata[17] && !wdata[16];
                      ibad_cmd     <= (!wdata[17] && !wdata[16]) || (wdata[17] && wdata[16]);
                    end
                  end
                end
                if (byten[3]) spicr[31:24] <= wdata[31:24];
              end
            end
        endcase
      end
    end
  end

//--------------------------- Address monitoring expansion - part II (START) ---------------------------//
  
   //==================================================================
   // Write access to the interrupt status register of the slave
   //==================================================================

   always @(posedge gclk) begin
        if (!sync_rst_n)
             {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg} <= 2'b11; // Enable by default
        // Write transaction to IRQ_SIG_MASK register
        else if (write_trans & address[AW-1:0] == IRQ_SIG_MASK)
          {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg} <= wdata[1:0];
   end // always @ (posedge gclk)

   //==================================================================

   assign irq_sig_clr_p[1:0] = (wdata[1:0] & {2{(write_trans & address[AW-1:0] == IRQ_SIG_CLR_P)}}); // Signal is a pulse

   //==================================================================
   // Detection & save of write access to slave's exceeding address
   //==================================================================

   always @(posedge gclk) begin
        if (!sync_rst_n) begin
             bad_wr_addr[(AW+2)-1:0] <= {(AW+2){1'b0}};
             wr_err_p_irq_sig <= 1'b0;
        end
        // Write transaction beyond meaningfull address space of the slave
        else if (write_trans & address[AW-1:0] > MAX_VAL_ADDR) begin
                 bad_wr_addr[(AW+2)-1:0] <= {address[AW-1:0],2'b00}; // Save the exceeding address
                 wr_err_p_irq_sig <= 1'b1;
             end 
        else wr_err_p_irq_sig <= 1'b0;
   end // always @ (posedge gclk)

   //================================================================== 
   
   //============= Internal interrupt controller ======================

   reg [1:0] irq_sig_mask;
   reg [1:0] irq_sig_strb_in_p;
   
   always @(*) begin
        irq_sig_mask[1:0] = {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg};
        irq_sig_strb_in_p[1:0] = {wr_err_p_irq_sig,rd_err_p_irq_sig};
   end
   
   intc #(.DW(2)) I_intc (
                          // Outputs
                          .data_out_unmasked           (irq_sig_out_unmsk[1:0]),
                          .data_out                    (irq_sig_out[1:0]),
                          .any_data_out                (sig_out_irq_net),
                          .any_data_out_unmasked       (sig_out_unmsk_irq_net),
                          // Inputs
                          .sreset_n                    (sync_rst_n),
                          .clk                         (clk),
                          .strbs_in_p                  (irq_sig_strb_in_p[1:0]),
                          .clear_data_p                (irq_sig_clr_p[1:0]),
                          .enable_strbs                (irq_sig_mask[1:0])
                          );

   always @(posedge clk) spi_bad_addr_irq <= (~sync_rst_n) ? 1'b0 : sig_out_irq_net;
   always @(posedge clk) spi_bad_addr_unmsk_irq <= (~sync_rst_n) ? 1'b0 : sig_out_unmsk_irq_net;
   
   //==================================================================    
      
   //=================== Internal gated ckock =========================
   
   assign gclk_en = req;

   crg_clk_clockgate reg_file_gclk_i (
  		// Outputs
  		.out_clk (gclk),          // Output gated clock 
  		// Inputs
  		.clk        (clk),
  		.en         (gclk_en),          // RegFile clock gating signal 
  		.ten        (scan_enable));
   
   //==================================================================    

//--------------------------- Address monitoring expansion - part II (END) ----------------------------//
  
  // read_cmd synchronization
  spi_sync Iread_cmd_sync
    (
      .din_clk    (clk),
      .din_rst_n  (sync_rst_n),
      .dout_clk   (spi_clk),
      .dout_rst_n (spi_rst_n),
    
      .din        (iread_cmd),
      .dout       (read_cmd),

      .din_flag   (),
      .dout_flag  ()
    );

  // sread_cmd synchronization
  spi_sync Isread_cmd_sync
    (
      .din_clk    (clk),
      .din_rst_n  (sync_rst_n),
      .dout_clk   (spi_clk),
      .dout_rst_n (spi_rst_n),
    
      .din        (isread_cmd),
      .dout       (sread_cmd),

      .din_flag   (),
      .dout_flag  ()
    );


  // dread_cmd synchronization (dual read)
  spi_sync Idread_cmd_sync
    (
      .din_clk    (clk),
      .din_rst_n  (sync_rst_n),
      .dout_clk   (spi_clk),
      .dout_rst_n (spi_rst_n),
    
      .din        (idread_cmd),
      .dout       (dread_cmd),

      .din_flag   (),
      .dout_flag  ()
    );

  // write_cmd synchronization
  spi_sync Iwrite_cmd_sync
    (
      .din_clk    (clk),
      .din_rst_n  (sync_rst_n),
      .dout_clk   (spi_clk),
      .dout_rst_n (spi_rst_n),
    
      .din        (iwrite_cmd),
      .dout       (write_cmd),

      .din_flag   (),
      .dout_flag  ()
    );

  // bad_cmd synchronization
  spi_sync Ibad_cmd_sync
    (
      .din_clk    (clk),
      .din_rst_n  (sync_rst_n),
      .dout_clk   (spi_clk),
      .dout_rst_n (spi_rst_n),
    
      .din        (ibad_cmd),
      .dout       (bad_cmd),

      .din_flag   (),
      .dout_flag  ()
    );

  assign inew_cmd    = iread_cmd || iwrite_cmd || idread_cmd || isread_cmd;
  // Though technically the output of 3 synchronizers, these signals
  // are one hot, meaning by design they will only come out one at 
  // a time, ie, they are independent of each other.
  assign new_cmd     = read_cmd || write_cmd || dread_cmd || sread_cmd;

  assign spi_clk_en  = spicc[31];
  assign spi_clk_div = spicc[15:0];
  assign flen        = spicr[11:0];
  assign wlen        = spicr[23:19];
  assign icsnum      = spicr[29:28];
  assign ics_pol     = {spidc[25], spidc[17], spidc[9], spidc[1]};

  // This edge detect is only important for asynchronous clocks
  assign idr_load = (wc_sync || fc_sync) && !idr_load_q;

  crg_clk_an2 Ishift_in_data[DW-1:0]
    (
     .a (idr_load), 
     .b (shift_in_data), 
     .y (shift_in_data_g)
    );

  always @(posedge clk or negedge sync_rst_n)
  begin
    if (!sync_rst_n) begin
      spidr      <= 32'b0;
      idr_load_q <= 1'b0;
    end
    else begin
      idr_load_q <= (wc_sync || fc_sync);
      if (!sr_busy) begin
        if (!cmd && req && (address[AW-1:0] == SEL_SPIDR)) begin
          if (byten[0]) spidr[7:0]   <= wdata[7:0];
          if (byten[1]) spidr[15:8]  <= wdata[15:8];
          if (byten[2]) spidr[23:16] <= wdata[23:16];
          if (byten[3]) spidr[31:24] <= wdata[31:24];
        end
      end
      else begin
        if (idr_load) begin
          spidr <= shift_in_data_g;
        end
      end
    end
  end

  assign shift_out_data = spidr;

  // Sensitivity list changed to a wildcard (09.07.2015 - Slava)
  always @(*)
  begin
    iclk_pol = 1'b0;
    iclk_ph  = 1'b0;
    idat_dly = 2'd0;
    case ({spicr[29], spicr[28]})
      SEL_CS0: 
        begin
          iclk_pol = spidc[0];
          iclk_ph  = spidc[2];
          idat_dly = spidc[4:3];
        end
      SEL_CS1: 
        begin
          iclk_pol = spidc[8];
          iclk_ph  = spidc[10];
          idat_dly = spidc[12:11];
        end
      SEL_CS2: 
        begin
          iclk_pol = spidc[16];
          iclk_ph  = spidc[18];
          idat_dly = spidc[20:19];
        end
      SEL_CS3: 
        begin
          iclk_pol = spidc[24];
          iclk_ph  = spidc[26];
          idat_dly = spidc[28:27];
        end
    endcase
  end

  crg_clk_an2 Idat_dly[1:0]
    (
     .a (new_cmd), 
     .b (idat_dly), 
     .y (dat_dly_g)
    );

  crg_clk_an2 Iclk_ph
    (
     .a (new_cmd), 
     .b (iclk_ph), 
     .y (clk_ph_g)
    );

  crg_clk_an2 Iclk_pol
    (
     .a (new_cmd), 
     .b (iclk_pol), 
     .y (clk_pol_g)
    );

  crg_clk_an2 Icsnum[1:0]
    (
     .a (new_cmd), 
     .b (icsnum), 
     .y (csnum_g)
    );

  crg_clk_an2 Ics_pol[3:0]
    (
     .a (new_cmd), 
     .b (ics_pol), 
     .y (cs_pol_g)
    );

  crg_clk_an2 Iwlen[4:0]
    (
     .a (new_cmd), 
     .b (wlen), 
     .y (wlen_g)
    );

  always @(posedge spi_clk or negedge spi_rst_n)
  begin
    if (!spi_rst_n) begin
      dat_dly <= 2'd0;
      clk_ph  <= 1'b0;
      clk_pol <= 1'b0;
      csnum   <= 2'd0;
      cs_pol  <= 4'd0;
      wlen_ot <= 5'd0;
    end
    else if (new_cmd) begin
      dat_dly <= dat_dly_g;
      clk_ph  <= clk_ph_g;
      clk_pol <= clk_pol_g;
      csnum   <= csnum_g;
      cs_pol  <= cs_pol_g;
      wlen_ot <= wlen_g;
    end
  end

endmodule
