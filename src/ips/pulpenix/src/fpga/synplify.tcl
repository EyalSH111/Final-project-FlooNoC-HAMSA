puts "------------------- start of synplify.tcl -------------------"

source filelist.tcl

add_file fpgnix.sdc

impl -add rev_1 -type fpga
source options.tcl
source defines.tcl
project -result_file "rev_1/fpgnix.vqm"
impl -active rev_1

puts "* run..."
project -run

puts "-------------------- end of synplify.tcl --------------------"
