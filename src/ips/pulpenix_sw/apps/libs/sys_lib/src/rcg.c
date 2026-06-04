#include <pnx_util.h>
#include <rcg.h>

#ifdef FPGNIX
void init_pll_rcg() { return; }
#endif
#include <platform.h>
#include <utils.h>
#include <carp.h>


#ifdef LEO_I
void init_pll_rcg() {

   // Remove PLL Fref bypass
   wr32(GP_RF_PLL_CTRL_REG_ADDR, 0xC1);

   // Check that PLL lock is set
   reg_poll(GP_RF_PLL_STATUS_REG_ADDR, 0x1, 0x1);

   // Remove PNX_CARP bypass
   carp_clock_select(PNX_CARP, 1);

   if (get_hart_id() != HAMSA_CORE) {
       //if not hamsa core - put hamsa to sleep
       carp_goto_sleep(HAMSA_CORE_CARP);
   } else {
       //if is hamsa core - remove HAMSA_CORE_CARP bypass
       carp_clock_select(HAMSA_CORE_CARP, 1);
   }
}

//void set_rcg_div(int reg, int div) {
//   
//   int rcg_reg_addr = TOP_RCG_CFG_BASE_ADDR + 0x0004*reg;
//   wr32(GP_RF_PLL_CTRL_REG_ADDR, 0xffe);
//   wr32(rcg_reg_addr, div);
//   wr32(TOP_RCG_CFG_TOP_RCG_DIV_GO_SET_REG_ADDR, 0x1);
//}

void set_pll_div(int fbdiv, int refdiv, int posdiv2, int posdiv1, long int frac) {
    int pll_en = 0xc1;
    int pll_bypass = 0xc2;
    int val;
    wr32(GP_RF_PLL_CTRL_REG_ADDR, pll_bypass); 

    val = (fbdiv << 16) + refdiv;
    wr32(GP_RF_PLL_MASTER_DIV_REG_ADDR, val);
    val = (posdiv2 << 16) + posdiv1;
    wr32(GP_RF_PLL_POST_DIV_REG_ADDR, val);
    wr32(GP_RF_PLL_FRAC_ADDR, frac);

    wr32(GP_RF_PLL_CTRL_REG_ADDR, pll_en);
}

void leo_set_rcg_pll_div(int div) {
   wr32(TOP_RCG_CFG_BASE_ADDR + 0x04 * 0, div);
   wr32(TOP_RCG_CFG_BASE_ADDR + 0x04 * 1, div);
   wr32(TOP_RCG_CFG_BASE_ADDR + 0x04 * 3, div);
   wr32(TOP_RCG_CFG_TOP_RCG_DIV_GO_SET_REG_ADDR, 0x1);
}
#endif


