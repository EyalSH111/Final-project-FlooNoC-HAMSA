module sync_2ff_arst (
  input  rstn,
  input  clk,
  input  in,
  output out
);
   wire sync1;

   m_ffsync_arst sync1_ff (.D(in)   , .CK(clk),  .RN(rstn), .Q(sync1));
   m_ff_arst     sync2_ff (.D(sync1), .CK(clk ), .RN(rstn), .Q(out));

 endmodule
