// Description:
// 		  bscan_cell buffer
////// 
//-----------------------------------------------------------------------------
// Title         : CRG BSCAN CELL
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : crg_bscan_cell.v
// Created       : 25.10.2011
// Last modified : 25.10.2011
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by Ceragon This model is the confidential and
// proprietary property of Ceragon and the possession or use of this
// file requires a written license from Ceragon.
//------------------------------------------------------------------------------
// Modification history :
// 25.10.2011 : created
//-----------------------------------------------------------------------------

module crg_bscan_cell (a, y);
   input   a;   // Buffer input
   output  y;   // Buffer output
   
   assign  y  = a ;
   
endmodule 

