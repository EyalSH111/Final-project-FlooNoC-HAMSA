`undef STD_DEFINED
module m_and3( input A, input B, input C, output Z);

`ifdef STD_SIM
    `define STD_DEFINED
    assign Z = A && B && C;

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
 `define STD_DEFINED
   // NOTE: TSMC65LP does not have any balanced clock tree AND3 cells.
 `define I_AND3 i_an3 (.Y(Z), .A(A), .B(B), .C(C))

   AND3_X1M_A9TR `I_AND3;

 `undef I_AND3

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
 `define STD_DEFINED
   // NOTE: TSMC16FFC does not have any balanced clock tree AND3 cells.
 `define I_AND3 I_an3 (.A1(A), .A2(B), .A3(C), .Z(Z))
 
 `ifdef CTS_ULVT
   AN3D1BWP16P90CPDULVT `I_AND3;
 `elsif CTS_LVT
   AN3D1BWP16P90CPDLVT `I_AND3;
 `else
   AN3D1BWP16P90CPD `I_AND3;
 `endif

 `undef I_AND3

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
