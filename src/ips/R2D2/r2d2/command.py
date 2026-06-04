class Command:

    def __init__(self, interface, *args):
        self.interface = interface
        self.ilock = self.interface.lock

    def read(self, address):
        return NotImplementedError("write() not implemented")

    def write(self, address, value):
        return NotImplementedError("write() not implemented")

    def interactive(self):
        while True:
            self.interface.puts((input() + '\n').encode('ascii'))
            temp = ''
            while temp[-1:] != '>':
                temp = self.interface.gets().decode()
                print(temp, end='')
