module crg_clk_nor2 (a, b, y);
   input  a;    // a input
   input  b;    // b input
   output y;    // OR gate output.

   m_nor i_nor(.A(a), .B(b), .ZN(y));

endmodule // crg_clk_nor2
