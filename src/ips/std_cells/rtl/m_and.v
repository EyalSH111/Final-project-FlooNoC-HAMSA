`undef STD_DEFINED
module m_and( input A, input B, output Z);

`ifdef STD_SIM
 `define STD_DEFINED
   assign Z = A && B;

`elsif TSMC_65
   // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
   // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
 `define STD_DEFINED
 `define I_CLK_AND2 i_clk_an2 (.Y(ZN), .A(A), .B(B))
 `define I_CLK_INV  i_clk_inv (.Y(Z), .A(ZN))

   // Balanced version:
   wire   ZN;
 `ifdef CTS_LVT
   NAND2_X1B_A9TL `I_CLK_AND2;
   INV_X1B_A9TL   `I_CLK_INV;
 `else
   NAND2_X1B_A9TR `I_CLK_AND2;
   INV_X1B_A9TR   `I_CLK_INV;
 `endif

 `undef I_CLK_AND2
 `undef I_CLK_INV

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
 `define STD_DEFINED
 `define I_CLK_AN2 I_clk_an2 (.A1(A), .A2(B), .Z(Z))

 `ifdef CTS_ULVT
   CKAN2D1BWP16P90CPDULVT `I_CLK_AN2;
 `elsif CTS_LVT
   CKAN2D1BWP16P90CPDLVT `I_CLK_AN2;
 `else
   CKAN2D1BWP16P90CPD `I_CLK_AN2;
 `endif

 `undef I_CLK_AN2

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
ERROR NO STD_X TECHNOLOGY FOUND
`endif
