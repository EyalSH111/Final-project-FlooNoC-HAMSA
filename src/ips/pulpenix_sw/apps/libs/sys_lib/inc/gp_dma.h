#include <stdint.h>

// GPDMA
#define GPDMA__BASE              0x1A200000
#define GPDMA__SRC_ADD_0         GPDMA__BASE
#define GPDMA__DST_ADD_0         GPDMA__BASE + 0x4
#define GPDMA__TRANS_CTRL_0      GPDMA__BASE + 0X8
#define GPDMA__SRC_ADD_1         GPDMA__BASE + 0x40
#define GPDMA__DST_ADD_1         GPDMA__BASE + 0x44
#define GPDMA__TRANS_CTRL_1      GPDMA__BASE + 0x48

typedef struct {
   char     strt_stop;
   char     priority; // 26-28 , 0-higest
   char     dest_addr_mode; //0-increment , 2-Fixed
   char     src_addr_mode ; //0-increment , 2-Fixed
   char     burst_mode    ; // 0-4 byte , 1-8b , 2-16b;
   uint32_t trans_len     ; // bits 0-17
   uint32_t val;
} t_gp_dma_cfg;

void gp_dma_cfg_wr (t_gp_dma_cfg * dma_cfg);

void gp_dma_start (t_gp_dma_cfg * dma_cfg);
