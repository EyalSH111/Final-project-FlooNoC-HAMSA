//-----------------------------------------------------------------------------
// Title         : SPI top
// Project       : 
//-----------------------------------------------------------------------------
// File          : spi_top.v
// Author        : 
// Created       : 
// Last modified : 
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2010 by Ceragon This model is the confidential and
// proprietary property of Ceragon and the possession or use of this
// file requires a written license from Ceragon.
//------------------------------------------------------------------------------
// Modification history :
// 31.03.2010 : created
//-----------------------------------------------------------------------------

module spi_top(/*autoarg*/
   // Outputs
   mmspi_axiarready_i, mmspi_axiawready_i, mmspi_axibresp_i,
   mmspi_axibvalid_i, mmspi_axirdata_i, mmspi_axirlast_i,
   mmspi_axirresp_i, mmspi_axirvalid_i, mmspi_axiwready_i,
   mmspi_axibid_i, mmspi_axibuser_i, mmspi_axirid_i, mmspi_axiruser_i,
   mmspi_bad_addr_irq, mmspi_bad_addr_unmsk_irq, mmspi_intr_o,
   mmspi_cs_o, mmspi_dclk_o, mmspi_dout_o, mmspi_dout_oe_n,
   mmspi_disable_ack,
   // Inputs
   big_endian, test_mode, scan_mode, dft_clk_en, phy_cg_sel,
   scan_enable, mmspi_clk, mmspi_rst_n, mmspi_axiaraddr_o,
   mmspi_axiarburst_o, mmspi_axiarcache_o, mmspi_axiarlen_o,
   mmspi_axiarlock_o, mmspi_axiarprot_o, mmspi_axiarsize_o,
   mmspi_axiarvalid_o, mmspi_axiarid_o, mmspi_axiarqos_o,
   mmspi_axiarregion_o, mmspi_axiaruser_o, mmspi_axiawaddr_o,
   mmspi_axiawburst_o, mmspi_axiawcache_o, mmspi_axiawlen_o,
   mmspi_axiawlock_o, mmspi_axiawprot_o, mmspi_axiawsize_o,
   mmspi_axiawvalid_o, mmspi_axibready_o, mmspi_axirready_o,
   mmspi_axiwdata_o, mmspi_axiwlast_o, mmspi_axiwstrb_o,
   mmspi_axiwvalid_o, mmspi_axiawid_o, mmspi_axiawqos_o,
   mmspi_axiawregion_o, mmspi_axiawuser_o, mmspi_axiwuser_o,
   mmspi_req_mode_ival, mmspi_d_clk, mmspi_dclk_i, mmspi_din_i,
   mmspi_dout_i, mmspi_disable_req
   );

   parameter SPI_NUM_OF_CS_EQ_4=  1'b1;
   parameter SPI_MEM_BASE      =  32'h02000000;
   parameter SPI_CFG_BASE      =  32'h1fd00000;
   parameter SPI_MEM_CS_SIZE   =  24;
   parameter SPI_CFG_CS_SIZE   =  10;

   parameter SPI_IS_BOOT = 0;

   localparam AW = SPI_CFG_CS_SIZE;

   localparam SPI_MEM_CS0_BASE = SPI_MEM_BASE;
   localparam SPI_MEM_CS1_BASE = SPI_MEM_BASE + 1*(2**SPI_MEM_CS_SIZE);
   localparam SPI_MEM_CS2_BASE = SPI_MEM_BASE + 2*(2**SPI_MEM_CS_SIZE);
   localparam SPI_MEM_CS3_BASE = SPI_MEM_BASE + 3*(2**SPI_MEM_CS_SIZE);

   `define A2C_DWFIFO_PTRW       2 //5
   `define A2C_DWFIFO_AFTHRS_LSB 2'b01

   `define A2C_CWFIFO_PTRW       2
   `define A2C_CWFIFO_AFTHRS_LSB 2'b01

   `define A2C_RDFIFO_PTRW       2 //5
   `define A2C_RDFIFO_AFTHRS_LSB 2'b01

   //----------------------------------------------------------------------------
   // DFT & Endianity
   //----------------------------------------------------------------------------
   input                big_endian;
   input                test_mode;
   input                scan_mode;
   input                dft_clk_en;
   input [1:0]          phy_cg_sel;
   input                scan_enable;

   //----------------------------------------------------------------------------
   // AXI I/F
   //----------------------------------------------------------------------------
   input                mmspi_clk;
   input                mmspi_rst_n;
   input [31:0]         mmspi_axiaraddr_o;
   input [1:0]          mmspi_axiarburst_o;
   input [3:0]          mmspi_axiarcache_o;
   input [7:0]          mmspi_axiarlen_o;
   input                mmspi_axiarlock_o;
   input [2:0]          mmspi_axiarprot_o;
   input [2:0]          mmspi_axiarsize_o;
   input                mmspi_axiarvalid_o;
   input [4:0]          mmspi_axiarid_o;        
   input [3:0]          mmspi_axiarqos_o;       
   input [3:0]          mmspi_axiarregion_o;    
   input                mmspi_axiaruser_o;      
   input [31:0]         mmspi_axiawaddr_o;
   input [1:0]          mmspi_axiawburst_o;
   input [3:0]          mmspi_axiawcache_o;
   input [7:0]          mmspi_axiawlen_o;
   input                mmspi_axiawlock_o;
   input [2:0]          mmspi_axiawprot_o;
   input [2:0]          mmspi_axiawsize_o;
   input                mmspi_axiawvalid_o;
   input                mmspi_axibready_o;
   input                mmspi_axirready_o;
   input [31:0]         mmspi_axiwdata_o;
   input                mmspi_axiwlast_o;
   input [3:0]          mmspi_axiwstrb_o;
   input                mmspi_axiwvalid_o;
   input [4:0]          mmspi_axiawid_o;    
   input [3:0]          mmspi_axiawqos_o;   
   input [3:0]          mmspi_axiawregion_o;
   input                mmspi_axiawuser_o;  
   input                mmspi_axiwuser_o;          
   output               mmspi_axiarready_i;
   output               mmspi_axiawready_i;
   output [1:0]         mmspi_axibresp_i;
   output               mmspi_axibvalid_i;
   output [31:0]        mmspi_axirdata_i;
   output               mmspi_axirlast_i;
   output [1:0]         mmspi_axirresp_i;
   output               mmspi_axirvalid_i;
   output               mmspi_axiwready_i;
   output [4:0]         mmspi_axibid_i;        
   output               mmspi_axibuser_i;      
   output [4:0]         mmspi_axirid_i;        
   output               mmspi_axiruser_i;      
   

   //----------------------------------------------------------------------------
   // MMSPI CS mode initial value from strapping resistors
   //----------------------------------------------------------------------------
   input [1:0]          mmspi_req_mode_ival;

   //----------------------------------------------------------------------------
   // SPI Config Region out-of-range access interrupt
   //----------------------------------------------------------------------------
   output               mmspi_bad_addr_irq;
   output               mmspi_bad_addr_unmsk_irq;
   
//   //----------------------------------------------------------------------------
//   // AXI2CBUS I/F RAM control vector
//   //----------------------------------------------------------------------------
//   input [6:0]          mmspi_ram_ctrl_vec;

   //----------------------------------------------------------------------------
   // MMSPI I/F
   //----------------------------------------------------------------------------
   output               mmspi_intr_o;
   input                mmspi_d_clk;
   input                mmspi_dclk_i;
   input                mmspi_din_i;
   input                mmspi_dout_i;
   output [3:0]         mmspi_cs_o;
   output               mmspi_dclk_o;
   output               mmspi_dout_o;
   output               mmspi_dout_oe_n;

   //----------------------------------------------------------------------------
   // Signals definitions
   //----------------------------------------------------------------------------
   reg [31:0]           cbus_m_address_mask;
   wire                 mmspi_cfg_req;
   reg                  mmspi_mm_req0;
   reg                  mmspi_mm_req1;
   reg                  mmspi_mm_req2;
   reg                  mmspi_mm_req3;
   
   /*autoinput*/

   //*autooutput*/
 
   /*autowire*/
   
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]          cbus_m_address;         // From I_axi2cbus_top of axi2cbus_top.v
   wire [1:0]           cbus_m_amode;           // From I_axi2cbus_top of axi2cbus_top.v
   wire [9:0]           cbus_m_bytecnt;         // From I_axi2cbus_top of axi2cbus_top.v
   wire [3:0]           cbus_m_byten;           // From I_axi2cbus_top of axi2cbus_top.v
   wire [2:0]           cbus_m_clsize;          // From I_axi2cbus_top of axi2cbus_top.v
   wire                 cbus_m_cmd;             // From I_axi2cbus_top of axi2cbus_top.v
   wire                 cbus_m_first;           // From I_axi2cbus_top of axi2cbus_top.v
   wire                 cbus_m_last;            // From I_axi2cbus_top of axi2cbus_top.v
   wire [7:0]           cbus_m_mstid;           // From I_axi2cbus_top of axi2cbus_top.v
   wire [31:0]          cbus_m_rdatap;          // From I_spi of spi.v
   wire                 cbus_m_req;             // From I_axi2cbus_top of axi2cbus_top.v
   wire                 cbus_m_rresp;           // From I_spi of spi.v
   wire                 cbus_m_waccept;         // From I_spi of spi.v
   wire [31:0]          cbus_m_wdata;           // From I_axi2cbus_top of axi2cbus_top.v
   wire [1:0]           mmspi_req_mode;         // From I_spi of spi.v
   // End of automatics

   assign               mmspi_cfg_req = (cbus_m_address[31:SPI_CFG_CS_SIZE] == SPI_CFG_BASE[31:SPI_CFG_CS_SIZE]) ? cbus_m_req : 1'b0;

generate
if (SPI_NUM_OF_CS_EQ_4 == 1'b1) begin : num_of_cs_4
   always @(*)
     begin
          //==================================================================
          // MM CS Combining;
          // mmspi_req_mode = 2'b00;
          //   mmspi_mm_req0[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req1[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req2[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req3[size] = 2^SPI_MEM_CS_SIZE
          // mmspi_req_mode = 2'b01;
          //   mmspi_mm_req0[size] = 2^(SPI_MEM_CS_SIZE+1)
          //   mmspi_mm_req1[size] = Not-Active
          //   mmspi_mm_req2[size] = Not-Active
          //   mmspi_mm_req3[size] = 2^SPI_MEM_CS_SIZE
          // mmspi_req_mode = 2'b10;
          //   mmspi_mm_req0[size] = 2^(SPI_MEM_CS_SIZE+2)
          //   mmspi_mm_req1[size] = Not-Active
          //   mmspi_mm_req2[size] = Not-Active
          //   mmspi_mm_req3[size] = Not-Active
          // mmspi_req_mode = 2'b11;
          //   mmspi_mm_req0[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req1[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req2[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req3[size] = 2^SPI_MEM_CS_SIZE
          //==================================================================
          case (mmspi_req_mode[1:0])
            2'b00:
              begin
                   cbus_m_address_mask = {{(32-SPI_MEM_CS_SIZE){1'b0}}, cbus_m_address[SPI_MEM_CS_SIZE-1:0]};
                   mmspi_mm_req0 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req2 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req3 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS3_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
              end
            2'b01:
              begin
                   cbus_m_address_mask = {{(32-(SPI_MEM_CS_SIZE+1)){1'b0}}, cbus_m_address[(SPI_MEM_CS_SIZE+1)-1:0]};
                   mmspi_mm_req0 = ((cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) || 
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE])) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = 1'b0;
                   mmspi_mm_req2 = ((cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE]) || 
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS3_BASE[31:SPI_MEM_CS_SIZE])) ? cbus_m_req : 1'b0;
                   mmspi_mm_req3 = 1'b0;
              end
            2'b10:
              begin
                   cbus_m_address_mask = {{(32-(SPI_MEM_CS_SIZE+2)){1'b0}}, cbus_m_address[(SPI_MEM_CS_SIZE+2)-1:0]};
                   mmspi_mm_req0 = ((cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) || 
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE]) ||
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE]) || 
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS3_BASE[31:SPI_MEM_CS_SIZE])) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = 1'b0;
                   mmspi_mm_req2 = 1'b0;
                   mmspi_mm_req3 = 1'b0;
              end
            default:
              begin
                   cbus_m_address_mask = {{(32-SPI_MEM_CS_SIZE){1'b0}}, cbus_m_address[SPI_MEM_CS_SIZE-1:0]};
                   mmspi_mm_req0 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req2 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req3 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS3_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
              end
          endcase // case (mmspi_req_mode[1:0])
     end // always @ (*)
end // block: num_of_cs_4
else begin : num_of_cs_3
   always @(*)
     begin
          //==================================================================
          // MM CS Combining;
          // mmspi_req_mode = 2'b00;
          //   mmspi_mm_req0[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req1[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req2[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req3[size] = 2^SPI_MEM_CS_SIZE
          // mmspi_req_mode = 2'b01;
          //   mmspi_mm_req0[size] = 2^(SPI_MEM_CS_SIZE+1)
          //   mmspi_mm_req1[size] = Not-Active
          //   mmspi_mm_req2[size] = Not-Active
          //   mmspi_mm_req3[size] = 2^SPI_MEM_CS_SIZE
          // mmspi_req_mode = 2'b10;
          //   mmspi_mm_req0[size] = 2^(SPI_MEM_CS_SIZE+2)
          //   mmspi_mm_req1[size] = Not-Active
          //   mmspi_mm_req2[size] = Not-Active
          //   mmspi_mm_req3[size] = Not-Active
          // mmspi_req_mode = 2'b11;
          //   mmspi_mm_req0[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req1[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req2[size] = 2^SPI_MEM_CS_SIZE
          //   mmspi_mm_req3[size] = 2^SPI_MEM_CS_SIZE
          //==================================================================
          case (mmspi_req_mode[1:0])
            2'b00:
              begin
                   cbus_m_address_mask = {{(32-SPI_MEM_CS_SIZE){1'b0}}, cbus_m_address[SPI_MEM_CS_SIZE-1:0]};
                   mmspi_mm_req0 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req2 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req3 = 1'b0;
                   
              end
            2'b01:
              begin
                   cbus_m_address_mask = {{(32-(SPI_MEM_CS_SIZE+1)){1'b0}}, cbus_m_address[(SPI_MEM_CS_SIZE+1)-1:0]};
                   mmspi_mm_req0 = ((cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) || 
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE])) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = 1'b0;
                   mmspi_mm_req2 = ((cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE])) ? cbus_m_req : 1'b0;
                   mmspi_mm_req3 = 1'b0;
              end
            2'b10:
              begin
                   cbus_m_address_mask = {{(32-(SPI_MEM_CS_SIZE+2)){1'b0}}, cbus_m_address[(SPI_MEM_CS_SIZE+2)-1:0]};
                   mmspi_mm_req0 = ((cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) || 
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE]) ||
                                    (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE])) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = 1'b0;
                   mmspi_mm_req2 = 1'b0;
                   mmspi_mm_req3 = 1'b0;
              end
            default:
              begin
                   cbus_m_address_mask = {{(32-SPI_MEM_CS_SIZE){1'b0}}, cbus_m_address[SPI_MEM_CS_SIZE-1:0]};
                   mmspi_mm_req0 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS0_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req1 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS1_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req2 = (cbus_m_address[31:SPI_MEM_CS_SIZE] == SPI_MEM_CS2_BASE[31:SPI_MEM_CS_SIZE]) ? cbus_m_req : 1'b0;
                   mmspi_mm_req3 = 1'b0;
              end
          endcase // case (mmspi_req_mode[1:0])
     end // always @ (*)
end
endgenerate
   
   //==================================================================
   // Clock stop logic
   //==================================================================
   output               mmspi_disable_ack;
   input                mmspi_disable_req;
   
   
   reg                  mmspi_disable_ack;
   wire                 mmspi_disable_req;
   always @ (posedge mmspi_clk)
     begin
        if (!mmspi_rst_n)
          mmspi_disable_ack <= 1'd0;
        else
          mmspi_disable_ack <= (~mmspi_cfg_req & 
                                   ~mmspi_mm_req0 & 
                                   ~mmspi_mm_req1 & 
                                   ~mmspi_mm_req2 & 
                                   ~mmspi_mm_req3 & 
                                   mmspi_disable_req);
     end // always @ (posedge cbus_clk)
   
   reg [1:0] addr_lsb_recov;
   
//------------------------------------------------------------
// Since SGN doesn't preserves the lower address bits, 
// we have recover them from the byte_en + endianity
//-------------------------------------------------------------
  always @(*) 
    begin
         casex (cbus_m_byten[3:0])
           4'b1000:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h0;
              else
                addr_lsb_recov = 2'h3;
             end
           4'b0100:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h1;
              else
                addr_lsb_recov = 2'h2;
             end
           4'b0010:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h2;
              else
                addr_lsb_recov = 2'h1;
             end
           4'b0001:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h3;
              else
                addr_lsb_recov = 2'h0;
             end
           4'b1100:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h0;
              else
                addr_lsb_recov = 2'h2;
             end
           4'b0110:
             begin
                addr_lsb_recov = 2'h1;
             end
           4'b0011:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h2;
              else
                addr_lsb_recov = 2'h0;
             end
           4'b1110:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h0;
              else
                addr_lsb_recov = 2'h1;
             end
           4'b0111:
             begin
              if (big_endian)
                addr_lsb_recov = 2'h1;
              else
                addr_lsb_recov = 2'h0;
             end
           default:
             begin
                addr_lsb_recov = 2'h0;
             end
         endcase // casex (bytee[3:0])
    end

   /*axi2cbus_top AUTO_TEMPLATE (
      .cbus_m_xcnt                      (),
      .cbus_m_align                     (),
      .aclk                             (mmspi_clk),
      .areset_n                         (mmspi_rst_n),
      .awready_i                        (mmspi_axiawready_i),
      .wready_i                         (mmspi_axiwready_i),
      .bid_i                            (mmspi_axibid_i[4:0]),
      .buser_i                          (mmspi_axibuser_i),      
      .bresp_i                          (mmspi_axibresp_i[1:0]),
      .bvalid_i                         (mmspi_axibvalid_i),
      .arready_i                        (mmspi_axiarready_i),
      .rdata_i                          (mmspi_axirdata_i[31:0]),
      .rresp_i                          (mmspi_axirresp_i[1:0]),
      .rid_i                            (mmspi_axirid_i[4:0]),
      .ruser_i                          (mmspi_axiruser_i),      
      .rlast_i                          (mmspi_axirlast_i),
      .rvalid_i                         (mmspi_axirvalid_i),
      .awid_o                           (mmspi_axiawid_o[4:0]),
      .awqos_o                          (mmspi_axiawqos_o[3:0]),
      .awregion_o                       (mmspi_axiawregion_o[3:0]),
      .awuser_o                         (mmspi_axiawuser_o),      
      .awaddr_o                         (mmspi_axiawaddr_o[31:0]),
      .awlen_o                          (mmspi_axiawlen_o[7:0]),
      .awsize_o                         (mmspi_axiawsize_o[2:0]),
      .awvalid_o                        (mmspi_axiawvalid_o),
      .awlock_o                         (mmspi_axiawlock_o),
      .awburst_o                        (mmspi_axiawburst_o[1:0]),
      .awcache_o                        (mmspi_axiawcache_o[3:0]),
      .awprot_o                         (mmspi_axiawprot_o[2:0]),
      .wdata_o                          (mmspi_axiwdata_o[31:0]),
      .wstrb_o                          (mmspi_axiwstrb_o[3:0]),
      .wlast_o                          (mmspi_axiwlast_o),
      .wvalid_o                         (mmspi_axiwvalid_o),
      .wuser_o                          (mmspi_axiwuser_o),      
      .bready_o                         (mmspi_axibready_o),
      .araddr_o                         (mmspi_axiaraddr_o[31:0]),
      .arlen_o                          (mmspi_axiarlen_o[7:0]),
      .arsize_o                         (mmspi_axiarsize_o[2:0]),
      .arvalid_o                        (mmspi_axiarvalid_o),
      .arlock_o                         (mmspi_axiarlock_o),
      .arid_o                           (mmspi_axiarid_o[4:0]),
      .arqos_o                          (mmspi_axiarqos_o[3:0]),
      .arregion_o                       (mmspi_axiarregion_o[3:0]),
      .aruser_o                         (mmspi_axiaruser_o),      
      .arburst_o                        (mmspi_axiarburst_o[1:0]),
      .arcache_o                        (mmspi_axiarcache_o[3:0]),
      .arprot_o                         (mmspi_axiarprot_o[2:0]),
      .rready_o                         (mmspi_axirready_o),
     );*/
   axi2cbus_top #(.A2C_DWFIFO_PTRW(`A2C_DWFIFO_PTRW),
                  .A2C_CWFIFO_PTRW(`A2C_CWFIFO_PTRW),
                  .A2C_RDFIFO_PTRW(`A2C_RDFIFO_PTRW)) I_axi2cbus_top
     (/*autoinst*/
      // Outputs
      .cbus_m_address                   (cbus_m_address[31:0]),
      .cbus_m_align                     (),                      // Templated
      .cbus_m_amode                     (cbus_m_amode[1:0]),
      .cbus_m_bytecnt                   (cbus_m_bytecnt[9:0]),
      .cbus_m_byten                     (cbus_m_byten[3:0]),
      .cbus_m_clsize                    (cbus_m_clsize[2:0]),
      .cbus_m_cmd                       (cbus_m_cmd),
      .cbus_m_first                     (cbus_m_first),
      .cbus_m_last                      (cbus_m_last),
      .cbus_m_mstid                     (cbus_m_mstid[7:0]),
      .cbus_m_req                       (cbus_m_req),
      .cbus_m_wdata                     (cbus_m_wdata[31:0]),
      .cbus_m_xcnt                      (),                      // Templated
      .awready_i                        (mmspi_axiawready_i),    // Templated
      .wready_i                         (mmspi_axiwready_i),     // Templated
      .bid_i                            (mmspi_axibid_i[4:0]),   // Templated
      .buser_i                          (mmspi_axibuser_i),      // Templated
      .bresp_i                          (mmspi_axibresp_i[1:0]), // Templated
      .bvalid_i                         (mmspi_axibvalid_i),     // Templated
      .arready_i                        (mmspi_axiarready_i),    // Templated
      .rdata_i                          (mmspi_axirdata_i[31:0]), // Templated
      .rresp_i                          (mmspi_axirresp_i[1:0]), // Templated
      .rlast_i                          (mmspi_axirlast_i),      // Templated
      .rid_i                            (mmspi_axirid_i[4:0]),   // Templated
      .ruser_i                          (mmspi_axiruser_i),      // Templated
      .rvalid_i                         (mmspi_axirvalid_i),     // Templated
      // Inputs
      .aclk                             (mmspi_clk),             // Templated
      .areset_n                         (mmspi_rst_n),           // Templated
      .scan_mode                        (scan_mode),
      .cbus_m_rdatap                    (cbus_m_rdatap[31:0]),
      .cbus_m_rresp                     (cbus_m_rresp),
      .cbus_m_waccept                   (cbus_m_waccept),
      .awaddr_o                         (mmspi_axiawaddr_o[31:0]), // Templated
      .awlen_o                          (mmspi_axiawlen_o[7:0]), // Templated
      .awsize_o                         (mmspi_axiawsize_o[2:0]), // Templated
      .awid_o                           (mmspi_axiawid_o[4:0]),  // Templated
      .awqos_o                          (mmspi_axiawqos_o[3:0]), // Templated
      .awregion_o                       (mmspi_axiawregion_o[3:0]), // Templated
      .awuser_o                         (mmspi_axiawuser_o),     // Templated
      .awvalid_o                        (mmspi_axiawvalid_o),    // Templated
      .awlock_o                         (mmspi_axiawlock_o),     // Templated
      .awburst_o                        (mmspi_axiawburst_o[1:0]), // Templated
      .awcache_o                        (mmspi_axiawcache_o[3:0]), // Templated
      .awprot_o                         (mmspi_axiawprot_o[2:0]), // Templated
      .wdata_o                          (mmspi_axiwdata_o[31:0]), // Templated
      .wstrb_o                          (mmspi_axiwstrb_o[3:0]), // Templated
      .wlast_o                          (mmspi_axiwlast_o),      // Templated
      .wuser_o                          (mmspi_axiwuser_o),      // Templated
      .wvalid_o                         (mmspi_axiwvalid_o),     // Templated
      .bready_o                         (mmspi_axibready_o),     // Templated
      .araddr_o                         (mmspi_axiaraddr_o[31:0]), // Templated
      .arlen_o                          (mmspi_axiarlen_o[7:0]), // Templated
      .arsize_o                         (mmspi_axiarsize_o[2:0]), // Templated
      .arid_o                           (mmspi_axiarid_o[4:0]),  // Templated
      .arqos_o                          (mmspi_axiarqos_o[3:0]), // Templated
      .arregion_o                       (mmspi_axiarregion_o[3:0]), // Templated
      .aruser_o                         (mmspi_axiaruser_o),     // Templated
      .arvalid_o                        (mmspi_axiarvalid_o),    // Templated
      .arlock_o                         (mmspi_axiarlock_o),     // Templated
      .arburst_o                        (mmspi_axiarburst_o[1:0]), // Templated
      .arcache_o                        (mmspi_axiarcache_o[3:0]), // Templated
      .arprot_o                         (mmspi_axiarprot_o[2:0]), // Templated
      .rready_o                         (mmspi_axirready_o));    // Templated
   
   /*spi AUTO_TEMPLATE (
    .waccept                            (cbus_m_waccept),
    .rdatap                             (cbus_m_rdatap[]),
    .rresp                              (cbus_m_rresp),
    .rstatus                            (),
    .sreq                               (),
    .sstatus                            (),
    .sdone                              (),
    .sid                                (),
    .smstid                             (),
    .spi_intr_o                         (mmspi_intr_o),
    .spi_dclk_i                         (mmspi_dclk_i),
    .spi_din_i                          (mmspi_din_i),
    .spi_dout_i                         (mmspi_dout_i),
    .spi_dclk_o                         (mmspi_dclk_o),
    .spi_cs_o                           (mmspi_cs_o[3:0]),
    .spi_dout_o                         (mmspi_dout_o),
    .spi_dout_oe_n                      (mmspi_dout_oe_n),
    .clk                                (mmspi_clk),
    .spi_clk                            (mmspi_d_clk),
    .rst_n                              (mmspi_rst_n),
    .cfg_req                            (mmspi_cfg_req),
    .mm_req0                            (mmspi_mm_req0),
    .mm_req1                            (mmspi_mm_req1),
    .mm_req2                            (mmspi_mm_req2),
    .mm_req3                            (mmspi_mm_req3),
    .address                            ({cbus_m_address_mask[31:2], addr_lsb_recov[1:0]}),
    .first                              (cbus_m_first),
    .last                               (cbus_m_last),
    .bytecnt                            (cbus_m_bytecnt[]),
    .byten                              (cbus_m_byten[]),
    .cmd                                (cbus_m_cmd),
    .wdata                              (cbus_m_wdata[]),
    .amode                              (cbus_m_amode),
    .clsize                             (cbus_m_clsize[]),
    .xid                                (4'd0),
    .mstid                              (cbus_m_mstid[]),
    .done                               (1'b1),
    .sready                             (1'b1),
    .spi_bad_addr_irq                   (mmspi_bad_addr_irq),
    .spi_bad_addr_unmsk_irq             (mmspi_bad_addr_unmsk_irq),
    );
    */
   
   spi #(/*AUTOINSTPARAM*/
         // Parameters
         .SPI_IS_BOOT                   (SPI_IS_BOOT),
         .AW                            (AW))   // AW bits out of full address[31:0] used for internal mapping 
   I_spi (/*autoinst*/
          // Outputs
          .mmspi_req_mode               (mmspi_req_mode[1:0]),
          .waccept                      (cbus_m_waccept),        // Templated
          .rdatap                       (cbus_m_rdatap[31:0]),   // Templated
          .rresp                        (cbus_m_rresp),          // Templated
          .rstatus                      (),                      // Templated
          .sreq                         (),                      // Templated
          .sstatus                      (),                      // Templated
          .sdone                        (),                      // Templated
          .sid                          (),                      // Templated
          .smstid                       (),                      // Templated
          .spi_intr_o                   (mmspi_intr_o),          // Templated
          .spi_dclk_o                   (mmspi_dclk_o),          // Templated
          .spi_cs_o                     (mmspi_cs_o[3:0]),       // Templated
          .spi_dout_o                   (mmspi_dout_o),          // Templated
          .spi_dout_oe_n                (mmspi_dout_oe_n),       // Templated
          .spi_bad_addr_irq             (mmspi_bad_addr_irq),    // Templated
          .spi_bad_addr_unmsk_irq       (mmspi_bad_addr_unmsk_irq), // Templated
          // Inputs
          .clk                          (mmspi_clk),             // Templated
          .spi_clk                      (mmspi_d_clk),           // Templated
          .rst_n                        (mmspi_rst_n),           // Templated
          .cfg_req                      (mmspi_cfg_req),         // Templated
          .mm_req0                      (mmspi_mm_req0),         // Templated
          .mm_req1                      (mmspi_mm_req1),         // Templated
          .mm_req2                      (mmspi_mm_req2),         // Templated
          .mm_req3                      (mmspi_mm_req3),         // Templated
          .mmspi_req_mode_ival          (mmspi_req_mode_ival[1:0]),
          .address                      ({cbus_m_address_mask[31:2], addr_lsb_recov[1:0]}), // Templated
          .first                        (cbus_m_first),          // Templated
          .last                         (cbus_m_last),           // Templated
          .bytecnt                      (cbus_m_bytecnt[9:0]),   // Templated
          .byten                        (cbus_m_byten[3:0]),     // Templated
          .cmd                          (cbus_m_cmd),            // Templated
          .wdata                        (cbus_m_wdata[31:0]),    // Templated
          .amode                        (cbus_m_amode),          // Templated
          .clsize                       (cbus_m_clsize[2:0]),    // Templated
          .xid                          (4'd0),                  // Templated
          .mstid                        (cbus_m_mstid[7:0]),     // Templated
          .done                         (1'b1),                  // Templated
          .sready                       (1'b1),                  // Templated
          .big_endian                   (big_endian),
          .spi_dclk_i                   (mmspi_dclk_i),          // Templated
          .spi_din_i                    (mmspi_din_i),           // Templated
          .spi_dout_i                   (mmspi_dout_i),          // Templated
          .test_mode                    (test_mode),
          .dft_clk_en                   (dft_clk_en),
          .phy_cg_sel                   (phy_cg_sel[1:0]),
          .scan_enable                  (scan_enable));
   
endmodule // spi_top

// Local Variables:
// verilog-library-directories:("." "$NEGEV_IP/design/crgn/soc_building_blocks/hdl" "../../axi2cbus/hdl")
// verilog-library-files:()
// verilog-library-extensions:(".v")
// End:



