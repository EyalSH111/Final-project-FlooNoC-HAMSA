// +FHDR------------------------------------------------------------
//                 Copyright (c) 2020 EnICS.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : dummy_mem.v
// Author        : shoshay
// Created On    : 2020-10-28 15:06
// Last Modified : 
// -----------------------------------------------------------------
// Description:
//
//
// -FHDR------------------------------------------------------------

`timescale 1ns/1ps

module dummy_mem #(
    parameter AXI4_DATA_WIDTH   = 32,
    parameter AXI_NUMBYTES       = AXI4_DATA_WIDTH/8,
    parameter MEM_ADDR_WIDTH     = 13
)
(
    input logic                                     clk,
    input logic                                     rstn, 

    output  logic                                    MGRANT_i     ,
    input logic                                    CEN_o        ,
    input logic                                    WEN_o        ,
    input logic  [MEM_ADDR_WIDTH-1:0]              A_o          ,
    input logic  [AXI4_DATA_WIDTH-1:0]            D_o          ,
    input logic  [AXI_NUMBYTES-1:0]                BE_o         ,
    output  logic  [AXI4_DATA_WIDTH-1:0]            Q_i
);

logic [AXI4_DATA_WIDTH-1:0] mem_arr [(1<<MEM_ADDR_WIDTH)-1:0];

logic mem_en;
assign mem_en = ~CEN_o;
logic write;
assign write = ~WEN_o;
logic [MEM_ADDR_WIDTH-1:0] raddr;

logic busy, busy_soon;
logic [9:0] cnt;

assign busy_soon = ~busy & (cnt == 'h0);

always @ (posedge clk or negedge rstn)
   if (!rstn)
      cnt <= 'h0;
   else if (cnt == 'h0)
      cnt <= 'h100;
   else
      cnt <= cnt - 'h1;

always @ (posedge clk or negedge rstn)
   if (!rstn)
      busy <= 1'b0;
   else if (cnt == 'h0)
      busy <= ~busy;

assign MGRANT_i = ~busy;


always @ (posedge clk)
   if (mem_en & ~(busy | busy_soon))
      if (write)
         mem_arr[A_o] <= D_o;

always @ (posedge clk)
   if ((mem_en & ~(busy|busy_soon)) & ~write)
      raddr <= A_o;
   else
      raddr <= 'hx;

always @ (*)
   Q_i = mem_arr[raddr];

endmodule

