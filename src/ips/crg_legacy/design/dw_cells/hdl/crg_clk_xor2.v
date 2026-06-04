module crg_clk_xor2 (a, b, y);
   input  a;    // a input
   input  b;    // b input
   output y;   // XOR gate output.

   m_xor i_xor (.A(a), .B(b), .Z(y));

endmodule // crg_clk_xor2
