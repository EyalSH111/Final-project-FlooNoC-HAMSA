#ifndef _IO_CTRL_
#define _IO_CTRL_
#include <platform.h>
#define IO_CTRL_BASE (MIN_IO_CTRL)                         
void io_ctrl_set_pe(unsigned char pad, unsigned char pe);
void io_ctrl_set_ps(unsigned char pad, unsigned char ps);
void io_ctrl_set_drv(unsigned char pad, unsigned char drv);
void io_ctrl_set_force_ie(unsigned char pad, unsigned char force);
void io_ctrl_set_oen(unsigned char pad, unsigned char oen);
void io_ctrl_set_ie(unsigned char pad, unsigned char ie);

unsigned char io_ctrl_get_pe(unsigned char pad);
unsigned char io_ctrl_get_ps(unsigned char pad);
unsigned char io_ctrl_get_drv(unsigned char pad);
unsigned char io_ctrl_get_force_ie(unsigned char pad);
unsigned char io_ctrl_get_oen(unsigned char pad);
unsigned char io_ctrl_get_ie(unsigned char pad);
#endif
