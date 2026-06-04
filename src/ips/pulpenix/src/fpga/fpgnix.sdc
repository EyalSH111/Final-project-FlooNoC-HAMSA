puts "* sdc..."
define_clock -name clk25 p:altera_clk25mhz -period 40  -clockgroup clkgrp0 -rise 0 -fall 20  -route 0 
define_clock -name tck   p:TCK             -period 200 -clockgroup clkgrp1 -rise 1 -fall 101 -route 0  

set_output_delay -clock clk25 10 p:uart_tx
set_output_delay -clock clk25 10 {p:led[0]}
set_output_delay -clock clk25 10 {p:led[1]}
set_output_delay -clock clk25 10 {p:led[2]}
set_output_delay -clock clk25 10 {p:led[3]}

set_input_delay -clock clk25 10 p:sys_rst
set_input_delay -clock clk25 10 p:uart_rx

set_input_delay -clock clk25 10 p:nSRST 

set_input_delay -clock  tck 50 p:nTRST 
set_input_delay -clock  tck 50 p:TMS 
set_input_delay -clock  tck 50 p:TDI 
set_output_delay -clock tck 50 p:TDO

