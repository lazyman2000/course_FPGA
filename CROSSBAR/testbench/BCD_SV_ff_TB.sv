`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.12.2024 12:37:19
// Design Name: 
// Module Name: BCD_SV_ff_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BCD_TB;
// Inputs
reg [13:0] bin_in;
reg clk;
reg rst;
// Outputs
wire [31:0] ascii_out;
wire [3:0] ascii_out1, ascii_out10, ascii_out100, ascii_out1000;
// Instantiate the Unit Under Test (UUT)
BCD_SV_ff uut (
.bin_in(bin_in),
.clk(clk),
.rst(rst),
.ascii_out(ascii_out)
);
assign ascii_out1 = ascii_out[7:0];
assign ascii_out10 = ascii_out[15:8];
assign ascii_out100 = ascii_out[23:16];
assign ascii_out1000 = ascii_out[31:24];
initial
begin
bin_in = 'd0;
clk = 'd0;
rst = 'd1;
#4 rst = 'd0;
#1 rst = 'd1;
#1 bin_in = 'd11;
#10 bin_in = 'd243;
#120 $finish;
end
always
begin
#1 clk <= ~clk;
end
endmodule
