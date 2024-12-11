`include "if/uart_if.sv"

module uart_tx
  #(parameter
    DATA_WIDTH = 8,
    BAUD_RATE  = 115200,
    CLK_FREQ   = 100_000_000,

    localparam
    LB_DATA_WIDTH    = $clog2(DATA_WIDTH),
    PULSE_WIDTH      = CLK_FREQ / BAUD_RATE,
    LB_PULSE_WIDTH   = $clog2(PULSE_WIDTH),
    HALF_PULSE_WIDTH = PULSE_WIDTH / 2)
   (uart_if.tx   txif,
    input logic  clk,
    input logic  rstn,
    input logic [DATA_WIDTH-1:0] data_from_sensor,
    input logic valid_from_sensor,
    output logic ready_to_sensor);

   typedef enum logic [1:0] {STT_DATA,
                             STT_STOP,
                             STT_WAIT} statetype;

   statetype state;
   logic [DATA_WIDTH-1:0] data_r;
   logic sig_r;
   logic ready_r;
   logic [LB_DATA_WIDTH-1:0] data_cnt;
   logic [LB_PULSE_WIDTH:0] clk_cnt;

   always_ff @(posedge clk) begin
      if(!rstn) begin
         state          <= STT_WAIT;
         sig_r          <= 1;
         data_r         <= 0;
         ready_r        <= 1;
         ready_to_sensor <= 1;
         data_cnt       <= 0;
         clk_cnt        <= 0;
      end
      else begin
         case(state)
           STT_DATA: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else begin
                 sig_r   <= data_r[data_cnt];
                 clk_cnt <= PULSE_WIDTH;

                 if(data_cnt == DATA_WIDTH - 1) begin
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
              else begin
                 state   <= STT_WAIT;
                 sig_r   <= 1;
                 clk_cnt <= PULSE_WIDTH + HALF_PULSE_WIDTH;
              end
           end

           STT_WAIT: begin
              if(0 < clk_cnt) begin
                 clk_cnt <= clk_cnt - 1;
              end
              else if(!ready_r) begin
                 ready_r <= 1;
              end
              else if(valid_from_sensor) begin
                 state          <= STT_DATA;
                 sig_r          <= 0;
                 data_r         <= data_from_sensor;
                 ready_r        <= 0;
                 ready_to_sensor <= 0; // Занято
                 data_cnt       <= 0;
                 clk_cnt        <= PULSE_WIDTH;
              end
              else if(txif.valid) begin
                 state    <= STT_DATA;
                 sig_r    <= 0;
                 data_r   <= txif.data;
                 ready_r  <= 0;
                 ready_to_sensor <= 1; // Готов к приему от датчика
                 data_cnt <= 0;
                 clk_cnt  <= PULSE_WIDTH;
              end
           end

           default: state <= STT_WAIT;
         endcase
      end
   end

   assign txif.sig   = sig_r;
   assign txif.ready = ready_r;

endmodule
