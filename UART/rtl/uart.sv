
module uart
  #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE  = 115200,
    CLK_FREQ   = 50_000_000)
   (
    input logic rx_sig,
    output logic tx_sig,
    input logic clk,
    input logic rstn,
    input logic sensor_ready,
    output logic [DATA_WIDTH-1:0] sensor_data,
    output logic sensor_valid,
    input logic [DATA_WIDTH-1:0] data_from_sensor,
    input logic valid_from_sensor,
    output logic ready_to_sensor
   );

   uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uart_rx_inst (
      .rx_sig(rx_sig),
      .clk(clk),
      .rstn(rstn),
      .sensor_ready(sensor_ready),
      .sensor_data(sensor_data),
      .sensor_valid(sensor_valid)
   );

   uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uart_tx_inst (
      .tx_sig(tx_sig),
      .clk(clk),
      .rstn(rstn),
      .data_from_sensor(data_from_sensor),
      .valid_from_sensor(valid_from_sensor),
      .ready_to_sensor(ready_to_sensor)
   );

endmodule
