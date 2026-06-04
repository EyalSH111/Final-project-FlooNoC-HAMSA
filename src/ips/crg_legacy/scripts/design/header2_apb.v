

//==========================================
//         Start Header Num 2
//==========================================
// System
   input               rf_clk;
   input               hw_reset_n;                  
   input               scan_mode;
	 
   // APB Slave protocol 				
   input [ADD_DW-1:0]  apbpaddr_o;
   input               apbpenable_o;
   input               apbpsel_o;
   input [31:0]        apbpwdata_o;
   input               apbpwrite_o;
   output              apbpready_i;
   output              apbpslverr_i;
   output [31:0]       apbprdata_i;

   // APB Error Support
   input               apb_sgn_clk;
   input               apb_sgn_rst_n;
   input               apb_clk_dis;
      
   //bridge from APB to CBUS
   reg [31:0]          cbus_slv_rdatap;
   wire                cbus_slv_cfg_req;
   wire                cbus_slv_cmd;
   wire  [ADD_DW-1:0]  cbus_slv_address;
   wire  [31:0]        cbus_slv_wdata;

   apb2cbus 
       #(.ADDRW(ADD_DW))                    
  	    I_apb2cbus  (
                      // Outputs
                      .apbpready_i       (apbpready_i),
                      .apbpslverr_i      (apbpslverr_i), 
                      .apbprdata_i       (apbprdata_i[31:0]), 
                      .cbus_s_address    (cbus_slv_address[ADD_DW-1:0]), 
                      .cbus_s_bytecnt    (),              
                      .cbus_s_byten      (),              
                      .cbus_s_cmd        (cbus_slv_cmd), 
                      .cbus_s_first      (),              
                      .cbus_s_last       (),              
                      .cbus_s_req        (cbus_slv_cfg_req), 
                      .cbus_s_wdata      (cbus_slv_wdata[31:0]), 
                      // Inputs
                      .apbpaddr_o        (apbpaddr_o[ADD_DW-1:0]), 
                      .apbpenable_o      (apbpenable_o), 
                      .apbpreset_no      (1'b0),          
                      .apbpsel_o         (apbpsel_o), 
                      .apbpwdata_o       (apbpwdata_o[31:0]), 
                      .apbpwrite_o       (apbpwrite_o),
                      .cbus_s_sgn_clk    (apb_sgn_clk),
                      .cbus_s_sgn_rst_n  (apb_sgn_rst_n),
                      .cbus_s_clk_dis    (apb_clk_dis),
                      .cbus_s_clk        (rf_clk),    
                      .cbus_s_rst_n      (hw_reset_n),  
                      .cbus_s_rdatap     (cbus_slv_rdatap[31:0]), 
                      .cbus_s_rresp      (cbus_slv_rresp), 
                      .cbus_s_waccept    (cbus_slv_waccept)); 

   assign wr_pulse = cbus_slv_cfg_req & ~cbus_slv_cmd;
   
   assign rd_pulse = cbus_slv_cfg_req & cbus_slv_cmd;

   assign cbus_slv_waccept = 1'b1;
   assign cbus_slv_rresp   = 1'b1;
   //==========================================
   //         End Header Num 2
   //==========================================

   
