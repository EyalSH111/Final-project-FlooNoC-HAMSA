/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
////                                                                 ////
////  generic_sync_pulse.v                                           ////
////                                                                 ////
////  This file is part of the "nwss_top" project                    ////
////                                                                 ////
////  Known problems (limits):                                       ////
////  None                                                           ////
////                                                                 ////
////  To Do:                                                         ////
////  Nothing.                                                       ////
////                                                                 ////
////  Author(s):                                                     ////
////      - avis@ceragon.com                                         ////
////      - Avi Shamli                                               ////
////                                                                 ////
////  Created:        17.05.10                                       ////
////  Last Updated:   17.05.10                                       ////
////                                                                 ////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

module generic_sync_pulse (
                           //Inputs
		           rst1_n,
		           clk1,
                           
		           pulse1,
                           
                           rst2_n,
                           clk2,
                           
		           //Output
		           pulse2
		           );
   
   
   
  /////////////////////////////////
   
   input          rst1_n;
   input          clk1;
   input          pulse1;
   
   input          rst2_n;   
   input          clk2;
   
   output         pulse2;
   
   /////////////////////////////////
                  
   reg            pulse1_wide;
   
   reg            pulse2_wide;
   reg            pulse2_wide_d;
   reg            pulse2_wide_dd;
   reg            pulse2;

  /////////////////////////////////
   
   // toggle the signal
   always @( posedge clk1 )
     if (!rst1_n)
       pulse1_wide <= 1'd0;
     else
       if ( pulse1 ) 
         pulse1_wide <= !pulse1_wide;

   // Sample twice to eliminate M.S
   always @( posedge clk2 )
     if (!rst2_n)
       begin
            pulse2_wide    <= 1'd0;
            pulse2_wide_d  <= 1'd0;
            pulse2_wide_dd <= 1'd0;
       end
     else
       begin
            pulse2_wide    <= pulse1_wide;
            pulse2_wide_d  <= pulse2_wide;
            pulse2_wide_dd <= pulse2_wide_d;
       end
   
   // check posedge and negedge 
   always @( * )
       pulse2 = (pulse2_wide_d & !pulse2_wide_dd) | (!pulse2_wide_d & pulse2_wide_dd);
   

endmodule 


   
   
