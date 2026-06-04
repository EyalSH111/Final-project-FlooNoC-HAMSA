// WEASIC MICROELECTRONICS S.A.
// DATE 08-03-2019 VERSION 1.0
// Author: Athanassios Moschos

// DAC model in Verilog AMS 
`define Nbits 10
`define N1bits 9

module wrealDAC (PD,DATAIN,CLK,IBIAS,IOUT1,IOUT2,VDD,VSS);
   input [`Nbits-1:0] DATAIN;  
   input              PD,CLK;
   input              IBIAS;
   input              VDD,VSS; 
   output             IOUT1, IOUT2;  

   
   wreal        IOUT1 ;
   wreal        IOUT2 ;
   wreal        IBIAS ;

   
   
   parameter real Td=1ns;
   real       PreBit,Aval;

   always begin // get dA per bit wrt Ibias
      PreBit = (IBIAS) / ((1<<`Nbits)-1);
      @(IBIAS);// update if Ibias changes
   end
// The analog output of the DAC
   always begin
     if (PD ==  1)
       Aval <= 0;
     else
       @(posedge CLK) begin
         Aval <= PreBit*DATAIN;	 
       end
     @(CLK,PD);
   end
   assign  #(Td/1n) IOUT1 = Aval;
   assign  #(Td/1n) IOUT2 = -Aval;
endmodule // wrealDAC
