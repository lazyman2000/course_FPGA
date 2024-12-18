//`define SIMULATION
module sensor_top (
                    input  logic       clk,
                    input  logic       rst_n,
                    // UART
                    input  logic       uart_rx_i,
                    output logic       uart_tx_o,
                    // DHT11
`ifdef SIMULATION
                    inout  logic       dht11_data,
`else // ~SIMULATION
                    input  logic       dht11_data_i,
                    output logic       dht11_data_o,
                    output logic       dht11_data_o_en,
`endif // SIMULATION
                    // HC-SR04
                    input  logic       echo,
                    output logic       trig

);

//-------------------------------------------------------------
// LOCAL SIGNALS DECLARATION
//-------------------------------------------------------------

// CROSSBAR <-> UART
logic [7:0] uart_rx;                //received data from UART
logic [7:0] uart_tx;                //transmitted data to UART
logic       uart_ready;             //is UART ready to read?
logic       valid_command;          //signal from UART, if command is valid
logic       ready_to_act;           //1 by default. 0 when recieved valid command and until data from sensors sent to UART
logic       data_transaction_ready; //pulse that shows data is ready to be sent

// CROSSBAR <-> DHT11
logic        dht11_start;           //signal for initializing DHT11 measurements
logic [15:0] dht11_data_rec;            //received data from DHT11
logic        dht11_data_available;  //is data from DHT11 available?

// CROSSBAR <-> HC-SR04
logic        hc_sr04_start;         //signal for initializing HCSR04 measurements
logic [15:0] hc_sr04_data;          //received data from HCSR04
logic        hc_sr04_data_available;//is data from DHT11 available?

// // UART external interface
// logic        rx_sig;
// logic        tx_sig;

// // HC-SR04 external interface
// logic        echo;
// logic        trig;
`ifdef SIMULATION
// DHT11 extrenal interface
logic        dht11_data_i;
logic        dht11_data_o;
logic        dht11_data_o_en;

assign dht11_data_i = dht11_data;
assign dht11_data   = dht11_data_o_en ? dht11_data_o : 'bz;
`endif // SIMULATION


//-------------------------------------------------------------
// Crossbar instance
//-------------------------------------------------------------

Crossbar_pipeline i_crossbar (
    // Common signals
    .clk                    (clk                   ),
    .rst                    (rst_n                 ),
    // CROSSBAR <-> UART
    .uart_rx                (uart_rx               ),
    .uart_tx                (uart_tx               ),
    .uart_ready             (uart_ready            ),
    .valid_command          (valid_command         ),
    .ready_to_act           (ready_to_act          ),
    .data_transaction_ready (data_transaction_ready),
    // CROSSBAR <-> DHT11
    .dht11_start            (dht11_start           ),
    .dht11_data             (dht11_data_rec        ),
    .dht11_data_available   (dht11_data_available  ),
    // CROSSBAR <-> HC-SR04
    .hc_sr04_start          (hc_sr04_start         ),
    .hc_sr04_data           (hc_sr04_data          ),
    .hc_sr04_data_available (hc_sr04_data_available)
);

//-------------------------------------------------------------
// UART instance
//-------------------------------------------------------------

uart i_uart (
    // Common
    .clk               (clk),
    .rstn              (rst_n),
    // External interface
    .rx_sig            (uart_rx_i),
    .tx_sig            (uart_tx_o),
    // UART <-> CROSSBAR
    .sensor_ready      (ready_to_act),
    .sensor_data       (uart_rx),
    .sensor_valid      (valid_command),
    .data_from_sensor  (uart_tx),
    .valid_from_sensor (data_transaction_ready),
    .ready_to_sensor   (uart_ready)
);

//-------------------------------------------------------------
// DHT11 instance
//-------------------------------------------------------------

DHT11 i_dht11 (
    // Common
    .clk             (clk                 ),
    .rst_n           (rst_n               ),
    // DHT11 <-> CROSSBAR
    .uart_rx         (dht11_start         ),
    .uart_tx         (dht11_data_rec      ),
    .ready           (dht11_data_available),
    // External interface
    .dht11_data_i    (dht11_data_i        ),
    .dht11_data_o    (dht11_data_o        ),
    .dht11_data_o_en (dht11_data_o_en     )
);

//-------------------------------------------------------------
// HC-SR04 instance
//-------------------------------------------------------------
HCSR04 i_hcsr04 (
    // Common
    .clk      (clk                        ),
    .rst      (rst_n                        ),
    // HC-SCR04 <-> CROSSBAR
    .start    (hc_sr04_start                ),
    .val      (hc_sr04_data_available       ),
    .distance (hc_sr04_data               ),
    // External interface
    .echo     (echo                       ),
    .trig     (trig                       )
);



endmodule: sensor_top