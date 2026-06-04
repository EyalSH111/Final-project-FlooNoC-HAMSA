

interface di_pfb_interface() ;

    // Prefetch buffer interface
    
    logic [3:0][31:0] instr_buf  ;                   // quad word buffer content
    logic [2:0]       pi_hw_idx ;                    // current primary issue , instruction half-word index within the buffer    
                                                     // Notice there are 8 16bit half-words within the 128 line buffer     
    logic             pi_hw_idx_valid ;              // indexed primary word is valid
    logic             i2_instr_allocate_ok ;         // issue2 detected a potential instruction for execution sunjrct to pi validity
    logic             i2_instr_allocated ;           // issue2 detected a valid instruction for execution    
    logic [2:0]       next_potential_hw_idx ;        // potential subject to hwloop, next 16b half-word index within 128b line , after the current DI execution    
    logic [2:0]       next_hw_idx ;                  // actual next 16b half-word index within 128b line , after the current DI execution    
   
    
 //********** primary pfb (pre-fetch-buffer) interface port *****

  // Notice separation per hierarchical level require for Quartos compilation in some cases.
  
  // riscv_orefetch_L0_buffer level
  modport pi (    
   output instr_buf,       
   output pi_hw_idx,   
   output pi_hw_idx_valid, 
   input  i2_instr_allocated,
    input  i2_instr_allocate_ok,  
   input  next_potential_hw_idx,
   input  next_hw_idx               
  );
   
  modport i2 (  
  
   input  instr_buf,  
   input  pi_hw_idx,
   input  pi_hw_idx_valid,
   output i2_instr_allocated,
   output i2_instr_allocate_ok,   
   output next_potential_hw_idx,   
   output next_hw_idx     
  ); 
  
endinterface


