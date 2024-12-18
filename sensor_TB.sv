`timescale 1ns / 0.1ps
module sensor_TB();

  parameter DATA_WIDTH = 8;
  parameter BAUD_RATE  = 115200;
  parameter CLK_FREQ   = 100_000_000;

  // Локальные параметры
  localparam PULSE_WIDTH = CLK_FREQ / BAUD_RATE;

logic clk;
logic rst_n;
logic uart_rx_i;
logic uart_tx_o;
tri   dht11_data;
logic       echo;
logic       trig;
logic dht11_data_output; // когда 1 это выход (для датчика), когда 0 - вход для датчика
logic dht11_data_internal; // когда dht11_data_output=1, можно отправитб 1/0 микроконтроллеру
logic [39:0] data_sequence;
assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz; // tri-state 
sensor_top i_sensor (
    .*
);


 task send_uart_data(input [DATA_WIDTH-1:0] data);
    integer i;
    begin
      // Генерация стартового бита
      uart_rx_i = 0;
      #(PULSE_WIDTH * 10);

      // Генерация бит данных
      for (i = 0; i < DATA_WIDTH; i = i + 1) begin
        uart_rx_i = data[i];
        #(PULSE_WIDTH * 10);
      end

      // Генерация стопового бита
      uart_rx_i = 1;
      #(PULSE_WIDTH * 10);
    end
  endtask

initial begin
    clk = 0;
end

initial forever begin
    #10 clk = ~clk;
end

initial begin
    rst_n = 1'b1;
    #10 rst_n = 1'b0;
    #100 rst_n = 1'b1;
    send_uart_data(8'h54); 
    #23_000_000 $finish;
end

    initial begin
    
        // В течение 1 sec DHT11 стабилизируется (учитываем это в rtl)
        dht11_data_output = 0; // устанавливаем на вход
        
        // Ожидаем команду 0 от микроконтроллера
         wait(dht11_data == 0);
         #18_000_000; // Распознаем в течение 18 мс
            
         // Ответ DHT11:
         dht11_data_output = 1; // Устанавливаем на выход
         
         dht11_data_internal = 0; // Передаем низкий сигнал микроконтроллеру
         #80_000; // Низкий сигнал (80 мкс)

         dht11_data_internal = 1; // Передаем высокий сигнал
         #80_000; // Высокий сигнал (80 мкс)

          // Будем передавать такую последовательность бит: 00110101_00000000_00011000_00000000_01001101
          data_sequence = 40'b0011010100000000000110000000000001001101;
            for (int i = 0; i < 40; i++) begin
                if (data_sequence[i] == 0) begin
                    // Передаем бит '0'
                    dht11_data_internal = 0; // Устанавливаем низкий уровень
                    #50_000; // Удерживаем низкий уровень (50 мкс)
                    dht11_data_internal = 1; // Устанавливаем высокий уровень
                    #28_000; // Задержка для завершения бита '0' (26-28 мкс)
                end else begin
                    // Передаем бит '1'
                    dht11_data_internal = 0; // Устанавливаем низкий уровень
                    #50_000; // Низкий уровень (50 мкс)
                    dht11_data_internal = 1; // Устанавливаем высокий уровень
                    #70_000; // Задержка для завершения бита '1' (70 мкс)
                end
            end
             
             // окончание передачи данных
             dht11_data_internal = 0; // Устанавливаем низкий уровень
             #50_000; // Низкий уровень (50 мкс)
             dht11_data_output = 0; // выставляем на вход
            // Ожидание перед следующей итерацией цикла обмена

        end
endmodule: sensor_TB