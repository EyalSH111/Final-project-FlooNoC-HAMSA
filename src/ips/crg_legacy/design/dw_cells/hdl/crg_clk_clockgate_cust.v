module crg_clk_clockgate_cust (/*autoarg*/
                               // Outputs
                               out_clk,
                               // Inputs
                               clk, scan_enable, cg_sel,clk_en
                               );

   input       clk;         // Clock input
   input       scan_enable; // To be tied to scan_enable or test_enable
   input [1:0] cg_sel;
   input       clk_en;      // functional clock enable
   output      out_clk;     // Gated clock output.

   wire        en_op;

   crg_mx3 I_cg_opr_mux (
                         // Outputs
                         .y				(en_op),
                         // Inputs
                         .a				(clk_en), //en
                         .b				(1'b1),   //bp
                         .c				(1'b0),   //dis
                         .s				(cg_sel[1:0])
                         );

   m_cg I_crg_cg (.CK(clk), .E(en_op), .SE(scan_enable), .ECK(out_clk));

endmodule // crg_clk_clockgate_cust

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
