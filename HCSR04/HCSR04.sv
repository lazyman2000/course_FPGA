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


module HCSR04(input logic clk, rst, start, echo,   // clk - 20ns, start - from crossbar, echo - from sensor
output logic trig, val,                            // trig - to sensor, val - to crossbar (validation)
output logic [11:0] distance);                     // data for crossbar im mm
logic [2:0] state;
logic [27:0] cnt_e;                                // time counter of echo
logic [11:0] cnt_t;                                 // time counter of trig 
logic [31:0] dist_m;                               // data*10000 for divition

enum logic [2:0] {RESET = 3'd0, SIG = 3'd1, START = 3'd2, TRIGGER = 3'd3, WAITER = 3'd4, ECHO = 3'd5, DONE = 3'd6} STATE;

always_ff @(posedge clk or negedge rst)
begin
if (!rst) begin
state <= RESET;
trig <=0;
cnt_t <=0;
cnt_e <=0; 
end
else begin
state <= SIG;
case (state)
RESET:                                                    
begin
state <= SIG;
trig <=0;
cnt_t <=0;
cnt_e <=0;                
end
SIG:                       // waiting of start signal 
begin
trig <=0;
cnt_t <=0;
cnt_e <=0; 
 if (start)
 state <= START;
 else
 state <= SIG;
end
START: 
begin
trig <=1;                // creation of trig signal
state <= TRIGGER;
end
TRIGGER: 
begin
if (cnt_t == 499)       // waitin 10 us (500*20ns); end of trig ignal
  begin
  trig <=0;         
  state <= WAITER;
  end
 else
  begin
  cnt_t <= cnt_t +1;  // count while cnt_t < 499
  state <= TRIGGER;  
  end 
end
WAITER:              // waiting for a echo signal fron senson
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
  cnt_e <= cnt_e +1;   // count number of clock while echo is on
  state <= ECHO; 
  end
 else 
  state <= DONE;
end
DONE: 
begin
  if ((cnt_e > 0) && (cnt_e != 1899999))     // checked that echo is not null
   begin
   state <= SIG;
   end
  else
  state <= RESET;
end
 default:
  begin
  state <= RESET;
  end
endcase
end
end

always_comb
begin
val = 0;
distance = 0;
dist_m = 0;
case(state)
DONE: 
begin
  if ((cnt_e > 0) && (cnt_e != 1899999))
   begin
   dist_m = cnt_e*34;           // 340 m/s = 34*10^-5 ss/ns; N*cnt = N*20 ns; takes half => 17*2; 10^-5*10 => 10^-4            
   distance = (dist_m >>> 14) + (dist_m >>> 15) + (dist_m >>> 17) + (dist_m >>> 21) + (dist_m >>> 22) + (dist_m >>> 24)+ (dist_m >>> 25)
   +(dist_m >>> 27)+(dist_m >>> 28)+(dist_m >>> 29);  
   val = 1;                     // 10^-4 = 0.00000000000001101000110110111 (shifi left by degrees corresponding to 1)
   end                         // calculating the distance and setting the validity flag
end
endcase
end
endmodule


/*always_comb
begin
dist_m = 0;
case(state)
RESET:
begin
val = 0;
distance = 0;
end
START:
begin
val = 0;
distance = 0;
end
DONE: 
begin
  if ((cnt_e > 0) && (cnt_e != 1899999))
   begin
   dist_m = cnt_e*34;           // 340 m/s = 34*10^-5 ss/ns; N*cnt = N*20 ns; takes half => 17*2; 10^-5*10 => 10^-4            
   distance = (dist_m >>> 14) + (dist_m >>> 15) + (dist_m >>> 17) + (dist_m >>> 21) + (dist_m >>> 22) + (dist_m >>> 24)+ (dist_m >>> 25)
   +(dist_m >>> 27)+(dist_m >>> 28)+(dist_m >>> 29);  
   val = 1;                     // 10^-4 = 0.00000000000001101000110110111 (shifi left by degrees corresponding to 1)
   end                         // calculating the distance and setting the validity flag
end
endcase
end
*/
