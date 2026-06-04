// Description:
// 		  chip level JTAG bscan
////// 
//-----------------------------------------------------------------------------
// Title         : CRG CHIP JTAG
// Project       : MARS
//-----------------------------------------------------------------------------
// File          : crg_chip_jtag.v
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

module crg_chip_jtag (tdi, trstn, tck, tms, tdo, tdo_en);

   input   tdi, trstn, tck, tms;  
   output  tdo, tdo_en;  
   
   wire tdo     = 1'b0;
   wire tdo_en  = 1'b0;

   crg_bscan_cell I_crg_bscan_cell (
                                    .a          (1'b0),
                                    .y          ());


endmodule 

