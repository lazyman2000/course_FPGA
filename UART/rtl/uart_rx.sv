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
    input logic rstn);

   
   //----------------------------------------------------------------
   // description about receive UART signal
   typedef enum logic [1:0] {STT_DATA,
                             STT_STOP,
                             STT_WAIT
                             } statetype;

   statetype                 state;

   logic [DATA_WIDTH-1:0]   data_tmp_r; // Регистр для временного хранения принимаемых данных
   logic [LB_DATA_WIDTH:0]  data_cnt; // Счетчик битов данных
   logic [LB_PULSE_WIDTH:0] clk_cnt; // Счетчик тактов для синхронизации с длительностью бита
   logic                    rx_done; // Флаг, указывающий, что все данные успешно приняты

   always_ff @(posedge clk) begin
      if(!rstn) begin
         state      <= STT_WAIT;
         data_tmp_r <= 0;
         data_cnt   <= 0;
         clk_cnt    <= 0;
      end
      else begin

         //-----------------------------------------------------------------------------
         // 3-state FSM
         case(state)

           //-----------------------------------------------------------------------------
           // state      : STT_DATA
           // Следующее состояние : когда все данные получены -> STT_STOP
           STT_DATA: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else begin
              // rxif.sig - Текущий бит входного сигнала UART
                 data_tmp_r <= {rxif.sig, data_tmp_r[DATA_WIDTH-1:1]}; //сдвиговый регистр
                 clk_cnt    <= PULSE_WIDTH;

                 if(data_cnt == DATA_WIDTH - 1) begin // Если все биты данных приняты
                    state <= STT_STOP;
                 end
                 else begin
                    data_cnt <= data_cnt + 1;
                 end
              end
           end

           //-----------------------------------------------------------------------------
           // state      : STT_STOP
           //ПРоверка  stop bit
           // Следующее состояние : STT_WAIT
           STT_STOP: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else if(rxif.sig) begin // Проверяется, соответствует ли rxif.sig = 1
                 state <= STT_WAIT;
              end
           end

           //-----------------------------------------------------------------------------
           // state      : STT_WAIT
           // Ожидание стартового бита
           // Следующее состояние: когда start bit получен -> STT_DATA
           STT_WAIT: begin
           // Постоянно отслеживается входной сигнал
              if(rxif.sig == 0) begin //Если обнаружен стартовый бит
                 clk_cnt  <= PULSE_WIDTH + HALF_PULSE_WIDTH; // для синхронизации с серединой стартового бита
                 data_cnt <= 0;
                 state    <= STT_DATA;
              end
           end

           default: begin
              state <= STT_WAIT;
           end
         endcase
      end
   end

   assign rx_done = (state == STT_STOP) && (clk_cnt == 0);

   //-----------------------------------------------------------------------------
   // description about output signal
   logic [DATA_WIDTH-1:0] data_r;
   logic                  valid_r; // Флаг, указывающий, что данные готовы для передачи через интерфейс

   always_ff @(posedge clk) begin
      if(!rstn) begin
         data_r  <= 0;
         valid_r <= 0;
      end
      else if(rx_done && !valid_r) begin
         valid_r <= 1;
         data_r  <= data_tmp_r;
      end
      else if(valid_r && rxif.ready) begin
         valid_r <= 0;
      end
   end

   assign rxif.data  = data_r;
   assign rxif.valid = valid_r;

endmodule