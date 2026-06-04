import r2d2

class CSUPPLY(r2d2.Command):

    def __init__(self, interface, *args):
        r2d2.Command.__init__(self, interface, *args)

    def __del__(self):
        self.interface.puts('SYSTEM:local\n'.encode('ascii', errors='strict'))

    def read(self, address):
        print('WARNING: READ is not yet implemented')
        return 0

    def write(self, address, value):
        self.interface.puts('SYSTEM:REMOTE\n'.encode('ascii', errors='strict'))
        # self.interface.puts(('OUTPUT:STATE ' + 'OFF\n').encode('ascii', errors='strict'))
        self.interface.puts(('APPL %s, %s, 1.0\n' % (address, value)).encode('ascii', errors='strict'))
        self.interface.puts(('OUTPUT:STATE ' + 'ON\n').encode('ascii', errors='strict'))
        # self.interface.puts(('SYSTEM:ERROR?\n').encode('ascii', errors='strict'))
        # print(self.interface.read(30).decode('ascii'))
