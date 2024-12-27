`include "if/uart_if.sv"
module uart_tx
  #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE  = 115200,
    CLK_FREQ   = 100_000_000,

    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH), //Количество бит, необходимое для адресации всех бит данных (= 3)
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE, // Количество тактовых импульсов для одной длительности бита
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH), // Количество бит для хранения PULSE_WIDTH
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2) //Половина длительности одного бита (для точной синхронизации)
   (
    output logic tx_sig, // Сигнал передачи, формируемый передатчиком
    input logic clk,
    input logic rstn,
    input logic [DATA_WIDTH-1:0] data_from_sensor, 
    input logic valid_from_sensor, // Сигнал наличия валидных данных у кроссбара
    output logic ready_to_sensor // Флаг для кроссбара, о готовности UART принимать данные
   );

   typedef enum logic [1:0] {STT_DATA,
                             STT_STOP,
                             STT_WAIT,
                             STT_DELAY} statetype;

   statetype state;
   logic [DATA_WIDTH-1:0] data_r;
   logic sig_r;
   logic [LB_DATA_WIDTH-1:0] data_cnt;
   logic [LB_PULSE_WIDTH:0] clk_cnt;

   logic sensor_data_pending; //если флаг sensor_data_pending установлен, данные от датчика отправляются на ПК

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         state              <= STT_WAIT;
         sig_r              <= 1;
         data_r             <= 0;
         ready_to_sensor    <= 1;
         sensor_data_pending <= 0;
         data_cnt           <= 0;
         clk_cnt            <= 0;
      end else begin
         case (state)
           STT_DATA: begin
              if (0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end else begin
                 sig_r   <= data_r[data_cnt]; //На выходной сигнал sig_r передаётся значение текущего бита из регистра data_r, индексируемого счётчиком data_cnt
                 clk_cnt <= PULSE_WIDTH; // Это устанавливает длительность для следующего бита
                 if (data_cnt == DATA_WIDTH - 1) begin // Проверяется, был ли передан последний бит данных (старший бит)
                    state <= STT_STOP;
                 end else begin
                    data_cnt <= data_cnt + 1; // следующий бит данных, который будет передан в следующем цикле
                 end
              end
           end

           STT_STOP: begin
              if (0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end else begin
                 state   <= STT_DELAY; // Переход в состояние задержки после стопового бита
                 sig_r   <= 1; // линия передачи (TX) должна находиться в состоянии покоя (1) после завершения передачи стопового бита
                 clk_cnt <= PULSE_WIDTH + HALF_PULSE_WIDTH; // Задержка перед приёмом новых данных
                 data_r <= 0; // Новая добавка
              end
           end

           STT_DELAY: begin
              if (0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end else begin
                 state <= STT_WAIT; // После задержки переходим в ожидание новых данных
                 ready_to_sensor <= 1; // Устанавливаем флаг готовности после задержки
                 sensor_data_pending <= 0;
              end
           end

           STT_WAIT: begin
              if (ready_to_sensor && valid_from_sensor) begin
                 state   <= STT_DATA;
                 sig_r   <= 0;
                 data_r  <= data_from_sensor;
                 ready_to_sensor <= 0; // Опускаем флаг готовности сразу после приёма данных
                 sensor_data_pending <= 1; // внутренний флаг, который указывает, что данные от датчика получены и ожидают отправки
                 data_cnt <= 0;
                 clk_cnt  <= PULSE_WIDTH;
              end
           end

           default: state <= STT_WAIT;
         endcase
      end
   end

   assign tx_sig = sig_r;

endmodule
