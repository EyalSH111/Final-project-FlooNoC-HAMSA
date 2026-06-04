
interface di_regfile_interface() ;

    
   // issue2 Read port a2
   logic [4:0]  raddr_a2 ;
   logic [31:0] rdata_a2 ;
   
   // issue2 Read port b2
   logic [4:0]  raddr_b2 ;
   logic [31:0] rdata_b2 ;
   
   // issue port Write port b2
   logic [4:0]  waddr_b2 ;
   logic [31:0] wdata_b2 ;
   logic        we_b2 ;
   
      
  
  modport pi (  
  
   // issue2 Read port a2
   input  raddr_a2,
   output rdata_a2,
   
   // issue2 Read port b2
   input  raddr_b2,
   output rdata_b2,
   
   // issue port Write port b2
   input  waddr_b2,
   input  wdata_b2,
   input  we_b2
   
  );
  
 
  modport i2 (  
   
   // issue2 Read port a2
   output  raddr_a2 ,
   input   rdata_a2 ,
   
   // issue2 Read port b2
   output  raddr_b2,
   input   rdata_b2,
   
   // issue port Write port b2
   output  waddr_b2,
   output  wdata_b2,
   output  we_b2
     
  ); 
  
endinterface


