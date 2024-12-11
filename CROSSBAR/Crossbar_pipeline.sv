`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Starodubov Roman Alexandrovich
// 
// Create Date: 07.12.2024 20:38:45
// Module Name: Crossbar_pipeline
// Project Name: -
// Target Devices: Arty A7-35
//
// Additional Comments: Version 2
// 
//////////////////////////////////////////////////////////////////////////////////


module Crossbar_pipeline(
    input logic clk, //clock signal
    input logic rst, //reset signal (should be renamed?)
    input logic [7:0] uart_rx, //received data from UART (should be renamed as Vova says)
    output logic [7:0] uart_tx, //transmitted data to UART (should be renamed as Vova says)
    output logic dht11_start, //signal for initializing DHT11 measurements (should be renamed as Kristina says)
    input logic [39:0] dht11_data, //received data from DHT11 (should be renamed as Kristina says)
    input logic dht11_data_available, //is data from DHT11 available? (should be renamed as Kristina says)
    output logic hc_sr04_start, //signal for initializing HC-SR04 measurements (should be renamed as Katya says)
    input logic [15:0] hc_sr04_data, //received data from HC-SR04 (should be renamed as Katya says)
    input logic hc_sr04_data_available //is data from DHT11 available? (should be renamed as Kristina says)
    );
    
    //numerable variable for device state
    typedef enum logic [1:0] {
        IDLE = 2'b00, //wait for command
        READ_TEMP_N_MOIST_CONT = 2'b01, //type 8'h54 ("T") for temperature and moisture measurement (command name should be set by Vova)
        READ_DIST_CONT = 2'b10 //type 8'h44 ("D") for distance measurement (command name should be set by Vova)
    } device_state;
    
    device_state command_decode;
    
    //buffers for pipeline
    logic [7:0] uart_command_fetch; //register for received UART command (ASCII symbol) (size should be changed as Vova says)        
    logic [39:0] execute_data; //data from the sensor 40-bit (should be changed, i guess. DHT11 has 16 bit resolution and HC-SR4 has 40 bits package including control sum, idk)      
    
    logic uart_received; //flag if data received from UART 
    
    logic [2:0] TEMP_counter; //counter for transmitting data by bytes
    logic sending; //flag if the data is sending
    logic send_lower_byte; //flag for lower byte for DHT11 data sending

    //stage 1 - Fetch
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            uart_command_fetch <= 8'b0;
            uart_received <= 1'b0;
        end else begin
            uart_command_fetch <= uart_rx; //write the data from UART
			case (uart_command_fetch) //if command is correct set the flag
				8'h54, 8'h44: uart_received <= 1'b1; //set the flag that the data received
				default: uart_received <= 1'b0;
			endcase
        end
    end
    
    //stage 2 - Decode the command from UART
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            command_decode <= IDLE; //the idle state
        end else begin
            if (uart_received) begin //if flag is set than decode the command otherwise stay in IDLE state
                dht11_start <= 1'b0;
                hc_sr04_start <= 1'b0;
                case (uart_command_fetch)
                    8'h54: command_decode <= READ_TEMP_N_MOIST_CONT; //read data from HC-SR4 (ASCII symbol "T")
                    8'h44: command_decode <= READ_DIST_CONT; //read data from DHT11 (ASCII symbol "D")
                    default: command_decode <= IDLE; //default state
                endcase
            end else begin
				command_decode <= IDLE; //default state
			end
        end
    end
    
    //stage 3 - Recieve data from the sensor
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            dht11_start <= 1'b0;
            hc_sr04_start <= 1'b0;
            execute_data <= 40'b0;
        end else begin
            case (command_decode)
                READ_TEMP_N_MOIST_CONT: begin
                    dht11_start <= 1'b1; //send the measurement initializing bit
                    if (dht11_data_available) begin //if there is any data in sensor buffer, read it
                        execute_data <= dht11_data; //place recieved data from DHT11 into buffer
                        $display("Data in buffer (temp): %h", execute_data);
                    end
                end
                READ_DIST_CONT: begin
                    hc_sr04_start <= 1'b1;
                    if (hc_sr04_data_available) begin
                        execute_data <= hc_sr04_data; //place recieved data from DHT11 into buffer
                        $display("Data in buffer (dist): %h", execute_data);
                    end
                end
                default: begin
                    execute_data <= 40'b0;
                    dht11_start <= 1'b0;
                    hc_sr04_start <= 1'b0;
                end
            endcase
        end
    end
    
    //stage 4 - Send data to UART
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            uart_tx <= 8'b0;
            TEMP_counter <= 3'b0;
            sending <= 1'b0;
            send_lower_byte <= 1'b1;
        end else begin
            case (command_decode)
                READ_TEMP_N_MOIST_CONT: begin
                    if (!sending) begin
                        sending <= 1'b1;
                        TEMP_counter <= 3'b0;
                    end else if (execute_data !== 40'b0) begin
                        case (TEMP_counter)
                            3'd0: uart_tx <= execute_data[7:0];  
                            3'd1: uart_tx <= execute_data[15:8];
                            3'd2: uart_tx <= execute_data[23:16];
                            3'd3: uart_tx <= execute_data[31:24];
                            3'd4: uart_tx <= execute_data[39:32]; 
                            default: sending <= 1'b0;
                        endcase
                        
                        if (TEMP_counter < 3'd4) begin
                            TEMP_counter <= TEMP_counter + 1;
                            $display("Counter: %d", TEMP_counter);
                        end else begin
                            sending <= 1'b0;
                        end
                    end
                    //uart_tx <= execute_data[39:0];  //THIS SHOULD BE DONE THE OTHER WAY. 
                end
                READ_DIST_CONT: begin         
                    if (send_lower_byte) begin
                        uart_tx <= execute_data[7:0];  
                        send_lower_byte <= 1'b0;      
                    end else begin
                        uart_tx <= execute_data[15:8]; 
                        send_lower_byte <= 1'b1;      
                    end
                
                    //uart_tx <= execute_data[39:0];  //THIS SHOULD BE DONE THE OTHER WAY. 
                end
                default: begin
                    uart_tx <= 8'b0;
                    sending <= 1'b0;
                    TEMP_counter <= 3'b0;
                    send_lower_byte <= 1'b1;
                end
            endcase
        end
    end
endmodule
