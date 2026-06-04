module spi_machine
  (
    clk,
    rst_n,
    // Parameters
    wlen,    // spicr[23:19]
    flen,    // spicr[11:0]
    dat_dly, // spidc[4:3], [12:11], [20:19], [28:27]
    // Control Inputs
    read_cmd,
    sread_cmd,
    dread_cmd,
    write_cmd,
    bad_cmd,
    // Control Outputs
    cs_n,
    sread,
    dread,
    write_en,
    dr_load,
    shift_on,
    shift_out_load,
    idle,
    // Status outputs
    busy,   // spisr[0]
    wc,     // spisr[1]
    fc,     // spisr[2]
    wdcnt   // spisr[27:16]
  );

input         clk;
input         rst_n;
// Parameters
input  [4:0]  wlen;
input  [11:0] flen;
input  [1:0]  dat_dly;
// Control Inputs
input         read_cmd;
input         sread_cmd;
input         dread_cmd;
input         write_cmd;
input         bad_cmd;
// Control Outputs
output        cs_n;
output        sread;
output        dread;
output        write_en;
output        dr_load;
output        shift_on;
output        shift_out_load;
output        idle;
// Status Outputs
output        busy;
output        wc;
output        fc;
output [11:0] wdcnt;

// State Machine States
parameter STATE_IDLE   = 3'b000;
parameter STATE_LOAD   = 3'b001;
parameter STATE_DELAY1 = 3'b010;
parameter STATE_DELAY2 = 3'b011;
parameter STATE_DELAY3 = 3'b100;
parameter STATE_SHIFT  = 3'b101;
parameter STATE_TOGGLE = 3'b110;
parameter STATE_WAIT   = 3'b111;

// State Registers
reg [2:0]   st_machine;
reg [2:0]   nx_state;

reg         sread;
reg         dread;
reg         write_en;
reg         idle;
reg         dr_load;
reg         busy;
reg         wc;
reg         fc;
reg  [11:0] wdcnt;
reg         cs_n;
reg         ics_n;
reg         shift_on;
reg         shift_out_load;

reg         ld_count;
reg         dec_frmcnt;
reg         update_cnt;
reg         load_once;
reg         update_reg;
reg  [11:0] frame_cnt;
reg  [4:0]  bit_cnt;
reg         iwc;
reg         ifc;

wire        wlen_load;
wire [4:0]  iwlen;
wire        flen_load;
wire [11:0] iflen;


  ///////////////////////////////
  //      SPI State Machine    //
  ///////////////////////////////
  
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      st_machine <= STATE_IDLE;
    end
    else begin
      st_machine <= nx_state;
    end
  end

  always @(*)
  begin
    ics_n          = 1'b1;    // SPI Inactive
    ld_count       = 1'b0;
    dec_frmcnt     = 1'b0;
    update_cnt     = 1'b0;
    load_once      = 1'b0;
    update_reg     = 1'b0;
    shift_on       = 1'b0;
    shift_out_load = 1'b0;
    idle           = 1'b0;
    case (st_machine)
      STATE_IDLE:  
        begin
          idle = 1'b1;
          nx_state = STATE_IDLE;
          if (read_cmd || write_cmd || dread_cmd || sread_cmd) begin
            nx_state = STATE_LOAD;
          end
        end
  
      STATE_LOAD:  
        begin
          nx_state       = STATE_LOAD;
          ics_n          = 1'b0;
          ld_count       = 1'b1;
          shift_out_load = 1'b1;
          if (dat_dly == 2'b00) begin
            nx_state = STATE_SHIFT;
          end
          else begin
            nx_state = STATE_DELAY1;
          end
        end
  
      STATE_DELAY1:  
        begin
          nx_state = STATE_DELAY1;
          ics_n    = 1'b0;
          ld_count = 1'b1;
          if (dat_dly == 2'b01) begin
            nx_state = STATE_SHIFT;
          end
          else begin
            nx_state = STATE_DELAY2;
          end
        end
  
      STATE_DELAY2:  
        begin
          nx_state = STATE_DELAY2;
          ics_n    = 1'b0;
          ld_count = 1'b1;
          if (dat_dly == 2'b10) begin
            nx_state = STATE_SHIFT;
          end
          else begin
            nx_state = STATE_DELAY3;
          end
        end

      STATE_DELAY3:  
        begin
          ics_n    = 1'b0;
          ld_count = 1'b1;
          nx_state = STATE_SHIFT;
        end
  
      STATE_SHIFT: 
        begin
          nx_state   = STATE_SHIFT;
          ics_n      = 1'b0;
          shift_on   = 1'b1;
          if (!bad_cmd) begin // Check for termination command
            if ((frame_cnt != 0) || (bit_cnt != 0)) begin
              if (bit_cnt != 0) begin
                nx_state = STATE_SHIFT;
              end
              else begin
                nx_state   = STATE_WAIT;
                dec_frmcnt = 1'b1;
                load_once  = 1'b1;
              end
            end
            else begin
              nx_state  = STATE_TOGGLE;
              load_once = 1'b1;
            end
          end
//VCS coverage off
          else begin
            nx_state = STATE_TOGGLE;
          end
//VCS coverage on
        end
  
      STATE_TOGGLE:  
        begin
          ics_n    = 1'b0;
          nx_state = STATE_IDLE;
        end
  
      STATE_WAIT:  
        begin
          ics_n    = 1'b0;    // SPI Active
          nx_state = STATE_WAIT;
          if (bad_cmd) begin
            nx_state = STATE_TOGGLE;
          end
          else if (read_cmd || write_cmd || dread_cmd || sread_cmd) begin
            nx_state       = STATE_SHIFT;
            update_cnt     = 1'b1;
            update_reg     = 1'b1;  // CLEAR scaninreg and LOAD scanoutreg
            shift_out_load = 1'b1;
          end
        end
  
//VCS coverage off
      default: 
        begin
          ics_n      = 1'b1;    // SPI Inactive
          idle       = 1'b0;
          ld_count   = 1'b0;
          nx_state   = STATE_IDLE;
          dec_frmcnt = 1'b0;
          update_cnt = 1'b0;
          load_once  = 1'b0;
          update_reg = 1'b0;
        end
//VCS coverage on
    endcase
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      dr_load  <= 1'b0;
      dread    <= 1'b0;
      sread    <= 1'b0;
      write_en <= 1'b0;
      cs_n     <= 1'b1;
    end
    else begin
      cs_n    <= ics_n;
      dr_load <= load_once;

      if (read_cmd || dread_cmd || sread_cmd) begin
        write_en <= 1'b0;
      end
      else if (write_cmd && ((st_machine == STATE_IDLE) || (st_machine == STATE_WAIT))) begin
        write_en <= 1'b1;
      end

      if (write_cmd || read_cmd || dread_cmd) begin
        sread <= 1'b0;
      end
      else if (sread_cmd && ((st_machine == STATE_IDLE) || (st_machine == STATE_WAIT))) begin
        sread <= 1'b1;
      end

      if (write_cmd || read_cmd || sread_cmd) begin
        dread <= 1'b0;
      end
      else if (dread_cmd && ((st_machine == STATE_IDLE) || (st_machine == STATE_WAIT))) begin
        dread <= 1'b1;
      end
    end
  end

  assign wlen_load = ld_count || update_cnt;

  crg_clk_an2 Iwlen[4:0]
    (
     .a (wlen_load), 
     .b (wlen), 
     .y (iwlen)
    );

  assign flen_load = ld_count;

  crg_clk_an2 Iflen[11:0]
    (
     .a (flen_load), 
     .b (flen), 
     .y (iflen)
    );

  ///////////////////////////////////////////
  // Control for # frames/words            //
  ///////////////////////////////////////////
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      frame_cnt    <= 12'd0;
      bit_cnt      <= 5'd0;
    end
    else begin
      case ({ld_count, update_cnt})
        2'b00: 
          begin
            if (st_machine == STATE_SHIFT) begin
              if (!dread) begin
                bit_cnt <= bit_cnt - 1'b1;
              end
              else begin
                bit_cnt <= bit_cnt - 2'd2;
              end
            end
          end
        2'b01:   
          begin
            if (!dread_cmd) begin
              bit_cnt <= iwlen;  // spicr[23:19]
            end
            else begin
              bit_cnt <= {iwlen[4:1], 1'b0};
            end
          end    
        2'b10:   
          begin
            if (!dread) begin 
              bit_cnt <= iwlen;  // spicr[23:19]
            end
            else begin
              bit_cnt <= {iwlen[4:1], 1'b0};
            end
          end    
//VCS coverage off
        2'b11:   
          begin 
            if (ld_count) begin
              if (!dread) begin 
                bit_cnt <= iwlen;  // spicr[23:19]
              end
              else begin
                bit_cnt <= {iwlen[4:1], 1'b0};
              end
            end
            else begin
              if (!dread_cmd) begin
                bit_cnt <= iwlen;  // spicr[23:19]
              end
              else begin
                bit_cnt <= {iwlen[4:1], 1'b0};
              end
            end
          end    
        default: 
          begin 
            bit_cnt <= bit_cnt;
          end
//VCS coverage on
      endcase
  
      if (ld_count) begin
        frame_cnt    <= iflen; // spicr[11:0];   // Load register with cmd field value
      end
      else begin
        if (dec_frmcnt) begin
          if (frame_cnt != 12'd0) begin
            frame_cnt <= frame_cnt - 1'b1;
          end
        end
      end
    end
  end

  ///////////////////////////////////////////
  //         SPI Status register           //
  ///////////////////////////////////////////
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      busy   <= 1'b0;  // spisr[0]
      wc     <= 1'b0;  // spisr[1]
      fc     <= 1'b0;  // spisr[2]
      wdcnt  <= 12'd0; // spisr[27:16]
      iwc    <= 1'b0;
      ifc    <= 1'b0;
    end
    else begin
      // Delay wc and fc by 1 clock to account for additional
      // delay from shifter
      wc <= iwc;
      fc <= ifc;
      if (read_cmd || write_cmd || dread_cmd || sread_cmd) begin
        busy <= 1'b1;   // Set BUSY bit on new command
        iwc  <= 1'b0;   // Clear word complete bit
        ifc  <= 1'b0;   // Clear frame complete bit
      end
      else begin
        if (nx_state == STATE_IDLE || nx_state == STATE_WAIT) begin
          busy <= 1'b0;
        end
        // WC set
        if (frame_cnt != 12'd0) begin
          if (bit_cnt == 5'd0 && (nx_state == STATE_WAIT || nx_state == STATE_TOGGLE)) begin
            iwc <= 1'b1;     // Set word complete bit
          end
        end
        else if (nx_state == STATE_IDLE && (st_machine == STATE_SHIFT || st_machine == STATE_TOGGLE)) begin
          iwc <= 1'b1;       // Set word complete bit at same time as fc
        end
        // FC set
        if (nx_state == STATE_IDLE && (st_machine == STATE_SHIFT || st_machine == STATE_TOGGLE)) begin
          ifc <= 1'b1;     // Set frame complete bit
        end      
        if (st_machine == STATE_LOAD) begin
          wdcnt <= 12'd0;   // Clear word count;
        end
        else if ((st_machine == STATE_SHIFT && nx_state == STATE_WAIT) || 
                 (st_machine == STATE_SHIFT && nx_state == STATE_TOGGLE)) begin
          wdcnt <= wdcnt + 1; // word_cnt;  // Update word count
        end
      end
    end
  end

endmodule
