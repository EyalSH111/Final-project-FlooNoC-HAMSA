module crg_mx4 (a, b, c, d, s, y);
   input             a;  // Data a input
   input             b;  // Data b input
   input             c;  // Data c input
   input             d;  // Data d input

   input  wire [1:0] s;  // Select input
   output            y;  // MUX data ouput.
   wire              y;

   m_mx4 i_mx4(.A(a), .B(b), .C(c), .D(d), .S(s), .Z(y));

endmodule // crg_mx4
