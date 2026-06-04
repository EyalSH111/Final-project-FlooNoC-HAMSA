// boot DMA
.org 0x80
    // ******************* configuring dma ***********************//
    lui	 a4, 0x1a200   // dma base addr
        
    // ******************* INSTR ***********************//
    // set source (flash instruction) - wr32(DMA_SOURCE, 0x1a840000)
    lui	 a1, 0x1a840
    addi a0, a4, 1024
    sw	 a1, 0(a0)
    
    // set destination (TCM imem) - wr32(DMA_DESTINATION, 0x0)
    lui	 a1, 0
    addi a0, a4, 1028
    sw	 a1, 0(a0)

    // get instruction len
    lui	 a6, 0x1a800
    lw	 a5, 0(a6)
    
    // ------- wfi config ------- //
    lui	 s0,0x1a104
    lui	 s1,0x1000
    sw	 s1,16(s0)   // EER = 0x1000000; set Event enable
    sw	 s1,0(s0)    // IER = 0x1000000; set Interrupt enable
    
    // ------- gp_dma_start (&dma_cfg) ------- //
    addi a1, a5, 2
    addi a0,a4,1032
    lui	 a2, 0x80000
    or   a1, a1, a2
    sw	 a1, 0(a0)
    
    // ------- set core to sleep mode --------//
    //SCR = 0x1;
    li	 a5, 1
    sw	 a5, 32(s0)
    wfi
    
    sw	 s1,12(s0)  // ICP = 0x1000000; Interupt clear
    sw	 s1,28(s0)  // ECP = 0x1000000; Event clear
    
    // ********************* DMEM ***********************//
     // set source (flash data) - wr32(DMA_SOURCE, 0x1a880000)
    lui	 a1, 0x1a880
    addi a0, a4, 1024
    sw	 a1, 0(a0)
    
    // set destination (TCM dmem) - wr32(DMA_DESTINATION, 0x100000)
    lui	 a1, 0x0100
    addi a0, a4, 1028
    sw	 a1, 0(a0)

   // get data len
    lui	 a6, 0x1a800
    lw	 a5, 4(a6)

    // ------- gp_dma_start (&dma_cfg) ------- //
    addi a1, a5, 1
    addi a0,a4,1032
    lui	 a2, 0x80000
    or  a1, a1, a2
    sw	 a1, 0(a0)

    // ------- set core to sleep mode --------//
    //SCR = 0x1;
    li	 a5, 1
    sw	 a5, 32(s0)
    wfi

    sw	 s1,12(s0)  // ICP = 0x1000000; Interrupt clear
    sw	 s1,28(s0)  // ECP = 0x1000000; Event clear
    
    // finish - jump to address 0x80 at IMEM (start executing the c code)
    addi x1, x0, 0x80
    jalr x0, 0(x1)
