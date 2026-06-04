import re
import r2d2

class Sansa(r2d2.SoC):
    def __init__(self, command, *args):
        r2d2.SoC.__init__(self, command, *args)
        self.addr={}
        self.addr['MIN_XCORE_IMEM'] = 0x00000000
        self.addr['MAX_XCORE_IMEM'] = 0x0001FFFF
        self.addr['MIN_XCORE_DMEM'] = 0x00100000
        self.addr['MAX_XCORE_DMEM'] = 0x00117FFF
        self.addr['MIN_UART'] = 0x1A100000
        self.addr['MAX_UART'] = 0x1A100FFF
        self.addr['MIN_GPIO'] = 0x1A101000
        self.addr['MAX_GPIO'] = 0x1A101FFF
        self.addr['MIN_SPIM'] = 0x1A102000
        self.addr['MAX_SPIM'] = 0x1A102FFF
        self.addr['MIN_TIMER'] = 0x1A103000
        self.addr['MAX_TIMER'] = 0x1A103FFF
        self.addr['MIN_EVENT_UNIT'] = 0x1A104000
        self.addr['MAX_EVENT_UNIT'] = 0x1A104FFF
        self.addr['MIN_I2C'] = 0x1A105000
        self.addr['MAX_I2C'] = 0x1A105FFF
        self.addr['MIN_SOC_CTRL'] = 0x1A107000
        self.addr['MAX_SOC_CTRL'] = 0x1A107FFF
        self.addr['MIN_XCORE_DEBUG'] = 0x1A110000
        self.addr['MAX_XCORE_DEBUG'] = 0x1A117FFF
        self.addr['MIN_XCORE_IEDRAM_CTRL'] = 0x1A118000
        self.addr['MAX_XCORE_IEDRAM_CTRL'] = 0x1A119FFF
        self.addr['MIN_XCOER_DEDRAM_CTRL'] = 0x1A11A000
        self.addr['MAX_XCOER_DEDRAM_CTRL'] = 0x1A11BFFF
        self.addr['MIN_GPDMA'] = 0x1A200000
        self.addr['MAX_GPDMA'] = 0x1A2000FF
        self.addr['MIN_GP_RF'] = 0x1A301000
        self.addr['MAX_GP_RF'] = 0x1A301FFF
        self.addr['MIN_STXFY'] = 0x1A302000
        self.addr['MAX_STXFY'] = 0x1A3020FF
        self.addr['MIN_HIST_TOP'] = 0x1A302100
        self.addr['MAX_HIST_TOP'] = 0x1A3021FF
        self.addr['MIN_HAMSA_DEBUG'] = 0x1A303000
        self.addr['MAX_HAMSA_DEBUG'] = 0x1A303FFF
        self.addr['MIN_IO_CTRL'] = 0x1A304000
        self.addr['MAX_IO_CTRL'] = 0x1A304FFF
        self.addr['MIN_L2_EDRAM_CTRL0'] = 0x1A308000
        self.addr['MAX_L2_EDRAM_CTRL0'] = 0x1A308FFF
        self.addr['MIN_L2_EDRAM_CTRL1'] = 0x1A309000
        self.addr['MAX_L2_EDRAM_CTRL1'] = 0x1A309FFF
        self.addr['MIN_ANN'] = 0x1A30A000
        self.addr['MAX_ANN'] = 0x1A30BFFF
        self.addr['MIN_PIXEL_PROC'] = 0x1A30C000
        self.addr['MAX_PIXEL_PROC'] = 0x1A30FFFF
        self.addr['MIN_DOMV'] = 0x1A320000
        self.addr['MAX_DOMV'] = 0x1A33FFFF
        self.addr['MIN_MMSPI'] = 0x1A800000
        self.addr['MAX_MMSPI'] = 0x1ABFFFFF
        self.addr['MIN_HAMSA_IMEM'] = 0x1AC00000
        self.addr['MAX_HAMSA_IMEM'] = 0x1AC0FFFF
        self.addr['MIN_HAMSA_DMEM'] = 0x1AD00000
        self.addr['MAX_HAMSA_DMEM'] = 0x1AD0FFFF
        self.addr['MIN_L2_MEM'] = 0x1AE00000
        self.addr['MAX_L2_MEM'] = 0x1AE3FFFF

    def sanity(self):
        for min_key in [x for x in self.addr.keys() if 'MIN_' in x]:
            if 'MIN_IO_CTRL' == min_key: #skip due to Z failing simulation
                continue
            max_key = re.sub('MIN_', 'MAX_', min_key)
            addr = self.addr[min_key]
            print(min_key)
            for addr in range(self.addr[min_key], self.addr[max_key], ((self.addr[max_key]-self.addr[min_key])//40)*4):
                print(hex(addr), hex(self.read(addr)))

        #we assume endless.c is running which is busy-waiting for variable pointed by MIN_L2_MEM to become 0
        cond_addr = self.read(self.addr['MIN_L2_MEM'])
        #so this write is expected to end simulation
        print("Test done")
        print("cond_addr: ",hex(cond_addr))
        self.write(cond_addr, 0)


