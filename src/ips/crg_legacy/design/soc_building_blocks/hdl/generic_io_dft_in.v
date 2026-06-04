// Time-stamp: <2011-10-04 1705 naftalyb>
//-----------------------------------------------------------------------------
// Title         : 
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : generic_io_dft_in.v
// Author        : Naftaly Blum
// Created       : 21.09.2011
// Last modified : 21.09.2011
//-----------------------------------------------------------------------------
// Description :
// Important: 2 <= IO_DFT_IN_DW <= 32
//  IO_DFT_IN_DW <= MISR_LFSR_DW <= 32
//-----------------------------------------------------------------------------
// Copyright (c) 2011 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD.
//------------------------------------------------------------------------------
// Modification history :
// 21.09.2011 : created
//------------------------------------------------------------------------------
module generic_io_dft_in (/*AUTOARG*/
   // Outputs
   bcfg_io_dft_in_misr,
   // Inputs
   func_clk, func_rst_n, bcfg_io_dft_in_misr_seed,
   bcfg_io_dft_in_ate_en, bcfg_io_dft_in_en, bcfg_io_dft_in_start,
   io_dft_in_en, io_dft_in_start, func_datap_io_reg
   ) ;

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------
   parameter  IO_DFT_IN_DW = 8;
   parameter  MISR_LFSR_DW = 8;
   parameter  IO_DFT_IN_FB_DLY = 1;
   localparam MISR_DW = IO_DFT_IN_DW;
   
   //----------------------------------------------------------------------------
   // Clock/reset
   //----------------------------------------------------------------------------
   input                      func_clk;
   input                      func_rst_n;

   //----------------------------------------------------------------------------
   // BootCFG I/F
   //----------------------------------------------------------------------------
   input [MISR_LFSR_DW-1:0]   bcfg_io_dft_in_misr_seed;
   input                      bcfg_io_dft_in_ate_en;
   input                      bcfg_io_dft_in_en;
   input                      bcfg_io_dft_in_start;
   output [MISR_LFSR_DW-1:0]  bcfg_io_dft_in_misr;
   
   //----------------------------------------------------------------------------
   // IO DFT control signals from ATE
   //----------------------------------------------------------------------------
   input                      io_dft_in_en;
   input                      io_dft_in_start;
   
   //----------------------------------------------------------------------------
   // Datapath from IO register (Feedback path)
   //----------------------------------------------------------------------------
   input [IO_DFT_IN_DW-1:0]   func_datap_io_reg;
   
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   /*autowire*/
   integer              i;
   wire                 i_bcfg_io_dft_in_en_sync;
   wire                 i_bcfg_io_dft_in_start_sync;
   wire                 i_io_dft_in_lfsr_load;
   wire                 i_io_dft_in_lfsr_start;
   wire                 i_io_dft_in_misr_lfsr_start;
   
   reg [IO_DFT_IN_FB_DLY-1:0] i_io_dft_in_misr_lfsr_start_sr;
   
   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   /*autotieoff*/
   /*autoinput*/
   /*autooutput*/
   /*autoreginput*/
   /*autoreg*/
   assign               i_io_dft_in_lfsr_load = (bcfg_io_dft_in_ate_en) ? !io_dft_in_en : !i_bcfg_io_dft_in_en_sync;
   assign               i_io_dft_in_lfsr_start = (bcfg_io_dft_in_ate_en) ? io_dft_in_start : i_bcfg_io_dft_in_start_sync;
   assign               i_io_dft_in_misr_lfsr_start = i_io_dft_in_misr_lfsr_start_sr[0];

   crg_sync2 I_bcfg_io_dft_in_en_sync2 (.q(i_bcfg_io_dft_in_en_sync), .clk(func_clk), .d(bcfg_io_dft_in_en));

   crg_sync2 I_bcfg_io_dft_in_start_sync2 (.q(i_bcfg_io_dft_in_start_sync), .clk(func_clk), .d(bcfg_io_dft_in_start));
   
   /*generic_misr AUTO_TEMPLATE (
      .misr_out                         (bcfg_io_dft_in_misr[]),
      .misr_in                          (func_datap_io_reg[]),
      .lfsr_load                        (i_io_dft_in_lfsr_load),
      .lfsr_start                       (i_io_dft_in_misr_lfsr_start),
      .lfsr_seed                        (bcfg_io_dft_in_misr_seed[]),
     ); */
   generic_misr #(.MISR_LFSR_DW(MISR_LFSR_DW), .MISR_DW(MISR_DW)) I_generic_misr
     (/*autoinst*/
      // Outputs
      .misr_out                         (bcfg_io_dft_in_misr[MISR_LFSR_DW-1:0]), // Templated
      // Inputs
      .func_clk                         (func_clk),
      .func_rst_n                       (func_rst_n),
      .lfsr_load                        (i_io_dft_in_lfsr_load), // Templated
      .lfsr_start                       (i_io_dft_in_misr_lfsr_start), // Templated
      .lfsr_seed                        (bcfg_io_dft_in_misr_seed[MISR_LFSR_DW-1:0]), // Templated
      .misr_in                          (func_datap_io_reg[MISR_DW-1:0])); // Templated

   generate

   if (IO_DFT_IN_FB_DLY>1)
     begin : gen_io_dft_in_misr_lfsr_start_sr_a
          always@(posedge func_clk)
            begin
                 if (!func_rst_n)
                   begin
                        for (i = 0 ; i<IO_DFT_IN_FB_DLY ; i=i+1)
                          begin
	                       i_io_dft_in_misr_lfsr_start_sr[i] <= 1'b0;
                          end
                   end // if (!func_rst_n)
                 else
                   begin
                        i_io_dft_in_misr_lfsr_start_sr[IO_DFT_IN_FB_DLY-1] <= i_io_dft_in_lfsr_start;
                        for (i=1 ; i<IO_DFT_IN_FB_DLY ; i=i+1)
                          begin
	                       i_io_dft_in_misr_lfsr_start_sr[i-1] <= i_io_dft_in_misr_lfsr_start_sr[i];
                          end
                   end // else: !if(!func_rst_n)
            end // always@ (posedge func_clk)
     end // if (IO_DFT_IN_FB_DLY>1)
   else
     begin : gen_io_dft_in_misr_lfsr_start_sr_b
          always@(posedge func_clk)
            begin
                 if (!func_rst_n)
                   begin
                        i_io_dft_in_misr_lfsr_start_sr[0] <= 1'b0;
                   end
                 else
                   begin
 	                i_io_dft_in_misr_lfsr_start_sr[0] <= i_io_dft_in_lfsr_start;
                   end // else: !if(!func_rst_n)
            end // always@ (posedge func_clk)
     end // else: !if(IO_DFT_IN_FB_DLY>1)
   endgenerate
   
endmodule // generic_io_dft_in

// Local Variables:
// verilog-library-directories:("." "../hdl/" "$JUPITER_DIR/common/general/dw_cells" "$DB_DIR/jupiter/common/general/hdl")
// End:
