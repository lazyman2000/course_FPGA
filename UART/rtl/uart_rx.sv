`include "if/uart_if.sv"

module uart_rx
  #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE  = 115200,
    CLK_FREQ   = 100_000_000,

    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH), // Количество бит, необходимое для адресации всех бит данных
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE, // Количество тактовых импульсов для одной длительности бита
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH),
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2)
   (uart_if.rx  rxif,
    input logic clk,
    input logic rstn,
    input logic sensor_ready,         // Сигнал готовности датчика
    output logic [DATA_WIDTH-1:0] sensor_data, // Данные, отправляемые в датчик
    output logic sensor_valid         // Сигнал валидации данных для датчика
   );

   //----------------------------------------------------------------
   // description about receive UART signal
   typedef enum logic [1:0] {STT_DATA,
                             STT_STOP,
                             STT_WAIT} statetype;

   statetype                 state;

   logic [DATA_WIDTH-1:0]    data_tmp_r; // Регистр для временного хранения принимаемых данных
   logic [LB_DATA_WIDTH:0]   data_cnt;   // Счетчик битов данных
   logic [LB_PULSE_WIDTH:0]  clk_cnt;    // Счетчик тактов для синхронизации с длительностью бита
   logic                     rx_done;   // Флаг, указывающий, что все данные успешно приняты

   // Регистр для хранения данных перед отправкой в датчик
   logic [DATA_WIDTH-1:0]    buffer_r;
   logic                     buffer_valid;

   always_ff @(posedge clk) begin
      if(!rstn) begin
         state        <= STT_WAIT;
         data_tmp_r   <= 0;
         data_cnt     <= 0;
         clk_cnt      <= 0;
         buffer_r     <= 0;
         buffer_valid <= 0;
         sensor_valid <= 0;
         sensor_data  <= 0;
      end
      else begin

         //---------------------------------------------------------------------- 
         // FSM for UART reception
         case(state)

           STT_DATA: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else begin
                 data_tmp_r <= {rxif.sig, data_tmp_r[DATA_WIDTH-1:1]}; // Сдвиговый регистр
                 clk_cnt    <= PULSE_WIDTH;

                 if(data_cnt == DATA_WIDTH - 1) begin // Если все биты данных приняты
                    state <= STT_STOP;
                 end
                 else begin
                    data_cnt <= data_cnt + 1;
                 end
              end
           end

           STT_STOP: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else if(rxif.sig) begin // Проверяется стоповый бит
                 state <= STT_WAIT;
                 buffer_r     <= data_tmp_r; // Сохранение данных в буфер
                 buffer_valid <= 1;          // Установка флага наличия данных
              end
           end

           STT_WAIT: begin
              if(rxif.sig == 0) begin // Ожидание стартового бита
                 clk_cnt  <= PULSE_WIDTH + HALF_PULSE_WIDTH;
                 data_cnt <= 0;
                 state    <= STT_DATA;
              end
           end

           default: state <= STT_WAIT;
         endcase

         // Проверка готовности датчика и отправка данных
         if(buffer_valid && sensor_ready) begin
            sensor_data  <= buffer_r; // Передача данных в датчик
            sensor_valid <= 1;       // Уведомление о готовности данных
            buffer_valid <= 0;       // Очищение буфера
         end
         else begin
            sensor_valid <= 0; // Отключение валидации, если датчик не готов
         end
      end
   end

   assign rx_done = (state == STT_STOP) && (clk_cnt == 0);

endmodule
