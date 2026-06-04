// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the ���License���); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an ���AS IS��� BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


`define MEM_INST spram (                               \
                        .clk            (clk),         \
                        .en_i           (en_i),        \
                        .addr_i         (addr_i),      \
                        .wdata_i        (wdata_i),     \
                        .ram_rdata_o    (rdata_o),     \
                        .we_i           (we_i),        \
                        .be_i           (be_i),        \
                        .ram_ctrl       (ram_ctrl))

module sp_ram_wrap
  #(
    parameter RAM_SIZE   = 32768,    // In bytes. We have 4 memories with 2048 lines of 32 bits each. 
    parameter DATA_WIDTH = 32,
    parameter NUM_WORDS_REG = 256,
    parameter ADDR_WIDTH = DATA_WIDTH == 128 && NUM_WORDS_REG == 128 ? $clog2(RAM_SIZE/4) : $clog2(RAM_SIZE/(DATA_WIDTH/8)), //For data mem, we still want 32 word access to be possible
    parameter ADDR_WIDTH_REG = $clog2(NUM_WORDS_REG),
    parameter init_file = "",
    parameter MEM_CTRL_DW = 5,
    parameter MEM_MUX = 4
    )(
      // Clock and Reset
      input logic                    clk,
      input logic                    rstn_i,
      input logic                    en_i,
      input logic [ADDR_WIDTH-1:0]   addr_i, // Byte address
      input logic [DATA_WIDTH-1:0]   wdata_i,
      output logic [DATA_WIDTH-1:0]  rdata_o,
      input logic                    we_i,
      input logic [DATA_WIDTH/8-1:0] be_i,
      input logic                    bypass_en_i,

      input wire [MEM_CTRL_DW-1:0]   ram_ctrl
      );
   localparam IN_ROW_ADDR_BITS = $clog2(DATA_WIDTH/8);

   reg [ADDR_WIDTH-1:0]             addr_i_d1 ;
   always @( posedge clk or negedge rstn_i)
     if (!rstn_i) addr_i_d1 <= #1 {ADDR_WIDTH{1'b0}} ;
     else addr_i_d1         <= #1 addr_i ;

`ifdef ALTERA


    generate
    if (RAM_SIZE==32*1024 && DATA_WIDTH==32) begin : alt8192x32
       altera_sram_8192x32 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
         );
    end else if (RAM_SIZE==64*1024 && DATA_WIDTH==32) begin : alt16384x32
       altera_sram_16384x32 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
         );
         
    end else if (RAM_SIZE==192*1024 && DATA_WIDTH==32) begin : alt49152x32 // 192KB
       altera_sram_49152x32 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
         );
         
         
    end else if (RAM_SIZE==64*1024 && DATA_WIDTH==128) begin : alt4096x128
       altera_sram_4096x128 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
                      );
                      
     end else if (RAM_SIZE==256*1024 && DATA_WIDTH==128) begin : alt16384x128
       altera_sram_16384x128 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
                      );

    end else if (RAM_SIZE==160*1024 && DATA_WIDTH==128) begin : alt10240x128   // 160KB
       altera_sram_10240x128 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
                      );
                      

    end else if (RAM_SIZE==120*1024 && DATA_WIDTH==128) begin : alt7680x128   // 120KB
       altera_sram_7680x128 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
                      );

                     
    end else if (RAM_SIZE==192*1024 && DATA_WIDTH==128) begin : alt12288x128   // 192KB
       altera_sram_12288x128 #(.init_file(init_file))
       altera_sram_i (
                      .address ( addr_i[ADDR_WIDTH-1:0] ),
                      .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                      .clken   ( en_i                   ),
                      .clock   ( clk                    ),
                      .data    ( wdata_i                ),
                      .wren    ( we_i                   ),
                      .q       ( rdata_o                )
                      );
                      
              
     end else begin : altX
        altera_sramx #(.init_file(init_file), .WIDTH(DATA_WIDTH), .DEPTH(RAM_SIZE/(DATA_WIDTH/8)))
        altera_sram_i (
                       .address ( addr_i[ADDR_WIDTH-1:0] ),
                       .byteena ( be_i & {(DATA_WIDTH/8){we_i}}       ),
                       .clken   ( en_i                   ),
                       .clock   ( clk                    ),
                       .data    ( wdata_i                ),
                       .wren    ( we_i                   ),
                       .q       ( rdata_o                )
                       );
     end
    endgenerate

`else //ASIC

    generate
        if (DATA_WIDTH == 128) begin : dw128
            if (ADDR_WIDTH == 12) begin : aw12
                    sp_sram4096X128_bank_i #(.MEM_MUX(MEM_MUX)) `MEM_INST;
            end else if (ADDR_WIDTH == 13) begin : aw11
                    sp_sram2048X128_bank_i #(.MEM_MUX(MEM_MUX)) `MEM_INST;
            end
        end

        else begin : dw32
            if (ADDR_WIDTH == 13) begin: aw13
                sp_sram8192X32_bank_i #(.MEM_MUX(MEM_MUX)) `MEM_INST;
           end else if (ADDR_WIDTH == 14) begin : aw14
                sp_sram16384X32_bank_i #(.MEM_MUX(MEM_MUX)) `MEM_INST;
            end
        end
    endgenerate


`endif // !`ifdef ALTERA

endmodule // sp_ram_wrap
