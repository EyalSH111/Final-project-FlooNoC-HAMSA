// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


// define five registers per timer - timerx2, cmpx2, control registers
`define REGS_MAX_IDX             'd3
`define REG_TIMER_LO              3'b000
`define REG_TIMER_HI              3'b001
`define REG_CMP_LO                3'b010
`define REG_CMP_HI                3'b011
`define REG_TIMER_CTRL            3'b100

module timer
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    output logic                [1:0] irq_o // overflow and cmp interrupt
);

    // APB register interface
    logic [`REGS_MAX_IDX-1:0]       register_adr;
    assign register_adr = PADDR[`REGS_MAX_IDX + 2:2];
    // APB logic: we are always ready to capture the data into our regs
    // not supporting transfare failure
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
    // registers
    logic [7:0] cycle_counter_n, cycle_counter_q;

    logic [63:0] timer_q, timer_n;
    logic [63:0] cmp_q, cmp_n;
    logic [7:0] prescaler_n, prescaler_q;
    logic enable_n, enable_q;

    //irq logic
    always_comb
    begin
        irq_o = 2'b0;

        // overlow irq
        if (&timer_q)
            irq_o[0] = 1'b1;

        // cmp irq
        if (timer_q >= cmp_q)
            irq_o[1] = 1'b1;

    end

    // register write logic
    always_comb
    begin
        enable_n        = enable_q;
        timer_n         = timer_q;
        cmp_n           = cmp_q;
        prescaler_n     = prescaler_q;
        cycle_counter_n = cycle_counter_q + enable_q;

        if (enable_q) begin
            if (prescaler_q == 0)
                timer_n = timer_q + 'h1;
            else if (cycle_counter_q == prescaler_q) begin
                timer_n = timer_q + 'h1;
                cycle_counter_n = 'h0;
            end
        end

        // written from APB bus - gets priority
        if (PSEL && PENABLE && PWRITE)
        begin
            case (register_adr)
                `REG_TIMER_CTRL: begin
                    enable_n = PWDATA[0];
                    prescaler_n = PWDATA[15:8];
                end

                `REG_TIMER_LO:
                    timer_n[31:0] = PWDATA;

                `REG_TIMER_HI:
                    timer_n[63:32] = PWDATA;

                `REG_CMP_LO:
                    cmp_n[31:0] = PWDATA;

                `REG_CMP_HI:
                    cmp_n[63:32] = PWDATA;

            endcase
        end
    end

    // APB register read logic
    always_comb
    begin
        PRDATA = 'b0;

        if (PSEL && PENABLE && !PWRITE)
        begin
            case (register_adr)
                `REG_TIMER_CTRL:
                    PRDATA = { 16'h0 ,prescaler_q,7'h0, enable_q};

                `REG_TIMER_LO:
                    PRDATA = timer_q[31:0];

                `REG_TIMER_HI:
                    PRDATA = timer_q[63:32];

                `REG_CMP_LO:
                    PRDATA = cmp_q[31:0];

                `REG_CMP_HI:
                    PRDATA = cmp_q[63:32];
            endcase

        end
    end
    // synchronouse part
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            enable_q <= 1'b1;
            prescaler_q <= 8'd99;
            timer_q <= 64'h0;
            cmp_q <= {64{1'b1}};

            cycle_counter_q <= 32'b0;
        end
        else begin
            enable_q    <= enable_n;
            prescaler_q <= prescaler_n;
            timer_q     <= timer_n;
            cmp_q       <= cmp_n;

            cycle_counter_q <= cycle_counter_n;
        end
    end


endmodule
