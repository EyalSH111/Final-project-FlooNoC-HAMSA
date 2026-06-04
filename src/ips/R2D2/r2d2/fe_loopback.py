import r2d2

class FELoopback:
    def __init__(self, interface):
        self.interface = interface
        self.hb_loop = r2d2.HalfBridge(interface, interface)

    def start(self):
        self.hb_loop.start()

    def stop(self):
        self.hb_loop.stop()

