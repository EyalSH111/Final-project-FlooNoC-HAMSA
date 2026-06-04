
# DDP23 FPGA SETUP
#=================

# IMPORTANT: For hiererchical synplify/quartus vqm flow please first see: vqm_hir_fpga_syn_guide.txt

generic
source $ws/ddp23_pulpenix/ddp23_pulpenix_tb/setup.sh
cd $ws/ddp23_pulpenix/ddp23_pulpenix_tb/src/ips/pulpenix/src/fpga

# Make sure you xbox or other specific added files are included in filelist.tcl

qrun ./run_synplify

Wait for message:
Created tarball: fpgnix.tar.gz

copy all files in fpgnix.tar.gz to FPGA window environment:

C:\Users\user\Desktop\BIU\pulpenix2_lite_win\pulpenix\src\fpga

from powershell:

./run_quartus

proceed with pulpenix2_lite_win guiding


#=====================================================================================

# ADVANCED GENPRO REFERENCE (NOT ALL INFORMATION BELOW IS RELEVANT FOR DDP23 SETUP

# FPGNIX
FPGNIX is the FPGA version of Pulpenix. It adds a wrapper targeting the E115 board we use at EnICS.
The top is ```fpgnix``` which instantiates ```msystem``` as well as PLL and some FPGA-related glue logic.

## Prerequisites
### Hardware
* E115 FPGA Board
* USB Blaster (for programming)
* FTDI flat cable (or compatiable, for uart)
* Segger's J-LINK probe (or compatiable, for software debug, optional)

### Software
* [Synplify Premier](https://www.synopsys.com/implementation-and-signoff/fpga-based-design/synplify-premier.html) (P-2019.09-SP1) (if you want to change RTL)
* [Intel Quartus Prime](https://fpgasoftware.intel.com/18.1/?edition=lite) (Lite 18.1) (if you want to change RTL)
    * on Windows machines: [USB blaster drivers](https://www.intel.com/content/www/us/en/programmable/support/support-resources/download/drivers/usb-blaster/dri-usb-blaster-vista.html)
* [Official OpenOCD](http://openocd.org/getting-openocd/) - compiled with support for usb-blaster (for FPGA programming) and your JTAG adapter (for SW debugging, this README uses jlink). Use a recent version as risc-v support is constantly getting better.
    * on Linux machines: make sure to copy contrib/60-openocd.rules as described in the [README](https://sourceforge.net/p/openocd/code/ci/master/tree/README).
* [RISCV-toolchain](https://github.com/riscv/riscv-gnu-toolchain) (with gdb)
* Git (with [LFS](https://git-lfs.github.com) support)
* Python3
    * [pyserial](https://pypi.org/project/pyserial/)
    * [pyyaml](https://pypi.org/project/PyYAML/)
* Serial terminal such as PuTTY/Teraterm/picoterm/etc.

## I cannot wait / Quick Start
1. Clone the pulpenix repository (if not already cloned)
    ```
2. Connect the usb blaster to the computer
3. Connect the E115 board to the power supply and turn it on
4. Program the FPGA in one of the following methods:
    1. using OpenOCD:
    ```
    cd $PULP_ENV/src/fpga
    openocd -f program_fpga.cfg
    ```

    2. using Quartus from command line:
    ```
    cd $PULP_ENV/src/fpga
    ./program_fpga # or program_fpga.bat on windows
    ```
    
    3. using Quartus GUI:
    
        * open Quartus GUI
        * open the programmer (Tools -> Programmer)
        * click `Add file...`
        * select .../src/fpga/output_files/fpgnix.sof and press `OK`
        * click `Hardware Setup...` and select your USB Blaster
        * click `Start`
    
    <br/>
    
    If all went well, when finished programming (using one of the methods above) you should see the LEDs blinking:
        
    * 1 led is driven by a hardware counter and blinks once per second
    * The other 3 leds are driven by the software running on the RISCV core, making 2 dots dance

5. Connect the FTDI flat cable (as described [here](#uart))
6. Open a terminal (e.g. PuTTY/picocom) for serial communication, with baudrate 115200
    * For linux, you can run the following command:
    ```
    picocom /dev/ttyUSB0 --baud 115200 --imap lfcrlf
    ```
    * You should see Winnie the Pooh.
    * You might need to replace ```/dev/ttyUSB0``` in the command above with something else. Use ```python3 -m serial.tools.list_ports``` to list all available serial devices.
    * **If using picocom, press ```Crtl+A+X``` to exit.**
    
7. Connect the JTAG probe (according to the instructions [here](#jtag))
    
    **Note: there is an option to send JTAG commands through the UART connection without using a JTAG probe. See [JTAG over UART](#jtag-over-uart) below.**

8. Run the following command (still under $PULP_ENV/src/fpga)
    ```
    openocd -f jlink.cfg -f debug.cfg
    ```
    **Note: if you use a different JTAG-adapter, you should replace ```jlink.cfg``` in the line above (and any following code snippets) with a script that sets up your adapter of choice.**
    
    The output should look something like this:
    ```
    Open On-Chip Debugger 0.10.0+dev-00858-g4f9e2d717 (2020-05-25-13:58)
    Licensed under GNU GPL v2
    For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
    Info : Hardware thread awareness created
    Info : Listening on port 6666 for tcl connections
    Info : Listening on port 4444 for telnet connections
    Info : J-Link V10 compiled Feb  2 2018 18:12:40
    Info : Hardware version: 10.10
    Info : VTarget = 2.554 V
    Info : clock speed 8000 kHz
    Info : JTAG tap: FPGNIX.cpu tap/device found: 0x349511c3 (mfg: 0x0e1 (Wintec Industries), part: 0x4951, ver: 0x3)
    Info : datacount=2 progbufsize=8
    Info : Examined RISC-V core; found 1 harts
    Info :  hart 0: XLEN=32, misa=0x40801104
    Info : Listening on port 3333 for gdb connections
    Info : accepting 'gdb' connection on tcp/3333
    ```
    
9. Now, in a different terminal run gdb (riscv32-unknown-elf-gdb) and enter the following command
    ```
    target extended-remote :3333
    ```
    You should now be able to debug with gdb. Note that while gdb stops the
    program     – the led blinking every 1 second keeps blinking because it is
    not driven by software. The other 3 leds should freeze.
    * enter the continue command
        ```
        (gdb) continue
        ```
        The leds should continue moving
        
    * Hit ```Ctrl+c```
    
        Control goes back to GDB and the 3 leds should freeze.
        
    * quit gdb (type ```quit``` and hit 'y' when asked)

10. Go back to the first terminal and kill the running OpenOCD by pressing `Ctrl+c`, then run the following command
    ```
    openocd -f jlink.cfg -f load_elf.cfg
    ```
    This command halts the core, loads a different image to the core's instruction and data memories, and resets the core. The image loaded is ```$PULP_ENV/src/fpga/test.elf```.
    The new software does not change the SW leds, so only the HW led should keep blinking, but you should notice a different pattern in the terminal.
    

## JTAG over UART
**_NOTE: Recent design changes cause NDMRESET (Non-Debug Module Reset) to halt  UART communication, so the JTAG over UART is currently not recommended._**

There is a way to debug the core over the UART cable. Currently, this disables any other IO through UART - but it will be solved soon.

From $PULP_ENV/src/fpga run the following command:

```
openocd_bridge.py [serial]
```

```[serial]``` is the device name on your machine. On Linux machine it usualy looks like /dev/ttyUSB0, and on Windows machine it usually looks like COM1. 
You can run ```python3 -m serial.tools.list_ports``` on both Linux and Windows machines to get a list of available devices.

Once you run this script you should see it waiting for openocd to connect, and some code to copy like so:
```
export SIM_HOST=localhost
export SIM_PORT=8989
```

Copy these lines, open a new terminal and run them in the new terminal. Then run openocd as described but replace jlink.cfg with bitbang.cfg, and continue as usual.
Using this technique you might end up using 3 terminals, the first for the bridge (openocd_bridge.py), another for openocd, and a third for gdb.


## RTL Compile flow
We use Synplify to map the source into a Cyclone IV netlist and Quartus to fit and place.

### Synplify
The script ```src/fpga/run_sypnlify``` is used to run Synplify. After runnig Synplify, it creates a tarball with all the files needed for the next stage in Quartus.
* ```rev_1/fpgnix.vqm``` Quartus netlist
* ```rev_1/fpgnix.sdc``` Timing constraints file
* ```rev_1/fpgnix.tcl``` Quartus tcl script
* ```rev_1/*.mif/hex``` memory initialization files

The memories are initialized according to the mif files located under ```src/fpga/slm_files```.

#### How To run:
from src/fpga/ directory
```
$ ./run_synplify
```

if no errors - script will finish printing:
```
    >>> Created tarball: fpgnix.tar.gz
```

tarball contains all files required for the next stage in Quartus.

*TODO:* explain flow and files (filelist, defines, etc.)
*TODO:* how to generate slm_files
*TODO:* quartus version trick

### Quartus
If Quartus is run from another machine (e.g. windows), need to first copy the tarball created in the previous stage and untar it. The files should be under ```src/fpga/rev_1```.
```fpgnix.qpf``` is the Quartus project file, and should be used to open the project.
```fpgnix.qsf``` sets the target device, lists the files to be used (outputs of synplify from previous stage), and assigns FPGA pins to IOs.

#### How To run:
from src/fpga/ directory
```
$ ./run_quartus # or run_quartus.bat for Windows machines
```
*TODO:* sof generation

*TODO:* jic generation and programming


## FPGA Programming
### FPGA programming - using Quartus
One of the outputs from the compile flow is ```output_files/fpgnix.sof```, which can be used by Quartus to program the FPGA.
The shell script ```program_fpga``` (or ```program_fpga.bat``` for windows machines) is using Quartus to program the FPGA.
Note: this does not write to the on-board flash, so the image will be lost after power-down. See "FLASH burning" for instructions.

### FPGA programming - using OpenOCD
One of the outputs from the compile flow is ```output_files/fpgnix.svf```, which can be used by OpenOCD to program the FPGA.
To program the FPGA via USB-Blaster using OpenOCD:

```openocd -f program_fpga.cfg```

**Note: this does not write to the on-board flash, so the image will be lost after power-down. See "FLASH burning" for instructions.**

### FLASH burning
In order for the FPGA image to be loaded after power-up, the image has to be stored on the on-board FPGA. 
One of the outputs from the compile flow is ```output_files/fpgnix.jic```, which is used to burn the image to the flash.
The shell script ```burn_flash``` (or ```burn_flash.bat``` for windows machines) is using Quartus to burn the on-board FPGA.

**Note: flash burning using openocd is currently not supported.**

## Software loading
Once the FPGA image is loaded, new software can be loaded using OpenOCD through the core JTAG (through GPIO pins; not to be confused with the board JTAG driven by USB Blaster).
To load a new ELF file using OpenOCD:

```openocd -f jlink.cfg -f load_elf.cfg```

This script loads the test.elf that is in the current directory, resets the core and exits

## Software debugging
In order to connect to the core with GDB, the following script connects to the target and waits for incoming GDB connections:

```openocd -f jlink.cfg -f debug.cfg```

## GPIOs
Currently the only interfaces connected to the board's header pins are UART and JTAG. They are connected to the 60-pins header located near the USB blaster connector. Use the following image for orientation:

<img src="src/fpga/images/north_gpio.png" alt="GPIO orientation" width="450">

### UART
The UART signals are connected according to the following table:

|Signal name    | FPGA pin number   |
|:-------------:|:------------------|
| ```uart_tx``` | 7                 |
| ```uart_rx``` | 9                 |
| ```GND```     | 15                |

The signals are named from the FPGA's prespective, so the FPGA is sending data over ```uart_tx``` and expects to receieve data over ```uart_rx```.
Make sure to connect FPGA's TX to cable's RX and vice versa.

```GND``` (pin 15) is not driven by the FPGA but connected to the FPGA's ground. This pin configuration was selected to connect to the 6-pin FTDI UART connector (see image above). If using a different connector, please make sure to also connect the ground pin.

### JTAG
In this section we describe the J-LINK JTAG adapter which follows the ARM 20-pin JTAG interface.

<img src="src/fpga/images/jlink_header.png" alt="20-pin JTAG interface" width="300">

In J-LINK header, pin number 1 has a small arrow pointing at it.
This pinout does not fit to the FPGA pins, so some wiring is required according to the following table:

|Adapter pin number   |Signal name    | FPGA pin number   |
|--------------------:|:-------------:|:------------------|
| 1                   | ```VTref```   | 60                |
| 3                   | ```nTRST```   | 58                |
| 5                   | ```TDI```     | 56                |
| 7                   | ```TMS```     | 54                |
| 9                   | ```TCK```     | 52                |
| 11                  | ```RTCK```    | 50 (unsupported)  |
| 4/6/8/10            | ```GND```     | 48                |
| 13                  | ```TDO```     | 46                |
| 15                  | ```nSRST```   | 44                |
| 17                  | ```DBGREQ```  | 42 (unsupported)  |

**For JTAG adapters with different pinout - please consult your adapter's documentation.**
