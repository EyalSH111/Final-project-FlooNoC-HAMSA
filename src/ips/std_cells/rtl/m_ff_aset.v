`undef STD_DEFINED
module m_ff_aset( input CK, input SN, input D,
`ifdef STD_SIM
output reg Q);
`else
output     Q);
`endif

`ifdef STD_SIM
    `define STD_DEFINED
    always @(posedge CK or negedge SN)
        if (!SN)
            Q <= 1'b1;
        else
            Q <= D;

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
    `define STD_DEFINED
    DFFSQ_X1M_A9TR i_ff_aset (.Q(Q), .CK(CK), .D(D), .SN(SN));

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpdulvt_100a/tcbn16ffcllbwp16p90cpdulvt.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf

  `ifdef ULVT_ONLY
      `define STD_DEFINED
      DFSNQD0BWP16P90CPDULVT I_ff (.SDN (SN), .CP(CK), .D(D), .Q(Q));
  `else
      `define STD_DEFINED
      DFSNQD0BWP16P90CPD I_ff (.SDN (SN), .CP(CK), .D(D), .Q(Q));
  `endif

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
