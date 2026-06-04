#!/usr/bin/env python3
import sys, os, time
sys.path.append(os.environ["PULP_ENV"]+"/src/ips/R2D2")
import r2d2

if len(sys.argv)>1:
    uart = sys.argv[1]
else:
    uart = '/dev/ttyUSB0'

if len(sys.argv)>2:
    port = int(sys.argv[2])
else:
    port = 8989

#interface connection to io_server.c
i=r2d2.IUart(uart, 115200)
#print("*** Connected to {} ({})".format(uart, i))
print("*** Connected to {}".format(uart))

#enable openocd over uart
c = r2d2.CSMenu(i)

# jtag_sel = 0 (openocd)
c.write(0x1a300000, 0x0)

# put uart in openocd mode
c.write(0x1a10001f, 0x4)

#new socket towards openocd
ocd_i=r2d2.ISocket("", port, server=True, start=False)

#bridge between openocd and cpu
b=r2d2.OpenOCD_Bridge(i, ocd_i, 'cpu', 'ocd')
print("*** waiting for openocd remote_bitbang on port {}".format(port))
print("export SIM_HOST=localhost")
print("export SIM_PORT={}".format(port))
ocd_i.start()
#print("*** Opened socket at port {} ({}) ".format(port,ocd_i))
print("*** Connection established")
b.start()


while True:
    time.sleep(10)
