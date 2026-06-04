@echo off

del .\proj_1_app_instr*.mif
del .\proj_1_app_data*.mif

echo *** UPDATE_MIF (update_mif.log) ***
copy rev_1\proj_1_app_instr*.mif .
copy rev_1\proj_1_app_data*.mif .
quartus_cdb.exe --update_mif fpgnix > update_mif.log
del .\proj_1_app_instr*.mif
del .\proj_1_app_data*mif

echo *** ASM (update_asm.log) ***
quartus_asm.exe fpgnix > update_asm.log

echo *** JIC (jic.log) ***
quartus_cpf.exe -c output_files\fpgnix.cof > jic.log

echo *** SVF (update_svf.log) ***
quartus_cpf.exe -c -q 25MHz -g 3.3 -n p output_files\fpgnix.sof output_files\fpgnix.svf > update_svf.log

@echo on
