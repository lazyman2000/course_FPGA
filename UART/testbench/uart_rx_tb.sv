timeunit 1ns;
timeprecision 1ns;
`include "../rtl/if/uart_if.sv"

module uart_rx_tb;

  // Параметры
  parameter DATA_WIDTH = 8;
  parameter BAUD_RATE  = 115200;
  parameter CLK_FREQ   = 100_000_000;

  // Локальные параметры
  localparam PULSE_WIDTH = CLK_FREQ / BAUD_RATE;

  // Сигналы для теста
  logic clk;
  logic rstn;
  logic sensor_ready;
  logic [DATA_WIDTH-1:0] sensor_data;
  logic sensor_valid;
  logic rx_sig;

  // Тестируемый модуль
  uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uut (
    .clk(clk),
    .rstn(rstn),
    .sensor_ready(sensor_ready),
    .sensor_data(sensor_data),
    .sensor_valid(sensor_valid),
    .rx_sig(rx_sig)
  );

  // Генератор тактового сигнала
  initial clk = 0;
  always #(5) clk = ~clk; // Период 10 нс -> 100 МГц

  // Задача для генерации UART-сигнала
  task send_uart_data(input [DATA_WIDTH-1:0] data);
    integer i;
    begin
      // Генерация стартового бита
      rx_sig = 0;
      #(PULSE_WIDTH * 10);

      // Генерация бит данных
      for (i = 0; i < DATA_WIDTH; i = i + 1) begin
        rx_sig = data[i];
        #(PULSE_WIDTH * 10);
      end

      // Генерация стопового бита
      rx_sig = 1;
      #(PULSE_WIDTH * 10);
    end
  endtask

  // Инициализация сигналов
  initial begin
    rstn = 0;
    sensor_ready = 0;
    rx_sig = 1; // Линия в состоянии покоя

    #(PULSE_WIDTH * 10);
    rstn = 1;

    // Тестовые сценарии

    // Сценарий 1: ПК отправляет данные, датчик не готов
    $display("Scenario 1: Waiting for sensor to be ready after receiving data from PC");
    send_uart_data(8'hA5); // Отправляем 0xA5
    #(PULSE_WIDTH * 50); // Датчик не готов некоторое время
    sensor_ready = 1;    // Датчик становится готов
    #(PULSE_WIDTH * 20);
    sensor_ready = 0;

    // Сценарий 2: ПК перезаписывает буфер, датчик не готов
    $display("Scenario 2: Buffer overwritten by PC while waiting for sensor readiness");
    send_uart_data(8'h5A); // Отправляем 0x5A
    #(PULSE_WIDTH * 30);
    send_uart_data(8'hFF); // Перезаписываем буфер новым значением 0xFF
    #(PULSE_WIDTH * 20);
    sensor_ready = 1; // Датчик становится готов
    #(PULSE_WIDTH * 20);
    sensor_ready = 0;

    // Сценарий 3: Датчик заранее готов
    $display("Scenario 3: Sensor ready before PC data is received");
    sensor_ready = 1; // Датчик готов заранее
    send_uart_data(8'hC3); // Отправляем 0xC3
    #(PULSE_WIDTH * 20);
    sensor_ready = 0;

    // Завершение симуляции
    #(PULSE_WIDTH * 50);
    $finish;
  end

  // Мониторинг сигналов
  initial begin
    $monitor($time, 
             " sensor_ready=%b, sensor_valid=%b, sensor_data=%h", 
             sensor_ready, sensor_valid, sensor_data);
  end

endmodule
