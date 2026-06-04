#include <ddp23_libs.h>


#define XBOX_BASE_ADDR 0x1A400000

int main() {

  unsigned int  gpp_test_val ;

  // Test Regs Access

  int gpp_reg_idx ;
  volatile unsigned int * gpp_reg_addr ;

  bm_printf("C MSG: \n\n\n **** HELLO GPP XBOX **** \n\n\n") ;   // bare-metal output to terminal
 
  // Write gpp reg #5 (currently not in use by accelerators)
 
  gpp_test_val = 0xaaaaaaaa ;
  
  gpp_reg_idx = 5 ;
  gpp_reg_addr =  (volatile unsigned int *)(XBOX_BASE_ADDR+(gpp_reg_idx*4)) ;
  
  bm_printf("C MSG: Writing %x to gpp_reg %x at address %x\n",gpp_test_val,gpp_reg_idx,gpp_reg_addr) ;
  
  *gpp_reg_addr  = gpp_test_val ;
  
   // Write gpp reg #6 (currently not in use by accelerators)
  
  gpp_test_val = 0xbbbbbbbb ;
  
  gpp_reg_idx = 6 ;
  gpp_reg_addr =  (volatile unsigned int *)(XBOX_BASE_ADDR+(gpp_reg_idx*4)) ;
  
  bm_printf("C MSG: Writing %x to gpp_reg %x at address %x\n",gpp_test_val,gpp_reg_idx,gpp_reg_addr) ;
  
  *gpp_reg_addr  = gpp_test_val ;

 // Reading gpp reg 5
 
  gpp_reg_idx = 5 ;
  gpp_reg_addr = (volatile unsigned int *) (XBOX_BASE_ADDR+(gpp_reg_idx*4)) ;

  gpp_test_val =   *gpp_reg_addr ;
  
  bm_printf("C MSG: Reading %x from gpp_reg %x at address %x\n",gpp_test_val,gpp_reg_idx,gpp_reg_addr) ; 
  
  // Reading gpp reg 6
  
  gpp_reg_idx = 6 ;
  gpp_reg_addr = (volatile unsigned int *) (XBOX_BASE_ADDR+(gpp_reg_idx*4)) ;

  gpp_test_val =   *gpp_reg_addr ;
  
  bm_printf("C MSG: Reading %x from gpp_reg %x at address %x\n",gpp_test_val,gpp_reg_idx,gpp_reg_addr) ; 

//=======================================================================================================


 // Test XBOX mem Access

 #define XBOX_MEM_BASE_ADDR (XBOX_BASE_ADDR+0x80000)  
  
 #define NUM_32KB_INST 2


 
  for (int mem_idx=0;mem_idx<NUM_32KB_INST;mem_idx++) {
      
       unsigned char * mem_inst_base_addr = (unsigned char *)(XBOX_MEM_BASE_ADDR) + (mem_idx*32*1024) ; // memory inst first byte address
       volatile unsigned int * gpp_xbox_mem_addr ;
 
        // Writing to memory inst first address
        
        gpp_test_val = 0xaaaaaaa0 + mem_idx ; // testing unique value per memory
        
        gpp_xbox_mem_addr = (volatile unsigned int *) (mem_inst_base_addr) ;
        
        bm_printf("C MSG: Writing %08x to xbox mem addr %08x\n",gpp_test_val,gpp_xbox_mem_addr) ;
        
        *gpp_xbox_mem_addr = gpp_test_val ;
        
        // Writing to memory inst last addr  
        
        gpp_test_val = 0xbbbbbbb0 + mem_idx ; // testing unique value per memory
        
        gpp_xbox_mem_addr = (volatile unsigned int *) (mem_inst_base_addr+((32*1024)-4)) ;
        
        bm_printf("C MSG: Writing %08x to xbox mem addr %08x\n",gpp_test_val,gpp_xbox_mem_addr) ;
        
        *gpp_xbox_mem_addr = gpp_test_val ;
        
        // Reading from memory inst first address
        
        gpp_xbox_mem_addr = (volatile unsigned int *) (mem_inst_base_addr) ;
        
        gpp_test_val =   *gpp_xbox_mem_addr ;
        
        bm_printf("C MSG: Reading %08x from xbox memory address %x\n",gpp_test_val,gpp_xbox_mem_addr) ; 
        
        // Reading from mem inst last address 
        
        gpp_xbox_mem_addr = (volatile unsigned int *) (mem_inst_base_addr+((32*1024)-4))  ;
        
        gpp_test_val =   *gpp_xbox_mem_addr ;
        
        bm_printf("C MSG: Reading %08x from xbox memory address %x\n",gpp_test_val,gpp_xbox_mem_addr) ; 
  }        


//=======================================================================================================

  // Finish
   
  sim_finish () ;  // flag to trigger simulation termination
  
  return 0;
}
