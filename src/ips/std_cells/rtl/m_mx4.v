`undef STD_DEFINED
module m_mx4( input A, input B, input C, input D, input [1:0] S, output Z);

`ifdef STD_SIM
    `define USE_3_MUXES
    `define STD_DEFINED
`elsif TSMC_65
    `define USE_3_MUXES
    `define STD_DEFINED
`elsif TSMC16
    `define USE_3_MUXES
    `define STD_DEFINED
`endif

`ifdef USE_3_MUXES
    wire   Z0, Z1;
    m_mx2 i_clk_mx2_0 (.A(A),  .B(B),  .S(S[0]), .Z(Z0));
    m_mx2 i_clk_mx2_1 (.A(C),  .B(D),  .S(S[0]), .Z(Z1));
    m_mx2 i_clk_mx2_2 (.A(Z0), .B(Z1), .S(S[1]), .Z(Z));
    `undef USE_3_MUXES
`endif

endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
