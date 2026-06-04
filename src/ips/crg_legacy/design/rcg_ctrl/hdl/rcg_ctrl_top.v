// Time-stamp: <2016-02-15 0925 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Jupiter Global Clock Controller
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_top.v
// Author        :   <naftalyb@NAFTALYB-LT6410>
// Created       : 30.01.2013
// Last modified : 30.01.2013
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Copyright (c) 2011 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 30.01.2013 : created
// 20.05.2015 : RCC_OFFSET changed to be a product of 12 bits shift instead of 8
//------------------------------------------------------------------------------

module rcg_ctrl_top(/*AUTOARG*/
   // Outputs
   rcg_ctrl_rcc_rf_state_out, rcg_ctrl_div_rf_div_go_ack, mod_disable,
   mod_disable_req, clk_out, clk_out_div_en, mod_rst_out_n,
   // Inputs
   clk_in, ref_clk, scan_clk, grst_n, hgrst_n, rcg_ctrl_rf_clk,
   rcg_ctrl_rf_rst_n, rcg_ctrl_rcc_rf_stb, rcg_ctrl_rcc_rf_state_in,
   rcg_ctrl_div_rf_div_ratio, rcg_ctrl_div_rf_div_go,
   rcg_ctrl_div_rf_div_go_ack_read_p, mod_cg_en_add_dly,
   mod_disable_ack, mod_force_enable, mod_hw_rst_req, mod_init_state,
   mod_grstn_cgen_dly, scan_mode, scan_enable, opcg_mode,
   opcg_trigger, scan_async_ctrl, force_rcc_on, force_rcc_off,
   pll_bypass_pad, pll_bypass_r, pll_bypass_src_r,
   div_clk_align_vec_mask_n, udef_vec_en, udef_vec
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter DIV_NUM_PULSE = 0;
   parameter DIV_NUM_HALFDC = 4;
   parameter RCC_NUM_ARRAY = 32'h01_01_01_01;
   parameter RCC_OFFST_ARRAY = 32'h03_02_01_00;
   parameter RCC_NUM = 4;
   parameter DIV_WIDTH = 16;
   localparam DIV_NUM = DIV_NUM_PULSE + DIV_NUM_HALFDC;
   parameter HALFDC_UP = {DIV_NUM{1'b1}};
   parameter RCC_BYP_VEC = {RCC_NUM{1'b0}};

   //----------------------------------------------------------------------------
   // Input clocks (functional high speed clok and scan clock)
   //----------------------------------------------------------------------------
   input                      clk_in;
   input                      ref_clk;
   input                      scan_clk;
   //----------------------------------------------------------------------------
   // Global resets from POR/GRST blocks
   //----------------------------------------------------------------------------
   input                      grst_n; // asserts for 1024 cycles afer hgrst_n
   input                      hgrst_n; // asserts upon assertion of POR or RST_in resets
   //----------------------------------------------------------------------------
   // Registers file signals
   //----------------------------------------------------------------------------
   input                      rcg_ctrl_rf_clk;
   input                      rcg_ctrl_rf_rst_n;
   input [RCC_NUM-1:0]        rcg_ctrl_rcc_rf_stb;
   input [((3)*RCC_NUM-1):0]  rcg_ctrl_rcc_rf_state_in;
   output [((6)*RCC_NUM-1):0] rcg_ctrl_rcc_rf_state_out;
   input [((DIV_WIDTH*DIV_NUM)-1):0] rcg_ctrl_div_rf_div_ratio;
   input                      rcg_ctrl_div_rf_div_go;
   input                      rcg_ctrl_div_rf_div_go_ack_read_p;
   output                     rcg_ctrl_div_rf_div_go_ack;
   //----------------------------------------------------------------------------
   // RCC tie-offs
   //----------------------------------------------------------------------------
   input [RCC_NUM-1:0]        mod_cg_en_add_dly;
   input [RCC_NUM-1:0]        mod_disable_ack;
   input [RCC_NUM-1:0]        mod_force_enable;
   input [RCC_NUM-1:0]        mod_hw_rst_req;
   input [((2)*RCC_NUM-1):0]  mod_init_state;
   input [((8)*RCC_NUM-1):0]  mod_grstn_cgen_dly;
   output [RCC_NUM-1:0]       mod_disable;
   output [RCC_NUM-1:0]       mod_disable_req;
   //----------------------------------------------------------------------------
   // DFT control signals
   //----------------------------------------------------------------------------
   input                      scan_mode;
   input                      scan_enable;
   input                      opcg_mode;
   input [DIV_NUM-1:0]        opcg_trigger;
   input                      scan_async_ctrl;
   input [RCC_NUM-1:0]        force_rcc_on;
   input [RCC_NUM-1:0]        force_rcc_off;
   //----------------------------------------------------------------------------
   // PLL bypass mux signals
   //----------------------------------------------------------------------------
   input                      pll_bypass_pad;
   input                      pll_bypass_r;
   input                      pll_bypass_src_r;
   //----------------------------------------------------------------------------
   // Divider ratio and alignment signals
   //----------------------------------------------------------------------------
   input [DIV_NUM-1:0]        div_clk_align_vec_mask_n;
   //----------------------------------------------------------------------------
   // Divider ratio from JTAG controlled user defined registers
   //----------------------------------------------------------------------------
   input [DIV_NUM-1:0]        udef_vec_en;
   input [((DIV_WIDTH*DIV_NUM)-1):0] udef_vec;
   //----------------------------------------------------------------------------
   // RCG clock outpus
   //----------------------------------------------------------------------------
   output [RCC_NUM-1:0]       clk_out;
   output [RCC_NUM-1:0]       clk_out_div_en;
   //----------------------------------------------------------------------------
   // RCG RCC reset outpus
   //----------------------------------------------------------------------------
   output [RCC_NUM-1:0]       mod_rst_out_n;

   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   wire [DIV_NUM-1:0] div_clk_align_vec;
   wire [DIV_NUM-1:0] divider_go_ack_vec;
   wire [DIV_NUM-1:0] divider_go_ack_vec_sync;
   wire               divider_go_ack_sync;
   reg                divider_go_ack_sync_s0;
   reg                divider_go_ack_sync_s1;
   wire               divider_go_sync;
   reg                rcg_ctrl_div_rf_div_go_ack;
   reg                rcg_ctrl_div_rf_div_go_lvl;
   wire [DIV_NUM-1:0] div_clk_align_vec_mask_n_sync2;

   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 clk_in_mux;             // From I_rcg_ctrl_pll_bypass of rcg_ctrl_pll_bypass.v
   wire                 rcg_grst_n;             // From I_rcg_ctrl_grst_gen of rcg_ctrl_grst_gen.v
   wire                 rcg_hgrst_n;            // From I_rcg_ctrl_grst_gen of rcg_ctrl_grst_gen.v
   wire                 rcg_pre_grst_n_ind;     // From I_rcg_ctrl_grst_gen of rcg_ctrl_grst_gen.v
   // End of automatics

   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------

   //----------------------------------------------------------------------------
   // Bitwise AND post-synchronized divider_go ACK. outputs
   //----------------------------------------------------------------------------
   assign divider_go_ack_sync = &divider_go_ack_vec_sync[DIV_NUM-1:0];

   ////*autotieoff*/
   /*autoinput*/
   ////*autooutput*/
   /*autoreginput*/
   ////*autoreg*/

   //----------------------------------------------------------------------------
   // grst_n/pre_grst_n_ind re-generation
   //----------------------------------------------------------------------------
   rcg_ctrl_grst_gen I_rcg_ctrl_grst_gen
     (/*AUTOINST*/
      // Outputs
      .rcg_hgrst_n                      (rcg_hgrst_n),
      .rcg_grst_n                       (rcg_grst_n),
      .rcg_pre_grst_n_ind               (rcg_pre_grst_n_ind),
      // Inputs
      .ref_clk                          (ref_clk),
      .hgrst_n                          (hgrst_n),
      .grst_n                           (grst_n));

   //----------------------------------------------------------------------------
   // RCG PLL bypass mux
   //----------------------------------------------------------------------------
    /* rcg_ctrl_pll_bypass AUTO_TEMPLATE (
     .pll_clk_out                       (clk_in_mux),
     .pll_clk_in                        (clk_in),
     .hgrst_n                           (rcg_hgrst_n),
   );*/
   rcg_ctrl_pll_bypass I_rcg_ctrl_pll_bypass
    (/*AUTOINST*/
     // Outputs
     .pll_clk_out                       (clk_in_mux),            // Templated
     // Inputs
     .pll_clk_in                        (clk_in),                // Templated
     .ref_clk                           (ref_clk),
     .hgrst_n                           (rcg_hgrst_n),           // Templated
     .scan_mode                         (scan_mode),
     .pll_bypass_pad                    (pll_bypass_pad),
     .pll_bypass_r                      (pll_bypass_r),
     .pll_bypass_src_r                  (pll_bypass_src_r));

   //----------------------------------------------------------------------------
   // This process loades the register-file pulse signal "rcg_ctrl_div_rf_div_go"
   // into "rcg_ctrl_div_rf_div_go_lvl" register. This register cleared
   // when "divider_go_ack_sync" signal sets to 1'b1.
   //----------------------------------------------------------------------------
   always @ (posedge rcg_ctrl_rf_clk or negedge rcg_ctrl_rf_rst_n)
     begin
        if (!rcg_ctrl_rf_rst_n)
          begin
               rcg_ctrl_div_rf_div_go_lvl <=  1'b0;
          end
        else
          begin
               if (divider_go_ack_sync == 1'b1)
                 begin
                      rcg_ctrl_div_rf_div_go_lvl <=  1'b0;
                 end
               else if (rcg_ctrl_div_rf_div_go == 1'b1)
                 begin
                      rcg_ctrl_div_rf_div_go_lvl <=  1'b1;
                 end
          end // else: !if(!rcg_ctrl_rf_rst_n)
     end

   //----------------------------------------------------------------------------
   // This process detects the falling edge of "divider_go_ack_sync" and
   // generates "rcg_ctrl_div_rf_div_go_ack" signal towards the register-file.
   // The signal is cleared when "rcg_ctrl_div_rf_div_go_ack_read_p" is
   // asserted upon reading the status from the CPU.
   //----------------------------------------------------------------------------
   always @ (posedge rcg_ctrl_rf_clk or negedge rcg_ctrl_rf_rst_n)
     begin
        if (!rcg_ctrl_rf_rst_n)
          begin
               divider_go_ack_sync_s0 <=  1'b0;
               divider_go_ack_sync_s1 <=  1'b0;
               rcg_ctrl_div_rf_div_go_ack <=  1'b0;
          end
        else
          begin
               divider_go_ack_sync_s0 <=  divider_go_ack_sync;
               divider_go_ack_sync_s1 <=  divider_go_ack_sync_s0;
               if (divider_go_ack_sync_s0 & ~divider_go_ack_sync_s1)
                 begin
                      rcg_ctrl_div_rf_div_go_ack <=  1'b1;
                 end
               else if (rcg_ctrl_div_rf_div_go_ack_read_p == 1'b1)
                 begin
                      rcg_ctrl_div_rf_div_go_ack <=  1'b0;
                 end // else: !if(divider_go_ack_sync_s0 & ~divider_go_ack_sync_s1)
          end // else: !if(!rcg_ctrl_rf_rst_n)
     end

   crg_sync2 I_divider_go_div_sync2
     (
      // Outputs
      .q                                (divider_go_sync),
      // Inputs
      .clk                              (clk_in_mux),
      .d                                (rcg_ctrl_div_rf_div_go_lvl));

  generate
  genvar                x;
  for (x=0; x<DIV_NUM ; x=x+1) begin : div_go_ack_sync2

   crg_sync2 I_go_ack_sync2
     (
       // Outputs
      .q                                (divider_go_ack_vec_sync[x]),
      // Inputs
      .d                                (divider_go_ack_vec[x]),
      .clk                              (rcg_ctrl_rf_clk));

  end
  endgenerate

  generate
  genvar                z;
  for (z=0; z<DIV_NUM ; z=z+1) begin : div_clk_algn_vec_mask_n_sync2

   crg_sync2 I_div_clk_align_vec_mask_n_sync2
     (
       // Outputs
      .q                                (div_clk_align_vec_mask_n_sync2[z]),
      // Inputs
      .d                                (div_clk_align_vec_mask_n[z]),
      .clk                              (clk_in_mux));

  end
  endgenerate

  generate
  genvar                i;
  for (i=0; i<DIV_NUM_PULSE ; i=i+1) begin : clock_div_core_gen_pulse

   localparam [7:0] RCC_NUM_PULSE = (RCC_NUM_ARRAY>>8*i);

   // The shift is modified from 8 bits to 12 bits, to fit an updated RCG setup
   localparam [11:0] RCC_OFFST_PULSE = (RCC_OFFST_ARRAY>>12*i);

   localparam RCC_BYP_VEC_PULSE = RCC_BYP_VEC[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)];

   rcg_ctrl_core #(.DIV_WIDTH(DIV_WIDTH), .DIV_NUM(DIV_NUM_PULSE), .DIV_TYPE("PULSE_DIV"), .RCC_NUM(RCC_NUM_PULSE[7:0]), .HALFDC_UP(HALFDC_UP[i]), .RCC_BYP_VEC(RCC_BYP_VEC_PULSE)) I_rcg_ctrl_core
     (
      // Outputs
      .rcg_ctrl_rcc_rf_state_out        (rcg_ctrl_rcc_rf_state_out[6*(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:6*(RCC_OFFST_PULSE)]),
      .mod_disable                      (mod_disable[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_disable_req                  (mod_disable_req[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_rst_out_n                    (mod_rst_out_n[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .divider_go_ack                   (divider_go_ack_vec[i]),
      .div_clk_align                    (div_clk_align_vec[i]),
      .clk_out                          (clk_out[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .clk_out_div_en                   (clk_out_div_en[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      // Inputs
      .clk_in                           (clk_in_mux),
      .scan_clk                         (scan_clk),
      .pre_grst_n_ind                   (rcg_pre_grst_n_ind),
      .grst_n                           (rcg_grst_n),
      .hgrst_n                          (rcg_hgrst_n),
      .rcg_ctrl_rf_clk                  (rcg_ctrl_rf_clk),
      .rcg_ctrl_rcc_rf_stb              (rcg_ctrl_rcc_rf_stb[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .rcg_ctrl_rcc_rf_state_in         (rcg_ctrl_rcc_rf_state_in[3*(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:3*(RCC_OFFST_PULSE)]),
      .force_rcc_on                     (force_rcc_on[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .force_rcc_off                    (force_rcc_off[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_cg_en_add_dly                (mod_cg_en_add_dly[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_disable_ack                  (mod_disable_ack[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_force_enable                 (mod_force_enable[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_hw_rst_req                   (mod_hw_rst_req[(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:(RCC_OFFST_PULSE)]),
      .mod_init_state                   (mod_init_state[2*(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:2*(RCC_OFFST_PULSE)]),
      .mod_grstn_cgen_dly               (mod_grstn_cgen_dly[8*(RCC_NUM_PULSE+RCC_OFFST_PULSE)-1:8*(RCC_OFFST_PULSE)]),
      .scan_mode                        (scan_mode),
      .scan_enable                      (scan_enable),
      .opcg_mode                        (opcg_mode),
      .opcg_trigger                     (opcg_trigger[i]),
      .scan_async_ctrl                  (scan_async_ctrl),
      .div_ratio                        (rcg_ctrl_div_rf_div_ratio[(DIV_WIDTH*(i+1))-1:(DIV_WIDTH*i)]),
      .divider_go                       (divider_go_sync),
      .div_clk_align_vec                (div_clk_align_vec[(DIV_NUM_PULSE-1):0] | ~div_clk_align_vec_mask_n_sync2[(DIV_NUM_PULSE-1):0]),
      .udef_vec_en                      (udef_vec_en[i]),
      .udef_vec                         (udef_vec[(DIV_WIDTH*(i+1))-1:(DIV_WIDTH*i)]));

  end // block: clock_div_core_gen_pulse
  endgenerate

  generate
  genvar                j;

  for (j=DIV_NUM_PULSE; j<(DIV_NUM_PULSE+DIV_NUM_HALFDC) ; j=j+1) begin : clock_div_core_gen_halfdc

         localparam [7:0] RCC_NUM_HALFDC   = (RCC_NUM_ARRAY>>8*j);

     // The shift is modified from 8 bits to 12 bits, to fit an updated RCG setup
     localparam [11:0] RCC_OFFST_HALFDC = (RCC_OFFST_ARRAY>>12*j);

     localparam RCC_BYP_VEC_HALFDC = RCC_BYP_VEC[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)];

   rcg_ctrl_core #(.DIV_WIDTH(DIV_WIDTH), .DIV_NUM(DIV_NUM_HALFDC), .DIV_TYPE("HALF_DC"), .RCC_NUM(RCC_NUM_HALFDC[7:0]), .HALFDC_UP(HALFDC_UP[j]), .RCC_BYP_VEC(RCC_BYP_VEC_HALFDC)) I_rcg_ctrl_core
     (
      // Outputs
      .rcg_ctrl_rcc_rf_state_out        (rcg_ctrl_rcc_rf_state_out[6*(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:6*(RCC_OFFST_HALFDC)]),
      .mod_disable                      (mod_disable[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_disable_req                  (mod_disable_req[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_rst_out_n                    (mod_rst_out_n[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .divider_go_ack                   (divider_go_ack_vec[j]),
      .div_clk_align                    (div_clk_align_vec[j]),
      .clk_out                          (clk_out[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .clk_out_div_en                   (clk_out_div_en[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      // Inputs
      .clk_in                           (clk_in_mux),
      .scan_clk                         (scan_clk),
      .pre_grst_n_ind                   (rcg_pre_grst_n_ind),
      .grst_n                           (rcg_grst_n),
      .hgrst_n                          (rcg_hgrst_n),
      .rcg_ctrl_rf_clk                  (rcg_ctrl_rf_clk),
      .rcg_ctrl_rcc_rf_stb              (rcg_ctrl_rcc_rf_stb[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .rcg_ctrl_rcc_rf_state_in         (rcg_ctrl_rcc_rf_state_in[3*(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:3*(RCC_OFFST_HALFDC)]),
      .force_rcc_on                     (force_rcc_on[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .force_rcc_off                    (force_rcc_off[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_cg_en_add_dly                (mod_cg_en_add_dly[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_disable_ack                  (mod_disable_ack[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_force_enable                 (mod_force_enable[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_hw_rst_req                   (mod_hw_rst_req[(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:(RCC_OFFST_HALFDC)]),
      .mod_init_state                   (mod_init_state[2*(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:2*(RCC_OFFST_HALFDC)]),
      .mod_grstn_cgen_dly               (mod_grstn_cgen_dly[8*(RCC_NUM_HALFDC+RCC_OFFST_HALFDC)-1:8*(RCC_OFFST_HALFDC)]),
      .scan_mode                        (scan_mode),
      .scan_enable                      (scan_enable),
      .opcg_mode                        (opcg_mode),
      .opcg_trigger                     (opcg_trigger[j]),
      .scan_async_ctrl                  (scan_async_ctrl),
      .div_ratio                        (rcg_ctrl_div_rf_div_ratio[(DIV_WIDTH*(j+1))-1:(DIV_WIDTH*j)]),
      .divider_go                       (divider_go_sync),
      .div_clk_align_vec                (div_clk_align_vec[(DIV_NUM-1):DIV_NUM_PULSE] | ~div_clk_align_vec_mask_n_sync2[(DIV_NUM-1):DIV_NUM_PULSE]),
      .udef_vec_en                      (udef_vec_en[j]),
      .udef_vec                         (udef_vec[(DIV_WIDTH*(j+1))-1:(DIV_WIDTH*j)]));

  end // block: clock_div_a
  endgenerate

endmodule // rcg_ctrl_top

// Local Variables:
// verilog-library-directories:("." "../../")
// End:
