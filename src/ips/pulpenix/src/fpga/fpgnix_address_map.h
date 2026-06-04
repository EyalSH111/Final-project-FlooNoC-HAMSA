// this file was auto generated with gen_h.py


#ifndef _SANSA_ADDRESS_MAP_
#define _SANSA_ADDRESS_MAP_


#define MIN_XCORE_IMEM                    0x00000000
#define MAX_XCORE_IMEM                    0x00027FFF // 160KB-1

#define MIN_XCORE_DMEM                    0x00100000
#define MAX_XCORE_DMEM                    0x0012FFFF // MIN_XCORE_DMEM + 192KB-1

#define MIN_UART                          0x1A100000
#define MAX_UART                          0x1A100FFF

#define MIN_GPIO                          0x1A101000
#define MAX_GPIO                          0x1A101FFF

#define MIN_SPIM                          0x1A102000
#define MAX_SPIM                          0x1A102FFF

#define MIN_TIMER                         0x1A103000
#define MAX_TIMER                         0x1A103FFF

#define MIN_EVENT_UNIT                    0x1A104000
#define MAX_EVENT_UNIT                    0x1A104FFF

#define MIN_I2C                           0x1A105000
#define MAX_I2C                           0x1A105FFF

#define MIN_SOC_CTRL                      0x1A107000
#define MAX_SOC_CTRL                      0x1A107FFF

#define MIN_XCORE_DEBUG                   0x1A110000
#define MAX_XCORE_DEBUG                   0x1A117FFF

#define MIN_XCORE_IEDRAM_CTRL             0x1A118000
#define MAX_XCORE_IEDRAM_CTRL             0x1A119FFF

#define MIN_XCOER_DEDRAM_CTRL             0x1A11A000
#define MAX_XCOER_DEDRAM_CTRL             0x1A11BFFF

#define MIN_GPDMA                         0x1A200000
#define MAX_GPDMA                         0x1A2000FF

#define MIN_GP_RF                         0x1A301000
#define MAX_GP_RF                         0x1A301FFF

#define MIN_STXFY                         0x1A302000
#define MAX_STXFY                         0x1A3020FF

#define MIN_HIST_TOP                      0x1A302100
#define MAX_HIST_TOP                      0x1A3021FF

#define MIN_HAMSA_DEBUG                   0x1A303000
#define MAX_HAMSA_DEBUG                   0x1A303FFF

#define MIN_IO_CTRL                       0x1A304000
#define MAX_IO_CTRL                       0x1A304FFF

#define MIN_L2_EDRAM_CTRL0                0x1A308000
#define MAX_L2_EDRAM_CTRL0                0x1A308FFF

#define MIN_L2_EDRAM_CTRL1                0x1A309000
#define MAX_L2_EDRAM_CTRL1                0x1A309FFF

#define MIN_ANN                           0x1A30A000
#define MAX_ANN                           0x1A30BFFF

#define MIN_PIXEL_PROC                    0x1A30C000
#define MAX_PIXEL_PROC                    0x1A30FFFF

#define MIN_MMSPI                         0x1A800000
#define MAX_MMSPI                         0x1ABFFFFF

#define MIN_HAMSA_IMEM                    0x1AC00000
#define MAX_HAMSA_IMEM                    0x1AC0FFFF

#define MIN_HAMSA_DMEM                    0x1AD00000
#define MAX_HAMSA_DMEM                    0x1AD0FFFF

#define MIN_L2_MEM                        0x1AE00000
#define MAX_L2_MEM                        0x1AE3FFFF

#endif // _SANSA_ADDRESS_MAP_
