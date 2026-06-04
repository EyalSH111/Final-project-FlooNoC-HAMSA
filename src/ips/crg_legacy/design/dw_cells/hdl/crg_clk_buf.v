module crg_clk_buf (a, y);
   input   a;   // Buffer input
   output  y;   // Buffer output

   m_buf i_buf(.A(a), .Z(y));

endmodule // crg_clk_buf
