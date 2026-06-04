// Description	: Reset sample to be instantiated in each layout macro
//                NOTE: not needed with Ceragon style reset
//                NOTE: This is *NOT* a reset synchronizer
//                When 'test_mode' is high - sample is bypassed
//                Note: There is NO aoutomatic false path on rstn_i 
//                  
//
// test--------------\
//          -----    |
//    1'b1--|   |   |\
//          |   |---| |
// clk -----|>  |   | |------>
//          --o-- /-| |
//            |   | |/
//            |   |   
// rstn_i ----+---/
// Revision	: 0.1
//
//------------------------------------------------------------------------------

module reset_sample (
    input wire  clk,
    input wire  rstn_i,
    input wire  test_mode,
    output wire rstn_o
);

wire 	ff;
m_ff_arst  ff_inst (.D(1'b1),   .CK(clk),      .RN(rstn_i),      .Q(ff));
m_mx2      rst_mux (.A(ff) ,    .B(rstn_i),    .S(test_mode),    .Z(rstn_o));
   
endmodule //reset_sample
