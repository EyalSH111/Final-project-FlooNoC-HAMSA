import r2d2
import re

class OpenOCD_Bridge(r2d2.Bridge):
    def __init__(self, if_cpu, if_ocd, file_from_cpu=None, file_to_cpu=None):
        r2d2.Bridge.__init__(self, if_cpu, if_ocd, file_a2b=file_from_cpu, file_b2a=file_to_cpu, filter_a2b=None, filter_b2a=OpenOCD_Bridge.filter_ocd_to_cpu)

    def filter_ocd_to_cpu(b):
        a = b.decode()

        #remove led blinks
        a = re.sub('[bB]', '', a)
        
        #remove duplicates of normal characters (exluding R and my special characters)
        a = re.sub('(([01234567bBrstu].)\1+)', '\\1', a)
        
        #replace changes of tdi/tms while clock is low
        a = re.sub('[0123]([0123])', '\\1', a)

        a = re.sub('04', ')', a)
        a = re.sub('15', '!', a)
        a = re.sub('26', '@', a)
        a = re.sub('37', '#', a)
        a = re.sub('0R4', '$', a)
        a = re.sub('1R5', '%', a)
        a = re.sub('2R6', '^', a)
        a = re.sub('3R7', '&', a)

        b = a.encode()
        return b

