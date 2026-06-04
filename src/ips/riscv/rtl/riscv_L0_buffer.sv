// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`ifdef HAMSA_DI
  `define EN_L0_INBUF 1
`endif


module riscv_L0_buffer
#(
  parameter                                   RDATA_IN_WIDTH = 128
)
(
  input  logic                                clk,
  input  logic                                rst_n,

  input  logic                                prefetch_i,
  input  logic [31:0]                         prefetch_addr_i,

  input  logic                                branch_i,
  input  logic [31:0]                         branch_addr_i,

  input  logic                                hwlp_i,
  input  logic [31:0]                         hwlp_addr_i,

  output logic                                fetch_gnt_o,
  output logic                                fetch_valid_o,

  output logic                                valid_o,
  output logic [RDATA_IN_WIDTH/32-1:0][31:0]  rdata_o,
  output logic [31:0]                         addr_o,

  // goes to instruction memory / instruction cache
  output logic                                instr_req_o,
  output logic [31:0]                         instr_addr_o,
  input  logic                                instr_gnt_i,
  input  logic                                instr_rvalid_i,
  input  logic [RDATA_IN_WIDTH/32-1:0][31:0]  instr_rdata_i,

  output logic                                busy_o    
);

  enum logic [2:0] { EMPTY, VALID_L0, WAIT_GNT, WAIT_RVALID, ABORTED_BRANCH, WAIT_HWLOOP
     `ifdef EN_L0_INBUF
       ,FOUND_IN_BUF
     `endif
  } CS, NS;

  logic [3:0][31:0]   L0_buffer;
  logic      [31:0]   addr_q, instr_addr_int;
  logic               valid;

  `ifdef EN_L0_INBUF  
  logic fetch_found_in_buf ;
  logic [31:0] addr_in_buf ;
  logic instr_inbuf_rvalid ;
  `endif
  
  logic fetch_req ;
  
  //////////////////////////////////////////////////////////////////////////////
  // FSM
  //////////////////////////////////////////////////////////////////////////////

  always_comb
  begin
    NS             = CS;
    valid          = 1'b0;
    instr_req_o    = 1'b0;
    instr_addr_int = '0;
    fetch_valid_o  = 1'b0;
    

    if (branch_i)
      instr_addr_int = branch_addr_i;
    else if (hwlp_i)
      instr_addr_int = hwlp_addr_i;
    else
      instr_addr_int = prefetch_addr_i;
    
    fetch_req = branch_i || hwlp_i || prefetch_i ;
    
    `ifdef EN_L0_INBUF      
    fetch_found_in_buf = fetch_req && (addr_in_buf[31:4]==instr_addr_int[31:4]) ;      
    `endif
    
    case(CS)

      // wait for the first branch request before fetching any instructions
      EMPTY:
      begin

        if (branch_i | hwlp_i | prefetch_i) // make the request to icache
        begin
          instr_req_o    = 1'b1;

          if (instr_gnt_i)
            NS = WAIT_RVALID;
          else
            NS = WAIT_GNT;
        end
      end //~EMPTY

      WAIT_GNT:
      begin
        if (!(branch_i || hwlp_i)) instr_addr_int = addr_q;

        instr_req_o = 1'b1; 
        
        if (instr_gnt_i)
          NS = WAIT_RVALID;
        else
          NS = WAIT_GNT;        
      end //~WAIT_GNT

      WAIT_RVALID:
      begin
        valid   = instr_rvalid_i;

        if (branch_i) begin
        
          if (instr_rvalid_i) begin
            `ifndef HAMSA_DI     // Udi: looks to me as not needed also in SI since we are prioritizing the branch
              fetch_valid_o  = 1'b1;    
            `endif
              instr_req_o    = 1'b1;
              
            if (instr_gnt_i)
              NS = WAIT_RVALID;
            else
              NS = WAIT_GNT;
          end else begin
            NS = ABORTED_BRANCH; // TODO: THIS STATE IS IDENTICAL WITH THIS ONE
          end

        end else begin

          if (instr_rvalid_i)
          begin
            fetch_valid_o = 1'b1;

            if (prefetch_i | hwlp_i) // we are receiving the last packet, then prefetch the next one
            begin
              instr_req_o    = 1'b1;

              if (instr_gnt_i)
                NS = WAIT_RVALID;
              else
                NS = WAIT_GNT;
            end
            else // not the last chunk
            begin
              NS = VALID_L0;
            end
          end
        end
      end //~WAIT_RVALID

      VALID_L0:
      begin
        valid  = 1'b1;       
        if (fetch_req)
        begin 
          instr_req_o = 1'b1;
          NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
              
          `ifdef EN_L0_INBUF     
             if (fetch_found_in_buf) begin
               instr_req_o = 1'b0;                 
               NS = FOUND_IN_BUF ;   
             end   
          `endif   
          
        end
      end //~VALID_L0

      ABORTED_BRANCH:
      begin

        //$display($time," TMP DEBUG Entered Aborted Branch") ;

        // prepare address even if we don't need it
        // this removes the dependency for instr_addr_o on instr_rvalid_i
        
        if (!branch_i) instr_addr_int = addr_q;

        if (instr_rvalid_i)
        begin
          instr_req_o    = 1'b1;

          if (instr_gnt_i)
            NS = WAIT_RVALID;
          else
            NS = WAIT_GNT;
        end
      end //~ABORTED_BRANCH

       `ifdef EN_L0_INBUF      
       FOUND_IN_BUF:
       begin
           valid         = 1'b1; 
           fetch_valid_o = instr_inbuf_rvalid ;          
           if (fetch_req)
           begin                      
             if (fetch_found_in_buf) begin
                NS = FOUND_IN_BUF ;                       
             end else begin
                instr_req_o    = 1'b1;
                NS = instr_gnt_i ? WAIT_RVALID : WAIT_GNT;
             end                             
           end
       end //~FOUND_IN_BUF      
       `endif

      default:
      begin
         NS = EMPTY;
      end
    endcase //~CS
  end

  //////////////////////////////////////////////////////////////////////////////
  // registers
  //////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n)
    begin
      CS              <= EMPTY;
      L0_buffer       <= '0;
      addr_q          <= '0;
      
      `ifdef EN_L0_INBUF
      addr_in_buf        <= '0;      
      instr_inbuf_rvalid <= '0 ;
      `endif
      
    end else begin
      CS             <= NS;
      
      if (instr_rvalid_i) begin
        L0_buffer <= instr_rdata_i;
        `ifdef EN_L0_INBUF
        addr_in_buf <= addr_q ;
        `endif
      end
      
      if (branch_i | hwlp_i | prefetch_i)
        addr_q <= instr_addr_int;
      `ifdef EN_L0_INBUF  
       instr_inbuf_rvalid <= fetch_found_in_buf ;  
      `endif 
    end
  end

  //////////////////////////////////////////////////////////////////////////////
  // output ports
  //////////////////////////////////////////////////////////////////////////////

  assign instr_addr_o = { instr_addr_int[31:4], 4'b0000 };

  assign rdata_o = (instr_rvalid_i) ? instr_rdata_i : L0_buffer;
  assign addr_o  = addr_q;

  `ifndef EN_L0_INBUF
  assign valid_o = valid & (~branch_i);
  assign fetch_gnt_o   = instr_gnt_i  ; 
  `else
  assign valid_o = valid & ((~branch_i)|| instr_inbuf_rvalid) ;
  assign fetch_gnt_o   = instr_gnt_i || fetch_found_in_buf ;  
  `endif

  assign busy_o = (CS != EMPTY) && (CS != VALID_L0) || instr_req_o;



endmodule