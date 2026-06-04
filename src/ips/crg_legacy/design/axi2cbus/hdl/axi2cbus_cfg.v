`define A2C_DWFIFO_DW         37
//`define A2C_DWFIFO_PTRW       10 //5
//`define A2C_DWFIFO_AFTHRS_LSB 2'b01
`define A2C_CWFIFO_DW         53
//`define A2C_CWFIFO_PTRW       5
//`define A2C_CWFIFO_AFTHRS_LSB 2'b01
`define A2C_RDFIFO_DW         41
//`define A2C_RDFIFO_PTRW       10 //5
//`define A2C_RDFIFO_AFTHRS_LSB 2'b01
  
`define A2C_DWFIFO_WDATA_L  0
`define A2C_DWFIFO_WDATA_H  31
`define A2C_DWFIFO_WSTRB_L  32
`define A2C_DWFIFO_WSTRB_H  35
`define A2C_DWFIFO_WLAST_C  36

`define A2C_CWFIFO_ADDR_L   0
`define A2C_CWFIFO_ADDR_H   31
`define A2C_CWFIFO_AXLEN_L  32
`define A2C_CWFIFO_AXLEN_H  39
`define A2C_CWFIFO_AXBRST_L 40
`define A2C_CWFIFO_AXBRST_H 41
`define A2C_CWFIFO_WSTRB_L  42
`define A2C_CWFIFO_WSTRB_H  45
`define A2C_CWFIFO_RWN_C    46
`define A2C_CWFIFO_ID_L     47
`define A2C_CWFIFO_ID_H     51
`define A2C_CWFIFO_USER_C   52

`define A2C_ID_DW           5

`define A2C_RDFIFO_RDATA_L  0
`define A2C_RDFIFO_RDATA_H  31
`define A2C_RDFIFO_RRESP_L  32
`define A2C_RDFIFO_RRESP_H  33
`define A2C_RDFIFO_RLAST_C  34
`define A2C_RDFIFO_ID_L     35
`define A2C_RDFIFO_ID_H     39
`define A2C_RDFIFO_USER_C   40

`define A2C_FRAME_BITS     12
`define A2C_X_BITS         8
`define A2C_TOKEN_BITS     6
`define A2C_OUT_BITS       4
`define A2C_DELAY_BITS     3
`define A2C_CMD_CNT_BITS   12
`define A2C_INT_CNT_BITS   4
`define A2C_WAIT_BITS      12
`define A2C_TIMEOUT_BITS   10
`define A2C_WDT_BITS       11
`define A2C_CMD_BITS       7
`define A2C_ID_BITS        5

`define A2C_LEN_BITS       8
`define A2C_SIZE_BITS      3
 
`define A2C_ID_END_LINE    6
`define A2C_ID_LAST        3

//----------------------------------------------------------------------------
// Burst size encoding
//----------------------------------------------------------------------------
`define A2C_SIZE_4B        3'b010
`define A2C_LEN_16T        4'b1111

//----------------------------------------------------------------------------
// Burst type encoding
//----------------------------------------------------------------------------
`define A2C_FIXED          2'b00
`define A2C_INCR           2'b01
`define A2C_WRAP           2'b10

//----------------------------------------------------------------------------
// Atomic access encoding
//----------------------------------------------------------------------------
`define A2C_NORMAL         2'b00
`define A2C_EXCLUSIVE      2'b01
`define A2C_LOCKED         2'b10

//----------------------------------------------------------------------------
// Response signaling
//----------------------------------------------------------------------------
`define A2C_OKAY           2'b00
`define A2C_EXOKAY         2'b01
`define A2C_SLVERR         2'b10
`define A2C_DECERR         2'b11
