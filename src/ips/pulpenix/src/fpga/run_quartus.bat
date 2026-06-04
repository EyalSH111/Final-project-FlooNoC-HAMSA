@echo off

del .\*.mif

echo *** MAP (map.log) ***
quartus_map.exe fpgnix > map.log

echo *** FIT (fit.log) ***
quartus_fit.exe fpgnix > fit.log

echo *** ASM (asm.log) ***
quartus_asm.exe fpgnix > asm.log

echo *** SVF (svf.log) ***
quartus_cpf.exe -c -q 25MHz -g 3.3 -n p output_files\fpgnix.sof output_files\fpgnix.svf > svf.log

echo *** JIC (jic.log) ***
quartus_cpf.exe -c output_files\fpgnix.cof > jic.log

#echo *** SVF_FLASH (svf_flash.log) ***
#quartus_cpf.exe -c -q 25MHz -g 3.3 -n p output_files\fpgnix.cdf output_files\fpgnix_flash.svf > svf_flash.log

@echo on
