
`timescale 1 ns / 1 ns

module faked_fast_sim_altpll #(parameter  CLK_PERIOD = 0) (

	input	  areset,
	input	  inclk0,
	output	  c0,
	output	  c1,
	output	  c2,
	output	  c3,
	output	  locked );
    
  reg clk ;

  initial
  begin
    $display ("ALTERA PLL NOTICE: Simulation faked_fast_sim_altpll.v in use");
    #(CLK_PERIOD/2);
    clk = 1'b1;
    forever clk = #(CLK_PERIOD/2) ~clk;
  end  

  assign c0 = clk ;
  assign locked = 1 ;
       
endmodule    
