#include <ddp23_libs.h> 

/****************************** MACROS ******************************/

// XBOX SW addressing defines
//#define XBOX_APB_BASE_ADDR 0x1A400000   // APB MAPPED accelerator address space ; Not in use for this app
#define XBOX_TCM_BASE_ADDR 0x00200000     // TCM MAPPED(Tightly Coupled Memory)  This is the base address of the accelerators memories from SW perspective.

//Following C macro can be used to easily address a location in the XBOX acceleration memory.
# define LOG2_LINES_PER_MEM 8
# define LINES_PER_MEM (2<<(LOG2_LINES_PER_MEM-1)) // Same as 2 to the power of LOG2_LINES_PER_MEM

// Notice that the actual memory size is determined by the number of lines per memory defined by LOG2_LINES_PER_MEM parameter at xbox.sv
// However regardless of the memory size the occupied address space per memory is 1024*32 bytes (1024 lines of 8 bytes each)
# define XBOX_TCM_ADDR(mem_idx,line_idx,word_idx) (XBOX_TCM_BASE_ADDR+(mem_idx*1024*32)+(line_idx*32)+(word_idx*4))

# define BYTES_PER_LINE 32  // Number of bytes per XBOX accelerator memory line.
#define SUB_IMG_NUM_BYTES 32*32

//----------------------------------------------------------------------------------------------

#define MEM0_BASE ((volatile unsigned int  *)  XBOX_TCM_ADDR(0,0,0)) 
#define MEM1_BASE ((volatile unsigned int  *)  XBOX_TCM_ADDR(1,0,0)) 

//----------------------------------------------------------------------------------------------

// This function is used to invoke the SOC level (System Ob Chip) to load the frame sun image from a text file.

void load_sub_img_file(char * dst_addr, char * file_name)  {
    
  bm_printf("C MSG: Loading sub image from file %s to address 0x%08x\n",file_name,dst_addr) ; 
  //unsigned int img_file  = bm_fopen_r("app_src_dir/bf_sub_img.txt") ; << ERROR
  unsigned int img_file  = bm_fopen_r(file_name) ; // Open the image input file  <<< CORRECT  
 
  // Starting a SOC level file to memory copy transfer
  bm_start_soc_load_hex_file (img_file, SUB_IMG_NUM_BYTES, (unsigned char *) dst_addr) ; 

  // Polling till transfer completed (SW may also do other stuff mean while)
  int num_loaded = 0 ;
  while (num_loaded==0) num_loaded = bm_check_soc_load_hex_file () ; // num_loaded!=0 indicates completion.
  
  bm_printf("C MSG: Loaded %d bytes\n",num_loaded) ;

  bm_fclose(img_file); // Close image input file.
}

//---------------------------------------------------------------------------------------------



int main() {
    
  bm_printf("\nHELLO XBOX TCM ACCESS TEST\n"); 

  unsigned char (* xmem0)[BYTES_PER_LINE] = (unsigned char **) MEM0_BASE; // Base frame 32X32 bytes sub image
  unsigned char (* xmem1)[BYTES_PER_LINE] = (unsigned char **) MEM1_BASE; // Next frame 32X32 bytes sub image

  xmem0 [0][0] = 0xAA ;
  xmem0 [LINES_PER_MEM-1][31] = 0xBB ;

  xmem1 [0][0] = 0xCC ;
  xmem1 [LINES_PER_MEM-1][31] = 0xDD ;
 
  bm_printf("xmem0[0][0]=%02X, xmem0[LINES_PER_MEM-1][31]=%02X, xmem1[0][0]=%02X ,xmem1[LINES_PER_MEM-1][31]=%02X\n",
             xmem0[0][0],      xmem0[LINES_PER_MEM-1][31],      xmem1[0][0],      xmem1[LINES_PER_MEM-1][31]);
 
   
  // Testings xmeme load
  
  load_sub_img_file((char *)xmem0,"app_src_dir/xmem0_data_to_load.txt"); // Load from file to mem0
  load_sub_img_file((char *)xmem1,"app_src_dir/xmem1_data_to_load.txt"); // Load from file to mem1

  bm_printf("xmem0[0][0]=%02x, xmem0[31][31]=%02x, xmem1[0][0]=%02x ,xmem1[31][31]=%02x\n",
             xmem0[0][0],      xmem0[31][31],      xmem1[0][0],      xmem1[31][31]);
  
 
  sim_finish();  // flag to trigger execution termination 
    
 return 0;
 
 
}
