module crg_clk_inv (a, y);
   input  a;    // Invertor input
   output y;   // Invertor output

   m_inv i_inv (.A(a), .ZN(y));
   
endmodule // crg_clk_inv
