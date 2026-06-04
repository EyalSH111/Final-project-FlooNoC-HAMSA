
puts "* sdc..."

# Clock and Reset

define_clock -name clk_sys p:clk_sys -period -clockgroup clkgrp0 -rise 0 -fall 20 -route 0 

    set_input_delay  -clock  clk_sys 10  rstn_sys 
    set_input_delay  -clock  clk_sys 10  apor_n 
    set_input_delay  -clock  clk_sys 10  enable_core     
    set_output_delay -clock  clk_sys 10  ndmreset     
    set_output_delay -clock  clk_sys 10  pad_uart_tx 
    set_input_delay  -clock  clk_sys 10  pad_uart_rx 
    set_input_delay  -clock  clk_sys 10  pad_tck
    set_input_delay  -clock  clk_sys 10  pad_trstn
    set_input_delay  -clock  clk_sys 10  pad_tms
    set_input_delay  -clock  clk_sys 10  pad_tdi
    set_output_delay -clock  clk_sys 10  pad_tdo
    set_input_delay  -clock  clk_sys 10  jtag_sel
    set_output_delay -clock  clk_sys 10  [get_pins gpio_out*]
    
    set_output_delay -clock  clk_sys 10  gpp_master_psel   
    set_output_delay -clock  clk_sys 10  gpp_master_penable
    set_output_delay -clock  clk_sys 10  gpp_master_pwrite    
    set_output_delay -clock  clk_sys 10  [get_pins gpp_master_paddr*] 
    set_output_delay -clock  clk_sys 10  [get_pins gpp_master_pwdata*]
    
    set_input_delay  -clock  clk_sys 10  [get_pins gpp_master_prdata*]
    set_input_delay  -clock  clk_sys 10  gpp_master_pready
    set_input_delay  -clock  clk_sys 10  gpp_master_pslverr    
