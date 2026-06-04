import r2d2
import socket


class ISocket(r2d2.Interface, socket.socket):
    def __init__(self, host, port, server=False, start=True):
        r2d2.Interface.__init__(self)
        socket.socket.__init__(self, socket.AF_INET, socket.SOCK_STREAM)
        self.host = host
        self.port = port
        self.is_server = server

        if self.is_server:
            self.bind((host, port))
            self.listen(1) 
            self.con_socket = None

        if start:
            self.start()

    def __del__(self):
        self.close()

    def __str__(self):
        r = 'ISocket '
        if self.is_server:
            r += 'server listens on '
        else:
            r += 'client connects to '

        r += '(HOST: ' + str(self.host)
        r += ' PORT: ' + str(self.port) + ')'

        return r

    def start(self):
        if self.is_server:
            self.con_socket, _ = self.accept()
        else:
            self.connect((self.host, self.port))
            self.con_socket = self

    #TODO this is a HACK to allow for socket menu to operate
    def write(self):
        pass

    def puts(self, message, encode=False):
        if encode:
            message = message.encode()
        return self.con_socket.sendall(message)

    def flushi(self):
        self.con_socket.setblocking(0)
        self.con_socket.recv(1000)
        self.con_socket.setblocking(1)

    def gets(self, size=0):
        if not self.con_socket:
            return None

        if size == 0: #nonblocking
            try:
                self.con_socket.setblocking(0)
                data = self.con_socket.recv(1000)
                self.con_socket.setblocking(1)
            except:
                self.con_socket.setblocking(1)
                return b''
        else: #blocking, get until 'size' bytes received
            data = b''
            remaining = size - len(data)
            while True:
                d = self.con_socket.recv(remaining)
                if not d:
                    raise Exception("Connection closed")
                data += d
                remaining = size - len(data)
                if not remaining:
                    break

        if data:
            return data
        else:
            raise Exception("Connection closed")

