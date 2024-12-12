`timescale 1ns / 1ps

module BCD_SV_ff(
    input logic [13:0] bin_in,
    input logic clk,
    input logic rst,
    output logic [31:0] ascii_out,
    output logic ready
);

    logic [13:0] bin;
    logic [15:0] bcd;
    logic [3:0] i;
    
    enum logic [2:0] {RESET = 3'd0, START = 3'd1, SHIFT = 3'd2, ADD = 3'd3, DONE = 3'd4} state, next_state;
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            state <= RESET;
        else
            state <= next_state;
    end
    
    always_comb begin
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
                next_state = START;
            RESET:
                next_state = START;
            default:
                next_state = RESET;
        endcase
    end
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            bin <= 'd0;
            bcd <= 'd0;
            i <= 'd0;
            ready <= 1'b0;
            ascii_out <= 32'b0;
        end else begin
            case(state)
                START: begin
                    bin <= bin_in;
                    bcd <= 'd0;
                    i <= 4'd0;
                    ready <= 1'b0;
                end
                SHIFT: begin
                    bin <= {bin[12:0], 1'd0};
                    bcd <= {bcd[14:0], bin[13]};
                    i <= i + 4'd1;
                end
                ADD: begin
                    if (bcd[3:0] > 4'd4) bcd[3:0] <= bcd[3:0] + 4'd3;
                    if (bcd[7:4] > 4'd4) bcd[7:4] <= bcd[7:4] + 4'd3;
                    if (bcd[11:8] > 4'd4) bcd[11:8] <= bcd[11:8] + 4'd3;
                    if (bcd[15:12] > 4'd4) bcd[15:12] <= bcd[15:12] + 4'd3;
                end
                DONE: begin
                    ascii_out <= {
                        (bcd[15:12] + 8'd48),
                        (bcd[11:8] + 8'd48),
                        (bcd[7:4] + 8'd48),
                        (bcd[3:0] + 8'd48)};
                    ready <= 1'b1;
                    $display("inside DONE");
                end
                RESET: begin
                    bin <= 'd0;
                    bcd <= 'd0;
                    i <= 'd0;
                    ready <= 1'b0;
                end
            endcase
        end
        $display("bin_in: %b, bcd: %b, ascii_out: %b",bin_in,bcd,ascii_out);
    end
endmodule
