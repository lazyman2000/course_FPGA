`timescale 1ns / 1ps

module BCD_SV_ff(
    input logic [13:0] bin_in,
    input logic clk,
    input logic rst,
    output logic [31:0] ascii_out, 
    input logic cross_ready, 
    output logic bcd_ready 
);

    logic [13:0] bin;
    logic [15:0] bcd;
    logic [3:0] i;
    
    enum logic [2:0] {RESET = 3'd0, START = 3'd1, SHIFT = 3'd2, ADD = 3'd3, DONE = 3'd4, FLAG = 3'd5} state, next_state;
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            state <= RESET;
        else
            state <= next_state;
    end
    
    always_comb begin
    if (cross_ready) begin //if crossbar recieved data from sensor
        case(state)
            START: 
                next_state = SHIFT;
            SHIFT:
                if (i == 4'd13)
                    next_state = DONE;
                else
                    next_state = ADD;
            ADD:
                next_state = SHIFT;
            DONE:
                next_state = FLAG;
            FLAG:
                next_state = START;
            RESET:
                next_state = START;
            default:
                next_state = RESET;
        endcase
        end else begin
           next_state = START;
    end
    end
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            bin <= 'd0;
            bcd <= 'd0;
            i <= 'd0;
            bcd_ready <= 1'b0;
            ascii_out <= 32'b0;
        end else if (cross_ready) begin 
            case(state)
                START: begin
                    bin <= bin_in;
                    bcd <= 'd0;
                    i <= 4'd0;
                    bcd_ready <= 1'b0;
                    //ascii_out <= 32'b0;
                    $display("inside START");
                    $display("START bin: %d", bin);
                end
                SHIFT: begin
                    bin <= {bin[12:0], 1'd0};
                    bcd <= {bcd[14:0], bin[13]};
                    i <= i + 4'd1;
                    $display("inside SHIFT");
                    $display("SHifted bin: %d", bin);
                    $display("bcd is: %d",bcd);
                end
                ADD: begin
                    if (bcd[3:0] > 'd4) bcd[3:0] <= bcd[3:0] + 4'd3;
                    if (bcd[7:4] > 'd4) bcd[7:4] <= bcd[7:4] + 4'd3;
                    if (bcd[11:8] > 'd4) bcd[11:8] <= bcd[11:8] + 4'd3;
                    if (bcd[15:12] > 'd4) bcd[15:12] <= bcd[15:12] + 4'd3;
                    $display("inside ADD");
                end
                DONE: begin
                    ascii_out <= {
                        (bcd[15:12] + 8'd48), //ASCII code for '0' is 8'd48
                        (bcd[11:8] + 8'd48),
                        (bcd[7:4] + 8'd48),
                        (bcd[3:0] + 8'd48)};
                    i <= 'd0;
                    $display("inside DONE");
                end
                FLAG: begin //just to guarantee that flag is set after the output assignment
                    bcd_ready <= 1'b1;
                    $display("inside FLAG");
                end
                RESET: begin
                    bin <= 'd0;
                    bcd <= 'd0;
                    i <= 'd0;
                    bcd_ready <= 1'b0;
                    $display("inside RESET");
                end
            endcase
        end
        $display("bin_in: %b, bcd: %b, ascii_out: %b",bin_in,bcd,ascii_out);
    end
endmodule
