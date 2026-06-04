
//===============================================
//         Start Header Num 4
//===============================================

   //APB I/F
   apbpaddr_o,            // [I] {ADD_DW}b
   apbpenable_o,          // [I] 1b
   apbpsel_o,             // [I] 1b
   apbpwdata_o,           // [I] 32b
   apbpwrite_o,           // [I] 1b
   apbpready_i,           // [O] 1b
   apbpslverr_i,           // [O] 1b
   apbprdata_i,            // [O] 32b

   //APB Error Support
   apb_sgn_clk,
   apb_sgn_rst_n,
   apb_clk_dis
//===============================================
//         End Header Num 4
//===============================================
	
);
