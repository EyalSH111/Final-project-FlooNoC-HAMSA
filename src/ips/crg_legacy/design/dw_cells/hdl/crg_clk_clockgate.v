module crg_clk_clockgate (clk, en, ten, out_clk);
   input   clk;             // Clock input
   input   en;              // Active high clock enable input.
   input   ten;             // To be tied to scan_enable or test_enable
   output  out_clk;         // Gated clock output.

   m_cg i_cg (
              .CK  (clk),
              .E   (en),
              .SE  (ten),
              .ECK (out_clk)
              );

endmodule // crg_clk_clockgate
