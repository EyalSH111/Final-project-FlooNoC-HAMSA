@echo off

echo *** write to flash (flash.log) ***
quartus_pgm.exe -c usb-blaster -m JTAG -o "ip;output_files\fpgnix.jic" > flash.log

@echo on
