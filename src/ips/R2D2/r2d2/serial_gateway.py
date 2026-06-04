import serial

# ================================================================================


SU_CMD_WR_WORD = 0x80
SU_CMD_RD_WORD = 0x83
SU_CMD_RSP = 0x88


# ================================================================================

def configPort(portName):
    # configure the serial connections (the parameters differs on the device you are connecting to)
    ser = serial.Serial()
    ser.port = portName
    ser.baudrate = 115200
    ser.parity = serial.PARITY_NONE
    ser.stopbits = serial.STOPBITS_ONE
    ser.bytesize = serial.EIGHTBITS  # number of bits per bytes
    ser.xonxoff = False  # disable software flow control
    ser.rtscts = False  # disable hardware (RTS/CTS) flow control
    ser.dsrdtr = False  # disable hardware (DSR/DTR) flow control
    ser.timeout = 1  # non-block read
    ser.writeTimeout = 1  # timeout for write
    return ser


# ---------------------------------------------------------------------------------


class serGate():

    def __init__(self):
        self.fromPulpQue = []
        self.toPulpQue = []

    # ---------------------------------------------------------------------------------


class serGateWay():
    def __init__(self, serPort, stdioSerGate, escSerGate):
        self.serPort = serPort
        self.stdioSerGate = stdioSerGate
        self.escSerGate = escSerGate

    def activate(self):

        self.serPort.open()

    def gwIterate(self, numItr):
        for i in range(numItr):
            # Continues Read attempt from Serial Port (transmitted from  Pulp's TX)
            # print("TMP DBG: serPort = %s" % self.serPort.port)
            while self.serPort.inWaiting() > 0:
                # print ("TMP DBG: while self.serPort.inWaiting>0 =%d" % self.serPort.inWaiting())
                serReadChar = self.serPort.read(1)
                suCmdRspOn = (ord(serReadChar) == SU_CMD_RSP)
                if suCmdRspOn:
                    rdata = 0
                    for i in range(4):
                        rdata = rdata * 256 + ord(self.getSerChar())
                    self.escSerGate.fromPulpQue.append(rdata)
                    # print("TMP DBG, escSerGate.fromPulpQue.append(%x)" % rdata)
                    suCmdRspOn = False
                else:
                    self.stdioSerGate.fromPulpQue.append(serReadChar)
                    # print("TMP DBG, stdioSerGate.fromPulpQue.append(%x)" % ord(serReadChar))

                    if ord(serReadChar) > 127:
                        print("WARNING, Non ASCII: stdioSerGate.fromPulpQue.append(%d)" % ord(serReadChar))

            # Continues write attempt from write Queues to Serial (To Pulp's RX)

            while len(self.escSerGate.toPulpQue) >= 2:
                escCmd = self.escSerGate.toPulpQue.pop(0)
                escAddr = self.escSerGate.toPulpQue.pop(0)
                self.serPort.write(bytearray([escCmd]))
                self.serPort.write(escAddr.to_bytes(4, byteorder='big'))
                if (escCmd == SU_CMD_WR_WORD):
                    while len(self.escSerGate.toPulpQue) == 0:
                        pass
                    escWrData = self.escSerGate.toPulpQue.pop(0)

                    self.serPort.write(escWrData.to_bytes(4, byteorder='big'))

            while len(self.stdioSerGate.toPulpQue) > 0:
                stdioWrChar = self.stdioSerGate.toPulpQue.pop(0)
                self.serPort.write(bytearray([stdioWrChar]))

    # -------------------------------------------------------------------------------------

    def wr_mem_by_uart(self, addr, wdata):
        self.escSerGate.toPulpQue.append(SU_CMD_WR_WORD)
        self.escSerGate.toPulpQue.append(addr)
        self.escSerGate.toPulpQue.append(wdata)

        # -------------------------------------------------------------------------------------

    def rd_mem_by_uart(self, addr):

        self.escSerGate.toPulpQue.append(SU_CMD_RD_WORD)
        self.escSerGate.toPulpQue.append(addr)

        while len(self.escSerGate.fromPulpQue) == 0:  # iterate serGW till read data is back
            self.gwIterate(numItr=1)

        rdata = self.escSerGate.fromPulpQue.pop(0)

        return rdata

    # -------------------------------------------------------------------------------------

    def getSerChar(self):
        # poll till byte is available
        while (self.serPort.inWaiting() == 0):
            pass
        return self.serPort.read(1)

# -------------------------------------------------------------------------------
