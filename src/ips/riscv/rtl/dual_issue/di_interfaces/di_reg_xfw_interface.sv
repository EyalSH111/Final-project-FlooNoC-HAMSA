
// registers forwarding logic exchange between issues

interface di_reg_xfw_interface() ;
    
   // i2 to pi register forwarding
   
   logic        regfile_we_wb         ;
   logic        regfile_alu_we_fw     ;
   
   logic [31:0] regfile_alu_wdata_fw  ;
   logic [31:0] regfile_wdata_wb      ;
   
   logic  [5:0] regfile_waddr_ex      ;    
   logic  [5:0] regfile_waddr_wb      ; 
   logic  [5:0] regfile_alu_waddr_fw  ; 

    
  modport in (                    // Forwarding from this Issue to other issue
  
   input regfile_we_wb         ,
   input regfile_alu_we_fw     ,
                             
   input regfile_alu_wdata_fw  ,
   input regfile_wdata_wb      ,
                            
   input regfile_waddr_ex      ,    
   input regfile_waddr_wb      , 
   input regfile_alu_waddr_fw       
  );


  modport out (                  // Forwarding from other issue to this issue
  
   output regfile_we_wb         ,
   output regfile_alu_we_fw     ,
                            
   output regfile_alu_wdata_fw  ,
   output regfile_wdata_wb      ,
                               
   output regfile_waddr_ex      ,    
   output regfile_waddr_wb      , 
   output regfile_alu_waddr_fw       
  );




endinterface


