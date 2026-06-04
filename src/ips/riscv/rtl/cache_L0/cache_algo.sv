//*****************************************************************//
// this module calculate the next line to replace in cache miss    //
// when the module get request it will immediately return answer   //
// and then calculate the next line "off-line"                     //
//        ____  __  ____  __                                       //
//       (  __)(  )(  __)/  \                                      //
//        ) _)  )(  ) _)(  O )                                     //
//       (__)  (__)(__)  \__/                                      //
//                                                                 //
//*****************************************************************//
module cache_algo
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
    reg                       ready_d;
    reg [LOG2_NUM_BLKS - 1:0] rplc_line_idx_d;
    
    always @(*) begin
        rplc_line_idx_d     = rplc_line_idx_o;
        if(en_i)
            rplc_line_idx_d = rplc_line_idx_o + 1;
    end
    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) 
            rplc_line_idx_o <=  'b0;
        else 
            rplc_line_idx_o <= rplc_line_idx_d; 
    end
endmodule
        
     
    