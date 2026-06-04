import r2d2
import threading

class HalfBridge:
    def __init__(self, if_from, if_to, save_to_file=None, filter_func=None):
        self.if_from = if_from
        self.if_to   = if_to
        self.thread_half_bridge = threading.Thread(target = self.x_to_y, args=(if_from, if_to), daemon=True)
        self.half_bridge_active = False
        if save_to_file:
            self.file = open(save_to_file, 'w')
        else:
            self.file = None

        self.filter_func = filter_func

    def start(self):
        self.half_bridge_active = True
        self.thread_half_bridge.start()

    def stop(self):
        self.half_bridge_active = False

    def x_to_y(self, x, y):
        while self.half_bridge_active:
            data = x.gets()
            if data:
                if self.filter_func:
                    data = self.filter_func(data)
                y.puts(data)
                if self.file:
                    self.file.write(data.decode(encoding='ascii'))
                    self.file.flush()

