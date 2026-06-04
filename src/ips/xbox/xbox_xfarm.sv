
// ACCELERATORS REGION

module xbox_xfarm #(parameter NUM_MEMS=2,LOG2_LINES_PER_MEM=8)  (

  // XBOX memories interface

   // System Clock and Reset
   input clk,
   input rst_n, // asserted when 0

   // Accelerator XBOX mastered memories interface

   output logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] xlr_mem_addr,  //  address per memory instance  
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance
   output logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   input  logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance

   // Accelerator XBOX TCM other access trigger support
   // Use for SW to optionally trigger an accelerator upon memory update
   input [18:0] soc_xmem_wr_addr,  // XBOX memory address accessed by SOC (processor/apb)
   input        soc_xmem_wr,        // validate actual SOC xmem wr access 
   
   // Command Status Register Interface
   input  [31:0][31:0] host_regs,                   // regs accelerator write data, reflecting registers content as most recently written by SW over APB
   input  [31:0]       host_regs_valid_pulse,       // reg written by host (APB) (one per register)
   
   output logic [31:0][31:0] host_regs_data_out, // regs accelerator write data,  this is what SW will read when accessing the register
                                                 // provided that the register specific xi_regs_valid_out is asserted
   output logic       [31:0] host_regs_valid_out // reg accelerator (one per register)
 ) ;

//------------------------------------------------------------------------------------------

 enum {XLR0=0,XLR1=1,XLR2=2, XLR3=3} xlr_idx ; // Accelerators reference indexing

 localparam NUM_XLRS = 4 ;

//------------------------------------------------------------------------------------------

 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] xi_mem_addr;
 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0] [7:0][31:0] xi_mem_wdata;
 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0]      [31:0] xi_mem_be;
 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0]             xi_mem_rd;
 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0]             xi_mem_rd_s ; // sampled
 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0]             xi_mem_wr;
 logic [NUM_XLRS-1:0] [NUM_MEMS-1:0] [7:0][31:0] xi_mem_rdata;

 logic [NUM_XLRS-1:0]                [31:0][31:0] xi_host_regs;                   
 logic [NUM_XLRS-1:0]                [31:0]       xi_host_regs_valid_pulse;       
 logic [NUM_XLRS-1:0]                [31:0][31:0] xi_host_regs_data_out;                                                               
 logic [NUM_XLRS-1:0]                [31:0]       xi_host_regs_valid_out;                  

//---------------------------------------------------------------------------------------------

 logic [18:0] trig_soc_xmem_wr_addr;  // XBOX memory address accessed by SOC (processor/apb)
 logic        trig_soc_xmem_wr;       // validate the the actual SO xmem wr access 
 
 // Sample trigger
 always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      trig_soc_xmem_wr_addr <= 0 ;
      trig_soc_xmem_wr      <= 0 ;     
    end else begin
      trig_soc_xmem_wr_addr <= soc_xmem_wr_addr ;
      trig_soc_xmem_wr      <= soc_xmem_wr ;        
    end
 end 
  

// ======================  ACCELERATORS INSTANCES ===========================================

xbox_xlr_aa #(.NUM_MEMS(NUM_MEMS),.LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM))  xbox_xlr_aa (   

   .clk   (clk),
   .rst_n (rst_n), 
   .xlr_mem_addr           ( xi_mem_addr                [XLR0] ),
   .xlr_mem_wdata          ( xi_mem_wdata               [XLR0] ),
   .xlr_mem_be             ( xi_mem_be                  [XLR0] ), 
   .xlr_mem_rd             ( xi_mem_rd                  [XLR0] ),
   .xlr_mem_wr             ( xi_mem_wr                  [XLR0] ),
   .xlr_mem_rdata          ( xi_mem_rdata               [XLR0] ),
   .host_regs              ( xi_host_regs               [XLR0] ),
   .host_regs_valid_pulse  ( xi_host_regs_valid_pulse   [XLR0] ),
   .host_regs_data_out     ( xi_host_regs_data_out      [XLR0] ),
   .host_regs_valid_out    ( xi_host_regs_valid_out     [XLR0] ),  
   .trig_soc_xmem_wr_addr  (trig_soc_xmem_wr_addr              ),
   .trig_soc_xmem_wr       (trig_soc_xmem_wr                   )  
 ) ;

//----------------------------------------------------------------------------------------------

xbox_xlr_dmy1 #(.NUM_MEMS(NUM_MEMS),.LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM))  xbox_xlr_dmy1 (   

   .clk   (clk),
   .rst_n (rst_n), 
   .xlr_mem_addr           ( xi_mem_addr                [XLR1] ),
   .xlr_mem_wdata          ( xi_mem_wdata               [XLR1] ),
   .xlr_mem_be             ( xi_mem_be                  [XLR1] ), 
   .xlr_mem_rd             ( xi_mem_rd                  [XLR1] ),
   .xlr_mem_wr             ( xi_mem_wr                  [XLR1] ),
   .xlr_mem_rdata          ( xi_mem_rdata               [XLR1] ),
   .host_regs              ( xi_host_regs               [XLR1] ),
   .host_regs_valid_pulse  ( xi_host_regs_valid_pulse   [XLR1] ),
   .host_regs_data_out     ( xi_host_regs_data_out      [XLR1] ),
   .host_regs_valid_out    ( xi_host_regs_valid_out     [XLR1] ),
   .trig_soc_xmem_wr_addr  (trig_soc_xmem_wr_addr              ),
   .trig_soc_xmem_wr       (trig_soc_xmem_wr                   )     
 ) ;

//----------------------------------------------------------------------------------------------

xbox_xlr_dmy2 #(.NUM_MEMS(NUM_MEMS),.LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM))  xbox_xlr_dmy2 (   
  
   .clk   (clk),
   .rst_n (rst_n), 
   .xlr_mem_addr           ( xi_mem_addr                [XLR2] ),
   .xlr_mem_wdata          ( xi_mem_wdata               [XLR2] ),
   .xlr_mem_be             ( xi_mem_be                  [XLR2] ), 
   .xlr_mem_rd             ( xi_mem_rd                  [XLR2] ),
   .xlr_mem_wr             ( xi_mem_wr                  [XLR2] ),
   .xlr_mem_rdata          ( xi_mem_rdata               [XLR2] ),
   .host_regs              ( xi_host_regs               [XLR2] ),
   .host_regs_valid_pulse  ( xi_host_regs_valid_pulse   [XLR2] ),
   .host_regs_data_out     ( xi_host_regs_data_out      [XLR2] ),
   .host_regs_valid_out    ( xi_host_regs_valid_out     [XLR2] ),
   .trig_soc_xmem_wr_addr  (trig_soc_xmem_wr_addr              ),
   .trig_soc_xmem_wr       (trig_soc_xmem_wr                   )  
   
 ) ;

//----------------------------------------------------------------------------------------------
 
xbox_xlr_dmy3 #(.NUM_MEMS(NUM_MEMS),.LOG2_LINES_PER_MEM(LOG2_LINES_PER_MEM))  xbox_xlr_dmy3 (   
  
   .clk   (clk),
   .rst_n (rst_n), 
   .xlr_mem_addr           ( xi_mem_addr                [XLR3] ),
   .xlr_mem_wdata          ( xi_mem_wdata               [XLR3] ),
   .xlr_mem_be             ( xi_mem_be                  [XLR3] ), 
   .xlr_mem_rd             ( xi_mem_rd                  [XLR3] ),
   .xlr_mem_wr             ( xi_mem_wr                  [XLR3] ),
   .xlr_mem_rdata          ( xi_mem_rdata               [XLR3] ),
   .host_regs              ( xi_host_regs               [XLR3] ),
   .host_regs_valid_pulse  ( xi_host_regs_valid_pulse   [XLR3] ),
   .host_regs_data_out     ( xi_host_regs_data_out      [XLR3] ),
   .host_regs_valid_out    ( xi_host_regs_valid_out     [XLR3] ),
   .trig_soc_xmem_wr_addr  (trig_soc_xmem_wr_addr              ),
   .trig_soc_xmem_wr       (trig_soc_xmem_wr                   )  
   
 ) ;

//----------------------------------------------------------------------------------------------

 
 
// Accelerators memory access muxing

// Currently Strict priority always for the lower index axlerator 
// Diffrent accelerators can access simulteniously diffrent memories.
// In case of simultenious access to same meory the loosing acceleror is access currently ignored
// Currently there is no pending mechanisim, it is managment SW/HW role to avoid damaging conflicts.
// Currenytly the ignored acces id not even notified, that his access has been ignored, but incase of read, will read zero

int xi,mi,ri ; // for loop iterators

 always @(*) begin // MUXING signals from accelerator outputs to memory inputs
 
     for (mi=0; mi<NUM_MEMS; mi=mi+1) begin

        // defalt all outputs to memories ;
        xlr_mem_addr  [mi]  =  0 ;
        xlr_mem_wdata [mi]  =  0 ;
        xlr_mem_be    [mi]  =  0 ;
        xlr_mem_rd    [mi]  =  0 ;
        xlr_mem_wr    [mi]  =  0 ;

        for (xi=NUM_XLRS-1; xi>=0 ; xi=xi-1) begin // lowst index is last in loop to win 

          if  (xi_mem_wr[xi][mi] || xi_mem_rd[xi][mi]) begin
          
           xlr_mem_addr  [mi]  = xi_mem_addr  [xi][mi] ;          
           xlr_mem_wdata [mi]  = xi_mem_wdata [xi][mi] ;
           xlr_mem_be    [mi]  = xi_mem_be    [xi][mi] ;
           xlr_mem_rd    [mi]  = xi_mem_rd    [xi][mi] ;
           xlr_mem_wr    [mi]  = xi_mem_wr    [xi][mi] ; 
           
          end // if
        end // for xi
      end // for mi   
  end // always

 // Sample read 
 always @(posedge clk, negedge rst_n) begin
    if (!rst_n)  xi_mem_rd_s <= 0 ;
     else begin
        for (mi=0; mi<NUM_MEMS; mi=mi+1) begin
          for (xi=NUM_XLRS-1; xi>=0 ; xi=xi-1) xi_mem_rd_s[xi][mi] <= xi_mem_rd[xi][mi] ;
        end ;
     end
 end

// data return demuxing, all accelerators other thean the winning, get zero data in case ignored.
 always @(*) begin // MUXING signals from accelerator outputs to memory inputs 
     for (mi=0; mi<NUM_MEMS; mi=mi+1) begin
        for (xi=NUM_XLRS-1; xi>=0 ; xi=xi-1) begin // lowest index is last in loop to win 
          xi_mem_rdata[xi][mi] = xi_mem_rd_s[xi][mi] ? xlr_mem_rdata[mi] : 0 ;
        end // for xi
     end // for mi
 end // always

//----------------------------------------------------------------------------------------------------

// Regs access muxing , same as memory access, strict priority to lowest indexed XLR
 always @(*) begin
   host_regs_valid_out = 0 ; // default 
   host_regs_data_out = 0 ;  // default  
   for (xi=NUM_XLRS-1; xi>=0 ; xi=xi-1) begin
        xi_host_regs[xi] = host_regs ;  
        xi_host_regs_valid_pulse[xi] = host_regs_valid_pulse ; // currently all xlrtrs see all input pulses 
        for (ri=0;ri<32;ri=ri+1) begin
            if (xi_host_regs_valid_out[xi][ri]) begin
              host_regs_valid_out[ri] = xi_host_regs_valid_out[xi][ri] ;           
              host_regs_data_out[ri]  = xi_host_regs_data_out[xi][ri] ;
            end
        end

   end 
 end

endmodule 
