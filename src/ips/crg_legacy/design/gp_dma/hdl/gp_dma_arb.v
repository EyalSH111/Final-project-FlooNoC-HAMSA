module gp_dma_arb (
  cbus_clk,
  cbus_rst_n,
  cycle_start,
  dma_pending,
  priority0,
  priority1,
  priority2,
  priority3,
  owner,
  owner_oh,
  active
);

input         cbus_clk;
input         cbus_rst_n;
input         cycle_start;
input   [3:0] dma_pending;
input   [2:0] priority0;
input   [2:0] priority1;
input   [2:0] priority2;
input   [2:0] priority3;
output  [1:0] owner;
output  [3:0] owner_oh;
input         active;

parameter DMA0 = 2'd0; 
parameter DMA1 = 2'd1; 
parameter DMA2 = 2'd2; 
parameter DMA3 = 2'd3; 

reg   [1:0] owner;
reg   [1:0] n_owner;
wire  [3:0] owner_oh;
reg   [1:0] d1_owner;
reg   [1:0] nxt_owner;
reg   [1:0] rr_owner_p0;
reg   [1:0] rr_owner_p1;
reg   [1:0] rr_owner_p2;
reg   [1:0] rr_owner_p3;
reg   [1:0] rr_owner_p4;
reg   [1:0] rr_owner_p5;
reg   [1:0] rr_owner_p6;
reg   [1:0] rr_owner_p7;
reg   [1:0] rr_owner;
reg   [2:0] cur_pri;

assign owner_oh[0] = (owner == DMA0);
assign owner_oh[1] = (owner == DMA1);
assign owner_oh[2] = (owner == DMA2);
assign owner_oh[3] = (owner == DMA3);

// Remember who the last owner on the bus is
always @ (posedge cbus_clk)
begin
  if (!cbus_rst_n)
    d1_owner <= DMA0;
  else
    d1_owner <= owner;
end

// capture the next owner
always @ (posedge cbus_clk)
begin
  if (!cbus_rst_n)
    nxt_owner <= DMA0;
  else
    nxt_owner <= n_owner;
end

always @ (active or nxt_owner or d1_owner)
begin
  if (!active)
    owner = nxt_owner;
  else
    owner = d1_owner;
end

// keep the last owners for round-robin per priority
always @ (posedge cbus_clk)
begin
  if (!cbus_rst_n)
    begin
      rr_owner_p0 <= 2'd0;
      rr_owner_p1 <= 2'd0;
      rr_owner_p2 <= 2'd0;
      rr_owner_p3 <= 2'd0;
      rr_owner_p4 <= 2'd0;
      rr_owner_p5 <= 2'd0;
      rr_owner_p6 <= 2'd0;
      rr_owner_p7 <= 2'd0;
    end
  else if (active)
    case (cur_pri)
      3'd0     : rr_owner_p0 <= owner;
      3'd1     : rr_owner_p1 <= owner;
      3'd2     : rr_owner_p2 <= owner;
      3'd3     : rr_owner_p3 <= owner;
      3'd4     : rr_owner_p4 <= owner;
      3'd5     : rr_owner_p5 <= owner;
      3'd6     : rr_owner_p6 <= owner;
      default  : rr_owner_p7 <= owner;
    endcase
end

// only enable the rr arb for those with the highest priority
wire [3:0] pri_highest;
assign     pri_highest[0] = !((dma_pending[1] && (priority1 < priority0)) ||
                              (dma_pending[2] && (priority2 < priority0)) ||
                              (dma_pending[3] && (priority3 < priority0)));
assign     pri_highest[1] = !((dma_pending[0] && (priority0 < priority1)) ||
                              (dma_pending[2] && (priority2 < priority1)) ||
                              (dma_pending[3] && (priority3 < priority1)));
assign     pri_highest[2] = !((dma_pending[0] && (priority0 < priority2)) ||
                              (dma_pending[1] && (priority1 < priority2)) ||
                              (dma_pending[3] && (priority3 < priority2)));
assign     pri_highest[3] = !((dma_pending[0] && (priority0 < priority3)) ||
                              (dma_pending[1] && (priority1 < priority3)) ||
                              (dma_pending[2] && (priority2 < priority3)));
wire [3:0] pri_pending = pri_highest & dma_pending;

always @ (*)
begin
  if (active)
    case (d1_owner)
      DMA0    : cur_pri = priority0;
      DMA1    : cur_pri = priority1;
      DMA2    : cur_pri = priority2;
      default : cur_pri = priority3;
    endcase
  else if (pri_pending[0])
    cur_pri = priority0;
  else if (pri_pending[1])
    cur_pri = priority1;
  else if (pri_pending[2])
    cur_pri = priority2;
  else
    cur_pri = priority3;
end

always @ (*)
begin
  case (cur_pri)
    3'd0 :    rr_owner = rr_owner_p0;
    3'd1 :    rr_owner = rr_owner_p1;
    3'd2 :    rr_owner = rr_owner_p2;
    3'd3 :    rr_owner = rr_owner_p3;
    3'd4 :    rr_owner = rr_owner_p4;
    3'd5 :    rr_owner = rr_owner_p5;
    3'd6 :    rr_owner = rr_owner_p6;
    default : rr_owner = rr_owner_p7;
  endcase
end

// Round robin prioritized arbiter (fair)
always @ (*)
begin
  case (rr_owner) 
    DMA0: n_owner = (pri_pending[1]) ? DMA1 : (pri_pending[2]) ? DMA2 : (pri_pending[3]) ? DMA3 : DMA0; 
    DMA1: n_owner = (pri_pending[2]) ? DMA2 : (pri_pending[3]) ? DMA3 : (pri_pending[0]) ? DMA0 : DMA1; 
    DMA2: n_owner = (pri_pending[3]) ? DMA3 : (pri_pending[0]) ? DMA0 : (pri_pending[1]) ? DMA1 : DMA2; 
    DMA3: n_owner = (pri_pending[0]) ? DMA0 : (pri_pending[1]) ? DMA1 : (pri_pending[2]) ? DMA2 : DMA3;
    default: n_owner = rr_owner;
  endcase
end

endmodule
