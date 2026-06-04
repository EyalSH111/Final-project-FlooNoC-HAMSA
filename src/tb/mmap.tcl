simvision mmap new -name "Opcode" -contents {
	{00000000 -label "j 0 <IRQ0>"}
	{00000004 -label "j 4 <IRQ1>"}
	{00000008 -label "j 8 <IRQ2>"}
	{0000000c -label "j c <IRQ3>"}
	{00000010 -label "j 10 <IRQ4>"}
	{00000014 -label "j 14 <IRQ5>"}
	{00000018 -label "j 18 <IRQ6>"}
	{0000001c -label "j 1d8 <ISR_TA_CMP_ASM>"}
	{00000020 -label "j 20 <IRQ8>"}
	{00000024 -label "j 24 <IRQ9>"}
	{00000028 -label "j 28 <IRQ10>"}
	{0000002c -label "j 2c <IRQ11>"}
	{00000030 -label "j 30 <IRQ12>"}
	{00000034 -label "j 34 <IRQ13>"}
	{00000038 -label "j 38 <IRQ14>"}
	{0000003c -label "j 3c <IRQ15>"}
	{00000040 -label "j 160 <ISR_I2C_ASM>"}
	{00000044 -label "j 178 <ISR_UART_ASM>"}
	{00000048 -label "j 190 <ISR_GPIO_ASM>"}
	{0000004c -label "j 1a8 <ISR_SPIM0_ASM>"}
	{00000050 -label "j 1c0 <ISR_SPIM1_ASM>"}
	{00000054 -label "j 1f0 <ISR_TA_OVF_ASM>"}
	{00000058 -label "j 220 <ISR_TB_OVF_ASM>"}
	{0000005c -label "j 208 <ISR_TB_CMP_ASM>"}
	{00000060 -label "j 60 <IRQ24>"}
	{00000064 -label "j 64 <IRQ25>"}
	{00000068 -label "j 68 <IRQ26>"}
	{0000006c -label "j 6c <IRQ27>"}
	{00000070 -label "j 70 <IRQ28>"}
	{00000074 -label "j 74 <IRQ29>"}
	{00000078 -label "j 78 <IRQ30>"}
	{0000007c -label "j 7c <IRQ31>"}
	{00000080 -label "j 8c <_stext>"}
	{00000084 -label "j 238 <illegal_insn_handler>"}
	{00000088 -label "j 238 <illegal_insn_handler>"}
	{0000008c -label "csrwi 0x800,3"}
	{00000090 -label "li ra,0"}
	{00000094 -label "mv sp,ra"}
	{00000098 -label "mv gp,ra"}
	{0000009c -label "mv tp,ra"}
	{000000a0 -label "mv t0,ra"}
	{000000a4 -label "mv t1,ra"}
	{000000a8 -label "mv t2,ra"}
	{000000ac -label "mv s0,ra"}
	{000000b0 -label "mv s1,ra"}
	{000000b4 -label "mv a0,ra"}
	{000000b8 -label "mv a1,ra"}
	{000000bc -label "mv a2,ra"}
	{000000c0 -label "mv a3,ra"}
	{000000c4 -label "mv a4,ra"}
	{000000c8 -label "mv a5,ra"}
	{000000cc -label "mv a6,ra"}
	{000000d0 -label "mv a7,ra"}
	{000000d4 -label "mv s2,ra"}
	{000000d8 -label "mv s3,ra"}
	{000000dc -label "mv s4,ra"}
	{000000e0 -label "mv s5,ra"}
	{000000e4 -label "mv s6,ra"}
	{000000e8 -label "mv s7,ra"}
	{000000ec -label "mv s8,ra"}
	{000000f0 -label "mv s9,ra"}
	{000000f4 -label "mv s10,ra"}
	{000000f8 -label "mv s11,ra"}
	{000000fc -label "mv t3,ra"}
	{00000100 -label "mv t4,ra"}
	{00000104 -label "mv t5,ra"}
	{00000108 -label "mv t6,ra"}
	{0000010c -label "auipc sp,0x130"}
	{00000110 -label "addi sp,sp,-268 # 130000 <_stack_start>"}
	{00000114 -label "auipc s10,0x100"}
	{00000118 -label "addi s10,s10,888 # 10048c <_edata>"}
	{0000011c -label "auipc s11,0x100"}
	{00000120 -label "addi s11,s11,880 # 10048c <_edata>"}
	{00000124 -label "ble s11,s10,134 <zero_loop_end>"}
	{00000128 -label "sw zero,0(s10)"}
	{0000012c -label "addi s10,s10,4"}
	{00000130 -label "ble s10,s11,128 <zero_loop>"}
	{00000134 -label "jal ra,34c <__libc_init_array>"}
	{00000138 -label "li a0,0"}
	{0000013c -label "li a1,3"}
	{00000140 -label "jal ra,1210 <uart_set_cfg>"}
	{00000144 -label "jal ra,269c <init_pll_rcg>"}
	{00000148 -label "li a0,0"}
	{0000014c -label "li a1,0"}
	{00000150 -label "jal ra,ff0 <main>"}
	{00000154 -label "jal ra,2690 <sim_finish>"}
	{00000158 -label "jal ra,12bc <uart_wait_tx_done>"}
	{0000015c -label "jal ra,1334 <exit>"}
	{00000160 -label "addi sp,sp,-96"}
	{00000164 -label "sw ra,92(sp)"}
	{00000168 -label "jal ra,250 <store_regs>"}
	{0000016c -label "auipc ra,0x0"}
	{00000170 -label "addi ra,ra,348 # 2c8 <end_except>"}
	{00000174 -label "j 11ec <ISR_I2C>"}
	{00000178 -label "addi sp,sp,-96"}
	{0000017c -label "sw ra,92(sp)"}
	{00000180 -label "jal ra,250 <store_regs>"}
	{00000184 -label "auipc ra,0x0"}
	{00000188 -label "addi ra,ra,324 # 2c8 <end_except>"}
	{0000018c -label "j 11f0 <ISR_UART>"}
	{00000190 -label "addi sp,sp,-96"}
	{00000194 -label "sw ra,92(sp)"}
	{00000198 -label "jal ra,250 <store_regs>"}
	{0000019c -label "auipc ra,0x0"}
	{000001a0 -label "addi ra,ra,300 # 2c8 <end_except>"}
	{000001a4 -label "j 11f4 <ISR_GPIO>"}
	{000001a8 -label "addi sp,sp,-96"}
	{000001ac -label "sw ra,92(sp)"}
	{000001b0 -label "jal ra,250 <store_regs>"}
	{000001b4 -label "auipc ra,0x0"}
	{000001b8 -label "addi ra,ra,276 # 2c8 <end_except>"}
	{000001bc -label "j 11f8 <ISR_SPIM0>"}
	{000001c0 -label "addi sp,sp,-96"}
	{000001c4 -label "sw ra,92(sp)"}
	{000001c8 -label "jal ra,250 <store_regs>"}
	{000001cc -label "auipc ra,0x0"}
	{000001d0 -label "addi ra,ra,252 # 2c8 <end_except>"}
	{000001d4 -label "j 11fc <ISR_SPIM1>"}
	{000001d8 -label "addi sp,sp,-96"}
	{000001dc -label "sw ra,92(sp)"}
	{000001e0 -label "jal ra,250 <store_regs>"}
	{000001e4 -label "auipc ra,0x0"}
	{000001e8 -label "addi ra,ra,228 # 2c8 <end_except>"}
	{000001ec -label "j 1204 <ISR_TA_CMP>"}
	{000001f0 -label "addi sp,sp,-96"}
	{000001f4 -label "sw ra,92(sp)"}
	{000001f8 -label "jal ra,250 <store_regs>"}
	{000001fc -label "auipc ra,0x0"}
	{00000200 -label "addi ra,ra,204 # 2c8 <end_except>"}
	{00000204 -label "j 1200 <ISR_TA_OVF>"}
	{00000208 -label "addi sp,sp,-96"}
	{0000020c -label "sw ra,92(sp)"}
	{00000210 -label "jal ra,250 <store_regs>"}
	{00000214 -label "auipc ra,0x0"}
	{00000218 -label "addi ra,ra,180 # 2c8 <end_except>"}
	{0000021c -label "j 120c <ISR_TB_CMP>"}
	{00000220 -label "addi sp,sp,-96"}
	{00000224 -label "sw ra,92(sp)"}
	{00000228 -label "jal ra,250 <store_regs>"}
	{0000022c -label "auipc ra,0x0"}
	{00000230 -label "addi ra,ra,156 # 2c8 <end_except>"}
	{00000234 -label "j 1208 <ISR_TB_OVF>"}
	{00000238 -label "addi sp,sp,-96"}
	{0000023c -label "sw ra,92(sp)"}
	{00000240 -label "jal ra,250 <store_regs>"}
	{00000244 -label "auipc ra,0x0"}
	{00000248 -label "addi ra,ra,132 # 2c8 <end_except>"}
	{0000024c -label "j 10c0 <illegal_insn_handler_c>"}
	{00000250 -label "sw gp,0(sp)"}
	{00000254 -label "sw tp,4(sp)"}
	{00000258 -label "sw t0,8(sp)"}
	{0000025c -label "sw t1,12(sp)"}
	{00000260 -label "sw t2,16(sp)"}
	{00000264 -label "sw a0,20(sp)"}
	{00000268 -label "sw a1,24(sp)"}
	{0000026c -label "sw a2,28(sp)"}
	{00000270 -label "sw a3,32(sp)"}
	{00000274 -label "sw a4,36(sp)"}
	{00000278 -label "sw a5,40(sp)"}
	{0000027c -label "sw a6,44(sp)"}
	{00000280 -label "sw a7,48(sp)"}
	{00000284 -label "sw t3,52(sp)"}
	{00000288 -label "sw t4,56(sp)"}
	{0000028c -label "sw t5,60(sp)"}
	{00000290 -label "sw t6,64(sp)"}
	{00000294 -label "csrr t3,lpstart0"}
	{00000298 -label "csrr t4,lpend0"}
	{0000029c -label "csrr t5,lpcount0"}
	{000002a0 -label "sw t3,68(sp)"}
	{000002a4 -label "sw t4,72(sp)"}
	{000002a8 -label "sw t5,76(sp)"}
	{000002ac -label "csrr t3,lpstart1"}
	{000002b0 -label "csrr t4,lpend1"}
	{000002b4 -label "csrr t5,lpcount1"}
	{000002b8 -label "sw t3,80(sp)"}
	{000002bc -label "sw t4,84(sp)"}
	{000002c0 -label "sw t5,88(sp)"}
	{000002c4 -label "ret"}
	{000002c8 -label "lw t3,80(sp)"}
	{000002cc -label "lw t4,84(sp)"}
	{000002d0 -label "lw t5,88(sp)"}
	{000002d4 -label "csrw lpstart1,t3"}
	{000002d8 -label "csrw lpend1,t4"}
	{000002dc -label "csrw lpcount1,t5"}
	{000002e0 -label "lw t3,68(sp)"}
	{000002e4 -label "lw t4,72(sp)"}
	{000002e8 -label "lw t5,76(sp)"}
	{000002ec -label "csrw lpstart0,t3"}
	{000002f0 -label "csrw lpend0,t4"}
	{000002f4 -label "csrw lpcount0,t5"}
	{000002f8 -label "lw gp,0(sp)"}
	{000002fc -label "lw tp,4(sp)"}
	{00000300 -label "lw t0,8(sp)"}
	{00000304 -label "lw t1,12(sp)"}
	{00000308 -label "lw t2,16(sp)"}
	{0000030c -label "lw a0,20(sp)"}
	{00000310 -label "lw a1,24(sp)"}
	{00000314 -label "lw a2,28(sp)"}
	{00000318 -label "lw a3,32(sp)"}
	{0000031c -label "lw a4,36(sp)"}
	{00000320 -label "lw a5,40(sp)"}
	{00000324 -label "lw a6,44(sp)"}
	{00000328 -label "lw a7,48(sp)"}
	{0000032c -label "lw t3,52(sp)"}
	{00000330 -label "lw t4,56(sp)"}
	{00000334 -label "lw t5,60(sp)"}
	{00000338 -label "lw t6,64(sp)"}
	{0000033c -label "lw ra,92(sp)"}
	{00000340 -label "addi sp,sp,96"}
	{00000344 -label "mret"}
	{00000348 -label "ret"}
	{0000034c -label "      addi sp,sp,-16"}
	{00000350 -label "      sw s2,0(sp)"}
	{00000368 -label "      sw s1,4(sp)"}
	{00000378 -label "      lw a5,0(s0)"}
	{0000037c -label "      jalr a5"}
	{00000380 -label "bne s2,s1,378 <__libc_init_array+0x2c>"}
	{00000384 -label "      jal 348 <_fini>"}
	{000003a8 -label "      lw a5,0(s0)"}
	{000003ac -label "      jalr a5"}
	{000003b0 -label "bne s2,s1,3a8 <__libc_init_array+0x5c>"}
	{000003b4 -label "      lw ra,12(sp)"}
	{000003b8 -label "      lw s1,4(sp)"}
	{000003bc -label "      addi sp,sp,16"}
	{000003c0 -label "xor a5,a1,a0"}
	{000003c4 -label "      andi a5,a5,3"}
	{000003cc -label "      li a5,3"}
	{000003d8 -label "      bnez a4,42a <memcpy+0x6a>"}
	{000003e8 -label "      mv a4,a5"}
	{000003f0 -label "      addi a4,a4,4"}
	{000003f8 -label "bltu a4,a6,3ee <memcpy+0x2e>"}
	{000003fc -label "not a4,a5"}
	{00000400 -label "      add a6,a6,a4"}
	{00000408 -label "      add a5,a5,a6"}
	{0000040c -label "bltu a5,a7,418 <memcpy+0x58>"}
	{00000410 -label "      ret"}
	{00000414 -label "bleu a7,a0,410 <memcpy+0x50>"}
	{00000418 -label "lbu a4,0(a1)"}
	{0000041c -label "      addi a5,a5,1"}
	{00000424 -label "bltu a5,a7,418 <memcpy+0x58>"}
	{00000428 -label "      ret"}
	{00000430 -label "sb a4,-1(a5)"}
	{00000434 -label "andi a4,a5,3"}
	{00000438 -label "      addi a1,a1,1"}
	{0000043c -label "lbu a4,0(a1)"}
	{00000440 -label "      addi a5,a5,1"}
	{0000044c -label "      bnez a4,42a <memcpy+0x6a>"}
	{00000450 -label "lw t2,0(a1)"}
	{00000454 -label "lw t0,4(a1)"}
	{00000458 -label "lw t6,8(a1)"}
	{0000045c -label "lw t5,12(a1)"}
	{00000460 -label "lw t4,16(a1)"}
	{00000464 -label "lw t3,20(a1)"}
	{00000468 -label "lw t1,24(a1)"}
	{0000046c -label "      lw a2,28(a1)"}}
