
// SMART UART Master's command codes

`define SU_CMD_MSN          4'h8             // Smart UART Most Significant nibble
`define SU_CMD_WR_WORD      {`SU_CMD_MSN,4'h0}   // followed by address and full word data    (+ 8 bytes)
`define SU_CMD_WR_HALFWORD  {`SU_CMD_MSN,4'h1}   // followed by address and half word data    (+ 6 bytes)
`define SU_CMD_WR_BYTE      {`SU_CMD_MSN,4'h2}   // followed by address and half byte data    (+ 5 bytes)
`define SU_CMD_RD_WORD      {`SU_CMD_MSN,4'h3}   // followed by address                       (+ 4 bytes)
`define SU_CMD_RD_NUMWORDS  {`SU_CMD_MSN,4'h4}   // followed by number (one byte) and address (+ 5 bytes)
`define SU_CMD_JTAG         {`SU_CMD_MSN,4'h5}   // followed by ascii character               (+ 1 byte)
`define SU_CMD_RSP          {`SU_CMD_MSN,4'h8}   // Response Indicator

