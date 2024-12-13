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


module HCSR04(input logic clk, rst, start, echo,
output logic trig, val,                          
output logic [11:0] distance);                   
logic [2:0] state;
logic [21:0] cnt_e;
logic [9:0] cnt_t; // cnt = 10ns

enum logic [2:0] {RESET = 3'd0, SIG = 3'd1, START = 3'd2, TRIGGER = 3'd3, WAITER = 3'd4, ECHO = 3'd5, DONE = 3'd6} STATE;

always_ff @(posedge clk or negedge rst)
begin
if (!rst)
state <= RESET;
else
state <= SIG;
case (state)
RESET: 
begin
state <= SIG;
end
SIG: 
begin
 if (start)
 state <= START;
 else
 state <= SIG;
end
START: 
begin
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
  state <= RESET;
  end
 else
 begin
  if (cnt_e > 0)
   begin
   state <= RESET;
   end
  else
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

always_comb
begin
case(state)
RESET: 
begin
val <=0;
trig <=0;
cnt_t <=0;
cnt_e <=0;
distance <= 0;
end
SIG: 
begin
val <=0;
trig <=0;
cnt_t <=0;
cnt_e <=0;
distance <= 0;
end
DONE: 
begin
 if (cnt_e == 379999)  // 38 ms 
  begin
  val <=0;
  distance <= 0;
  end
 else
 begin
  if (cnt_e > 0)
   begin
   distance <= cnt_e*17/10000; // 340 m/s = 34*10^-5 ss/ns; N*cnt = N*10 ns; takes half => 17  
   val<=1;
   end
  else
  val <=0;
 end
end
endcase
end
endmodule