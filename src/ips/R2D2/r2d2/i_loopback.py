import r2d2
from collections import deque
import time

class ILoopback(r2d2.Interface):
    def __init__(self):
        self.Q = deque()

    def __del__(self):
        pass

    def puts(self, message, encode=True):
        if encode:
            message = message.encode()
        self.Q.extend([c for c in message])

    def gets(self, size=1, blocking=False):
        r = ''
        if not blocking:
            while self.Q and size:
                size -= 1
                r += (chr(self.Q.popleft()))
        else:
            while size:
                if self.Q:
                    size -= 1
                    r += (chr(self.Q.popleft()))
                else:
                    time.sleep(1)
        return r
