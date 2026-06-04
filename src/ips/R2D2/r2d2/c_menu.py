import r2d2
import time

class CMenu(r2d2.Command):

    def __init__(self, interface, *args):
        r2d2.Command.__init__(self, interface, *args)

    def read(self, address, timeout=0):
        with self.ilock:
            cmd = 'r ' + hex(address)[2:] + '\n'
            cmd_e = cmd.encode('ascii')
            a = self.interface.gets(0)
            self.interface.puts(cmd_e)
            if timeout:
                temp = self.interface.gets_timed(32, timeout = timeout)
            else:
                temp = self.interface.gets(32)
            self.wait_for_ready(timeout=timeout, lock=False)
            temp_e = temp.decode('ascii').strip()
            return int(temp_e[-8:], 16)

    def write(self, address, value, timeout=0):
        with self.ilock:
            cmd = 'w ' + hex(address)[2:] + ' ' + hex(value)[2:] + '\n'
            cmd_e = cmd.encode('ascii')
            self.interface.puts(cmd_e)
            self.wait_for_ready(timeout=timeout, lock=False)

    def wait_for_ready(self, timeout=0, lock=True):
        if lock:
            self.ilock.acquire()

        x = ''
        while x[-7:] != 'Ready> ':
            if timeout:
                x += self.interface.gets_timed(1, timeout).decode('ascii')
            else:
                x += self.interface.gets(1).decode('ascii')

        if lock:
            self.ilock.release()

    def test(self):
        cmd = 'r 1f000000\n'
        self.interface.puts(cmd.encode('ascii'))
        time.sleep(1)
        print(self.interface.gets(10).decode('ascii'))

    def reset(self, timeout=0):
        with self.ilock:
            cmd = '~\n'
            cmd_e = cmd.encode('ascii')
            self.interface.puts(cmd_e)
            self.wait_for_ready(timeout=timeout, lock=False)

    def set_pll(self, value, timeout=0):
        with self.ilock:
            cmd = 'p ' + hex(value)[2:] + '\n'
            cmd_e = cmd.encode('ascii')
            self.interface.puts(cmd_e)
            self.wait_for_ready(timeout=timeout, lock=False)

    def send_raw(self, string, live_print=False, timeout=0, end='\n', lock=True):
        if lock:
            self.ilock.acquire()

        cmd_e = (string+end).encode('ascii')
        self.interface.puts(cmd_e)
        x = ''
        while x[-7:] != 'Ready> ':
            if timeout:
                c = self.interface.gets_timed(1,timeout).decode('ascii')
            else:
                c = self.interface.gets(1).decode('ascii')
            x += c
            if live_print:
                print(c,end='')
        a = self.interface.gets(0)

        if lock:
            self.ilock.release()

        return x

    def raw_action(self,string,func,live_print=False, timeout=0):
        with self.ilock:
            cmd_e = (string+'\n').encode('ascii')
            self.interface.puts(cmd_e)
            x = ''
            data=[]
            while x[-7:] != 'Ready> ':
                data+=func()
                if timeout:
                    c = self.interface.gets_timed(1,timeout).decode('ascii')
                else:
                    c = self.interface.gets(1).decode('ascii')
                x += c
                if live_print:
                    print(c,end='')
            return data

    def load_data(self,address,data,timeout=0):
        """

        :param address: int base address
        :param data: bytearray in big endian to put in memory using L
        :return:
        """
        with self.ilock:
            a=self.interface.gets(0)
            cmd_e = ('L '+hex(address)[2:]+' '+hex(len(data))[2:]+'\n').encode('ascii')
            self.interface.puts(cmd_e)
            self.interface.puts(data)
            self.wait_for_ready(timeout, lock=False)

    def unload_data(self, address, length,timeout=0):
        """
        parses mem dump to list of bytes
        :param address: start address
        :param length: data size
        :return: list of 32b from mem starting from address
        """
        with self.ilock:
            a = self.interface.gets(0)
            mem=self.send_raw('D ' + hex(address)[2:] + ' ' + hex(length)[2:],timeout=timeout, lock=False)
            mem=mem.split(' ')
            mem=[int(x.strip(' '),16) for x in mem if '0x' in x]
            return mem
