module one_bit_inv (/*AUTOARG*/
   // Outputs
   a_inv,
   // Inputs
   a
   );

   input a;
   output a_inv;

   assign a_inv = ~a;
   
endmodule
