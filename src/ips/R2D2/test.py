import time
import r2d2

# import negev
# from negev.address import *
a = r2d2.CFSPI(r2d2.IUart('COM23', 115200))
# a = negev.Negev('uart')

# i = 0
# while(i <= 25):
#     a.write('P25V', i)
#     sleep(0.25)
#     i = i + 0.1
#     if(i>=25):
#         i = 0

#a.interactive()
# print(a.read(0x1fd00000))
# a.write(0x1fd00000, 0xf)
# print(a.read(0x1fd00000))
print("starting at " + str(time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime())))
for i in range(0xffffffff, 0, -1):
    for j in range(0x1fd00004, 0x1fd80000):
        a.write(j, i)
        temp = a.read(j)
        if temp != i:
            print('Failed to read: ' + hex(j) + ' = ' + hex(i) + ' != ' + hex(temp))
            a.write(j, i)
            temp = a.read(j)
            if temp != i:
                print("stopping at " + str(time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime())))
                raise NameError('Failed to read: ' + hex(j) + ' = ' + hex(i) + ' != ' + hex(temp))
    print("stopping at " + str(time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime())))
