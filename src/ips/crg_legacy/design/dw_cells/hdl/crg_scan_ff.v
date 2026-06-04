module crg_scan_ff(clk, d, q);

   input  clk;
   input  d;
   output q;

   m_ff_scan i_ff_scan(.CK(clk), .D(d), .Q(q), .SE(1'b0), .SI(q));

endmodule // crg_scan_ff
