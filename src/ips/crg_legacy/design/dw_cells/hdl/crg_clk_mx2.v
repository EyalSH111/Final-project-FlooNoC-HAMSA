module crg_clk_mx2 (a, b, s, y);
   input  a;  // Data a input
   input  b;  // Data b input
   input  s;  // Select input, '0' selects a, others selects b
   output y;  // MUX data ouput.

   wire   y;

   m_mx2 i_mx2 (
                    .A   (a),
                    .B   (b),
                    .S   (s),
                    .Z   (y)
                    );

endmodule // crg_clk_mx2
