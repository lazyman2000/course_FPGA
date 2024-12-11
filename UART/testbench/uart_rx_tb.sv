timeunit 1ns;
timeprecision 1ns;

`include "../rtl/if/uart_if.sv"

module uart_rx_tb();
   localparam DATA_WIDTH = 8;
   localparam BAUD_RATE  = 115200;
   localparam CLK_FREQ   = 100_000_000;

   uart_if #(DATA_WIDTH) rxif();
   logic clk, rstn;

   //----------------------------------------------------------------------------- 
   // clock generater 
   localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;

   initial begin
      clk = 1'b0;
      forever #(CLK_PERIOD / 2) clk = ~clk;
   end

   //----------------------------------------------------------------------------- 
   // DUT 
   uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) dut(.rxif(rxif),
                                                  .clk(clk),
                                                  .rstn(rstn));

   //----------------------------------------------------------------------------- 
   // test scenario 
   localparam LB_DATA_WIDTH = $clog2(DATA_WIDTH);
   localparam PULSE_WIDTH   = CLK_FREQ / BAUD_RATE;

   logic [DATA_WIDTH-1:0] data     = 0;

   int                    success  = 1;
   int                    end_flag = 0;
   int                    index    = 0;

   initial begin
      rxif.sig   = 1;
      rxif.ready = 0;
      rstn       = 0;

      repeat(100) @(posedge clk);
      rstn       = 1;

      while(!end_flag) begin

         for(index = -1; index <= DATA_WIDTH; index++) begin
            case(index)
              -1:         rxif.sig = 0;
              DATA_WIDTH: rxif.sig = 1;
              default:    rxif.sig = data[index];
            endcase

            repeat(PULSE_WIDTH) @(posedge clk);
         end

         while(!rxif.valid) @(posedge clk);

         $display("input : %b, result : %b", data, rxif.data);
         if(data != rxif.data) begin
            success = 0;
         end

         repeat($urandom_range(PULSE_WIDTH/2, PULSE_WIDTH)) @(posedge clk);
         rxif.ready = 1;

         repeat(1) @(posedge clk);
         rxif.ready = 0;

         if(data == 8'b1111_1111) begin
            end_flag = 1;
         end
         else begin
            data = data + 1;
         end
      end

      if(success) begin
         $display("simulation is success!");
      end
      else begin
         $display("simulation is failure!");
      end

      $finish;
   end

endmodule
