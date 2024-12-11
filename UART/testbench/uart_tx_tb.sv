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

   logic [DATA_WIDTH-1:0] data_from_sensor = 0; // Данные, полученные от датчика
   logic [DATA_WIDTH-1:0] data_to_send     = 0; // Данные для отправки

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

         // Получение данных от датчика (эмуляция)
         data_from_sensor = $random & ((1 << DATA_WIDTH) - 1); // Генерация случайных данных
         $display("[INFO] Time: %0t | Data received from sensor: %b", $time, data_from_sensor);

         // Ожидание готовности передатчика
         while(!txif.ready) begin
            $display("[WAIT] Time: %0t | Transmitter not ready. txif.ready: %b", $time, txif.ready);
            @(posedge clk);
         end

         // Отправка данных на ПК
         txif.data  = data_from_sensor; // Передача данных на передатчик
         txif.valid = 1;

         $display("[SEND] Time: %0t | Data sent to PC: %b | txif.valid: %b", $time, txif.data, txif.valid);

         @(posedge clk); // Wait one cycle before deasserting valid
         txif.valid = 0;

         // Проверка передачи данных по UART
         repeat(PULSE_WIDTH / 2) @(posedge clk);
         for(index = -1; index <= DATA_WIDTH; index++) begin
            case(index)
              -1:         if(txif.sig != 0) begin 
                            success = 0;
                            $display("[ERROR] Time: %0t | Start bit error detected!", $time);
                         end
              DATA_WIDTH: if(txif.sig != 1) begin 
                            success = 0;
                            $display("[ERROR] Time: %0t | Stop bit error detected!", $time);
                         end
              default:    if(txif.sig != data_from_sensor[index]) begin 
                            success = 0;
                            $display("[ERROR] Time: %0t | Data mismatch detected at index %0d! Expected: %b, Got: %b", 
                                      $time, index, data_from_sensor[index], txif.sig);
                         end
            endcase

            repeat(PULSE_WIDTH) @(posedge clk);
         end

         $display("[STATUS] Time: %0t | Data transmission completed for data: %b", $time, data_from_sensor);

         // Завершение теста
         if(data_from_sensor == $pow(2, DATA_WIDTH)-1) begin
            end_flag = 1;
         end
         else begin
            data_to_send++;
         end
      end

      // Результат теста
      if(success) begin
         $display("[RESULT] Time: %0t | Simulation is SUCCESS!", $time);
      end
      else begin
         $display("[RESULT] Time: %0t | Simulation is FAILURE!", $time);
      end

      $finish;
   end

endmodule
