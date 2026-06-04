module crg_ff_arst(ck, d, rd, q);

   input  ck;
   input  d;
   input  rd;
   output q;

m_ff_arst i_ff_arst(.CK(ck), .RN(rd), .D(d), .Q(q));

endmodule // crg_ff_arst