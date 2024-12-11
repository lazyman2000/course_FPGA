`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.12.2024 19:31:48
// Design Name: 
// Module Name: HCSR04_TB
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


module HCSR04_TB;
reg clk, rst, start, echo, trig, val;
reg [11:0] distance;

HCSR04 uut (.clk(clk),.rst(rst),.start(start),.echo(echo),.trig(trig),.distance(distance),.val(val));

initial
begin
start = 'd0;
clk = 'd0;
rst = 'd0;
echo = 'd0;
#3 rst = 'd1;
#1 rst = 'd0;
#5 start = 'd1;
#1 start = 'd0;
#10500 echo = 'd1;
#500000 echo = 'd0; //  85mm  cm
#50 $finish;
end
always
begin
#5 clk <= ~clk;
$display ("distance=%d, clk=%d, start=%d, trig=%d, echo=%d, val=%d, state=%d, cnt_t=%d, cnt_e=%d", distance, clk, start, rst, trig, echo,val, uut.state, uut.cnt_t, uut.cnt_e);
end
endmodule
