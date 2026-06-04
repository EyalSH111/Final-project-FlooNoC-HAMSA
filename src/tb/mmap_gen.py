import sys
import re

objdump = open(str(sys.argv[1]), 'r')
mmap = open(sys.argv[2], 'w')

mmap.write('simvision mmap new -name "Opcode" -contents {')

text = objdump.read()
i, c = 0, 0
while c < 10:
   line = re.search('\s{1,3}' + str(hex(i))[2:] + ':[^\n]*', text)
   if line != None:
      c = 0;
      pc, remaining = line.group().split(':', 1)
      op, instr = remaining.split('       ', 1)
      mmap.write('\n	{'+str(hex(i))[2:].zfill(8)+' -label "' + re.sub("\t", " ", instr)[4:] + '"}')
   else:
      c += 1;
   i += 4
mmap.write('}\n')

objdump.close()
mmap.close()
