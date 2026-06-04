`undef STD_DEFINED

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Special flip-flop intended to be used as 1st FF in a synchronizer:                                       //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
module m_ffsync_arst( input CK, input RN, input D,
`ifdef STD_SIM
output reg Q);
`else
output     Q);
`endif

`ifdef STD_SIM
    `define STD_DEFINED
    always @(posedge CK or negedge RN)
        if (!RN)
            Q <= 1'b0;
        else
            Q <= D;

`elsif TSMC_65
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/verilog/sc9_cln65lp_base_rvt.v
    // /data/tsmc/65LP//dig_libs/ARM_FEONLY/arm/tsmc/cln65lp/sc9_base_rvt/r0p0/doc/sc9_cln65lp_base_rvt_databook.pdf
    `define STD_DEFINED
    wire R; //only active-high reset found in library
    INV_X1M_A9TR    i_rst_inv             (.Y(R), .A(RN));
    DFFRPQ_X1M_A9TR i_ff_arst_active_high (.Q(Q), .CK(CK), .D(D), .R(R));

`elsif TSMC16
   // /data/tsmc/16FF/dig_libs/TSMCHOME/digital/Front_End/verilog/tcbn16ffcllbwp16p90cpd_100a/tcbn16ffcllbwp16p90cpd.v
   // /data/tsmc/16FF/dig_libs/doc/DB_TCBN16FFCLLBWP16P90CPD_TT0P8V25C.pdf
  `define STD_DEFINED
  `ifdef ULVT_ONLY
      SDFSYNCNQD1BWP16P90CPDULVT I_ff (.CDN(RN), .CP(CK), .D(D), .SE(1'b0), .SI(1'b0), .Q(Q));
  `else
      SDFSYNCNQD1BWP16P90CPD     I_ff (.CDN(RN), .CP(CK), .D(D), .SE(1'b0), .SI(1'b0), .Q(Q));
  `endif

`endif // !`elsif TSMC16


endmodule
`ifndef STD_DEFINED
    ERROR NO STD_X TECHNOLOGY FOUND
`endif
