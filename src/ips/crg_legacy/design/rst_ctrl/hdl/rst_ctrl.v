//-----------------------------------------------------------------------------
// Title         : Reset Controller
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : Reset Controller
// Author        : Naftaly Blum
// Created       : 04.03.2010
// Last modified : Time-stamp: <2016-03-15 1120 naftalyb>
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by Ceragon This model is the confidential and
// proprietary property of Ceragon and the possession or use of this
// file requires a written license from Ceragon.
//------------------------------------------------------------------------------
// Modification history :
// 04.03.2010 : created
// [Slava] 20.10.2015 : Addition of address monitoring mechanism of RegFile
//-----------------------------------------------------------------------------

module rst_ctrl (/*autoarg*/
   // Outputs
   pre_grst_n_ind, apor_n, hgrst_n, grst_n, pad_highz,
   rst_ctrl_bad_addr_irq, rst_ctrl_bad_addr_unmsk_irq,
   rst_ctrl_apbpslverr_i, rst_ctrl_apbprdata_i, rst_ctrl_apbpready_i,
   // Inputs
   por_n, rst_n, wd_rst_req, mips_cpu_rst_req, mips_per_rst_req,
   mips_hw_rst_cause_gpio, mips_hw_rst_cause_gpio_en,
   mips_hw_rst_cause_mips_wd, mips_jtag_swrst_en, scan_enable,
   scan_mode, mbist_mode, dft_clk_en, phy_cg_sel, clk_in_ref,
   scfg_sw_rst_mask, scfg_mips_rst_mask, rst_ctrl_clk, rst_ctrl_rst_n,
   rst_ctrl_apbpaddr_o, rst_ctrl_apbpenable_o, rst_ctrl_apbpreset_no,
   rst_ctrl_apbpsel_o, rst_ctrl_apbpwdata_o, rst_ctrl_apbpwrite_o,
   apb_clk_dis, apb_sgn_clk, apb_sgn_rst_n
   );

   parameter       AW               = 8;	// 2^8 bytes = 256 bytes space
   parameter       RESET_DURATION   = 256;
   localparam      DW = 32;
   
   //Registers Address
   parameter       SOFT_RESET       = {{(AW-4){1'b0}} ,2'h0, 2'h0};
   parameter       CAUSE            = {{(AW-4){1'b0}} ,2'h1, 2'h0};
   parameter       UNLOCK0          = {{(AW-4){1'b0}} ,2'h2, 2'h0};
   parameter       UNLOCK1          = {{(AW-4){1'b0}} ,2'h3, 2'h0};
   
   localparam MAX_SLV_ADDR = UNLOCK1;
   localparam [AW-1:0] ONE_WORD = {{(AW-3){1'b0}},3'b100};    // AW-wide one vector

//--------------------------------------------- Address monitoring registers --------------------------------------------//

   // The last legal address of the RST_CTRL slave is UNLOCK1 = 8b'00001100, so next address allocated to BAD_RD_ADDR
   localparam BAD_RD_ADDR = MAX_SLV_ADDR + ONE_WORD; // 8b'00010000 bytes ==> 0x10

   // Next address of 0x24 allocated to BAD_WR_ADDR
   localparam BAD_WR_ADDR = BAD_RD_ADDR + ONE_WORD;                   // 8b'00010100 bytes ==> 0x14
   
   // Next address of 0x28 allocated to IRQ_SIG_MASK (internal)
   localparam IRQ_SIG_MASK = BAD_WR_ADDR + ONE_WORD;                  // 8b'00011000 bytes ==> 0x18

   // Next address of 0x2C allocated to IRQ_SIG_CLR_P
   localparam IRQ_SIG_CLR_P = IRQ_SIG_MASK + ONE_WORD;                // 8b'00011100 bytes ==> 0x1C

   // Next address of 0x30 allocated to IRQ_SIG_OUT - maskable interrupt
   localparam IRQ_SIG_OUT = IRQ_SIG_CLR_P + ONE_WORD;                 // 8b'00100000 bytes ==> 0x20

   // Next address of 0x34 allocated to IRQ_SIG_OUT_UNMSK - unmaskable interrupt
   localparam IRQ_SIG_OUT_UNMSK = IRQ_SIG_OUT + ONE_WORD;             // 8b'00100100 bytes ==> 0x24  
   
   localparam MAX_VAL_ADDR = IRQ_SIG_OUT_UNMSK;
   
//-----------------------------------------------------------------------------------------------------------------------//       
   //unlock psw
   parameter       KICK_DATA0       = 32'h20406080;
   parameter       KICK_DATA1       = 32'h10305070; 
                                       
   //Power on Reset (POR_N) and RST_N directly from PADS
   input           por_n;
   input           rst_n;
   
   //Reset request from pll "pll_reset" due to pll configuration changing, or due to other
   //HW causes such as WDT Emulation etc.
   input           wd_rst_req;
   input           mips_cpu_rst_req;
   input           mips_per_rst_req;

   // Reset causes from tear-down block (gpio or mips watch-dog)
   input           mips_hw_rst_cause_gpio;
   input           mips_hw_rst_cause_gpio_en;
   input           mips_hw_rst_cause_mips_wd;

   //Soft Reset Enable. EJTAG can deassert this signal if it wants to mask soft resets.
   // If this signal is deasserted all soft reset sources are masked.
   input           mips_jtag_swrst_en;

   // DFT signals
   input           scan_enable;
   input           scan_mode;
   input           mbist_mode; 
   
   input           dft_clk_en;

   input [1:0]     phy_cg_sel;   
   
   //Reference clock in this clock is either XTAL clock or ext source clock
   //The mux which select between them is located in the pll controller.  
   input           clk_in_ref;
   
   //pre greset indecation to pll controller to gate the clock befor grest_n is issued
   output          pre_grst_n_ind;
   //Syncronized por_n to "clk_in_ref"
   output          apor_n;

   //Sync reset to sys_clk_in_ref 
   output          hgrst_n;
   //global reset to the device - will be cascaded into RCG's
   output          grst_n;
   
   output          pad_highz;

   // Address monitoring interrupts
   output reg      rst_ctrl_bad_addr_irq;   
   output reg      rst_ctrl_bad_addr_unmsk_irq;   

   //Reset  MASK
   input           scfg_sw_rst_mask;
   input           scfg_mips_rst_mask;
   
   //APB Slave interface
   input           rst_ctrl_clk;
   input           rst_ctrl_rst_n;
   input [AW-1:0]  rst_ctrl_apbpaddr_o;
   input           rst_ctrl_apbpenable_o;
   input           rst_ctrl_apbpreset_no;
   input           rst_ctrl_apbpsel_o;
   input [DW-1:0]    rst_ctrl_apbpwdata_o;
   input           rst_ctrl_apbpwrite_o;
   output          rst_ctrl_apbpslverr_i; 

   input           apb_clk_dis;            
   input           apb_sgn_clk;            
   input           apb_sgn_rst_n;          
   
   output [DW-1:0]   rst_ctrl_apbprdata_i;
   output          rst_ctrl_apbpready_i;

   /*autoinput*/

   //*autooutput*/

   /*autowire*/

   /*autotieoff*/

   wire            rst_ctrl_cbus_req;
   wire [AW-1:0]   rst_ctrl_cbus_address;
   wire            rst_ctrl_cbus_cmd;
   wire [3:0]      rst_ctrl_cbus_byten;
   wire [DW-1:0]     rst_ctrl_cbus_wdata;
   reg  [DW-1:0]     rst_ctrl_cbus_rdata;
   wire            rst_ctrl_cbus_rresp   = 1'b1;
   wire            rst_ctrl_cbus_waccept = 1'b1;
//   wire            rst_ctrl_cbus_rresp   = rst_ctrl_cbus_req & rst_ctrl_cbus_cmd;
//   wire            rst_ctrl_cbus_waccept = rst_ctrl_cbus_req & ~rst_ctrl_cbus_cmd;

   wire            apor_n;
   wire            apor_n_tmp;
   wire            arst_n;

   reg             hgrst_n_r;
   wire            hgrst_n;
   
   reg [15:0]      grst_n_cnt;
   wire            grst_n;
   reg             grst_n_r;
   reg             pre_grst_n_ind;
   
   reg             soft_reset_r;
   reg             soft_reset_r_d1;
   reg [15:0]      reset_cause_r; //Read only
   reg [DW-1:0]      rst_ctrl_cbus_rdata_t;
   
   reg             grst_n_req_d1;
   reg             grst_n_req_d2;
   
   reg             grst_n_req_pls_d1;
   reg             grst_n_req_pls_d2;
   reg             grst_n_req_pls_d3;
   reg             grst_n_req_pls_d4;
   
   /*apb2cbus AUTO_TEMPLATE (
    .cbus_s_clk                       (rst_ctrl_clk),
    .cbus_s_rst_n                     (rst_ctrl_rst_n),
    .cbus_s_address                   (rst_ctrl_cbus_address[]),
    .cbus_s_bytecnt                   (),
    .cbus_s_byten                     (rst_ctrl_cbus_byten[3:0]),
    .cbus_s_cmd                       (rst_ctrl_cbus_cmd),
    .cbus_s_first                     (),
    .cbus_s_last                      (),
    .cbus_s_req                       (rst_ctrl_cbus_req),
    .cbus_s_wdata                     (rst_ctrl_cbus_wdata[DW-1:0]),
    .cbus_s_rdatap                    (rst_ctrl_cbus_rdata[DW-1:0]),
    .cbus_s_rresp                     (rst_ctrl_cbus_rresp),
    .cbus_s_waccept                   (rst_ctrl_cbus_waccept),
    .cbus_s_sgn_clk     (apb_sgn_clk),
    .cbus_s_sgn_rst_n   (apb_sgn_rst_n),
    .cbus_s_clk_dis     (apb_clk_dis),
    .\(apb.*\)                        (rst_ctrl_\1[]),
    ); */
   
   apb2cbus #(.ADDRW(AW)) I_rst_ctrl_apb2cbus
     (
      // Outputs
      .apbpready_i                      (rst_ctrl_apbpready_i),  // Templated
      .apbpslverr_i                     (rst_ctrl_apbpslverr_i), // Templated
      .apbprdata_i                      (rst_ctrl_apbprdata_i[31:0]), // Templated
      .cbus_s_address                   (rst_ctrl_cbus_address[AW-1:0]), // Templated
      .cbus_s_bytecnt                   (),                      // Templated
      .cbus_s_byten                     (rst_ctrl_cbus_byten[3:0]), // Templated
      .cbus_s_cmd                       (rst_ctrl_cbus_cmd),     // Templated
      .cbus_s_first                     (),                      // Templated
      .cbus_s_last                      (),                      // Templated
      .cbus_s_req                       (rst_ctrl_cbus_req),     // Templated
      .cbus_s_wdata                     (rst_ctrl_cbus_wdata[DW-1:0]), // Templated
      // Inputs
      .apbpaddr_o                       (rst_ctrl_apbpaddr_o[AW-1:0]), // Templated
      .apbpenable_o                     (rst_ctrl_apbpenable_o), // Templated
      .apbpreset_no                     (rst_ctrl_apbpreset_no), // Templated
      .apbpsel_o                        (rst_ctrl_apbpsel_o),    // Templated
      .apbpwdata_o                      (rst_ctrl_apbpwdata_o[31:0]), // Templated
      .apbpwrite_o                      (rst_ctrl_apbpwrite_o),  // Templated
      .cbus_s_sgn_clk                   (apb_sgn_clk),           // Templated
      .cbus_s_sgn_rst_n                 (apb_sgn_rst_n),         // Templated
      .cbus_s_clk                       (rst_ctrl_clk),          // Templated
      .cbus_s_rst_n                     (rst_ctrl_rst_n),        // Templated
      .cbus_s_clk_dis                   (apb_clk_dis),           // Templated
      .cbus_s_rdatap                    (rst_ctrl_cbus_rdata[DW-1:0]), // Templated
      .cbus_s_rresp                     (rst_ctrl_cbus_rresp),   // Templated
      .cbus_s_waccept                   (rst_ctrl_cbus_waccept)); // Templated
   
   //Sync POR_N and RST_N to "clk_in_ref" which is XTAL clock or ext source clock 
   crg_sync2_arst I_por_n_sync2
     (
      // Outputs
      .q                                (apor_n_tmp),
      // Inputs
      .clr_n                            (por_n),
      .d                                (1'b1),
      .clk                              (clk_in_ref));
   

   crg_clk_mx2 I_test_apor_n_mux
     (
      // Outputs
      .y                                (apor_n),
      // Inputs
      .a                                (apor_n_tmp),
      .b                                (por_n),
      .s                                (scan_mode));
   
   crg_sync2_arst I_rst_n_sync2
     (
      // Outputs
      .q                                (arst_n),
      // Inputs
      .clr_n                            (rst_n),
      .d                                (1'b1),
      .clk                              (clk_in_ref));

   
   //hgrst_n assersion combination of sync por_a -->apor_n and rst_n -->arst_n
   always @(posedge clk_in_ref)
       hgrst_n_r <= (apor_n & arst_n);
   
   // Yossi: scan_async_ctrl goes directly to async logic at scan mode
   // crg_clk_mx2 dft_hgrst_n_mux ( .a(hgrst_n_r), .b(scan_async_ctrl), .s(scan_mode), .y(hgrst_n));
   assign hgrst_n = hgrst_n_r;

   
   //Global Reset request due to pll , soft reset or hw request vector

   //sync Reset request signals to rst controller clk_in_ref clock domain

   wire            scfg_mips_rst_mask_sync2;
   reg             scfg_mips_rst_mask_sync2cbus_d1;
   reg             mips_cpu_rst_req_tmp_sync2cbus_d1;
   reg             mips_per_rst_req_tmp_sync2cbus_d1;
   
   crg_sync2 I_mips_rst_mask_sync
     (
      // Outputs
      .q(scfg_mips_rst_mask_sync2),
      // Inputs
      .d(scfg_mips_rst_mask_sync2cbus_d1),
      .clk(clk_in_ref));

      
   wire            mips_jtag_swrst_en_sync2;   
   crg_sync2 I_mips_swrst_en_sync
     (
      // Outputs
      .q(mips_jtag_swrst_en_sync2),
      // Inputs
      .d(mips_jtag_swrst_en),
      .clk(clk_in_ref));

   wire            wd_rst_req_in_sync2;
    crg_sync2_arst I_wd_rst_req_in_sync2
     (
      // Outputs
      .q(wd_rst_req_in_sync2),
      // Inputs
      .clr_n(apor_n),
      .d(wd_rst_req),
      .clk(rst_ctrl_clk));

   wire            wd_rst_req_sync2;
   reg             wd_rst_req_d1;
    crg_sync2_arst I_wd_rst_sync
     (
      // Outputs
      .q(wd_rst_req_sync2),
      // Inputs
      .clr_n(apor_n),
      .d(wd_rst_req_d1),
      .clk(clk_in_ref));

   // Delay wd_rst_req by one cbus_clk cycles to ensure it lock by the cause register before it will initiate the grst_n process.
   always @ (posedge rst_ctrl_clk or negedge rst_ctrl_rst_n)
     begin
        if (!rst_ctrl_rst_n)
          begin
               wd_rst_req_d1 <= 1'b0;
          end
        else
          begin
               wd_rst_req_d1 <= wd_rst_req_in_sync2;
          end // else: !if(!rst_ctrl_rst_n)
     end

   wire            mips_cpu_rst_req_sync2;
   wire            mips_cpu_rst_req_tmp_sync2;
   assign          mips_cpu_rst_req_sync2 = ~scfg_mips_rst_mask_sync2 & mips_cpu_rst_req_tmp_sync2;
   
   
   crg_sync2 I_mips_cpu_rst_req_sync2
     (
      // Outputs
      .q(mips_cpu_rst_req_tmp_sync2),
      // Inputs
      .d(mips_cpu_rst_req_tmp_sync2cbus_d1),
      .clk(clk_in_ref));
   
   wire            mips_per_rst_req_sync2;
   wire            mips_per_rst_req_tmp_sync2;

   assign          mips_per_rst_req_sync2 = ~scfg_mips_rst_mask_sync2 & mips_per_rst_req_tmp_sync2;
   
   crg_sync2 I_mips_per_rst_req_sync2
     (
      // Outputs
      .q(mips_per_rst_req_tmp_sync2),
      // Inputs
      .d(mips_per_rst_req_tmp_sync2cbus_d1),
      .clk(clk_in_ref));

   wire            soft_reset_r_sync2;
   
   crg_sync2 I_soft_reset_r_sync2
     (
      // Outputs
      .q(soft_reset_r_sync2),
      // Inputs
      .d(soft_reset_r_d1),
      .clk(clk_in_ref));
   
   wire                    grst_n_w_muxed;
   wire                    grst_n_w;
   assign                  grst_n_w = (wd_rst_req_sync2 |
                                       mips_cpu_rst_req_sync2 | 
                                       mips_per_rst_req_sync2 | 
                                       soft_reset_r_sync2) & mips_jtag_swrst_en_sync2;

   reg                     grst_n_req;
   
   // In scan_mode, we block grst_n_w external souces.
   crg_clk_mx2 grst_n_w_mux (.a(grst_n_w), .b(1'b0), .s((scan_mode | mbist_mode)), .y(grst_n_w_muxed));
   
   always @ (posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_req <= 1'b0;
     else
       grst_n_req <= grst_n_w_muxed;
   
   //pipe the reset request 4 Cycles of ==> "clk_in_ref" , and create stretched pulse
   
   always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_req_d1 <= 1'b0;
     else
       grst_n_req_d1 <= grst_n_req;

   //level to pulse 
   wire           grst_n_req_pls = ~grst_n_req_d1 & grst_n_req;
 
   always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_req_pls_d1 <= 1'b0;
     else
       grst_n_req_pls_d1 <= grst_n_req_pls;
   
   always @(posedge clk_in_ref  or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_req_pls_d2 <= 1'b0;
     else
       grst_n_req_pls_d2 <= grst_n_req_pls_d1;
   
   always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_req_pls_d3 <= 1'b0;
     else
       grst_n_req_pls_d3 <= grst_n_req_pls_d2;

   reg            grst_n_req_strch;   
   always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_req_strch <= 1'b0;
     else
       grst_n_req_strch <= grst_n_req_pls_d1 | grst_n_req_pls_d2 | grst_n_req_pls_d3;
   
   //=========================
   //grst_n generation
   //=========================
   
    always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_r  <= 1'b0;
     else
       begin
          if(grst_n_cnt[15:0] == RESET_DURATION)
            grst_n_r  <= ~grst_n_req_strch;
          else if(grst_n_cnt[15:0] < RESET_DURATION)
            grst_n_r  <= 1'b0;         
       end // else: !if(!hgrst_n)
   
   // Yossi: scan_async_ctrl goes directly to async logic at scan mode
   // crg_clk_mx2 dft_grst_n_mux ( .a(grst_n_r), .b(scan_async_ctrl), .s(scan_mode), .y(grst_n));
   assign grst_n = grst_n_r;

        
   //grst_n counter
   always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       grst_n_cnt[15:0] <= 16'h0;
     else if (grst_n_req_strch)
       grst_n_cnt[15:0] <= 16'h0;
     else
       grst_n_cnt[15:0] <= (grst_n_cnt[15:0] < RESET_DURATION) ?  grst_n_cnt[15:0] +1 : grst_n_cnt[15:0];
   
   //pre_grst_n_ind generation
    always @(posedge clk_in_ref or negedge hgrst_n)
     if (!hgrst_n)
       pre_grst_n_ind  <= 1'b0;
     else
       pre_grst_n_ind  <= ((grst_n_cnt[15:0] > RESET_DURATION - 5) & ~grst_n)   ? 1'b1 : 1'b0;


   
   // ----------------------------   Cbus Interface   -----------------------------------------
   //Unlock reset controller
   reg        rst_ctrl_is_unlock0;
   reg        rst_ctrl_is_unlock1;
   wire       rst_ctrl_is_unlock;
     
   wire       unlock_req0;
   wire       unlock_req1;
   
   assign     unlock_req0 = (rst_ctrl_cbus_req & ~rst_ctrl_cbus_cmd) &
                            (rst_ctrl_cbus_address[AW-1:0] == UNLOCK0) &
                            (rst_ctrl_cbus_wdata[DW-1:0]  == KICK_DATA0);
   
   assign     unlock_req1 = (rst_ctrl_cbus_req & ~rst_ctrl_cbus_cmd)& 
                            (rst_ctrl_cbus_address[AW-1:0] == UNLOCK1)&
                            (rst_ctrl_cbus_wdata[DW-1:0]  == KICK_DATA1);
   
   always @ (posedge rst_ctrl_clk or negedge rst_ctrl_rst_n)
     begin
        if (!rst_ctrl_rst_n)
          begin
             rst_ctrl_is_unlock0 <= 1'd0;
             rst_ctrl_is_unlock1 <= 1'd0;
          end
        else
          begin
             rst_ctrl_is_unlock0 <= unlock_req0 ? 1'b1 : rst_ctrl_is_unlock0;
             rst_ctrl_is_unlock1 <= (unlock_req1 & rst_ctrl_is_unlock0) ? 1'b1 : rst_ctrl_is_unlock1;
          end
     end // always @ (posedge rst_ctrl_clk or negedge grst_n)

   assign rst_ctrl_is_unlock = rst_ctrl_is_unlock1 & rst_ctrl_is_unlock0;
   
   
   //SOFT Reset Register
   wire    soft_reset_req;
   wire    scfg_sw_rst_mask; //this signal is from cbus clk domain
   
   assign  soft_reset_req = rst_ctrl_is_unlock & 
                            (rst_ctrl_cbus_req & ~rst_ctrl_cbus_cmd) & 
                            (rst_ctrl_cbus_address[AW-1:0] == SOFT_RESET);
      
   always @ (posedge rst_ctrl_clk or negedge rst_ctrl_rst_n)
     begin
        if (!rst_ctrl_rst_n)
          begin
               soft_reset_r <= 1'd0;
               soft_reset_r_d1 <= 1'd0;
          end
        else
          begin
               // Delay soft_reset_r by one cbus_clk cycles to ensure it lock by the cause register before it will initiate the grst_n process.
               soft_reset_r_d1 <= soft_reset_r;
               soft_reset_r <= (soft_reset_req & ~scfg_sw_rst_mask) ? rst_ctrl_cbus_wdata[0] : soft_reset_r;
          end // else: !if(!rst_ctrl_rst_n)
     end
   
   //Reset Cause register is resets only due to por_n and after read.

   wire            scfg_mips_rst_mask_sync2cbus;
   
   crg_sync2_arst I_mips_rst_mask_sync2cbus
     (
      // Outputs
      .q(scfg_mips_rst_mask_sync2cbus),
      // Inputs
      .clr_n(rst_ctrl_rst_n),
      .d(scfg_mips_rst_mask),
      .clk(rst_ctrl_clk));
  

   wire            mips_cpu_rst_req_sync2cbus;
   wire            mips_cpu_rst_req_tmp_sync2cbus;

   assign          mips_cpu_rst_req_sync2cbus = ~scfg_mips_rst_mask_sync2cbus & mips_cpu_rst_req_tmp_sync2cbus;
   
   crg_sync2_arst I_mips_cpu_rst_req_sync2cbus
     (
      // Outputs
      .q(mips_cpu_rst_req_tmp_sync2cbus),
      // Inputs
      .clr_n(rst_ctrl_rst_n),
      .d(mips_cpu_rst_req),
      .clk(rst_ctrl_clk));


   wire            mips_per_rst_req_sync2cbus;
   wire            mips_per_rst_req_tmp_sync2cbus;

   assign          mips_per_rst_req_sync2cbus = ~scfg_mips_rst_mask_sync2cbus & mips_per_rst_req_tmp_sync2cbus;
   
   crg_sync2_arst I_mips_per_rst_req_sync2cbus
     (
      // Outputs
      .q(mips_per_rst_req_tmp_sync2cbus),
      // Inputs
      .clr_n(rst_ctrl_rst_n),
      .d(mips_per_rst_req),
      .clk(rst_ctrl_clk));

   // Delay  by one cbus_clk cycles to ensure it lock by the cause register before it will initiate the grst_n process.
   always @ (posedge rst_ctrl_clk or negedge rst_ctrl_rst_n)
     begin
        if (!rst_ctrl_rst_n)
          begin
               scfg_mips_rst_mask_sync2cbus_d1 <= 1'b0;
               mips_cpu_rst_req_tmp_sync2cbus_d1 <= 1'b0;
               mips_per_rst_req_tmp_sync2cbus_d1 <= 1'b0;
          end
        else
          begin
               scfg_mips_rst_mask_sync2cbus_d1 <= scfg_mips_rst_mask_sync2cbus;
               mips_cpu_rst_req_tmp_sync2cbus_d1 <= mips_cpu_rst_req_tmp_sync2cbus;
               mips_per_rst_req_tmp_sync2cbus_d1 <= mips_per_rst_req_tmp_sync2cbus;
          end // else: !if(!rst_ctrl_rst_n)
     end
   
   wire    mips_hw_rst_cause_gpio_en_sync2cbus;
   wire    mips_hw_rst_cause_gpio_sync2cbus;
   wire    mips_hw_rst_cause_gpio_tmp_sync2cbus;
   assign  mips_hw_rst_cause_gpio_sync2cbus = mips_hw_rst_cause_gpio_tmp_sync2cbus & mips_hw_rst_cause_gpio_en_sync2cbus;
   
   crg_sync2_arst I_mips_hw_rst_cause_gpio_tmp_sync2cbus
     (
      // Outputs
      .q(mips_hw_rst_cause_gpio_tmp_sync2cbus),
      // Inputs
      .clr_n(rst_ctrl_rst_n),
      .d(mips_hw_rst_cause_gpio),
      .clk(rst_ctrl_clk));
   
   crg_sync2_arst I_mips_hw_rst_cause_gpio_en_sync2cbus
     (
      // Outputs
      .q(mips_hw_rst_cause_gpio_en_sync2cbus),
      // Inputs
      .clr_n(rst_ctrl_rst_n),
      .d(mips_hw_rst_cause_gpio_en),
      .clk(rst_ctrl_clk));

   wire          reset_cause_write = rst_ctrl_cbus_req & ~rst_ctrl_cbus_cmd & (rst_ctrl_cbus_address[AW-1:0] == CAUSE);
   
   wire          lock_reset_cause;
   reg           lock_reset_cause_s0;
   
   assign        lock_reset_cause = |{mips_hw_rst_cause_mips_wd,mips_hw_rst_cause_gpio_sync2cbus,wd_rst_req_in_sync2,mips_cpu_rst_req_sync2cbus,mips_per_rst_req_sync2cbus,soft_reset_r};
   
   always @ (posedge rst_ctrl_clk or negedge apor_n)
     begin
          if (!apor_n)
            begin
                 reset_cause_r[5:0] <= 6'd0;
                 reset_cause_r[6]   <= 1'b1; // set por cause
                 reset_cause_r[15:7] <= 9'd0;
                 lock_reset_cause_s0 <= 1'b0;
            end
          else
            begin
                 // Default
                 lock_reset_cause_s0 <= lock_reset_cause;
                 if (lock_reset_cause == 1'b1 && lock_reset_cause_s0 == 1'b0)
                   begin
                        reset_cause_r[15:0] <= {10'b0,mips_hw_rst_cause_mips_wd,mips_hw_rst_cause_gpio_sync2cbus,wd_rst_req_in_sync2,mips_cpu_rst_req_sync2cbus,mips_per_rst_req_sync2cbus,soft_reset_r};
                   end
                 else if (reset_cause_write)
                   begin
                        reset_cause_r[15:0] <= 16'd0;
                   end
                 else
                   begin
                        reset_cause_r[15:0] <= reset_cause_r[15:0];
                   end // else: !if(reset_cause_write)
            end // else: !if(!apor_n)
     end // always @ (posedge rst_ctrl_clk or negedge apor_n)

   wire          read_trans = rst_ctrl_cbus_req & rst_ctrl_cbus_cmd;
   reg				rd_err_p_irq_sig_t;
   reg	[AW-1:0]	bad_rd_addr_t;

   assign pad_highz = ~apor_n | ~hgrst_n | ~grst_n; 
   
//----------------------------------- Address monitoring expansion (START) ------------------------------------//

   wire                 gclk_en;
   wire                 gclk;                
   wire                 write_trans;
   wire [1:0]           irq_sig_clr_p;
   wire [1:0]           irq_sig_out;   
   wire [1:0]           irq_sig_out_unmsk;
   
   wire                 sig_out_irq_net = 1'b0;
   wire                 sig_out_unmsk_irq_net = 1'b0;

   reg [AW-1:0]     bad_rd_addr;
   reg [AW-1:0]     bad_wr_addr;
   reg                  rd_err_p_irq_sig;
   reg                  wr_err_p_irq_sig;
   reg                  rd_err_p_irq_sig_reg;
   reg                  wr_err_p_irq_sig_reg;
    
   assign write_trans = rst_ctrl_cbus_req & (!rst_ctrl_cbus_cmd);
   
//================================== Asynchronous CBUS READ =======================================//  
   always @ (*)
     begin
	    rd_err_p_irq_sig_t = 1'b0;	// Default RD interrupt indicator turned OFF
		bad_rd_addr_t[AW-1:0] = {AW{1'b0}};
		rst_ctrl_cbus_rdata_t[DW-1:0] = {DW{1'b0}};	  // Prevent latches
        case (rst_ctrl_cbus_address[AW-1:0])
          CAUSE        : rst_ctrl_cbus_rdata_t = {16'd0,reset_cause_r[15:0]};
          UNLOCK0      : rst_ctrl_cbus_rdata_t = {31'd0,rst_ctrl_is_unlock0};
          UNLOCK1      : rst_ctrl_cbus_rdata_t = {31'd0,rst_ctrl_is_unlock1};  
          SOFT_RESET   : rst_ctrl_cbus_rdata_t = 32'h0;
          BAD_RD_ADDR  : rst_ctrl_cbus_rdata_t[AW-1:0] = bad_rd_addr[AW-1:0];
          BAD_WR_ADDR  : rst_ctrl_cbus_rdata_t[AW-1:0] = bad_wr_addr[AW-1:0];	
          IRQ_SIG_MASK : rst_ctrl_cbus_rdata_t[1:0] = {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg};
          IRQ_SIG_OUT  : rst_ctrl_cbus_rdata_t[1:0] = irq_sig_out[1:0];
          IRQ_SIG_OUT_UNMSK  : rst_ctrl_cbus_rdata_t[1:0] = irq_sig_out_unmsk[1:0];
          default: begin
				rst_ctrl_cbus_rdata_t[DW-1:0] = 32'hBABADBAD;
				rd_err_p_irq_sig_t = 1'b1;	// RD interrupt indicator turned ON
				bad_rd_addr_t[AW-1:0] = rst_ctrl_cbus_address[AW-1:0]; // Save the exceeding address
			end	
        endcase // case(rst_ctrl_cbus_address[AW-1:0])
     end
//=================================================================================================//	 
   
//=================================== Registration of READ data ===================================//
   always @ (posedge gclk or negedge rst_ctrl_rst_n)
     begin
        if (!rst_ctrl_rst_n) begin
          rst_ctrl_cbus_rdata[DW-1:0] <= {DW{1'b0}};
		  bad_rd_addr[AW-1:0] <= {AW{1'b0}};
          rd_err_p_irq_sig <= 1'b0;
		end
        else begin
          rst_ctrl_cbus_rdata[DW-1:0] <= read_trans ? rst_ctrl_cbus_rdata_t[DW-1:0] : rst_ctrl_cbus_rdata[DW-1:0];
		  bad_rd_addr[AW-1:0] <= (read_trans) ? bad_rd_addr_t[AW-1:0] : bad_rd_addr[AW-1:0];
		  rd_err_p_irq_sig <= (read_trans) ? rd_err_p_irq_sig_t : rd_err_p_irq_sig;
		end  
     end
//=================================================================================================//
   
   //==================================================================
   // Write access to the interrupt status register of the slave
   //==================================================================

   always @(posedge gclk) begin
        if (!rst_ctrl_rst_n)
             {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg} <= 2'b11; // Enable by default
        // Write transaction to IRQ_SIG_MASK register
        else if (write_trans & rst_ctrl_cbus_address[AW-1:0] == IRQ_SIG_MASK)
          {wr_err_p_irq_sig_reg,rd_err_p_irq_sig_reg} <= rst_ctrl_cbus_wdata[1:0];
   end // always @ (posedge gclk)

   //==================================================================

   assign irq_sig_clr_p[1:0] = (rst_ctrl_cbus_wdata[1:0] & {2{(write_trans & rst_ctrl_cbus_address[AW-1:0] == IRQ_SIG_CLR_P)}}); // Signal is a pulse

   //==================================================================
   // Detection & save of write access to slave's exceeding address
   //==================================================================

   always @(posedge gclk) begin
        if (!rst_ctrl_rst_n) begin
             bad_wr_addr[AW-1:0] <= {AW{1'b0}};
             wr_err_p_irq_sig <= 1'b0;
        end
        // Write transaction beyond meaningfull address space of the slave
        else if (write_trans & rst_ctrl_cbus_address[AW-1:0] > MAX_VAL_ADDR) begin
                 bad_wr_addr[AW-1:0] <= rst_ctrl_cbus_address[AW-1:0]; // Save the exceeding address
                 wr_err_p_irq_sig <= 1'b1;
             end 
        else wr_err_p_irq_sig <= 1'b0;
   end // always @ (posedge gclk)

   //================================================================== 
   
   always @(posedge rst_ctrl_clk) rst_ctrl_bad_addr_irq <= (~rst_ctrl_rst_n) ? 1'b0 : sig_out_irq_net;
   always @(posedge rst_ctrl_clk) rst_ctrl_bad_addr_unmsk_irq <= (~rst_ctrl_rst_n) ? 1'b0 : sig_out_unmsk_irq_net;
   
   //==================================================================    
      
   //=================== Internal gated ckock =========================
   
   assign gclk_en = rst_ctrl_cbus_req;

/////////////////////////////////////////// CLOCK GATING /////////////////////////////////////////// 
 crg_clk_clockgate reg_file_gclk_i (
		// Outputs
		.out_clk (gclk),          // Output gated clock 
		// Inputs
		.clk        (rst_ctrl_clk),
		.en         (gclk_en),          // RegFile clock gating signal 
		.ten        (scan_enable));

   //==================================================================    

//----------------------------------- Address monitoring expansion (END) -------------------------------------//
   
endmodule // rst_ctrl
// Local Variables:
// verilog-library-directories:("." "$NEGEV_IP/design/crgn/soc_building_blocks/hdl")
// verilog-library-files:()
// verilog-library-extensions:(".v" ".h" ".sv")
// verilog-auto-inst-param-value: t
// End:


