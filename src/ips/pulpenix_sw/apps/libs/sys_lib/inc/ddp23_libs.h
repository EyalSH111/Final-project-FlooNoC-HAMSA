#ifndef __DDP23_LIBS_H__
#define __DDP23_LIBS_H__

#include <gpio.h>        // simple SOC gpio interface
#include <iosim.h>       // Simulated IO (basic terminal and file access)  over gpio interface
#include <bm_printf.h>   // bare-metal printf
#include <uart.h>
#include <rcg.h>
#include <hamsa_config.h>
#include <utils.h>
#include <cycle_count_access.h>
#include <ddr_lib.h>

#define printf bm_printf

#ifdef FPGA_EMUL
#define sim_finish bm_quit_app
#define sim_stop bm_quit_app
#endif

#endif