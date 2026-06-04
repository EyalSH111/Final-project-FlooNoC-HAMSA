// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/**
 * @file
 * @brief Register mapping for PULPino peripherals.
 *
 * Contains event register mappings for the PULPino SOC as
 * well as some general definitions for the overall system.
 *
 * @author Florian Zaruba
 *
 * @version 1.0
 *
 * @date 2/10/2015
 *
 */
#ifndef PULPINO_H
#define PULPINO_H
#include <address_map.h>
#define PULPINO_BASE_ADDR             0x10000000

/** SOC PERIPHERALS */
#define SOC_PERIPHERALS_BASE_ADDR     ( PULPINO_BASE_ADDR + 0xA100000 )

#define UART_BASE_ADDR                ( MIN_UART       )
#define GPIO_BASE_ADDR                ( MIN_GPIO       )
#define SPI_BASE_ADDR                 ( MIN_SPIM       )
#define TIMER_BASE_ADDR               ( MIN_TIMER      )
#define EVENT_UNIT_BASE_ADDR          ( MIN_EVENT_UNIT )
#define I2C_BASE_ADDR                 ( MIN_I2C        )
//#define FLL_BASE_ADDR                 ( SOC_PERIPHERALS_BASE_ADDR + 0x6000 )
#define SOC_CTRL_BASE_ADDR            ( MIN_SOC_CTRL   )

/** STDOUT */
#define STDOUT_BASE_ADDR              ( SOC_PERIPHERALS_BASE_ADDR + 0x10000 )
#define FPUTCHAR_BASE_ADDR            ( STDOUT_BASE_ADDR + 0x1000 )
#define FILE_CMD_BASE_ADDR            ( STDOUT_BASE_ADDR + 0x2000 )
#define STREAM_BASE_ADDR              ( STDOUT_BASE_ADDR + 0x3000 )

/** Instruction RAM */
#define INSTR_RAM_BASE_ADDR           ( 0x00       )
#define INSTR_RAM_START_ADDR          ( 0x80       )

/** ROM */
#define ROM_BASE_ADDR                 ( 0x8000     )

/** Data RAM */
#define DATA_RAM_BASE_ADDR            ( 0x00100000 )

/** Registers and pointers */
#define REGP(x) ((volatile unsigned int*)(x))
#define REG(x) (*((volatile unsigned int*)(x)))
#define REGP_8(x) (((volatile uint8_t*)(x)))

/* pointer to mem of apb pulpino unit - PointerSocCtrl */
#define __PSC__(a) *(unsigned volatile int*) (SOC_CTRL_BASE_ADDR + a)

/** Peripheral Clock gating */
#define CGREG __PSC__(0x04)

/** Clock gate SPI */
#define CGSPI     0x00
/** Clock gate UART */
#define CGUART    0x01
/** Clock gate GPIO */
#define CGGPIO    0x02
/** Clock gate SPI Master */
#define CGGSPIM   0x03
/** Clock gate Timer */
#define CGTIM     0x04
/** Clock gate Event Unit */
#define CGEVENT   0x05
/** Clock gate I2C */
#define CGGI2C    0x06
/** Clock gate FLL */
#define CGFLL     0x07

/** Boot address register */
#define BOOTREG     __PSC__(0x08)

#define RES_STATUS  __PSC__(0x14)


#define DFLT_NS_PER_BIT ((1000000000)/BAUD_RATE)           // Notice BAUD_RATE is defined at compile make/command
#define DFLT_UART_CLK (((DFLT_NS_PER_BIT/CLK_PERIOD))-1)   // Notice CLK_PERIOD is defined at compile make/command



#endif
