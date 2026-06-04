//*#*********************************************************************************************************************/
//*
//*# Technology     : TSMC 16nm CMOS Logic FinFet Compact (FFC) Low Leakage HKMG                          */
//*# Memory Type    : TSMC 16nm FFC Single Port SRAM with d0907 bit cell                     */
//*# Library Name   : ts1n16ffcllulvta1024x8m4s (user specify : ts1n16ffcllulvta1024x8m4s)            */
//*# Library Version: 120a                                                */
//*# Generated Time : 2020/08/31, 14:10:27                                        */
//*#*********************************************************************************************************************/
//*#                                                            */
//*# STATEMENT OF USE                                                    */
//*#                                                            */
//*# This information contains confidential and proprietary information of TSMC.                    */
//*# No part of this information may be reproduced, transmitted, transcribed,                        */
//*# stored in a retrieval system, or translated into any human or computer                        */
//*# language, in any form or by any means, electronic, mechanical, magnetic,                        */
//*# optical, chemical, manual, or otherwise, without the prior written permission                    */
//*# of TSMC. This information was prepared for informational purpose and is for                    */
//*# use by TSMC's customers only. TSMC reserves the right to make changes in the                    */
//*# information at any time and without notice.                                    */
//*#                                                            */
//*#*********************************************************************************************************************/
//********************************************************************************/
//*                                                                              */
//*      Usage Limitation: PLEASE READ CAREFULLY FOR CORRECT USAGE               */
//*                                                                              */
//* Please be careful when using non 2^n  memory.                                */
//* In a non-fully decoded array, a write cycle to a nonexistent address location*/
//* does not change the memory array contents and output remains the same.       */
//* In a non-fully decoded array, a read cycle to a nonexistent address location */
//* does not change the memory array contents but the output becomes unknown.    */
//*                                                                              */
//* In the verilog model, the behavior of unknown clock will corrupt the         */
//* memory data and make output unknown regardless of CEB signal.  But in the    */
//* silicon, the unknown clock at CEB high, the memory and output data will be   */
//* held. The verilog model behavior is more conservative in this condition.     */
//*                                                                              */
//* The model doesn't identify physical column and row address.                  */
//*                                                                              */
//* The verilog model provides TSMC_CM_UNIT_DELAY mode for the fast function     */
//* simulation.                                                                  */
//* All timing values in the specification are not checked in the                */
//* TSMC_CM_UNIT_DELAY mode simulation.                                          */
//* The timing values specified in this model do not reflect real circuit        */
//* behavior. For real timing simulation, please back annotate SDF file.         */
//*                                                                              */
//* Template Version : S_01_61301                                                */
//****************************************************************************** */
//*      Macro Usage       : (+define[MACRO] for Verilog compiliers)             */
//* +TSMC_CM_UNIT_DELAY : Enable fast function simulation.                       */
//* +TSMC_CM_NO_WARNING : Disable all runtime warnings message from this model.  */
//* +TSMC_INITIALIZE_MEM : Initialize the memory data in verilog format.         */
//* +TSMC_INITIALIZE_FAULT : Initialize the memory fault data in verilog format. */
//* +TSMC_NO_TESTPINS_DEFAULT_VALUE_CHECK : Disable the wrong test pins          */
//*                           connection error  message if necessary.            */
//* +TSMC_STUCKAT_FAULT : Enable injectSA task. Please don't use this option     */
//*                       with initial options like +vcs+initmem+0/1 or          */
//*                       +vcs+initreg+0/1 ...                                   */
//****************************************************************************** */
`resetall

`celldefine

`timescale 1ns/1ps
`delay_mode_path
`suppress_faults
`enable_portfaults
      
module TS1N16FFCLLULVTA1024X8M4S (
            CLK, CEB, WEB,
            A, D,
            RTSEL,
            WTSEL,
            Q);

parameter numWord = 1024;
parameter numRow = 256;
parameter numCM = 4;
parameter numIOBit = 8;
parameter numBit = 8;
parameter numWordAddr = 10;
parameter numRowAddr = 8;
parameter numCMAddr = 2;
`ifdef TSMC_STUCKAT_FAULT
parameter numStuckAt = 20;
`endif

`ifdef TSMC_CM_UNIT_DELAY
parameter SRAM_DELAY = 0.0010;
`endif
`ifdef TSMC_INITIALIZE_MEM
parameter INITIAL_MEM_DELAY = 0.01;
`else
  `ifdef TSMC_INITIALIZE_MEM_USING_DEFAULT_TASKS
parameter INITIAL_MEM_DELAY = 0.01;
  `endif
`endif
`ifdef TSMC_INITIALIZE_FAULT
parameter INITIAL_FAULT_DELAY = 0.01;
`endif

`ifdef TSMC_INITIALIZE_MEM
parameter cdeFileInit  = "TS1N16FFCLLULVTA1024X8M4S_initial.cde";
`endif
`ifdef TSMC_INITIALIZE_FAULT
parameter cdeFileFault = "TS1N16FFCLLULVTA1024X8M4S_fault.cde";
`endif

`ifdef TSMC_CM_NO_WARNING
parameter MES_ALL = "OFF";
`else
parameter MES_ALL = "ON";
`endif

//=== IO Ports ===//

// Normal Mode Input
input CLK;
input CEB;
input WEB;
input [9:0] A;
input [7:0] D;


// Data Output
output [7:0] Q;


// Test Mode
input [1:0] RTSEL;
input [1:0] WTSEL;

//=== Internal Signals ===//
        
// Normal Mode Input
wire SLP_b;
wire SLP_i = 1'b0;
wire DSLP_b;
wire DSLP_i = 1'b0;
wire SD_i;
wire CLK_i;
wire CEB_i;
wire WEB_i;
wire [numWordAddr-1:0] A_i;
wire [numIOBit-1:0] D_i;

wire BIST_i;
assign BIST_i = 1'b0;


// Data Output
wire [numIOBit-1:0] Q_i;

// Serial Shift Register Data

// Test Mode
wire [1:0] RTSEL_i;
wire [1:0] WTSEL_i;

//=== IO Buffers ===//
        
// Normal Mode Input
buf (CLK_i, CLK);
buf (CEB_i, CEB);
buf (WEB_i, WEB);
buf (A_i[0], A[0]);
buf (A_i[1], A[1]);
buf (A_i[2], A[2]);
buf (A_i[3], A[3]);
buf (A_i[4], A[4]);
buf (A_i[5], A[5]);
buf (A_i[6], A[6]);
buf (A_i[7], A[7]);
buf (A_i[8], A[8]);
buf (A_i[9], A[9]);
buf (D_i[0], D[0]);
buf (D_i[1], D[1]);
buf (D_i[2], D[2]);
buf (D_i[3], D[3]);
buf (D_i[4], D[4]);
buf (D_i[5], D[5]);
buf (D_i[6], D[6]);
buf (D_i[7], D[7]);



// Data Output
nmos (Q[0], Q_i[0], 1'b1);
nmos (Q[1], Q_i[1], 1'b1);
nmos (Q[2], Q_i[2], 1'b1);
nmos (Q[3], Q_i[3], 1'b1);
nmos (Q[4], Q_i[4], 1'b1);
nmos (Q[5], Q_i[5], 1'b1);
nmos (Q[6], Q_i[6], 1'b1);
nmos (Q[7], Q_i[7], 1'b1);



// Test Mode
buf sRTSEL0 (RTSEL_i[0], RTSEL[0]);
buf sRTSEL1 (RTSEL_i[1], RTSEL[1]);
buf sWTSEL0 (WTSEL_i[0], WTSEL[0]);
buf sWTSEL1 (WTSEL_i[1], WTSEL[1]);

//=== Data Structure ===//
reg invalid_slp;
reg invalid_dslp;
reg invalid_sd_dslp;
integer awt_counter;
integer wk_counter;

reg [numBit-1:0] MEMORY[numRow-1:0][numCM-1:0];
reg [numBit-1:0] MEMORY_FAULT[numRow-1:0][numCM-1:0];
reg [numIOBit-1:0] Q_d, bQ_tmp;
reg [numBit-1:0] Q_d_tmp;
reg [numIOBit-1:0] PRELOAD[0:numWord-1];
reg [numIOBit-1:0] PRELOAD2[0:numWord-1];
reg [numBit-1:0] DIN_tmp;

`ifdef TSMC_STUCKAT_FAULT
reg [numBit-1:0] ERR_tmp;
reg [numWordAddr-1:0] stuckAt0Addr [numStuckAt:0];
reg [numWordAddr-1:0] stuckAt1Addr [numStuckAt:0];
reg [numBit-1:0] stuckAt0Bit [numStuckAt:0];
reg [numBit-1:0] stuckAt1Bit [numStuckAt:0];
`endif

reg [numWordAddr-numCMAddr-1:0] row_tmp;
reg [numCMAddr-1:0] col_tmp;

integer i, j;
reg read_flag, write_flag, idle_flag;
reg slp_mode;
reg dslp_mode;
reg sd_mode;
reg clk_latch;
reg awt_mode;

`ifdef TSMC_CM_UNIT_DELAY
`else
reg notify_testpin;
reg notify_clk;
reg notify_sd_dslp;
reg notify_bist;
reg notify_ceb;
reg notify_web;
reg notify_addr;
reg notify_d0;
reg notify_d1;
reg notify_d2;
reg notify_d3;
reg notify_d4;
reg notify_d5;
reg notify_d6;
reg notify_d7;
`endif    //end `ifdef TSMC_CM_UNIT_DELAY

reg CEBL;
reg WEBL;

wire iCEB = (BIST_i===1) ? CEB_i : CEB_i;
wire iWEB = (BIST_i===1) ? WEB_i : WEB_i;
wire [numWordAddr-1:0] iA = A_i;
reg RCEB;

reg [numWordAddr-numCMAddr-1:0] iRowAddr;
reg [numCMAddr-1:0] iColAddr;
wire [numIOBit-1:0] iD = D_i;


assign SD_i=1'b0;
assign DSLP_b=1'b0;
assign SLP_b=1'b0;

wire bDFTBYP;
wire bSE;
assign bDFTBYP = 1'b0;
assign bSE = 1'b0;

`ifdef TSMC_CM_UNIT_DELAY
`else
wire check_invalid_sd_dslp = invalid_sd_dslp;
wire check_read = read_flag & ~SD_i & ~DSLP_i & ~SLP_i;
wire check_write = write_flag & ~SD_i & ~DSLP_i & ~SLP_i & ~bDFTBYP & ~bSE;
wire check_nosd = ~SD_i & ~invalid_sd_dslp;
wire check_nosd_invalid = ~SD_i;
wire check_nosddslp = ~SD_i & ~DSLP_i ;
wire check_nopd = ~SD_i & ~DSLP_i & ~SLP_i;
wire mem_nopd = ~SD_i & ~DSLP_i & ~SLP_i & ~bDFTBYP & ~bSE;
wire check_noidle = ~idle_flag & ~SD_i & ~DSLP_i & ~SLP_i & ~bDFTBYP & ~bSE;
wire check_wk_2_clk = (~idle_flag | bDFTBYP) & ~SD_i & ~DSLP_i & ~SLP_i & ~invalid_sd_dslp;
wire check_wk_2_clk_invalid = (~idle_flag | bDFTBYP) & ~SD_i & ~DSLP_i & ~SLP_i;
wire check_idle = idle_flag & ~SD_i & ~DSLP_i & ~SLP_i & ~bDFTBYP & ~bSE;
wire check_ceb = ~CEB_i & ~SD_i & ~DSLP_i & ~SLP_i & ~bDFTBYP & ~bSE;

`endif    //end `ifdef TSMC_CM_UNIT_DELAY


assign Q_i= Q_d;


`ifdef TSMC_CM_UNIT_DELAY
`else

`ifdef TSMC_CM_ACCESS
`else
`define TSMC_CM_ACCESS 0.02
`endif
`ifdef TSMC_CM_RETAIN
`else
`define TSMC_CM_RETAIN 0.015
`endif
`ifdef TSMC_CM_SETUP
`else
`define TSMC_CM_SETUP 0.001
`endif
`ifdef TSMC_CM_HOLD
`else
`define TSMC_CM_HOLD 0.001
`endif
`ifdef TSMC_CM_PERIOD
`else
`define TSMC_CM_PERIOD 1
`endif
`ifdef TSMC_CM_WIDTH
`else
`define TSMC_CM_WIDTH 0.5
`endif
`ifdef TSMC_CM_CONTENTION
`else
`define TSMC_CM_CONTENTION 0.001
`endif

specify
    specparam PATHPULSE$ = ( 0, 0.001 );

    specparam tCYC = (`TSMC_CM_PERIOD);
    specparam tCKH = (`TSMC_CM_WIDTH);
    specparam tCKL = (`TSMC_CM_WIDTH);
    specparam tCS = (`TSMC_CM_SETUP);
    specparam tCH = (`TSMC_CM_HOLD);
    specparam tWS = (`TSMC_CM_SETUP);
    specparam tWH = (`TSMC_CM_HOLD);
    specparam tAS = (`TSMC_CM_SETUP);
    specparam tAH = (`TSMC_CM_HOLD);
    specparam tDS = (`TSMC_CM_SETUP);
    specparam tDH = (`TSMC_CM_HOLD);
    specparam tCD = (`TSMC_CM_ACCESS);
`ifdef TSMC_CM_READ_X_SQUASHING
    specparam tHOLD = (`TSMC_CM_ACCESS);
`else    
    specparam tHOLD = (`TSMC_CM_RETAIN);
`endif    


    specparam ttests = (`TSMC_CM_SETUP);
    specparam ttesth = (`TSMC_CM_HOLD);





    if(!CEB & WEB) (posedge CLK => (Q[0] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[1] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[2] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[3] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[4] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[5] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[6] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    if(!CEB & WEB) (posedge CLK => (Q[7] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);









    $period(posedge CLK &&& check_ceb, tCYC, notify_clk);
    $period(negedge CLK &&& check_ceb, tCYC, notify_clk);
    $width(posedge CLK &&& check_ceb, tCKH, 0, notify_clk);
    $width(negedge CLK &&& check_ceb, tCKL, 0, notify_clk);


    $setuphold(posedge CLK &&& mem_nopd, negedge CEB, tCS, tCH, notify_ceb);
    $setuphold(posedge CLK &&& mem_nopd, posedge CEB, tCS, tCH, notify_ceb);

    $setuphold(posedge CLK &&& check_noidle, negedge WEB, tWS, tWH, notify_web);
    $setuphold(posedge CLK &&& check_noidle, posedge WEB, tWS, tWH, notify_web);

    $setuphold(posedge CLK &&& check_noidle, negedge A[0], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[1], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[2], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[3], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[4], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[5], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[6], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[7], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[8], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, negedge A[9], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[0], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[1], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[2], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[3], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[4], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[5], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[6], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[7], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[8], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_noidle, posedge A[9], tAS, tAH, notify_addr);
    $setuphold(posedge CLK &&& check_write, negedge D[0], tDS, tDH, notify_d0);
    $setuphold(posedge CLK &&& check_write, negedge D[1], tDS, tDH, notify_d1);
    $setuphold(posedge CLK &&& check_write, negedge D[2], tDS, tDH, notify_d2);
    $setuphold(posedge CLK &&& check_write, negedge D[3], tDS, tDH, notify_d3);
    $setuphold(posedge CLK &&& check_write, negedge D[4], tDS, tDH, notify_d4);
    $setuphold(posedge CLK &&& check_write, negedge D[5], tDS, tDH, notify_d5);
    $setuphold(posedge CLK &&& check_write, negedge D[6], tDS, tDH, notify_d6);
    $setuphold(posedge CLK &&& check_write, negedge D[7], tDS, tDH, notify_d7);
    $setuphold(posedge CLK &&& check_write, posedge D[0], tDS, tDH, notify_d0);
    $setuphold(posedge CLK &&& check_write, posedge D[1], tDS, tDH, notify_d1);
    $setuphold(posedge CLK &&& check_write, posedge D[2], tDS, tDH, notify_d2);
    $setuphold(posedge CLK &&& check_write, posedge D[3], tDS, tDH, notify_d3);
    $setuphold(posedge CLK &&& check_write, posedge D[4], tDS, tDH, notify_d4);
    $setuphold(posedge CLK &&& check_write, posedge D[5], tDS, tDH, notify_d5);
    $setuphold(posedge CLK &&& check_write, posedge D[6], tDS, tDH, notify_d6);
    $setuphold(posedge CLK &&& check_write, posedge D[7], tDS, tDH, notify_d7);





    $setuphold (posedge CLK &&& check_noidle, posedge RTSEL[0], ttests, 0, notify_testpin); 
    $setuphold (posedge CLK &&& check_noidle, negedge RTSEL[0], ttests, 0, notify_testpin);
    $setuphold (posedge CLK &&& check_idle, posedge RTSEL[0], 0, ttesth, notify_testpin); 
    $setuphold (posedge CLK &&& check_idle, negedge RTSEL[0], 0, ttesth, notify_testpin);
    $setuphold (posedge CLK &&& check_noidle, posedge RTSEL[1], ttests, 0, notify_testpin); 
    $setuphold (posedge CLK &&& check_noidle, negedge RTSEL[1], ttests, 0, notify_testpin);
    $setuphold (posedge CLK &&& check_idle, posedge RTSEL[1], 0, ttesth, notify_testpin); 
    $setuphold (posedge CLK &&& check_idle, negedge RTSEL[1], 0, ttesth, notify_testpin);
    $setuphold (posedge CLK &&& check_noidle, posedge WTSEL[0], ttests, 0, notify_testpin); 
    $setuphold (posedge CLK &&& check_noidle, negedge WTSEL[0], ttests, 0, notify_testpin);
    $setuphold (posedge CLK &&& check_idle, posedge WTSEL[0], 0, ttesth, notify_testpin); 
    $setuphold (posedge CLK &&& check_idle, negedge WTSEL[0], 0, ttesth, notify_testpin);
    $setuphold (posedge CLK &&& check_noidle, posedge WTSEL[1], ttests, 0, notify_testpin); 
    $setuphold (posedge CLK &&& check_noidle, negedge WTSEL[1], ttests, 0, notify_testpin);
    $setuphold (posedge CLK &&& check_idle, posedge WTSEL[1], 0, ttesth, notify_testpin); 
    $setuphold (posedge CLK &&& check_idle, negedge WTSEL[1], 0, ttesth, notify_testpin);



endspecify
`endif    //end `ifdef TSMC_CM_UNIT_DELAY

initial begin
    read_flag = 0;
    write_flag = 0;
    idle_flag = 1;
    slp_mode = 0;
    dslp_mode = 0;
    sd_mode = 0;
    awt_mode = 0;
    awt_counter  = 0;
    wk_counter  = 0;
    invalid_slp = 1'b0;
    invalid_dslp = 1'b0;
    invalid_sd_dslp = 1'b0;
`ifdef TSMC_STUCKAT_FAULT
    #(0.001);
    for (i = 0; i < numStuckAt; i = i + 1) begin
        stuckAt0Addr[i] = {numWordAddr{1'bx}};
        stuckAt1Addr[i] = {numWordAddr{1'bx}};
        stuckAt0Bit[i] = {numBit{1'bx}};
        stuckAt1Bit[i] = {numBit{1'bx}};
    end
`endif
end

`ifdef TSMC_INITIALIZE_MEM_USING_DEFAULT_TASKS
initial begin
    #(INITIAL_MEM_DELAY) ;
`ifdef TSMC_MEM_LOAD_0
    zeroMemoryAll;
`else
 `ifdef TSMC_MEM_LOAD_1
    oneMemoryAll;
 `else
  `ifdef TSMC_MEM_LOAD_RANDOM
    randomMemoryAll;
  `else
    xMemoryAll;
  `endif
 `endif
`endif    
end
`endif //`ifdef TSMC_INITIALIZE_MEM_USING_DEFAULT_TASKS

 `ifdef TSMC_INITIALIZE_MEM
initial begin 
    #(INITIAL_MEM_DELAY) ;
    preloadData(cdeFileInit) ;
end
`endif //  `ifdef TSMC_INITIALIZE_MEM
   
`ifdef TSMC_INITIALIZE_FAULT
initial begin
`ifdef TSMC_INITIALIZE_FORMAT_BINARY
     #(INITIAL_FAULT_DELAY) $readmemb(cdeFileFault, PRELOAD2, 0, numWord-1);
`else
     #(INITIAL_FAULT_DELAY) $readmemh(cdeFileFault, PRELOAD2, 0, numWord-1);
`endif
    for (i = 0; i < numWord; i = i + 1) begin
        {row_tmp, col_tmp} = i;
        MEMORY_FAULT[row_tmp][col_tmp] = PRELOAD2[i];
    end
end
`endif //  `ifdef TSMC_INITIALIZE_FAULT


always @(RTSEL_i) begin
    if(SLP_i === 1'b0 && DSLP_i === 1'b0 && SD_i === 1'b0) begin
    if(($realtime > 0) && idle_flag === 1'b0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : input RTSEL should not be toggled when CEB is low at simulation time %t\n", $realtime);
`endif
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin    
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d = {numIOBit{1'bx}};        
        xMemoryAll;
    end
    end
    end
end
always @(WTSEL_i) begin
    if(SLP_i === 1'b0 && DSLP_i === 1'b0 && SD_i === 1'b0) begin
    if(($realtime > 0) && idle_flag === 1'b0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : input WTSEL should not be toggled when CEB is low at simulation time %t\n", $realtime);
`endif
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin    
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d = {numIOBit{1'bx}};        
        xMemoryAll;
    end
    end
    end
end

`ifdef TSMC_NO_TESTPINS_DEFAULT_VALUE_CHECK
`else
always @(CLK_i or RTSEL_i) begin
    if(SLP_i === 1'b0 && DSLP_i === 1'b0 && SD_i === 1'b0) begin
    if((RTSEL_i !== 2'b01) && ($realtime > 0)) begin
        $display("\tError %m : input RTSEL should be set to 2'b01 at simulation time %t\n", $realtime);
        $display("\tError %m : Please refer the datasheet for the RTSEL setting in the different segment and mux configuration\n");
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d = {numIOBit{1'bx}};
        xMemoryAll;
    end
    end
    end
end
always @(CLK_i or WTSEL_i) begin
    if(SLP_i === 1'b0 && DSLP_i === 1'b0 && SD_i === 1'b0) begin
    if((WTSEL_i !== 2'b01) && ($realtime > 0)) begin
        $display("\tError %m : input WTSEL should be set to 2'b01 at simulation time %t\n", $realtime);
        $display("\tError %m : Please refer the datasheet for the WTSEL setting in the different segment and mux configuration\n");
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d = {numIOBit{1'bx}};
        xMemoryAll;
    end
    end
    end
end
`endif




always @(CLK_i) begin : CLK_OPERATION
    if(SLP_i === 1'b0 && DSLP_i === 1'b0 && SD_i === 1'b0 && bDFTBYP === 1'b0 && bSE === 1'b0) begin
    if (CLK_i === 1'b1) begin
        read_flag=0;
        idle_flag=1;
        write_flag=0;
    end
    if (slp_mode === 1'b0 && dslp_mode === 1'b0 && sd_mode === 1'b0) begin
        if (CLK_i === 1'bx) begin
`ifdef TSMC_CM_NO_WARNING
`else
            $display("\tWarning %m : input CLK unknown/high-Z at simulation time %t\n", $realtime);
`endif
`ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
`endif
            Q_d = {numIOBit{1'bx}};
            xMemoryAll;
        end
        else if ((CLK_i===1) && (clk_latch===0)) begin    //posedge
            iRowAddr = iA[numWordAddr-1:numCMAddr];
            iColAddr = iA[numCMAddr-1:0];
            if (iCEB === 1'b0) begin
                idle_flag = 0;
                if (iWEB === 1'b1) begin        // read
                        read_flag = 1;
                        if ( ^iA === 1'bx ) begin
`ifdef TSMC_CM_NO_WARNING
`else
  `ifndef TSMC_CM_NO_XADDR_WARNING
                            $display("\tWarning %m : input A unknown/high-Z in read cycle at simulation time %t\n", $realtime);
  `endif
`endif
`ifdef TSMC_CM_UNIT_DELAY
                            #(SRAM_DELAY);
`endif
                            Q_d = {numIOBit{1'bx}};
                            //xMemoryAll;
                        end 
                        else if (iA >= numWord) begin
`ifdef TSMC_CM_NO_WARNING
`else
                            $display("\tWarning %m : address exceed word depth in read cycle at simulation time %t\n", $realtime);
`endif
`ifdef TSMC_CM_UNIT_DELAY
                            #(SRAM_DELAY);
`endif
                            Q_d = {numIOBit{1'bx}};
                        end
                        else begin
`ifdef TSMC_CM_UNIT_DELAY
                            #(SRAM_DELAY);
    `ifdef TSMC_INITIALIZE_FAULT
                            Q_d = (MEMORY[iRowAddr][iColAddr] ^ MEMORY_FAULT[iRowAddr][iColAddr]);
    `else
                            Q_d =  MEMORY[iRowAddr][iColAddr];
    `endif
`else
                            Q_d = {numBit{1'bx}};    //transition to x first
  `ifdef TSMC_INITIALIZE_FAULT
                            #0.001 Q_d = (MEMORY[iRowAddr][iColAddr] ^ MEMORY_FAULT[iRowAddr][iColAddr]);
  `else
                            #0.001 Q_d =  MEMORY[iRowAddr][iColAddr];
  `endif
`endif
                        end // else: !if(iA >= numWord)
                end // if (iWEB === 1'b1)
                else if (iWEB === 1'b0) begin    // write
                    if ( ^iA === 1'bx ) begin
`ifdef TSMC_CM_NO_WARNING
`else
                        $display("\tWarning %m : input A unknown/high-Z in write cycle at simulation time %t\n", $realtime);
`endif
                        xMemoryAll;
                    end 
                    else if (iA >= numWord) begin
`ifdef TSMC_CM_NO_WARNING
`else
                        $display("\tWarning %m : address exceed word depth in write cycle at simulation time %t\n", $realtime);
`endif
                    end 
                    else begin
                        write_flag = 1;
                        begin
                            DIN_tmp = MEMORY[iRowAddr][iColAddr];
                            DIN_tmp[numBit-1:0] = iD[numBit-1:0];
`ifdef TSMC_STUCKAT_FAULT
                            if ( isStuckAt0(iA) || isStuckAt1(iA) ) begin
                                combineErrors(iA, ERR_tmp);
                                for (j = 0; j < numBit; j = j + 1) begin
                                    DIN_tmp[j] = (ERR_tmp[j] !== 1'bx) ? ERR_tmp[j] : DIN_tmp[j] ;
                                end
                            end
`endif                            
                            MEMORY[iRowAddr][iColAddr] = DIN_tmp;
                        end
                    end //end of if ( ^iA === 1'bx ) begin
                end 
                else begin
`ifdef TSMC_CM_NO_WARNING
`else
                    $display("\tWarning %m : input WEB unknown/high-Z at simulation time %t\n", $realtime);
`endif
`ifdef TSMC_CM_UNIT_DELAY
                    #(SRAM_DELAY);
`endif
                    Q_d = {numIOBit{1'bx}};
                    xMemoryAll;
                end // else: !if(iWEB === 1'b0)
            end // if (iCEB === 1'b0)
            else if (iCEB === 1'b1) begin
                idle_flag = 1;
            end
            else begin    //CEB is 'x / 'Z
                idle_flag = 1'bx;                
`ifdef TSMC_CM_NO_WARNING
`else
                $display("\tWarning %m : input CEB unknown/high-Z at simulation time %t\n", $realtime);
`endif
`ifdef TSMC_CM_UNIT_DELAY
                #(SRAM_DELAY);
`endif
                Q_d = {numIOBit{1'bx}};
                xMemoryAll;
            end // else: !if(iCEB === 1'b1)
        end // if ((CLK_i===1) &&(clk_latch===0))
    end
    end
    clk_latch=CLK_i;    //latch CLK_i
end // always @(CLK_i)



always @(posedge CLK_i) begin
    if(SLP_i === 1'b0 && DSLP_i === 1'b0 && SD_i === 1'b0) begin
    if (CLK_i === 1'b1) begin
        CEBL = iCEB;
        WEBL = iWEB;
    end
    end
end



always @(SD_i or DSLP_i or SLP_i) begin
    idle_flag  = 1'b1;
    write_flag = 1'b0;
    read_flag  = 1'b0;
    if (SD_i === 1'bx && $realtime !=0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : input SD unknown/high-Z at simulation time %t\n", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end
    else if (SD_i === 1'b0 && DSLP_i !== 1'b0 && sd_mode === 1'b1 && $realtime !=0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : Invalid Wake Up Sequence. DSLP must be low before wake up from shut down mode at simulation time %t", $realtime);
`endif
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
        invalid_sd_dslp = 1'b1;
    end        
    else if (SD_i === 1'b0 && sd_mode === 1'b1) begin
        sd_mode = 1'b0;
        slp_mode = SLP_i;
        dslp_mode = DSLP_i;
        if(slp_mode !== 1 && dslp_mode !== 1'b1) begin
`ifdef TSMC_MEM_LOAD_0
            Q_d={numIOBit{1'b0}};
`else
 `ifdef TSMC_MEM_LOAD_1
            Q_d={numIOBit{1'b1}};
 `else
  `ifdef TSMC_MEM_LOAD_RANDOM
            Q_d=$random;
  `else
            Q_d={numIOBit{1'bx}};
  `endif
 `endif
`endif

        end
    end
    else if (SD_i === 1'b1 && sd_mode === 1'b0) begin
`ifdef TSMC_MEM_LOAD_0
        zeroMemoryAll;
`else
 `ifdef TSMC_MEM_LOAD_1
        oneMemoryAll;
 `else
  `ifdef TSMC_MEM_LOAD_RANDOM
        randomMemoryAll;
  `else
        xMemoryAll;
  `endif
 `endif
`endif    
        sd_mode = 1'b1;
        dslp_mode = DSLP_i;
        slp_mode = SLP_i;
        if(|Q_d !== 1'b0 || dslp_mode !== 1'b1 || slp_mode !== 1'b1) begin
            Q_d={numIOBit{1'bx}};
`ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
`else        
            #0.001;
`endif            
        end
        Q_d=0;
    end
    else if (SD_i === 1'b0 && sd_mode === 1'bx) begin
        sd_mode = 1'b0;
    end
    else if (SD_i === 1'b1 && sd_mode === 1'bx) begin
        sd_mode = 1'b1;
    end
    else if (DSLP_i === 1'bx && SLP_i === 1'b0 && SD_i === 1'b0 && $realtime !=0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : input DSLP unknown/high-Z at simulation time %t\n", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end    
    else if (SD_i === 1'b0 && DSLP_i === 1'b1 && SLP_i === 1'b0 && iCEB !== 1'b1 && dslp_mode === 1'b0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : Invalid Deep Sleep Mode Sequence. Input CEB 0/unknown/high-Z while entering deep sleep mode at simulation time %t", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end
    else if (SD_i === 1'b0 && DSLP_i === 1'b0 && SLP_i === 1'b0 && iCEB !== 1'b1 && dslp_mode === 1'b1) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : Invalid Wake Up Sequence. Input CEB is 0/unknown/high-Z while exiting sleep mode at simulation time %t", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end
    else if (DSLP_i === 1'b1 && (iCEB === 1'b1 || $realtime == 0) && dslp_mode === 1'b0) begin
        dslp_mode = 1'b1;
        if(|Q_d !== 1'b0 || (sd_mode !== 1'b1 && slp_mode !== 1'b1) ) begin
            Q_d={numIOBit{1'bx}};
`ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
`else        
            #0.001;
`endif            
        end
        Q_d=0;
    end
    else if (DSLP_i === 1'b0 && iCEB === 1'b1 && dslp_mode === 1'b1) begin
        dslp_mode = 1'b0;
        if(sd_mode !== 1'b1 && slp_mode !== 1'b1) begin
            Q_d={numIOBit{1'bx}};
        end
    end
    else if (DSLP_i === 1'b0 && dslp_mode === 1'bx) begin  //power on
        dslp_mode = 1'b0;
    end
    else if (DSLP_i===1'b1 && dslp_mode === 1'bx) begin //power on
        dslp_mode = 1'b1;
    end
    if (SD_i === 1) begin
`ifdef TSMC_MEM_LOAD_0
        zeroMemoryAll;
`else
 `ifdef TSMC_MEM_LOAD_1
        oneMemoryAll;
 `else
  `ifdef TSMC_MEM_LOAD_RANDOM
        randomMemoryAll;
  `else
        xMemoryAll;
  `endif
 `endif
`endif
    end
    else if (SLP_i === 1'bx && DSLP_i === 1'b0 && SD_i === 1'b0 && $realtime !=0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : input SLP unknown/high-Z at simulation time %t\n", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end    
    else if (SD_i === 1'b0 && DSLP_i === 1'b0 && SLP_i === 1'b1 && iCEB !== 1'b1 && slp_mode === 1'b0) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : Invalid Sleep Mode Sequence. Input CEB 0/unknown/high-Z while entering sleep mode at simulation time %t", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end
    else if (SD_i === 1'b0 && DSLP_i === 1'b0 && SLP_i === 1'b0 && iCEB !== 1'b1 && slp_mode === 1'b1) begin
`ifdef TSMC_CM_NO_WARNING
`else
        $display("\tWarning %m : Invalid Wake Up Sequence. Input CEB is 0/unknown/high-Z while exiting sleep mode at simulation time %t", $realtime);
`endif
        slp_mode = 1'b0;
        dslp_mode = 1'b0;
        sd_mode = 1'b0;
`ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
`endif
        Q_d={numIOBit{1'bx}};
        xMemoryAll;
    end
    else if (SLP_i === 1'b1 && (iCEB === 1'b1 || $realtime == 0) && slp_mode === 1'b0) begin
        slp_mode = 1'b1;
        if(|Q_d !== 1'b0 || (sd_mode !== 1'b1 && dslp_mode !== 1'b1) ) begin
            Q_d={numIOBit{1'bx}};
`ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
`else        
            #0.001;
`endif            
        end
        Q_d=0;
    end
    else if (SLP_i === 1'b0 && iCEB === 1'b1 && slp_mode === 1'b1) begin
        slp_mode = 1'b0;
        if(sd_mode !== 1'b1 && dslp_mode !== 1'b1) begin
            Q_d={numIOBit{1'bx}};
        end
    end
    else if (SLP_i === 1'b0 && slp_mode === 1'bx) begin  //power on
        slp_mode = 1'b0;
    end
    else if (SLP_i===1'b1 && slp_mode === 1'bx) begin //power on
        slp_mode = 1'b1;
    end
    if (SD_i === 1) begin
`ifdef TSMC_MEM_LOAD_0
        zeroMemoryAll;
`else
 `ifdef TSMC_MEM_LOAD_1
        oneMemoryAll;
 `else
  `ifdef TSMC_MEM_LOAD_RANDOM
        randomMemoryAll;
  `else
        xMemoryAll;
  `endif
 `endif
`endif
    end
end




`ifdef TSMC_CM_UNIT_DELAY
`else
always @(notify_testpin) begin
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin
      Q_d = {numIOBit{1'bx}};
      xMemoryAll;
    end
    else if(bDFTBYP === 1'b0) begin
      Q_d = {numIOBit{1'bx}};
    end
end


always @(notify_clk) begin
    disable CLK_OPERATION;
    if (bDFTBYP === 1'b0 && bSE === 1'b0) begin
        Q_d = {numIOBit{1'bx}};
        xMemoryAll;
    end
    else if(bDFTBYP === 1'b0) begin 
        Q_d = {numIOBit{1'bx}};
    end
end
always @(notify_bist) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin
      Q_d = {numIOBit{1'bx}};
      xMemoryAll;
    end
    else if(bDFTBYP === 1'b0) begin
      Q_d = {numIOBit{1'bx}};
    end
end
always @(notify_ceb) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin
        Q_d = {numIOBit{1'bx}};
        xMemoryAll;
        read_flag = 0;
        write_flag = 0;
    end
    else if(bDFTBYP === 1'b0) begin
      Q_d = {numIOBit{1'bx}};
    end
end
always @(notify_web) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin
        Q_d = {numIOBit{1'bx}};
        xMemoryAll;
        read_flag = 0;
        write_flag = 0;
    end
end
always @(notify_addr) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin
        if (iWEB === 1'b1) begin
            Q_d = {numIOBit{1'bx}};           
        end
        else if (iWEB === 1'b0) begin
        end
        else begin
            Q_d = {numIOBit{1'bx}};
        end        
        xMemoryAll;
        read_flag = 0;
        write_flag = 0;
    end
    else if(bDFTBYP === 1'b0) begin
        Q_d = {numIOBit{1'bx}};        
    end
end
always @(notify_d0) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 0);
        end
        write_flag = 0;
    end
end

always @(notify_d1) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 1);
        end
        write_flag = 0;
    end
end

always @(notify_d2) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 2);
        end
        write_flag = 0;
    end
end

always @(notify_d3) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 3);
        end
        write_flag = 0;
    end
end

always @(notify_d4) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 4);
        end
        write_flag = 0;
    end
end

always @(notify_d5) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 5);
        end
        write_flag = 0;
    end
end

always @(notify_d6) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 6);
        end
        write_flag = 0;
    end
end

always @(notify_d7) begin
    disable CLK_OPERATION;
    if(bDFTBYP === 1'b0 && bSE === 1'b0) begin 
        if ( ^iA === 1'bx ) begin
            xMemoryAll;
        end
        else begin
            xMemoryBit(iA, 7);
        end
        write_flag = 0;
    end
end


`endif    //end `ifdef TSMC_CM_UNIT_DELAY


task xMemoryAll;
integer row;
integer col;
integer row_index;
integer col_index;
begin
    for (row_index = 0; row_index <= numRow-1; row_index = row_index + 1) begin
        for (col_index = 0; col_index <= numCM-1; col_index = col_index + 1) begin
            row=row_index;
            col=col_index;
            MEMORY[row][col] = {numBit{1'bx}};
        end
    end
    if( MES_ALL=="ON" && $realtime != 0) $display("\nInfo : Set Memory Content to all x at %t.>>", $realtime);
end
endtask

task zeroMemoryAll;
integer row;
integer col;
integer row_index;
integer col_index;
begin
    for (row_index = 0; row_index <= numRow-1; row_index = row_index + 1) begin
        for (col_index = 0; col_index <= numCM-1; col_index = col_index + 1) begin
            row=row_index;
            col=col_index;
            MEMORY[row][col] = {numBit{1'b0}};
        end
    end
    if( MES_ALL=="ON" && $realtime != 0) $display("\nInfo : Set Memory Content to all 0 at %t.>>", $realtime);
end
endtask

task oneMemoryAll;
integer row;
integer col;
integer row_index;
integer col_index;
begin
    for (row_index = 0; row_index <= numRow-1; row_index = row_index + 1) begin
        for (col_index = 0; col_index <= numCM-1; col_index = col_index + 1) begin
            row=row_index;
            col=col_index;
            MEMORY[row][col] = {numBit{1'b1}};
        end
    end
    if( MES_ALL=="ON" && $realtime != 0) $display("\nInfo : Set Memory Content to all 1 at %t.>>", $realtime);
end
endtask

task randomMemoryAll;
integer row;
integer col;
integer row_index;
integer col_index;
begin
    for (row_index = 0; row_index <= numRow-1; row_index = row_index + 1) begin
        for (col_index = 0; col_index <= numCM-1; col_index = col_index + 1) begin
            row=row_index;
            col=col_index;
            MEMORY[row][col] = $random;
        end
    end
    if( MES_ALL=="ON" && $realtime != 0) $display("\nInfo : Set Memory Content to random patterns at %t.>>", $realtime);
end
endtask

task xMemoryWord;
input [numWordAddr-1:0] addr;
reg [numRowAddr-1:0] row;
reg [numCMAddr-1:0] col;
begin
    {row, col} = addr;
    MEMORY[row][col] = {numBit{1'bx}};
end
endtask

task xMemoryBit;
input [numWordAddr-1:0] addr;
input integer abit;
reg [numRowAddr-1:0] row;
reg [numCMAddr-1:0] col;
begin
    {row, col} = addr;
    MEMORY[row][col][abit] = 1'bx;
end
endtask

task preloadData;
input [256*8:1] infile;  // Max 256 character File Name
reg [numWordAddr:0] w;
reg [numWordAddr-numCMAddr-1:0] row;
reg [numCMAddr-1:0] col;
begin
`ifdef TSMC_CM_NO_WARNING
`else
    $display("Preloading data from file %s", infile);
`endif
`ifdef TSMC_INITIALIZE_FORMAT_BINARY
        $readmemb(infile, PRELOAD);
`else
        $readmemh(infile, PRELOAD);
`endif
    for (w = 0; w < numWord; w = w + 1) begin
        {row, col} = w;
        MEMORY[row][col] = PRELOAD[w];
    end
end
endtask

/*
 * task injectSA - to inject a stuck-at error, please use hierarchical reference to call the injectSA task from the wrapper module
 *      input addr - the address location where the defect is to be introduced
 *      input bit - the bit location of the specified address where the defect is to occur
 *      input type - specify whether it's a s-a-0 (type = 0) or a s-a-1 (type = 1) fault
 *
 *      Multiple faults can be injected at the same address, regardless of the type.  This means that an address location can have 
 *      certain bits having stuck-at-0 faults while other bits have the stuck-at-1 defect.
 *
 * Examples:
 *      injectSA(0, 0, 0);  - injects a s-a-0 fault at address 0, bit 0
 *      injectSA(1, 0, 1);  - injects a s-a-1 fault at address 1, bit 0
 *      injectSA(1, 1, 0);  - injects a s-a-0 fault at address 1, bit 1
 *      injectSA(1, 2, 1);  - injects a s-a-1 fault at address 1, bit 2
 *      injectSA(1, 3, 1);  - injects a s-a-1 fault at address 1, bit 3
 *      injectSA(2, 2, 1);  - injects a s-a-1 fault at address 2, bit 2
 *      injectSA(14, 2, 0); - injects a s-a-0 fault at address 14, bit 2
 *
 */
`ifdef TSMC_STUCKAT_FAULT
task injectSA;
input [numWordAddr-1:0] addr;
input integer bitn;
input typen;
reg [numStuckAt:0] i;
reg [numBit-1:0] btmp;
begin
    j=bitn;
    if ( typen === 0 ) begin
        for (i = 0; i < numStuckAt; i = i + 1) begin
            if ( ^stuckAt0Addr[i] === 1'bx ) begin
                stuckAt0Addr[i] = addr;
                btmp = {numBit{1'bx}};
                btmp[j] = 1'b0;
                stuckAt0Bit[i] = btmp;
                i = numStuckAt;
`ifdef TSMC_CM_NO_WARNING
`else
                $display("First s-a-0 error injected at address location %d = %b", addr, btmp);
`endif
                i = numStuckAt;
            end
            else if ( stuckAt0Addr[i] === addr ) begin
                btmp = stuckAt0Bit[i];
                btmp[j] = 1'b0;
                stuckAt0Bit[i] = btmp;
`ifdef TSMC_CM_NO_WARNING
`else
                $display("More s-a-0 Error injected at address location %d = %b", addr, btmp);
`endif
                i = numStuckAt;
            end        
        end
    end
    else if (typen === 1) begin
        for (i = 0; i < numStuckAt; i = i + 1) begin
            if ( ^stuckAt1Addr[i] === 1'bx ) begin
                stuckAt1Addr[i] = addr;
                btmp = {numBit{1'bx}};
                btmp[j] = 1'b1;
                stuckAt1Bit[i] = btmp;
                i = numStuckAt;
`ifdef TSMC_CM_NO_WARNING
`else
                $display("First s-a-1 error injected at address location %d = %b", addr, btmp);
`endif
                i = numStuckAt;
            end
            else if ( stuckAt1Addr[i] === addr ) begin
                btmp = stuckAt1Bit[i];
                btmp[j] = 1'b1;
                stuckAt1Bit[i] = btmp;
`ifdef TSMC_CM_NO_WARNING
`else
                $display("More s-a-1 Error injected at address location %d = %b", addr, btmp);
`endif
                i = numStuckAt;
            end        
        end
    end
end
endtask

task combineErrors;
input [numWordAddr-1:0] addr;
output [numBit-1:0] errors;
integer j;
reg [numBit-1:0] btmp;
begin
    errors = {numBit{1'bx}};
    if ( isStuckAt0(addr) ) begin
        btmp = stuckAt0Bit[getStuckAt0Index(addr)];
        for ( j = 0; j < numBit; j = j + 1 ) begin
            if ( btmp[j] === 1'b0 ) begin
                errors[j] = 1'b0;
            end
        end
    end
    if ( isStuckAt1(addr) ) begin
        btmp = stuckAt1Bit[getStuckAt1Index(addr)];
        for ( j = 0; j < numBit; j = j + 1 ) begin
            if ( btmp[j] === 1'b1 ) begin
                errors[j] = 1'b1;
            end
        end
    end
end
endtask

function [numStuckAt-1:0] getStuckAt0Index;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
begin
    for (i = 0; i < numStuckAt; i = i + 1) begin
        if (stuckAt0Addr[i] === addr) begin
            getStuckAt0Index = i;
        end
    end
end
endfunction

function [numStuckAt-1:0] getStuckAt1Index;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
begin
    for (i = 0; i < numStuckAt; i = i + 1) begin
        if (stuckAt1Addr[i] === addr) begin
            getStuckAt1Index = i;
        end
    end
end
endfunction

function isStuckAt0;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
reg flag;
begin
    flag = 0;
    for (i = 0; i < numStuckAt; i = i + 1) begin
        if (stuckAt0Addr[i] === addr) begin
            flag = 1;
            i = numStuckAt;
        end
    end
    isStuckAt0 = flag;
end
endfunction

function isStuckAt1;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
reg flag;
begin
    flag = 0;
    for (i = 0; i < numStuckAt; i = i + 1) begin
        if (stuckAt1Addr[i] === addr) begin
            flag = 1;
            i = numStuckAt;
        end
    end
    isStuckAt1 = flag;
end
endfunction
`endif

task printMemory;
reg [numRowAddr-1:0] row;
reg [numCMAddr-1:0] col;
reg [numRowAddr:0] row_index;
reg [numCMAddr:0] col_index;
begin
    $display("\n\nDumping memory content at %t...\n", $realtime);
    for (row_index = 0; row_index <= numRow-1; row_index = row_index + 1) begin
        for (col_index = 0; col_index <= numCM-1; col_index = col_index + 1) begin
            row=row_index;
            col=col_index;
            $display("[%d] = %b", {row, col}, MEMORY[row][col]);
        end
    end    
    $display("\n\n");
end
endtask

task printMemoryFromTo;
input [numWordAddr-1:0] addr1;
input [numWordAddr-1:0] addr2;
reg [numWordAddr:0] addr;
reg [numRowAddr-1:0] row;
reg [numCMAddr-1:0] col;
begin
    $display("\n\nDumping memory content at %t...\n", $realtime);
    for (addr = addr1; addr < addr2; addr = addr + 1) begin
        {row, col} = addr;
        $display("[%d] = %b", addr, MEMORY[row][col]);
    end    
    $display("\n\n");
end
endtask




endmodule
`endcelldefine

