//-----------------------------------------------------------------------------
// Title         : Single Clock FIFO
// Project       : Negev
//-----------------------------------------------------------------------------
// File          : sc_fifo.v
// Author        : naftalyb@ceragon.com
// Created       : 3.4.2015
// Last modified : Time-stamp: <2016-03-01 1711 naftalyb>
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2015 by Ceragon LTD. This model is the confidential and
// proprietary property of Ceragon LTD. and the possession or use of this
// file requires a written license from Ceragon LTD..
//------------------------------------------------------------------------------
// Modification history :
// 3.4.2015 : created
//------------------------------------------------------------------------------
  
module sc_fifo (/*autoarg*/
   // Outputs
   dataout, wr_full_err, rd_empty_err, empty, full, afull, entry_used,
   // Inputs
   clk, reset_n, datain, wr_op, rd_op, clr_err
   );

   parameter        DW   = 32;
   parameter        PTRW  = 8;
   parameter        AFTHRS_LSB = 2'b01;
   
   //----------------------------------------------------------------------------
   // Reference Clocks & PIO configuration/status
   //----------------------------------------------------------------------------
   input             clk;
   input             reset_n;
   
   //----------------------------------------------------------------------------
   // FIFO data-path & rd/wr control
   //----------------------------------------------------------------------------
   input [DW-1:0]    datain;
   output [DW-1:0]   dataout;
   input             wr_op;
   input             rd_op;
   input             clr_err;
   
   //----------------------------------------------------------------------------
   // FIFO Flags
   //----------------------------------------------------------------------------
   output            wr_full_err;
   output            rd_empty_err;
   output            empty;
   output            full;
   output            afull;
   output [PTRW:0]   entry_used;
   
   //----------------------------------------------------------------------------
   // Signal Definitions
   //----------------------------------------------------------------------------
   integer           i;
   reg [DW-1:0]      fifo_array[0:(2**PTRW)-1];
   reg [PTRW-1:0]    fifo_wr_ptr;
   reg [PTRW-1:0]    fifo_rd_ptr;
   reg [PTRW:0]      fifo_used;
   reg               full_err;
   reg               empty_err;
   
   /*autoinput*/

   /*autoutputs*/
   
   /*autowire*/

   
   //----------------------------------------------------------------------------
   // Cont. Assignments
   //----------------------------------------------------------------------------
   assign            dataout = fifo_array[fifo_rd_ptr];
   assign            entry_used = fifo_used;
   assign            empty = (fifo_used == {(PTRW+1){1'b0}}) ? 1'b1 : 1'b0;
   assign            full = (fifo_used == 2**PTRW) ? 1'b1 : 1'b0;
   assign            afull = (fifo_used >= (2**PTRW - AFTHRS_LSB)) ? 1'b1 : 1'b0;
   assign            wr_full_err = full_err;
   assign            rd_empty_err = empty_err;
   
                            
   always @(posedge clk or negedge reset_n)
     begin
          if (reset_n == 1'b0) 
            begin
                 for (i=0 ; i<2**PTRW ; i=i+1)
                   begin
                        fifo_array[i] <= {DW{1'b0}};
                   end
                 fifo_wr_ptr <= {PTRW{1'b0}};
                 fifo_rd_ptr <= {PTRW{1'b0}};
                 fifo_used <= {(PTRW+1){1'b0}};
            end
          else
            begin
                 //----------------------------------------------------------------------------
                 // If both "wr_opt" and "rd_op" are asserted at the same cycle, pointers are
                 // incremented and used level remains the same.
                 //----------------------------------------------------------------------------
                 if     (wr_op == 1'b1 && rd_op == 1'b1) 
                  begin
                       fifo_wr_ptr <= fifo_wr_ptr + {{(PTRW-1){1'b0}}, 1'b1};
                       fifo_rd_ptr <= fifo_rd_ptr + {{(PTRW-1){1'b0}}, 1'b1};
                       //----------------------------------------------------------------------------
                       // Write data into array at the location pointed by "fifo_wr_ptr"
                       //----------------------------------------------------------------------------
                       fifo_array[fifo_wr_ptr] <= datain;
                       fifo_used <= fifo_used;
                  end
                 //----------------------------------------------------------------------------
                 // Push into FIFO when "wr_op" is asserted and level is not full.
                 //----------------------------------------------------------------------------
                 else if (wr_op == 1'b1 && fifo_used != 2**PTRW)
                   begin
                        fifo_wr_ptr <= fifo_wr_ptr + {{(PTRW-1){1'b0}}, 1'b1};
                        //----------------------------------------------------------------------------
                        // Write data into array at the location pointed by "fifo_wr_ptr"
                        //----------------------------------------------------------------------------
                        fifo_array[fifo_wr_ptr] <= datain;
                        fifo_used <= fifo_used + {{(PTRW+1){1'b0}}, 1'b1};
                   end
                 //----------------------------------------------------------------------------
                 // Pop out of FIFO whe "rd_op" is asserted and level is not zero.
                 //----------------------------------------------------------------------------
                 else if (rd_op == 1'b1 && fifo_used != {(PTRW+1){1'b0}})
                   begin
                        fifo_rd_ptr <= fifo_rd_ptr + {{(PTRW-1){1'b0}}, 1'b1};
                        fifo_used <= fifo_used - {{(PTRW+1){1'b0}}, 1'b1};
                   end
            end // else: !if(reset_n == 1'b0)
     end // always @ (posedge clk)
   

   always @(posedge clk or negedge reset_n)
     begin
          if (reset_n == 1'b0) 
            begin
                 full_err <= 1'b0;
                 empty_err <= 1'b0;
            end
          else
            begin
                 //----------------------------------------------------------------------------
                 // Full error is asserted when "wr_op" is asserted while FIFO is full.
                 // Status remains util reset or "clr_err" is asserted.
                 //----------------------------------------------------------------------------
                 if (clr_err == 1'b1)
                   begin
                        full_err <= 1'b0;
                   end
                 else
                   begin
                        if (wr_op == 1'b1 && fifo_used == 2**PTRW)
                          begin
                               full_err <= 1'b1;
                          end
                   end
                 //----------------------------------------------------------------------------
                 // Empty error is asserted when "rd_op" is asserted while FIFO is empty.
                 // Status remains util reset or "clr_err" is asserted.
                 //----------------------------------------------------------------------------
                 if (clr_err == 1'b1)
                   begin
                        empty_err <= 1'b0;
                   end
                 else
                   begin
                        if (rd_op == 1'b1 && fifo_used == {(PTRW+1){1'b0}})
                          begin
                               empty_err <= 1'b1;
                          end
                   end
                        
            end // else: !if(reset_n == 1'b0)
     end // always @ (posedge clk)
   

endmodule // sc_fifo

// Local Variables:
// verilog-library-directories:(".")
// End:
