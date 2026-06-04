//****************************************************************//
// this module calculate the next line to replace in cache miss   //
// when the module get request it will immediately return answer  //
// and then calculate the next line "off-line"                    //
//                                                                //
//         (  )  (  _ \/ )( \                                     //
//         / (_/\ )   /) \/ (                                     //
//         \____/(__\_)\____/                                     //
//                                                                //
//****************************************************************//
module cache_LRU
#( 
    parameter integer LOG2_NUM_BLKS = 3
)
(
    input                            clk,
    input                            rst_n,
    input                            en_i,
    input [LOG2_NUM_BLKS - 1:0]      last_used_line_i,
    
    output reg                       ready_o,
    output reg [LOG2_NUM_BLKS - 1:0] rplc_line_idx_o
);

    localparam NUM_LINES = 2**LOG2_NUM_BLKS;
    enum logic [2:0] { IDLE, WORK} CS, NS;

    logic [NUM_LINES-1:0]       LRU_tbl   [0:NUM_LINES-1];
    logic [NUM_LINES-1:0]       LRU_tbl_d [0:NUM_LINES-1];
    logic [LOG2_NUM_BLKS : 0]   j, k;
    logic [LOG2_NUM_BLKS : 0]   match_indx;
    logic                       match_flag;
    logic [LOG2_NUM_BLKS - 1:0] rplc_line_idx_d;
    
    // seasrch for the LRU = zeros line.
    // each line represented by one bit in "match"
    genvar i;  
    generate
        wire [NUM_LINES-1:0] match;       
        for(i = 0; i < NUM_LINES; i = i+1) begin: ix_compare
            assign match[i] = ~|(LRU_tbl[i]);        
        end         
    endgenerate
    
    assign rplc_line_idx_d = match_indx; // gen_lvl[NUM_LINES-1].match_indx;
    // calculating
    always @(*) begin
        LRU_tbl_d  = LRU_tbl;
        match_flag = 1'b0;
        match_indx =  'b0;
        
        for(k = 0; k < NUM_LINES; k = k+1) 
            if (match[k] == 1 & match_flag == 0) begin
                match_indx = k;
                match_flag = 1'b1;
            end
        
        // if there were been an access to Cache's table at line i:
        // 1 - fill row i with ones
        // 2 - fill column i with zeros
        if(en_i) begin
            LRU_tbl_d[last_used_line_i] = '{default:'b1};      
            for(j = 0; j < NUM_LINES; j = j+1)
                LRU_tbl_d[j][last_used_line_i] = 1'b0;
        end                  
    end
    
    always @(posedge clk) begin
        if(!rst_n) begin
            LRU_tbl         <= '{default:'b00};
            rplc_line_idx_o <= 'b0;
        end else begin
            LRU_tbl         <= LRU_tbl_d;
            rplc_line_idx_o <= rplc_line_idx_d;
        end
    end
endmodule
        
     
    