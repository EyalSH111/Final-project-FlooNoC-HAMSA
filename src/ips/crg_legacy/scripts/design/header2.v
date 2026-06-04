

//==========================================
//         Start Header Num 2
//==========================================
// System
   input 	 rf_clk;
   input 	 hw_reset_n;                  
   input         scan_mode;
	 
   // CBUS Slave protocol 				
   input 	       cbus_slv_cfg_req_orig;             
   input 	       cbus_slv_cmd_orig;          
   input [ADD_DW-1:0]  cbus_slv_address_orig;  
   input [31:0]        cbus_slv_wdata_orig;              

   // Should be used by SS design if needed
   // Instead of the original CBUS lines
   output 	       cbus_slv_cfg_req_sync;             
   output 	       cbus_slv_cmd_sync;          
   output [ADD_DW-1:0] cbus_slv_address_sync;  
   output [31:0]       cbus_slv_wdata_sync;              
      
   output [31:0] cbus_slv_rdatap;  
   output        cbus_slv_waccept;
   output        cbus_slv_rresp;

   reg [31:0] 	 cbus_slv_rdatap;
   wire          cbus_slv_waccept;
   wire          cbus_slv_rresp;

   // Due to synthesis problems we output waccept/rresp from
   // FFs and use internal CBUS lines to support pulses delayed
   // cycle cases. When First pulse cycle arrives, waccept/rresp
   // is immediately asserted, while next cycle will wait if
   // previous one didn't ended due to GCLK delays


   wire                cbus_slv_cfg_req;
   wire                cbus_slv_cmd;
   wire  [ADD_DW-1:0]  cbus_slv_address;
   wire  [31:0]        cbus_slv_wdata;


   assign cbus_slv_cfg_req =  cbus_slv_cfg_req_orig ;
   assign cbus_slv_cmd     =  cbus_slv_cmd_orig     ;
   assign cbus_slv_address =  cbus_slv_address_orig ;
   assign cbus_slv_wdata   =  cbus_slv_wdata_orig   ;

   assign cbus_slv_cfg_req_sync = cbus_slv_cfg_req_orig;
   assign cbus_slv_cmd_sync     = cbus_slv_cmd_orig;
   assign cbus_slv_address_sync = cbus_slv_address_orig;
   assign cbus_slv_wdata_sync   = cbus_slv_wdata_orig;

   assign wr_pulse = cbus_slv_cfg_req & ~cbus_slv_cmd;
   
   assign rd_pulse = cbus_slv_cfg_req & cbus_slv_cmd;


   assign cbus_slv_waccept = 1'b1;
   assign cbus_slv_rresp   = 1'b1;
   
   //==========================================
   //         End Header Num 2
   //==========================================

   
