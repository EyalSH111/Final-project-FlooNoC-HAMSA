#include <pnx_util.h>
#include <gp_dma.h>

void gp_dma_cfg_wr (t_gp_dma_cfg * dma_cfg) {
   
   int dma_cfg_val;

   dma_cfg_val =  (dma_cfg->priority << 26)  +
                  (dma_cfg->dest_addr_mode<<24) +
                  (dma_cfg->src_addr_mode<<22)  +
                  (dma_cfg->burst_mode<<20)     +
                  (dma_cfg->trans_len);

   dma_cfg->val = dma_cfg_val;

   wr32(GPDMA__TRANS_CTRL_0, dma_cfg_val);   

}

void gp_dma_start (t_gp_dma_cfg * dma_cfg) {
   
   wr32(GPDMA__TRANS_CTRL_0, dma_cfg->val | 0x80000000);

}


