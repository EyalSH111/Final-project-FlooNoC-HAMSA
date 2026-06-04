// sflash start
.org 0x80  //XCORE BOOT
   addi x1, x0, 0x80
   jalr x0, 0(x1)
.org 0x180 //HAMSA BOOT
   li   x1, 0x1ac00000
   addi x1, x1, 0x80
   jalr x0, 0(x1)
