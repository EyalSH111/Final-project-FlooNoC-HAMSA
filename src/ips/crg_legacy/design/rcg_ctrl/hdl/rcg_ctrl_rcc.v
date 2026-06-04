// Time-stamp: <2015-12-17 1404 naftalyb>
//-----------------------------------------------------------------------------
// Title         : Jupiter Global Clock Controller
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : rcg_ctrl_rcc.v
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

module rcg_ctrl_rcc(/*AUTOARG*/
   // Outputs
   rcg_ctrl_rcc_rf_state_out, mod_rst_out_n, mod_gclk_cg_en,
   mod_disable_req, mod_disable,
   // Inputs
   grst_n, hgrst_n, mod_hw_rst_req, clk_in, scan_mode,
   scan_async_ctrl, force_rcc_on, force_rcc_off, rcg_ctrl_rf_clk,
   rcg_ctrl_rcc_rf_stb, rcg_ctrl_rcc_rf_state_in, mod_src_clk,
   mod_disable_ack, mod_force_enable, mod_init_state,
   mod_cg_en_add_dly, mod_grstn_cgen_dly
   );

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   //Module Main SM parameters
   parameter       DISABLE   = 2'b00;
   parameter       SYNC_RST  = 2'b01;
   parameter       ENABLE    = 2'b11;
   parameter       CLK_DIS   = 2'b10;

   parameter       SYNC_RST_PERIOD = 31;
   parameter       CLK_DIS_PERIOD  = 31;
   parameter       CLK_ENB_PERIOD  = 15;
   
   //Registers address
   parameter       MOD_STATE       = 4'd0;
   parameter       MOD_STATUS      = 4'd1;
   parameter       MOD_RSTN_CLK_EN = 4'd2;
   
   //----------------------------------------------------------------------------
   // Global reset from GRST block and hw reset request signals
   //----------------------------------------------------------------------------
   input                 grst_n;
   input                 hgrst_n;
   input                 mod_hw_rst_req;
   //----------------------------------------------------------------------------
   // Pre clock gate high speed clock input
   //----------------------------------------------------------------------------
   input                 clk_in;
   //----------------------------------------------------------------------------
   // DFT control signals
   //----------------------------------------------------------------------------
   input                 scan_mode;
   input                 scan_async_ctrl;
   input                 force_rcc_on;
   input                 force_rcc_off;
   //----------------------------------------------------------------------------
   // Reset and Clock from rcg_ctrl global registers file block
   //----------------------------------------------------------------------------
   input                 rcg_ctrl_rf_clk;
   //----------------------------------------------------------------------------
   // Configurations to/from rcg_ctrl rcc global registers file block
   //----------------------------------------------------------------------------
   input                 rcg_ctrl_rcc_rf_stb;
   input  [2:0]          rcg_ctrl_rcc_rf_state_in;
   output [5:0]          rcg_ctrl_rcc_rf_state_out;
   //----------------------------------------------------------------------------
   // RCC source clock from (functional high speed clock)
   //----------------------------------------------------------------------------
   input                 mod_src_clk;
   //----------------------------------------------------------------------------
   // RCC output reset signal
   //----------------------------------------------------------------------------
   output                mod_rst_out_n;
   //----------------------------------------------------------------------------
   // RCC output clock gate-en signal
   //----------------------------------------------------------------------------
   output                mod_gclk_cg_en;
   //----------------------------------------------------------------------------
   // RCC disable hand-shake signals
   //----------------------------------------------------------------------------
   output                mod_disable_req;
   input                 mod_disable_ack;
   output                mod_disable;
   //----------------------------------------------------------------------------
   // RCC default configuration signals
   //----------------------------------------------------------------------------
   input                 mod_force_enable;
   input [1:0]           mod_init_state;
   input                 mod_cg_en_add_dly;
   input [7:0]           mod_grstn_cgen_dly;
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   wire                  mod_src_clk;
   wire                  mod_gclk_cg_en;
   wire                  mod_cg_en;
   wire                  mod_cg_en_stat;
   wire                  mod_force_enable;

   //SM register
   reg [1:0]             state;
   reg [1:0]             n_state;   
   reg                   n_mod_cg_enable;
   reg                   n_mod_rst_n;   
   reg                   mod_cg_enable;   
   reg                   mod_rst_n;
   reg                   mod_disable_req;   
   reg                   n_mod_disable_req;
   reg [7:0]             sync_rst_cnt;
   reg [7:0]             n_sync_rst_cnt;   
   reg [7:0]             clk_dis_cnt;
   reg [7:0]             n_clk_dis_cnt;
   reg                   mod_disable;
   reg                   n_mod_disable;

   //Module registers
   wire [2:0]            rcg_ctrl_rcc_rf_state_in;
   reg [5:0]             rcg_ctrl_rcc_rf_state_out;
   wire                  mod_hw_rst_req_sync;
   reg [1:0]             mod_state_r;
   reg                   mod_rstn_clk_en_r;

   wire                  mod_cg_en_stat_sync;
   wire                  mod_rst_n_sync;
   
   wire                  mod_disable_ack;
   wire                  mod_disable_ack_sync2;

   wire                  rcc_async_reset_n;
   wire                  scan_async_ctrl_n;

   wire                  mod_cg_en_pre_dly;
   reg [8:0]             mod_cg_en_pre_dly_sreg;

   wire                  mod_rstn_clken_clk_sync2;
   wire                  mod_rstn_clk_sync2;
   wire                  mod_rstn_clk_en_r_mux;

   wire                  mod_rst_n_mux;
   reg                   clk_clr_n;
   wire                  rcc_async_reset_n_clk_sync;

   wire                  mod_rst_out_n;

   reg [7:0]             grst_n_dly_cntr;
   reg                   grst_n_cg_en;

   reg                   rcg_ctrl_rcc_rf_stb_s0;
   
   /*autowire*/
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   crg_clk_inv  I_scan_async_ctrl 
     (
       .a                     (scan_async_ctrl), 
       .y                     (scan_async_ctrl_n));

   crg_clk_mx2  I_rcc_async_reset_n
     (
      // Outputs
      .y                      (rcc_async_reset_n),
      // Inputs
      .a                      (grst_n),
      .b                      (scan_async_ctrl_n),
      .s                      (scan_mode));
          
   crg_sync2 I_hw_rst_sync
     (
      // Outputs
      .q                      (mod_hw_rst_req_sync),
      // Inputs
      .d                      (mod_hw_rst_req),
      .clk                    (rcg_ctrl_rf_clk));

   //----------------------------------------------------------------------------
   // RCC rf status register sampling. This status if fed back to the global rf
   // block.
   //----------------------------------------------------------------------------
   crg_sync2 I_mod_cg_en_stat_sync
     (
      // Outputs
      .q                      (mod_cg_en_stat_sync),
      // Inputs
      .d                      (mod_cg_en_stat),
      .clk                    (rcg_ctrl_rf_clk));

   crg_sync2 I_mod_rst_n_sync
     (
      // Outputs
      .q                      (mod_rst_n_sync),
      // Inputs
      .d                      (mod_rst_out_n),
      .clk                    (rcg_ctrl_rf_clk));
   
    always @ (posedge rcg_ctrl_rf_clk or negedge rcc_async_reset_n)
      begin
         if (!rcc_async_reset_n)
           begin
                rcg_ctrl_rcc_rf_state_out[5:0] <=  6'h0;
           end
         else
           begin
                rcg_ctrl_rcc_rf_state_out[5:0] <=  {mod_cg_en_stat_sync, mod_rst_n_sync, mod_state_r[1:0], state[1:0]};
           end // else: !if(!rcc_async_reset_n)
      end

   //----------------------------------------------------------------------------
   // This process loads the mod_state value coming from rf. If mod_force_enable 
   // is high, mod_state_r is forced to 2'b11 (enable state).
   // The rcg_ctrl_rcc_rf_stb signal is asserted one cycle before rcg_ctrl_rcc_rf_state_in[1:0]
   // is stable.
   //----------------------------------------------------------------------------
   always @ (posedge rcg_ctrl_rf_clk or negedge rcc_async_reset_n)
     begin
        if (!rcc_async_reset_n)
          begin
               mod_state_r[1:0] <=  mod_init_state[1:0];
               rcg_ctrl_rcc_rf_stb_s0 <=  1'b0;
          end
        else
          begin
               // Default
               rcg_ctrl_rcc_rf_stb_s0 <=  rcg_ctrl_rcc_rf_stb;
               if (mod_hw_rst_req_sync)
                 begin
                      mod_state_r[1:0] <=  mod_init_state[1:0];
                 end
               else
                 begin
                      mod_state_r[1:0] <=  mod_force_enable ? 2'b11 : (rcg_ctrl_rcc_rf_stb_s0 ? rcg_ctrl_rcc_rf_state_in[1:0] : mod_state_r[1:0]);
                 end // else: !if(mod_hw_rst_req_sync)
          end // else: !if(!rcc_async_reset_n)
     end

   //----------------------------------------------------------------------------
   // This process loads mod_rstn_clk_en_r regiser from rcg_ctrl_rcc_rf_state_in[2].
   // This signal, if asserted, forces the RCC to enable state.
   //----------------------------------------------------------------------------
   always @ (posedge rcg_ctrl_rf_clk or negedge rcc_async_reset_n)
     begin
        if (!rcc_async_reset_n)
          begin
               mod_rstn_clk_en_r <=  1'b0;
          end
        else
          begin
               mod_rstn_clk_en_r <=  rcg_ctrl_rcc_rf_stb_s0 ? rcg_ctrl_rcc_rf_state_in[2] : mod_rstn_clk_en_r;
          end // else: !if(!rcc_async_reset_n)
     end

   //----------------------------------------------------------------------------
   // Sync the clk stop ack to rcc clock domain
   //----------------------------------------------------------------------------
   crg_sync2 I_clkstop_ack_sync
     (
      // Outputs
      .q                      (mod_disable_ack_sync2),
      // Inputs
      .d                      (mod_disable_ack),
      .clk                    (rcg_ctrl_rf_clk));

   //----------------------------------------------------------------------------
   // RCC main state machine
   //----------------------------------------------------------------------------
   always @(*)
     begin

        n_state[1:0]        = state[1:0];
        n_mod_cg_enable     = mod_cg_enable;
        n_mod_rst_n         = mod_rst_n;
        n_mod_disable_req   = mod_disable_req;
        n_sync_rst_cnt[7:0] = sync_rst_cnt[7:0];
        n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0];
        n_mod_disable       = mod_disable;
        
        case (state)
          DISABLE:
            begin
               n_sync_rst_cnt[7:0]  = 8'h0;
               n_clk_dis_cnt[7:0]   = 8'h0;
               
               if (mod_state_r[1:0] != DISABLE)
                 begin
                    n_state         = SYNC_RST;
                    n_mod_cg_enable = 1'b1;
                    n_mod_rst_n     = 1'b0;
                 end
               else
                 begin
                    n_state         = DISABLE;
                    n_mod_cg_enable = 1'b0;
                    n_mod_rst_n     = 1'b0;
                 end // else: !if(mod_state_r[1:0] != DISABLE)
            end // case: DISABLE
          SYNC_RST:
            begin
               if (mod_state_r[1:0] == SYNC_RST)
                 begin
                    n_state         = SYNC_RST;
                    n_mod_cg_enable = 1'b1;
                    n_mod_rst_n     = 1'b0;
                 end
               else
                 begin
                    if (sync_rst_cnt[7:0] < SYNC_RST_PERIOD)
                      begin
                         n_state             = SYNC_RST;
                         n_mod_cg_enable     = 1'b1;
                         n_mod_rst_n         = 1'b0;
                         n_sync_rst_cnt[7:0] = sync_rst_cnt[7:0] + 1; 
                      end
                    else
                      begin
                         if (mod_state_r[1:0] == ENABLE)
                           begin
                              n_state             = CLK_DIS;
                              n_mod_cg_enable     = 1'b1;
                              n_mod_rst_n         = 1'b0;
                              n_sync_rst_cnt[7:0] = 8'h0; 
                              n_clk_dis_cnt[7:0]  = 8'h0;
                           end
                         else if (mod_state_r[1:0] == CLK_DIS)
                           begin
                              n_state             = CLK_DIS;
                              n_mod_cg_enable     = 1'b1;
                              n_mod_rst_n         = 1'b0;
                              n_sync_rst_cnt[7:0] = 8'h0;
                              n_clk_dis_cnt[7:0]  = 8'h0;
                           end
                         else
                           begin
                              n_state             = DISABLE;
                              n_mod_cg_enable     = 1'b0;
                              n_mod_rst_n         = 1'b0;
                              n_sync_rst_cnt[7:0] = 8'h0;
                           end // else: !if(mod_state_r[1:0] == CLK_DIS)
                      end // else: !if(sync_rst_cnt[7:0] < SYNC_RST_PERIOD)
                 end // else: !if(mod_state_r[1:0] == SYNC_RST)
            end // case: SYNC_RST
          
         
          CLK_DIS:
            begin
               if (clk_dis_cnt[7:0] < CLK_DIS_PERIOD)
                 begin
                    n_state             = CLK_DIS;
                    n_mod_cg_enable     = 1'b0;
                    n_mod_rst_n         = 1'b0;
                    n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0] +1;
                 end
               else if (clk_dis_cnt[7:0] < CLK_DIS_PERIOD + 40)
                 begin 
                    n_state             = CLK_DIS;
                    n_mod_cg_enable     = 1'b0;
                    n_mod_rst_n         = 1'b1;
                    n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0] +1;
                 end
               else
                 begin
                    if(mod_state_r[1:0] == CLK_DIS)
                      begin
                         n_state             = CLK_DIS;
                         n_mod_cg_enable     = 1'b0;
                         n_mod_rst_n         = 1'b1;
                         n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0];    
                      end
                    else if(mod_state_r[1:0] == ENABLE)
                      begin
                         n_state             = ENABLE;
                         n_mod_cg_enable     = 1'b0;
                         n_mod_rst_n         = 1'b1;
                         n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0];
                      end
                    else 
                      begin
                         n_state             = ENABLE;
                         n_mod_cg_enable     = 1'b0;
                         n_mod_rst_n         = 1'b1;
                         n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0];
                      end // else: !if(mod_state_r[1:0] == ENABLE)
                 end // else: !if(clk_dis_cnt[7:0] < CLK_DIS_PERIOD + 10)
            end // case: CLK_DIS
  
          ENABLE:
            begin
               if (mod_state_r[1:0] == ENABLE)
                 begin
                    n_state             = ENABLE;
                    n_mod_cg_enable     = 1'b1;
                    n_mod_rst_n         = 1'b1;
                    n_mod_disable       = 1'b0;
                    n_mod_disable_req   = 1'b0;
                 end
               else
                 begin
                    n_mod_disable_req = 1'b1;
                    if (mod_disable_ack_sync2)
                      begin
                         n_mod_disable_req   = 1'b0;
                         if (mod_state_r[1:0] == CLK_DIS)
                           begin
                              n_state             = CLK_DIS;
                              n_mod_cg_enable     = 1'b0;
                              n_mod_rst_n         = 1'b1;
                              n_mod_disable       = 1'b1;
                           end
                         else
                           begin
                              begin
                                 n_state             = SYNC_RST;
                                 n_mod_cg_enable     = 1'b1;
                                 n_mod_rst_n         = 1'b0;
                                 n_mod_disable       = 1'b1;
                                 n_sync_rst_cnt[7:0] = 8'h0;
                              end
                           end // else: !if(mod_state_r[1:0] == CLK_DIS)
                      end // if (mod_disable_ack_sync2)
                 end // else: !if(mod_state_r[1:0] == ENABLE)
            end // case: ENABLE
          default:
            begin
               n_state[1:0]        = state[1:0];
               n_mod_cg_enable     = mod_cg_enable;
               n_mod_rst_n         = mod_rst_n;
               n_mod_disable_req   = mod_disable_req;
               n_sync_rst_cnt[7:0] = sync_rst_cnt[7:0];
               n_clk_dis_cnt[7:0]  = clk_dis_cnt[7:0];
               n_mod_disable       = mod_disable;
            end
        endcase // case(state)
     end // always @ (*)

   //----------------------------------------------------------------------------
   // The SM is running on the rcc cbus clock = clock control clock which is free running clock.
   //----------------------------------------------------------------------------
   always @(posedge rcg_ctrl_rf_clk or negedge rcc_async_reset_n)
     begin

        if (!rcc_async_reset_n)
          begin
             state[1:0]           <=  DISABLE; 
             mod_rst_n            <=  1'b0;
             mod_cg_enable        <=  1'b0;
             mod_disable_req      <=  1'b0;
             sync_rst_cnt[7:0]    <=  8'h0;
             clk_dis_cnt[7:0]     <=  8'h0;
             mod_disable          <=  1'b1;        
          end // if (!rcc_async_reset_n)
        else if (mod_hw_rst_req_sync)
          begin
             state[1:0]           <=  SYNC_RST;
             mod_rst_n            <=  1'b0;
             mod_cg_enable        <=  1'b1;
             mod_disable_req      <=  1'b0;
             sync_rst_cnt[7:0]    <=  8'h0;
             clk_dis_cnt[7:0]     <=  8'h0;
             mod_disable          <=  1'b1;     
          end
        else
          begin
             state[1:0]           <=  n_state[1:0];
             mod_rst_n            <=  n_mod_rst_n;
             mod_cg_enable        <=  n_mod_cg_enable;
             mod_disable_req      <=  n_mod_disable_req;
             sync_rst_cnt[7:0]    <=  n_sync_rst_cnt[7:0];
             clk_dis_cnt          <=  n_clk_dis_cnt[7:0];
             mod_disable          <=  n_mod_disable & ~mod_rstn_clk_en_r;
          end 
     end // always @ (posedge rcg_ctrl_rf_clk or negedge rcc_async_reset_n)

   //----------------------------------------------------------------------------
   // Module clock enable and reset synchronizers
   //----------------------------------------------------------------------------

   //----------------------------------------------------------------------------
   //sync the mod_rstn_clk_en_r to each clock domain (register force)
   //----------------------------------------------------------------------------
   crg_clk_mx2  I_mod_rstn_clk_en_r_scan_mux
     (
      // Outputs
      .y                                (mod_rstn_clk_en_r_mux),
      // Inputs
      .a                                (mod_rstn_clk_en_r),
      .b                                (rcc_async_reset_n),
      .s                                (scan_mode));
   
   crg_sync2_arst I_rstn_clken_clk1_sync2
     (
      // Outputs
      .q                                (mod_rstn_clken_clk_sync2),
      // Inputs
      .clr_n                            (mod_rstn_clk_en_r_mux),
      .d                                (1'b1),
      .clk                              (mod_src_clk));


  //----------------------------------------------------------------------------
  // Module Reset
  //----------------------------------------------------------------------------
   
  //----------------------------------------------------------------------------
  // According to scan_mode, select between mod_rst_n (from state-machine) or
  // rcc_asynch_reset_n (tester conrolled reset).
  //----------------------------------------------------------------------------
  crg_clk_mx2  I_mod_rst_n_scan_mux
     (
      // Outputs
      .y                                (mod_rst_n_mux),
      // Inputs
      .a                                (mod_rst_n),
      .b                                (rcc_async_reset_n),
      .s                                (scan_mode));

  //----------------------------------------------------------------------------
  // Synchronize mod_rstn_clk_sync2 into RCC clock domain
  //----------------------------------------------------------------------------
  crg_sync2_arst I_rstn_sclk1_sync2
     (
      // Outputs
      .q                                (mod_rstn_clk_sync2),
      // Inputs
      .clr_n                            (mod_rst_n_mux),
      .d                                (1'b1),
      .clk                              (mod_src_clk));
   
  //----------------------------------------------------------------------------
  // rcc_async_reset_n synchronization into RCC clock domain
  //----------------------------------------------------------------------------
  crg_reset_sync I_rcc_async_reset_n_clk_sync
     (
      .rst_out_n                        (rcc_async_reset_n_clk_sync),
      .arst_n                           (rcc_async_reset_n),
      .scan_mode                        (scan_mode),
      .clk                              (mod_src_clk));

  //----------------------------------------------------------------------------
  // Module reset can be cleared from state machine (mod_rstn_clk_sync2) or
  // from RCC force-enable-register (mod_rstn_clken_clk_sync2).
  //----------------------------------------------------------------------------
  always @(posedge mod_src_clk or negedge rcc_async_reset_n_clk_sync)
    begin
       if (rcc_async_reset_n_clk_sync == 1'b0)
         begin
              clk_clr_n <=  1'b0;
         end
       else
         begin
              clk_clr_n <=  mod_rstn_clk_sync2 | mod_rstn_clken_clk_sync2;
         end
     end

  //----------------------------------------------------------------------------
  // Module reset final stage. In scan mode, reset is controllable by tester
  // via "scan_async_ctrl" in functional mode, reset is comming from "clk_clr_n"
  // register (state machine or RCC force-enable-register)
  //----------------------------------------------------------------------------
  crg_clk_mx2  I_mod_rst_n_mux
    (
     // Outputs
     .y                                (mod_rst_out_n),
     // Inputs
     .a                                (clk_clr_n),
     .b                                (rcc_async_reset_n),
     .s                                (scan_mode));

  //----------------------------------------------------------------------------
  // Module clock gaters
  //----------------------------------------------------------------------------
   
  //----------------------------------------------------------------------------
  // Module clock gater status is dervied from "mod_rstn_clken_clk_sync2"
  // (RCC force-enable-register) and from state-machine clock-gater enable
  // signal (mod_cg_en)
  //----------------------------------------------------------------------------
  assign mod_cg_en_stat = mod_rstn_clken_clk_sync2 | mod_cg_en;
   
  //----------------------------------------------------------------------------
  // This synchronizer synchronizes the sate-machine "mod_cg_enable" signal
  // into RCC functional clock domain.
  //----------------------------------------------------------------------------
  crg_sync2_arst I_mod_cg_en_sync2
    (
     // Outputs
     .q                                (mod_cg_en_pre_dly),
     // Inputs
     .clr_n                            (rcc_async_reset_n_clk_sync),
     .d                                (mod_cg_enable),
     .clk                              (mod_src_clk));
   
  //----------------------------------------------------------------------------
  // This process generates 9 cycles delyed version of mod_cg_en_pre_dly
  // signal.
  //----------------------------------------------------------------------------
  always @(posedge mod_src_clk or negedge rcc_async_reset_n_clk_sync)
    begin
         if (rcc_async_reset_n_clk_sync == 1'b0)
           begin
                mod_cg_en_pre_dly_sreg <= 9'h0;
           end
         else
           begin
                mod_cg_en_pre_dly_sreg[0] <=  mod_cg_en_pre_dly;
                mod_cg_en_pre_dly_sreg[8:1] <=  mod_cg_en_pre_dly_sreg[7:0];
           end
    end

  //----------------------------------------------------------------------------
  // This multiplexer seletcs bettwen delayed and undelayed versions of the
  // post-synchronized version of the RCC state-machine clock gater enable.
  //----------------------------------------------------------------------------
  crg_clk_mx2  I_cg_en1_dly_mux
    (
     // Outputs
     .y                                (mod_cg_en),
     // Inputs
     .a                                (mod_cg_en_pre_dly),
     .b                                (mod_cg_en_pre_dly_sreg[8]),
     .s                                (mod_cg_en_add_dly));
   
  //----------------------------------------------------------------------------
  // This process adds delay between the de-assertion of hgrst to the enabling
  // of the clock-gater during grst_n sequence.
  //----------------------------------------------------------------------------
  always @(posedge clk_in or negedge hgrst_n)
    begin
         if (hgrst_n == 1'b0)
           begin
                grst_n_dly_cntr <=  8'h0;
                grst_n_cg_en <=  1'b0;
           end
         else
           begin
                if (grst_n == 1'b0)
                  begin
                    if (grst_n_dly_cntr < mod_grstn_cgen_dly)
                      begin
                           grst_n_dly_cntr <=  grst_n_dly_cntr + 8'h1;
                      end
                    else
                      begin
                           grst_n_dly_cntr <=  grst_n_dly_cntr;
                           grst_n_cg_en <=  1'b1;
                      end
                  end
                else
                  begin
                       grst_n_cg_en <=  1'b0;
                       grst_n_dly_cntr <=  8'h0;
                  end
           end
    end

  assign mod_gclk_cg_en = (mod_cg_en | grst_n_cg_en | mod_rstn_clken_clk_sync2 | force_rcc_on) & ~force_rcc_off;
   
endmodule // rcg_ctrl_rcc

// Local Variables:
// verilog-library-directories:("." "../../")
// End:
