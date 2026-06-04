#include "carp.h"
#include "pnx_util.h"

#define CTRL_DIV_BY_LSB         (0)
#define CTRL_DIV_BY_WIDTH       (10)
#define CTRL_DIV_BY_UPDATE_BIT  (10)
#define CTRL_CLK_SEL_BIT        (11)
#define CTRL_STATE_LSB          (12)
#define CTRL_STATE_WIDTH        (3)
#define CTRL_MASK_HW_REQ_LSB    (15)
#define CTRL_MASK_HW_REQ_WIDTH  (2)
#define STAT_STATE_LSB          (0)
#define STAT_STATE_WIDTH        (4)
#define STAT_DIV_BY_UPDATED_BIT (4)
#define STAT_CLK0_SELECTED_BIT  (5)
#define STAT_CLK1_SELECTED_BIT  (6)

#define CTRL (addr+0x0)
#define STAT (addr+0x4)


void carp_clock_select(unsigned int addr, unsigned char clk_sel) {
    wr_bit(CTRL, CTRL_CLK_SEL_BIT, clk_sel);
    //wait for update
    while (carp_get_selected_clock(addr)!=clk_sel);

}

char carp_get_selected_clock(unsigned int addr) {
    if (rd_bit(STAT, STAT_CLK0_SELECTED_BIT))
        return 0;

    if (rd_bit(STAT, STAT_CLK1_SELECTED_BIT))
        return 1;

    //called while no clock selected
    return -1;
}


char carp_get_div_by_updated(unsigned int addr) {
    return rd_bit(addr+4, STAT_DIV_BY_UPDATED_BIT);
}

void carp_set_div_by_update(unsigned int addr, char val) {
    wr_bit(addr, CTRL_DIV_BY_UPDATE_BIT, val);

    //wait for update
    while (carp_get_div_by_updated(addr)!=val);
}

void carp_set_divider(unsigned int addr, unsigned char div_by) {
    carp_set_div_by_update(addr, 0);

    wr_field(addr, CTRL_DIV_BY_LSB, CTRL_DIV_BY_WIDTH, div_by);

    carp_set_div_by_update(addr, 1);

    carp_set_div_by_update(addr, 0);
}

unsigned char carp_get_divider(unsigned int addr) {
    return rd_field(CTRL, CTRL_DIV_BY_LSB, CTRL_DIV_BY_WIDTH);
}

unsigned char carp_get_state(unsigned int addr) {
    return rd_field(STAT, STAT_STATE_LSB, STAT_STATE_WIDTH);
}

unsigned char carp_is_in_reset_state(unsigned int addr) {
    return (carp_get_state(addr)==0x0);
}

void carp_goto_reset(unsigned int addr) {
    wr_field(CTRL, CTRL_STATE_LSB, CTRL_STATE_WIDTH, 0x1);
    while (!carp_is_in_reset_state(addr));
}

unsigned char carp_is_in_active_state(unsigned int addr) {
    return (carp_get_state(addr)==0x7);
}

void carp_goto_active (unsigned int addr) {
    wr_field(CTRL, CTRL_STATE_LSB, CTRL_STATE_WIDTH, 0x2);
    while (!carp_is_in_active_state(addr));
}

unsigned char carp_is_in_sleep_state(unsigned int addr) {
    return (carp_get_state(addr)==0xd);
}

void carp_goto_sleep (unsigned int addr) {
    wr_field(CTRL, CTRL_STATE_LSB, CTRL_STATE_WIDTH, 0x4);
    if (!carp_is_in_reset_state(addr)) //no transition from reset-->sleep
        while (!carp_is_in_sleep_state(addr));
}

void carp_set_hw_req_mask(unsigned int addr, unsigned char hw_req_mask) {
    wr_field(CTRL, CTRL_MASK_HW_REQ_LSB, CTRL_MASK_HW_REQ_WIDTH, hw_req_mask);
}

unsigned char carp_get_hw_req_mask(unsigned int addr) {
    return rd_field(CTRL, CTRL_MASK_HW_REQ_LSB, CTRL_MASK_HW_REQ_WIDTH);
}

// // // //

void carp_test(unsigned int addr) {
    unsigned int i,j;
    for (i=0; i<3; i++) {
        carp_clock_select(addr, i%2);

        for (j=0; j<3; j++) {
            carp_set_divider(addr, 1+j*3);

            carp_goto_reset(addr);
            carp_goto_active(addr);
            carp_goto_sleep(addr);
            carp_goto_active(addr);
            carp_goto_sleep(addr);
            carp_goto_reset(addr);
            carp_goto_sleep(addr);//reset to sleep does nothing

        }

    }
}
