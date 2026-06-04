`define C2A_DWFIFO_DW         37
//`define C2A_DWFIFO_PTRW       5
//`define C2A_DWFIFO_AFTHRS_LSB 2'b01
`define C2A_CWFIFO_DW         46
//`define C2A_CWFIFO_PTRW       5
//`define C2A_CWFIFO_AFTHRS_LSB 2'b01
`define C2A_RDFIFO_DW         33
//`define C2A_RDFIFO_PTRW       5
//`define C2A_RDFIFO_AFTHRS_LSB 2'b01
  
`define C2A_DWFIFO_WDATA_L  0
`define C2A_DWFIFO_WDATA_H  31
`define C2A_DWFIFO_BYTEN_L  32
`define C2A_DWFIFO_BYTEN_H  35
`define C2A_DWFIFO_LAST_C   36

`define C2A_CWFIFO_ADDR_L   0
`define C2A_CWFIFO_ADDR_H   31
`define C2A_CWFIFO_WCOUNT_L 32
`define C2A_CWFIFO_WCOUNT_H 40
`define C2A_CWFIFO_CMD_C    41
`define C2A_CWFIFO_LAST_C   42
`define C2A_CWFIFO_FIRST_C  43
`define C2A_CWFIFO_AMOD_L   44
`define C2A_CWFIFO_AMOD_H   45

`define C2A_RDFIFO_RDATA_L  0
`define C2A_RDFIFO_RDATA_H  31
`define C2A_RDFIFO_RLAST_C  32

`define C2A_FRAME_BITS     12
`define C2A_X_BITS         8
`define C2A_TOKEN_BITS     6
`define C2A_OUT_BITS       4
`define C2A_DELAY_BITS     3
`define C2A_CMD_CNT_BITS   12
`define C2A_INT_CNT_BITS   4
`define C2A_WAIT_BITS      12
`define C2A_TIMEOUT_BITS   10
`define C2A_WDT_BITS       11
`define C2A_CMD_BITS       7
`define C2A_ID_BITS        1

`define C2A_LEN_BITS       8
`define C2A_SIZE_BITS      3
 
`define C2A_ID_END_LINE    6
`define C2A_ID_LAST        3

//----------------------------------------------------------------------------
// Burst size encoding
//----------------------------------------------------------------------------
`define C2A_SIZE_4B        3'b010
`define C2A_LEN_16T        4'b1111

//----------------------------------------------------------------------------
// Burst type encoding
//----------------------------------------------------------------------------
`define C2A_FIXED          2'b00
`define C2A_INCR           2'b01
`define C2A_WRAP           2'b10

//----------------------------------------------------------------------------
// Atomic access encoding
//----------------------------------------------------------------------------
`define C2A_NORMAL         2'b00
`define C2A_EXCLUSIVE      2'b01
`define C2A_LOCKED         2'b10

//----------------------------------------------------------------------------
// Response signaling
//----------------------------------------------------------------------------
`define C2A_OKAY           2'b00
`define C2A_EXOKAY         2'b01
`define C2A_SLVERR         2'b10
`define C2A_DECERR         2'b11
