import r2d2

class CSmUart(r2d2.Command):

    def __init__(self, interface, *args):
        r2d2.Command.__init__(self, interface, *args)

    def read(self, address):
        self.interface.puts(('#r ' + hex(address)[2:] + '\n').encode('ascii'))
        temp = self.interface.gets(10).strip().decode('ascii')
        return int(temp, 16)

    def write(self, address, value):
        self.interface.puts(('#w ' + hex(address)[2:] + ' ' + hex(value)[2:] + '\n').encode('ascii'))
