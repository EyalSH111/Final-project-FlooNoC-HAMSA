module spi_slave_native(
input  wire        test_mode              ,//           
input  wire        clk_slow               ,// clock for DFT
input  wire        sel_clk_spisn_pos      ,//select clk_spisn to be positive. def=neg
//SPI Native 2 Regf
output wire        clk_native_wr          ,//clock to write out_regs
output reg  [ 7:0] a_native2regf          ,//address to select reg
output reg  [15:0] d_native2regf          ,//data in for out_regs
input  wire [15:0] d_regf2native          ,//data out from reg_file 2 native SPI
//SPI NATIVE IF                       
input  wire        clk_spim_din2_spisn    ,//clock to read inp_regs
input  wire        pad_spim_din3_spisn_di ,//          
output reg         pad_spin_do            ,//     
input  wire        pad_spin_cs             //
);
 
wire clk_native_int;
m_mx2 m_mx2_clk (.A(clk_spim_din2_spisn), .B(clk_slow), .S0(test_mode),  .Y(clk_native_int)) ;

wire sel_clk_spisn_pos_tst = sel_clk_spisn_pos || test_mode;
wire clk_native_neg, clk_spim_din2_spisn_n;
m_inv   m_inv1    (.A(clk_spim_din2_spisn), .Y(clk_spim_din2_spisn_n));
m_mx2 m_mx2_clk_n (.A(clk_spim_din2_spisn_n), .B(clk_native_int), .S0(sel_clk_spisn_pos_tst), .Y(clk_native_neg)) ;


//assign clk_native_wr = !rd && pad_spin_cs ;
//?? Asynch reset pad_spin_cs becomes a clock:
// ?? Is there a way to do it by usung it only as Aync??
reg        rd ;
//reg clk_native_wr_s;
//always @(posedge clk_native_int or negedge pad_spin_cs)
//if (!pad_spin_cs)  clk_native_wr_s   <=#1 1'd0 ;
//else  if (!rd)     clk_native_wr_s   <=#1 1'd1 ; 
//else               clk_native_wr_s   <=#1 1'd0 ; 
//assign clk_native_wr = clk_native_wr_s;
m_and m_and_clk_native_wr (.A(!rd), .B(pad_spin_cs), .Y(clk_native_wr));

//bit 26 = 0=WR 1=RD
//bit 25-18 = Address
//bit 17-16 = Dont care
//bit 15-0 = Data 

reg  [26:0] internal_spi_SR    ;
reg  [ 5:0] bit_cntr ;
 
always @(posedge clk_native_int or posedge pad_spin_cs)
  if (pad_spin_cs) bit_cntr <=#1 6'd0 ;
  else bit_cntr <=#1 bit_cntr + 1'b1 ;

always @(posedge clk_native_int)
  if (bit_cntr=='d0) rd <=#1 pad_spim_din3_spisn_di ;

always @(posedge clk_native_int or posedge pad_spin_cs)
  if (pad_spin_cs) internal_spi_SR <=#1 27'd0 ;
  else if (rd && bit_cntr==6'd10) internal_spi_SR <=#1 {11'd0,d_regf2native} ;
  else internal_spi_SR <=#1 {internal_spi_SR[25:0],pad_spim_din3_spisn_di} ;

always @(posedge clk_native_int)
  if (bit_cntr==6'd9) a_native2regf <=#1 internal_spi_SR[7:0] ;

always @(posedge clk_native_int)
  d_native2regf <=#1 {internal_spi_SR[14:0],pad_spim_din3_spisn_di} ;


//always @(negedge clk_native_int)
always @(posedge clk_native_neg)
  if (bit_cntr>='d11) pad_spin_do <=#1 internal_spi_SR[15] ;
  else pad_spin_do <=#1 1'b0 ;

endmodule







 