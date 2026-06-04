
import sys
import os

sys.path.append(os.getenv('PULP_ENV')+'/src/tb/py_spi_tb/py/py_port')
import spi_access 


#===============================================================================================

# Main

port  = spi_access.port()

addr1 = 8
addr2 = 12
addr3 = 16

data1 = 0xAAAAAAAA
data2 = 0xBBBBBBBB
data3 = 0xCCCCCCCC

sys.stdout.write("PY: Writing %08x to addr %08x\n" % (data1,addr1))
port.write(addr1,data1)

sys.stdout.write("PY: Writing %08x to addr %08x\n" % (data2,addr2))
port.write(addr2,data2)

sys.stdout.write("PY: Writing %08x to addr %08x\n" % (data3,addr3))
port.write(addr3,data3)


val = port.read(addr1)
sys.stdout.write("PY: reading %08x from addr %08x\n" % (val,addr1))

val = port.read(addr2)
sys.stdout.write("PY: reading %08x from addr %08x\n" % (val,addr2))

val = port.read(addr3)
sys.stdout.write("PY: reading %08x from addr %08x\n" % (val,addr3))


port.quit()
     

 



