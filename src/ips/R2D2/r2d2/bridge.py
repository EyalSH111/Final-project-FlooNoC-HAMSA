import r2d2

class Bridge:
    def __init__(self, if_a, if_b, file_a2b=None, file_b2a=None, filter_a2b=None, filter_b2a=None):
        self.if_a = if_a
        self.if_b = if_b

        self.hb_a2b = r2d2.HalfBridge(if_a, if_b, file_a2b, filter_func=filter_a2b)
        self.hb_b2a = r2d2.HalfBridge(if_b, if_a, file_b2a, filter_func=filter_b2a)

    def start(self):
        self.hb_a2b.start()
        self.hb_b2a.start()

    def stop(self):
        self.hb_a2b.stop()
        self.hb_b2a.stop()

