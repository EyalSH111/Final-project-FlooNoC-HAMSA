
interface di_ctrl_interface(

  input pi_id_ready        ,  // primary issue id ready
  input pi_ex_ready        ,  // primary issue ex ready
  input pi_wb_ready        ,  // primary issue wb ready
  input pi_branch_in_ex    ,  // primary issue branch in execution  
  input pi_data_misaligned    // primary issue LSU data misaligned , Impact registers FW mechanism 

) ;

 
logic i2_load_stall_cond ; // stall required due to I2 reg accessing active PI load (from ear;ier cycle/s)
logic pi_load_stall ;      // PI detected load/stall condition, should propohate to I2
logic pi_branch_taken_ex ; 
logic pi_unusal_state_prevent_di ;  // Prevent DI at some PI special  transition states.
logic pi_unusal_state_kill_di ;     // Kill DI in-progress for some PI special transition state.
logic pi_halt_id ;
        
modport pi (
 input  i2_load_stall_cond,
 output pi_load_stall,
 output pi_branch_taken_ex,
 output pi_unusal_state_prevent_di,    
 output pi_unusal_state_kill_di, 
 output pi_halt_id
); 

modport i2 (
 input  pi_id_ready,
 input  pi_ex_ready,
 input  pi_wb_ready,
 input  pi_branch_in_ex,
 input  pi_data_misaligned,
 input  pi_branch_taken_ex,
 output i2_load_stall_cond,
 input  pi_load_stall,
 input  pi_unusal_state_prevent_di,
 input  pi_unusal_state_kill_di,
 input  pi_halt_id 
); 

endinterface


