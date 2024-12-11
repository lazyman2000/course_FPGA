`include "if/uart_if.sv"

module uart_tx
  #(parameter
    DATA_WIDTH = 8, // Размер данных для передачи
    BAUD_RATE  = 115200, // Скорость передачи данных в битах в секунду
    CLK_FREQ   = 100_000_000,

    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH), // Количество бит, необходимое для адресации всех бит данных (=3 при DATA_WIDTH = 8)
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE, // Количество тактовых импульсов для одной длительности бита
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH), // Количество бит для хранения PULSE_WIDTH
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2) // Половина длительности одного бита (для точной синхронизации).
   (uart_if.tx   txif,
    input logic  clk,
    input logic  rstn);
    // Подключается к интерфейсу txif, принимая данные для передачи от внешнего модуля
   typedef enum logic [1:0] {STT_DATA,
                             STT_STOP,
                             STT_WAIT
                             } statetype;

   statetype                 state; // Текущие состояние FSM

   logic [DATA_WIDTH-1:0]     data_r; // Регистр хранения данных для передачи (8 бит)
   logic                      sig_r; // Сигнал передачи, формируемый передатчиком (выходной сигнал txif.sig)
   logic                      ready_r; // Флаг готовности передатчика к приему новых данных (связан с txif.ready)
   logic [LB_DATA_WIDTH-1:0]  data_cnt; // Счетчик для отслеживания текущего бита данных, передаваемого в STT_DATA
   logic [LB_PULSE_WIDTH:0]   clk_cnt; // Счетчик тактов, отслеживающий длительность текущего бита.

   always_ff @(posedge clk) begin
      if(!rstn) begin
         state    <= STT_WAIT; // по умолчанию
         sig_r    <= 1; // при = 0 - это состояние покоя UART 
         data_r   <= 0;
         ready_r  <= 1; // готов к приему данных
         data_cnt <= 0;
         clk_cnt  <= 0;
         // обнуление счетчиков
      end
      else begin

         //-----------------------------------------------------------------------------
         // 3-state FSM (конечный автомат)
         case(state)

           //-----------------------------------------------------------------------------
           // state      : STT_DATA
           // Сериализует и передает данные. Последовательно обрабатывает каждый бит данных.
           // Следующие состояние : когда все данные переданы -> STT_STOP
           STT_DATA: begin
           // Счетчик clk_cnt отсчитывает длительность одного бита
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else begin // если clk_cnt = 0
                 sig_r   <= data_r[data_cnt]; // Устанавливается в значение текущего бита data_r[data_cnt]
                 clk_cnt <= PULSE_WIDTH;

                 if(data_cnt == DATA_WIDTH - 1) begin
                 // Если все биты данных переданы
                    state <= STT_STOP;
                 end
                 else begin
                    data_cnt <= data_cnt + 1;
                 end
              end
           end

           //-----------------------------------------------------------------------------
           // state      : STT_STOP
           // Перердает стоповый бит
           // следующее состояние : STT_WAIT
           STT_STOP: begin
           // Счетчик clk_cnt снова отсчитывает длительность одного бита.
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else begin
                 state   <= STT_WAIT;
                 sig_r   <= 1; // стоповый бит
                 clk_cnt <= PULSE_WIDTH + HALF_PULSE_WIDTH;
              end
           end

           //-----------------------------------------------------------------------------
           // state      : STT_WAIT
           // Ждет сигнал valid, и передает стартовый бит когда valid signal получен
           // Следующее сост : когда valid signal получен -> STT_STAT
           STT_WAIT: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else if(!ready_r) begin
                 ready_r <= 1;
              end
              else if(txif.valid) begin
        // Проверяется, активен ли флаг txif.valid (новые данные готовы к передаче).
                // Если valid = 1:
                 state    <= STT_DATA;
                 sig_r    <= 0; // стартовый бит UART
                 data_r   <= txif.data; // принимает значение входных данных
                 ready_r  <= 0; // занято, данные обрабатываются
                 data_cnt <= 0;
                 clk_cnt  <= PULSE_WIDTH; // установка счетчика в значение Количества тактовых импульсов для одной длительности бита
              end
           end

           default: begin
              state <= STT_WAIT;
           end
         endcase
      end
   end

   assign txif.sig   = sig_r;
   assign txif.ready = ready_r;

endmodule
