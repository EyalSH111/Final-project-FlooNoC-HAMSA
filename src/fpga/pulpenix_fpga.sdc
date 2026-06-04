
create_clock -period 40 [get_ports altera_clk25mhz]

derive_pll_clocks

derive_clock_uncertainty

#over constrain hold for fitting
set quartus_exe $::TimeQuestInfo(nameofexecutable)
if { $quartus_exe == "quartus_fit" } {
   set_clock_uncertainty 0.25 -add -hold -enable_same_physical_edge -from [get_clocks {msystem|altera_pll|altpll_component|auto_generated|pll1|clk[0]}]
}

set_false_path -from [all_inputs]
set_false_path -to   [all_outputs]
