// Time-stamp: <2014-04-07 1443 naftalyb>
//-----------------------------------------------------------------------------
// Title         : 
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : generic_io_dft_out.v
// Author        : Naftaly Blum
// Created       : 21.09.2011
// Last modified : 21.09.2011
//-----------------------------------------------------------------------------
// Description :
// Important: 2 <= IO_DFT_OUT_DW <= 32
//  IO_DFT_OUT_DW <= MISR_LFSR_DW <= 32
//-----------------------------------------------------------------------------
// Copyright (c) 2011 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD.
//------------------------------------------------------------------------------
// Modification history :
// 21.09.2011 : created
//------------------------------------------------------------------------------
module generic_io_dft_out (/*AUTOARG*/
   // Outputs
   bcfg_io_dft_out_active, bcfg_io_dft_out_misr, func_datap_out,
   // Inputs
   func_clk, func_clk_io_fb, func_rst_n, bcfg_io_dft_out_lfsr_seed,
   bcfg_io_dft_out_misr_seed, bcfg_io_dft_out_ate_en,
   bcfg_io_dft_out_en, bcfg_io_dft_out_start, io_dft_out_en,
   io_dft_out_start, func_datap_in, func_datap_io_fb
   ) ;

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter IO_DFT_OUT_DW = 8;
   parameter MISR_LFSR_DW = 8;
   parameter IO_DFT_OUT_FB_DLY = 1;
   parameter IO_DFT_OUT_MISR_EN = 1;
   parameter LFSR_TOG_INIT = 32'b10101010101010101010101010101010;
   parameter LFSR_TOG_MASK = 32'b11111111111111111111111111111111;
   localparam LFSR_DW = IO_DFT_OUT_DW;
   localparam MISR_DW = IO_DFT_OUT_DW;
   
   //----------------------------------------------------------------------------
   // Clock/reset
   //----------------------------------------------------------------------------
   input                      func_clk;
   input                      func_clk_io_fb;
   input                      func_rst_n;

   //----------------------------------------------------------------------------
   // BootCFG I/F
   //----------------------------------------------------------------------------
   input [LFSR_DW-1:0]        bcfg_io_dft_out_lfsr_seed;
   input [MISR_LFSR_DW-1:0]   bcfg_io_dft_out_misr_seed;
   input                      bcfg_io_dft_out_ate_en;
   input                      bcfg_io_dft_out_en;
   input                      bcfg_io_dft_out_start;
   output                     bcfg_io_dft_out_active;
   output [MISR_LFSR_DW-1:0]  bcfg_io_dft_out_misr;
   
   //----------------------------------------------------------------------------
   // IO DFT control signals from ATE
   //----------------------------------------------------------------------------
   input                      io_dft_out_en;
   input                      io_dft_out_start;
   
   //----------------------------------------------------------------------------
   // Datapath from core/to IO register
   //----------------------------------------------------------------------------
   input [IO_DFT_OUT_DW-1:0]  func_datap_in;
   output [IO_DFT_OUT_DW-1:0] func_datap_out;

   //----------------------------------------------------------------------------
   // Datapath from IO register (Feedback path)
   //----------------------------------------------------------------------------
   input [IO_DFT_OUT_DW-1:0]  func_datap_io_fb;
   
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [LFSR_DW-1:0]   lfsr_out;               // From I_generic_lfsr of generic_lfsr.v
   // End of automatics
   integer              i;
   wire                 i_bcfg_io_dft_out_en_sync;
   wire                 i_bcfg_io_dft_out_start_sync;
   wire                 i_io_dft_out_lfsr_load;
   wire                 i_io_dft_out_lfsr_start;
   wire                 i_io_dft_out_mux_sel;
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/
   assign               i_io_dft_out_lfsr_load  = (bcfg_io_dft_out_ate_en) ?  !io_dft_out_en : !i_bcfg_io_dft_out_en_sync;
   assign               i_io_dft_out_lfsr_start = (bcfg_io_dft_out_ate_en) ?  io_dft_out_start : i_bcfg_io_dft_out_start_sync;
   assign               i_io_dft_out_mux_sel    = (bcfg_io_dft_out_ate_en) ?  io_dft_out_en : i_bcfg_io_dft_out_en_sync;
   assign               bcfg_io_dft_out_active  = i_io_dft_out_mux_sel;
   
   crg_sync2 I_bcfg_io_dft_out_en_sync2 (.q(i_bcfg_io_dft_out_en_sync), .clk(func_clk), .d(bcfg_io_dft_out_en));

   crg_sync2 I_bcfg_io_dft_out_start_sync2 (.q(i_bcfg_io_dft_out_start_sync), .clk(func_clk), .d(bcfg_io_dft_out_start));
   
   generate
   genvar j;
   for (j=0 ; j<IO_DFT_OUT_DW ; j=j+1) begin : I_io_dft_out_mx2_gen
    /* crg_clk_mx2 AUTO_TEMPLATE (
      .y                                (func_datap_out[j]),
      .a                                (func_datap_in[j]),
      .b                                (lfsr_out[j]),
      .s                                (i_io_dft_out_mux_sel),
      ); */
   crg_clk_mx2 I_func_datap_out
     (/*autoinst*/
      // Outputs
      .y                                (func_datap_out[j]),     // Templated
      // Inputs
      .a                                (func_datap_in[j]),      // Templated
      .b                                (lfsr_out[j]),           // Templated
      .s                                (i_io_dft_out_mux_sel));  // Templated
   end // block: I_io_dft_out_mx2_gen
   endgenerate

   /* generic_lfsr AUTO_TEMPLATE (
      .lfsr_out                         (lfsr_out[]),
      .lfsr_load                        (i_io_dft_out_lfsr_load),
      .lfsr_start                       (i_io_dft_out_lfsr_start),
      .lfsr_seed                        (bcfg_io_dft_out_lfsr_seed[]),
     ); */
   generic_lfsr #(.LFSR_DW(LFSR_DW), .LFSR_TOG_INIT(LFSR_TOG_INIT), .LFSR_TOG_MASK(LFSR_TOG_MASK)) I_generic_lfsr
     (/*autoinst*/
      // Outputs
      .lfsr_out                         (lfsr_out[LFSR_DW-1:0]), // Templated
      // Inputs
      .func_clk                         (func_clk),
      .func_rst_n                       (func_rst_n),
      .lfsr_load                        (i_io_dft_out_lfsr_load), // Templated
      .lfsr_start                       (i_io_dft_out_lfsr_start), // Templated
      .lfsr_seed                        (bcfg_io_dft_out_lfsr_seed[LFSR_DW-1:0])); // Templated

generate
if (IO_DFT_OUT_MISR_EN)
  begin : gen_dft_io_out_misr_on
     reg                                i_io_dft_out_misr_lfsr_start;

   /*generic_misr AUTO_TEMPLATE (
      .misr_out                         (bcfg_io_dft_out_misr[]),
      .func_clk                         (func_clk_io_fb),
      .misr_in                          (func_datap_io_fb[]),
      .lfsr_load                        (i_io_dft_out_lfsr_load),
      .lfsr_start                       (i_io_dft_out_misr_lfsr_start),
      .lfsr_seed                        (bcfg_io_dft_out_misr_seed[]),
     ); */
   generic_misr #(.MISR_LFSR_DW(MISR_LFSR_DW), .MISR_DW(MISR_DW)) I_generic_misr
     (/*autoinst*/
      // Outputs
      .misr_out                         (bcfg_io_dft_out_misr[MISR_LFSR_DW-1:0]), // Templated
      // Inputs
      .func_clk                         (func_clk_io_fb),        // Templated
      .func_rst_n                       (func_rst_n),
      .lfsr_load                        (i_io_dft_out_lfsr_load), // Templated
      .lfsr_start                       (i_io_dft_out_misr_lfsr_start), // Templated
      .lfsr_seed                        (bcfg_io_dft_out_misr_seed[MISR_LFSR_DW-1:0]), // Templated
      .misr_in                          (func_datap_io_fb[MISR_DW-1:0])); // Templated

       always@(posedge func_clk_io_fb)
         begin
              if (!func_rst_n)
                begin
                     i_io_dft_out_misr_lfsr_start <= 1'b0;
                end // if (!func_rst_n)
              else
                begin
                     i_io_dft_out_misr_lfsr_start <= i_io_dft_out_lfsr_start;
                end // else: !if(!func_rst_n)
         end // always@ (posedge func_clk)
       
  end // block: gen_dft_io_out_misr_on
else
  begin : gen_dft_io_out_misr_off
     assign bcfg_io_dft_out_misr = {MISR_LFSR_DW{1'b0}};
  end // else: !if(IO_DFT_OUT_MISR_EN)
endgenerate
 
endmodule // generic_io_dft_out

// Local Variables:
// verilog-library-directories:("." "../hdl/" "$JUPITER_DIR/common/general/dw_cells" "$DB_DIR/jupiter/common/general/hdl")
// End:
