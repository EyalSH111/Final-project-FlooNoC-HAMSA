
// Pseudo DDR interface for supporting for fast simulation. (Altera DDR model is heavy)

module sim_psd_ddr_intrfc # (    
    parameter DDR_ADDR_WIDTH = 26,
    parameter DDR_DATA_WIDTH = 128
) (

input                            phy_clk,
input                            rst_n,
output                           local_init_done,
input      [DDR_ADDR_WIDTH-1:0]  local_address,
input                            local_burstbegin,
output reg                       local_ready,
input                            local_read_req,
output reg [DDR_DATA_WIDTH-1:0]  local_rdata,
output reg                       local_rdata_valid,
input                            local_write_req,
input       [DDR_DATA_WIDTH-1:0] local_wdata

) ;
assign local_init_done  = 1 ; // Pseudo always fast init done

localparam DDR_DEPTH = 2**DDR_ADDR_WIDTH ; // Number of DDR memory lines each of  DDR_DATA_WIDTH

reg [DDR_DATA_WIDTH-1:0] mem [DDR_DEPTH-1:0] ;

always @(posedge phy_clk or negedge rst_n) begin

   if (!rst_n) begin
       local_ready <= 0 ;
       local_rdata_valid <= 0 ;

   end else begin

       if (local_write_req) begin
         mem[local_address] <= local_wdata ;
         local_ready <= 1 ;
       end else begin
         local_ready <= 0 ;
       end
       
       if (local_read_req) begin
         local_rdata <= mem[local_address]  ;
         local_rdata_valid <= 1 ;
       end else begin
         local_rdata_valid <= 0 ;
       end
   
   end

end 


endmodule





