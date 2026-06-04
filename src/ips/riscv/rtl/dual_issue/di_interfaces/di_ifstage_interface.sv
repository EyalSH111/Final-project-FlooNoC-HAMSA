
 interface di_ifstage_interface() ;

    // Prefetch buffer interface
    
    logic             primary_if_valid ;             // primary IF stager is valid (i.e not stalled , propagating to primary ID   
    logic [31:0]      pi_fetch_addr ;                // primary issue fetch address
    logic [31:0]      pi_instr_decomp ;              // Primary issue decompressed instruction (used also for uncompressed coded instruction  
    logic             i2_instr_allocated ;           // issue2 detected a valid instruction for execution
    logic             pi_hwlp_di_prevent_cond ;      // some hwloop condition prevents allocation

      
  //riscv_if_stage level 

  // Notice separation per hierarchical level require for Quartos limited sv interface/modport support.

  modport pi (
   output primary_if_valid,   
   output pi_fetch_addr,          
   output pi_instr_decomp,
   input  i2_instr_allocated,
   output pi_hwlp_di_prevent_cond          
  );
   
  modport i2 (  
   // issue2 prefeth buffer interface   
   input  primary_if_valid, 
   input  pi_fetch_addr,
   input  pi_instr_decomp,
   output i2_instr_allocated,
   input  pi_hwlp_di_prevent_cond               
  ); 
  
endinterface


