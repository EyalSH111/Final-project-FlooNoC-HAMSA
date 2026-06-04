module sp_sram8192X32_bank_i
  #(
    parameter init_file = "",
    parameter MEM_MUX   = 8
    )(
      clk,
      en_i,
      addr_i,
      wdata_i,
      ram_rdata_o,
      we_i,
      be_i,
      ram_ctrl
      );

   localparam DW          = 32 ;
   localparam AW          = 13 ;
   localparam TSMC_MUX    = 16 ;

   input  logic            clk;
   input  logic            en_i;
   input  logic [AW-1:0]   addr_i;
   input  logic [DW-1:0]   wdata_i;
   output logic [DW-1:0]   ram_rdata_o;
   input  logic            we_i;
   input  logic [DW/8-1:0] be_i;

`ifdef TSMC16
   input  logic [3:0]      ram_ctrl;
`else
   input  logic [4:0]      ram_ctrl;
`endif

   logic [DW-1:0]          ben_expand;
   genvar                  i;
   for (i = 0; i < (DW/8) ; i = i + 1) begin
      always_comb begin
         ben_expand[i * 8 +: 8] = (be_i[i] & we_i) ? 8'h00 : 8'hFF;
      end
end

`ifdef TSMC16


   // localparam WT_SEL  = (TSMC_MUX == 2) ? 2'b01
   //                    : ((TSMC_MUX == 4)  ? ((2**AW > 1024) ? 2'b00 : 2'b01 )
   //                    : ((TSMC_MUX == 8)  ? ((2**AW > 2048) ? 2'b00 : 2'b01 )
   //                    : ((2**AW > 4096) ? 2'b00 : ((2**AW >= 2048) ? 2'b01 : (( DW > 32 ) ? 2'b11 : 2'b01 )))));

   // localparam RT_SEL  = 2'b01;

   generate
      case(MEM_MUX)
        2 : begin: mem_macro
          TS1N16FFCLLULVTA8192X32M2SW
          I_sp_ram (
                    .CLK   (clk),
                    .CEB   (~en_i),
                    .WEB   (~we_i),
                    .A     (addr_i),
                    .D     (wdata_i),
                    .BWEB  (ben_expand),
                    .RTSEL (ram_ctrl[1:0]),
                    .WTSEL (ram_ctrl[3:2]),
                    .Q     (ram_rdata_o)
                    );
        end
        8 : begin: mem_macro
          TS1N16FFCLLULVTA8192X32M8SW
          I_sp_ram (
                    .CLK   (clk),
                    .CEB   (~en_i),
                    .WEB   (~we_i),
                    .A     (addr_i),
                    .D     (wdata_i),
                    .BWEB  (ben_expand),
                    .RTSEL (ram_ctrl[1:0]),
                    .WTSEL (ram_ctrl[3:2]),
                    .Q     (ram_rdata_o)
                    );
        end
        16 : begin: mem_macro
          TS1N16FFCLLULVTA8192X32M16SW
          I_sp_ram (
                    .CLK   (clk),
                    .CEB   (~en_i),
                    .WEB   (~we_i),
                    .A     (addr_i),
                    .D     (wdata_i),
                    .BWEB  (ben_expand),
                    .RTSEL (ram_ctrl[1:0]),
                    .WTSEL (ram_ctrl[3:2]),
                    .Q     (ram_rdata_o)
                    );

        end
        default : begin: mem_macro
          TS1N16FFCLLULVTA8192X32M4SW
          I_sp_ram (
                    .CLK   (clk),
                    .CEB   (~en_i),
                    .WEB   (~we_i),
                    .A     (addr_i),
                    .D     (wdata_i),
                    .BWEB  (ben_expand),
                    .RTSEL (ram_ctrl[1:0]),
                    .WTSEL (ram_ctrl[3:2]),
                    .Q     (ram_rdata_o)
                    );
        end
      endcase // case (MEM_MUX))
   endgenerate

 `ifdef RTL_SIM
   localparam numWord     = 2**AW;
   localparam numWordAddr = AW;
   localparam numCMAddr   = $clog2(MEM_MUX);
   localparam numIOBit    = DW;
   localparam totalBit    = numWord*numIOBit;
   localparam totalBitAddr = $clog2(totalBit);
   localparam numIOBitAddr = $clog2(numIOBit);
   task preloadData;
      input [256*8:1] infile;  // Max 256 character File Name
      begin
         //MEM
         reg [numWordAddr-numCMAddr-1:0] mem_row;
         reg [numCMAddr-1:0]             mem_col;
         reg [numIOBitAddr-1:0]          mem_bit;

         //PRE
         reg [totalBit/32-1:0]           pre_row;
         reg [4:0]                       pre_bit;

         reg [totalBitAddr:0]            bit_idx;
         reg [31:0]                      PRELOAD [0:(numWord*numIOBit/32)-1];
         $readmemh(infile, PRELOAD);

         for (bit_idx = 0; bit_idx < totalBit; bit_idx = bit_idx + 1) begin
            {mem_row, mem_col, mem_bit} = bit_idx;
            {pre_row,          pre_bit} = bit_idx;
            mem_macro.I_sp_ram.MEMORY[mem_row][mem_col][mem_bit] = PRELOAD[pre_row][pre_bit];
         end
      end
   endtask
 `endif //  `ifdef RTL_SIM

endmodule

`else // !`ifdef TSMC16


ARM_SPSRAM_32X8192_M16_MEM
  I_sp_ram (
            .Q         (ram_rdata_o),
            .CLK       (clk),
            .CEN       (~en_i),
            .WEN       (ben_expand),
            .GWEN      (~we_i),
            .A         (addr_i),
            .D         (wdata_i),
            .CENY      (),
            .WENY      (),
            .GWENY     (),
            .AY        (),
            .SO        (),
            .EMA       (ram_ctrl[2:0]),
            .EMAW      (ram_ctrl[4:3]),
            .TEN       (1'b1),
            .TCEN      (1'b0),
            .TWEN      ('b0),
            .TGWEN     (1'b0),
            .TA        ('b0),
            .TD        ('b0),
            .RET1N     (1'b1),
            .SI        (2'b00),
            .SE        (1'b0),
            .DFTRAMBYP (1'b0)
            );
endmodule


`endif // !`ifdef TSMC16
