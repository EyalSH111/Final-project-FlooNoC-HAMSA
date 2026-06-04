module sp_sram2048X128_wbp_bank_i
  #(
    parameter MEM_MUX   = 4,
    parameter init_file = ""
  )(
    clk,
    en_i,
    addr_i,
    wdata_i,
    ram_rdata_o,
    we_i,
    be_i,
    ram_ctrl,
    narrow_access_i
  );

    localparam DW          = 128 ;
    localparam AW          = 11 ;
    localparam TSMC_MUX    = 4 ;

    input  logic            clk;
    input  logic            en_i;
    input  logic [AW+1:0]   addr_i; //Additional 2 bits in order to take the memory selector into account
    input  logic [DW-1:0]   wdata_i;
    output logic [DW-1:0]   ram_rdata_o;
    input  logic            we_i;
    input  logic [DW/8-1:0] be_i;
    input logic             narrow_access_i;

`ifdef TSMC16
   input  logic [3:0]  ram_ctrl; // TODO
`else
   input  logic [5:0]  ram_ctrl;
`endif

`ifdef TSMC16
     
    logic [1:0]      sel, sel_d;
    logic [32/8-1:0] en; 
    logic [AW-1:0]   addr;

    genvar i, j;
    generate        
        for(i = 0; i < 4; i = i+1) begin: mem_i
            logic [31:0] wdata, rdata;
            logic [3:0]  be;
            logic [32-1:0] ben_expand;
            
            assign wdata = (!narrow_access_i)? wdata_i[(i + 1) * 32 - 1:i * 32]: wdata_i[31:0];
            assign be    = (!narrow_access_i)? be_i[(i + 1) * 4 - 1:i * 4]     : be_i[3:0];
            for (j = 0; j < (32/8) ; j = j + 1)
                always_comb ben_expand[j * 8 +: 8] = (be[j] & we_i) ? 8'h00 : 8'hFF;
            
                case(MEM_MUX)
                    4 : begin: mem_macro
                        TS1N16FFCLLULVTA2048X32M4SW I_sp_ram
                        ( 
                             .CLK    ( clk           ), 
                             .CEB    ( ~en[i]        ), 
                             .WEB    ( ~we_i         ),
                             .A      ( addr          ), 
                             .D      ( wdata         ),
                             .BWEB   ( ben_expand    ),
                             .RTSEL  ( ram_ctrl[1:0] ),
                             .WTSEL  ( ram_ctrl[3:2] ),
                             .Q      ( rdata         )
                         );
                     end
                     8 : begin: mem_macro
                        TS1N16FFCLLULVTA2048X32M8SW I_sp_ram
                        ( 
                             .CLK    ( clk           ), 
                             .CEB    ( ~en[i]        ), 
                             .WEB    ( ~we_i         ),
                             .A      ( addr          ), 
                             .D      ( wdata         ),
                             .BWEB   ( ben_expand    ),
                             .RTSEL  ( ram_ctrl[1:0] ),
                             .WTSEL  ( ram_ctrl[3:2] ),
                             .Q      ( rdata         )
                         );
                     end
                     16 : begin: mem_macro
                        TS1N16FFCLLULVTA2048X32M16SW I_sp_ram
                        ( 
                             .CLK    ( clk           ), 
                             .CEB    ( ~en[i]        ), 
                             .WEB    ( ~we_i         ),
                             .A      ( addr          ), 
                             .D      ( wdata         ),
                             .BWEB   ( ben_expand    ),
                             .RTSEL  ( ram_ctrl[1:0] ),
                             .WTSEL  ( ram_ctrl[3:2] ),
                             .Q      ( rdata         )
                         );
                     end
                     default : begin: mem_macro
                        TS1N16FFCLLULVTA2048X32M4SW I_sp_ram
                        ( 
                             .CLK    ( clk           ), 
                             .CEB    ( ~en[i]        ), 
                             .WEB    ( ~we_i         ),
                             .A      ( addr          ), 
                             .D      ( wdata         ),
                             .BWEB   ( ben_expand    ),
                             .RTSEL  ( ram_ctrl[1:0] ),
                             .WTSEL  ( ram_ctrl[3:2] ),
                             .Q      ( rdata         )
                         );
                     end
                 endcase
        end
    endgenerate
           
    assign {addr, sel} = addr_i;
    //assign addr        = {addr_i[AW-1:2], 2'b0};
    //assign sel         = addr_i[1:0];
    assign en          = (!narrow_access_i)? {4{en_i}} : {sel == 3, sel == 2, sel == 1, sel == 0} & {4{en_i}};  // if 32b, onlt one bit can be set
    assign ram_rdata_o = (!narrow_access_i)? {mem_i[3].rdata, mem_i[2].rdata, mem_i[1].rdata, mem_i[0].rdata}: 
                                             (sel_d == 0)? {96'b0, mem_i[0].rdata}:
                                             (sel_d == 1)? {96'b0, mem_i[1].rdata}:
                                             (sel_d == 2)? {96'b0, mem_i[2].rdata}:
                                             /*sel == 3*/  {96'b0, mem_i[3].rdata};
    always @(posedge clk) sel_d <= sel;

       `ifdef RTL_SIM

            localparam numInst     = 4;
            localparam numInstAddr = $clog2(numInst);


            localparam numWord     = 8192;
            localparam numWordAddr = $clog2(numWord);

            localparam numCMAddr   = $clog2(TSMC_MUX);
            localparam numIOBit    = 32;

            localparam totalBit    = numWord*numIOBit;
            localparam totalBitAddr = $clog2(totalBit);
            localparam numIOBitAddr = $clog2(numIOBit);
            task preloadData;
                input [256*8:1] infile;  // Max 256 character File Name
            begin
                //MEM
                reg [numWordAddr-numCMAddr-1:0] mem_row;
                reg [numCMAddr-1:0] mem_col;
                reg [numIOBitAddr-1:0] mem_bit;
                reg [numInstAddr-1:0]  mem_inst;
            
                //PRE
                reg [totalBit/32-1:0] pre_row;
                reg [4:0] pre_bit;
            
                reg [totalBitAddr:0] bit_idx;
                reg [31:0] PRELOAD [0:(numWord*numIOBit/32)-1];
                $readmemh(infile, PRELOAD);
            
                for (bit_idx = 0; bit_idx < totalBit; bit_idx = bit_idx + 1) begin
                    {mem_row, mem_col, mem_inst, mem_bit} = bit_idx;
                    {pre_row,          pre_bit} = bit_idx;
                    if (mem_inst == 0)
                        mem_i[0].mem_macro.I_sp_ram.MEMORY[mem_row][mem_col][mem_bit] = PRELOAD[pre_row][pre_bit];
                    else if (mem_inst == 1)
                        mem_i[1].mem_macro.I_sp_ram.MEMORY[mem_row][mem_col][mem_bit] = PRELOAD[pre_row][pre_bit];
                    else if (mem_inst == 2)
                        mem_i[2].mem_macro.I_sp_ram.MEMORY[mem_row][mem_col][mem_bit] = PRELOAD[pre_row][pre_bit];
                    else 
                        mem_i[3].mem_macro.I_sp_ram.MEMORY[mem_row][mem_col][mem_bit] = PRELOAD[pre_row][pre_bit];
                 end
            end
            endtask
        `endif //  `ifdef RTL_SIM
    `else

      logic [DW-1:0] ben_expand;
      genvar i;
      for (i = 0; i < (DW/8) ; i = i + 1) begin
           always_comb begin
              ben_expand[i * 8 +: 8] = (be_i[i] & we_i) ? 8'h00 : 8'hFF;
           end
      end

      ARM_SPSRAM_128X2048_M4_MEM
      I_sp_ram (
                 .Q     (ram_rdata_o),
                 .CLK   (clk),
                 .CEN   (~en_i),
                 .WEN   (ben_expand),
                 .GWEN  (~we_i),
                 .A     (addr_i),
                 .D     (wdata_i),
                 .EMA   (ram_ctrl[2:0]),
                 .EMAW  (ram_ctrl[4:3]),
                 .EMAS  (ram_ctrl[5]),
                 .RET1N (1'b1)
                 );
        `ifdef RTL_SIM
            localparam numInst     = 1;
            localparam numInstAddr = $clog2(numInst);

            localparam numMux      = 4; //from memory
            localparam numMuxAddr  = $clog2(numMux);

            localparam numWord     = 2048/*from memory*/ / numMux;
            localparam numWordAddr = $clog2(numWord);

            localparam numIOBit      = 128/*from memory*/;
            localparam numIOBitAddr  = $clog2(numIOBit);

            localparam totalBit     = numInst*numWord*numIOBit*numMux;
            localparam totalBitAddr = $clog2(totalBit);

            task preloadData;
                input [256*8:1] infile;  // Max 256 character File Name
            begin
                //MEM
                reg [numWordAddr-1:0]  mem_row;
                reg [numIOBitAddr-1:0] mem_bit;
                reg [numMuxAddr-1:0]   mem_mux;
            
                //PRE
                reg [totalBit/32-1:0] pre_row;
                reg [4:0] pre_bit;
            
                reg [totalBitAddr:0] bit_idx;
                reg [31:0] PRELOAD [0:(totalBit/32)-1];
                $readmemh(infile, PRELOAD);
            
                for (bit_idx = 0; bit_idx < totalBit; bit_idx = bit_idx + 1) begin
                    {mem_row, mem_mux, mem_bit} = bit_idx;
                    {pre_row, pre_bit} = bit_idx;

                    I_sp_ram.mem[mem_row][{mem_bit, mem_mux}] = PRELOAD[pre_row][pre_bit];
                end
            end
            endtask
        `endif
`endif // !`ifdef

endmodule

