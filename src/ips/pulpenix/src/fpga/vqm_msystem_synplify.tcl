puts "------------------- start of synplify.tcl -------------------"

source vqm_msystem_filelist.tcl

add_file vqm_msystem_wrap.sdc

impl -add rev_1 -type fpga
source vqm_msystem_options.tcl
source defines.tcl
project -result_file "rev_1/vqm_msystem_wrap.vqm"
impl -active rev_1

puts "* run..."
project -run

puts "-------------------- end of synplify.tcl --------------------"
