
//===============================================
//         Start Header Num 4
//===============================================

   // Arbiter Mux IF
   cbus_slv_cfg_req_orig,          // [I] 1b
   cbus_slv_cmd_orig,              // [I] 1b
   cbus_slv_address_orig,          // [I] 12b
   cbus_slv_wdata_orig,            // [I] 32b
   cbus_slv_cfg_req_sync,          // [O] 1b
   cbus_slv_cmd_sync,              // [O] 1b
   cbus_slv_address_sync,          // [O] 12b
   cbus_slv_wdata_sync,            // [O] 32b
   cbus_slv_waccept,               // [O] 1b
   cbus_slv_rresp,                 // [O] 1b
   cbus_slv_rdatap                 // [O] 32b
// cbus_slv_byten                  // [I] 4b 
//===============================================
//         End Header Num 4
//===============================================
	
);
