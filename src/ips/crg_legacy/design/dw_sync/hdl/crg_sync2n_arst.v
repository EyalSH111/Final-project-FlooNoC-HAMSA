module crg_sync2n_arst (clr_n, d, clk, q);
   input        wire clr_n;          // Active low  async clear input
   input        wire d;              //  data input
   input        wire clk;            //  clock input
   output       wire q;              //  data output
   parameter RESET_STATE = 1'b0;

wire negclk;

m_inv I_inv(.A(clk), .ZN(negclk));
crg_sync2_arst #(.RESET_STATE(RESET_STATE)) I_sync2_arst (.clk(negclk), .d(d), .clr_n(clr_n), .q(q));

endmodule // crg_sync2n_arst
