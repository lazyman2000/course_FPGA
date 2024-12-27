module uart_rx
  #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE  = 115200,
    CLK_FREQ   = 100_000_000,

    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH),
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE,
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH),
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2)
   (
    input logic rx_sig,
    input logic clk,
    input logic rstn,
    input logic sensor_ready, // Входной сигнал, указывающий на готовность кроссбара принять данные.
    output logic [DATA_WIDTH-1:0] sensor_data, // Выходной сигнал, через который данные передаются на кроссбар 
    output logic sensor_valid // Выходной сигнал, указывающий, что данные на sensor_data действительны.
   );

   typedef enum logic [1:0] {STT_DATA,
                             STT_STOP,
                             STT_WAIT} statetype;

   statetype state;

   logic [DATA_WIDTH-1:0] data_tmp_r;
   logic [LB_DATA_WIDTH:0] data_cnt;
   logic [LB_PULSE_WIDTH:0] clk_cnt;
   logic rx_done;

   logic [DATA_WIDTH-1:0] buffer_r; // используется для хранения данных, принятых от ПК, до тех пор, пока кроссбар не станет готов их принять
   logic buffer_valid; // сигнализирует о наличии данных в буфере.

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         state        <= STT_WAIT;
         data_tmp_r   <= 0;
         data_cnt     <= 0;
         clk_cnt      <= 0;
         buffer_r     <= 0;
         buffer_valid <= 0;
         sensor_valid <= 0;
         sensor_data  <= 0;
      end else begin
         case (state)
           STT_DATA: begin
              if (0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end else begin
                 data_tmp_r <= {rx_sig, data_tmp_r[DATA_WIDTH-1:1]};
                 clk_cnt    <= PULSE_WIDTH;
                 if (data_cnt == DATA_WIDTH - 1) begin
                    state <= STT_STOP;
                 end else begin
                    data_cnt <= data_cnt + 1;
                 end
              end
           end

           STT_STOP: begin
              if (0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end else if (rx_sig) begin
                 state        <= STT_WAIT;
                 buffer_r     <= data_tmp_r;
                 buffer_valid <= 1;
              end
           end

           STT_WAIT: begin
              if (rx_sig == 0) begin
                 clk_cnt  <= PULSE_WIDTH + HALF_PULSE_WIDTH;
                 data_cnt <= 0;
                 state    <= STT_DATA;
              end
           end

           default: state <= STT_WAIT;
         endcase

         if (buffer_valid && sensor_ready) begin
            sensor_data  <= buffer_r;
            sensor_valid <= 1;
            buffer_valid <= 0;
         end else begin
            sensor_valid <= 0;
         end
      end
   end

   assign rx_done = (state == STT_STOP) && (clk_cnt == 0);

endmodule
