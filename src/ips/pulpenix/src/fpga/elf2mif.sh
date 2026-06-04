#!/bin/bash
#elf->s19->slm->mif

echo "ELF -> S19 (srec)"
mkdir -p build
${PREFIX}-objcopy --srec-len 1 --output-target=srec $1 build/test.s19
cp build/test.s19 build/flash.s19

echo "S19 -> SLM"
./s19toslm.py build/test.s19

echo "SLM -> MIF"
./slm2mif.py l2_stim.slm tcdm_bank0.slm 128


echo "clean..."
\rm -rf build
rm *.slm
rm spi_stim.txt
rm app_data.mif  app_data128.mif    app_instr.mif    app_instr32.mif
