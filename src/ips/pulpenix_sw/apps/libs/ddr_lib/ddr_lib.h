#ifndef __DDR_LIB_H__
#define __DDR_LIB_H__


#define FILE_TO_DDR_BUF_NUM_WORDS 64  // must be multiple of 4
#define FILE_TO_DDR_BUF_NUM_BYTES (FILE_TO_DDR_BUF_NUM_WORDS*4)

char init_ddr();
    
    
void store_to_ddr(volatile unsigned int * soc_start_addr,   // Recommended for performance but not required to be word address aligned
                  volatile unsigned int   ddr_start_addr,   // TODO! Need to Check: Recommended/Must be be 4 words (128b) address aligned
                  int                     num_words,        // Must be multiplication of 4, other wise down-rounded with no warning !
                  char                    do_print);        // do print (for debug)                 


void load_from_ddr(volatile unsigned int * soc_start_addr,   // Recommended for performance but not required to be word address aligned
                   volatile unsigned int   ddr_start_addr,   // TODO! Need to Check: Recommended/Must be be 4 words (128b) address aligned
                   int                     num_words,        // Must be multiplication of 4, other wise down-rounded with no warning !
                   char                    do_print);        // do print (for debug)                 


void ddr_store_from_hex_file (int file_id, 
                              int num_bytes , 
                              unsigned int ddr_addr, 
                              char do_print);


void ddr_dump_to_hex_file (int           file_id, 
                           int           num_bytes , 
                           unsigned int  ddr_addr, 
                           int           num_bytes_per_first_line, 
                           int           num_bytes_per_non_first_line,
                           char          do_print);
  
#endif