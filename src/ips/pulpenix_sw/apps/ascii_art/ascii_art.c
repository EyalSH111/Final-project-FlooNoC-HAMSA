#include <ddp23_libs.h> 

/****************************** MACROS ******************************/

// XBOX SW addressing defines
//#define XBOX_APB_BASE_ADDR 0x1A400000   // APB MAPPED accelerator address space ; Not in use for this app
#define XBOX_TCM_BASE_ADDR 0x00200000     // TCM MAPPED(Tightly Coupled Memory)  This is the base address of the accelerators memories from SW perspective.

//Following C macro can be used to easily address a location in the XBOX acceleration memory.
#define LOG2_LINES_PER_MEM 8
#define LINES_PER_MEM (2<<(LOG2_LINES_PER_MEM-1)) // Same as 2 to the power of LOG2_LINES_PER_MEM
#define BYTES_PER_MEM 32
#define SPACE_SIZE_PER_MEM 1024 // Reseved space per meomey , regardles of acrual available size
#define MAX_BYTES_PER_MEM (SPACE_SIZE_PER_MEM*BYTES_PER_MEM)

#define XBOX_TCM_ADDR(mem_idx,line_idx,word_idx) (XBOX_TCM_BASE_ADDR+(mem_idx*MAX_BYTES_PER_MEM)+(line_idx*BYTES_PER_MEM)+(word_idx*4))

 // Addresses of the base and Next char 2D array of multiple lines each of 32 bytes
#define FONTS_LIB_BASE_ADDR ((char *) XBOX_TCM_ADDR(0,0,0))  // Fonts library is loaded to xbox memory 0
#define AA_IMAGE_BASE_ADDR  ((char *) XBOX_TCM_ADDR(1,0,0))  // asci art image will br built into xbox memory 1


// SW-HW TCM CMD/STATUS handshake TCM locations addressing
// NOTICE following must be compliant with the relative used address in the accelerator code, this is NOT automated.

//                                                                    (MEM,LINE,WORD)
#define XLRTR_TCM_CMD_ADDR    ((volatile unsigned int *)    XBOX_TCM_ADDR(1,255,0))  // An agreed memory location to trigger commands to the accelerator. 
#define XLRTR_TCM_CMD_INFO1_ADDR ((volatile unsigned int *) XBOX_TCM_ADDR(1,255,1))  // An agreed memory location to transfer command related information between the software and the hardware.
#define XLRTR_TCM_CMD_INFO2_ADDR ((volatile unsigned int *) XBOX_TCM_ADDR(1,255,2))  // Aditional information if needed
#define XLRTR_TCM_CMD_INFO3_ADDR ((volatile unsigned int *) XBOX_TCM_ADDR(1,255,3))  // Aditional information if needed
#define XLRTR_TCM_CMD_INFO4_ADDR ((volatile unsigned int *) XBOX_TCM_ADDR(1,255,4))  // Aditional information if needed
#define XLRTR_TCM_STATUS_ADDR    ((volatile unsigned int *) XBOX_TCM_ADDR(1,255,7))  // An agreed memory location for the hardware to tell the SW status of execution such as 'done'.

// Few more application specific C macros

// Currently we support only upper case fonts 'A' to 'Z' (continues ASCII code)
#define FIRST_LIB_CHAR ('A')
#define LAST_LIB_CHAR  ('Z')
#define NUM_FONTS (LAST_LIB_CHAR-FIRST_LIB_CHAR+1)
#define SPACE (' ')

#define BYTES_PER_LINE 32         // Number of bytes per XBOX accelerator memory line 
#define AA_PIX_H        8         // Height of character font.
#define AA_PIX_W  BYTES_PER_LINE  // Width of charterer font 

#define BYTES_PER_FONT (AA_PIX_H*AA_PIX_W)             // Total number of bytes per font.  
#define FONTS_LIB_NUM_BYTES (NUM_FONTS*BYTES_PER_FONT) // Total number of bytes in fonts library.

#define STR_MAX_LEN 17 // Do not change !!! this is constrained by xbox hw.
#define AA_STRIDE   12
#define AA_OUT_ARR_MAX_W (((STR_MAX_LEN-1)*AA_STRIDE)+AA_PIX_W) 

//-------------------------------------------------------------------------------------------------------------------

// Enumerated type of different commands code
enum {GEN_CHAR=0,   // Place holder for accelerator command1
      CMD2_TBD=1    // Place holder for accelerator command2
     } xlrtr_cmd ;

//--------------------------------------------------------------------------------------------------------------------

// This function is used to invoke the SOC level (System On Chip) to load the fonts library to xbox memory.

void load_fonts_lib_file(char * dst_addr, char * file_name)  {
    
  bm_printf("Loading fonts library from file %s to address 0x%08x , size=%d bytes\n",file_name,dst_addr,FONTS_LIB_NUM_BYTES) ; 

  unsigned int fonts_lib_file  = bm_fopen_r(file_name) ; // Open the fonts lib input file  
 
  // Starting a SOC level file to memory copy transfer
  bm_start_soc_load_hex_file (fonts_lib_file, FONTS_LIB_NUM_BYTES, (unsigned char *) dst_addr) ; 

  // Polling till transfer completed (SW may also do other stuff mean while)
  int num_loaded = 0 ;
  while (num_loaded==0) num_loaded = bm_check_soc_load_hex_file () ; // num_loaded!=0 indicates completion.
  
  bm_printf("Loaded %d bytes\n",num_loaded) ;

  bm_fclose(fonts_lib_file); // Close image input file.
}

//-------------------------------------------------------------------------------------------------------------------

// Dump generated ascii art to file.

void dump_aa_image(char aa_image[][AA_OUT_ARR_MAX_W], // Image to dump
                   int  image_num_col,                // Number of columns in image
                   char * aa_out_file_name)           // dump file name
{
  bm_printf("Dumping ascii art generated image to file: %s , can take few seconds\n",aa_out_file_name);

  unsigned int aa_out_f = bm_fopen_w(aa_out_file_name) ; // Open the fonts lib input file

  for (int img_row=0;img_row<AA_PIX_H;img_row++) {
    char img_line_str[AA_OUT_ARR_MAX_W] ;
    int col ;// column iterator
    for (col=0;col<image_num_col;col++) img_line_str[col] = aa_image[img_row][col] ; // copy to line string to be printed
    img_line_str[col]=0; // close each line string for printing
    bm_fprintf(aa_out_f,"%s\n",img_line_str) ; // print
  }
 
  bm_fclose(aa_out_f); // Close image output file.
}

//-------------------------------------------------------------------------------------------------------------------

// Take care of a single charterer in the generated image. - NON accelerated

void gen_aa_char_nox (char aa_char,                      // ascii-art input string
                      int  char_idx,                     // Index of charterer within the input string
                      char aa_image[][AA_OUT_ARR_MAX_W], // image array to be built
                      char fonts_lib_arr[][AA_PIX_W],    // fonts library array.
                      char is_last,                      // True if last character of input sting                      
                      char flip_horiz)                   // Optionally flip image horizontally 

{    
    int  font_idx = aa_char - FIRST_LIB_CHAR ;  // Relative font index in font memory  
    char mrg_pix_val ;                          // merged pixel incase of overlap   
   
    // Copy the font to its place in the output image
    
    for (int font_row=0; font_row<AA_PIX_H; font_row++) {    // font row loop
      for (int font_col=0; font_col<AA_PIX_W; font_col++) {  // font column loop

         int font_mem_row = (font_idx*AA_PIX_H) + font_row ;     // font memory row for current font row.
         char font_pix_val = fonts_lib_arr[font_mem_row][font_col] ;  // New font's pixel to write to the image.  
         
         int aa_image_col = (char_idx*AA_STRIDE)+font_col ; // current column in generated image
                    
         // transparency merging with previous pixel if needed
         char at_overlap_mrg = (char_idx>0) && (font_col<(AA_PIX_W-AA_STRIDE)) && (font_pix_val==SPACE) ;
         if (at_overlap_mrg) {
             mrg_pix_val = aa_image[font_row][aa_image_col] ;                 
         }
         else mrg_pix_val = font_pix_val ; // overlapping transparency not applied                
         // Write the pixel to the image        
         aa_image[font_row][aa_image_col] = mrg_pix_val ;         
         //bm_printf("DBG: %d@(%d,%d)\n", mrg_pix_val,font_row,aa_image_col) ;  // Example of debug print         
      } // font row loop
   } // font column loop

    // Handling optional horizontal flip (done after building the non flipped image)
     if (flip_horiz && is_last) {
        int aa_str_in_len = char_idx+1 ;                                             // length of sting provided we are at last index.
        int num_img_col = ((aa_str_in_len-1)*AA_STRIDE)+AA_PIX_W ;                   // number of columns in image 
        for (int img_row=0; img_row<AA_PIX_H; img_row++) {                           // image row loop
          for (int img_col=0; img_col<(num_img_col/2); img_col++) {                  // Swap horizontally pixels per line, iterate till half line.
            char left_pix  = aa_image[img_row][img_col] ;                            // Save left pix 
            char right_pix = aa_image[img_row][(num_img_col-img_col)-1]  ;           // saved right pix

            // swap '/' with '\' ; Notice double backslash used to indicate non escaping backslash. 
            if      (left_pix =='/') left_pix  = '\\' ;   
            else if (left_pix =='\\') left_pix  = '/' ; 
            if      (right_pix=='/') right_pix = '\\' ;   
            else if (right_pix=='\\') right_pix = '/' ;  
            
            aa_image[img_row][img_col] = right_pix;                  // move right to left   
            aa_image[img_row][(num_img_col-img_col)-1] = left_pix ;  // move left to right                 
          }  
        }  
     }


}

//-------------------------------------------------------------------------------------------------------------------

// Take care of a single charterer in the generated image. - HW accelerated

void gen_aa_char_xlr  (char aa_char,     // ascii-art input string
                       int  char_idx,    // Index of charterer within the input string
                       char is_last,     // True if last character of input sting
                       char flip_horiz)  // Optionally flip image horizontally 

{    
    // Make sure xlrtr interface is well supported by ddp23_pnx/src/ips/xbox/xbox_xlr_aa.sv

    *XLRTR_TCM_STATUS_ADDR = 0 ;             // initialize done polling indication // TODO use a real done
    *XLRTR_TCM_CMD_INFO1_ADDR = aa_char;     // provide the charterer    
    *XLRTR_TCM_CMD_INFO2_ADDR = char_idx ;   // provide the charterer index within the string. 
    *XLRTR_TCM_CMD_INFO3_ADDR = is_last ;    // Indicate last char in string (excluding closing zero)
    *XLRTR_TCM_CMD_INFO4_ADDR = flip_horiz ; // Request to flip output image horizontally  
    *XLRTR_TCM_CMD_ADDR  = GEN_CHAR;         // Trigger accelerator , after providing info
    
    char polling_done=0 ;  // Polling to check if accelerator is done             
    while (!polling_done) polling_done = ((*XLRTR_TCM_STATUS_ADDR)!=0);  
}

//-------------------------------------------------------------------------------------------------------------------

// This function check the difference per byte between two lines and updates the compressed vector accordingly.

int gen_aa_image (char * aa_str_in,                   // ascii-art input string
                   char aa_image[][AA_OUT_ARR_MAX_W],  // image array to be built
                   char fonts_lib_arr[][AA_PIX_W],     // fonts library array.
                   char is_xltr_enabled,               // Indicates accelerator or non accelerator mode.
                   char flip_horiz)                    // Optionally flip image horizontally 
{    
    int aa_str_in_len = bm_strlen(aa_str_in) ; // Length of input string (excluding closing zero)    
    //bm_printf("Length of input String: %d\n",aa_str_in_len) ; // Prints must be excluded for performance checking
    
    int image_num_col = ((aa_str_in_len-1)*AA_STRIDE)+AA_PIX_W ; // number of columns in image 
    //bm_printf("Number of columns in output image: %d\n",image_num_col) ; // Prints must be excluded for performance checking 

    for (int char_idx=0; char_idx<aa_str_in_len; char_idx++) { // input char loop, parse charchter in string        

           char is_last = char_idx==(aa_str_in_len-1) ;

           if (is_xltr_enabled) 
             gen_aa_char_xlr(aa_str_in[char_idx],char_idx,is_last,flip_horiz) ; // Call HW accelerator driving function      
               
           else gen_aa_char_nox (            // Call non accelerated fully SW function 
                        aa_str_in[char_idx], // ascii-art input string
                        char_idx,            // Index of charterer within the input string
                        aa_image,            // image array to be built
                        fonts_lib_arr,       // fonts library array. 
                        is_last,             // Indicate last char in string (excluding closing zero)
                        flip_horiz);         // Optionally flip image horizontally                      
                        
    } // input char loop 

    return image_num_col ;
 }

//---------------------------------------------------------------------------------------------


int main() {
    
 bm_printf("\nHELLO DDP24 ASCII ART\n"); 

  int is_xltr_enabled = 0 ; // 1: enabled ; 0: disabled 
  char flip_horiz = 1 ; // Optionally flip image horizontally 

 // Locate the fonts library of multiple lines each of 32 bytes,  cast to 2D-array
  char (* fonts_lib_arr)[BYTES_PER_LINE] = (char **) FONTS_LIB_BASE_ADDR; 

  load_fonts_lib_file((char *)fonts_lib_arr,"app_src_dir/fonts_lib.txt"); 
  
  //Locate the generate aa image, cast to 2D-array
  char (* aa_image)[AA_OUT_ARR_MAX_W] = (char **) AA_IMAGE_BASE_ADDR; 
   
  // Performance time stamping initialize 
  int start_cycle,end_cycle ;            // For performance checking.  
  ENABLE_CYCLE_COUNT ;                   // Enable the cycle counter
  RESET_CYCLE_COUNT  ;                   // Reset counter to ensure 32 bit counter does not wrap in-between start and end.   
  GET_CYCLE_COUNT_START(start_cycle) ;   // Capture the cycle count before the operation.

  char ascii_art_str[STR_MAX_LEN] = "SABABA" ; // Input string, NOTICE! only A to Z upper-case letters supported for now.
  
  int image_num_col = gen_aa_image(ascii_art_str, aa_image, fonts_lib_arr, is_xltr_enabled, flip_horiz) ;

  // Performance time stamping report
  GET_CYCLE_COUNT_END(end_cycle) ;  // Capture the cycle count after the operation.
  int cycle_cnt = end_cycle-start_cycle ; // Calculate consumed cycles.  
  bm_printf("Ascii-Art generation took %d cycles \n\n",cycle_cnt); // Report

  dump_aa_image(aa_image, image_num_col,"../ascii_art_out.txt") ; // Dump generated ascii art to file (to sim folder)

  sim_finish();  // flag to trigger execution termination     
  return 0;
}

