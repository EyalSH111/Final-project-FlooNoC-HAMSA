//the following module is used to convert 128b instruction interface to 32b
//towards axi
//
//******************************************************************
//      >>> performance was not my goal, only correctness <<<
// >>> this module's preofrmance is probably might sub-optimal <<<
//******************************************************************
module inst_narrower(/*autoarg*/
   // Outputs
   core_axi_i_wide_gnt, core_axi_i_wide_rvalid, core_axi_i_wide_rdata,
   core_axi_i_narrow_req, core_axi_i_narrow_addr,
   // Inputs
   clk, rst_n, core_axi_i_wide_req, core_axi_i_wide_addr,
   core_axi_i_narrow_gnt, core_axi_i_narrow_rvalid,
   core_axi_i_narrow_rdata
   );
parameter INSTR_RDATA_WIDTH=128;

//CLOCK AND RESET
input                                clk;
input                                rst_n;

//WIDE I/F
input                                core_axi_i_wide_req;
input [31:0]                         core_axi_i_wide_addr;
output logic                         core_axi_i_wide_gnt;
output logic                         core_axi_i_wide_rvalid;
output logic [INSTR_RDATA_WIDTH-1:0] core_axi_i_wide_rdata;

//NARROW I/F
output logic                         core_axi_i_narrow_req;
output logic [31:0]                  core_axi_i_narrow_addr;
input                                core_axi_i_narrow_gnt;
input                                core_axi_i_narrow_rvalid;
input [31:0]                         core_axi_i_narrow_rdata;


generate
if (INSTR_RDATA_WIDTH==32) begin
    assign core_axi_i_narrow_req  = core_axi_i_wide_req;
    assign core_axi_i_narrow_addr = core_axi_i_wide_addr;
    assign core_axi_i_wide_gnt    = core_axi_i_narrow_gnt;
    assign core_axi_i_wide_rvalid = core_axi_i_narrow_rvalid;
    assign core_axi_i_wide_rdata  = core_axi_i_narrow_rdata;
end else begin
    logic busy;
    logic [31:0] wide_addr;
    logic [2:0] transaction_number;


    assign core_axi_i_wide_gnt = core_axi_i_wide_req && !busy;

    assign core_axi_i_narrow_addr = wide_addr + transaction_number*4;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            busy <= 1'b0;
            transaction_number <= 3'b0;
            wide_addr <= 32'h0;
            core_axi_i_narrow_req <= 1'b0;
            core_axi_i_wide_rdata <= 128'b0;
            core_axi_i_wide_rvalid <= 1'b0;
        end
        else begin
            if (core_axi_i_wide_req && core_axi_i_wide_gnt) begin
                busy <= 1'b1;
                wide_addr <= core_axi_i_wide_addr;
                transaction_number <= 3'h0;
            end

            if (core_axi_i_wide_req && !busy) //first narrow request triggered by wide req
                core_axi_i_narrow_req <= 1'b1;

            if (core_axi_i_narrow_rvalid && transaction_number!=3'h4) //following requests triggered by narrow rvalid
                core_axi_i_narrow_req <= 1'b1;

            if (core_axi_i_narrow_req && core_axi_i_narrow_gnt) begin //narrow_request is deasserted on narrow_gnt
                core_axi_i_narrow_req <= 1'b0;
                transaction_number <= transaction_number + 3'h1;
            end

            if (core_axi_i_narrow_rvalid) begin // sample data on rvalid
                core_axi_i_wide_rdata[32*(transaction_number)-1 -: 32] <= core_axi_i_narrow_rdata; //transaction_number is incremented in advance
                if (transaction_number==3'h4) begin // and assert wide_rvalid after last
                    core_axi_i_wide_rvalid <= 1'b1;
                    busy <= 1'b0;
                end
            end

            if (core_axi_i_wide_rvalid) begin //transaction ends on wide_rvalid
                core_axi_i_wide_rvalid <= 1'b0;
            end
        end

end
endgenerate

endmodule
