module crg_clk_an2 (a, b, y);
   input  a;    // a input
   input  b;    // b input
   output y;   // NAND gate output.

   m_and i_and2 (.A(a), .B(b), .Z(y));

endmodule // crg_clk_an2
