`undef STD_DEFINED
module m_buf( input A, output Z);

`ifdef STD_SIM
    `define STD_DEFINED
    assign Z = A;

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
 `define STD_DEFINED
 `define I_CLK_BUF i_clk_buf (.Y(Z), .A(A))

 `ifdef CTS_LVT
   BUF_X1B_A9TL `I_CLK_BUF;
 `else
   BUF_X1B_A9TR `I_CLK_BUF;
 `endif

 `undef I_CLK_BUF

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
 `define STD_DEFINED
 `define I_CLK_BUF I_clk_buf (.I(A), .Z(Z))
 
 `ifdef CTS_ULVT
   CKBD4BWP16P90CPDULVT `I_CLK_BUF;
 `elsif CTS_LVT
   CKBD4BWP16P90CPDLVT `I_CLK_BUF;
 `else
   CKBD4BWP16P90CPD `I_CLK_BUF;
 `endif

 `undef I_CLK_BUF

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
