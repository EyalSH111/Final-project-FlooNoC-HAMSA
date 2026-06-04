`ifndef PNR
module sync_2ff (
  input  clk,
  input  in,
  output out
);
   wire sync1;

       m_ffsync #(.X_SIZE (1)) sync1_ff (.D(in),    .CK(clk), .Q(sync1));
       m_ff     #(.X_SIZE (2)) sync2_ff (.D(sync1), .CK(clk), .Q(out));

endmodule
`endif // !`elsif PNR
