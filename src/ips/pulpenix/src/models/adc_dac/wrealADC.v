// WEASIC MICROELECTRONICS S.A.
// DATE 08-03-2019 VERSION 1.0
// Author: Athanassios Moschos
`define Nbits 10
`define N1bits 9

// ADC Model in Verilog AMS
//
module wrealADC (CLK,PD,SAMPLE,VDD,VSS,AIN1,AIN2,RST,HIGH,DATAOUT);
   output      [`Nbits-1:0] DATAOUT;
   output      SAMPLE;  
   input       CLK,PD,RST;
   input       AIN1,AIN2,VDD,VSS,HIGH; 
   wreal       AIN1,AIN2,HIGH,VDD,VSS;
   parameter   Td = 1n;
   real        PreBit, REF, REFN, DIFF;
   reg	       signBit;
   reg         sampling;
   reg         [14:0] counter;
   integer     Dval;
// My precision is with respect to the bits I have available.
// For 10 bits precision I can depict 1024 (= max Decimal value) different values,
// thus my precision is (HIGHref - VSS)/(maxBitValue) ~= 0.XXXV precision 
   always begin     // get dV per bit wrt reference voltages
     PreBit = (HIGH-VSS) / ((1<<`N1bits)-1);
      REF = HIGH;
      REFN =  -HIGH;
      @(HIGH,VSS);// update if reference voltages change
   end

   always begin
     DIFF = AIN1 - AIN2; // get the difference between the input signals, either positive or negative
     @(AIN1,AIN2);
   end

   always @(negedge PD) begin
     counter = 15'b1;
   end

   always @(posedge PD) begin
     counter = 15'b0; 
   end

   always @(posedge CLK) begin
     if (~PD) begin
       if (RST)
         begin
           counter = 15'b1;
           sampling = 1'b0;
         end
       else if (counter[14] == 1'b1)
         begin
           counter = 15'b1;
           sampling = 1'b0;
         end
       else if (counter[0] == 1'b1)
         begin
           counter = counter << 1;
           sampling = 1'b1;
         end
       else
         begin
           counter = counter << 1;
           sampling = 1'b0;
         end
     end
     else
       begin
         sampling = 1'b0;
         counter = counter;
       end
   end

   always @(posedge CLK) begin
      if (PD == 1)
        begin
          Dval = 1'b0;
          signBit = 0;
        end
      else if (RST == 1)
        begin
          Dval = 1'b0;
          signBit = 0;
        end
      else if (counter[14] == 1'b1)
	begin
// If DIFF < -HIGH then clipping effect with lowest value.
          if (DIFF<REFN) begin
            Dval = 'b0;
            signBit = 0;
          end
// If DIFF > HIGH then clipping effect with highest value.
          else if (DIFF>REF) begin 
            Dval = {`Nbits{1'b1}};
            signBit = 1;
          end
// The quantized output value of the ADC
          else
            if (DIFF < 0)
	      begin
                Dval = abs(DIFF)/PreBit;
                signBit = 1'b0;
  	      end
            else
              begin
                Dval = DIFF/PreBit;
	        signBit = 1'b1;
	      end
	end
     else if (counter[0] == 1'b1)
       begin
         Dval = Dval;
         signBit = signBit;
       end
     else
       begin
         Dval = Dval;
         signBit = signBit; 
       end
   end
   assign #(Td/1n) SAMPLE = sampling;
   assign #(Td/1n) DATAOUT[`Nbits-1] = signBit;
   assign #(Td/1n) DATAOUT[`Nbits-2:0] = Dval;
endmodule // wrealADC
