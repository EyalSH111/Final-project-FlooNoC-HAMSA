module crg_clk_or2 (a, b, y);
   input  a;    // a input
   input  b;    // b input
   output y;    // OR gate output.

   m_or i_or(.A(a), .B(b), .Z(y));

endmodule // crg_clk_or2
