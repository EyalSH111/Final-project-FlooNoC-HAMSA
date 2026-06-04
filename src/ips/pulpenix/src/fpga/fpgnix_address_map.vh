`ifndef _FPGNIX_ADDRESS_MAP_
`define _FPGNIX_ADDRESS_MAP_


`define MIN_XCORE_IMEM                    32'h00000000
`define MAX_XCORE_IMEM                    32'h00027FFF // 160KB-1

`define MIN_XCORE_DMEM                    32'h00100000
`define MAX_XCORE_DMEM                    32'h0012FFFF // MIN_XCORE_DMEM + 192KB-1

`define MIN_XBOX_TCM_DMEM                 32'h00200000
`define MAX_XBOX_TCM_DMEM                 32'h0027FFFF

`define MIN_UART                          32'h1A100000
`define MAX_UART                          32'h1A100FFF

`define MIN_GPIO                          32'h1A101000
`define MAX_GPIO                          32'h1A101FFF

`define MIN_SPIM                          32'h1A102000
`define MAX_SPIM                          32'h1A102FFF

`define MIN_TIMER                         32'h1A103000
`define MAX_TIMER                         32'h1A103FFF

`define MIN_EVENT_UNIT                    32'h1A104000
`define MAX_EVENT_UNIT                    32'h1A104FFF

`define MIN_I2C                           32'h1A105000
`define MAX_I2C                           32'h1A105FFF

`define MIN_SOC_CTRL                      32'h1A107000
`define MAX_SOC_CTRL                      32'h1A107FFF

`define MIN_XCORE_DEBUG                   32'h1A110000
`define MAX_XCORE_DEBUG                   32'h1A117FFF

`define MIN_XCORE_IEDRAM_CTRL             32'h1A118000
`define MAX_XCORE_IEDRAM_CTRL             32'h1A119FFF

`define MIN_XCOER_DEDRAM_CTRL             32'h1A11A000
`define MAX_XCOER_DEDRAM_CTRL             32'h1A11BFFF

`define MIN_GPDMA                         32'h1A200000
`define MAX_GPDMA                         32'h1A2000FF

`define MIN_GP_RF                         32'h1A301000
`define MAX_GP_RF                         32'h1A301FFF

//these defines are for files that are in the filelist but not in the design
`define MIN_HAMSA_IMEM                    32'hF0000000
`define MIN_HAMSA_DMEM                    32'hF0100000
`define MIN_HAMSA_DEBUG                   32'hFA110000

`endif // _FPGNIX_ADDRESS_MAP_
