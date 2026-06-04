#!/usr/bin/env python2.7

# ////////////////////////////////////////////////////////////////////////////////
# // Company:        Multitherman Laboratory @ DEIS - University of Bologna     //
# //                    Viale Risorgimento 2 40136                              //
# //                    Bologna - fax 0512093785 -                              //
# //                                                                            //
# // Engineer:       Davide Rossi - davide.rossi@unibo.it                       //
# //                                                                            //
# // Additional contributions by:                                               //
# //                 Andreas Traber - atraber@student.ethz.ch                   //
# //                                                                            //
# // Create Date:    05/04/2013                                                 //
# // Design Name:    ULPSoC                                                     //
# // Project Name:   ULPSoC                                                     //
# // Language:       tcl, now python                                            //
# //                                                                            //
# // Description:    s19 to slm conversion tool for stxp70 cluster compilation  //
# //                                                                            //
# // Revision:                                                                  //
# // Revision v0.1 - File Created                                               //
# // Revision v0.2 - Modification: Compiler does now generate little endian     //
# //                 directly. revert bytes!                                    //
# // Revision v0.3 - Moved from 128 bit s19 to 8 bit s19 file. This solves our  //
# //                 problems with misaligned addresses in s19 files.           //
# // Revision v0.4 - Added TCDM memory initialization                           //
# // Revision v0.5 - Rewrote the whole thing in python as tcl cannot handle     //
# //                 long file names properly
# ////////////////////////////////////////////////////////////////////////////////

import sys

###############################################################################
# Read s19 file and put data bytes into a dictionary
###############################################################################
def s19_parse(filename, s19_dict):
    s19_file = open(filename, 'r')
    for line in s19_file:
        rec_field = line[:2]
        prefix    = line[:4]

        if rec_field == "S0" or prefix == "S009" or prefix == "S505" or prefix == "S705" or prefix == "S017" or prefix == "S804" or line == "":
            continue

        data = line[-6:-4] # extract data byte
        str_addr = line[4:-6]

        addr = int("0x%s" % str_addr, 0)


        s19_dict[addr] = data

    s19_file.close()

###############################################################################
# Start of file
###############################################################################
if(len(sys.argv) < 2):
    print "Usage s19tosflash.py FILENAME"
    quit()

sflash_start = 0x00000000
sflash_end   = 0x003FFFFF
imem_base    = 0x00040000
dmem_base    = 0x00080000


l2_bank_size = 16384 if "64KI" in sys.argv else 8192 # in words (32 bit)
l2_start     = 0x00000000
l2_end       = l2_start + l2_bank_size * 4 - 1

tcdm_bank_size = 6144 # in words (32 bit)
tcdm_start     = 0x00100000
tcdm_end       = tcdm_start + tcdm_bank_size * 4 - 1

###############################################################################
# Parse s19 file
###############################################################################
'''
This section parse the c code and boot preload code and fuse them together into one file as follow: (by address)
    00000-00004 - instruction size
    00004-00008 - data size
    00080-40000 - boot preload
    40000-80000 - c code instruction section
    80000+      - c code data section
'''
slm_dict = {}
s19tosflash_dict = {}
s19_parse(sys.argv[1], slm_dict)  # 'build/test.s19'

if ((len(sys.argv) == 4 and ("64KI" in sys.argv)) or (len(sys.argv) == 3 and ("64KI" not in sys.argv))):  # boot preload   
    s19_parse(sys.argv[2], s19tosflash_dict)  # 'build/boot_preload.s19'

    l2_stim_fused  = open("sflash_stim_boot_preload.slm", 'w')
    l2_size    = 0  
    tcdm_size  = 0  
    
    # write to file:

    ###############
    # L2  and TCDM
    ###############
    for addr in sorted(slm_dict.keys()):
        data = slm_dict[addr]
        if(addr >= l2_start and addr <= l2_end):     # write instruction (l2) address range
            l2_base = imem_base + addr - l2_start 
            l2_stim_fused.write("@%08X %s\n" % (l2_base, data))
            l2_size += 1
            
        if(addr >= tcdm_start and addr <= tcdm_end): # write data (tcdm) address range
            tcdm_addr = dmem_base + addr - tcdm_start 
            l2_stim_fused.write("@%08X %s\n" % (tcdm_addr, data))
            tcdm_size += 1
            
    ##############
    # Boot preload
    ##############
    s19_iter = iter(sorted(s19tosflash_dict.keys()))

    for i in range(8): # write instruction and data sizes
        addr = next(s19_iter)
        if i < 4:      # imem size
            data = l2_size & 0xFF
            s19tosflash_dict[addr] = "%02X"%(data)
            l2_size = l2_size >> 8
        else:          # dmem size
            data = tcdm_size & 0xFF
            s19tosflash_dict[addr] = "%02X"%(data)
            tcdm_size = tcdm_size >> 8   
            
    for addr in sorted(s19tosflash_dict.keys()): # write boot preload
        data = s19tosflash_dict[addr]
        if (addr >= sflash_start and addr <= sflash_end):
            sflash_addr = addr - sflash_start
            l2_stim_fused.write("@%08X %s\n" % (sflash_addr, data))
            
    l2_stim_fused.close()
       
else:  # basic sflash
    ###############################################################################
    # open files
    ###############################################################################
    sflash_stim = open("sflash_stim.slm", 'w')
    
    ###############################################################################
    # write the stimuli
    ###############################################################################
    for addr in sorted(slm_dict.keys()):
        data = slm_dict[addr]
    
        if(addr >= sflash_start and addr <= sflash_end):
            sflash_addr = (addr - sflash_start)
            sflash_stim.write("@%08X %s\n" % (sflash_addr, data))
    ###############################################################################
    # close all files
    ###############################################################################        
    sflash_stim.close()



