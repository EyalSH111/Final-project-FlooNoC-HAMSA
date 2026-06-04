import socket
import threading
import time

#TODO: add redirection of gets and puts to log file(s)

class Interface():
    def __init__(self):
        self.telnet_server = False
        self.lock = threading.Lock()
        
    def __del__(self):
        pass

    def start(self):
        pass

    def puts(self, message):
        return NotImplementedError("puts(message) not implemented")

    def gets(self, size=0):
        return NotImplementedError("gets([size]) not implemented")

    def show_tx(self):
        print("START OF TX")
        print("====================")
        while True:
            try:
                data = self.gets(1)
            except:
                print("\n")
                print("====================")
                print("END OF TX")
                break
            print(data.decode('ascii'), end='', flush=True)

    def run_telnet(self):
        print("running telnet server")
        HOST = '' # Symbolic name meaning all available interfaces

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((HOST, 0))
            s.listen()
            print("Listening on port: +"+str(s.getsockname()[1]))
            print(s.getsockname())
            conn, addr = s.accept()
            print('Connected by', addr)

            #s.setblocking(0) #<<<caution

            self.telnet_server = True

            th_telnet_rx = threading.Thread(target=self.telnet_rx, args=(conn,), daemon=True)
            th_telnet_tx = threading.Thread(target=self.telnet_tx, args=(conn,), daemon=True)

            th_telnet_rx.start()
            th_telnet_tx.start()

            while self.telnet_server:
                time.sleep(1)

    def telnet_rx(self, conn):
        while conn and self.telnet_server:
            data = conn.recv(1024)
            if data:
                self.puts(data)
            else: #connection dropped
                print("Telnet disconnected...")
                self.stop_telnet_server(conn)
                break

    def telnet_tx(self, conn):
        while conn and self.telnet_server:
            try:
                data = self.gets(1)
            except:
                print("Interface disconnected...")
                self.stop_telnet_server(conn)
                break

            conn.sendall(data)

    def stop_telnet_server(self, conn):
        self.telnet_server = False
        conn.close()
