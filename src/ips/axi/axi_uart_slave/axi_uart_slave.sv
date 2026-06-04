`include "axi_bus.sv"
//`include "../soc/includes/smart_uart_defines.sv"
//`include "../soc/includes/remote_access_intrfc.sv"
`include "smart_uart_defines.sv"
//`include "remote_access_intrfc.sv"

module axi_uart_slave    // meaning: UART interface master on AXI (confusing...)
#(
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_DATA_WIDTH    = 64,   
    parameter AXI_ID_WIDTH      = 16,
    parameter AXI_USER_WIDTH    = 10,
    parameter REGISTERED_GRANT = "FALSE"
  )
(
    input logic              clk_i,
    input logic              rst_ni,
 
    AXI_BUS.Master           axi_master,
    
    REMOTE_ACCESS_INTRFC.near   remote_access_intrfc 

);

    localparam AXI4_RDATA_WIDTH = AXI_DATA_WIDTH;
    localparam AXI4_WDATA_WIDTH = AXI_DATA_WIDTH;


    logic                      data_req;
    logic                      data_gnt;
    logic                      data_rvalid;
    logic [AXI_ADDR_WIDTH-1:0] data_addr;
    logic                      data_we;
    logic [3:0]                data_be;
    logic [31:0]               data_rdata;
    logic [31:0]               data_wdata;
    
    logic                      data_we_d;      
    logic [AXI_ADDR_WIDTH-1:0] data_addr_d ;   
    logic [AXI_ADDR_WIDTH-1:0] data_wdata_d ; 

    logic                      data_we_s;      
    logic [AXI_ADDR_WIDTH-1:0] data_addr_s ;   
    logic [AXI_ADDR_WIDTH-1:0] data_wdata_s ; 
    
        
    
    assign data_be    = 4'b1111 ;                       // TMP  -- Need to support half/byte access
    
    logic data_req_d , data_req_s ;
    
    always_comb  
    begin
       data_req_d = data_req_s ;
       
       data_addr_d  = data_addr ;
       data_wdata_d = data_wdata ;
       data_we_d    = data_we ;   
       
       if (remote_access_intrfc.cmd_valid) begin
       
        data_req_d = 1 ;     
        
        data_addr_d  = remote_access_intrfc.cmd_addr ;
        data_wdata_d = remote_access_intrfc.cmd_data ;
        data_we_d    = remote_access_intrfc.cmd_wr_word ;         
       end         
       if (data_gnt) data_req_d = 0 ;  
    end
    
    always_ff @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin 
       data_req_s <= 0 ;
       data_addr_s  <=  0 ;
       data_wdata_s <=  0 ;
       data_we_s    <=  0 ;               
      end else begin
       data_req_s <= data_req_d ;
       data_addr_s  <= data_addr_d ;
       data_wdata_s <= data_wdata_d ;
       data_we_s    <= data_we_d ;               
      end
    end
    
    assign data_req = remote_access_intrfc.cmd_valid || data_req_s ;
    assign data_addr  = remote_access_intrfc.cmd_valid ? data_addr_d     : data_addr_s ;
    assign data_wdata = remote_access_intrfc.cmd_valid ? data_wdata_d    : data_wdata_s ;    
    assign data_we    = remote_access_intrfc.cmd_valid ? data_we_d       : data_we_s ;      
    
    assign remote_access_intrfc.rsp_data = data_rdata ;
    assign remote_access_intrfc.rsp_valid = data_rvalid ;

  // AXI_BUS
  // #(
  //   .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH      ),
  //   .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH      ),
  //   .AXI_ID_WIDTH     ( AXI_ID_WIDTH        ),
  //   .AXI_USER_WIDTH   ( AXI_USER_WIDTH      )
  // )
  // axi_master_int(); 

 enum logic [2:0] { IDLE, READ_WAIT, WRITE_DATA, WRITE_ADDR, WRITE_WAIT } CS, NS;

  logic [31:0]  rdata;
  logic         valid;
  logic         granted;

  // main FSM
  always_comb
  begin
    NS         = CS;
    granted    = 1'b0;
    valid      = 1'b0;

    axi_master.aw_valid = 1'b0;
    axi_master.ar_valid = 1'b0;
    
    axi_master.r_ready  = 1'b0;
    axi_master.w_valid  = 1'b0;
    axi_master.b_ready  = 1'b0;

    case (CS)
      // wait for a request to come in from the core
      IDLE: begin
        // the same logic is also inserted in READ_WAIT and WRITE_WAIT, if you
        // change it here, take care to change it there too!
        if (data_req)
        begin
          // send address over aw channel for writes,
          // over ar channels for reads
          if (data_we)
          begin
            axi_master.aw_valid = 1'b1;
            axi_master.w_valid  = 1'b1;

            if (axi_master.aw_ready) begin
              if (axi_master.w_ready) begin
                granted = 1'b1;
                NS = WRITE_WAIT;
              end else begin
                NS = WRITE_DATA;
              end
            end else begin
              if (axi_master.w_ready) begin
                NS = WRITE_ADDR;
              end else begin
                NS = IDLE;
              end
            end
          end else begin
            axi_master.ar_valid = 1'b1;

            if (axi_master.ar_ready) begin
              granted = 1'b1;
              NS = READ_WAIT;
            end else begin
              NS = IDLE;
            end
          end
        end else begin
          NS = IDLE;
        end
      end

      // if the bus has not accepted our write data right away, but has
      // accepted the address already
      WRITE_DATA: begin
        axi_master.w_valid = 1'b1;
        if (axi_master.w_ready) begin
          granted = 1'b1;
          NS = WRITE_WAIT;
        end
      end

      // the bus has accepted the write data, but not yet the address
      // this happens very seldom, but we still have to deal with the
      // situation
      WRITE_ADDR: begin
        axi_master.aw_valid = 1'b1;

        if (axi_master.aw_ready) begin
          granted = 1'b1;
          NS = WRITE_WAIT;
        end
      end

      // we have sent the address and data and just wait for the write data to
      // be done
      WRITE_WAIT:
      begin
        axi_master.b_ready = 1'b1;

        if (axi_master.b_valid)
        begin
          valid = 1'b1;

          NS = IDLE;
        end
      end

      // we wait for the read response, address has been sent successfully
      READ_WAIT:
      begin
        if (axi_master.r_valid)
        begin
          valid     = 1'b1;
          axi_master.r_ready = 1'b1;

          NS = IDLE;
        end
      end

      default:
      begin
        NS = IDLE;
      end
    endcase
  end

  // registers
  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if (~rst_ni)
    begin
      CS     <= IDLE;
    end
    else
    begin
      CS     <= NS;
    end
  end

  // take care of read data adaption
  generate if (AXI4_RDATA_WIDTH == 32) begin : axi32
      assign rdata = axi_master.r_data[31:0];
    end else if (AXI4_RDATA_WIDTH == 64) begin : axi64
      logic [0:0] addr_q;

      always_ff @(posedge clk_i, negedge rst_ni)
      begin
        if (~rst_ni)
          addr_q <= '0;
        else
          if (data_gnt) // only update when we give the grant
            addr_q <= data_addr[2:2];
      end

      assign rdata = addr_q[0] ? axi_master.r_data[63:32] : axi_master.r_data[31:0];
    end else begin
      `ifndef SYNTHESIS
      initial $error("AXI4_WDATA_WIDTH has an invalid value");
      `endif
    end
  endgenerate

  // take care of write data adaption
  generate
    genvar w;
    for(w = 0; w < AXI4_WDATA_WIDTH/32; w++) begin : axidiv32
      assign axi_master.w_data[w*32 + 31:w*32 + 0] = data_wdata; // just replicate the wdata to fill the bus
    end
  endgenerate

  // take care of write strobe
  generate if (AXI4_WDATA_WIDTH == 32) begin : axieql32
      assign axi_master.w_strb = data_be;
    end else if (AXI4_WDATA_WIDTH == 64) begin : axieql64
      assign axi_master.w_strb = data_addr[2] ? {data_be, 4'b0000} : {4'b0000, data_be};
    end else begin  : axiother
      `ifndef SYNTHESIS
      initial $error("AXI4_WDATA_WIDTH has an invalid value");
      `endif
    end
  endgenerate

  // AXI interface assignments
  assign axi_master.aw_id     = '0;
  assign axi_master.aw_addr   = data_addr;
  assign axi_master.aw_size = 3'b010;
  assign axi_master.aw_len    = '0;
  assign axi_master.aw_burst  = '0;
  assign axi_master.aw_lock   = '0;
  assign axi_master.aw_cache  = '0;
  assign axi_master.aw_prot   = '0;
  assign axi_master.aw_region = '0;
  assign axi_master.aw_user   = '0;
  assign axi_master.aw_qos    = '0;

  assign axi_master.ar_id    = '0;
  assign axi_master.ar_addr   = data_addr;
  assign axi_master.ar_size  = 3'b010;
  assign axi_master.ar_len    = '0;
  assign axi_master.ar_burst  = '0;
  assign axi_master.ar_prot   = '0;
  assign axi_master.ar_region = '0;
  assign axi_master.ar_lock   = '0;
  assign axi_master.ar_cache  = '0;
  assign axi_master.ar_qos    = '0;
  assign axi_master.ar_user   = '0;

  assign axi_master.w_last   = 1'b1;
  assign axi_master.w_user    = '0;

  generate if (REGISTERED_GRANT == "TRUE")
    begin : axrg // label added by Udi 28/Feb/2019 required by Quartus
      logic        valid_q;
      logic [31:0] rdata_q;

      always_ff @(posedge clk_i, negedge rst_ni)
      begin
        if (~rst_ni) begin
          valid_q <= 1'b0;
          rdata_q <= '0;
        end
        else
        begin
          valid_q <= valid;

          if (valid)
            rdata_q <= rdata;
        end
      end

      assign data_rdata  = rdata_q;
      assign data_rvalid = valid_q;
      assign data_gnt    = valid;
    end
    else
    begin
      assign data_rdata  = rdata;
      assign data_rvalid = valid;
      assign data_gnt    = granted;
    end
  endgenerate
  
 
endmodule
