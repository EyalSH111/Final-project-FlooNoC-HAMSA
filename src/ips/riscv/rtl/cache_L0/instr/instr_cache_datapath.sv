//**********************************************************
// this module contain the Cache data
// the module managing of all that related to data manipolate
// operation: 
//      search line
//      replace line with new data
//      soft reset - unvalidate all data in the table
//**********************************************************
module instr_cache_datapath 
   #( 
    parameter integer LOG2_NUM_BLKS = 3,       // how many bits (log2) required to represent the rows
    parameter integer RAM_WIDTH     = 128,
    parameter integer CORE_WIDTH    = 128
   )				  
   (				
    input  logic                       clk,
	input  logic                       rst_n,
	input  logic                       soft_rst_i,
    
    input  logic                       search,         // from control
    input  logic                       new_rvalid_i,   // from control
    input  logic                       new_rdata_i,    // from control
    
    input  logic [31:0]                addr_i,         // from core
	input  logic [RAM_WIDTH - 1:0]     data_i,         // from memory
	input  logic [LOG2_NUM_BLKS - 1:0] rplc_line_idx,  // from algo
    
	input  logic [32 - $clog2(RAM_WIDTH/32) -2 - 1:0] tag_d_i, 
	
	output logic                       data_ready_o,
    output logic                       miss_o,
	output logic [CORE_WIDTH - 1:0]    data_o,
    output logic [LOG2_NUM_BLKS - 1:0] addr_found_line
);	
    
    //---------------------------------define -----------------------------------------//
    localparam NUM_BLKS = 2**LOG2_NUM_BLKS;
    localparam WORDS_IN_BLOCK = RAM_WIDTH/32;
    localparam LOG2_WORDS_IN_BLOCK = $clog2(WORDS_IN_BLOCK);
    
    
    logic                                     data_ready_d;
    logic                                     hit;
	logic [NUM_BLKS-1:0]                      cache_vld;
	logic [NUM_BLKS-1:0]                      cache_vld_d;
    logic [WORDS_IN_BLOCK-1:0][31:0]          cache_arr   [0:NUM_BLKS-1] ;
    logic [WORDS_IN_BLOCK-1:0][31:0]          cache_arr_d [0:NUM_BLKS-1] ;
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] cache_arr_tag   [NUM_BLKS-1:0]; // block(line) address
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] cache_arr_tag_d [NUM_BLKS-1:0]; 	
    logic [LOG2_NUM_BLKS-1:0]                 addr_found_line_d;
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] tag;                            // 2 bits for 4 bytes in word, 
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] tag_d;                           
	logic [LOG2_WORDS_IN_BLOCK - 1:0]         offset;                         // chose a specific word in the block
	logic [LOG2_WORDS_IN_BLOCK - 1:0]         offset_d;                       
    logic [LOG2_NUM_BLKS-1:0]                 match_indx;
    logic [NUM_BLKS-1:0]                      j;     
    

    //---------------------------------- logic -----------------------------------------//
	assign {tag, offset} = addr_i[31:2];        // divide the address to:
                                                //    - tag    (= addr of the block we looking for) 
                                                //    - offset (= word in block)
	
    if(CORE_WIDTH == 128)
        assign data_o = (new_rvalid_i == 0)? cache_arr[addr_found_line]:
                                               cache_arr_d[rplc_line_idx];
    else if (CORE_WIDTH == 32)
        assign data_o = (new_rvalid_i == 0)? cache_arr[addr_found_line][offset_d]:
                                               cache_arr_d[rplc_line_idx][offset_d];
    
    // seasrch for the line that have the address that have been requested.
    // each line represented by one bit in "match". "match" i-th bit is set if we find the address in the i line 
    genvar i;  
    generate
        wire [NUM_BLKS-1:0] match;
        for(i = 0; i < NUM_BLKS; i = i+1) begin: gen_comp
            assign match[i] = ~|(tag^cache_arr_tag[i]);   
        end         
    endgenerate
    
    // calculation
    always @* begin
        hit               = 1'b0;
        data_ready_d      = 1'b0;
        miss_o            = 1'b0; 
        addr_found_line_d = addr_found_line;        
        cache_vld_d       = cache_vld;
        cache_arr_d       = cache_arr;
        cache_arr_tag_d   = cache_arr_tag;        
        match_indx        = 'b0;
        
        
        for(j = 0; j < NUM_BLKS; j = j+1) 
            if (match[j]==1 && !match_indx) 
                match_indx = j;
        if(soft_rst_i)
            cache_vld_d = '{default:'b00};
        else if(search) begin  
            if(new_rdata_i) begin  
                if(tag == tag_d_i) begin                    // the requested data is data that just arrive from RAM 
                    addr_found_line_d = rplc_line_idx;
                    hit               = 1'b1;
                end else if(match_indx == rplc_line_idx)    // the requested data is in the line we are going to replace
                    hit = 1'b0;     
                else begin
                    addr_found_line_d = match_indx;         // the requested data is in the rest of the table
                    hit               = |match && cache_vld[match_indx];
                end
            end else begin
                addr_found_line_d = match_indx;            
                hit               = |match && cache_vld[match_indx];  // if there are at least one set bit then it is hit (suposse to be only one)
            end
            miss_o       = ~hit;  
            data_ready_d = hit;
        end   
        
        // insert new data from RAM
        if(new_rdata_i) begin  
            cache_arr_d[rplc_line_idx]     = data_i;
            cache_arr_tag_d[rplc_line_idx] = tag_d_i;
            cache_vld_d[rplc_line_idx]     = 1'b1; 
        end	      
    end
    
    // sample
    always @(posedge clk, negedge rst_n) begin
        if(! rst_n) begin    
            data_ready_o    <= 1'b0;
            offset_d        <= 'b0;
            tag_d           <= 'b0;
            addr_found_line <= '{default:'b00};
            cache_vld       <= '{default:'b00};
            cache_arr       <= '{default:'b00};
            cache_arr_tag   <= '{default:'b00};     
        end
        else begin
            data_ready_o    <= data_ready_d;
            offset_d        <= offset;
            tag_d           <= tag;
            addr_found_line <= addr_found_line_d;        
            cache_vld       <= cache_vld_d;
            cache_arr       <= cache_arr_d;
            cache_arr_tag   <= cache_arr_tag_d; 
        end
    end
endmodule
