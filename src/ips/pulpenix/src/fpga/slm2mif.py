#!/usr/bin/env python2

import sys

#--------------------------------------------------------------------------
  

def  store_bank(store_bank_vec , addr_bank , data) :
 vec_extend_length = addr_bank+100 - len(store_bank_vec)
 if (vec_extend_length > 0) :
    for i in range(vec_extend_length) :    
       store_bank_vec.append(0)
 store_bank_vec[addr_bank] = data
    

#--------------------------------------------------------------------------
                  
def gen_mif_file(slmFileName,mifFileName, k=1) :

   slmFileName = open(slmFileName, 'r')
   
   slm_vec = []   
     
   for line in slmFileName.readlines():
   
     lineSplit = line.split()
   
     addr = int("0x" + lineSplit[0][1:] , 16)
     data = int("0x" + lineSplit[1] , 16)
     

     store_bank(slm_vec , addr , data) 
       
   slmFileName.close()

   mem_file = open(mifFileName,'w')
   
   mem_file.write("DEPTH = %d;         -- The size of memory in words\n" % len(slm_vec));
   mem_file.write("WIDTH = %d;          -- The size of data in bits\n" % (32*k));
   mem_file.write("ADDRESS_RADIX = HEX; -- The radix for address values\n");
   mem_file.write("DATA_RADIX = HEX;    -- The radix for data v\n");
   mem_file.write("CONTENT              -- start of (address : data pairs)\n");
   mem_file.write("\nBEGIN\n");

   for i in range(len(slm_vec)/k) :
        mem_file.write("%08X: "%(i))
        for j in range(k):
            mem_file.write("%08X"%slm_vec[i*k+(k-j-1)])
        mem_file.write(";\n")
    
   mem_file.write("\nEND;\n"); 
   mem_file.close()


# main

if(len(sys.argv) < 4):
    print "Missing Argument, please provide source functional memory file names and instruction width (1/4)"
    quit(1)
    
gen_mif_file (sys.argv[1],"app_instr.mif", int(sys.argv[3]))
gen_mif_file (sys.argv[2],"app_data.mif")
gen_mif_file (sys.argv[1],"app_instr32.mif", 1)
gen_mif_file (sys.argv[1],"app_instr128.mif", 4)
gen_mif_file (sys.argv[2],"app_data32.mif", 1)
gen_mif_file (sys.argv[2],"app_data128.mif", 4)
 
#--------------------------------------------------------------------------

