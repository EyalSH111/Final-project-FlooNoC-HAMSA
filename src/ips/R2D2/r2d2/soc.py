import importlib


class SoC:
    def __init__(self, command, *args):
        self.command = command

    def read(self, address):
        return self.command.read(address)

    def write(self, address, value):
        return self.command.write(address, value)

    def interactive(self):
        return self.command.interactive()
