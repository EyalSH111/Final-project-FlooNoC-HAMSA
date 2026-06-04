module crg_lat (clk, d, q);
   input  clk;
   input  d;
   output q;

   m_lat i_lat(.G(clk), .D(d), .Q(q));

endmodule // crg_lat
