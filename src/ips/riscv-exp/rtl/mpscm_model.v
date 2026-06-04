`timescale 1ns/1ps
module mpscm #(parameter ROWS=32 , ADDR_WIDTH=$clog2(ROWS) , ASYNC_READ=0 , READ_OLD=0, DATA_WIDTH=32 , WP=3 , RP=5) (

//module mpscm #(parameter ROWS=32 , ADDR_WIDTH=5 , ASYNC_READ=0 , READ_OLD=0, DATA_WIDTH=32 , WP=20 , RP=20) (
    
    
    input [DATA_WIDTH-1:0] DIN [0:WP-1],
    output reg [DATA_WIDTH-1:0] DOUT [0:RP-1],
    input [ADDR_WIDTH-1:0] RADDR [0:RP-1],
    input [ADDR_WIDTH-1:0] WADDR [0:WP-1],
    input CLK,
    input [RP-1:0] RE,
    input [WP-1:0] WE,
    input SE
    );
    
    localparam MEM_DEPTH = ROWS; // the number of MEM lines

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    reg [RP-1:0] RE_s;
    reg [ADDR_WIDTH-1:0] RADDR_s [0:RP-1];

    integer i;
    always @(posedge CLK) begin
        for (i=0; i<WP; i=i+1)     
            if (WE[i])
                mem[WADDR[i]] <= DIN[i];
    end

    generate
    if (ASYNC_READ==0) begin
        if (READ_OLD==1) begin //READ THE DATA THAT WAS IN THE MEMORY DURING THE RE CYCLE
            always @(posedge CLK) begin
                for (i=0; i<RP; i=i+1)     
                    if (RE[i])
                        if (RADDR[i] == '0)
                           DOUT[i] <= '0;
                        else
                           DOUT[i] <= mem[RADDR[i]];
            end
        end 
        else begin //READ THE DATA THAT IS IN THE MEMORY DURING THE DOUT CYCLE
            always @(posedge CLK) begin
                //noytzach RE_s <= RE;
                for (i=0; i<RP; i=i+1)
                    if (RE[i]) //noytzach
                        RADDR_s[i] <= RADDR[i];
            end
            always @(*)
                for (i=0; i<RP; i=i+1)
                    //noytzach if (RE_s[i])
                    if (RE[i])
                        if (RADDR_s[i] == '0)
                           DOUT[i] = '0;
                        else
                           DOUT[i] = mem[RADDR_s[i]];
        end
    end 
    else begin
        always @(*)
            for (i=0; i<RP; i=i+1)
                if (RADDR[i] == '0)
                   DOUT[i] = '0;
                else
                   DOUT[i] = mem[RADDR[i]];
    end
    endgenerate

endmodule
