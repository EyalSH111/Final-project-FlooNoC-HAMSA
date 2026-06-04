
// Controlled by remote python tak
// Acting as SPI mater driving PNX spice slave

import sock::*; // To support remote python interface

module py_spi_tb(


    input  spi_sdi,
    output logic spi_csn,    
    output logic spi_sck,    
    output logic spi_sdo 
) ;

  `define SPI_SEMIPERIOD       1000ns    //1Mhz SPI CLK
  `define DELAY_BETWEEN_SPI    1000ns

  int                   num_stim,num_exp,num_cycles,num_err = 0;   // counters for statistics

  logic                 more_stim = 1;


  //----------------------------------------------------
  
  task spi_send_cmd_addr;

    input    [7:0] command;
    input   [31:0] addr;
    
    begin
       for (int i = 7; i >= 0; i--) begin
         spi_sdo = command[i];
         #`SPI_SEMIPERIOD spi_sck = 1;
         #`SPI_SEMIPERIOD spi_sck = 0;
       end
       
       for (int i = 31; i >= 0; i--) begin
         spi_sdo = addr[i];
         #`SPI_SEMIPERIOD spi_sck = 1;
         #`SPI_SEMIPERIOD spi_sck = 0;
       end    
    end

  endtask

  //----------------------------------------------------

  task spi_send_data;

    input   [31:0] data;
    begin

        for (int i = 31; i >= 0; i--)
        begin
          spi_sdo = data[i];
          #`SPI_SEMIPERIOD spi_sck = 1;
          #`SPI_SEMIPERIOD spi_sck = 0;
        end

    end
  endtask
  
  //----------------------------------------------------
  
  task spi_recv_data;
    output  [31:0] data;
    begin

        for (int i = 31; i >= 0; i--)
        begin
          data[i] = spi_sdi;
          #`SPI_SEMIPERIOD spi_sck = 1;
          #`SPI_SEMIPERIOD spi_sck = 0;
        end

    end
  endtask

  //----------------------------------------------------

  task spi_write_reg;

    input    [7:0] command;
    input    [7:0] reg_val;
    begin
    
      spi_csn  = 1'b0;
      #100;

      for (int i = 7; i >= 0; i--)
      begin
        spi_sdo = command[i];
        #`SPI_SEMIPERIOD spi_sck = 1;
        #`SPI_SEMIPERIOD spi_sck = 0;
      end

      for (int i = 7; i >= 0; i--)
      begin
        spi_sdo = reg_val[i];
        #`SPI_SEMIPERIOD spi_sck = 1;
        #`SPI_SEMIPERIOD spi_sck = 0;
      end

      #100 spi_csn  = 1'b1;
      #`DELAY_BETWEEN_SPI;           
    end
         
  endtask

  //----------------------------------------------------

  task spi_write_word;
    input   [31:0] addr;
    input   [31:0] data;
    begin
    
  
      $display($time,"[SPI-SLAVE] spi_write_word task , addr=%h,data=%h",addr,data);      
      spi_csn  = 1'b0;
      #`DELAY_BETWEEN_SPI;
      spi_send_cmd_addr(8'h2, addr);
      spi_send_data(data);
      #1000 spi_csn  = 1'b1;
      #`DELAY_BETWEEN_SPI;      
      $display($time,"[SPI-SLAVE] Done spi_write_word task"); 
          
    end
  endtask

  //----------------------------------------------------

  task spi_read_nword;
    input   [31:0] addr;
    input int      n;
    inout   [31:0] data[];

    logic    [7:0] command;
    int i;
    int j;
    begin
        
      command = 8'hB;
      spi_sck = 0;
      #`SPI_SEMIPERIOD spi_sck = 0;
      #`SPI_SEMIPERIOD spi_sck = 0;
      spi_csn = 0;
      #`SPI_SEMIPERIOD spi_sck = 0;
      #`SPI_SEMIPERIOD spi_sck = 0;

      for (i = 7; i >= 0; i--)
      begin
        spi_sdo = command[i];
        #`SPI_SEMIPERIOD spi_sck = 1;
        #`SPI_SEMIPERIOD spi_sck = 0;
      end

      for (i = 31; i >= 0; i--)
      begin
        spi_sdo = addr[i];
        #`SPI_SEMIPERIOD spi_sck = 1;
        #`SPI_SEMIPERIOD spi_sck = 0;
      end

      for (i = 32; i >= 0; i--)
      begin
        #`SPI_SEMIPERIOD spi_sck = 1;
        #`SPI_SEMIPERIOD spi_sck = 0;
      end

      for (j = 0; j < n; j++)
      begin
        for (i = 31; i >= 0; i--)
        begin
          #`SPI_SEMIPERIOD spi_sck = 1;
          data[j][i] = spi_sdi;
          #`SPI_SEMIPERIOD spi_sck = 0;
        end
      end

      #`SPI_SEMIPERIOD spi_sck = 0;
      #`SPI_SEMIPERIOD spi_sck = 0;
      spi_csn   = 1;
      #`SPI_SEMIPERIOD spi_sck = 0;
      #`SPI_SEMIPERIOD spi_sck = 0;
      
      
    end
  endtask

  //----------------------------------------------------

  task spi_read_word;
    input   [31:0] addr;
    output  [31:0] data;

    logic   [31:0] tmp[1];
    begin
      spi_read_nword(addr, 1, tmp);
      data = tmp[0];      
    end
  endtask

  //----------------------------------------------------

  task spi_write_halfword;
    input   [31:0] addr;
    input   [15:0] data;

    logic   [31:0] temp;
    begin
      spi_read_word({addr[31:2], 2'b00}, temp);

      case (addr[1])
        1'b0: temp[15: 0] = data[15:0];
        1'b1: temp[31:16] = data[15:0];
      endcase

      spi_write_word({addr[31:2], 2'b00}, temp);
    end
  endtask

  //----------------------------------------------------

  task spi_write_byte;
    input   [31:0] addr;
    input   [ 7:0] data;

    logic   [31:0] temp;
    begin
      spi_read_word({addr[31:2], 2'b00}, temp);

      case (addr[1:0])
        2'b00: temp[ 7: 0] = data[7:0];
        2'b01: temp[15: 8] = data[7:0];
        2'b10: temp[23:16] = data[7:0];
        2'b11: temp[31:24] = data[7:0];
      endcase

      spi_write_word({addr[31:2], 2'b00}, temp);
    end
  endtask

  //----------------------------------------------------

  task spi_read_halfword;
    input   [31:0] addr;
    output  [15:0] data;

    logic   [31:0] temp;
    begin
      spi_read_word({addr[31:2], 2'b00}, temp);

      case (addr[1])
        1'b0: data[15:0] = temp[15: 0];
        1'b1: data[15:0] = temp[31:16];
      endcase
    end
  endtask

  //----------------------------------------------------

  task spi_read_byte;
    input   [31:0] addr;
    output  [ 7:0] data;

    logic   [31:0] temp;
    begin
      spi_read_word({addr[31:2], 2'b00}, temp);

      case (addr[1:0])
        2'b00: data[7:0] = temp[ 7: 0];
        2'b01: data[7:0] = temp[15: 8];
        2'b10: data[7:0] = temp[23:16];
        2'b11: data[7:0] = temp[31:24];
      endcase
    end
  endtask


//============================================================================

// Socket to Python  tasks

 chandle h;
 logic wait_after_reset = 1 ;
 logic [31:0] spi_arg_word ;
 logic [31:0] spi_arg_addr ;
 logic [31:0] rd_word_rsp_data ;

//--------------------------------------------------------------------

  task sock_connect ;

	// Init
	if(sock_init() < 0) begin
		$error("Error couldn't init the socket");
		$stop();
	end 

	// Connect
	h = sock_open("tcp://localhost:1234");
	if(h == null) begin
		$error("ERROR couldn't connect to socket");
		sock_shutdown();
		$stop();
	end 

	// Send / receive
	if(!sock_writeln(h, "Hello from py_spi_tb.sv!")) begin
		$error("Socket access error");
		sock_shutdown();
		$stop();
	end
	$display("py_spi_tb.sv got line from remote python: %s",sock_readln(h));
  
  endtask
    
//---------------------------------------------------------------------

task receive_remote_py_cmd ; // From now on spi communication is connected to the remote python 

   string  remote_py_cmd_str  ;
   integer str_idx ;
   logic [7:0] rp_c ;
   logic ignore_space ;
   logic is_last_c ;
   logic arg_is_avail ;
   logic wr_word_on ;
   logic rd_word_on ;
   logic wr_word_addr_avail ;
   integer nibble_idx  ;
   string remote_py_rsp_str ;  
   
//---------------------------------------------------------------------
   
   while (1) begin // DO forever

       remote_py_cmd_str = sock_readln(h) ;
      
      $display ("%0t py_spi_tb.sv: Remote Py Command: %s",$time,remote_py_cmd_str) ; // Debug Option
      
      ignore_space = 0 ;
      is_last_c  = 0 ;
      arg_is_avail = 0 ;
      nibble_idx = 0 ;
      wr_word_on = 0 ;
      rd_word_on = 0 ;
      wr_word_addr_avail = 0 ;

            
      for (str_idx=0 ; str_idx < remote_py_cmd_str.len() ; str_idx++) begin
        
                  rp_c = remote_py_cmd_str.getc(str_idx) ; 
                  
                  is_last_c = (str_idx == (remote_py_cmd_str.len()-1)) ;  
                  arg_is_avail = is_last_c || (rp_c==8'h0A) || ((rp_c==" ") && !ignore_space) ;
      

                  if (rp_c=="Q") begin
                        $display("\n\n py_spi_tb.sv: Detected remote quit command. Quitting \n\n") ;                    
                        sock_close(h);
                        sock_shutdown();
                        $finish ;
                  end else if (rp_c=="W") begin
                       ignore_space = 1 ;
                       wr_word_on = 1 ;
                  end  else if (rp_c=="R") begin                      
                       ignore_space = 1 ;  
                       rd_word_on = 1;
                  end else if ((rp_c>="0")&&(rp_c<="9")) begin 
                     spi_arg_word[(7-nibble_idx)*4+:4] = (rp_c - "0") ;
                     nibble_idx++;   
                     ignore_space = 0 ;                    
                  end else if ((rp_c>="a")&&(rp_c<="f")) begin 
                     spi_arg_word[(7-nibble_idx)*4+:4] = 10+(rp_c - "a") ; 
                     nibble_idx++;  
                     ignore_space = 0 ;     
                  end                              
                  
                  if (arg_is_avail) begin
                      spi_arg_word = spi_arg_word >> ((8-nibble_idx)*4) ;
                      nibble_idx = 0 ;                      
                      if (wr_word_on) begin
                        if (wr_word_addr_avail) begin
                          spi_write_word(spi_arg_addr,spi_arg_word) ;  
                        end else begin
                          spi_arg_addr = spi_arg_word ;
                          wr_word_addr_avail = 1 ;
                        end                      
                      end else if  (rd_word_on) begin                       
                       spi_read_word(spi_arg_word, rd_word_rsp_data) ; 
                       remote_py_rsp_str.hextoa(rd_word_rsp_data) ;  
 	                   if(!sock_writeln(h,remote_py_rsp_str)) begin
		                 $error("Socket access error");
		                 sock_shutdown();
		                 $stop();
                       end
                      
                      end
                  end   // arg_is_avail               
      end  // for
 end // while         
   
endtask 

// --------------------------------- Check for remote py commands  ---------------------------------------------

initial begin
 spi_csn = 1 ;
 sock_connect ; 
 wait_after_reset = 1 ;
 #2000ns ;
 wait_after_reset = 0 ;
end 

always begin
  if (wait_after_reset) wait (wait_after_reset==0) ;     
  receive_remote_py_cmd ;
end

//------------------------------------------------------------------------------------ 

endmodule

