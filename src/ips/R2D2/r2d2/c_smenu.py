import r2d2
import time

class CSMenu(r2d2.Command):

    def __init__(self, interface, *args):
        r2d2.Command.__init__(self, interface, *args)
        self.use_hashtag = False

    def read(self, address, timeout=0):
        if self.use_hashtag:
            return self.hashtag_read(address, timeout)
        else:
            return self.smart_read(address, timeout)

    def write(self, address, value, timeout=0):
        if self.use_hashtag:
            return self.hashtag_write(address, value, timeout)
        else:
            return self.smart_write(address, value, timeout)

    def smart_read(self, addr, timeout=0):
        with self.ilock:
            self.interface.gets(0)
            self.interface.puts(bytearray([0x83]), False)
            self.interface.puts(addr.to_bytes(4, byteorder='big'), False)
            resp = None
            while resp != 0x88: 
                resp = int.from_bytes(self.interface.gets(1), byteorder='big')

            data = int.from_bytes(self.interface.gets(4), byteorder='big')
            return data

    def smart_write(self, addr, wdata, timeout=0):
        with self.ilock:
            self.interface.puts(bytearray([0x80]), False)
            self.interface.puts(addr.to_bytes(4, byteorder='big'), False)
            self.interface.puts(wdata.to_bytes(4, byteorder='big'), False)

    def hashtag_read(self, address, timeout=0):
        with self.ilock:
            self.interface.gets(0)
            self.interface.puts(('#r ' + hex(address)[2:] + '\n').encode('ascii'))
            temp = self.interface.gets(9).strip().decode('ascii')
            return int(temp, 16)

    def hashtag_write(self, address, value, timeout=0):
        with self.ilock:
            self.interface.puts(('#w ' + hex(address)[2:] + ' ' + hex(value)[2:] + '\n').encode('ascii'))

    def openocd_start(self):
        self.interface.puts(bytearray([0x85]))

    def openocd(self, char):
        with self.ilock:
            self.interface.gets(0)
            self.interface.puts(bytearray([ord(char)]))
            if char is 'R':
                r = int.from_bytes(self.interface.gets(1), byteorder='big')
                return chr(r)
            else:
                return None

    def openocd_server(self, port):
        sock = r2d2.ISocket(ip='', port=6789, server=True)

        f = open('openocd.txt', 'w')
        #self.openocd_start()

        while True:
            x = sock.gets(1).decode()
            f.write(x)
            r = self.openocd(x)
            if r is not None:
                sock.puts(bytearray([ord(r)]))

    def openocd_to_jtag(self, sock):
        while True:
            x = sock.gets(1)
            self.interface.puts(x)

    def jtag_to_openocd(self, sock):
        while True:
            x = self.interface.gets(1)
            sock.puts(x)

                

