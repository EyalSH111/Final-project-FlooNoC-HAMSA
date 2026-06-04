module sync_2ff_aset (
  input  setn,
  input  clk,
  input  in,
  output out
);
   wire sync1;

   m_ffsync_aset sync1_ff (.D(in)   , .CK(clk),  .SN(setn), .Q(sync1));
   m_ff_aset     sync2_ff (.D(sync1), .CK(clk ), .SN(setn), .Q(out));

 endmodule
