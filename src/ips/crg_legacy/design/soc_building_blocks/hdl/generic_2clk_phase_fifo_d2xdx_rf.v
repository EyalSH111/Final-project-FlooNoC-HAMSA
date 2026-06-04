//-----------------------------------------------------------------------------
// Title         : 2 Clocks Phase Compensation FIFO with DW to 2xDW ratio
// Project       : Jupiter
//-----------------------------------------------------------------------------
// File          : 
// Author        :   <naftalyb@ceragon.com>
// Created       : 27.08.2013
// Last modified : Time-stamp: <2013-08-27 2348 naftalyb>
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2013 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 27.08.2013 : created
//------------------------------------------------------------------------------

module generic_2clk_phase_fifo_d2xdx_rf (/*autoarg*/
   // Outputs
   rddata,
   // Inputs
   sreset_n, wr_clk, rd_clk, wrdata
   );

   parameter PTR_WIDTH       = 3;            // address bus width of the fifo
   parameter DW              = 10;           // data bus width of the fifo read port
   localparam NUM_OF_ENTRIES = 2**PTR_WIDTH; // number of read-port rows, must be a 2^x value


   //----------------------------------------------------------------------------
   // Write/Read clock (same frequency but different phase is allowed)
   //----------------------------------------------------------------------------
   input             sreset_n;
   input             wr_clk;
   input             rd_clk;

   //----------------------------------------------------------------------------
   // Write data port, related to wr_clk
   //----------------------------------------------------------------------------
   input [2*DW-1:0]  wrdata;

   //----------------------------------------------------------------------------
   // Read data port, related to rd_clk
   //----------------------------------------------------------------------------
   output [DW-1:0]   rddata;
   
   //----------------------------------------------------------------------------
   // Signals Definitions
   //----------------------------------------------------------------------------
   reg [DW-1:0]        i_mem_core_array[0:NUM_OF_ENTRIES-1] /* synthesis syn_ramstyle="M9K, no_rw_check"*/;
   reg [PTR_WIDTH-1:0] i_wr_ptr;
   reg [PTR_WIDTH-1:0] i_rd_ptr;
   reg [2*DW-1:0]      i_wrdata;
   reg [DW-1:0]        i_rddata;

   integer             j;
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 rd_sreset_n_sync2;      // From I_rd_sreset_n_sync2 of crg_sync2.v
   wire                 wr_sreset_n_sync2;      // From I_wr_sreset_n_sync2 of crg_sync2.v
   // End of automatics

   //----------------------------------------------------------------------------
   // Parameters Definitions
   //----------------------------------------------------------------------------

   //----------------------------------------------------------------------------
   // Continues Assignments
   //----------------------------------------------------------------------------
   assign               rddata = i_rddata;
   
   /*autotieoff*/
   
   /*autoinput*/
   ////*autooutput*/
   /*autoreginput*/
   /*autoreg*/

   //----------------------------------------------------------------------------
   // Synchronize sreset_n into rd_clk domain, this synchronizer creates a
   // a delay of 2 to 3 cycles between write-pointer and read-pointer.
   //----------------------------------------------------------------------------

   /*crg_sync2 AUTO_TEMPLATE (
    .q          (wr_sreset_n_sync2),
    .d          (sreset_n),
    .clk        (rd_clk),
    ); */
   crg_sync2 I_wr_sreset_n_sync2
     (/*autoinst*/
      // Outputs
      .q                                (wr_sreset_n_sync2),     // Templated
      // Inputs
      .clk                              (rd_clk),                // Templated
      .d                                (sreset_n));              // Templated

   /*crg_sync2 AUTO_TEMPLATE (
    .q          (rd_sreset_n_sync2),
    .d          (wr_sreset_n_sync2),
    .clk        (rd_clk),
    ); */
   crg_sync2 I_rd_sreset_n_sync2
     (/*autoinst*/
      // Outputs
      .q                                (rd_sreset_n_sync2),     // Templated
      // Inputs
      .clk                              (rd_clk),                // Templated
      .d                                (wr_sreset_n_sync2));     // Templated
   
   //----------------------------------------------------------------------------
   // Write port process.
   //----------------------------------------------------------------------------
   always @ (posedge wr_clk) 
     begin
          if (wr_sreset_n_sync2 == 1'b0)
            begin
                 for (j = 0; j < NUM_OF_ENTRIES; j = j + 1)
                   begin
                        i_mem_core_array[j] <= {DW{1'b0}};
                   end
                 i_wr_ptr <= {PTR_WIDTH{1'b0}};
                 i_wrdata <= {2*DW{1'b0}};
            end
          else
            begin
                 // Default
                 // Increment pointer by 2
                 i_wr_ptr <= i_wr_ptr + {{(PTR_WIDTH-2){1'b0}}, 2'b10};
                 // Sample input data
                 i_wrdata <= wrdata;
                 // Write lower data into array location i_wr_ptr
                 i_mem_core_array[i_wr_ptr] <= i_wrdata[DW-1:0];
                 // Write upprer data into array location i_wr_ptr+1
                 i_mem_core_array[i_wr_ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1}] <= i_wrdata[2*DW-1:DW];
            end
     end

   //----------------------------------------------------------------------------
   // Read port process.
   //----------------------------------------------------------------------------
   always @ (posedge rd_clk) 
     begin
          if (rd_sreset_n_sync2 == 1'b0)
            begin
                 i_rd_ptr <= {PTR_WIDTH{1'b0}};
                 i_rddata <= {DW{1'b0}};
            end
          else
            begin
                 // Default
                 // Increment pointer by 2
                 i_rd_ptr <= i_rd_ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
                 // Read data from array at i_rd_ptr location
                 i_rddata[DW-1:0] <= i_mem_core_array[i_rd_ptr];
            end
     end
   
endmodule // generic_2clk_phase_fifo_d2xdx_rf

// Local Variables:
// verilog-library-directories:("." "../../../common/general/dw_sync/" "../../../common/general/dw_cells")
// End: