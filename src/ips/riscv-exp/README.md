# RISCV-exp

This is a truly risky riscy.
It is based on regular riscv and holds only modified files.
Any modified module gets a new name (and hence, filename). The convention is to prefix the module name with a captial X: so riscv_core changes to Xriscv_core.
This means all modules above a modified file gets a modified version too.

As any unmodified file is coming from the regular riscv - it is considered as a subcomponent of riscv-exp in ips_list.yml.

The filelist of the experimental core is reusing the filelist of the regular core.


IMPORTNAT! Before taping out - please diff the modified against the original files, to make sure no fix/feature went to one but should have gone to both

The tags used for this repo follow the tags of the regular repo they are using.
