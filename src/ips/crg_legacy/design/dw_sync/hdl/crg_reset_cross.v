// the block  synchronize the sreset (syn reset) from domain A to domain B
// the first stage clean the glitches clock to clock path
// the second is a metsatable synchronizer
module crg_reset_cross (
                        clka,
                        clka_sreset_n,
                        clkb,
                        scan_mode,
                        clkb_sreset_n
                        );

   input         clka;
   input         clka_sreset_n;
   input         clkb;
   input         scan_mode;
   output        clkb_sreset_n;

   wire          sreset_n_no_glitch;
   wire          sreset_n_no_glitch_w_scan;
   reg           rst_d1;
   reg           rst_d2;

   m_ff  I_crg_scan_ff (.CK(clka), .D(clka_sreset_n), .Q(sreset_n_no_glitch));
   m_mx2 I_crg_clk_mx2 (.A(sreset_n_no_glitch), .B(clka_sreset_n), .S(scan_mode), .Z(sreset_n_no_glitch_w_scan));
   crg_reset_sync I_crg_rst_sync (.arstn(sreset_n_no_glitch_w_scan), .clk(clkb), .scan_mode(scan_mode), .rst_out_n(clkb_sreset_n));

endmodule
