#include <ddp23_libs.h>

int main() {

  bm_printf("\nHello Accelerator Simple Example #1\n");   

  unsigned int hex_inF     = bm_fopen_r("app_src_dir/hex_in.txt") ;  

  #define VEC_SIZE 4
  unsigned char bytes_vec[VEC_SIZE] ;
  
  bm_load_hex_file (hex_inF,VEC_SIZE,bytes_vec); // load vec1 byte from hex file
  bm_printf("vec1 =    ["); for (int i=0;i<VEC_SIZE;i++) bm_printf("%2x ",bytes_vec[i]); bm_printf("]\n");

  int start_cycle,end_cycle ; 

  //-----------------------------------------------------------------------

  // Count "1" bits in input vector
  int bit_is_one_cnt = 0 ;
  char bit_is_one ;

  ENABLE_CYCLE_COUNT ; // Enable the cycle counter
  RESET_CYCLE_COUNT  ; // Reset counter to ensure 32 bit counter does not wrap in-between start and end. 
  GET_CYCLE_COUNT_START(start_cycle) ;   

  int i,j ; 
  for (i=0;i<VEC_SIZE;i++) 
     for (j=0;j<8;j++) {
       bit_is_one = (((bytes_vec[i]>>j)%2)==1) ;
       if (bit_is_one) bit_is_one_cnt++ ; 
     }

  GET_CYCLE_COUNT_END(end_cycle) ;

  int cycle_cnt = end_cycle-start_cycle ;
  
  bm_printf("count of one bits is %d\n",bit_is_one_cnt); 
  bm_printf("\n\n*** Without acceleration: Took %d cycles to calculate count ***\n\n",cycle_cnt);

  //---------------------------------------------------------------------

  // Now with Accelaration

  #define XBOX_BASE_ADDR 0x1A400000

  // Test Regs Access

  int gpp_reg_idx ;
  volatile unsigned int * gpp_reg_addr ;

  // Write gpp reg #5 
 
  unsigned int gpp_test_val =  *((unsigned int *)bytes_vec) ;
  
  gpp_reg_idx = 5 ;
  gpp_reg_addr =  (volatile unsigned int *)(XBOX_BASE_ADDR+(gpp_reg_idx*4)) ;
  
  bm_printf("Writing %x to gpp_reg %x at address %x\n",gpp_test_val,gpp_reg_idx,gpp_reg_addr) ;
  
  RESET_CYCLE_COUNT  ; // Reset counter to ensure 32 bit counter does not wrap in-between start and end. 
  GET_CYCLE_COUNT_START(start_cycle) ;   

  *gpp_reg_addr  = gpp_test_val ;
  
  // Reading gpp reg 6
  
  gpp_reg_idx = 6 ;
  gpp_reg_addr = (volatile unsigned int *) (XBOX_BASE_ADDR+(gpp_reg_idx*4)) ;

  bit_is_one_cnt = *gpp_reg_addr ;

  GET_CYCLE_COUNT_END(end_cycle) ;
  cycle_cnt = end_cycle-start_cycle ;
  bm_printf("count of one bits is %d\n",bit_is_one_cnt); 
  bm_printf("\n\n*** With acceleration: Took %d cycles to calculate count ***\n\n",cycle_cnt);

  //---------------------------------------------------------------------

  bm_fclose(hex_inF);  

  sim_finish();  
  return 0;
}
