//   Description: generic power-of-two clock divider

module generic_clk_div (clk_in, reset_n, clk_out);

   parameter  DIV_N = 4;

   localparam DIV_WIDTH = $clog2(DIV_N);

   input  clk_in;
   input  reset_n;
   output clk_out;

   reg [DIV_WIDTH-1:0] div_cntr;
   reg                 clk_out_samp;

   assign clk_out = clk_out_samp;

   always @(posedge clk_in or negedge reset_n)
     // COMMENTED by Slava Yuzhaninov (yuzhans@biu.ac.il) on 10-03-2018:
     // NOTE: Using blocking assignment to prevent race conditions of the clk_out_samp generated clock signal
     begin
        if (reset_n == 1'b0)
          clk_out_samp = 1'b0;
        else
          clk_out_samp = div_cntr[DIV_WIDTH-1];
     end // always @ (posedge clk)

   generate
      if (DIV_WIDTH > 1)
        begin : div_grt_two

           always @(posedge clk_in or negedge reset_n)
             begin
                if (reset_n == 1'b0)
                  div_cntr <= {DIV_WIDTH{1'b0}};
                else
                  div_cntr <= div_cntr + {{DIV_WIDTH-1{1'b0}}, 1'b1};
             end // always @ (posedge clk)

        end // block: generic_div_gen
      else
        begin : div_by_two

           always @(posedge clk_in or negedge reset_n)
             begin
                if (reset_n == 1'b0)
                  div_cntr <= 1'b0;
                else
                  div_cntr <= ~div_cntr;
             end // always @ (posedge clk)

        end
   endgenerate

endmodule // generic_clk_div
