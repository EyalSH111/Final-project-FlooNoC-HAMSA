//////////////////////////////////////////////////////////////////
//                                                              //
//  Amber 2 Core top-Level module                               //
//                                                              //
//  This file is part of the Amber project                      //
//  http://www.opencores.org/project,amber                      //
//                                                              //
//  Description                                                 //
//  Instantiates the core consisting of fetch, instruction      //
//  decode, execute, and co-processor.                          //
//                                                              //
//  Author(s):                                                  //
//      - Conor Santifort, csantifort.amber@gmail.com           //
//                                                              //
//////////////////////////////////////////////////////////////////
//                                                              //
// Copyright (C) 2010 Authors and OPENCORES.ORG                 //
//                                                              //
// This source file may be used and distributed without         //
// restriction provided that this copyright statement is not    //
// removed from the file and that any derivative work contains  //
// the original copyright notice and the associated disclaimer. //
//                                                              //
// This source file is free software; you can redistribute it   //
// and/or modify it under the terms of the GNU Lesser General   //
// Public License as published by the Free Software Foundation; //
// either version 2.1 of the License, or (at your option) any   //
// later version.                                               //
//                                                              //
// This source is distributed in the hope that it will be       //
// useful, but WITHOUT ANY WARRANTY; without even the implied   //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      //
// PURPOSE.  See the GNU Lesser General Public License for more //
// details.                                                     //
//                                                              //
// You should have received a copy of the GNU Lesser General    //
// Public License along with this source; if not, download it   //
// from http://www.opencores.org/lgpl.shtml                     //
//                                                              //
//////////////////////////////////////////////////////////////////
`include "../../src/tb/timescale.v"


module copro
(
input wire            i_clk,
input wire					  i_rst_n,
input wire					  i_sync_rst_n,
input wire            i_int,             // Fast Interrupt request, active high
input wire					  i_memory_ready,
// Wishbone Master I/F
output reg  [31:0]    o_wb_adr,
output reg  [3:0]     o_wb_sel,
output reg            o_wb_we,
input  wire [31:0]    i_wb_dat,
output reg  [31:0]    o_wb_dat,
output reg            o_wb_cyc,
output reg            o_wb_stb,
input  wire           i_wb_ack,
input  wire           i_wb_err,
// GPIO in
input  wire	[15:0]		i_gpio,
output reg	[15:0]		o_gpio,
input  wire					  i_init_ram,
input  wire [6:0]			i_init_addr,
input  wire [31:0]    i_init_data,
input  wire           i_init_ram_reg,
input  wire [6:0]     i_init_addr_reg,
input  wire [31:0]    i_init_data_reg,
input  wire           o_copro_reverse_bus

);

//INSTRUCTION STRUCTURE : 
//REG:
//
//	OP(4)	RD(4)	RS(4)	RT(4)
//
//IMM:
//
//	OP(4)	RD(4)	RS(4)	IMM(4)
//
//JUMP:
//
//	OP(4)	ADDR(11:0)
parameter ADDR_W = 7 ;

parameter	ADD 	= 4'h0 ; //RD = RS + RT
parameter	SUB 	= 4'h1 ; //RD = RS - RT
parameter	AND 	= 4'h2 ; //RD = RS & RT
parameter	OR  	= 4'h3 ; //RD = RS | RT
parameter	XOR 	= 4'h4 ; //RD = RS ^ RT
parameter	ADDI	= 4'h5 ; //RD = RS + INST[3:0]
parameter	SUBI	= 4'h6 ; //RD = RS - INST[3:0]
parameter	SLL 	= 4'h7 ; //RD = RS << INST[3:0]
parameter	SRL 	= 4'h8 ; //RD = RS >> INST[3:0]
parameter	J   	= 4'h9 ; //JUMP
parameter	JZ  	= 4'ha ; //JUMP ZERO
parameter	JC  	= 4'hb ; //JUMP CARREY
parameter	LDI 	= 4'hc ; //RD = MEM[{4'hf,INST[3:0]}]
parameter	GPIO	= 4'hd ; //SAMPLE GPIO IN AND OUT
parameter WRWB	= 4'he ; //Write Rd to wishbone address = [Rs,Rt]
parameter RDWB	= 4'hf ; //Read from wishbone to Rd address = [Rs,Rt]

wire	[15:0]			instr ;
reg 	[ADDR_W-1:0]	pc ;
reg		[15:0]			mem [127:0] ;
reg		[15:0]			registers [15:0] ;
wire	[3:0]			op ;
wire	[3:0]			rd ;
wire	[3:0]			rs ;
wire	[3:0]			rt ;
wire	[3:0]			imm ;
wire	[15:0]			ldi_val ;
wire	[ADDR_W-1:0]	j_imm ;
reg						zero ;
reg						carrey;
reg						i_int_d1, i_int_d2, i_int_diff ;

assign instr=mem[pc] ;

assign op  = instr[15:12] ;
assign rd  = instr[11:8] ;
assign rs  = instr[7:4] ;
assign rt  = instr[3:0] ;
assign imm = instr[3:0] ;
assign ldi_val = mem[{{(ADDR_W-4){1'b1}},instr[3:0]}] ;
assign j_imm = instr[ADDR_W-1:0] ;

wire	[7:0] init_addr0 ;
wire	[7:0] init_addr1 ;
assign init_addr0 = {i_init_addr,1'b0} ;
assign init_addr1 = {i_init_addr,1'b1} ;

wire  [7:0] init_addr0_reg ;
wire  [7:0] init_addr1_reg ;
assign init_addr0_reg = {i_init_addr_reg,1'b0} ;
assign init_addr1_reg = {i_init_addr_reg,1'b1} ;

always @(posedge i_clk) i_int_d1 <=#1 i_int ;
always @(posedge i_clk) i_int_d2 <=#1 i_int_d1 ;
always @(posedge i_clk) i_int_diff <=#1 i_int_d1 && ! i_int_d2 ;

always @(posedge i_clk) 
 	if (i_init_ram) begin
		 mem[init_addr0] = i_init_data[15: 0] ;
	   mem[init_addr1] = i_init_data[31:16] ;
		end
  else if (i_init_ram_reg) begin
     mem[init_addr0_reg] = i_init_data_reg[15: 0] ;
     mem[init_addr1_reg] = i_init_data_reg[31:16] ;
    end


always @(posedge i_clk or negedge i_rst_n) 
 		if (!i_rst_n) begin
			zero 		 <=#1 1'b0 ;
			carrey		 <=#1 1'b0 ;
			pc 			 <=#1 'd0 ;
			registers[0] <=#1 16'hdead ;
			registers[1] <=#1 16'hbeaf ;
			registers[2] <=#1 16'hdead ;
			registers[3] <=#1 16'hbeaf ;
			registers[4] <=#1 16'hdead ;
			registers[5] <=#1 16'hbeaf ;
			registers[6] <=#1 16'hdead ;
			registers[7] <=#1 16'hbeaf ;
			registers[8] <=#1 16'hdead ;
			registers[9] <=#1 16'hbeaf ;
			registers[10]<=#1 16'hdead ;
			registers[11]<=#1 16'hbeaf ;
			registers[12]<=#1 16'hdead ;
			registers[13]<=#1 16'hbeaf ;
			registers[14]<=#1 16'hdead ;
			registers[15]<=#1 16'hbeaf ;
          	o_wb_adr 	 <=#1 'd0 ;
          	o_wb_sel 	 <=#1 'd0 ;
          	o_wb_dat 	 <=#1 'd0 ;
          	o_wb_we  	 <=#1 'd0 ;
          	o_wb_cyc 	 <=#1 'd0 ;
          	o_wb_stb 	 <=#1 'd0 ;
		end
		else if (!i_sync_rst_n) begin
			zero 		 <=#1 1'b0 ;
			carrey		 <=#1 1'b0 ;
			pc 			 <=#1 'd0 ;
			registers[0] <=#1 16'hdead ;
			registers[1] <=#1 16'hbeaf ;
			registers[2] <=#1 16'hdead ;
			registers[3] <=#1 16'hbeaf ;
			registers[4] <=#1 16'hdead ;
			registers[5] <=#1 16'hbeaf ;
			registers[6] <=#1 16'hdead ;
			registers[7] <=#1 16'hbeaf ;
			registers[8] <=#1 16'hdead ;
			registers[9] <=#1 16'hbeaf ;
			registers[10]<=#1 16'hdead ;
			registers[11]<=#1 16'hbeaf ;
			registers[12]<=#1 16'hdead ;
			registers[13]<=#1 16'hbeaf ;
			registers[14]<=#1 16'hdead ;
			registers[15]<=#1 16'hbeaf ;
          	o_wb_adr 	 <=#1 'd0 ;
          	o_wb_sel 	 <=#1 'd0 ;
          	o_wb_dat 	 <=#1 'd0 ;
          	o_wb_we  	 <=#1 'd0 ;
          	o_wb_cyc 	 <=#1 'd0 ;
          	o_wb_stb 	 <=#1 'd0 ;
		end
		else if (i_memory_ready) begin
			if (i_int_diff) pc <=#1 'd2 ;
			else case(op)
				ADD : begin
						{carrey,registers[rd]} 	<=#1 registers[rs] + registers[rt] ; 
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] + registers[rt]) == 'd0 ;
						end
				SUB : begin
						registers[rd] 			<=#1 registers[rs] - registers[rt] ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] - registers[rt]) == 'd0 ;
						end
				AND : begin
						registers[rd] 			<=#1 registers[rs] & registers[rt] ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] & registers[rt]) == 'd0 ;
						end
				OR  : begin	
						registers[rd] 			<=#1 registers[rs] | registers[rt] ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] | registers[rt]) == 'd0 ;
						end
				XOR : begin
						registers[rd] 			<=#1 registers[rs] ^ registers[rt] ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] ^ registers[rt]) == 'd0 ;
						end
				ADDI: begin
						{carrey,registers[rd]}	<=#1 registers[rs] + imm ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] + imm) == 'd0 ;
						end
				SUBI: begin
						registers[rd] 			<=#1 registers[rs] - imm ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] - imm) == 'd0 ;
						end
				SLL : begin
						{carrey,registers[rd]}	<=#1 registers[rs] << imm ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] << imm) == 'd0 ;
						end
				SRL : begin
						registers[rd] 			<=#1 registers[rs] >> imm ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 (registers[rs] >> imm) == 'd0 ;
						end
				J   : begin
						pc <=#1 j_imm;
						end
				JZ  : begin
						if (zero)		pc <=#1 j_imm;
						else pc <=#1 	pc + 1'b1 ;
						end
				JC  : begin
						if (carrey)		pc <=#1 j_imm;
						else pc <=#1 	pc + 1'b1 ;
						end
				LDI : begin
						registers[rd] 			<=#1 ldi_val ;
						zero <=#1 ldi_val == 'd0 ;
						pc <=#1 pc + 1'b1 ;
						end
				GPIO: begin
						o_gpio					<=#1 registers[15] ;
						registers[15]			<=#1 i_gpio ;
						pc <=#1 pc + 1'b1 ;
						zero <=#1 i_gpio == 'd0 ;
						end
				WRWB: begin
          				o_wb_adr <=#1 {registers[rs],registers[rt]} ;
          				o_wb_sel <=#1 4'hf ;
          				o_wb_dat <=#1 o_copro_reverse_bus ? {registers[rd],o_wb_dat[15:0]} : {o_wb_dat[31:16],registers[rd]} ;
          				o_wb_we  <=#1 !i_wb_ack ;
          				o_wb_cyc <=#1 !i_wb_ack ;
          				o_wb_stb <=#1 !i_wb_ack ;
						if (i_wb_ack) pc <=#1 pc + 1'b1 ;
						end
				RDWB: begin
          				o_wb_adr <=#1 {registers[rs],registers[rt]} ;
          				o_wb_sel <=#1 4'hf ;
						if (i_wb_ack) registers[rd] <=#1 o_copro_reverse_bus ? i_wb_dat[31:16] : i_wb_dat[15:0] ;
          				o_wb_we  <=#1 1'b0 ;
          				o_wb_cyc <=#1 !i_wb_ack ;
          				o_wb_stb <=#1 !i_wb_ack ;
						if (i_wb_ack) pc <=#1 pc + 1'b1 ;
						end
		  endcase
	  end

endmodule

