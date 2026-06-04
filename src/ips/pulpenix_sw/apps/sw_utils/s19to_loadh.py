#!/usr/bin/env python2.7

import sys
import math

###############################################################################
# Function to dump single bytes of a string to a file
###############################################################################
def dump_bytes( filetoprint, addr, data_s):
    for i in xrange(0,4,1):
        filetoprint.write("@%08X %s\n" % ( addr+i,  data_s[i*2:(i+1)*2] ))

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
# arrange bytes in words
###############################################################################
def bytes_to_words(byte_dict, word_dict):
    for addr in byte_dict:
        wordaddr = addr >> 2
        data = "00000000"

        if wordaddr in word_dict:
            data = word_dict[wordaddr]

        byte = addr % 4
        byte0 = data[0:2]
        byte1 = data[2:4]
        byte2 = data[4:6]
        byte3 = data[6:8]
        new   = byte_dict[addr]

        if byte == 0:
            data = "%s%s%s%s" % (byte0, byte1, byte2, new)
        elif byte == 1:
            data = "%s%s%s%s" % (byte0, byte1, new,   byte3)
        elif byte == 2:
            data = "%s%s%s%s" % (byte0, new,   byte2, byte3)
        elif byte == 3:
            data = "%s%s%s%s" % (new,   byte1, byte2, byte3)

        word_dict[wordaddr] = data

###############################################################################
# Start of file
###############################################################################
if(len(sys.argv) < 4):
    print "Usage s19to_loadh.py FILENAME instr_start_addr data_start_addr"
    quit()


l2_banks     = 1
l2_bank_size = 8192 # in words (32 bit)
l2_start     = int(sys.argv[2],0)
l2_end       = l2_start + l2_banks * l2_bank_size * 4 - 1

tcdm_banks     = 1
tcdm_bank_size = 6144 # in words (32 bit)
tcdm_start     = int(sys.argv[3],0)
tcdm_end       = tcdm_start + tcdm_banks * tcdm_bank_size * 4 - 1
tcdm_bank_bits = int(math.log(tcdm_banks, 2))


###############################################################################
# Parse s19 file
###############################################################################
s19_dict = {}
loadh_dict = {}

s19_parse(sys.argv[1], s19_dict)

bytes_to_words(s19_dict, loadh_dict)


# word align all addresses
l2_start   = l2_start   >> 2
l2_end     = l2_end     >> 2
tcdm_start = tcdm_start >> 2
tcdm_end   = tcdm_end   >> 2
# actual size of L2 and TCDM (for flash)
l2_size     = 0
tcdm_size   = 0
l2_blocks   = 0
tcdm_blocks = 0
###############################################################################
# open files
###############################################################################

tcdm_files = {}
for i in range(0, tcdm_banks):
    tcdm_files[i] = open("tcdm_bank%d_loadh.txt" % i, 'w')


instrFile  = open("instr_loadh.txt",    'w')


###############################################################################
# write the stimuli
###############################################################################
for addr in sorted(loadh_dict.keys()):
    data = loadh_dict[addr]

    # l2 address range
    if(addr >= l2_start and addr <= l2_end):
        l2_base = addr - l2_start
        l2_size += 1

        #l2_stim.write("@%08X %s\n" % (l2_base, data))
        instrFile.write("@%08X %s\n" % (addr*4, data)) # for loadable mode

    # tcdm address range
    else :
      # print ("TMP DBG addr = %x ; tcdm_start = %x , tcdm_end = %x" % (addr,tcdm_start,tcdm_end))
      if(addr >= tcdm_start and addr <= tcdm_end):
          tcdm_addr = addr >> tcdm_bank_bits # for loadable mode
          bank      = addr % tcdm_banks
          tcdm_files[bank].write("@%08X %s\n" % (tcdm_addr*4, data))
          tcdm_size += 1


###############################################################################
# close all files
###############################################################################

for i in tcdm_files:
    tcdm_files[i].close()

instrFile.close()

