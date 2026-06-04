module crg_clk_nand2 (a, b, y);
   input  a;    // a input
   input  b;    // b input
   output y;    // NAND gate output.

   m_nand i_nand (.A(a), .B(b), .Y(y));

endmodule // crg_nand2
