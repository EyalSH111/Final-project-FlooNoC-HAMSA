// Description  : Glitch Free Clock Mux
//  - Currently Selected clock must be toggling in order to switch to other clock
//  - rst_cntrl_n can be used to overcome non-toggling clocks
//  - INPUTS:
//       x clk_cntrl    - must be active to allow changes
//       x rst_cntrl_n  - no clk_out when asserted,
//                        NOTE: assertion might cause glitch on clk_out (negedge of rst_cntrl_n)
//                        assertion must happen while clk_out domain is in reset!!!
//                        or if current selected clock is not toggling
//       x sel          - clock to select. all controls are in clk_cntrl domain
//       x clock_enable - uses clock-gates to stop the clock. 
//                        clk_cntrl domain
//       x clk0         - clock selected when sel=0
//       x clk1         - clock selected when sel=1
//  - OUTPUTS:
//       x clk_out            - equal to selected clock when rst_cntrl_n=1 and clock_enable=1 
//       x switch_in_progress - indication in clk_cntrl domain. 
//                              RISES one clock AFTER sel INPUT has changed
//                              FALLS only AFTER CLK_OUT shows selected clock
//       x clock_enabled      - indication in clk_domain. rise/fall AFTER clk_out is enabled/disabled.
//
//
//------------------------------------------------------------------------------
module m_glitch_free_clock_mux(
    //clk_cntrl domain
    input clk_cntrl,
    input rst_cntrl_n,
    input sel,
    output switch_in_progress,
    input clock_enable,
    output clock_enabled,
   
    //other domains
    input clk0,
    input clk1,
    output clk_out,

    input test_mode,
    input opcg_mode);

parameter OPCG_CLK = 1;


wire en0;
wire en1;

wire gated_clk0;
wire gated_clk1;

wire not_sel_keep;
wire en0_sync;
wire en1_sync;
wire en0_sync_s;
wire en1_sync_s;
wire en0_sync_sync;
wire en1_sync_sync;
wire en0_sync_sync_s;
wire en1_sync_sync_s;
wire en0_sync_sync_s_inv;
wire en1_sync_sync_s_inv;
wire en0_sync_a;
wire en1_sync_a;
wire en0_sync_ao;
wire en1_sync_ao;

wire sel_keep;
wire sel_guard;
wire sel_guard_dft;
wire switch_start;
wire switch_end;
wire test_mode_or_opcg_mode;

wire LO1, LO2, LO3;
wire HI1, HI2, HI3;

m_inv  inv_sel_keep (.A(sel_keep),      .ZN(not_sel_keep));
m_inv  inv_en0_sync_sync (.A(en0_sync_sync_s), .ZN(en0_sync_sync_s_inv));
m_inv  inv_en1_sync_sync (.A(en1_sync_sync_s), .ZN(en1_sync_sync_s_inv));

m_and3 and_en0 (.A(not_sel_keep), .B(en1_sync_sync_s_inv), .C(clock_enable), .Z(en0));
m_and3 and_en1 (.A(sel_keep),     .B(en0_sync_sync_s_inv), .C(clock_enable), .Z(en1));

sync_2ff_arst sync_en0 (.clk(clk0), .rstn(rst_cntrl_n), .in(en0), .out(en0_sync));
sync_2ff_arst sync_en1 (.clk(clk1), .rstn(rst_cntrl_n), .in(en1), .out(en1_sync));

//add 1 cycle because clock is entering a CLOCK-GATE, not AND
//so when enX_sync_s falls - gated_clkX is guranteed to be 0
m_ff_arst smp_en0_sync (.RN(rst_cntrl_n), .CK(clk0), .D(en0_sync), .Q(en0_sync_s));
m_ff_arst smp_en1_sync (.RN(rst_cntrl_n), .CK(clk1), .D(en1_sync), .Q(en1_sync_s));

sync_2ff sync_en0_sync (.clk(clk_cntrl), .in(en0_sync_s), .out(en0_sync_sync));
sync_2ff sync_en1_sync (.clk(clk_cntrl), .in(en1_sync_s), .out(en1_sync_sync));

//add 1 cycle because mux select changes 1 clock later
m_ff_arst smp_en0_sync_sync (.RN(rst_cntrl_n), .CK(clk_cntrl), .D(en0_sync_sync), .Q(en0_sync_sync_s));
m_ff_arst smp_en1_sync_sync (.RN(rst_cntrl_n), .CK(clk_cntrl), .D(en1_sync_sync), .Q(en1_sync_sync_s));

m_tie_hi TIE_HI_1 (.HI(HI1));
m_tie_hi TIE_HI_2 (.HI(HI2));
m_tie_lo TIE_LO_1 (.LO(LO1));
m_tie_lo TIE_LO_2 (.LO(LO2));
m_tie_lo TIE_LO_3 (.LO(LO3));
m_and and_en0_sync_a  (.A(en0_sync), .B(HI1), .Z(en0_sync_a));
m_and and_en1_sync_a  (.A(en1_sync), .B(HI2), .Z(en1_sync_a));
m_or   or_en0_sync_ao (.A(en0_sync_a), .B(LO1), .Z(en0_sync_ao));
m_or   or_en1_sync_ao (.A(en1_sync_a), .B(LO2), .Z(en1_sync_ao));
m_or or_test_mode_or_opcg_mode (.A(test_mode), .B(opcg_mode), .Z(test_mode_or_opcg_mode));

generate
if (OPCG_CLK==0) begin : OPCG_CLK_0
   wire LO6;
   m_tie_lo TIE_LO_6 (.LO(LO6));
   m_mx2 mux_sel_guard_opcg (.A(sel_guard), .B(LO6), .S(test_mode_or_opcg_mode), .Z(sel_guard_dft));

   m_cg clk_gate0(
       .CK(clk0),
       .EN(en0_sync_ao),
       .SE(test_mode_or_opcg_mode),
       .Q(gated_clk0)
   );
   m_cg clk_gate1(
       .CK(clk1),
       .EN(en1_sync_ao),
       .SE(LO3),
       .Q(gated_clk1)
   );
end else begin : OPCG_CLK_1
   wire HI6;
   m_tie_hi TIE_HI_6 (.HI(HI6));
   m_mx2 mux_sel_guard_opcg (.A(sel_guard), .B(HI6), .S(test_mode_or_opcg_mode), .Z(sel_guard_dft));

   m_cg clk_gate0(
       .CK(clk0),
       .E(en0_sync_ao),
       .SE(LO3),
       .ECK(gated_clk0)
   );
   m_cg clk_gate1(
       .CK(clk1),
       .E(en1_sync_ao),
       .SE(test_mode_or_opcg_mode),
       .ECK(gated_clk1)
   );
end
endgenerate


m_mx2  clk_mux (.A(gated_clk0), .B(gated_clk1), .S(sel_guard_dft), .Z(clk_out));



//sel_guard - change output mux only when both clocks are off
//always @(posedge clk_cntrl)
//   if (!en0_sync_sync && !en1_sync_sync)
//      sel_guard <= sel_keep;
wire en0_ss_nor_en1_ss;
wire sel_guard_d;
m_nor nor_en0_en1 (.A(en0_sync_sync), .B(en1_sync_sync), .ZN(en0_ss_nor_en1_ss));
m_mx2 mux_sel_guard_en (.A(sel_guard), .B(sel_keep), .S(en0_ss_nor_en1_ss), .Z(sel_guard_d));
m_ff dff_sel_guard (.CK(clk_cntrl), .D(sel_guard_d), .Q(sel_guard));

//sel_keep - latch the new value of sel on change until switch ends
//always @(posedge clk_cntrl)
//   if (!switch_in_progress)
//      sel_keep <= sel;
wire sel_keep_d;
m_mx2 mux_sel_keep_en (.A(sel), .B(sel_keep), .S(switch_in_progress), .Z(sel_keep_d));
m_ff dff_sel_keep (.CK(clk_cntrl), .D(sel_keep_d), .Q(sel_keep));

//switch_in_progress
//assign switch_start = !switch_in_progress && (sel != sel_keep);
wire not_switch_in_progress;
wire sel_not_equal_sel_keep;
m_inv inv_not_switch_in_progress (.A(switch_in_progress), .ZN(not_switch_in_progress));
m_xor xor_sel_sel_keep (.A(sel), .B(sel_keep), .Z(sel_not_equal_sel_keep));
m_and and_switch_start (.A(not_switch_in_progress), .B(sel_not_equal_sel_keep), .Z(switch_start));

//assign switch_end   = switch_in_progress && 
//                      (sel_keep == en1_sync_sync) &&
//                      (sel_keep != en0_sync_sync);
wire sel_keep_equal_en1_sync_sync;
wire sel_keep_not_equal_en0_sync_sync;
m_xnor xnor_sel_keep_en1 (.A(sel_keep), .B(en1_sync_sync), .ZN(sel_keep_equal_en1_sync_sync));
m_xor  xor_sel_keep_en0  (.A(sel_keep), .B(en0_sync_sync), .Z(sel_keep_not_equal_en0_sync_sync));
m_and3 and_switch_end (
   .A(switch_in_progress),
   .B(sel_keep_equal_en1_sync_sync),
   .C(sel_keep_not_equal_en0_sync_sync),
   .Z(switch_end));

//always @(posedge clk_cntrl or negedge rst_cntrl_n)
//   if (!rst_cntrl_n)
//      switch_in_progress <= 1'b0;// 0 to allow sel_keep to get value after reset deassertion
//   else begin
//      if (switch_start)
//         switch_in_progress <= 1'b1;
//      if (switch_end) 
//         switch_in_progress <= 1'b0;
//   end
wire not_switch_end;
wire switch_in_progress_and_not_switch_end;
wire switch_in_progress_d;
m_inv inv_not_switch_end (.A(switch_end), .ZN(not_switch_end));
m_and and_switch_in_prgress_not_switch_end (.A(switch_in_progress), .B(not_switch_end), .Z(switch_in_progress_and_not_switch_end));
m_or or_switch_in_progress_d (.A(switch_start), .B(switch_in_progress_and_not_switch_end), .Z(switch_in_progress_d));
m_ff_arst dff_switch_in_progress (.CK(clk_cntrl), .RN(rst_cntrl_n), .D(switch_in_progress_d), .Q(switch_in_progress));

//clock_enabled
//assign clock_enabled = en0_sync_sync || en1_sync_sync;
m_or or_en0_en1 (.A(en0_sync_sync), .B(en1_sync_sync), .Z(clock_enabled));


endmodule
