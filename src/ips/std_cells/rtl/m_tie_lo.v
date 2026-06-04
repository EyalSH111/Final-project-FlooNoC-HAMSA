`undef STD_DEFINED
module m_tie_lo(output LO);

`ifdef STD_SIM
    `define STD_DEFINED
    assign LO = 1'b0;

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
    `define STD_DEFINED
    TIELO_X1M_A9TR i_tielo (.Y(LO));

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
   `ifdef ULVT_ONLY
    `define STD_DEFINED
    TIELBWP16P90CPDULVT I_tielo (.ZN(LO));
   `else
    `define STD_DEFINED
    TIELBWP16P90CPD I_tielo (.ZN(LO));
   `endif

`endif // !`elsif TSMC16

endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
