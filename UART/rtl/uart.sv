`include "if/uart_if.sv"

module uart
  #(parameter
    DATA_WIDTH = 8, // Размер данных передаваемых модулем
    BAUD_RATE  = 115200, // Baud rate UART
    CLK_FREQ   = 100_000_000) // Частота тактового сигнала
   (uart_if.rx   rxif,
    uart_if.tx   txif,
    input logic  clk,
    input logic  rstn,
    input logic  sensor_ready,
    output logic [DATA_WIDTH-1:0] sensor_data,
    output logic sensor_valid,
    input logic [DATA_WIDTH-1:0] data_from_sensor,
    input logic valid_from_sensor,
    output logic ready_to_sensor);

   // Приемник данных с ПК
   uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uart_rx_inst(
      .rxif(rxif),
      .clk(clk),
      .rstn(rstn),
      .sensor_ready(sensor_ready),
      .sensor_data(sensor_data),
      .sensor_valid(sensor_valid)
   );

   // Передатчик данных на ПК
   uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uart_tx_inst(
      .txif(txif),
      .clk(clk),
      .rstn(rstn),
      .data_from_sensor(data_from_sensor),
      .valid_from_sensor(valid_from_sensor),
      .ready_to_sensor(ready_to_sensor)
   );

endmodule
