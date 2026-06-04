// Copyright 2016 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

#include "pulpino.h"

#define EXCEPTION_STACK_SIZE 96


/* ========================================================= [ entry ] === */
  .section .text

reset_handler:
#ifdef ICACHE_ON    //2  
 #ifdef DCACHE_ON   //1
  #ifdef DI_ON      //0
   csrrwi x0, 2048, 7
  #else
   csrrwi x0, 2048, 6
  #endif
 #else
  #ifdef DI_ON      //0
   csrrwi x0, 2048, 5
  #else
   csrrwi x0, 2048, 4
  #endif
 #endif
#else
 #ifdef DCACHE_ON   //1
  #ifdef DI_ON      //0
   csrrwi x0, 2048, 3
  #else
   csrrwi x0, 2048, 2
  #endif
 #else
  #ifdef DI_ON      //0
   csrrwi x0, 2048, 1
  #else
   csrrwi x0, 2048, 0
  #endif
 #endif
#endif
  /* set all registers to zero */
  mv  x1, x0
  mv  x2, x1
  mv  x3, x1
  mv  x4, x1
  mv  x5, x1
  mv  x6, x1
  mv  x7, x1
  mv  x8, x1
  mv  x9, x1
  mv x10, x1
  mv x11, x1
  mv x12, x1
  mv x13, x1
  mv x14, x1
  mv x15, x1
  mv x16, x1
  mv x17, x1
  mv x18, x1
  mv x19, x1
  mv x20, x1
  mv x21, x1
  mv x22, x1
  mv x23, x1
  mv x24, x1
  mv x25, x1
  mv x26, x1
  mv x27, x1
  mv x28, x1
  mv x29, x1
  mv x30, x1
  mv x31, x1

  /* stack initilization */
  la   x2, _stack_start


_start:
  .global _start

  /* clear BSS */
  la x26, _bss_start
  la x27, _bss_end

  bge x26, x27, zero_loop_end

zero_loop:
  sw x0, 0(x26)
  addi x26, x26, 4
  ble x26, x27, zero_loop
zero_loop_end:

  /* Run global initialization functions */
  call    __libc_init_array

main_entry:
  addi x10, x0, 0
  addi x11, x0, DFLT_UART_CLK
  jal uart_set_cfg
  jal init_pll_rcg

  /* jump to main program entry point (argc = argv = 0) */
  addi x10, x0, 0
  addi x11, x0, 0
  jal x1, main

  jal x1, sim_finish // FINISH SIMULATION - Added by Udi, Vslid only for simulation environment.

  jal  uart_wait_tx_done;

  /* if program exits call exit routine from library */
  jal  x1, exit


/* ========================================== [ I2C handler ] === */
ISR_I2C_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_I2C

/* ========================================== [ UART handler ] === */
ISR_UART_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_UART

/* ========================================== [ GPIO handler ] === */
ISR_GPIO_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_GPIO

/* ========================================== [ SPI Master end of transmission handler ] === */
ISR_SPIM0_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_SPIM0

/* ========================================== [ SPI Master recieve/transmit finish handler ] === */
ISR_SPIM1_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_SPIM1

/* ========================================== [ Timer A compare handler ] === */
ISR_TA_CMP_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_TA_CMP

/* ========================================== [ Timer A overflow handler ] === */
ISR_TA_OVF_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_TA_OVF

/* ========================================== [ Timer B Compare handler ] === */
ISR_TB_CMP_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_TB_CMP

/* ========================================== [ Timer B overflow handler ] === */
ISR_TB_OVF_ASM:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, ISR_TB_OVF

/* ================================= [ illegal instruction handler] === */
illegal_insn_handler:
  addi x2, x2, -EXCEPTION_STACK_SIZE
  sw x1, 0x5C(x2)
  jal x1, store_regs
  la x1, end_except
  jal x0, illegal_insn_handler_c


// saves all caller-saved registers (except return address)
store_regs:
  sw  x3, 0x00(x2)  // gp
  sw  x4, 0x04(x2)  // tp
  sw  x5, 0x08(x2)  // t0
  sw  x6, 0x0c(x2)  // t1
  sw  x7, 0x10(x2)  // t2
  sw x10, 0x14(x2)  // a0
  sw x11, 0x18(x2)  // a1
  sw x12, 0x1c(x2)  // a2
  sw x13, 0x20(x2)  // a3
  sw x14, 0x24(x2)  // a4
  sw x15, 0x28(x2)  // a5
  sw x16, 0x2c(x2)  // a6
  sw x17, 0x30(x2)  // a7
  sw x28, 0x34(x2)  // t3
  sw x29, 0x38(x2)  // t4
  sw x30, 0x3c(x2)  // t5
  sw x31, 0x40(x2)  // t6
  csrr x28, 0x7B0
  csrr x29, 0x7B1
  csrr x30, 0x7B2
  sw x28, 0x44(x2)  // lpstart[0]
  sw x29, 0x48(x2)  // lpend[0]
  sw x30, 0x4C(x2)  // lpcount[0]
  csrr x28, 0x7B4
  csrr x29, 0x7B5
  csrr x30, 0x7B6
  sw x28, 0x50(x2)  // lpstart[1]
  sw x29, 0x54(x2)  // lpend[1]
  sw x30, 0x58(x2)  // lpcount[1]
  jalr x0, x1

// load back registers from stack
end_except:
  lw x28, 0x50(x2)  // lpstart[1]
  lw x29, 0x54(x2)  // lpend[1]
  lw x30, 0x58(x2)  // lpcount[1]
  csrrw x0, 0x7B4, x28
  csrrw x0, 0x7B5, x29
  csrrw x0, 0x7B6, x30
  lw x28, 0x44(x2)  // lpstart[0]
  lw x29, 0x48(x2)  // lpend[0]
  lw x30, 0x4C(x2)  // lpcount[0]
  csrrw x0, 0x7B0, x28
  csrrw x0, 0x7B1, x29
  csrrw x0, 0x7B2, x30
  lw  x3, 0x00(x2)
  lw  x4, 0x04(x2)
  lw  x5, 0x08(x2)
  lw  x6, 0x0c(x2)
  lw  x7, 0x10(x2)
  lw x10, 0x14(x2)
  lw x11, 0x18(x2)
  lw x12, 0x1c(x2)
  lw x13, 0x20(x2)
  lw x14, 0x24(x2)
  lw x15, 0x28(x2)
  lw x16, 0x2c(x2)
  lw x17, 0x30(x2)
  lw x28, 0x34(x2)
  lw x29, 0x38(x2)
  lw x30, 0x3c(x2)
  lw x31, 0x40(x2)
  lw  x1, 0x5C(x2)
  addi x2, x2, EXCEPTION_STACK_SIZE
  # eret --- UNKNOWN OPCODE ????
  # ret
  mret

  .global _init
  .global _fini
_init:
_fini:
  # These don't have to do anything since we use init_array/fini_array.
  ret

/* =================================================== [ exceptions ] === */
/* This section has to be down here, since we have to disable rvc for it  */

  .section .vectors, "ax"
  .option norvc;

  // external interrupts are handled by the same callback
  // until compiler supports IRQ routines
  .org 0x00

  IRQ0:    j IRQ0 //(should never happen)
  IRQ1:    j IRQ1 //(should never happen)
  IRQ2:    j IRQ2 //(should never happen)
  IRQ3:    j IRQ3 //TODO: SW Int
  IRQ4:    j IRQ4 //(should never happen)
  IRQ5:    j IRQ5 //(should never happen)
  IRQ6:    j IRQ6 //(should never happen)
  IRQ7:    j ISR_TA_CMP_ASM
  IRQ8:    j IRQ8 //(should never happen)
  IRQ9:    j IRQ9 //(should never happen)
  IRQ10:   j IRQ10 //should never happen
  IRQ11:   j IRQ11 //TODO: External int
  IRQ12:   j IRQ12 //(should never happen)
  IRQ13:   j IRQ13 //(should never happen)
  IRQ14:   j IRQ14 //(should never happen)
  IRQ15:   j IRQ15 //(should never happen)

  IRQ16:   j ISR_I2C_ASM
  IRQ17:   j ISR_UART_ASM
  IRQ18:   j ISR_GPIO_ASM
  IRQ19:   j ISR_SPIM0_ASM
  IRQ20:   j ISR_SPIM1_ASM
  IRQ21:   j ISR_TA_OVF_ASM
  IRQ22:   j ISR_TB_OVF_ASM
  IRQ23:   j ISR_TB_CMP_ASM
  IRQ24:   j IRQ24 //TODO: GPP0
  IRQ25:   j IRQ25 //TODO: GPP1
  IRQ26:   j IRQ26 //TODO: GPP2
  IRQ27:   j IRQ27 //TODO: GPP3
  IRQ28:   j IRQ28 //TODO: GPP4
  IRQ29:   j IRQ29 //TODO: GPP5
  IRQ30:   j IRQ30 //TODO: GPP6
  IRQ31:   j IRQ31 //TODO: GPP7




  // reset vector
  .org 0x80
  jal x0, reset_handler

  // illegal instruction exception
  .org 0x84
  jal x0, illegal_insn_handler

  // ecall handler
  .org 0x88
  jal x0, illegal_insn_handler
