// WEASIC MICROELECTRONICS S.A.
// DATE 08-03-2019 VERSION 1.0
// Author: Athanassios Moschos

// Testbench for Verilog AMS ADC/DAC Models

`timescale 1ns/1ps
`define Nbits 10
`define N1bits 9
`include "../constants.vams"
`include "../disciplines.vams"
module top ();
   wreal AIN1, AIN2, HIGH, IOUT1, IOUT2, IBIAS, VDD, VSS;
   wire [`Nbits-1:0] DATAOUT;
   wire SAMPLE;
   reg clk, pd, rst;
 
   wrealADC I_ADC (CLK,PD,SAMPLE,VDD,VSS,AIN1,AIN2,RST,HIGH,DATAOUT);
   wrealDAC I_DAC (PD,DATAOUT,CLK,IBIAS,IOUT1,IOUT2,VDD,VSS);
   real r_ain, r_vdd, r_vss, ref_i, ref_v;                 // input voltage
   real Freq=600K,Phase=0;   				   // sinusoid params 
   initial begin  
      clk = 0;
      pd = 1;
      rst = 0;
      ref_v = 0.6;   // 600 mV
      ref_i = 0.001; // 1 mA
      r_vdd = 0.9;
      r_vss = 0.0;
      r_ain = 0;        
// After 100ns start ADC and DAC
      #100 pd = 0;
      #30 while (Freq < 5000000) begin
                               // diferrential sine input      
        #100 Freq = Freq * 1.0007;  // gradual freq increase every 100 ns
        Phase=Phase+2n*Freq;        // integrate freq to get phase, with time of 2ns as every 2ns the frequency increases
        if (Phase>1) Phase=Phase-1; // wraparound per cycle
         // sinusoidal waveform shape
        r_ain = 0.3*(1+sin(`M_TWO_PI*Phase)); // M_TWO_PI = 2π
        // At 100000ns, ADC reset = 1
	if ($abstime > 100000000p) 
	  rst = 1;
	// At 130000ns, ADC reset = 0
        if ($abstime > 130000000p)
          rst = 0;
        // After 2900000ns poweroff ADC and DAC     
        if ($abstime > 290000000p)
	  pd = 1; 
      end
   end
   always #12.5 clk = ~clk; // 80MHz clock
   assign AIN1 = 0.6 + r_ain;
   assign AIN2 = 0.6 - r_ain;
   assign HIGH = ref_v;
   assign IBIAS = ref_i;
   assign PD = pd;
   assign RST = rst;
   assign CLK  = clk;
   assign VDD = r_vdd;
   assign VSS = r_vss;
endmodule   
