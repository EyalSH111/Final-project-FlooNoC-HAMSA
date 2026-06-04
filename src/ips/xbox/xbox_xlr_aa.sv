
module xbox_xlr_aa #(parameter NUM_MEMS=1,LOG2_LINES_PER_MEM=8)  (

  // XBOX memories interface

   // System Clock and Reset
   input clk,
   input rst_n, // asserted when 0

   // Accelerator XBOX mastered memories interface

   output logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] xlr_mem_addr,  //  line address per memory instance
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance
   output logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   input        [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance

   // Command Status Register Interface
   input  [31:0][31:0] host_regs,                   // regs accelerator write data, reflecting registers content as most recently written by SW over APB
   input        [31:0] host_regs_valid_pulse,       // reg written by host (APB) (one per register)
                                                    
   output [31:0][31:0] host_regs_data_out,          // regs accelerator write data,  this is what SW will read when accessing the register
                                                    // provided that the register specific host_regs_valid_out is asserted
   output       [31:0] host_regs_valid_out,         // reg accelerator (one per register)

   input [18:0]        trig_soc_xmem_wr_addr,       // optional trigger, XBOX memory address accessed by SOC (processor/apb)
   input               trig_soc_xmem_wr             // optional trigger, validate actual SOC xmem wr access   
) ;

//---------------------------------------------------------------

// XBOX memories interface types. - DO NOT TOUCH

// Interface to memory of address in case of read and write, 
//  and data with byte enable in case of write.
typedef struct packed {

  logic [LOG2_LINES_PER_MEM-1:0] addr;  //  address per memory instance  
  logic [7:0][31:0] wdata; // 32 bytes write data interface per memory instance
  logic [7:0][3:0]  be;    // byte-enable bute mask per word per instance.
  logic             rd;    // read signal per instance.
  logic             wr;    // write signal per instance.

} to_mem_t ;

// Interface of data returned from memory  
typedef struct packed {logic [7:0][31:0] rdata; } from_mem_t ; // type of read words data returned from memory.

//----------------------------------------------------------------

// Memory access busses.

to_mem_t   [NUM_MEMS-1:0] to_mem ;   // xbox to-memory access pre-sampled ports
from_mem_t [NUM_MEMS-1:0] from_mem ; // xbox from memory access  pre-sampled ports

// by this we 'cast' the xlr_mem_rdata as defined in the interface to the above 'from_mem' vector structure.
assign from_mem = xlr_mem_rdata ; 


//----------------------------------------------------------------

// A system verilog macro to calculate the relative memory address (in hardware terms) of an agreed location with the software
`define SPACE_SIZE_PER_MEM 1024 // Reserved space per memory , regardless of actual available size
`define XBOX_TCM_OFFSET_ADDR(mem_idx,line_idx,word_idx) ((mem_idx*`SPACE_SIZE_PER_MEM*32)+(line_idx*32)+(word_idx*4))

enum {MEM0=0,MEM1=1,MEM2=2,MEM3=3,MEM4=4,MEM5=5,MEM6=6,MEM7=7} mem_idx ; // xbox memories reference indexing

// Enumerated type of different commands code
enum {GEN_CHAR=0    // Handle generation of a single charterer
      // Place to add more commands code.
     } xlrtr_cmd ;

//----------------------------------------------------------------------------------------

// State machine - states

enum {

   IDLE,            // Idle
   READ_CMD,        // Read the Command
   CMD_ACCESS,      // Extra cycle for xlrtr memory access input sample 
   CMD_SAMPLE,      // Extra cycle to sample command before using.
   CMD_SELECT,      // Decide what command to execute.
   READ_FONT_LINE,  // Read next font line
   WRITE_IMG_LINE,  // write next font line 
   FLIP_IMG,        // flip the output image horizontally
   GEN_CHAR_DONE    // Char generation done

}  next_state,            // Next State
   current_state,         // Current State
   mem_access_state,      // The state relevant for current memory access, sampled from current state)
   mem_rdata_state ;      // The state relevant for current memory returned data,  sampled from current state)


// Notice: Since memory access is wrapped by sampling cycles , we sample states as follow
// next-state -> current_state ->  mem_access_state ->  mem_rdata_state 

//-----------------------------------------------------------------------------------------

// Ascii-Art generator setup hardwired parameters, should be exactly same as ascii_art.c

localparam FIRST_LIB_CHAR = "A";
localparam LAST_LIB_CHAR = "Z" ;
localparam NUM_FONTS = (LAST_LIB_CHAR-FIRST_LIB_CHAR+1) ;
localparam NUM_FONTS_CL2 = $clog2(NUM_FONTS); // width of NUM_FONTS range. (clog provied ciel og log)

localparam SPACE = " ";

localparam BYTES_PER_MEM_LINE = 32;         // Number of bytes per XBOX accelerator memory line 
localparam AA_PIX_H =  8;                   // Height of character font.
localparam AA_PIX_H_CL2 = $clog2(AA_PIX_H); // width of AA_PIX_H range. (clog provied ciel of log)

localparam STR_MAX_LEN = 17 ; // DO NOT CHANGE
localparam STR_MAX_LEN_CL2 = $clog2(STR_MAX_LEN); // width of STR_MAX_LEN range. (clog provied ciel og log)

localparam AA_PIX_W = BYTES_PER_MEM_LINE;  // Width of charterer font 
localparam AA_STRIDE = 12; // DO NOT CHANGE

localparam AA_IMG_ARR_MAX_W = (((STR_MAX_LEN-1)*AA_STRIDE)+AA_PIX_W); // Maximum width of the locally generated aa_imgage
localparam AA_IMG_ARR_MAX_W_CL2 = $clog2(AA_IMG_ARR_MAX_W) ;

localparam NUM_BYTES_AA_IMG = (AA_IMG_ARR_MAX_W*AA_PIX_H); // Total number of bytes in the locally generated aa_imgage.
localparam NUM_MEM_LINES_AA_IMG = (NUM_BYTES_AA_IMG/BYTES_PER_MEM_LINE); // Number of mem lines in the locally generated aa_imgage.
localparam NUM_MEM_LINES_AA_IMG_CL2 = $clog2(NUM_MEM_LINES_AA_IMG) ;

localparam NUM_FONT_LIB_LINES = (NUM_FONTS*AA_PIX_H) ;
localparam NUM_FONT_LIB_LINES_CL2 = $clog2(NUM_FONT_LIB_LINES); // width of NUM_FONT_LIB_LINES range. (clog provied ciel og log)

//---------------------------------------------------------------------------------------------

logic [AA_PIX_W-1:0][7:0] font_line_vals ; // sampled copy base font line

logic [7:0] crnt_char ;                   // will hold the command current charterer as provided by the software.
logic [STR_MAX_LEN_CL2-1:0] crnt_char_idx ; // will hold the command current charterer index in string as provided by the software.
logic crnt_char_is_last ; // Indicates last charterer in string.
logic flip_horiz ; // request from SW to flip horizontally the output image

logic [AA_PIX_H_CL2-1:0] font_line_idx;      // holds the line index to work on as provided bu the software.
logic [AA_PIX_H_CL2-1:0] font_line_idx_s1,font_line_idx_s2; // Samples to align with memory access pipe.


logic [AA_PIX_H_CL2-1:0] next_font_line_idx; // holds the next font line index to be sampled.
logic [NUM_FONT_LIB_LINES_CL2-1:0] font_base_line_in_lib ; // first line of font
logic [NUM_FONT_LIB_LINES_CL2-1:0] font_lib_line_addr ; // actual font lin line to read from
logic [NUM_FONTS_CL2-1:0] font_lib_idx ; // relative index of font in the library.

logic [NUM_MEM_LINES_AA_IMG_CL2-1:0] aa_img_line_idx;     // holds the image line index while writing back to mrmory
logic [NUM_MEM_LINES_AA_IMG_CL2-1:0] next_aa_img_line_idx; // holds the image line index next to be sampled.

//----------------------------------------------------------------------------------------

// This 3D packed register array holds the ascii-art image to be built and duped
logic [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] aa_image ; 

// Casting the aa_image to consecutive memory lines (Visually meaningless) 
// To be used for writing back th generated image to the memory.
// It is  guaranteed to have the same byte length.
logic [NUM_MEM_LINES_AA_IMG-1:0][BYTES_PER_MEM_LINE-1:0][7:0] aa_image_cnsctv_lines ; 
assign aa_image_cnsctv_lines = aa_image ; 

//---------------------------------------------------------------------------------------

// The accelerator sense the command address access by the software as a trigger to start acting. 
assign trig_detected = trig_soc_xmem_wr && (trig_soc_xmem_wr_addr==`XBOX_TCM_OFFSET_ADDR(1,255,0)) ; // SW Writing to CMD word in TCM

always_comb begin
    
  to_mem = 0 ; // default all to avoid undesired latches , Notice this zeros the entire packed vector and its structures.
  
  next_state = current_state ; // Default
 
  case (current_state)
 
    IDLE : if (trig_detected) next_state = READ_CMD ;  // Waiting for a trigger event.       
  
    READ_CMD :  begin                 // Event was triggered, issuing a memory access to read the command code and information.
        to_mem[MEM1].addr  = 255 ;    // set line address of memory #1 to line 255 , must be same as in SW
        to_mem[MEM1].rd    = 1 ;      // Assert the read request for memory zero.                  
        next_state = CMD_ACCESS ;     // Go to the access cycle in which the memory access address and rd are sampled.       
     end
     
    CMD_ACCESS: next_state = CMD_SAMPLE ; // Allow the memory input sampling cycle.
    
    CMD_SAMPLE: next_state = CMD_SELECT ; // Allow the access memory output sampling which in this case is the command code

    CMD_SELECT: begin                                         // Handle The command access returned value.
      if (xlrtr_cmd==GEN_CHAR) next_state = READ_FONT_LINE ;  // Generate Charterer
      else next_state = IDLE ;                                // Back to idle on unrecognized command
    end
 
    READ_FONT_LINE: begin                       // Read the base font line fr subtraction.
       to_mem[MEM0].addr = font_lib_line_addr ; // provide the base font line index.
       to_mem[MEM0].rd   = 1 ;                  // Assert the memory read signals. 
       
       if (font_line_idx<(AA_PIX_H-1)) next_state = READ_FONT_LINE ; // keep reading till all font lines are loaded.
       
       
       else if (crnt_char_is_last)  begin       
         if (flip_horiz)  next_state = FLIP_IMG ;    // Flip the output image array before writing back to memory  
         else   next_state = WRITE_IMG_LINE ;        // Start writing image lines.         
       end else next_state = GEN_CHAR_DONE ;         // Return to SW to proceed to next charterer.       
    end
          
    WRITE_IMG_LINE: begin 
       to_mem[MEM1].addr  = aa_img_line_idx ;                        // write back the generated image line (a line on top of the buffers lines)        
       to_mem[MEM1].wr    = 1 ;                                      // assert the memory write signal                                        
       to_mem[MEM1].wdata = aa_image_cnsctv_lines[aa_img_line_idx] ; // provide the generated image line to be written.                                  
       to_mem[MEM1].be    = 32'hffff_ffff  ;                         // write data byte enable (bit per byte)
                                                                               
       next_state  = (aa_img_line_idx==(NUM_MEM_LINES_AA_IMG-1)) ? GEN_CHAR_DONE : WRITE_IMG_LINE ; // keep writing till all lines are stored.
    end
    
    FLIP_IMG: begin                     // Flip image horizontally if requested) 
       if (mem_rdata_state==FLIP_IMG)   // Need to wait till last font line is read and updated  
          next_state = WRITE_IMG_LINE ; // Flipping takes just current cycle, proceed writing image lines.     
    end
    
    GEN_CHAR_DONE: begin                // Report done status.

       to_mem[MEM1].addr    = 255 ;     // write back the status line    
       to_mem[MEM1].wr       =  1 ;     // assert the write signal.                                      
       to_mem[MEM1].wdata[7] =  1 ;     // Indicate done word         
       to_mem[MEM1].be   [7] =  4'hf ;  // byte enable (bit per byte) , writing only to the least significant word
               
       next_state  = IDLE ;      
    end
    
  endcase ;

end // always_comb

// States machine sequential
always @(posedge clk, negedge rst_n) begin
   if (!rst_n) current_state <= 0 ;  // Reset
   else current_state <= next_state ; // Sample
end

//------------------------------------------------------------------------------

// generation and write back signals comb logic

assign font_lib_idx = crnt_char - FIRST_LIB_CHAR ;
assign font_base_line_in_lib = font_lib_idx * AA_PIX_H;  // first line of font
assign font_lib_line_addr = font_base_line_in_lib + font_line_idx ;

always_comb begin
  next_font_line_idx = 0 ; // Default
  if (current_state==READ_FONT_LINE) next_font_line_idx = font_line_idx+1 ; 
end

always_comb begin
  next_aa_img_line_idx = 0 ; // Default
  if (current_state==WRITE_IMG_LINE) next_aa_img_line_idx = aa_img_line_idx+1 ; 
end

//------------------------------------------------------------------------------

// generation and write back signal sequential logic

always @(posedge clk, negedge rst_n) begin
   if (!rst_n) begin
     font_line_idx <= 0 ;
     aa_img_line_idx <= 0 ;
   end else begin
     font_line_idx <= next_font_line_idx ; 
     aa_img_line_idx <= next_aa_img_line_idx ;
   end  
end
   
//------------------------------------------------------------------------------

// xbox memory access input sampling seq logic - DO NOT TOUCH!
always @(posedge clk, negedge rst_n) begin
   if (!rst_n) begin
     xlr_mem_addr   <= 0 ;
     xlr_mem_wdata  <= 0 ;
     xlr_mem_be     <= 0 ;
     xlr_mem_rd     <= 0 ;
     xlr_mem_wr     <= 0 ;
   end else begin
     xlr_mem_addr [MEM1:MEM0] <= {to_mem[MEM1].addr  , to_mem[MEM0].addr  } ;   
     xlr_mem_wdata[MEM1:MEM0] <= {to_mem[MEM1].wdata , to_mem[MEM0].wdata } ;
     xlr_mem_be   [MEM1:MEM0] <= {to_mem[MEM1].be    , to_mem[MEM0].be    } ;
     xlr_mem_rd   [MEM1:MEM0] <= {to_mem[MEM1].rd    , to_mem[MEM0].rd    } ;
     xlr_mem_wr   [MEM1:MEM0] <= {to_mem[MEM1].wr    , to_mem[MEM0].wr    } ;     
   end
end

//--------------------------------------------------------------------------

// Sample memory output

always @(posedge clk, negedge rst_n) begin
     if (!rst_n) begin
        mem_access_state  <= 0 ;
        mem_rdata_state   <= 0 ;
        crnt_char         <= 0 ;         
        crnt_char_idx     <= 0 ;
        crnt_char_is_last <= 0 ;        
        aa_image          <= 0 ;
        flip_horiz        <= 0 ;  
     end
     else begin
        mem_access_state <= current_state ;  
        mem_rdata_state <= mem_access_state ;
        
        font_line_idx_s1 <= font_line_idx ; // Extra ample for access cycle
        font_line_idx_s2 <= font_line_idx_s1 ; // Extra ample for rdata sample      

        if (mem_rdata_state==READ_CMD) begin
            xlrtr_cmd     <= from_mem[MEM1].rdata[0] ;           
            crnt_char     <= from_mem[MEM1].rdata[1][7:0] ;                 // INFO1
            crnt_char_idx <= from_mem[MEM1].rdata[2][STR_MAX_LEN_CL2-1:0] ; // INFO2
            crnt_char_is_last <= from_mem[MEM1].rdata[3][0] ;               // INFO3 
            flip_horiz <= from_mem[MEM1].rdata[4][0] ;                      // INFO4             
        end  
        
        else if (mem_rdata_state==READ_FONT_LINE) begin
             aa_image <= UPDATE_AA_IMG(aa_image, font_line_idx_s2, crnt_char_idx, from_mem[MEM0].rdata) ; 
        end else if ((current_state==FLIP_IMG)&&(mem_rdata_state==FLIP_IMG)) begin // Enter only once when trad and update is completed
             aa_image <= FLIP_HORIZ_AA_IMG(aa_image,crnt_char_idx) ;              
        end             
     end     
end

//--------------------------------------------------------------------------

assign host_regs_data_out  = 0 ; // Currently not in use for this accelerator                      
assign host_regs_valid_out = 0 ; // Currently not in use for this accelerator

//====================================================================================

// Commbinatorial Function

function automatic [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] UPDATE_AA_IMG(

    input [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] aa_image_in,        // aa_image input (before updating)         
    input [AA_PIX_H_CL2-1:0]                        line_idx,           // index of line in font
    input [STR_MAX_LEN_CL2-1:0]                     char_idx,           // index of charterer in input string.
    input [BYTES_PER_MEM_LINE-1:0][7:0]             mem_font_line_rdata // aa_image output (after updating) 
  );
  integer i ;
  logic [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] aa_image_out ; // function output packed array signal 
  aa_image_out = aa_image_in ;  
  
  for (i=0;i<AA_PIX_W;i++) begin
    aa_image_out[line_idx][(char_idx*AA_STRIDE)+i] = mem_font_line_rdata[i] ; 
  end  
    
  return aa_image_out ; // Function returned value
  
endfunction

//------------------------------------------------------------------------------------

function automatic [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] FLIP_HORIZ_AA_IMG(

    input [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] aa_image_in,   // aa_image input (before flipping)         
    input [STR_MAX_LEN_CL2-1:0]                     last_char_idx  // index of the last charterer in input string.
  );
  
  logic [AA_PIX_H-1:0][AA_IMG_ARR_MAX_W-1:0][7:0] aa_image_out ; // function output packed array signal 

  logic [STR_MAX_LEN_CL2-1:0] aa_str_in_len ;
  logic [AA_IMG_ARR_MAX_W_CL2-1:0] num_img_col ;
  
  logic [7:0] left_pix ;
  logic [7:0] right_pix ;  
  
  //$display($time," DEBUG Entered @FLIP_HORIZ_AA_IMG, last_char_idx=%d",last_char_idx) ; // Example of debug statement
  
  aa_str_in_len = last_char_idx+1 ;  // length of sting provided we are at last index.
  
  num_img_col = ((aa_str_in_len-1)*AA_STRIDE)+AA_PIX_W ; // number of columns in image 

  aa_image_out = aa_image_in ; // Default (nothing done) to be over written by below code to be provided
 
  // STUDENT FLIPPING VERILOG FUNCTION CODE HERE
 
  // END OF STUDENT FLIPPING VERILOG FUNCTION CODE
  
  return aa_image_out ; 
    
endfunction

//-------------------------------------------------------------------------------------

endmodule