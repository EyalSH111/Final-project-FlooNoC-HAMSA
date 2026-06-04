#include "edram_bist.h"
#include "address_map/headers/edram_ss_0.h"
#include "pnx_util.h"
#include "bm_printf.h"

//in order to support multiple instances of bist
//use bist_select_inst first
unsigned int base = MIN_L2_EDRAM_CTRL0;
void bist_select_inst(unsigned int i) {
    if (i==0)
        base = MIN_L2_EDRAM_CTRL0;
    else
        base = MIN_L2_EDRAM_CTRL1;
}

#define ENABLES_ADDR        (base+0x28)
#define BIST_CI_ADDR        (base+0x38)
#define BIST_PAL1_ADDR      (base+0x3c)
#define BIST_PAL2_ADDR      (base+0x40)
#define BIST_CFG_ADDR       (base+0x44)
#define BIST_STATUS_ADDR    (base+0x48)
#define BIST_EXTDATA0L_ADDR (base+0x54)
#define BIST_EXTDATA0H_ADDR (base+0x58)
#define BIST_EXTDATA1L_ADDR (base+0x5C)
#define BIST_EXTDATA1H_ADDR (base+0x60)
#define COMP_ADDR           (base+0x800)

void edram_bist_enable()  { wr_field(ENABLES_ADDR, 4, 1, 1); }
void edram_bist_disable() { wr_field(ENABLES_ADDR, 4, 1, 0); }

void edram_bist_set_p1(unsigned int i) { wr_field(BIST_PAL1_ADDR,  0,  3, i); }
void edram_bist_set_a1(unsigned int i) { wr_field(BIST_PAL1_ADDR,  3, 14, i); }
void edram_bist_set_l1(unsigned int i) { wr_field(BIST_PAL1_ADDR, 17, 14, i); }

void edram_bist_set_p2(unsigned int i) { wr_field(BIST_PAL2_ADDR,  0,  3, i); }
void edram_bist_set_a2(unsigned int i) { wr_field(BIST_PAL2_ADDR,  3, 14, i); }
void edram_bist_set_l2(unsigned int i) { wr_field(BIST_PAL2_ADDR, 17, 14, i); }


void edram_bist_set_ci(unsigned int i) { wr32(BIST_CI_ADDR, i); }
void edram_bist_set_extdata1(unsigned int hi, unsigned int lo) {
    wr32(BIST_EXTDATA0L_ADDR, lo);
    wr32(BIST_EXTDATA0H_ADDR, hi);
}
void edram_bist_set_extdata2(unsigned int hi, unsigned int lo) {
    wr32(BIST_EXTDATA1L_ADDR, lo);
    wr32(BIST_EXTDATA1H_ADDR, hi);
}

void edram_bist_set_cw(unsigned int i)   { wr_field(BIST_CFG_ADDR,  0, 5, i); }
void edram_bist_set_wmc(unsigned int i)  { wr_field(BIST_CFG_ADDR,  8, 3, i); }
void edram_bist_set_rmc(unsigned int i)  { wr_field(BIST_CFG_ADDR, 12, 3, i); }
void edram_bist_set_mem(unsigned int i)  { wr_field(BIST_CFG_ADDR, 16, 3, i); }
void edram_bist_set_lp(unsigned int i)   { wr_field(BIST_CFG_ADDR, 20, 2, i); }
void edram_bist_set_twop(unsigned int i) { wr_field(BIST_CFG_ADDR, 24, 1, i); }
void edram_bist_start()                  { wr_field(BIST_CFG_ADDR, 28, 1, 1); }
void edram_bist_reset()                  { wr_field(BIST_CFG_ADDR, 31, 1, 1); }

unsigned int edram_bist_state()          { return rd_field(BIST_STATUS_ADDR, 0, 4); };
unsigned int edram_bist_done()           { return rd_field(BIST_STATUS_ADDR, 5, 1); };
unsigned int edram_bist_passed()         { return rd_field(BIST_STATUS_ADDR, 6, 1); };

void edram_bist_wait_done() {
    while(!edram_bist_done());
}

unsigned int edram_bist_test() {
    int res = 0;

    for (int j=0; j<2; j++) {
        bist_select_inst(j);
        printf("start test %d/2 - rf offset: 0x%x\n",j+1, base);
    
        edram_bist_enable();
    
        edram_bist_set_p1(2); //checkerboard
        edram_bist_set_a1(0); //start=0
        edram_bist_set_l1(64-1); //num lines to test
    
        edram_bist_set_p2(5); //inverse checkerboard
        edram_bist_set_a2(64);
        edram_bist_set_l2(64-1);
    
        edram_bist_set_ci(0); // time from write to read
    
        edram_bist_set_cw(0);
        edram_bist_set_lp(0);
        edram_bist_set_twop(0);
        edram_bist_set_wmc(0);
        edram_bist_set_rmc(0);
        edram_bist_set_mem(0);
    
        edram_bist_set_extdata1(0x11111111,0x22222222);
        edram_bist_set_extdata2(0x33333333,0x44444444);
    
        edram_bist_start();
    
        edram_bist_wait_done();
    
        edram_bist_disable();
    
        int i;
        for (i=0; i<64; i++) {
            unsigned int a, b;
            a = rd32(COMP_ADDR+i*8);
            b = rd32(COMP_ADDR+i*8+4);
            printf("row %d : %08x %08x\n", i, a, b);
            res |= a;
            res |= b;
        }

    }

    return res;
}
