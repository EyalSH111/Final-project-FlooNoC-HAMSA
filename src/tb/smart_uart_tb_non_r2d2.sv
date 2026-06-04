
// Smart uart tb including file access from running C code but without R2D2 support
// Also compliant with FPGA/DDP pyshell terminal and file access SW interface.
// This means same compiled code images with file access can run both in this mode and in the FPGA.


//`include "pulpenix_defines.v"
`include "smart_uart_defines.sv"
`include "fpgnix_address_map.vh"

`define VERILOG_STDIN  32'h8000_0000 // Verilog pre-opened
`define VERILOG_STDOUT 32'h8000_0002 // Verilog pre-opened

interface uart_bus
  #(
    parameter BAUDRATE = `DEFAULT_BAUDRATE,
    parameter PARITY_EN = `DEFAULT_PARITY_EN,
    parameter NUM_SELECTABLE_UARTS = 1   
    )
  (
 
    input  [NUM_SELECTABLE_UARTS-1:0] uart_rx,
    output [NUM_SELECTABLE_UARTS-1:0] uart_tx,

    input  logic rx_en
  );
  timeunit      1ns;
  timeprecision 1ps;



  logic  rx,tx ; 
  logic [$clog2(NUM_SELECTABLE_UARTS):0] selected_uart = 0 ;  

  assign rx = (NUM_SELECTABLE_UARTS==1) ? uart_rx[0] : uart_rx[selected_uart] ;
  
  generate
    genvar u;
    for (u=0;u<NUM_SELECTABLE_UARTS;u++) begin : seluart
      assign uart_tx[u]  = ((NUM_SELECTABLE_UARTS==1)||(selected_uart==u)) ? tx : 1 ; 
    end
  endgenerate
   
  localparam BIT_PERIOD_NS = (1000000000.0/BAUDRATE);  // = 8680555.6 for BAUDRATE=115200
  localparam HALF_BIT_PERIOD_NS = (500000000.0/BAUDRATE); 

//----------------------------------------------------- 

//FPGA pyshell compatible interface  
 localparam NUM_FILES = 10 ;
 integer file_ptr_idx_aloc = 0 ;
 
 int file_ptrs[NUM_FILES-1:0] ; 
 string file_names[NUM_FILES-1:0] ;
 bit file_in_use[NUM_FILES-1:0] ;  // Mark when file is in use and not available
 
 integer file_int = -1 ;
 
 bit done = 0 ;

 string pyshell_str                     = "$pyshell"                  ;
 string pyshell_quit_str                = "$pyshell quit"             ; 
 string pyshell_openFile_str            = "$pyshell openFile"         ;
 string pyshell_closeFile_str           = "$pyshell closeFile"        ;
 string pyshell_fgets_str               = "$pyshell fgets"            ;
 string pyshell_fgetln_str              = "$pyshell fgetln"           ; 
 string pyshell_fgetHexF_str            = "$pyshell fgetHexF"         ;
 string pyshell_socStartFgetHexF_str    = "$pyshell socStartFgetHexF" ;
 string pyshell_socCheckFgetHexF_str    = "$pyshell socCheckFgetHexF" ;
 string pyshell_socStartFputHexF_str    = "$pyshell socStartFputHexF" ;
 string pyshell_socCheckFputHexF_str    = "$pyshell socCheckFputHexF" ; 
 string pyshell_accessFile_str          = "$pyshell accessFile"       ;
 string pyshell_sysCall_str             = "$pyshell sysCall"          ;
 string pyshell_set_xmem_mode_oel_str    = "$pyshell setXmemMoel"     ;

//------------------------------------------------------
   
  logic [7:0]       character,ms_char,ls_char;
  string            string_from_uart = "" ;
  logic             parity;
  integer           string_from_uart_head_charnum = 0 ;
  logic [31:0]      dpi_ret_val ;  // dpi tasks return values
  
  
  logic [8*8-1:0]  ready_string      = {"Ready> "} ;
  logic [8*8-1:0]  gdb_ready_string  = {"gdb-rdy"} ;  // String from Core , indicating it is ready for gdb debug commumication
  logic [14*8-1:0]  string_from_uart_head = "" ;
  logic prompt_active = 0 ; 
  logic su_cmd_rsp_active = 0 ;
  logic gdb_ready = 0 ;  
  logic su_uart_gateway_msg_on = 0 ;

  int su_rsp_byte_cnt = 0 ;  // response to smart uart terminal 
  int dpi_rsp_byte_cnt = 0 ; // response to mem_dpi.svh
  int pyshell_cmd_start_idx = 0 ;
  
  string pyshell_cmd_str ; 
  
  logic xmem_mode_oel_on = 0 ; // XBOX tcm odd-even memories per line address mode (such as used by mannix)
   
  initial begin  
    //$display("\n\nUART TB INFO: BAUDRATE = %d , CLK_DIV_CNTR =%d" , BAUDRATE ,CLK_DIV_CNTR) ;
    $display("\n\n%t UART TB INFO: BAUDRATE = %d" , $time, BAUDRATE) ;
`ifdef SIM_UART_SPEED_FACTOR
    $display("Notice SIM_UART_SPEED_FACTOR=%d, Simulation pseudo Baudrate = %d",`SIM_UART_SPEED_FACTOR,`SIM_UART_SPEED_FACTOR*BAUDRATE) ;
`endif
    
    tx   = 1'b1;
    
    for (int i=0;i<NUM_FILES;i++) file_in_use[i]  = 0 ;
  end

  // Capture RX characters

  always
  begin
    if (rx_en)
    begin
      @(negedge rx);
      #(HALF_BIT_PERIOD_NS) ;
      for (int i=0;i<=7;i++)
      begin
        #BIT_PERIOD_NS character[i] = rx;
      end

      if(PARITY_EN == 1)
      begin
        // check parity
        #BIT_PERIOD_NS parity = rx;

        for (int i=7;i>=0;i--)
        begin
          parity = character[i] ^ parity;
        end

        if(parity == 1'b1)
        begin
          $display("VERILOG UART_TB: Parity error detected");
        end
      end

      // STOP BIT
      #BIT_PERIOD_NS;
      
      if (character==`SU_CMD_RSP) su_cmd_rsp_active = 1 ;


      if (su_cmd_rsp_active && (su_rsp_byte_cnt>0)) begin
         if (su_rsp_byte_cnt<5) begin   // skip SU_CMD_RSP byte
           if (character[7:4]<=9) ms_char = "0" + character[7:4]  ;
           else ms_char = "a" +(character[7:4] - 10) ;
           $write("%c", ms_char);
           if (character[3:0]<=9) ls_char = "0" + character[3:0]  ;
           else ls_char = "a" +(character[3:0] - 10) ;                            
           $write("%c", ls_char);
         end 
         su_rsp_byte_cnt =  su_rsp_byte_cnt-1 ;
         if (su_rsp_byte_cnt==0) su_cmd_rsp_active = 0 ;
      end  
      else if (su_cmd_rsp_active && (dpi_rsp_byte_cnt>0)) begin 
         if (dpi_rsp_byte_cnt<5) dpi_ret_val[(dpi_rsp_byte_cnt-1)*8 +: 8] = character ; // skip SU_CMD_RSP byte
         dpi_rsp_byte_cnt =  dpi_rsp_byte_cnt-1 ; 
         if (dpi_rsp_byte_cnt==0) su_cmd_rsp_active = 0 ;         
      end 

      else begin  // print apb uart

           if (su_uart_gateway_msg_on && (character==8'h0A)) begin
              su_uart_gateway_msg_on = 0 ;      
              send_char(8'h0A) ; // to return control to SW menu via apb            
           end
                                     
           string_from_uart =  {string_from_uart,string'(character)} ;   
             
           string_from_uart_head[(12-string_from_uart_head_charnum)*8 +: 8] = character;
              
           if (string_from_uart_head==ready_string) begin
             prompt_active = 1 ; 
             string_from_uart_head = "";
           end
           
           if (string_from_uart_head==gdb_ready_string) begin // Indicate core is ready for debug
             gdb_ready = 1 ; 
             string_from_uart_head = "";
             $write("\n");
           end
           
           
           if (contains(string_from_uart_head,"$sim_finish") >= 0) begin
               $display("\n--- FINISH ---");
               $finish();
           end
           
           if (contains(string_from_uart_head,"$sim_stop") >= 0) begin
               $display("\n--- STOP --- (resuming simulation might not work)");
               $stop();
           end
           
                      
           if ((character == 8'h0A) ||  (string_from_uart_head_charnum == 254)) // end of line / line feed or max. chars reached
           begin

            pyshell_cmd_start_idx = contains(string_from_uart, pyshell_str) ;

               if (pyshell_cmd_start_idx>=0) begin
                 pyshell_cmd_str = string_from_uart.substr(pyshell_cmd_start_idx,string_from_uart.len()-1) ;
                 string_from_uart = string_from_uart.substr(0,pyshell_cmd_start_idx-1) ;
               end 

               if (pyshell_cmd_start_idx!=0)  begin                                                                            
    		      if (file_int==-1) 
    		       $write("%s",string_from_uart) ; 
    		      else begin
    		       $fwrite(file_ptrs[file_int],"%s",string_from_uart) ; 
                  end                                                               
               end 

               if (pyshell_cmd_start_idx!=-1) pyshell_cmd_handling(pyshell_cmd_str) ;
                              
               string_from_uart = "";
               string_from_uart_head_charnum = 0 ;
                              
           end else begin
            string_from_uart_head_charnum = string_from_uart_head_charnum + 1;            
           end

           
      end // print apb uart      
    end  // rx_en
    
    else  
    begin
      string_from_uart_head_charnum = 0;
      string_from_uart = "";
      #10;
    end
  end // always 
  
  // Send Terminal input to DUT 
  logic [7:0] c ;  
  logic su_msg_on = 0 ;
  logic su_cmd_identified = 0 ; 
  logic ui_cmd_identified = 0 ;   
  logic [31:0] su_arg_word ;
  integer tb_su_cmd_str_idx = 0 ;
  logic [(2*8)-1:0] tb_su_cmd_str ;
  integer nibble_idx = 0 ;
  integer byte_idx = 0 ;
  logic dpi_msg_on = 0 ; 
  logic prompt_msg_on = 0 ;    

  
  always @(prompt_active) begin               
     su_msg_on = 0 ;
     su_uart_gateway_msg_on = 0 ;
     su_cmd_identified = 0 ; 
     ui_cmd_identified = 0 ;     
     tb_su_cmd_str_idx = 0 ;
     tb_su_cmd_str = ""  ;
     if (dpi_msg_on) wait (!dpi_msg_on) ; // Avoid collision on tx 
     prompt_msg_on = 1 ;
     while (prompt_active) begin
     
           c = $fgetc(`VERILOG_STDIN) ;  
           
           if (c=="^") begin
              su_msg_on = 1 ;
              continue ;
           end 
           else if (c=="#") su_uart_gateway_msg_on = 1 ;
                                               
           if (!su_msg_on)  send_char(c); // send to apb slave for core to read
           else begin // su_msg_on
               if ((!su_cmd_identified)&&(!ui_cmd_identified)) begin 
                 tb_su_cmd_str[(1-tb_su_cmd_str_idx)*8 +: 8] = c;
                 tb_su_cmd_str_idx++ ;
                   if (c=="w") begin
                    tb_su_cmd_str = "" ;
                    su_cmd_identified = 1 ;
                    send_char(`SU_CMD_WR_WORD); 
                 end
                    if (c=="r") begin
                    tb_su_cmd_str = "" ;
                    su_cmd_identified = 1 ; 
                    su_rsp_byte_cnt = 5 ;       // SU_CMD_RSP byte + data word          
                    send_char(`SU_CMD_RD_WORD); 
                 end 
                 else if (tb_su_cmd_str=="ui") begin  // Multi-Uart support, uart selection
                    tb_su_cmd_str = "" ;
                    ui_cmd_identified = 1 ; 
                    selected_uart = 0 ;
                 end 

               end else if (ui_cmd_identified) begin 
                  if ((c>="0")&&(c<="9")) begin
                     selected_uart = (selected_uart*10) + (c - "0") ;  
                  end
               end else if ((c>="0")&&(c<="9")) begin 
                  su_arg_word[(7-nibble_idx)*4+:4] = (c - "0") ;
                  nibble_idx++;              
               end else if ((c>="a")&&(c<="f")) begin 
                  su_arg_word[(7-nibble_idx)*4+:4] = 10+(c - "a") ; 
                  nibble_idx++;                  
               end else if ((nibble_idx > 0) && ((c==" ")||(c==8'h0A))) begin
                  su_arg_word = su_arg_word >> ((8-nibble_idx)*4) ;
                  for (byte_idx=3;byte_idx>=0;byte_idx--) send_char(su_arg_word[(byte_idx*8) +: 8]);
                  nibble_idx = 0 ;
                  byte_idx = 0 ;                  
               end  
               if (c==8'h0A) begin
                 if (ui_cmd_identified) $display ("Selected test-bench UART port index = %-d",selected_uart);  
                 send_char(c); // return control to prompt
               end  
           end // su_msg_on
                      
                        
           prompt_active = (c!=8'h0A) ; // Return control on line feed
           
           
           if (!prompt_active) prompt_msg_on = 0 ;
     end // while
   end  // always    
  
  task send_char(input logic [7:0] c);

    int i;  

    // start bit
    tx = 1'b0;

    for (i = 0; i < 8; i++) begin
      #(BIT_PERIOD_NS);
      tx = c[i];
    end

    // stop bit
    #(BIT_PERIOD_NS);
    tx = 1'b1;
    #(BIT_PERIOD_NS);
  endtask


// -------- pyshell like handling task  ---------------------


 task pyshell_cmd_handling (string str);

   byte file_int_byte ;
   byte fileNumChar ;     
   int fileNum_StrIdx  ; 

   int fgets_file_int  ;   
   int fgets_file_ptr  ;
   int fgets_str_idx   ;
   string fgets_str    ;

   int fgetln_file_int  ;   
   int fgetln_file_ptr  ;
   int fgetln_str_idx   ;
   string fgetln_str   ;   
   
   int fgetHexF_file_int  ;   
   int fgetHexF_file_ptr  ;
   int fgetHexF_str_idx   ;
   string fgetHexF_str    ; 

   int fputHexF_file_int  ;   
   int fputHexF_file_ptr  ;
   int fputHexF_str_idx   ;
   string fputHexF_str    ; 
   
   int left_parenthesis_idx   ;
   int right_parenthesis_idx  ;
   string closeFileIdxStr     ;
   byte closeFileIdxChar      ;
   int closeFileIdx           ;
   byte c, byte_val           ;

   int soc_load_byte_cnt ;
   bit soc_load_done ;
   bit soc_load_comment_on ;
   
   int soc_store_byte_cnt ;
   int bytes_per_store_line_cnt;
   bit soc_store_done ;
    
   integer sys_task_code ;
  
  if (str.substr(0,pyshell_quit_str.len()-1)==pyshell_quit_str) begin // stop simulation on pyshell quit

             $write("$pyshell quitApp() triggred by SW , stopping simulation\n");
             $finish() ;

//-------------------------------------------------------------------------------------------------

   end  else if (str.substr(0,pyshell_openFile_str.len()-1)==pyshell_openFile_str)  begin
   // Handling $pyshell openFile

             automatic int first_quot_idx ;
             automatic int second_quot_idx  ;
             automatic string fileName ;
             automatic byte open_type_char ;
             automatic int fi ;           
             
             first_quot_idx =  str_find_char (.str(str),.start_idx(0),.c("\"")) ;
             second_quot_idx =  str_find_char (.str(str),.start_idx(first_quot_idx+1),.c("\"")) ;
             fileName = str.substr(first_quot_idx+1,second_quot_idx-1)  ;
             open_type_char = str.getc(second_quot_idx+3) ;
             
             for (fi=0;fi<NUM_FILES;fi=fi+1) begin
               if (file_in_use[fi]==0) begin
                 file_ptr_idx_aloc = fi ;
                 file_in_use[fi] = 1 ;
                 break;
               end             
             end
             
             if (fi==NUM_FILES) begin
               $display("TB ERROR: Exceeded number of aallowed simultanious opeen files");
               $finish();
             end             
             
		     //$display("");
		     //$write($time," VERILOG Message: Opening file %s,\"%c\" , TB file index: %d\n",fileName,open_type_char,file_ptr_idx_aloc) ;
		     //$display(""); 
             
             file_names[file_ptr_idx_aloc] = fileName ;              
             if (open_type_char == "w")  
		       file_ptrs[file_ptr_idx_aloc] = $fopen(fileName,"w");
             else  
               file_ptrs[file_ptr_idx_aloc] = $fopen(fileName,"r");
               
             
             if ((file_ptrs[file_ptr_idx_aloc])==0) begin
               $display("VERILOG: File %s was NOT opened successfully",fileName);
               $finish();
             end

             $cast(file_int_byte,file_ptr_idx_aloc);            
             send_char(file_int_byte) ; // Send file Index 
                        
//-------------------------------------------------------------------------------------------------

   end else if (str.substr(0,pyshell_accessFile_str.len()-1)==pyshell_accessFile_str)  begin
     // handling "$pyshell accessFile(idx)\n"

     fileNum_StrIdx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
     fileNumChar   = str.getc(fileNum_StrIdx+1) ;     
          
     if (fileNumChar=="-") file_int = -1 ;
     else  file_int = fileNumChar - "0" ;
     send_char(0) ; // dummy return
     
//-------------------------------------------------------------------------------------------------

  end else if (str.substr(0,pyshell_fgets_str.len()-1)==pyshell_fgets_str)  begin
   // handling pyshell_fgets_str
   
         fileNum_StrIdx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
         fileNumChar   = str.getc(fileNum_StrIdx+1) ;     
              
         if (fileNumChar=="-") begin
            //$display("VERILOG MESSAGE: Illegal read file reference, QUITING") ;
            $stop();

         end else begin
         
            fgets_file_int = fileNumChar - "0" ;             
            fgets_file_ptr = file_ptrs[fgets_file_int] ;
            fgets_str = "" ; 

            sys_task_code = $fscanf(fgets_file_ptr,"%s",fgets_str); // Read till encountering a white-space.
            if (sys_task_code==-1) send_char(8'hFF) ;   // Indicate EOF           
            else for (fgets_str_idx=0 ; fgets_str_idx <= fgets_str.len()-1 ; fgets_str_idx++) begin       
              send_char(fgets_str.getc(fgets_str_idx)) ; 
            end  // for        
            send_char(0) ; // to close string (line treated as string)          

        end


//-------------------------------------------------------------------------------------------------

   end else if (str.substr(0,pyshell_fgetln_str.len()-1)==pyshell_fgetln_str)  begin
   // handling pyshell_fgetln_str
   
         fileNum_StrIdx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
         fileNumChar   = str.getc(fileNum_StrIdx+1) ;     
              
         if (fileNumChar=="-") begin
            //$display("VERILOG MESSAGE: Illegal read file reference, QUITING") ;
            $stop();

         end else begin
         

            fgetln_file_int = fileNumChar - "0" ;             
            fgetln_file_ptr = file_ptrs[fgetln_file_int] ;
            done = 0 ;
            fgetln_str = "" ; 

            while (!done) begin
                 if ($feof(fgetln_file_ptr)) begin
                   fgetln_str = {fgetln_str,8'hFF} ;
                   done = 1 ;
                   continue ;
                 end else begin
                     c = $fgetc(fgetln_file_ptr) ;  
                     if (c==13) continue  ; // Attempt to ignore CR , followed by LF (should work for both Linux and Windows)                    
                     fgetln_str = {fgetln_str,c} ;
                     //if ((c==10)||(c==13)) done = 1 ;      // line feed or return ascii
                     if (c==10) done = 1 ;   // assuming LF works best for supporting both Linux and windows when reading files.
                 end
            end // while            

            for (fgetln_str_idx=0 ; fgetln_str_idx <= fgetln_str.len()-1 ; fgetln_str_idx++) begin       
              send_char(fgetln_str.getc(fgetln_str_idx)) ; 
            end  // for        
            send_char(0) ; // to close string (line treated as string)          

        end

//-------------------------------------------------------------------------------------------------

   end else if (str.substr(0,pyshell_fgetHexF_str.len()-1)==pyshell_fgetHexF_str)  begin
   // handling pyshell_fgetHexF_str

         automatic string numBytesStr ;
         automatic int numBytesStr_i0  ;
         automatic int numBytesStr_i1  ;
         automatic int numBytes  ;
         automatic int load_byte_cnt ;
      
         fileNum_StrIdx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
         fileNumChar   = str.getc(fileNum_StrIdx+1) ;

         numBytesStr_i0 =  str_find_char (.str(str),.start_idx(0),.c(","));
         numBytesStr_i1 =  str_find_char (.str(str),.start_idx(0),.c(")"));
         numBytesStr =  str.substr(numBytesStr_i0+1,numBytesStr_i1-1) ; 
         $sscanf(numBytesStr, "%d", numBytes);
                  
            
         if (fileNumChar=="-") begin
            // $display("VERILOG MESSAGE: Illegal read file reference, QUITING") ;
            $stop();        
        
         end else begin
        
            fgetHexF_file_int = fileNumChar - "0" ;             
            fgetHexF_file_ptr = file_ptrs[fgetHexF_file_int] ;
            done = 0 ;
            load_byte_cnt = 0 ;
            
            //$display("Verilog TB: Requested to deliver %d bytes from file %s",numBytes,file_names[fgetHexF_file_ptr]) ;
        
            while (!done) begin
                 if ($feof(fgetHexF_file_ptr)) begin
                   send_char(8'hFF) ; // EOF/DONE
                   done = 1 ;
                   continue ;
                 end else begin
                    sys_task_code = $fscanf(fgetHexF_file_ptr,"%s",fgetHexF_str); 

                    if (  ((fgetHexF_str[0]>="0")&&(fgetHexF_str[0]<="9"))
                        ||((fgetHexF_str[0]>="a")&&(fgetHexF_str[0]<="f"))
                        ||((fgetHexF_str[0]>="A")&&(fgetHexF_str[0]<="F")))                                        
                    begin
                     
                      if (fgetHexF_str.len()==1) send_char("0") ; // add single digit leading zero                              
                      send_char(fgetHexF_str[0]) ;          
                      if (fgetHexF_str.len() > 1) send_char(fgetHexF_str[1]) ;              
                      if (fgetHexF_str.len() > 2) begin
                         $display("TB Error fgetHexF can read only byte values 0 to ff ; got hex value string %s ; quitting",fgetHexF_str);
                         $finish()  ;   
                      end
                    
                      load_byte_cnt = load_byte_cnt+1 ;
                      if (((load_byte_cnt%1000)==0)&&(load_byte_cnt!=0)) $display($time," Verilog TB: delivered %d bytes .....",load_byte_cnt);
                      if (load_byte_cnt==numBytes) begin
                       done = 1 ;
                       send_char(8'hFF) ; // EOF/DONE
                      end
                    end                       
                 end
            end // while            
         end
      
//--------------------------------------------------------------------------------------------------

   end  else if (str.substr(0,pyshell_socStartFgetHexF_str.len()-1)==pyshell_socStartFgetHexF_str)  begin

   // handling socStartFgetHexF_str
   
   // BACK DOOR LOAD TO: fpgnix_tb.fpgnix.msystem.core_region_i.data_mem.alt16384x32.altera_sram_i.altsyncram_component.m_default.altsyncram_inst.mem_data[0:16383]

         automatic string numBytesStr ;
         automatic string bufAddrStr ;         
         automatic int comma1_idx  ;
         automatic int comma2_idx  ;         
         automatic int rightp_idx  ;
         automatic int numBytes  ;
         automatic int bufAddr ;
         automatic int byteAddr ;         
         automatic int ramAddr ; 

         automatic int mem_128b_line_addr ;
         automatic int mem_x64_inst_idx ;
         automatic int mem_x64_byte_idx ;
         
         automatic byte fgetHexF_val ;
         automatic logic [31:0] data_word ;         
         automatic logic [63:0] data_64b_word ;         
         automatic logic [255:0] data_xbox_mem_line ;  

         automatic logic [7:0] test_next_char ;
         automatic string dummy_str ;
                                
         fileNum_StrIdx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
         fileNumChar   = str.getc(fileNum_StrIdx+1) ;

         comma1_idx = str_find_char (.str(str),.start_idx(0),.c(","));
         comma2_idx = str_find_char (.str(str),.start_idx(comma1_idx+1),.c(","));
         rightp_idx = str_find_char (.str(str),.start_idx(0),.c(")")) ;
         
         numBytesStr =  str.substr(comma1_idx+1,comma2_idx-1) ; 
         $sscanf(numBytesStr, "%d", numBytes);
                 
         bufAddrStr =  str.substr(comma2_idx+1,rightp_idx-1) ; 
         $sscanf(bufAddrStr, "%h", bufAddr);       
         if (fileNumChar=="-") begin
            $stop();        
        
         end else begin
        
            fgetHexF_file_int = fileNumChar - "0" ;             
            fgetHexF_file_ptr = file_ptrs[fgetHexF_file_int] ;
            soc_load_done = 0 ;
            soc_load_byte_cnt = 0 ;
            
            // Initial byte addr
            if (bufAddr inside {[`MIN_XCORE_DMEM:`MAX_XCORE_DMEM]}) // TCM data memory access
               byteAddr = bufAddr- `MIN_XCORE_DMEM ; 
            else if (bufAddr inside {[`MIN_XBOX_TCM_DMEM:`MAX_XBOX_TCM_DMEM]}) 
               byteAddr = bufAddr-`MIN_XBOX_TCM_DMEM ;                            
                      
            while (!soc_load_done) begin
                 if ($feof(fgetHexF_file_ptr)) begin
                   send_char(8'hFF) ; // EOF/DONE
                   soc_load_done = 1 ;
                   continue ;
                 end else begin 

                    // Check comment indication, read and ignore till end of line
                    test_next_char = $fgetc(fgetHexF_file_ptr) ;
                    while (test_next_char<=32) test_next_char = $fgetc(fgetHexF_file_ptr) ; // Skip all potential white spaces                   
                    if (test_next_char=="#") begin                                         
                      sys_task_code = $fgets(dummy_str,fgetHexF_file_ptr); // Ignore till end of line
                      continue ;
                    end else begin
                     $ungetc(test_next_char,fgetHexF_file_ptr) ; // push back to stream the test char.
                    end
                 
                    sys_task_code = $fscanf(fgetHexF_file_ptr,"%h",fgetHexF_val);
                    
                    //$display("DBG TB fgetHexF_val = %h",fgetHexF_val);
                                       
                    test_next_char = $fgetc(fgetHexF_file_ptr) ;
                    while (test_next_char<=32) test_next_char = $fgetc(fgetHexF_file_ptr) ; // Skip all potential white spaces 
                    if (test_next_char=="#") begin                    
                      // Comment indicated not at beginning of line, read and ignore till end of line
                      sys_task_code = $fgets(dummy_str,fgetHexF_file_ptr);
                    end else $ungetc(test_next_char,fgetHexF_file_ptr) ; // push back to stream the test char.
                                                      
                    if (bufAddr inside {[`MIN_XCORE_DMEM:`MAX_XCORE_DMEM]}) begin // TCM data memory access (non xbox)
                    
                       ramAddr = byteAddr/4 ;
                       data_word = fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.core_region_i.data_mem.alt49152x32.altera_sram_i.altsyncram_component.m_default.altsyncram_inst.mem_data[ramAddr] ;
                       data_word[8*(byteAddr%4)+:8] = fgetHexF_val ;
                       
                       //$display("DBG TB byteAddr=%h ; ramAddr=%h ; data_word=%h",byteAddr,ramAddr,data_word); 
                       
                       fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.core_region_i.data_mem.alt49152x32.altera_sram_i.altsyncram_component.m_default.altsyncram_inst.mem_data[ramAddr] = data_word ;

                   end else if (bufAddr inside {[`MIN_XBOX_TCM_DMEM:`MAX_XBOX_TCM_DMEM]}) begin  // xbox as tcm memory load                          
                        xbox_tcm_load_byte(byteAddr , fgetHexF_val);
            
                    end else begin
                     $display("ERROR smart_uart_tb_non_r2d2.sv : pyshell_socStartFgetHexF address %08x out of supported range",bufAddr) ;
                    end
                    
                    byteAddr = byteAddr+1 ;
                    soc_load_byte_cnt = soc_load_byte_cnt+1 ;
                      if (soc_load_byte_cnt==numBytes) begin
                       soc_load_done = 1 ;
                      end                      
                 end
            end // while            
         end

//--------------------------------------------------------------------------------------------------


   end  else if (str.substr(0,pyshell_socCheckFgetHexF_str.len()-1)==pyshell_socCheckFgetHexF_str)  begin

        if (soc_load_done)  begin
            automatic string soc_load_byte_cnt_str = "";
            automatic int sld_str_idx ;
            $sformat(soc_load_byte_cnt_str,"%x",soc_load_byte_cnt);
            for (sld_str_idx=0 ; sld_str_idx < soc_load_byte_cnt_str.len() ; sld_str_idx++) 
               send_char(soc_load_byte_cnt_str.getc(sld_str_idx)) ; 
        end 
        send_char(8'hff) ;

//--------------------------------------------------------------------------------------------------


   end  else if (str.substr(0,pyshell_socStartFputHexF_str.len()-1)==pyshell_socStartFputHexF_str)  begin

   // handling socStartFputHexF_str
   
   // BACK DOOR STORE FROM: fpgnix_tb.fpgnix.msystem.core_region_i.data_mem.alt16384x32.altera_sram_i.altsyncram_component.m_default.altsyncram_inst.mem_data[0:16383]

         automatic string numBytesStr ;
         automatic string numBytesPerLineStr ;
         automatic string bufAddrStr ;         
         automatic int comma1_idx  ;
         automatic int comma2_idx  ;   
         automatic int comma3_idx  ;            
         automatic int rightp_idx  ;
         automatic int numBytes  ;
         automatic int numBytsPerLine ;
         automatic int bufAddr ;
         automatic int byteAddr ;         
         automatic int ramAddr ; 

         automatic int mem_128b_line_addr ;
         automatic int mem_x64_inst_idx ;
         automatic int mem_x64_byte_idx ;
         
         automatic byte fputHexF_val ;
         automatic logic [31:0] data_word ;         
         automatic logic [63:0] data_64b_word ;         
         automatic logic [255:0] data_xbox_mem_line ;          
           
         fileNum_StrIdx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
         fileNumChar   = str.getc(fileNum_StrIdx+1) ;

         comma1_idx = str_find_char (.str(str),.start_idx(0),.c(","));
         comma2_idx = str_find_char (.str(str),.start_idx(comma1_idx+1),.c(","));
         comma3_idx = str_find_char (.str(str),.start_idx(comma2_idx+1),.c(","));
         rightp_idx = str_find_char (.str(str),.start_idx(0),.c(")")) ;
         
         numBytesStr =  str.substr(comma1_idx+1,comma2_idx-1) ; 
         $sscanf(numBytesStr, "%d", numBytes);
 
         numBytesPerLineStr =  str.substr(comma2_idx+1,comma3_idx-1) ; 
         $sscanf(numBytesPerLineStr, "%d", numBytsPerLine);
 
         bufAddrStr =  str.substr(comma3_idx+1,rightp_idx-1) ; 
         $sscanf(bufAddrStr, "%h", bufAddr);       
         if (fileNumChar=="-") begin
            $stop();        
        
         end else begin
        
            fputHexF_file_int = fileNumChar - "0" ;             
            fputHexF_file_ptr = file_ptrs[fputHexF_file_int] ;
            soc_store_done = 0 ;
            soc_store_byte_cnt = 0 ;
            bytes_per_store_line_cnt = 0 ;
            
            // Initial byte addr
            if (bufAddr inside {[`MIN_XCORE_DMEM:`MAX_XCORE_DMEM]}) // TCM data memory access
               byteAddr = bufAddr- `MIN_XCORE_DMEM ; 
            else if (bufAddr inside {[`MIN_XBOX_TCM_DMEM:`MAX_XBOX_TCM_DMEM]}) 
               byteAddr = bufAddr-`MIN_XBOX_TCM_DMEM ;                            

          
            while (!soc_store_done) begin
                                                                           
                if (bufAddr inside {[`MIN_XCORE_DMEM:`MAX_XCORE_DMEM]}) begin // TCM data memory access (non xbox)
                
                   ramAddr = byteAddr/4 ;
                   data_word = fpgnix_tb.fpgnix.vqm_msystem_wrap.msystem.core_region_i.data_mem.alt49152x32.altera_sram_i.altsyncram_component.m_default.altsyncram_inst.mem_data[ramAddr] ;
                   fputHexF_val = data_word[8*(byteAddr%4)+:8]  ;
                   
                end else if (bufAddr inside {[`MIN_XBOX_TCM_DMEM:`MAX_XBOX_TCM_DMEM]}) begin  // xbox as tcm memory load                          
                    xbox_tcm_get_byte(byteAddr , fputHexF_val);
            
                end else begin
                 $display("ERROR smart_uart_tb_non_r2d2.sv : pyshell_socStartFputHexF address %08x out of supported range",bufAddr) ;
                end
                
                $fwrite(fputHexF_file_ptr,"%h",fputHexF_val) ;
                soc_store_byte_cnt ++ ; 
                bytes_per_store_line_cnt ++ ; 
                
                if (bytes_per_store_line_cnt==numBytsPerLine)  begin                    
                   $fwrite(fputHexF_file_ptr,"\n") ;
                   bytes_per_store_line_cnt = 0 ;                       
                end                    
                else $fwrite(fputHexF_file_ptr," ") ;
                
                byteAddr = byteAddr+1 ;               
                
                  if (soc_store_byte_cnt==numBytes) begin
                   soc_store_done = 1 ;
                  end                      

            end // while            

         end

//--------------------------------------------------------------------------------------------------

   end  else if (str.substr(0,pyshell_socCheckFputHexF_str.len()-1)==pyshell_socCheckFputHexF_str)  begin

        if (soc_store_done)  begin
            automatic string soc_store_byte_cnt_str ;
            automatic int sld_str_idx ;
            $sformat(soc_store_byte_cnt_str,"%x",soc_store_byte_cnt);
            for (sld_str_idx=0 ; sld_str_idx < soc_store_byte_cnt_str.len() ; sld_str_idx++) 
               send_char(soc_store_byte_cnt_str.getc(sld_str_idx)) ; 
        end 
        send_char(8'hff) ;

//--------------------------------------------------------------------------------------------------

   end  else if (str.substr(0,pyshell_closeFile_str.len()-1)==pyshell_closeFile_str)  begin
   // handling "$pyshell $pyshell closeFile ...
             
         automatic int left_parenthesis_idx ;
         automatic int right_parenthesis_idx ;
         
         left_parenthesis_idx =  str_find_char (.str(str),.start_idx(0),.c("(")) ;
         right_parenthesis_idx =  str_find_char (.str(str),.start_idx(left_parenthesis_idx+1),.c(")")) ;
         closeFileIdxStr = str.substr(left_parenthesis_idx+1,right_parenthesis_idx-1)  ;
         closeFileIdxChar   = closeFileIdxStr.getc(0)  ;
         closeFileIdx   =  closeFileIdxChar - "0" ;
         
         $fclose(file_ptrs[closeFileIdx]);
         file_in_use[closeFileIdx] = 0 ; // Mark as Free
         send_char(0) ; // dummy return 


//--------------------------------------------------------------------------------------------------

   
  end else if (str.substr(0,pyshell_sysCall_str.len()-1)==pyshell_sysCall_str)  begin
  
         // handling pyshell_sysCall_str


         automatic string sysCmdStr ;
         
         automatic int left_quote_idx ;
         automatic int right_quote_idx ;
                          
         left_quote_idx =  str_find_char (.str(str),.start_idx(0),.c("\"")) ;
         right_quote_idx =  str_find_char (.str(str),.start_idx(left_quote_idx+1),.c("\"")) ;
                 
         sysCmdStr = str.substr(left_quote_idx+1,right_quote_idx-1)  ;
         $display("TB: System Call executing %s",sysCmdStr);        
         $system(sysCmdStr) ;
              
//--------------------------------------------------------------------------------------------------

   
  end else if (str.substr(0,pyshell_set_xmem_mode_oel_str.len()-1)==pyshell_set_xmem_mode_oel_str)  begin
  
         // handling pyshell_set_xmem_mode_oel_str
         xmem_mode_oel_on = 1 ;
         $display("TB: Switched to XBOX Memories Odd-Even Line Mode");                     
  end


 endtask

//--------------------------------------------------------------

 function int str_find_char (string str , int start_idx , byte c) ;

   for (int i=start_idx;i<=str.len();i++) 
     if (str[i]==c) return i ;
   return -1 ;

 endfunction  

//--------------------------------------------------------------


function int contains(string a, string b);
  // checks if string A contains string B
  // returnd index or -2 if not found
  int len_a;
  int len_b;
  len_a = a.len();
  len_b = b.len();
  //$display("a (%s) len %d -- b (%s) len %d", a, len_a, b, len_b);
  for( int i=0; i<len_a; i++) begin
    if(a.substr(i,i+len_b-1) == b)
         return i;
  end
  return -1;
endfunction

//------------------------------------------------------------------------

task xbox_tcm_load_byte(input [18:0] addr, input [7:0] val);
 
  int xbox_mem_idx            ;   // Index of memory in mannix functional terms (in LEO2 there are only two memories thus byte_addr[5] determines odd or even per 256b (32B) line.
  int xbox_ram_line_addr ;
  logic [255:0] xbox_ram_line_data ;
  
  int do_print  ;
  do_print = 0 ;
  if (do_print) $display("task mannix_xbox_tcm_load_byte addr=%-d, val=%02x",addr,val);   
  
  if (!xmem_mode_oel_on) begin // Default mode
    xbox_mem_idx = addr[18:15]  ;  // Regardless of actual size , each memory instance has 1K lines space , each 32 bytes
    xbox_ram_line_addr = (addr/32) - 1024*xbox_mem_idx ; // 32 byte per line
  end else begin  // Switched to XBOX Memories Mode to odd-even-line
    xbox_mem_idx = addr[5]  ;  // Currently only two XBOX memories supported selected per 32B line odd/even address
    xbox_ram_line_addr = addr/(32*2); // line address , either odd or even.
  end  
    
  case (xbox_mem_idx) // NEED TO MANUALLY ADJUST MEM TYPE AND ADD A CASE PER INSTANCE UP TO xbox.NUM_MEMS in case changed 
   0 : xbox_ram_line_data  = fpgnix_tb.fpgnix.xbox.xbox_mfarm.mem_inst[0].lpi.sp_ram_be.altsyncram_component.m_default.altsyncram_inst.mem_data[xbox_ram_line_addr] ;
   1 : xbox_ram_line_data  = fpgnix_tb.fpgnix.xbox.xbox_mfarm.mem_inst[1].lpi.sp_ram_be.altsyncram_component.m_default.altsyncram_inst.mem_data[xbox_ram_line_addr] ;
  endcase

  xbox_ram_line_data[8*(addr%32)+:8] = val ;
 
  case (xbox_mem_idx) // NEED TO MANUALLY  ADJUST MEM TYPE AND ADD A CASE PER INSTANCE UP TO xbox.NUM_MEMS in case changed from 2
    0 : fpgnix_tb.fpgnix.xbox.xbox_mfarm.mem_inst[0].lpi.sp_ram_be.altsyncram_component.m_default.altsyncram_inst.mem_data[xbox_ram_line_addr] = xbox_ram_line_data ;
    1 : fpgnix_tb.fpgnix.xbox.xbox_mfarm.mem_inst[1].lpi.sp_ram_be.altsyncram_component.m_default.altsyncram_inst.mem_data[xbox_ram_line_addr] = xbox_ram_line_data ;    
  endcase 
endtask

//-------------------------------------------------------------------------


task xbox_tcm_get_byte(input [18:0] addr, output [7:0] val);
 
  int xbox_mem_idx            ;   // Index of memory in mannix functional terms (in LEO2 there are only two memories thus byte_addr[5] determines odd or even per 256b (32B) line.
  int xbox_ram_line_addr ;
  logic [255:0] xbox_ram_line_data ;
    
  if (!xmem_mode_oel_on) begin // Default mode
    xbox_mem_idx = addr[18:15]  ;  // Regardless of actual size , each memory instance has 1K lines space , each 32 bytes
    xbox_ram_line_addr = (addr/32) - 1024*xbox_mem_idx ; // 32 byte per line
  end else begin  // Switched to XBOX Memories Mode to odd-even-line
    xbox_mem_idx = addr[5]  ;  // Currently only two XBOX memories supported selected per 32B line odd/even address
    xbox_ram_line_addr = addr/(32*2); // line address , either odd or even.
  end  


  case (xbox_mem_idx) // NEED TO MANUALLY ADJUST MEM TYPE AND ADD A CASE PER INSTANCE UP TO xbox.NUM_MEMS in case changed 
   0 : xbox_ram_line_data  = fpgnix_tb.fpgnix.xbox.xbox_mfarm.mem_inst[0].lpi.sp_ram_be.altsyncram_component.m_default.altsyncram_inst.mem_data[xbox_ram_line_addr] ;
   1 : xbox_ram_line_data  = fpgnix_tb.fpgnix.xbox.xbox_mfarm.mem_inst[1].lpi.sp_ram_be.altsyncram_component.m_default.altsyncram_inst.mem_data[xbox_ram_line_addr] ;
  endcase

  val = xbox_ram_line_data[8*(addr%32)+:8]  ;

  //$display("task mannix_xbox_tcm_get_byte addr=%-d, val=%02x",addr,val);   


endtask

//-------------------------------------------------------------------------



endinterface

                
