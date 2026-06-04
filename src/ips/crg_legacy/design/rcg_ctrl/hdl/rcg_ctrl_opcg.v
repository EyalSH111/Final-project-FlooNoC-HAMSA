// Time-stamp: <2016-02-25 2342 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Jupiter Global Clock Controller
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_opcg.v
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
//------------------------------------------------------------------------------

module rcg_ctrl_opcg(/*AUTOARG*/
   // Outputs
   opcg_clk_cg_en,
   // Inputs
   clk_in, grst_n, scan_mode, scan_enable, opcg_mode, opcg_trigger,
   gclk_div_cg_en
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter IDEL          = 3'b00;
   parameter PRE_GEN       = 3'b01;
   parameter TWO_PULSE_GEN = 3'b10;
   parameter POST_GEN      = 3'b11;

   //----------------------------------------------------------------------------
   // Input clocks (functional high speed clok and scan clock)
   //----------------------------------------------------------------------------
   input                 clk_in;
   //----------------------------------------------------------------------------
   // Global reset from GRST block
   //----------------------------------------------------------------------------
   input                 grst_n;
   //----------------------------------------------------------------------------
   // Registers file signals
   //----------------------------------------------------------------------------
   //----------------------------------------------------------------------------
   // DFT control signals
   //----------------------------------------------------------------------------
   input                 scan_mode;
   input                 scan_enable;
   input                 opcg_mode;
   input                 opcg_trigger;
   //----------------------------------------------------------------------------
   // Global clock divider gater enable signal
   //----------------------------------------------------------------------------
   input                 gclk_div_cg_en;
   //----------------------------------------------------------------------------
   // OPCG clock clock gater enable signal
   //----------------------------------------------------------------------------
   output                opcg_clk_cg_en;

   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   wire                 opcg_trigger_sync;
   wire                 opcg_mode_sync;
   wire                 scan_mode_sync;
   wire                 scan_enable_sync;

   wire                 opcg_sm_go;
   reg                  opcg_sm_go_s0;
   reg                  opcg_sm_go_s1;
   wire                 opcg_sm_go_pulse;
   
   reg [1:0]            state;
   reg [1:0]            n_state;
   reg [1:0]            clk_pls_cnt;
   reg [1:0]            n_clk_pls_cnt;
   reg [3:0]            pre_gen_cnt;
   reg [3:0]            n_pre_gen_cnt;
   reg [3:0]            post_gen_cnt;
   reg [3:0]            n_post_gen_cnt;
   reg                  n_cg_en;
   reg                  cg_en;
   
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   assign                opcg_clk_cg_en = cg_en;
   
   /*autotieoff*/
   
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   
   crg_sync2 I_opcg_trigger_sync
     (
      // Outputs
      .q                                (opcg_trigger_sync),
      // Inputs
      .d                                (opcg_trigger),
      .clk                              (clk_in));
   
   
   crg_sync2 I_opcg_mode_sync
     (
      // Outputs
      .q                                (opcg_mode_sync),
      // Inputs
      .d                                (opcg_mode),
      .clk                              (clk_in));


   crg_sync2 I_scan_mode_sync
     (
      // Outputs
      .q                                (scan_mode_sync),
      // Inputs
      .d                                (scan_mode),
      .clk                              (clk_in));


   crg_sync2 I_scan_enable_sync
     (
      // Outputs
      .q                                (scan_enable_sync),
      // Inputs
      .d                                (scan_enable),
      .clk                              (clk_in));

   //genetart go signal to start the Clock Pulse Generator state machine
   assign opcg_sm_go         = (opcg_trigger_sync & ~scan_enable_sync & scan_mode_sync & opcg_mode_sync);
 
   //opcg SM go pulse gen
   
   always @(posedge clk_in or negedge grst_n)
     begin
        if(!grst_n)
          begin
               opcg_sm_go_s0  <=  1'b0;
               opcg_sm_go_s1 <=  1'b0;
          end
        else
          begin
             if (gclk_div_cg_en == 1'b1)
               begin
                    opcg_sm_go_s0  <=  opcg_sm_go;
                    opcg_sm_go_s1 <=  opcg_sm_go_s0;
               end
          end // else: !if(!grst_n)
     end // always @ (posedge clk_in or negedge grst_n)
   
   assign opcg_sm_go_pulse = (opcg_sm_go_s0 & ~opcg_sm_go_s1);

   //OPCG State Machine
   always @(*)
     begin

        n_state[1:0]        = state[1:0];
        n_clk_pls_cnt[1:0]  = clk_pls_cnt[1:0];
        n_pre_gen_cnt[3:0]  = pre_gen_cnt[3:0];
        n_post_gen_cnt[3:0] = post_gen_cnt[3:0];
        n_cg_en             = cg_en;
 
        case ({opcg_sm_go_s0,state[1:0]})
          IDEL:
            begin
               if (!opcg_sm_go_pulse)
                 n_state[1:0] = IDEL;
               else
                 n_state[1:0] = PRE_GEN;               
            end
          PRE_GEN:
            begin
               if (pre_gen_cnt[3:0] < 4'd10)
                 begin
                    n_pre_gen_cnt[3:0]  = n_pre_gen_cnt[3:0] + 1;
                    n_state[1:0] = PRE_GEN;
                 end
               else
                 begin
                    n_state[1:0] = TWO_PULSE_GEN; 
                 end
               
            end // case: PRE_GEN
                 
          TWO_PULSE_GEN:
            begin
               if (clk_pls_cnt[1:0] < 2'd2)
                 begin
                    n_clk_pls_cnt[1:0] = n_clk_pls_cnt[1:0] +1;
                    n_cg_en = 1'h1;
                    n_state[1:0] = TWO_PULSE_GEN;
                 end
               else
                 begin
                    n_clk_pls_cnt[1:0] = 2'h0;
                    n_cg_en = 1'h0;
                    n_state[1:0] = POST_GEN;
                 end // else: !if(clk_pls_cnt[1:0] < 2'd2)
                 
            end // case: TWO_PULSE_GEN
  
          POST_GEN:
            begin
               if (post_gen_cnt[3:0] < 4'd10)
                 begin
                    n_post_gen_cnt[3:0]  = n_post_gen_cnt[3:0] + 1;
                    n_state[1:0] = POST_GEN;
                 end
               else
                 begin
                    n_state[1:0]        = IDEL;
                    n_clk_pls_cnt[1:0]  = 2'h0;
                    n_pre_gen_cnt[3:0]  = 4'h0;
                    n_post_gen_cnt[3:0] = 4'h0;
                    n_cg_en             = 1'h0;
                 end
               
            end
          default:
            begin
               n_state[1:0]        = IDEL;
               n_clk_pls_cnt[1:0]  = 2'h0;
               n_pre_gen_cnt[3:0]  = 4'h0;
               n_post_gen_cnt[3:0] = 4'h0;
               n_cg_en             = 1'h0;
            end
        endcase // case(state)
     end // always @ (*)
   
   always @(posedge clk_in or negedge grst_n)
     begin
        if(!grst_n)
          begin
               state[1:0]        <=  IDEL;
               clk_pls_cnt[1:0]  <=  2'h0;
               pre_gen_cnt[3:0]  <=  4'h0;
               post_gen_cnt[3:0] <=  4'h0;
               cg_en             <=  1'h0;
          end
        else
          begin
               //Default
               cg_en <=  1'b0;
               if (gclk_div_cg_en == 1'b1)
                 begin
                      state[1:0]        <=  n_state[1:0];
                      clk_pls_cnt[1:0]  <=  n_clk_pls_cnt[1:0];
                      pre_gen_cnt[3:0]  <=  n_pre_gen_cnt[3:0];
                      post_gen_cnt[3:0] <=  n_post_gen_cnt[3:0];
                      cg_en             <=  n_cg_en;
                 end // if (gclk_div_cg_en == 1'b1)
          end // else: !if(!grst_n)
     end // always @ (posedge clk_in or negedge grst_n)

endmodule // rcg_ctrl_opcg

// Local Variables:
// verilog-library-directories:("." "../../")
// End: