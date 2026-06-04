module sync_2ffn_arst (
  input  rstn,
  input  clk,
  input  in,
  output out
);
   wire sync1;

   m_ffn_arst sync1_ff (.D(in)   , .CKN(clk),  .RN(rstn), .Q(sync1));
   m_ffn_arst sync2_ff (.D(sync1), .CKN(clk ), .RN(rstn), .Q(out));

 endmodule
