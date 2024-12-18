`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Starodubov Roman Alexandrovich
// 
// Create Date: 07.12.2024 20:38:45
// Module Name: Crossbar_pipeline
// Project Name: -
// Target Devices: Arty A7-35
//
// Additional Comments: Version 5
// 
//////////////////////////////////////////////////////////////////////////////////


module Crossbar_pipeline(
    input logic clk, //clock signal
    input logic rst, //reset signal (should be renamed?)
    input logic [7:0] uart_rx, //received data from UART (should be renamed)
    output logic [7:0] uart_tx, //transmitted data to UART (should be renamed)
    input logic uart_ready, //is UART ready to read? (should be renamed)
    output logic dht11_start, //signal for initializing DHT11 measurements (should be renamed)
    input logic [15:0] dht11_data, //received data from DHT11 (should be renamed)
    input logic dht11_data_available, //is data from DHT11 available? (should be renamed)
    output logic hc_sr04_start, //signal for initializing HCSR04 measurements (should be renamed)
    input logic [15:0] hc_sr04_data, //received data from HCSR04 (should be renamed)
    input logic hc_sr04_data_available, //is data from DHT11 available? (should be renamed)
    input logic valid_command, //signal from UART, if command is valid
    output logic ready_to_act, //1 by default. 0 when recieved valid command and until data from sensors sent to UART
    output logic data_transaction_ready //pulse that shows data is ready to be sent
    );
    
    //numerable variable for device state
    typedef enum logic [3:0] {
        IDLE = 4'b000, //wait for command
        START_TEMP_N_MOIST = 4'b001, //type 8'h54 ("T") for temperature and moisture measurement
        START_DIST = 4'b010, //type 8'h44 ("D") for distance measurement
        READ_TEMP_N_MOIST = 4'b011, 
        READ_DIST = 4'b100, 
        ASCII_TEMP_N_MOIST = 4'b101,
        ASCII_DIST = 4'b110,
        SEND_TEMP_N_MOIST = 4'b111,
        SEND_DIST = 4'b1000
    } device_state;
    
    device_state command_decode;
    
    //buffers for pipeline
    logic [7:0] uart_command_fetch; //register for received UART command (ASCII symbol)        
    logic [15:0] execute_data; //buffer for receieved data from sensors 
    logic [31:0] ascii_data_dist; //buffer for DHT11 data in ASCII symbols
    logic [31:0] ascii_data_temp; //buffer for HCSR4 temperature data in ASCII symbols   
    logic [31:0] ascii_data_moist; //buffer for HCSR4 moisture data in ASCII symbols    
    logic ready_to_act_set;

    logic ready_temp, ready_moist, ready_dist;
    logic bcd_temp, bcd_moist, bcd_dist;  
    
    logic [3:0] counter; //counter for transmitting data by bytes
    logic sending; //flag if the data is sending

    //Fetch
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            uart_command_fetch <= 8'b0;
            ready_to_act <= 1'b1;
        end else if (ready_to_act && valid_command) begin
            uart_command_fetch <= uart_rx; //write the data from UART
            ready_to_act <= 1'b0; //when the valid_command is up module doesn't read any commands until the cycle is done
        end
            else if (!ready_to_act && ready_to_act_set)
                ready_to_act <= 1'b1;
    end
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            command_decode <= IDLE; //the idle state
            dht11_start <= 1'b0;
            hc_sr04_start <= 1'b0;
            execute_data <= 16'b0;
            uart_tx <= 8'b0;
            counter <= 4'b0;
            sending <= 1'b0;
            bcd_temp <= 1'b0;
            bcd_moist <= 1'b0;
            bcd_dist <= 1'b0;
            data_transaction_ready <= 1'b0;
            ready_to_act_set <= 1'b0;
        end else begin
           case (command_decode)
                IDLE: begin //default state, waiting for the command
                    dht11_start <= 1'b0;
                    hc_sr04_start <= 1'b0;
                    execute_data <= 16'b0;
                    bcd_temp <= 1'b0;
                    bcd_moist <= 1'b0;
                    bcd_dist <= 1'b0;
                    data_transaction_ready <= 1'b0;
                    ready_to_act_set <= 1'b0;
                    if (!ready_to_act && uart_command_fetch == 8'h54) begin
                        command_decode <= START_TEMP_N_MOIST;
                    end else if (!ready_to_act && uart_command_fetch == 8'h44) begin
                        command_decode <= START_DIST;
                    end else begin
                        command_decode <= IDLE;
                    end
                end
                START_TEMP_N_MOIST: begin
                    dht11_start <= 1'b1; //send the measurement initializing bit for DHT11
                    command_decode <= READ_TEMP_N_MOIST;
                end
                START_DIST: begin
                    hc_sr04_start <= 1'b1; //send the measurement initializing bit for HCSR4
                    command_decode <= READ_DIST;
                end
                READ_TEMP_N_MOIST: begin
                    dht11_start <= 1'b0; //the initializing bit should be set only for 1 clk period
                    
                    if (dht11_data_available) begin //if there is any data in sensor buffer, read it
                        execute_data <= dht11_data; //place recieved data from DHT11 into buffer
                        bcd_temp <= 1'b1; //flag to start BCD-ASCII transformation of the temperature data
                        bcd_moist <= 1'b1; //flag to start BCD-ASCII transformation of the moisture data
                        command_decode <= ASCII_TEMP_N_MOIST;
                    end
                end
                ASCII_TEMP_N_MOIST: begin
                    if (ready_temp && ready_moist) begin //if the BCD-ASCII done it's job
                        data_transaction_ready <= 1'b1;
                        bcd_temp <= 1'b0; //flag to stop BCD-ASCII for temperature
                        bcd_moist <= 1'b0; //flag to stop BCD-ASCII for moisture
                        command_decode <= SEND_TEMP_N_MOIST;
                    end
                end
                SEND_TEMP_N_MOIST: begin
                    if (!sending && uart_ready) begin //if UART is ready to read and not sending
                            sending <= 1'b1; //start sending
                            counter <= 4'b0; //set counter constant to zero
                    end else if (execute_data != 16'b0 && uart_ready) begin //if there non-zero data in buffer and UART is ready to read
                        case (counter) //send bytes
                            4'd0: uart_tx <= ascii_data_temp[23:16]; 
                            4'd1: uart_tx <= ascii_data_temp[15:8];
                            4'd2: uart_tx <= ascii_data_temp[7:0];
                            4'd3: uart_tx <= 8'h0D;
                            4'd4: uart_tx <= ascii_data_moist[23:16];
                            4'd5: uart_tx <= ascii_data_moist[15:8];
                            4'd6: uart_tx <= ascii_data_moist[7:0];
                            4'd7: uart_tx <= 8'h0D;
                            default: sending <= 1'b0;
                        endcase
                        //$display("ascii_data_temp1: %b",ascii_data_temp[23:16]);
                        //$display("ascii_data_temp2: %b",ascii_data_temp[15:8]);
                        //$display("ascii_data_temp3: %b",ascii_data_temp[7:0]);
                        //$display("ascii_data_moist1: %b",ascii_data_moist[23:16]);
                        //$display("ascii_data_moist2: %b",ascii_data_moist[15:8]);
                        //$display("ascii_data_moist3: %b",ascii_data_moist[7:0]);
                        if (counter < 4'd7) begin
                            counter <= counter + 1;
                        end else begin
                            sending <= 1'b0;
                            ready_to_act_set <= 1'b1;
                            data_transaction_ready <= 1'b0;
                            command_decode <= IDLE;
                        end
                    end
                end
                    
                READ_DIST: begin
                    hc_sr04_start <= 1'b0;
                    if (hc_sr04_data_available) begin
                        execute_data <= hc_sr04_data; //place recieved data from DHT11 into buffer
                        bcd_dist <= 1'b1;
                        command_decode <= ASCII_DIST;
                    end
                end
                ASCII_DIST: begin
                    if (ready_dist) begin
                        data_transaction_ready <= 1'b1;
                        bcd_dist <= 1'b0;
                        command_decode <= SEND_DIST;
                    end
                end
                SEND_DIST: begin
                    if (!sending && uart_ready) begin
                        sending <= 1'b1;
                        counter <= 4'b0;
                    end else if (execute_data != 16'b0 && uart_ready) begin      
                        case (counter)
                            4'd0: uart_tx <= ascii_data_dist[31:24];  
                            4'd1: uart_tx <= ascii_data_dist[23:16];
                            4'd2: uart_tx <= ascii_data_dist[15:8];
                            4'd3: uart_tx <= ascii_data_dist[7:0];
                            4'd4: uart_tx <= 8'h0D;
                            default: sending <= 1'b0;
                        endcase
                        //$display("ascii_data_dist1: %b",ascii_data_moist[23:16]);
                        //$display("ascii_data_dist2: %b",ascii_data_moist[15:8]);
                        //$display("ascii_data_dist3: %b",ascii_data_moist[7:0]);
                        if (counter < 4'd4) begin
                            counter <= counter + 1;
                        end else begin
                            sending <= 1'b0;
                            ready_to_act_set <= 1'b1;
                            data_transaction_ready <= 1'b0;
                            command_decode <= IDLE;
                        end
                    end
                end
                default: begin
                    command_decode <= IDLE;
                    execute_data <= 16'b0;
                end
           endcase
        end
    end
    
    //BCD-ASCII instances
    BCD_SV_ff DHT11_TEMP(.bin_in({6'b0, execute_data[15:8]}), .clk(clk), .rst(rst), .ascii_out(ascii_data_temp), .cross_ready(bcd_temp), .bcd_ready(ready_temp));
    BCD_SV_ff DHT11_MOIST(.bin_in({6'b0, execute_data[7:0]}), .clk(clk), .rst(rst), .ascii_out(ascii_data_moist), .cross_ready(bcd_moist), .bcd_ready(ready_moist));
    BCD_SV_ff HCSR4(.bin_in(execute_data[13:0]), .clk(clk), .rst(rst), .ascii_out(ascii_data_dist), .cross_ready(bcd_dist), .bcd_ready(ready_dist));
endmodule
