`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2024 09:29:48
// Design Name: 
// Module Name: HCSR04
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


module HCSR04(clk, rst, start, echo, trig, distance, val);
input clk, rst, start, echo; 
output reg trig, val;
output reg [11:0] distance;  // in mm
logic [2:0] state;
reg [21:0] cnt_e;
reg [9:0] cnt_t; // cnt = 10ns

enum logic [2:0] {RESET = 3'd0, START = 3'd1, TRIGGER = 3'd2, WAITER = 3'd3, ECHO = 3'd4, DONE = 3'd5} STATE;

always_ff @(posedge clk)
begin
if (rst)
state <= RESET;
else
 if (start)
 state <= START;
 else
 state <= RESET;
case (state)
RESET: 
begin
val <=0;
trig <=0;
cnt_t <=0;
cnt_e <=0;
state <= START;
end
START: 
begin
val <=0;
trig <=1;
state <= TRIGGER;
end
TRIGGER: 
begin
if (cnt_t == 999)
  begin
  trig <=0;
  cnt_t <= 0;
  state <= WAITER;
  end
 else
  begin
  cnt_t <= cnt_t +1;
  state <= TRIGGER;  
  end 
end
WAITER:
begin
 if(echo)
  begin
  cnt_e <= cnt_e +1;
  state <= ECHO;
  end
 else
  state <= WAITER; 
end
ECHO: 
begin
 if (echo)
  begin
  cnt_e <= cnt_e +1;
  state <= ECHO;
  end
 else
  state <= DONE;
end
DONE: 
begin
 if (cnt_e == 379999)  // 38 ms 
  begin
  val <=0;
  distance <= 0;
  state <= RESET;
  end
 else
 begin
  if (cnt_e > 0)
   begin
   distance <= cnt_e*17/10000; // 340 m/s = 34*10^-5 ss/ns; N*cnt = N*10 ns; takes half => 17  
   val<=1;
   state <= RESET;
   end
  else
  val <=0;
  state <= RESET;
 end
end
 default:
  begin
  val <=0;
  trig <=0;
  cnt_e <=0; 
  cnt_t <=0; 
  state <= RESET;
  end
endcase
end
endmodule
