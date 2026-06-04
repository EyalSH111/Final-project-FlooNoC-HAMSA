module rst_sync(input RI_N, input CK, output RO_N);

    wire HI;
    wire R0, R1, R2;

    m_tie_hi      TH (.HI(HI));
    m_ffsync_arst F0 (.CK(CK), .RN(RI_N), .D(HI), .Q(R0));
    m_ff_arst     F1 (.CK(CK), .RN(RI_N), .D(R0), .Q(R1));
    m_ff_arst     F2 (.CK(CK), .RN(RI_N), .D(R1), .Q(R2));
    m_ff_arst     F3 (.CK(CK), .RN(RI_N), .D(R2), .Q(RO_N));

endmodule
