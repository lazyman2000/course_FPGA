timeunit 1ns;
timeprecision 1ns;

module uart_tx_tb;

  // Параметры
  parameter DATA_WIDTH = 8;
  parameter BAUD_RATE  = 115200;
  parameter CLK_FREQ   = 100_000_000;

  // Локальные параметры
  localparam PULSE_WIDTH = CLK_FREQ / BAUD_RATE;

  // Сигналы для теста
  logic clk;
  logic rstn;
  logic [DATA_WIDTH-1:0] data_from_sensor;
  logic valid_from_sensor;
  logic ready_to_sensor;
  logic tx_sig;

  // Тестируемый модуль
  uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uut (
    .clk(clk),
    .rstn(rstn),
    .data_from_sensor(data_from_sensor),
    .valid_from_sensor(valid_from_sensor),
    .ready_to_sensor(ready_to_sensor),
    .tx_sig(tx_sig)
  );

  // Генератор тактового сигнала
  initial clk = 0;
  always #(5) clk = ~clk; // Период 10 нс -> 100 МГц

  // Инициализация сигналов
  initial begin
    rstn = 0;
    data_from_sensor = 0;
    valid_from_sensor = 0;

    // Сброс
    #(PULSE_WIDTH * 10);
    rstn = 1;
    // Тестовые сценарии

    // Сценарий 1: Датчик не отправляет данные
    $display("Scenario 1: Sensor is not sending data");
    #(PULSE_WIDTH * 50);

    // Сценарий 2: Датчик отправляет данные сразу после их появления
    $display("Scenario 2: Sensor sends data immediately");
    data_from_sensor = 8'hc3;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 20);
    valid_from_sensor = 0; // Данные отправлены
    #(PULSE_WIDTH * 50);

    // Сценарий 3: Датчик хочет отправить данные, но модуль не готов
    $display("Scenario 3: Sensor waits for readiness");
    data_from_sensor = 8'hb3;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 10);
    valid_from_sensor = 0; // Модуль не готов принять новые данные
    #(PULSE_WIDTH * 30);
    valid_from_sensor = 1; // Попытка отправить данные снова
    #(PULSE_WIDTH * 20);

    // Завершение симуляции
    #(PULSE_WIDTH * 50);
    $finish;
  end

  // Мониторинг сигналов
  initial begin
    $monitor($time, 
             " valid_from_sensor=%b, ready_to_sensor=%b, data_from_sensor=%h, tx_sig=%b", 
             valid_from_sensor, ready_to_sensor, data_from_sensor, tx_sig);
  end

endmodule
