// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


`include "smart_uart_defines.sv"
//`include "remote_access_intrfc.sv"
`include "openocd_jtag.sv"

module apb_uart_sv
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      CLK,
    input  logic                      RSTN,
    /* verilator lint_off UNUSED */
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    /* lint_on */
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    input  logic                      rx_i,      // Receiver input
    output logic                      tx_o,      // Transmitter output

    output logic                      event_o,    // interrupt/event output

    // The apb UART interface  also side-transport the axi uart stream
    // both share a single uart physical interface.

    REMOTE_ACCESS_INTRFC.remote   remote_access_intrfc,
    OPENOCD_JTAG.master        openocd_jtag
     
);
    // register addresses
    parameter RBR = 3'h0, THR = 3'h0, DLL = 3'h0, IER = 3'h1, DLM = 3'h1, IIR = 3'h2,
              FCR = 3'h2, LCR = 3'h3, MCR = 3'h4, LSR = 3'h5, MSR = 3'h6, SCR = 3'h7;

    parameter TX_FIFO_DEPTH = 16; // in bytes
    parameter RX_FIFO_DEPTH = 16; // in bytes

    logic [2:0]       register_adr;
    logic [9:0][7:0]  regs_q, regs_n;
    logic [1:0]       trigger_level_n, trigger_level_q;

    // receive buffer register, read only
    logic [7:0]       rx_data;
    // parity error
    logic             parity_error;
    logic [3:0]       IIR_o;
    logic [3:0]       clr_int;

    /* verilator lint_off UNOPTFLAT */
    // tx flow control
    logic             tx_uart_ready_out;
    /* lint_on */

    // rx flow control
    logic             rx_valid;

    logic             tx_fifo_clr_n, tx_fifo_clr_q;
    logic             rx_fifo_clr_n, rx_fifo_clr_q;

    logic             apb_tx_valid_fifo_in;

    logic             fifo_rx_valid;
    logic             fifo_rx_ready_from_apb;
    logic             rx_ready_from_fifo;

    logic             [7:0] apb_tx_data_fifo_in;
    logic             [8:0] fifo_rx_data;

    logic             [$clog2(TX_FIFO_DEPTH):0] tx_elements;
    logic             [$clog2(RX_FIFO_DEPTH):0] rx_elements;
    
`ifndef SIM_UART_SPEED_FACTOR    
    wire [15:0] cfg_div_val = {regs_q[DLM + 'd8], regs_q[DLL + 'd8]} ;
`else
    wire [15:0] cfg_div_val = {regs_q[DLM + 'd8], regs_q[DLL + 'd8]}/`SIM_UART_SPEED_FACTOR ;
`endif 

logic su_rx_non_ascii_msg_on ;
logic su_rx_ascii_msg_on ;
logic su_rx_msg_on ;
logic su_tx_msg_on ;
logic cmd_valid ;
logic su_master_ascii_cmd_done_s ; 

logic enable_smart_uart ;   // enable/disable smart uart escape characters detection (by default enabled)
logic enable_smart_uart_d ; // pre-sample (by default enabled)

logic enable_hashtag ;   // enable/disable "#"  smart-uart commands detection
logic enable_hashtag_d ; // pre-sampled

logic enable_openocd ;   // enable/disable openocd mode
logic enable_openocd_d ; // pre-sampled

logic ocd_rx_valid;
logic [7:0] ocd_rx_data;
logic ocd_rx_ready;
logic ocd_tx_valid;
logic [7:0] ocd_tx_data;
logic ocd_tx_ready;

    // TODO: check that stop bits are really not necessary here
    uart_rx uart_rx_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),
        .rx_i               ( rx_i                          ),
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( cfg_div_val                   ),
        .cfg_parity_en_i    ( regs_q[LCR][3]                ),
        .cfg_bits_i         ( regs_q[LCR][1:0]              ),
        // .cfg_stop_bits_i    ( regs_q[LCR][2]             ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (                               ),
        /* lint_on */
        .err_o              ( parity_error                  ),
        .err_clr_i          ( 1'b1                          ),
        .rx_data_o          ( rx_data                       ),
        .rx_valid_o         ( rx_valid                      ),
        .rx_ready_i         ( rx_ready_from_fifo || su_rx_msg_on || (ocd_rx_ready && enable_openocd))
    );

 
    io_generic_fifo
    #(
        .DATA_WIDTH         ( 9                             ),
        .BUFFER_DEPTH       ( RX_FIFO_DEPTH                 )
    )
    uart_rx_fifo_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),

        .clr_i              ( rx_fifo_clr_q                 ),

        .elements_o         ( rx_elements                   ),

        .data_o             ( fifo_rx_data                  ),
        .valid_o            ( fifo_rx_valid                 ),
        .ready_i            ( fifo_rx_ready_from_apb        ),

        .valid_i            ( rx_valid && !su_rx_msg_on     ),
        .data_i             ( { parity_error, rx_data }     ),
        .ready_o            ( rx_ready_from_fifo            )
    );

    logic [7:0] tx_uart_data_in  ;
    logic tx_uart_valid_in ;
    
    logic su_tx_data_byte_valid ;
    logic [7:0] su_tx_data_byte ;
    
    logic [7:0] apb_tx_data_fifo_out ;  
    logic apb_tx_valid_fifo_out ;

    assign tx_uart_data_in  = enable_openocd ? ocd_tx_data   : (su_tx_msg_on ? su_tx_data_byte       : apb_tx_data_fifo_out ) ;          
    assign tx_uart_valid_in = enable_openocd ? ocd_tx_valid  : (su_tx_msg_on ? su_tx_data_byte_valid : apb_tx_valid_fifo_out) ;

    uart_tx uart_tx_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),
        .tx_o               ( tx_o                          ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (                               ),
        /* lint_on */
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( cfg_div_val                   ),
        .cfg_parity_en_i    ( regs_q[LCR][3]                ),
        .cfg_bits_i         ( regs_q[LCR][1:0]              ),
        .cfg_stop_bits_i    ( regs_q[LCR][2]                ),

        .tx_data_i          ( tx_uart_data_in               ),
        .tx_valid_i         ( tx_uart_valid_in              ),
        .tx_ready_o         ( tx_uart_ready_out             )
    );


    wire apb_tx_ready_fifo_in;
    assign apb_tx_ready_fifo_in = tx_uart_ready_out && !su_tx_msg_on ;

    io_generic_fifo
    #(
        .DATA_WIDTH         ( 8                             ),
        .BUFFER_DEPTH       ( TX_FIFO_DEPTH                 )
    )
    uart_tx_fifo_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),

        .clr_i              ( tx_fifo_clr_q                 ),

        .elements_o         ( tx_elements                   ),

        .data_o             ( apb_tx_data_fifo_out          ),
        .valid_o            ( apb_tx_valid_fifo_out         ),
        .ready_i            ( apb_tx_ready_fifo_in          ),

        .valid_i            ( apb_tx_valid_fifo_in          ),
        .data_i             ( apb_tx_data_fifo_in           ),
        // not needed since we are getting the status via the fifo population
        .ready_o            (                               )
    );

    uart_interrupt
    #(
        .TX_FIFO_DEPTH (TX_FIFO_DEPTH),
        .RX_FIFO_DEPTH (RX_FIFO_DEPTH)
    )
    uart_interrupt_i
    (
        .clk_i              ( CLK                           ),
        .rstn_i             ( RSTN                          ),


        .IER_i              ( regs_q[IER][2:0]              ), // interrupt enable register
        .RDA_i              ( regs_n[LSR][5]                ), // receiver data available
        .CTI_i              ( 1'b0                          ), // character timeout indication


        .error_i            ( regs_n[LSR][2]                ),
        .rx_elements_i      ( rx_elements                   ),
        .tx_elements_i      ( tx_elements                   ),
        .trigger_level_i    ( trigger_level_q               ),

        .clr_int_i          ( clr_int                       ), // one hot

        .interrupt_o        ( event_o                       ),
        .IIR_o              ( IIR_o                         )

    );

    // UART Registers

    // register write and update logic
    always_comb
    begin
        regs_n          = regs_q;
        trigger_level_n = trigger_level_q;
        
        enable_smart_uart_d = enable_smart_uart ;
        enable_hashtag_d = enable_hashtag ;
        enable_openocd_d = enable_openocd ;
        
        apb_tx_valid_fifo_in   = 1'b0;
        tx_fifo_clr_n   = 1'b0; // self clearing
        rx_fifo_clr_n   = 1'b0; // self clearing

        // rx status
        regs_n[LSR][0] = fifo_rx_valid; // fifo is empty

        // parity error on receiving part has occured
        regs_n[LSR][2] = fifo_rx_data[8]; // parity error is detected when element is retrieved

        // tx status register
        regs_n[LSR][5] = ~ (|tx_elements); // fifo is empty
        regs_n[LSR][6] = tx_uart_ready_out & ~ (|tx_elements); // shift register and fifo are empty
        
         apb_tx_data_fifo_in = 0 ; // 28/2/2019 TMP UDI RESOLVE SYNTHESIS INCOMP WARN, VERIFY

        if (PSEL && PENABLE && PWRITE)
        begin
            case (register_adr)

                THR: // either THR or DLL
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                    begin
                        regs_n[DLL + 'd8] = PWDATA[7:0];
                    end
                    else
                    begin
                        apb_tx_data_fifo_in = PWDATA[7:0];
                        apb_tx_valid_fifo_in = 1'b1;
                    end
                end

                IER: // either IER or DLM
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                        regs_n[DLM + 'd8] = PWDATA[7:0];
                    else
                        regs_n[IER] = PWDATA[7:0];
                end

                LCR:
                    regs_n[LCR] = PWDATA[7:0];

                FCR: // write only register, fifo control register
                begin
                    rx_fifo_clr_n   = PWDATA[1];
                    tx_fifo_clr_n   = PWDATA[2];
                    trigger_level_n = PWDATA[7:6];
                end
                
                SCR: 
                begin 
                 enable_openocd_d    =  PWDATA[2] ;
                 enable_smart_uart_d =  PWDATA[1] ; // enable/disable smart-uart escape characters commands detection
                 enable_hashtag_d    =  PWDATA[0] ; // enable/disable "#"  smart-uart commands detection
                end 

                default: ;
            endcase
        end // if (PSEL && PENABLE && PWRITE)                
    end // always_comb

    // register read logic
    always_comb
    begin
        PRDATA = 'b0;
        fifo_rx_ready_from_apb = 1'b0;
        clr_int      = 4'b0;
        
        
     if (PSEL && PENABLE && !PWRITE)
        begin
            case (register_adr)
                RBR: // either RBR or DLL
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                        PRDATA = {24'b0, regs_q[DLL + 'd8]};
                    else
                    begin

                        fifo_rx_ready_from_apb = 1'b1;

                        PRDATA = {24'b0, fifo_rx_data[7:0]};

                        clr_int = 4'b1000; // clear Received Data Available interrupt
                    end
                end

                LSR: // Line Status Register
                begin
                    PRDATA = {24'b0, regs_q[LSR]};
                    clr_int = 4'b1100; // clear parrity interrupt error
                end

                LCR: // Line Control Register
                    PRDATA = {24'b0, regs_q[LCR]};

                IER: // either IER or DLM
                begin
                    if (regs_q[LCR][7]) // Divisor Latch Access Bit (DLAB)
                        PRDATA = {24'b0, regs_q[DLM + 'd8]};
                    else
                        PRDATA = {24'b0, regs_q[IER]};
                end

                IIR: // interrupt identification register read only
                begin
                    PRDATA = {24'b0, 1'b1, 1'b1, 2'b0, IIR_o};
                    clr_int = 4'b0100; // clear Transmitter Holding Register Empty
                end
                
                SCR: PRDATA = {29'b0,enable_openocd,enable_smart_uart,enable_hashtag} ; // reads flag of enable/disable "#"  smart-uart commands detection

                default: ;
            endcase
        end // if (PSEL && PENABLE && !PWRITE)
                       
    end // always_comb

    // synchronouse part
    always_ff @(posedge CLK, negedge RSTN)
    begin
        if(~RSTN)
        begin

            regs_q[IER]       <= 8'h0;
            regs_q[IIR]       <= 8'h1;
            regs_q[LCR]       <= 8'h03;
            regs_q[MCR]       <= 8'h0;
            regs_q[LSR]       <= 8'h60;
            regs_q[MSR]       <= 8'h0;
            regs_q[SCR]       <= 8'h0;

            // default {dlm,dll} at reset to baudrate d 115200 @ 10MHz
            // = int((10*1000000/115200)-1) = 85 = 0x55
            // Use 0x15a for 40MHz
            
            regs_q[DLM + 'd8] <= 8'h0 ;
            regs_q[DLL + 'd8] <= 8'h55 ;   

            trigger_level_q <= 2'b10;
            tx_fifo_clr_q   <= 1'b1;
            rx_fifo_clr_q   <= 1'b1;

        end
        else
        begin
            regs_q <= regs_n;

            trigger_level_q <= trigger_level_n;
            tx_fifo_clr_q   <= tx_fifo_clr_n;
            rx_fifo_clr_q   <= rx_fifo_clr_n;

        end
    end
    
    always_ff @(posedge CLK, negedge RSTN) 
        if(~RSTN) begin
           enable_smart_uart <= 1 ;        
           enable_hashtag <= 1 ;   // By Default it is enabled
           enable_openocd <= 0 ; 
        end
        else begin
          enable_smart_uart <= enable_smart_uart_d ;        
          enable_hashtag <= enable_hashtag_d ;
          enable_openocd <= enable_openocd_d ;
        end

    assign register_adr = {PADDR[2:0]};
    // APB logic: we are always ready to capture the data into our regs
    // not supporting transfare failure
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
    
// ************ Smart-UART side messages logic ***********************************//
 
  // RX
  
   // Notice Master command support both ascii and value messages
  
   logic [3:0] su_cmd_rx_cntdown , su_cmd_rx_cntdown_d;
   logic su_cmd_rx_detected, su_cmd_rx_cntdown_expired ;
   
   wire capture_su_cmd =   enable_smart_uart && rx_valid && su_cmd_rx_cntdown_expired ;

   wire su_cmd_wr_word     = capture_su_cmd && (rx_data == `SU_CMD_WR_WORD      ) ;
   wire su_cmd_wr_halfword = capture_su_cmd && (rx_data == `SU_CMD_WR_HALFWORD  ) ;
   wire su_cmd_wr_byte     = capture_su_cmd && (rx_data == `SU_CMD_WR_BYTE      ) ;
   wire su_cmd_rd_word     = capture_su_cmd && (rx_data == `SU_CMD_RD_WORD      ) ;
   wire su_cmd_rd_numwords = capture_su_cmd && (rx_data == `SU_CMD_RD_NUMWORDS  ) ;
   
   // Logic to capture master ascii command from"#" to line feed
   
   logic su_master_ascii_cmd ;   
   wire su_master_ascii_cmd_done = su_master_ascii_cmd && (rx_valid && (rx_data==8'h0A)) ;   
   wire su_master_ascii_cmd_d =    (enable_smart_uart && enable_hashtag && (!su_rx_non_ascii_msg_on) && rx_valid && (rx_data=="#")) 
                                || (su_master_ascii_cmd && !su_master_ascii_cmd_done) ;

   always_ff @(posedge CLK, negedge RSTN)
     if(~RSTN)  su_master_ascii_cmd<= 0 ; else su_master_ascii_cmd <= su_master_ascii_cmd_d ; 

   logic su_master_ascii_cmd_rd , su_master_ascii_cmd_wr ;        
   wire su_master_ascii_cmd_rd_d = (su_master_ascii_cmd_rd || (su_master_ascii_cmd && rx_valid && (rx_data=="r"))) && !remote_access_intrfc.rsp_valid ;  // !cmd_valid  ;
   wire su_master_ascii_cmd_wr_d = (su_master_ascii_cmd_wr || (su_master_ascii_cmd && rx_valid && (rx_data=="w"))) && !remote_access_intrfc.rsp_valid ;  // !cmd_valid  ;
 
    always_ff @(posedge CLK, negedge RSTN)
     if(~RSTN)  begin
       su_master_ascii_cmd_rd <= 0 ; 
       su_master_ascii_cmd_wr <= 0 ;        
     end else begin
      su_master_ascii_cmd_rd <= su_master_ascii_cmd_rd_d ; 
      su_master_ascii_cmd_wr <= su_master_ascii_cmd_wr_d ;       
     end
     
    wire rx_data_ascii_is_0_to_9 = ((rx_data>="0")&&(rx_data<="9")) ;
    wire rx_data_ascii_is_a_to_f = ((rx_data>="a")&&(rx_data<="f")) ;  
    wire [7:0] conv_ascii_rx_nibble_val  =  rx_data_ascii_is_0_to_9 ? (rx_data - "0") : 10+(rx_data - "a") ;
        
    wire conv_ascii_rx = rx_valid && (su_master_ascii_cmd_rd || su_master_ascii_cmd_wr) 
                                  && (rx_data_ascii_is_0_to_9 || rx_data_ascii_is_a_to_f) ;
   
    
    logic[63:0] conv_ascii_rx_cmd_addr_data_val ; 
    logic [3:0] conv_ascii_rx_nibble_idx ;
    logic conv_addr_not_data ;

    
    always_ff @(posedge CLK, negedge RSTN)
     if(~RSTN)  begin
        conv_ascii_rx_cmd_addr_data_val  <= 0 ; 
        conv_ascii_rx_nibble_idx <= 0 ; 
        conv_addr_not_data <= 0 ;        
     end else begin
        if (conv_ascii_rx) begin
          if (conv_addr_not_data) conv_ascii_rx_cmd_addr_data_val[63:32] <= {conv_ascii_rx_cmd_addr_data_val[59:32],conv_ascii_rx_nibble_val[3:0]} ;   
          else conv_ascii_rx_cmd_addr_data_val[31:0]  <= {conv_ascii_rx_cmd_addr_data_val[27:0],conv_ascii_rx_nibble_val[3:0]} ;  
          conv_ascii_rx_nibble_idx <= conv_ascii_rx_nibble_idx+1;  
        end 
        if (su_master_ascii_cmd_done_s) begin
          conv_ascii_rx_cmd_addr_data_val <= 0 ;  
          conv_addr_not_data <= 0 ;
        end
        if (su_master_ascii_cmd && rx_valid && rx_data==" ") conv_addr_not_data <= ~conv_addr_not_data ;     
     end
      
    
    wire conv_ascii_rx_valid_d = conv_ascii_rx && (conv_ascii_rx_nibble_idx==0) ;
    logic conv_ascii_rx_valid ;
    always_ff @(posedge CLK, negedge RSTN)
     if(~RSTN) conv_ascii_rx_valid  <= 0 ; else conv_ascii_rx_valid <= conv_ascii_rx_valid_d ; 
    
   
   // Logic to capture Master value provide commands 

   logic [3:0] su_cmd_rx_set_byte_cntdown ; 

      
   assign su_cmd_rx_set_byte_cntdown = (su_cmd_wr_word      ?  4'd8 : (
                                        su_cmd_wr_halfword  ?  4'd6 : (
                                        su_cmd_wr_byte      ?  4'd5 : (
                                        su_cmd_rd_word      ?  4'd4 : (
                                        su_cmd_rd_numwords  ?  4'd5 : 4'd0))))) ; // TBD cmd_rd_numwords actually  currently not supported supported here
                                                                                  // Implemented by multiple cmd_rd_word
   assign su_cmd_rx_detected = (su_cmd_rx_set_byte_cntdown != 4'd0) ;
   

   assign su_cmd_rx_cntdown_expired = (su_cmd_rx_cntdown==4'd0) ;

   assign su_cmd_rx_cntdown_d = (su_cmd_rx_cntdown_expired) ? su_cmd_rx_set_byte_cntdown : 
                                   (rx_valid ? su_cmd_rx_cntdown-1 : su_cmd_rx_cntdown) ; 
   
   always_ff @(posedge CLK, negedge RSTN)
     if(~RSTN) su_cmd_rx_cntdown <= 0 ; else su_cmd_rx_cntdown <= su_cmd_rx_cntdown_d ;
   
   assign su_rx_non_ascii_msg_on = su_cmd_rx_detected || !su_cmd_rx_cntdown_expired ;   
   assign su_rx_ascii_msg_on = su_master_ascii_cmd || su_master_ascii_cmd_d ;   
  
   assign su_rx_msg_on =  su_rx_non_ascii_msg_on || su_rx_ascii_msg_on ;
                                                                                  
   logic cmd_wr_word_s       ; 
   logic cmd_wr_halfword_s   ;
   logic cmd_wr_byte_s       ; 
   logic cmd_rd_word_s       ;    
   logic cmd_rd_numwords_s   ;   
   logic [7:0][7:0] cmd_addr_data ;
   
   always @(posedge CLK, negedge RSTN) 
   if(~RSTN) 
   begin
    cmd_wr_word_s      <= 0  ;
    cmd_wr_halfword_s  <= 0  ;
    cmd_wr_byte_s      <= 0  ;
    cmd_rd_word_s      <= 0  ;
    cmd_rd_numwords_s  <= 0  ;        
   end else begin
    if (su_cmd_rx_detected) begin
       cmd_wr_word_s      <= su_cmd_wr_word     ; 
       cmd_wr_halfword_s  <= su_cmd_wr_halfword ; 
       cmd_wr_byte_s      <= su_cmd_wr_byte     ; 
       cmd_rd_word_s      <= su_cmd_rd_word     ; 
       cmd_rd_numwords_s  <= su_cmd_rd_numwords ;
    end else if (su_master_ascii_cmd)  begin
       cmd_wr_word_s      <= 0 ; 
       cmd_wr_halfword_s  <= 0 ; 
       cmd_wr_byte_s      <= 0 ; 
       cmd_rd_word_s      <= 0 ; 
       cmd_rd_numwords_s  <= 0 ;       
    end    
   end
                                         
   

 
 
   
  
   logic [3:0] cmd_addr_data_idx ;
   
   wire update_cmd_addr_data = conv_ascii_rx_valid || (rx_valid && !su_cmd_rx_cntdown_expired)  ;
   
   always @(posedge CLK, negedge RSTN) 
      if(~RSTN) begin
        cmd_addr_data  <= 64'd0 ;
        cmd_addr_data_idx <= 7 ;
      end
      else if (update_cmd_addr_data) 
      begin
       cmd_addr_data[cmd_addr_data_idx] <= rx_data ;
       cmd_addr_data_idx <=  cmd_addr_data_idx-1 ;
      end
      else if (su_cmd_rx_cntdown_expired || su_master_ascii_cmd_done) begin
        cmd_addr_data_idx <= 7 ;
        cmd_addr_data  <= 64'd0 ;
      end
   

   always @(posedge CLK, negedge RSTN) 
       if(~RSTN) su_master_ascii_cmd_done_s <=0 ; else su_master_ascii_cmd_done_s <= su_master_ascii_cmd_done ;

   always @(posedge CLK, negedge RSTN) 
   if(~RSTN) cmd_valid <=0 ; else cmd_valid <= (  (rx_valid && (su_rx_msg_on && (su_cmd_rx_cntdown==4'd1)))  // Last byte captured , cmd is valid  
                                                || su_master_ascii_cmd_done);                                
                                                 
   assign {remote_access_intrfc.cmd_addr,remote_access_intrfc.cmd_data} = su_master_ascii_cmd_done_s ? conv_ascii_rx_cmd_addr_data_val : cmd_addr_data ;
   assign remote_access_intrfc.cmd_wr_word       =  cmd_wr_word_s  || su_master_ascii_cmd_wr    ;
   assign remote_access_intrfc.cmd_wr_halfword   =  cmd_wr_halfword_s  ;
   assign remote_access_intrfc.cmd_wr_byte       =  cmd_wr_byte_s      ; 
   assign remote_access_intrfc.cmd_rd_word       =  cmd_rd_word_s || su_master_ascii_cmd_rd     ;
   assign remote_access_intrfc.cmd_rd_numwords   =  cmd_rd_numwords_s  ;
   assign remote_access_intrfc.cmd_valid         =  cmd_valid  ;  





// TX

 logic su_tx_msg_on_d , su_tx_msg_on_is_rd_ascii , su_tx_msg_on_is_wr_ascii ;
 logic su_tx_msg_on_is_rd_ascii_d , su_tx_msg_on_is_wr_ascii_d;
 
 logic [3:0] su_cmd_tx_cntdown , su_cmd_tx_cntdown_d ;
  wire cmd_rsp_expected = cmd_rd_word_s || cmd_rd_numwords_s || su_master_ascii_cmd_rd  || su_master_ascii_cmd_wr;
 
 
 
 always_comb
 begin
  su_tx_msg_on_d = su_tx_msg_on ;
  su_tx_msg_on_is_rd_ascii_d = su_tx_msg_on_is_rd_ascii ;
  su_tx_msg_on_is_wr_ascii_d = su_tx_msg_on_is_wr_ascii ;  
  
  if (remote_access_intrfc.rsp_valid && cmd_rsp_expected) begin
     su_tx_msg_on_d = 1 ;
     if (su_master_ascii_cmd_rd) su_tx_msg_on_is_rd_ascii_d = 1 ; 
     if (su_master_ascii_cmd_wr) su_tx_msg_on_is_wr_ascii_d = 1 ;      
  end 
  if ((su_cmd_tx_cntdown==4'd0) && tx_uart_ready_out && su_tx_msg_on) begin
    su_tx_msg_on_d = 0 ;
    su_tx_msg_on_is_rd_ascii_d = 0 ;
    su_tx_msg_on_is_wr_ascii_d = 0 ;    
  end
 end
 
 always @(posedge CLK, negedge RSTN) 
   if(~RSTN) su_tx_msg_on <= 0 ; else su_tx_msg_on <= su_tx_msg_on_d ;
   
 always @(posedge CLK, negedge RSTN) 
   if(~RSTN) su_tx_msg_on_is_rd_ascii <= 0 ; else su_tx_msg_on_is_rd_ascii <= su_tx_msg_on_is_rd_ascii_d ;

 always @(posedge CLK, negedge RSTN) 
   if(~RSTN) su_tx_msg_on_is_wr_ascii <= 0 ; else su_tx_msg_on_is_wr_ascii <= su_tx_msg_on_is_wr_ascii_d ;



 always_comb
 begin
  su_cmd_tx_cntdown_d =  su_cmd_tx_cntdown;
  if (remote_access_intrfc.rsp_valid) begin
    if (su_tx_msg_on_is_rd_ascii_d) su_cmd_tx_cntdown_d = 8 ;  // returning 9 (8..0) bytes of 8 nibble ascii  to uart terminal including the line-feed
    else if (su_tx_msg_on_is_wr_ascii_d) su_cmd_tx_cntdown_d = 0 ;  // returning just line-feed    
    else su_cmd_tx_cntdown_d = 4 ;  // returning 5 bytes (4..0) , to Testbench/Smart terminal , 4  SU_CMD_RSP header byte + 4 value bytes
  end
  if (su_tx_msg_on && tx_uart_ready_out) su_cmd_tx_cntdown_d = su_cmd_tx_cntdown - 1 ;
 end
 
 logic [31:0] rsp_data ;
 always @(posedge CLK, negedge RSTN) 
    if(~RSTN) rsp_data <= 0 ; 
    else if (remote_access_intrfc.rsp_valid) rsp_data <= remote_access_intrfc.rsp_data ;
    
 //logic [7:0] rsp_ascii_nibble ;   TBC
 //logic [7:0] rsp_ascii_nibble_idx ; 
 
 wire [7:0] rsp_data_byte = (su_tx_msg_on_is_rd_ascii||su_tx_msg_on_is_wr_ascii) ? 
                                       ((su_cmd_tx_cntdown==0) ? 8'h0A   // return line feed 
                                                               : nibble_hex_ascii(rsp_data[(su_cmd_tx_cntdown-1)*4+:4])) 
                            :  rsp_data[su_cmd_tx_cntdown*8+:8] ;
                            
                             
                                                        

 assign  su_tx_data_byte = (su_cmd_tx_cntdown==4 &&!su_tx_msg_on_is_rd_ascii) ? `SU_CMD_RSP : rsp_data_byte ;
 assign  su_tx_data_byte_valid = (su_tx_msg_on && tx_uart_ready_out) ;
 
 
 always @(posedge CLK, negedge RSTN) 
   if(~RSTN) su_cmd_tx_cntdown <= 0 ; else su_cmd_tx_cntdown <=  su_cmd_tx_cntdown_d ;

 //------------------------------------------------------------------------------
  
 function [7:0] nibble_hex_ascii ;
     input [3:0] nibble ; 
      nibble_hex_ascii = (nibble<=9) ? "0" + nibble : "a" +(nibble - 10) ;
 endfunction  
                       
 assign ocd_rx_valid = rx_valid && enable_openocd;
 assign ocd_rx_data  = rx_data;
 assign ocd_tx_ready = enable_openocd && tx_uart_ready_out;
 openocd_bitbang openocd_bitbang(
    .clk(CLK),
    .rstn(RSTN),

    .rx_valid     ( ocd_rx_valid ),
    .rx_data      ( ocd_rx_data  ),
    .rx_ready     ( ocd_rx_ready ),
    
    .tx_valid     ( ocd_tx_valid ),
    .tx_data      ( ocd_tx_data  ),
    .tx_ready     ( ocd_tx_ready ),

    .openocd_jtag ( openocd_jtag )
 );
endmodule
