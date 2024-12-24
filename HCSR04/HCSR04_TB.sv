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
rst = 'd1;
echo = 'd0;
#3 rst = 'd0;
#5 rst = 'd1;
#2 start = 'd1;
//#22 start = 'd1;
#20 start = 'd0;     // 1 clk
#210000 echo = 'd1;  // 10000 - time of trig, 200000 - time of sensor generate signal
#500000 echo = 'd0;  //  expected 85 mm, actual 82 mm  
//#1789630 echo = 'd0;  //  expected 304 mm, actual 301
//#23529411 echo = 'd0;  //  expected 4000 mm, actual 3997
#10000 $finish;
end
always
begin
#10 clk <= ~clk;
$display ("distance=%d, clk=%d, start=%d, trig=%d, echo=%d, val=%d, state=%d, cnt_t=%d, cnt_e=%d", distance, clk, start, rst, trig, echo,val, uut.state, uut.cnt_t, uut.cnt_e);
end
endmodule