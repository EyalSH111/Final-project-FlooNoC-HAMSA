`undef STD_DEFINED
module m_xnor( input A, input B, output ZN);

`ifdef STD_SIM
    `define STD_DEFINED
    assign ZN = !(A ^ B);

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
    `define STD_DEFINED
    XNOR2_X1M_A9TR i_xnor (.Y(ZN), .A(A), .B(B));

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
 `define STD_DEFINED
 `define I_CLK_XOR2 I_clk_xor2 (.A1(A), .A2(B), .Z(Z))
 `define I_CLK_INV I_clk_inv (.I(Z), .ZN(ZN))

   wire   Z;
 `ifdef CTS_ULVT
   CKXOR2D1BWP16P90CPDULVT `I_CLK_XOR2;
   CKND2BWP16P90CPDULVT `I_CLK_INV;
 `elsif CTS_LVT
   CKXOR2D1BWP16P90CPDLVT `I_CLK_XOR2;
   CKND2BWP16P90CPDLVT `I_CLK_INV;
 `else
   CKXOR2D1BWP16P90CPD `I_CLK_XOR2;
   CKND2BWP16P90CPD `I_CLK_INV;
 `endif

 `undef I_CLK_XOR2
 `undef I_CLK_INV

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
