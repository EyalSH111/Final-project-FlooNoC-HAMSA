// boot_preload    
.org 0x80
    lui	 a5, 0x1a840              // Flash instruction base addr
    addi a4, x0, 0                // IMEM base addr
  
    // get size of instruction to copy
    lui	 a6, 0x1a800
    lw	 a2, 0(a6)
    add  a3, a5, a2
    I_MEM_LOOP:                   // copy instructions
    lw	 a6, 0(a5)
    lw	 a0, 4(a5)
    lw	 a1, 8(a5)
    lw	 a2, 12(a5)
    sw	 a6, 0(a4)
    sw	 a0, 4(a4)
    sw	 a1, 8(a4)
    sw	 a2, 12(a4)
    addi a5, a5, 16
    addi a4, a4, 16
    blt	 a5, a3, I_MEM_LOOP
    
    lui	 a5, 0x1a880              // Flash data base addr
    lui  a4, 0x100                 // DMEM base addr
    
    // get size of instruction to copy
    lui	 a6, 0x1a800
    lw	 a2, 4(a6)
    add  a3, a5, a2
    D_MEM_LOOP:                   // copy data
    lw	 a6, 0(a5)
    lw	 a0, 4(a5)
    lw	 a1, 8(a5)
    lw	 a2, 12(a5)
    sw	 a6, 0(a4)
    sw	 a0, 4(a4)
    sw	 a1, 8(a4)
    sw	 a2, 12(a4)
    addi a5, a5, 16
    addi a4, a4, 16
    blt	 a5, a3, D_MEM_LOOP

    // go to start point at IMEM
    addi x1, x0, 0x80              
    jalr x0, 0(x1)
