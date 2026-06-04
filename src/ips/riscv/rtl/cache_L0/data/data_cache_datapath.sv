module data_cache_datapath 
    #( 
        parameter DATA_RAM_WIDTH      = 128,
        parameter DATA_CORE_WIDTH     = 32,
        parameter LOG2_WORDS_IN_BLOCK = 2,   // log2 of num of words in block
        parameter LOG2_NUM_BLKS       = 3    // how many bits (log2) required to represent the rows
    )				  
   (				
    input  logic                                clk,
	input  logic                                rst_n,
    // control                                            
    input  logic                                search_i,      
    output logic                                miss_o,
    output logic [LOG2_NUM_BLKS-1:0]            data_line_o,       // for LRU use                        
    input  logic                                write_to_mem_i,    // set if there are more dirty lines than MAX_DIRTY                           
    input  logic [LOG2_NUM_BLKS - 1:0]          rplc_line_idx_i,   // which line to replace
    output logic [LOG2_NUM_BLKS:0]              dirty_num_o,
    // core
    output logic [DATA_CORE_WIDTH-1:0]          data_o,
    input  logic                                we_i,              
    input  logic [(DATA_CORE_WIDTH/8)-1:0]      be_i,              
    input  logic [0:(DATA_CORE_WIDTH/8)-1][7:0] core_data_i,
	input  logic [31:0]                         addr_i,                                        
	input  logic                                write_ready_i,                                        	    
	// RAM   
    input  logic [DATA_RAM_WIDTH - 1:0]         mem_data_i,
    input  logic                                data_rvalid_i,
    output logic                                we_o,
    output logic [(DATA_RAM_WIDTH/8) - 1:0]     be_o,    
    output logic [31:0]                         waddr_o,    
    output logic [DATA_RAM_WIDTH - 1:0]         write_data_o
);	
    
               //--------------------------------- parameters and veriables -----------------------------------------//
    localparam NUM_BLKS       = 2**LOG2_NUM_BLKS;
    localparam WORDS_IN_BLOCK = 2**LOG2_WORDS_IN_BLOCK;
    
    logic                                     hit;
    logic                                     write_cache_hit;
    logic                                     write_cache_miss;
    logic                                     write_to_mem;
 
	logic [NUM_BLKS-1:0]                      cache_vld;
	logic [NUM_BLKS-1:0]                      cache_vld_d;
    logic [WORDS_IN_BLOCK-1:0][0:3][7:0]      cache_arr     [0:NUM_BLKS-1];
    logic [WORDS_IN_BLOCK-1:0][0:3][7:0]      cache_arr_d   [0:NUM_BLKS-1];
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] cache_tag     [NUM_BLKS-1:0]; // block(line) address	
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] cache_tag_d   [NUM_BLKS-1:0]; 
    logic [WORDS_IN_BLOCK-1:0][3:0]           cache_dirty   [NUM_BLKS-1:0]; // bit for each byte in the cache entry
    logic [WORDS_IN_BLOCK-1:0][3:0]           cache_dirty_d [NUM_BLKS-1:0]; 
    
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] tag;                          // 2 bits for 4 bytes in word, 
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] tag_d;                        
	logic [32 - LOG2_WORDS_IN_BLOCK -2 - 1:0] tag_miss;                     
	logic [LOG2_WORDS_IN_BLOCK - 1:0]         offset;                       
	logic [LOG2_WORDS_IN_BLOCK - 1:0]         offset_d;                    
	logic [LOG2_WORDS_IN_BLOCK - 1:0]         offset_miss;                    
	logic [LOG2_WORDS_IN_BLOCK - 1:0]         offset_miss_d;                    
                                
    logic [LOG2_NUM_BLKS - 1:0]               match_indx;
    logic [LOG2_NUM_BLKS - 1:0]               line_ix_hit;
    logic [LOG2_NUM_BLKS - 1:0]               line_ix_miss_d;
    logic [LOG2_NUM_BLKS - 1:0]               line_ix_miss;
    logic [LOG2_NUM_BLKS - 1:0]               rplc_dirty_idx;
    logic                                     miss_ix_dirty;
    logic [LOG2_NUM_BLKS:0]                   dirty_num_d;
    logic                                     we_d;
    logic                                     we_miss;
    logic [(DATA_CORE_WIDTH/8)-1:0]           be_d;
    logic [(DATA_CORE_WIDTH/8)-1:0]           be_miss;
    logic [0:(DATA_CORE_WIDTH/8)-1][7:0]      core_data_d;
    logic [0:(DATA_CORE_WIDTH/8)-1][7:0]      core_data_miss;
    
    logic [$clog2(DATA_CORE_WIDTH)-1:0]       k, j;
    logic                                     next_is_dirty;
    logic [31:0]                              be_32_miss, be_32_hit;
    
                        //---------------------------------- logic -----------------------------------------//
	assign {tag, offset} = addr_i[31:2]; 	// (tag-28, offset-2)
    assign data_o = (data_rvalid_i == 0)? cache_arr[data_line_o][offset_d]:             // data in the cache
                                          mem_data_i[(offset_miss_d+1) * 32 -1 -: 32];  // data from RAM
    
    // this section find out which line in the Cache is dirty
    genvar i;  
    generate
        wire [NUM_BLKS-1:0] match;   
        for(i = 0; i < NUM_BLKS; i = i+1) begin: gen_comp
            wire [LOG2_NUM_BLKS:0] dirty_line;
            assign match[i] = ~|(tag^cache_tag[i]);  // if there is match in line i so the i-th bit of 'match' is set 
            // sum dirty lines
            if(i == 0)
                assign dirty_line = |cache_dirty[i];
            else 
                assign dirty_line = gen_comp[i-1].dirty_line + |cache_dirty[i];
        end         
    endgenerate
    // find out how many lines is dirty, and if the next line to replace is dirty
    assign dirty_num_d   = gen_comp[NUM_BLKS-1].dirty_line;
    assign next_is_dirty = |(cache_dirty[(rplc_line_idx_i + 1)%NUM_BLKS] | cache_dirty[(rplc_line_idx_i + 2)%NUM_BLKS]);
    assign miss_ix_dirty = |cache_dirty[line_ix_miss_d];
    
    // calculation
    always_comb begin 
        hit              = 1'b0;
        miss_o           = 1'b0;
        write_cache_hit  = 1'b0; 
        write_cache_miss = 1'b0; 
        write_to_mem     = 1'b0; 
        we_o             = 1'b0; 
        be_o             = 4'b0; 
        line_ix_hit      = data_line_o;
        line_ix_miss     = line_ix_miss_d;
        cache_vld_d      = cache_vld;
        cache_dirty_d    = cache_dirty;
        cache_arr_d      = cache_arr;
        cache_tag_d      = cache_tag;  
        rplc_dirty_idx   = 'b0;
        write_data_o     = 'b0;
        waddr_o          = 32'b0;
        match_indx       = 'b0;
        tag_miss         = tag_d;           
        we_miss          = we_d;            
        be_miss          = be_d;            
        core_data_miss   = core_data_d;     
        offset_miss      = offset_miss_d;    
        be_32_hit        = 'b0;
        be_32_miss       = 'b0;
        
        // get the first match indx
        for(j = 0; j < NUM_BLKS; j = j+1) 
            if (match[j]==1 && !match_indx) 
                match_indx = j;
                
        // search dirty line to write to memory
        // line that is dirty and we are not writing to her
        for(k = 0; k < NUM_BLKS; k = k+1) begin
            rplc_dirty_idx = (rplc_line_idx_i + k) % NUM_BLKS;        
            //                line is dirty                        write to hit line                                      write to miss line
            if(cache_dirty[rplc_dirty_idx] != 0 && ~((write_cache_hit && rplc_dirty_idx == line_ix_hit) || (write_cache_miss && (rplc_dirty_idx == line_ix_miss_d)))) begin
                break;
            end
        end
        
        if(search_i) begin     
            if(data_rvalid_i) begin                        // data arrive from memory
                if(tag == tag_d) begin                     // the requested data is the data just arrive from RAM  
                    line_ix_hit = line_ix_miss_d;
                    hit         = 1'b1;
                end else if(match_indx == line_ix_miss_d)  // the requested data is in the line we going to replace
                    hit = 1'b0;     
                else begin                                 // check if the data at the rest of cache lines
                    line_ix_hit = match_indx;            
                    hit         = |match && cache_vld_d[match_indx];
                end
            end else begin
                line_ix_hit     = match_indx;            
                hit             = |match && cache_vld_d[match_indx];  
            end
            miss_o              = ~hit;         
            write_cache_hit     = (we_i && hit); 
            if(miss_o) begin
                line_ix_miss    = rplc_line_idx_i;
                tag_miss        = tag;
                we_miss         = we_i;
                be_miss         = be_i;
                core_data_miss  = core_data_i;
                offset_miss     = offset;
            end                          
        end                              
    
        // new data arrive and need to be store in the cache
        if(data_rvalid_i) begin
            if(DATA_RAM_WIDTH == 32)
                cache_arr_d[line_ix_miss_d][offset_miss_d] = mem_data_i;
            else if(DATA_RAM_WIDTH == 128)
                cache_arr_d[line_ix_miss_d]                = mem_data_i;
            // data managing
            cache_tag_d[line_ix_miss_d] = tag_d;
            cache_vld_d[line_ix_miss_d] = 1'b1;               
            write_cache_miss            = we_d;       
        end         
         
        if(data_rvalid_i && miss_ix_dirty) begin  // write dirty line before we replace it
            write_to_mem                  = 1'b1;
            rplc_dirty_idx                = line_ix_miss_d;                
            cache_dirty_d[line_ix_miss_d] = 'b0;
            // if RAM is not busy -> there is no read RAM (miss) and also not write RAM
            // and we have dirty lines to write
        end else if (hit && ((write_to_mem_i || next_is_dirty) && write_ready_i)) begin  
            if(cache_dirty[rplc_dirty_idx] != 0 && ~((write_cache_hit && rplc_dirty_idx == line_ix_hit) || (write_cache_miss && (rplc_dirty_idx == line_ix_miss_d)))) begin
                write_to_mem                  = 1'b1;
                cache_dirty_d[rplc_dirty_idx] = 'b0;
            end   
        end
        // -------------------------
        // write to cache or memory
        // -------------------------
        if(write_cache_miss) begin
            be_32_miss = {{8{be_d[3]}}, {8{be_d[2]}}, {8{be_d[1]}}, {8{be_d[0]}}}; 
            cache_arr_d[line_ix_miss_d][offset_miss_d]   = cache_arr_d[line_ix_miss_d][offset_miss_d] & ~be_32_miss;   
            cache_arr_d[line_ix_miss_d][offset_miss_d]   = cache_arr_d[line_ix_miss_d][offset_miss_d] | (core_data_d & be_32_miss); 
            cache_dirty_d[line_ix_miss_d][offset_miss_d] = cache_dirty_d[line_ix_hit][offset] | be_d;    
        end
        if(write_cache_hit) begin
            be_32_hit = {{8{be_i[3]}}, {8{be_i[2]}}, {8{be_i[1]}}, {8{be_i[0]}}};
            cache_arr_d[line_ix_hit][offset]   = cache_arr_d[line_ix_hit][offset] & ~be_32_hit;   
            cache_arr_d[line_ix_hit][offset]   = cache_arr_d[line_ix_hit][offset] | (core_data_i & be_32_hit);     
            cache_dirty_d[line_ix_hit][offset] = cache_dirty_d[line_ix_hit][offset] | be_i;    
        end
        if(write_to_mem) begin 
            write_data_o = cache_arr[rplc_dirty_idx];
            we_o         = 1'b1;
            be_o         = cache_dirty[rplc_dirty_idx];
            waddr_o      = {cache_tag[rplc_dirty_idx], {(LOG2_WORDS_IN_BLOCK + 2){1'b0}}};
        end
    end //always

    // sample
    always @(posedge clk, negedge rst_n) begin
        if(! rst_n) begin    
            data_line_o    <= 'b0;
            cache_vld      <= '{default:'b00};
            cache_arr      <= '{default:'b00};
            cache_tag      <= '{default:'b00};   
            cache_dirty    <= '{default:'b00};  
            dirty_num_o    <= 'b0;
            offset_d       <= 'b0;           
            offset_miss_d  <= 'b0;
            tag_d          <= 1'b0;
            we_d           <= 1'b0;
            core_data_d    <= 'b0; 
            be_d           <= 'b0;            
            line_ix_miss_d <= 'b0;            
        end else begin
            data_line_o    <= line_ix_hit;        
            cache_vld      <= cache_vld_d;
            cache_arr      <= cache_arr_d;
            cache_tag      <= cache_tag_d; 
            cache_dirty    <= cache_dirty_d;
            dirty_num_o    <= dirty_num_d;
            offset_d       <= offset;            
            offset_miss_d  <= offset_miss;
            tag_d          <= tag_miss;
            we_d           <= we_miss;
            core_data_d    <= core_data_miss; 
            be_d           <= be_miss;
            line_ix_miss_d <= line_ix_miss;
        end              
    end
endmodule
