module openocd_bitbang(
    input logic         clk,
    input logic         rstn,

    input logic         rx_valid,
    input logic [7:0]   rx_data,
    output logic        rx_ready,
    
    output logic        tx_valid,
    output logic [7:0]  tx_data,
    input logic         tx_ready,

    OPENOCD_JTAG.master openocd_jtag
);
localparam IDLE = 4'd0;
localparam S_B  = 4'd1;
localparam S_b  = 4'd2;
localparam S_R  = 4'd3;
localparam S_r  = 4'd4;
localparam S_s  = 4'd5;
localparam S_t  = 4'd6;
localparam S_u  = 4'd7;
localparam S_0  = 4'd8;
localparam S_1  = 4'd9;
localparam S_2  = 4'd10;
localparam S_3  = 4'd11;
localparam S_4  = 4'd12;
localparam S_5  = 4'd13;
localparam S_6  = 4'd14;
localparam S_7  = 4'd15;

localparam S_04 = {S_4, S_0};
localparam S_15 = {S_5, S_1};
localparam S_26 = {S_6, S_2};
localparam S_37 = {S_7, S_3};

localparam S_R4 = {S_4, S_R};
localparam S_R5 = {S_5, S_R};
localparam S_R6 = {S_6, S_R};
localparam S_R7 = {S_7, S_R};

localparam S_0R4 = {S_R4, S_0};
localparam S_1R5 = {S_R5, S_1};
localparam S_2R6 = {S_R6, S_2};
localparam S_3R7 = {S_R7, S_3};


localparam CNT = 4'h7;

logic [15:0] state;
logic [15:0] next_state;

logic is_B;
logic is_b;
logic is_R;
logic is_Q;
logic is_0;
logic is_1;
logic is_2;
logic is_3;
logic is_4;
logic is_5;
logic is_6;
logic is_7;
logic is_r;
logic is_s;
logic is_t;
logic is_u;
logic next_state_is_R;
assign is_B = (state[3:0] == S_B);
assign is_b = (state[3:0] == S_b);
assign is_0 = (state[3:0] == S_0);
assign is_1 = (state[3:0] == S_1);
assign is_2 = (state[3:0] == S_2);
assign is_3 = (state[3:0] == S_3);
assign is_4 = (state[3:0] == S_4);
assign is_5 = (state[3:0] == S_5);
assign is_6 = (state[3:0] == S_6);
assign is_7 = (state[3:0] == S_7);
assign is_r = (state[3:0] == S_r);
assign is_s = (state[3:0] == S_s);
assign is_t = (state[3:0] == S_t);
assign is_u = (state[3:0] == S_u);
assign is_R = (state[3:0] == S_R);
assign next_state_is_R = (next_state[3:0] == S_R);

logic [3:0] cnt;
logic cnt_exp;
always @(posedge clk or negedge rstn)
    if (!rstn)
        cnt <= CNT;
    else
        if (next_state != state)
            cnt <= CNT;
        else if (cnt!=0)
            cnt <= cnt - 1;
assign cnt_exp = cnt == 0;

logic rx_trans;
assign rx_trans = rx_valid && rx_ready;
assign rx_ready = (state == IDLE && cnt_exp);

logic tx_trans;
assign tx_trans = tx_valid && tx_ready;
always @(posedge clk or negedge rstn)
    if (!rstn)
        tx_valid <= 1'b0;
    else begin
        if (next_state_is_R && !is_R) //set only on state change
            tx_valid <= 1'b1;
        if (tx_trans) //clear once data transferred
            tx_valid <= 1'b0;
    end
assign tx_data = "0"+openocd_jtag.tdo;


always @(posedge clk or negedge rstn)
    if (!rstn)
        state <= IDLE;
    else
        state <= next_state;

always @(*) begin
    next_state = state;
    if (cnt_exp && (tx_trans || !tx_valid)) begin
        case (state)
            IDLE: begin
                if (rx_trans) begin
                    case (rx_data) //source: https://sourceforge.net/p/openocd/code/ci/master/tree/doc/manual/jtag/drivers/remote_bitbang.txt
                        "B": next_state = S_B;
                        "b": next_state = S_b;
                        "R": next_state = S_R;
                        "Q": next_state = IDLE; //Q does nothing
                        "0": next_state = S_0;
                        "1": next_state = S_1;
                        "2": next_state = S_2;
                        "3": next_state = S_3;
                        "4": next_state = S_4;
                        "5": next_state = S_5;
                        "6": next_state = S_6;
                        "7": next_state = S_7;
                        "r": next_state = S_r;
                        "s": next_state = S_s;
                        "t": next_state = S_t;
                        "u": next_state = S_u;

                        ")": next_state = S_04;
                        "!": next_state = S_15;
                        "@": next_state = S_26;
                        "#": next_state = S_37;

                        "$": next_state = S_0R4;
                        "%": next_state = S_1R5;
                        "^": next_state = S_2R6;
                        "&": next_state = S_3R7;
                        default: begin
                            $error("openocd_bitbang (%m) received unsupported character (%d) '%c'", rx_data, rx_data);
                            $finish(1);
                        end
                    endcase
                end
            end

            default: next_state = state>>4;
        endcase
    end //if cnt_exp
end //always

always @(posedge clk or negedge rstn)
    if (!rstn) begin
        openocd_jtag.srst <=1;
        openocd_jtag.trst <=1;
        openocd_jtag.tck  <=0; 
        openocd_jtag.tms  <=0; 
        openocd_jtag.tdi  <=0; 
        openocd_jtag.led  <=0;
        openocd_jtag.quit <=0;
    end else begin
        if (is_B)
            openocd_jtag.led <= 1'b1;

        if (is_b)
            openocd_jtag.led <= 1'b0;

        if (is_Q)
            openocd_jtag.quit <= 1'b1;
        else
            openocd_jtag.quit <= 1'b0;

        if (is_0) begin
            openocd_jtag.tck <= 1'b0;
            openocd_jtag.tms <= 1'b0;
            openocd_jtag.tdi <= 1'b0;
        end

        if (is_1) begin
            openocd_jtag.tck <= 1'b0;
            openocd_jtag.tms <= 1'b0;
            openocd_jtag.tdi <= 1'b1;
        end

        if (is_2) begin
            openocd_jtag.tck <= 1'b0;
            openocd_jtag.tms <= 1'b1;
            openocd_jtag.tdi <= 1'b0;
        end

        if (is_3) begin
            openocd_jtag.tck <= 1'b0;
            openocd_jtag.tms <= 1'b1;
            openocd_jtag.tdi <= 1'b1;
        end

        if (is_4) begin
            openocd_jtag.tck <= 1'b1;
            openocd_jtag.tms <= 1'b0;
            openocd_jtag.tdi <= 1'b0;
        end

        if (is_5) begin
            openocd_jtag.tck <= 1'b1;
            openocd_jtag.tms <= 1'b0;
            openocd_jtag.tdi <= 1'b1;
        end

        if (is_6) begin
            openocd_jtag.tck <= 1'b1;
            openocd_jtag.tms <= 1'b1;
            openocd_jtag.tdi <= 1'b0;
        end

        if (is_7) begin
            openocd_jtag.tck <= 1'b1;
            openocd_jtag.tms <= 1'b1;
            openocd_jtag.tdi <= 1'b1;
        end

        if (is_r) begin
            openocd_jtag.trst <= 2'b0;
            openocd_jtag.srst <= 2'b0;
        end

        if (is_s) begin
            openocd_jtag.trst <= 2'b0;
            openocd_jtag.srst <= 2'b1;
        end

        if (is_t) begin
            openocd_jtag.trst <= 2'b1;
            openocd_jtag.srst <= 2'b0;
        end

        if (is_u) begin
            openocd_jtag.trst <= 2'b1;
            openocd_jtag.srst <= 2'b1;
        end

    end


endmodule
