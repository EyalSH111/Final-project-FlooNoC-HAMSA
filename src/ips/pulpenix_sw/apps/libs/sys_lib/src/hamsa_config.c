#include <hamsa_config.h>

void hamsa_config(int di_en, int data_cache_en, int instr_cache_en) {
   int csr_value = di_en + (data_cache_en<<1) + (instr_cache_en<<2);
   asm("csrrw x0, 2048, %0": : "r" ( csr_value ) );
}

void uaslr_config(int ualsr_en, int rng, int start_address) {
   rng = ualsr_en + (rng<<2);
   asm("csrrw x0, 2049, %0": : "r" ( rng ));
   if(start_address < 0) {
      asm("csrrw x0, 2050, ra"); //set our return address as the starting point for where we randomize
   }
}

