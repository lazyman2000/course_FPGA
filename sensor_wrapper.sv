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

sensor_top i_sensor_top (
    .clk             (clk        ),
    .rst_n           (rst_n          ),
    .uart_rx_i       (FTDI_TXD       ),
    .uart_tx_o       (FTDI_RXD       ),
    .dht11_data_i    (dht11_data_i   ),
    .dht11_data_o    (dht11_data_o   ),
    .dht11_data_o_en (dht11_data_o_en),
    .echo            (echo),
    .trig            (trig)
);

clock_50 i_clock (
    .clk_in          (clk_100),
    .clk_out         (clk)
);

assign echo = JB[0];
assign JB[2] = trig;
assign JC[3] = dht11_data_o_en ? dht11_data_o : 'bz;
assign dht11_data_i = JC[3];



endmodule: sensor_wrapper