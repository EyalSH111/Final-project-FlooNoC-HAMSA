module spram(/*autoarg*/
   // Outputs
   Q,
   // Inputs
   CLK, CE, WE, BWM, D, A
   );

parameter DEPTH=1024;
parameter WIDTH=16;
parameter INIT_FILE="";
localparam DEPTH_W = $clog2(DEPTH);
localparam TOTAL_BYTES = DEPTH*WIDTH/8;

    input CLK;
    input CE;
    input WE;
    input [WIDTH-1:0] BWM;
    input [WIDTH-1:0] D;
    input [DEPTH_W-1:0] A;
    output reg [WIDTH-1:0] Q;

    reg [WIDTH-1:0] MEM [0:DEPTH-1];

    //write
    always @(posedge CLK)
        if (CE && WE)
            MEM[A] <= (MEM[A] & ~BWM) | (D & BWM);

    //read
    always @(posedge CLK)
        if (CE && !WE)
            Q <= MEM[A];


    `ifdef RTL_SIM
    `ifndef ALTERA
    initial
        if (INIT_FILE!="")
            preload(INIT_FILE);

    task preload(input string mem_file);
        integer i;
        integer j;
        integer x;
        integer r;
        integer c;
        logic [31:0] mem_content[];  // this variable holds the whole memory content
        mem_content  = new [TOTAL_BYTES/4];
        $readmemh(mem_file, mem_content);


        for (i=0; i<TOTAL_BYTES/4; i=i+1) begin
            for (j=0; j<4; j=j+1) begin
                x = i*4+j;
                r = x / (WIDTH/8);
                c = x % (WIDTH/8);
                MEM[r][8*(c+1)-1 -: 8] = mem_content[i][8*(j+1)-1 -: 8];
            end
        end
    endtask
    `endif
    `endif

endmodule
