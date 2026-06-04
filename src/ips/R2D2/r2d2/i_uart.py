import r2d2
from time import sleep,time
import serial
import serial.tools.list_ports as ports


class IUart(r2d2.Interface, serial.Serial):
    def __init__(self, port='auto', baudrate=115200, stopbits=1):
        r2d2.Interface.__init__(self)
        if port == 'auto':
            port_list = ports.comports()
            num_of_open_ports = len([port for port in port_list if self.port_open(port[0])])
            if num_of_open_ports == 0:
                print("No port detected. Please open a port")
            elif num_of_open_ports > 1:
                print("The following ports are open:")
                for i in range(0, num_of_open_ports):
                    print(str(i) + ') ' + str(port_list[i]))
                while True:
                    user_port = int(input("Please insert desired port to use, and press enter\n"))
                    if num_of_open_ports > user_port >= 0:
                        break
                port_list = [ports.comports()[user_port]]
            # TODO: remove this HACK (allows for waiting for os to prepare port)
            num_of_open_ports = len([port for port in port_list if self.port_open(port[0])])
            while num_of_open_ports != 1:
                port_list = ports.comports()
                num_of_open_ports = len([port for port in port_list if self.port_open(port[0])])
            print("Connecting to: " + str(port_list[0]))
            port = port_list[0][0]
            sleep(1)
        if stopbits == 1: #TODO this is a hack
            stopbits = serial.STOPBITS_ONE
            dsrdtr = False
        else:
           stopbits = serial.STOPBITS_TWO
           dsrdtr = 1
        serial.Serial.__init__(self, port=port,
                               baudrate=baudrate,
                               parity=serial.PARITY_NONE,
                               stopbits=stopbits,
                               bytesize=serial.EIGHTBITS,
                               xonxoff=False,  # disable software flow control,
                               rtscts=False,  # disable hardware (RTS/CTS) flow control
                               dsrdtr=dsrdtr,  # disable hardware (DSR/DTR) flow control
                               timeout=2,
                               write_timeout=1)

    def __del__(self):
        self.close()

    def puts(self, message, encode=False):
        if encode:
            message = message.encode()
        self.write(message)
        self.flush()

    def gets(self, size=1):
        if size == 0:
            if self.inWaiting() > 0:  # if incoming bytes are waiting to be read from the serial input buffer
                data = self.read(self.inWaiting())
                return data
            else:
                return b''
        else:  # blocking, get until 'size' bytes received
            data = b''
            remaining = size - len(data)
            while True:
                data += self.read(remaining)
                remaining = size - len(data)
                if not remaining:
                    break
        if data:

            return data
        else:
            raise Exception("Connection closed")

    def gets_timed(self, size=1, timeout=0):
        # blocks flow until timeout then raises exception
        start = now = time()
        data = b''
        remaining = size - len(data)
        while now < start + timeout:
            data += self.read(remaining)
            remaining = size - len(data)
            if remaining == 0 and data:
                return data
            now = time()
        if now >= start + timeout:
            raise TimeoutError  # if got here didn't get data in time specified




    def port_open(self, port):
        ser = serial.Serial()
        try:
            ser.port = port
            ser.open()
            ser.close()
            return True
        except serial.SerialException:
            return False
