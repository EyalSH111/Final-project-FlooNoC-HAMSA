#include <io_ctrl.h>
#include <pnx_util.h>

void io_ctrl_set_pe(unsigned char pad, unsigned char val)       { wr_field(IO_CTRL_BASE+0x4*pad, 0, 1, val); }
void io_ctrl_set_ps(unsigned char pad, unsigned char val)       { wr_field(IO_CTRL_BASE+0x4*pad, 1, 1, val); }

void io_ctrl_set_drv(unsigned char pad, unsigned char val)      { wr_field(IO_CTRL_BASE+0x4*pad, 2, 4, val); }
void io_ctrl_set_force_ie(unsigned char pad, unsigned char val) { wr_field(IO_CTRL_BASE+0x4*pad, 6, 1, val); }
void io_ctrl_set_oen(unsigned char pad, unsigned char val)      { wr_field(IO_CTRL_BASE+0x4*pad, 7, 1, val); }

void io_ctrl_set_ie(unsigned char pad, unsigned char val)       { wr_field(IO_CTRL_BASE+0x4*pad, 3, 1, val); }

unsigned char io_ctrl_get_pe(unsigned char pad)                 { return rd_field(IO_CTRL_BASE+0x4*pad, 0, 1); }
unsigned char io_ctrl_get_ps(unsigned char pad)                 { return rd_field(IO_CTRL_BASE+0x4*pad, 1, 1); }
unsigned char io_ctrl_get_drv(unsigned char pad)                { return rd_field(IO_CTRL_BASE+0x4*pad, 2, 4); }
unsigned char io_ctrl_get_force_ie(unsigned char pad)           { return rd_field(IO_CTRL_BASE+0x4*pad, 6, 1); }
unsigned char io_ctrl_get_oen(unsigned char pad)                { return rd_field(IO_CTRL_BASE+0x4*pad, 7, 1); }
unsigned char io_ctrl_get_ie(unsigned char pad)                 { return rd_field(IO_CTRL_BASE+0x4*pad, 3, 1); }
