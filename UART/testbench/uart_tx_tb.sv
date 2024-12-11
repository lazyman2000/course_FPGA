timeunit 1ns;
timeprecision 1ns;

`include "../rtl/if/uart_if.sv"

module uart_tx_tb();
   localparam DATA_WIDTH = 8;
   localparam BAUD_RATE  = 115200;
   localparam CLK_FREQ   = 100_000_000;

   uart_if #(DATA_WIDTH) txif();
   logic                 clk, rstn;

   //----------------------------------------------------------------------------- 
   // clock generator 
   localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ;

   initial begin
      clk = 1'b0;
      forever #(CLK_PERIOD / 2) clk = ~clk;
   end

   //----------------------------------------------------------------------------- 
   // DUT connection 
   uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) dut(.txif(txif),
                                                  .clk(clk),
                                                  .rstn(rstn));

   //----------------------------------------------------------------------------- 
   // test scenario 
   localparam LB_DATA_WIDTH = $clog2(DATA_WIDTH);
   localparam PULSE_WIDTH   = CLK_FREQ / BAUD_RATE;

   logic [DATA_WIDTH-1:0] data     = 0;

   int                    index    = 0;
   int                    success  = 1;
   int                    end_flag = 0;

   initial begin
      txif.data  = 0;
      txif.valid = 0;
      rstn       = 0;

      repeat(100) @(posedge clk);
      rstn       = 1;

      while(!end_flag) begin

         while(!txif.ready) @(posedge clk);
         txif.data  = data;
         txif.valid = 1;

         @(posedge clk); // Wait one cycle before deasserting valid
         txif.valid = 0;

         repeat(PULSE_WIDTH / 2) @(posedge clk);
         for(index = -1; index <= DATA_WIDTH; index++) begin
            case(index)
              -1:         if(txif.sig != 0)           success = 0;
              DATA_WIDTH: if(txif.sig != 1)           success = 0;
              default:    if(txif.sig != data[index]) success = 0;
            endcase

            repeat(PULSE_WIDTH) @(posedge clk);
         end

         if(data == $pow(2, DATA_WIDTH)-1) begin
            end_flag = 1;
         end
         else begin
            data++;
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
