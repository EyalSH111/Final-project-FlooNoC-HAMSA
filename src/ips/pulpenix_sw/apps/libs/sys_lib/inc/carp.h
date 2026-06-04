#ifndef _CARP_H_
#define _CARP_H_

//these functions get the address of control register, assuming status is at addr+4

void          carp_init               (unsigned int addr);
void          carp_clock_select       (unsigned int addr, unsigned char clk_sel);
char          carp_get_selected_clock (unsigned int addr);
void          carp_set_divider        (unsigned int addr, unsigned char div_by);
unsigned char carp_get_divider        (unsigned int addr);
void          carp_goto_reset         (unsigned int addr);
void          carp_goto_active        (unsigned int addr);
void          carp_goto_sleep         (unsigned int addr);
unsigned char carp_get_state          (unsigned int addr);
void          carp_set_hw_req_mask    (unsigned int addr, unsigned char hw_req_mask);
unsigned char carp_get_hw_req_mask    (unsigned int addr);

void          carp_test               (unsigned int addr);

#endif
