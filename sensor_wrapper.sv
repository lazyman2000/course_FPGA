module sensor_wrapper (
                    input  logic       clk_100,
                    input  logic       rst_n,
                    // UART
                    input  logic       FTDI_TXD,
                    output logic       FTDI_RXD,
                    // DHT11
                    inout  logic [7:0] JB,
                    inout  logic [7:0] JC
);

logic       uart_rx_i;
logic       uart_tx_o;
logic       dht11_data_i;
logic       dht11_data_o;
logic       dht11_data_o_en;
logic       echo;
logic       trig;
logic       clk;

sensor_top i_sensor_top (
    .clk             (clk_100        ),
    .rst_n           (rst_n          ),
    .uart_rx_i       (FTDI_TXD       ),
    .uart_tx_o       (FTDI_RXD       ),
    .dht11_data_i    (dht11_data_i   ),
    .dht11_data_o    (dht11_data_o   ),
    .dht11_data_o_en (dht11_data_o_en),
    .echo            (echo),
    .trig            (trig)
);


assign echo = JB[0];
assign JB[1] = trig;
assign JC[3] = dht11_data_o_en ? dht11_data_o : 'bz;
assign dht11_data_i = JC[3];



endmodule: sensor_wrapper