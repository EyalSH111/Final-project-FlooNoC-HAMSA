`undef STD_DEFINED
module m_cg( input CK, input E, input SE, output ECK);

`ifdef STD_SIM
    `define STD_DEFINED
   reg lat;
   always @(*)
      if (!CK) lat = SE || E;
   assign ECK = CK && lat;

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
 `define STD_DEFINED
 `define I_CG i_cg (.CK(CK), .E(E), .SE(SE), .ECK(ECK))

 `ifdef CTS_LVT
   PREICG_X1B_A9TL `I_CG;
 `else
   PREICG_X1B_A9TR `I_CG;
 `endif

 `undef I_CG

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
 `define STD_DEFINED
 `define I_CG I_cg (.Q(ECK), .CP(CK), .E(E), .TE(SE))

 `ifdef CTS_ULVT
   CKLNQD4BWP16P90CPDULVT `I_CG;
 `elsif CTS_LVT
   CKLNQD4BWP16P90CPDLVT `I_CG;
 `else
   CKLNQD4BWP16P90CPD `I_CG;
 `endif

 `undef I_CG

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
