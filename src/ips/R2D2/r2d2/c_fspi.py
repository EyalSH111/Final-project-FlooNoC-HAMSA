import r2d2


class CFSPI(r2d2.Command):

    def __init__(self, interface, *args):
        r2d2.Command.__init__(self, interface)
        self.wr_mem_by_uart(0x1a110000, 1)
        self.wr_mem_by_uart(0x1a112000, 0x80)
        self.wr_mem_by_uart(0x1a110000, 0)
        temp = ''
        while temp[-6:] != 'Ready>':
            t1 = self.interface.gets().decode('ascii')
            temp += t1
            # print(t1, end='')
        self.interface.gets() #clear the buffer

    def wr_mem_by_uart(self, addr, wdata):
        self.interface.write(bytearray([0x80]))
        self.interface.write(addr.to_bytes(4, byteorder='big'))
        self.interface.write(wdata.to_bytes(4, byteorder='big'))

    def read(self, address):
        cmd = 'R ' + hex(address)[2:] + '\n'
        cmd_e = cmd.encode('ascii')
        a = self.interface.gets(0)
        self.interface.puts(cmd_e)
        temp = ''
        while temp[-6:] != 'Ready>':
            t1 = self.interface.gets().decode('ascii')
            temp += t1
            #print(t1, end='')
        #temp = self.interface.gets(10)
        #print("temp = " + str(temp))
        #self.wait_for_ready()
        temp_e = temp.strip()
        return int(temp_e[2:10], 16)
        # WHAT THE ACTUAL FUCK IS GOING ON HERE?
        # self.interface.puts(('R ' + hex(address)[2:] + '\n').encode('ascii'))
        # temp = self.interface.gets(10)
        # print(temp)
        # temp = (temp.decode('ascii').split())
        # return int(temp[0], 16)
        # for i in range(0, len(temp)):
        #     if(temp[i] != 'Ready>'):
        #         return int(temp[i])

    def write(self, address, value):
        temp = ('W ' + hex(address)[2:] + ' ' + hex(value)[2:] + '\n')
        #print("temp1 = "+ temp)
        self.interface.puts(temp.encode('ascii'))
        self.wait_for_ready()

    def wait_for_ready(self):
        x = ''
        while x[-7:] != 'Ready> ':
            x += self.interface.gets(1).decode('ascii')
