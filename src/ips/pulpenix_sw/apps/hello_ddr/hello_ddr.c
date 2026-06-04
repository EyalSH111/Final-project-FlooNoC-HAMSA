#include <ddp23_libs.h>

int main() {
    
 bm_printf("\n\nHELLO DDR STORE/LOAD EXAMPLE\n\n");    
 
 init_ddr() ;
 
  int          store_src_file_id ;
  int          dump_dst_file_id ;
  int          num_bytes = 32*32 ; // 192*256 ;
  unsigned int ddr_addr = 0 ; 

  unsigned int ddr_hex_inF  = bm_fopen_r("app_src_dir/ddr_hex_in.txt") ;  
  unsigned int ddr_hex_outF = bm_fopen_w("app_src_dir/ddr_hex_out.txt") ;
  
  ddr_store_from_hex_file (ddr_hex_inF,num_bytes,ddr_addr);
  
  bm_printf("\nDone ddr_store_from_hex_file\n") ;
    
  int num_dump_bytes_per_first_line = 32 ; 
  int num_dump_bytes_per_non_first_line = 32 ;
  
  ddr_dump_to_hex_file (ddr_hex_outF, num_bytes , ddr_addr, 
                        num_dump_bytes_per_first_line, 
                        num_dump_bytes_per_non_first_line) ;

 return 0;
 
 
}
