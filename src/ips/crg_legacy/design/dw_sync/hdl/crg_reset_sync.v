module crg_reset_sync (arst_n, clk, scan_mode, rst_out_n);
input  arst_n;
input  clk;
input  scan_mode;
output rst_out_n;

wire   hi, q1, q2;

m_tie_hi  tie_hi_inst (.HI(hi));
m_ff_arst ff1_inst (.CK(clk), .D(hi), .RN(arst_n), .Q(q1));
m_ff_arst ff2_inst (.CK(clk), .D(q1), .RN(arst_n), .Q(q2));
m_mx2     mux_inst (.A(q2), .B(arst_n), .S(scan_mode), .Z(rst_out_n));

endmodule // crg_reset_sync
