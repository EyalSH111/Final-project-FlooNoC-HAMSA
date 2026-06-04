///////////////////////////////////////////////////////////////////////
//        _____        _           _____           _                 //
//       |  __ \      | |         / ____|         | |                //
//       | |  | | __ _| |_ __ _  | |     __ _  ___| |__   ___        //
//       | |  | |/ _` | __/ _` | | |    / _` |/ __| '_ \ / _ \       //
//       | |__| | (_| | || (_| | | |___| (_| | (__| | | |  __/       //
//       |_____/ \__,_|\__\__,_|  \_____\__,_|\___|_| |_|\___|       //
//                                                                   //
///////////////////////////////////////////////////////////////////////


module data_cache_L0 
#( 
    parameter RAM_SIZE        = 32768,                // in bytes
    parameter ADDR_WIDTH      = $clog2(RAM_SIZE) + 1, // one bit more than necessary, for boot rom
    parameter DATA_RAM_WIDTH  = 128,
    parameter DATA_CORE_WIDTH = 32,
    parameter LOG2_NUM_BLKS   = 3,                    // how many bits (log2) required to represent the rows
    parameter MAX_DIRTY       = 2                     // (2**LOG2_NUM_BLKS)/2  // the max number of dirty block allowed befor starting write them to memory
)
(
    input  logic                          clk           , 
    input  logic                          rst_n         ,

    // RAM mux interconnection - towards core                        
    input  logic                          en_i          ,
    input  logic [ADDR_WIDTH-1:0]         addr_i        ,
    input  logic [DATA_CORE_WIDTH-1:0]    wdata_i       ,
    output logic [DATA_CORE_WIDTH-1:0]    rdata_o       ,  
    input  logic                          we_i          ,
    input  logic [DATA_CORE_WIDTH/8-1:0]  be_i          ,
    input  logic                          bypass_en_i   ,
    output logic                          rvalid_o      ,
    output logic                          gnt_o         ,

    // SP RAM interconnection
    output logic                          ram_en_o      ,   
    output logic [31:0]                   ram_addr_o    , 
    output logic [DATA_RAM_WIDTH-1:0]     ram_wdata_o   ,
    output logic                          ram_we_o      ,   
    output logic [(DATA_RAM_WIDTH/8)-1:0] ram_be_o      ,
    input  logic [DATA_RAM_WIDTH-1:0]     ram_rdata_i   ,
    input  logic                          ram_data_gnt_i,
    input  logic                          ram_rvalid_i 
);           
      
    
    // datapath
    logic                          start_search;
    logic                          write_to_mem; // set if there are more dirty lines than MAX_DIRTY     
    logic                          rvalid_ram_read; 
    
    logic                          DP_rvalid;     
    logic                          DP_miss;
    logic [31:0]                   DP_addr;
    logic [31:0]                   DP_addr_d;   
    logic [DATA_CORE_WIDTH-1:0]    DP_wdata;  
    logic [DATA_CORE_WIDTH-1:0]    DP_wdata_d;  
    logic [DATA_CORE_WIDTH/8-1:0]  DP_be;  
    logic [DATA_CORE_WIDTH/8-1:0]  DP_be_d;  
    logic                          DP_we;
    logic                          DP_we_d; 
    
    // algo             
    logic                          algo_ready;  // not in use
    logic                          ALGO_en;  
    
    // datapath - algo            
    logic [LOG2_NUM_BLKS - 1:0]    algo_rplc_line_idx; 
    logic [LOG2_NUM_BLKS - 1:0]    last_used_line;    
    
    // ram
    logic [31:0]                   ram_raddr_d; 
    logic [31:0]                   ram_raddr_dd; 
    logic [31:0]                   ram_waddr; 
    logic [31:0]                   ram_waddr_d; 
    logic [31:0]                   ram_waddr_dd; 
    logic [DATA_RAM_WIDTH-1:0]     ram_wdata;
    logic [DATA_RAM_WIDTH-1:0]     ram_wdata_d;
    logic                          ram_we;   
    logic [(DATA_RAM_WIDTH/8)-1:0] ram_be;
    logic [(DATA_RAM_WIDTH/8)-1:0] ram_be_d;
    
    logic                          rvalid;
    logic                          rvalid_d;
    logic [LOG2_NUM_BLKS-1:0]      dirty_num;   // number of dirty blocks in the cache
    logic                          ready_to_write;
                                  
    enum logic [2:0] { IDLE, READ_FROM_RAM, WRITE_B4_READ, WRITE_B4_READ_WAIT_GNT, 
                                     READ_FROM_RAM_WAIT_GNT, WRITE_TO_RAM_WAIT_GNT} CS, NS;

    data_cache_datapath  
    #(
        .DATA_RAM_WIDTH  ( DATA_RAM_WIDTH  ),
        .DATA_CORE_WIDTH ( DATA_CORE_WIDTH ),
        .LOG2_NUM_BLKS   ( LOG2_NUM_BLKS   )
    )
    cache_datapath_i 
    (
        .clk            ( clk                ), 
        .rst_n          ( rst_n              ), 
                                                
        .search_i       ( start_search       ),        
        .data_rvalid_i  ( rvalid_ram_read    ),                                               
                                                 
        .we_i           ( DP_we              ),          
        .be_i           ( DP_be              ),          
        .core_data_i    ( DP_wdata           ), 
        .addr_i         ( DP_addr            ),        
        .mem_data_i     ( ram_rdata_i        ),   
        .rplc_line_idx_i( algo_rplc_line_idx ), 
                                                
        .miss_o         ( DP_miss            ), 
        .data_o         ( rdata_o            ), 
        .data_line_o    ( last_used_line     ), 
                                                
        .write_to_mem_i ( write_to_mem       ), 
        .we_o           ( ram_we             ), 
        .be_o           ( ram_be             ), 
        .waddr_o        ( ram_waddr          ), 
        .write_data_o   ( ram_wdata          ), 
                                                
        .dirty_num_o    ( dirty_num          ),       
        .write_ready_i  ( ready_to_write     )       
    );                          
    
    cache_algo      
    #(
        .LOG2_NUM_BLKS    ( LOG2_NUM_BLKS       )
    )
    cache_algo_i 
    (
        .clk              ( clk                 ), 
        .rst_n            ( rst_n               ), 
                          
        .en_i             ( ALGO_en             ), 
        .last_used_line_i ( last_used_line      ), 
                                                
        .rplc_line_idx_o  ( algo_rplc_line_idx  ),   
        .ready_o          ( algo_ready          )                    
    );                           

    assign ram_addr_o = ((ram_we == 1'b1) || 
                         (CS == WRITE_B4_READ_WAIT_GNT) || 
                         (CS == WRITE_TO_RAM_WAIT_GNT))? ram_waddr_d : ram_raddr_d; 
          
    assign rvalid_o = rvalid_d | rvalid_ram_read;
    assign ready_to_write = (CS == IDLE) || (CS == READ_FROM_RAM);
    always @(*) begin
        start_search    = 1'b0;
        rvalid_ram_read = 1'b0;
        ram_en_o        = 1'b0;
        rvalid          = 1'b0;
        write_to_mem    = 1'b0;
        ALGO_en         = 1'b0;
        gnt_o           = 1'b0;
        DP_addr         = DP_addr_d;
        DP_wdata        = DP_wdata_d;
        DP_we           = DP_we_d;
        DP_be           = DP_be_d;
        ram_raddr_d     = ram_raddr_dd;  
        ram_waddr_d     = ram_waddr_dd;  
        ram_wdata_o     = ram_wdata_d;
        ram_we_o        = 1'b0;   
        ram_be_o        = ram_be_d;
        
        if( !bypass_en_i ) begin    
            case(CS)
                IDLE: begin
                    if((dirty_num > MAX_DIRTY) && ready_to_write)
                        write_to_mem = 1'b1;
                    if(en_i) begin                    
                        DP_addr      = addr_i;
                        DP_wdata     = wdata_i;
                        DP_we        = we_i;
                        DP_be        = be_i;
                        start_search = 1'b1;
                        gnt_o        = 1'b1;
                        if(DP_miss) begin
                            ALGO_en     = 1'b1;   // get line index for the new data to come
                            ram_en_o    = 1'b1;
                            ram_raddr_d = addr_i;
                        end else
                            rvalid      = 1'b1;                   
                    end 
                    if(ram_we) begin              // if we write to memory
                        ram_waddr_d = ram_waddr;
                        ram_wdata_o = ram_wdata;
                        ram_we_o    = 1'b1; 
                        ram_be_o    = ram_be; 
                        ram_en_o    = 1'b1;
                    end
                end
                
                WRITE_B4_READ:          ram_en_o = 1'b1;   // we have done the write, now execute read         
                READ_FROM_RAM_WAIT_GNT: ram_en_o = 1'b1;
                WRITE_B4_READ_WAIT_GNT: begin
                    ram_en_o = 1'b1;
                    ram_we_o = 1'b1; 
                end
                WRITE_TO_RAM_WAIT_GNT: begin
                    ram_en_o = 1'b1;
                    ram_we_o = 1'b1; 
                end
                
                READ_FROM_RAM: begin
                    if(dirty_num > MAX_DIRTY && (CS == IDLE || CS == READ_FROM_RAM))
                        write_to_mem = 1'b1;
                        
                    if(ram_rvalid_i) begin
                        rvalid_ram_read  = 1'b1;          
                        if(en_i) begin                    
                            DP_addr      = addr_i;
                            DP_wdata     = wdata_i;
                            DP_we        = we_i;
                            DP_be        = be_i;
                            start_search = 1'b1;
                            gnt_o        = 1'b1;
                            if(DP_miss) begin
                                ALGO_en     = 1'b1; 
                                ram_en_o    = 1'b1;
                                ram_raddr_d = addr_i;
                            end else
                                rvalid      = 1'b1;                   
                        end 
                        if(ram_we) begin
                            ram_waddr_d = ram_waddr;
                            ram_wdata_o = ram_wdata;
                            ram_we_o    = 1'b1; 
                            ram_be_o    = ram_be; 
                            ram_en_o    = 1'b1;
                        end
                    end
                end  // READ_FROM_RAM
            endcase 
        end  // if( !bypass_en_i )
    end
    
    // state
    always_comb begin
        NS = CS;
        if( bypass_en_i )  
            NS = IDLE;
        else begin
            case(CS)
                IDLE: begin
                    if(ram_en_o) // in case of miss or write dirty
                        if(ram_we) begin 
                            if(ram_data_gnt_i) begin
                                if(DP_miss) NS = WRITE_B4_READ;
                                else        NS = IDLE;
                            end else begin
                                if(DP_miss) NS = WRITE_B4_READ_WAIT_GNT;
                                else        NS = WRITE_TO_RAM_WAIT_GNT;
                            end
                        end else begin // we can get here only when DP_miss
                            if(ram_data_gnt_i) NS = READ_FROM_RAM;                       
                            else               NS = READ_FROM_RAM_WAIT_GNT;
                        end
                end           
                
                WRITE_B4_READ: begin
                    if(ram_rvalid_i) begin
                        if(ram_data_gnt_i) NS = READ_FROM_RAM;
                        else               NS = READ_FROM_RAM_WAIT_GNT;
                    end
                end
                
                WRITE_B4_READ_WAIT_GNT: if(ram_data_gnt_i) NS = WRITE_B4_READ;
                READ_FROM_RAM_WAIT_GNT: if(ram_data_gnt_i) NS = READ_FROM_RAM;
                WRITE_TO_RAM_WAIT_GNT:  if(ram_data_gnt_i) NS = IDLE;
                
                READ_FROM_RAM: begin
                    if(ram_rvalid_i) begin
                        NS = IDLE;
                        if(ram_en_o) begin 
                            if(ram_we) begin // we need to write to memory before read from it 
                                if(ram_data_gnt_i) begin
                                    if(DP_miss)    NS = WRITE_B4_READ;
                                    else           NS = IDLE;
                                end else begin
                                    if(DP_miss)    NS = WRITE_B4_READ_WAIT_GNT;
                                    else           NS = WRITE_TO_RAM_WAIT_GNT;
                                end
                            end else begin
                                if(ram_data_gnt_i) NS = READ_FROM_RAM;                       
                                else               NS = READ_FROM_RAM_WAIT_GNT;
                            end
                        end
                    end
                end   
                default: NS = IDLE;
            endcase
        end  // if( !bypass_en_i )
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            CS           <= IDLE; 
            DP_addr_d    <= 32'b0;
            DP_wdata_d   <= 'b0;
            DP_we_d      <= 'b0;
            DP_be_d      <= 'b0;
            rvalid_d     <= 1'b0;
            
            ram_raddr_dd <= 32'b0; 
            ram_waddr_dd <= 32'b0;
            ram_wdata_d  <= 'b0;   
            ram_be_d     <= 'b0;
        end
        else begin
            CS           <= NS;
            DP_addr_d    <= DP_addr;        
            DP_wdata_d   <= DP_wdata;
            DP_we_d      <= DP_we;
            DP_be_d      <= DP_be;
            rvalid_d     <= rvalid;
            
            ram_raddr_dd <= ram_raddr_d;
            ram_waddr_dd <= ram_waddr_d;
            ram_wdata_d  <= ram_wdata_o;  
            ram_be_d     <= ram_be_o;             
        end            
    end
endmodule
