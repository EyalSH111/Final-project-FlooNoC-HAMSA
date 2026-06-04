`timescale 1ns / 100 ps

module gp_dma_regs (/*autoarg*/
   // Outputs
   slave_cbus_rdata, slave_cbus_aerror, source_address, source_amode,
   dest_address, dest_amode, burst_mode, byte_count, pri, dma_pending,
   done_intr,
   // Inputs
   cbus_clk, cbus_rst_n, slave_cbus_address, slave_cbus_wdata,
   slave_cbus_byten, slave_cbus_cmd, slave_cbus_req, active, dma_done,
   inc_source_address, inc_dest_address, dec_byte_count, address_p4,
   byte_count_m1
   );

input         cbus_clk;
input         cbus_rst_n;
   
input   [3:0] slave_cbus_address;
input  [31:0] slave_cbus_wdata;
input   [3:0] slave_cbus_byten;
input         slave_cbus_cmd;
input         slave_cbus_req;
output [31:0] slave_cbus_rdata;
output        slave_cbus_aerror;

input         active;
input         dma_done;
input         inc_source_address;
input         inc_dest_address;
input         dec_byte_count;
input  [31:0] address_p4;
input  [17:0] byte_count_m1;

output [31:0] source_address;
output  [1:0] source_amode;
output [31:0] dest_address;
output  [1:0] dest_amode;
output  [1:0] burst_mode;
output [17:0] byte_count;      
output  [2:0] pri;
output        dma_pending;
output        done_intr;

parameter SRC_ADDR  = 4'd0,
          DEST_ADDR = 4'd1,
          CTRL      = 4'd2;
// Addresses 3 - 15 are reserved

reg         aerror_int;
reg  [31:0] muxed_reg_data;
wire [31:0] slave_cbus_rdata         = muxed_reg_data;
wire        slave_cbus_aerror        = aerror_int && slave_cbus_req ;
   
wire [31:0] write_data;
   
reg  [31:0] source_address;
reg  [31:0] dest_address;
reg  [17:0] byte_count;
reg   [2:0] pri;
reg         dma_pending;
   
reg   [1:0] source_amode;
reg   [1:0] dest_amode;
reg   [1:0] burst_mode;

//==================================================================
// Values returned by a READ from the control register
//==================================================================
wire [31:0] ctrl_reg;
assign ctrl_reg[31]    = dma_pending;
assign ctrl_reg[30]    = active;
assign ctrl_reg[29]    = 1'b0;
assign ctrl_reg[28:26] = pri;
assign ctrl_reg[25:24] = dest_amode;
assign ctrl_reg[23:22] = source_amode;
assign ctrl_reg[21:20] = burst_mode;
assign ctrl_reg[19:18] = 2'd0;
assign ctrl_reg[17:0]  = byte_count;
   
//==================================================================
// Write Data Multiplexer
//==================================================================
assign  write_data[31:24] = (slave_cbus_byten[3]) ? slave_cbus_wdata[31:24] : muxed_reg_data[31:24];
assign  write_data[23:16] = (slave_cbus_byten[2]) ? slave_cbus_wdata[23:16] : muxed_reg_data[23:16];
assign  write_data[15:8]  = (slave_cbus_byten[1]) ? slave_cbus_wdata[15:8]  : muxed_reg_data[15:8];
assign  write_data[7:0]   = (slave_cbus_byten[0]) ? slave_cbus_wdata[7:0]   : muxed_reg_data[7:0];

//==================================================================
// Read Data Multiplexer and Address error generator
//==================================================================
always @ (*)
begin
  aerror_int = 1'b0;
  case (slave_cbus_address)
    SRC_ADDR:    muxed_reg_data = source_address;
    DEST_ADDR:   muxed_reg_data = dest_address;
    CTRL:        muxed_reg_data = ctrl_reg; 
    default: 
      begin
        muxed_reg_data = 32'd0;
        aerror_int = 1'b1; 
     end
  endcase 
end

//==================================================================
// Write Process
//==================================================================
always @ (posedge cbus_clk)
begin
  if (!cbus_rst_n)
    begin
      source_address <= 32'd0;
      dest_address   <= 32'd0;
      byte_count     <= 18'd0;
      dma_pending    <= 1'b0;
      source_amode   <= 2'd0;
      dest_amode     <= 2'd0;
      burst_mode     <= 2'd0;
      pri            <= 3'd7;
    end
  else
    begin
      // Source Address Register
      if (slave_cbus_req && !slave_cbus_cmd && (slave_cbus_address == SRC_ADDR))
        begin
          source_address <= write_data;
        end
      else if (inc_source_address)
        begin
          source_address <= address_p4;
        end

      // Destination Address Register
      if (slave_cbus_req && !slave_cbus_cmd && (slave_cbus_address == DEST_ADDR))
        begin
          dest_address   <= write_data;
        end
      else if (inc_dest_address)
        begin
          dest_address   <= address_p4; 
        end

      // DMA Control Register
      if (slave_cbus_req && !slave_cbus_cmd && (slave_cbus_address == CTRL))
        begin                               
          dma_pending  <= write_data[31] && !(write_data[17:0] == 18'd0);
          pri          <= write_data[28:26];
          dest_amode   <= write_data[25:24];
          source_amode <= write_data[23:22];
          burst_mode   <= write_data[21:20];
          byte_count   <= write_data[17:0];
        end
      else 
        begin
          if (dec_byte_count)
            byte_count  <= byte_count_m1;
          if (dma_done) 
            dma_pending <= 1'b0;
        end 
    end
end

wire intr_int = dma_done && dma_pending;
reg  done_intr;
   
//==================================================================
// Interrupt on dma done
//==================================================================
always @ (posedge cbus_clk)
begin
  if (!cbus_rst_n)
    done_intr <= 0;
  else 
    done_intr <= intr_int;
end 

endmodule
