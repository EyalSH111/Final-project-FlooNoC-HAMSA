//////////////////////////////////////////////////////////////////////////////////////////////
//   _____           _                   _   _                _____           _             //
//  |_   _|         | |                 | | (_)              / ____|         | |            //
//    | |  _ __  ___| |_ _ __ _   _  ___| |_ _  ___  _ __   | |     __ _  ___| |__   ___    //
//    | | | '_ \/ __| __| '__| | | |/ __| __| |/ _ \| '_ \  | |    / _` |/ __| '_ \ / _ \   //
//   _| |_| | | \__ \ |_| |  | |_| | (__| |_| | (_) | | | | | |___| (_| | (__| | | |  __/   //
//  |_____|_| |_|___/\__|_|   \__,_|\___|\__|_|\___/|_| |_|  \_____\__,_|\___|_| |_|\___|   //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


module instr_cache_L0
#( 
    parameter RAM_SIZE      = 32768,                // in bytes
    parameter ADDR_WIDTH    = $clog2(RAM_SIZE) + 1, // one bit more than necessary, for the boot rom
    parameter RAM_WIDTH     = 128,
    parameter CORE_WIDTH    = 128,
    parameter LOG2_NUM_BLKS = 3   // how many bits (log2) required to represent the rows
)
(                                     
    input  logic                  clk    , 
    input  logic                  rst_n  ,
    input  logic                  soft_rst_i  ,
   
    input  logic                  en_i   ,
    input  logic [31:0]           addr_i ,
    output logic [CORE_WIDTH-1:0] rdata_o,
    input  logic                  bypass_en_i,
    output logic                  rvalid_o,
    output logic                  gnt_o   ,

    // SP RAM interconnection
    output logic                  ram_en_o          ,   
    output logic [31:0]           ram_addr_o        ,     
    input  logic [RAM_WIDTH-1:0]  ram_rdata_i       ,
    input  logic                  ram_data_gnt_i    ,
    input  logic                  ram_data_rvalid_i 
);
    
    // control - datapath
    logic                          start_search;
    logic                          instr_rvalid;    
    logic                          new_rdata;    
    logic                          DP_rvalid;
    logic                          DP_miss;
    logic [31:0]                   DP_addr;
    logic [31:0]                   DP_addr_d;   
    logic                          rvalid;   
    logic                          rvalid_d;   

    // algo           
    logic                          algo_ready;  // not in use
    logic                          ALGO_en;         
    logic [LOG2_NUM_BLKS - 1:0]    algo_rplc_line_idx; 
    logic [LOG2_NUM_BLKS - 1:0]    last_used_line;
    
    // ram
    logic [31:0]                   ram_raddr_d; 
    
    // prefetch
    localparam LOG2_NUM_WORDS = $clog2(RAM_WIDTH/32);
    enum logic [2:0] { IDLE, READ_FROM_RAM, WAIT_FOR_GNT, PRE_FETCH} CS, NS;
    logic [3:0]                          access_counter;
    logic [3:0]                          access_counter_d;
    logic [31:LOG2_NUM_WORDS + 2]        last_tag;    
    logic [31:LOG2_NUM_WORDS + 2]        current_tag;    
    logic [32 - LOG2_NUM_WORDS -2 - 1:0] DP_tag; 
    
    instr_cache_datapath  
    #(
        .LOG2_NUM_BLKS   ( LOG2_NUM_BLKS      ),
        .RAM_WIDTH       ( RAM_WIDTH          ),
        .CORE_WIDTH      ( CORE_WIDTH         )
    )
    cache_datapath_i 
    (
        .clk             ( clk                ), 
        .rst_n           ( rst_n              ), 
        .soft_rst_i      ( soft_rst_i | bypass_en_i ), 
        // control                     
        .search          ( start_search       ), 
        .new_rvalid_i    ( instr_rvalid       ),   
        .new_rdata_i     ( new_rdata          ),   
        .data_ready_o    ( DP_rvalid          ), 
        .miss_o          ( DP_miss            ),  
        
        // from memory                        
        .addr_i          ( DP_addr            ), 
        .data_i          ( ram_rdata_i        ), 
        
        .tag_d_i         ( DP_tag             ),
        //  algo     
        .rplc_line_idx   ( algo_rplc_line_idx ),                 
        .addr_found_line ( last_used_line     ),              
        .data_o          ( rdata_o            )
    );                          
    
    cache_algo      
    #(
        .LOG2_NUM_BLKS    ( LOG2_NUM_BLKS      )
    )
    cache_algo_i 
    (
        .clk              ( clk                ), 
        .rst_n            ( rst_n              ), 
                          
        .en_i             ( ALGO_en            ), 
        .last_used_line_i ( last_used_line     ), 
                          
        .rplc_line_idx_o  ( algo_rplc_line_idx ),   
        .ready_o          ( algo_ready         )                    
    );
  
    assign rvalid_o = rvalid_d | instr_rvalid;
    
    always_comb begin
        start_search   = 1'b0;
        instr_rvalid   = 1'b0;
        new_rdata      = 1'b0;
        ram_en_o       = 1'b0;
        rvalid         = 1'b0;
        ALGO_en        = 1'b0;
        gnt_o          = 1'b0;
        DP_addr        = DP_addr_d;
        ram_addr_o     = ram_raddr_d;     
        access_counter = access_counter_d;
        current_tag    = last_tag;
        DP_tag         = last_tag;
        
        if( !bypass_en_i ) begin
            case(CS)
                IDLE:
                begin
                    if(en_i) begin
                        start_search = 1'b1;
                        gnt_o        = 1'b1;
                        DP_addr      = addr_i;
                        current_tag  = addr_i[31:LOG2_NUM_WORDS + 2];
                        if(last_tag == current_tag) begin
                            access_counter = access_counter_d + 1;
                            if(access_counter == (RAM_WIDTH/32)/2+1) begin
                                ram_addr_o = {current_tag + 1, {LOG2_NUM_WORDS + 2{1'b0}}};
                                ram_en_o   = 1'b1;
                            end
                        end else 
                            access_counter = 'b0;
                        if(DP_miss) begin
                            ram_addr_o = addr_i;
                            ram_en_o     = 1'b1;
                        end else
                            rvalid     = 1'b1;     
                                
                    end
                end  // IDLE
                
                PRE_FETCH:
                begin
                    if(ram_data_rvalid_i) begin
                        DP_tag    = last_tag + 1;
                        new_rdata = 1'b1;
                        ALGO_en   = 1'b1;
                    end
                    if(en_i) begin
                        start_search = 1'b1;
                        gnt_o        = 1'b1;
                        DP_addr      = addr_i;
                        current_tag  = addr_i[31:LOG2_NUM_WORDS + 2];
                        if(last_tag == current_tag) 
                            access_counter = access_counter_d + 1;
                        else 
                            access_counter = 'b0;
                        if(DP_miss) begin
                            ram_addr_o = addr_i;
                            ram_en_o     = 1'b1;
                        end else
                            rvalid     = 1'b1;     
                                
                    end
                end  // PRE_FETCH
                
                READ_FROM_RAM:
                begin
                    if(ram_data_rvalid_i) begin
                        instr_rvalid = 1'b1;
                        new_rdata    = 1'b1;
                        ALGO_en      = 1'b1;
                        if(en_i) begin
                            start_search = 1'b1;
                            gnt_o        = 1'b1;
                            DP_addr      = addr_i;
                            current_tag  = addr_i[31:LOG2_NUM_WORDS + 2];
                            if(last_tag == current_tag) begin
                                access_counter = access_counter_d + 1;
                                if(access_counter == (RAM_WIDTH/32)/2+1) begin
                                    ram_addr_o = {current_tag + 1, {LOG2_NUM_WORDS + 2{1'b0}}};
                                    ram_en_o   = 1'b1;
                                end
                            end else 
                                access_counter = 'b0;
                            if(DP_miss) begin
                                ram_addr_o = addr_i;
                                ram_en_o     = 1'b1;
                            end else
                                rvalid     = 1'b1;     
                                    
                        end
                    end
                end  // READ_FROM_RAM
                
                WAIT_FOR_GNT: ram_en_o = 1'b1;
            endcase
        end  // if( !bypass_en_i )
    end
    
    always_comb begin
        NS = CS;
        if( bypass_en_i )  
            NS = IDLE;
        else begin
            case(CS)
                IDLE: 
                begin
                    if(access_counter == (RAM_WIDTH/32)/2+1)
                        NS = PRE_FETCH;
                    else if(DP_miss) begin
                        if(ram_data_gnt_i)
                            NS = READ_FROM_RAM;
                        else
                            NS = WAIT_FOR_GNT;
                    end
                end
                
                PRE_FETCH: 
                begin
                    if(DP_miss) begin
                        if(ram_data_gnt_i)
                            NS = READ_FROM_RAM;
                        else
                            NS = WAIT_FOR_GNT;
                    end else
                        NS = IDLE;
                end
                
                WAIT_FOR_GNT:
                begin
                    if(ram_data_gnt_i)
                        NS = READ_FROM_RAM;
                end
       
                READ_FROM_RAM:  
                begin
                    if(ram_data_rvalid_i) begin
                        NS = IDLE;
                        if(DP_miss) begin
                            if(ram_data_gnt_i)
                                NS = READ_FROM_RAM;
                            else
                                NS = WAIT_FOR_GNT;
                        end
                    end
                end
                
                default: NS = IDLE;
            endcase
        end  // if( !bypass_en_i )
    end
    
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            CS               <= IDLE; 
            DP_addr_d        <= 32'b0;
            ram_raddr_d      <= 32'b0;
            rvalid_d         <= 1'b0;
            last_tag         <= 'b0;
            access_counter_d <= 'b0;
        end
        else begin
            CS               <= NS;
            DP_addr_d        <= DP_addr;        
            ram_raddr_d      <= ram_addr_o;        
            rvalid_d         <= rvalid;        
            last_tag         <= current_tag;        
            access_counter_d <= access_counter;
        end
    end
endmodule
