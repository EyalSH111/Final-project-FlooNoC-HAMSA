`ifndef _OPENOCD_JTAG_
`define _OPENOCD_JTAG_

interface OPENOCD_JTAG;
    logic srst;
    logic trst;

    logic tck;
    logic tms;
    logic tdi;
    logic tdo;

    logic led;
    logic quit;

modport master(
    output srst,
    output trst,

    output tck,
    output tms,
    output tdi,
    input  tdo,

    output led,
    output quit);

modport slave(
    input  srst,
    input  trst,

    input  tck,
    input  tms,
    input  tdi,
    output tdo,

    input  led,
    input  quit);

endinterface

`endif
