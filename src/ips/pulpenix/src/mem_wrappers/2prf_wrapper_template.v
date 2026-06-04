module MODULE_NAME_TEMPLATE
  #(
    parameter init_file = ""
  )(
    clk,
    we_i,
    wr_addr_i,
    wdata_i,
    re_i,
    rd_addr_i,
    ram_rdata_o,
    ram_ctrl
  );

    localparam DW          = DW_TEMPLATE ;
    localparam AW          = AW_TEMPLATE ;
    localparam TSMC_MUX    = TSMC_MUX_TEMPLATE ;

    input  logic            clk;
    input  logic [AW-1:0]   wr_addr_i;
    input  logic [DW-1:0]   wdata_i;
    output logic [DW-1:0]   ram_rdata_o;
    input  logic            we_i;
    input  logic            re_i;
    input  logic [AW-1:0]   rd_addr_i;

    input  logic [6:0]  ram_ctrl;

        TSMC_RAM_NAME_TEMPLATE
        I_sp_ram
        (
            .CLK    (clk),
            .WEB    (~we_i),
            .AA     (wr_addr_i),
            .D      (wdata_i),
            .REB    (~re_i),
            .AB     (rd_addr_i),
            .RTSEL  (ram_ctrl[1:0]),
            .WTSEL  (ram_ctrl[3:2]),
            .MTSEL  (ram_ctrl[5:4]),
            .Q      (ram_rdata_o)
        );


endmodule
