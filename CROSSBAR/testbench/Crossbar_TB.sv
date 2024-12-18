`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Starodubov Roman Alexandrovich
// 
// Create Date: 07.12.2024 20:38:45
// Module Name: Crossbar_TB
// Project Name: -
// Target Devices: Arty A7-35
//
// Additional Comments: Version 5
// 
//////////////////////////////////////////////////////////////////////////////////

module crossbar_pipeline_tb;

    logic clk;
    logic rst;
    logic [7:0] uart_rx;
    logic [7:0] uart_tx;
    logic uart_ready;
    logic dht11_start;
    logic [15:0] dht11_data;
    logic dht11_data_available;
    logic hc_sr04_start;
    logic [15:0] hc_sr04_data;
    logic hc_sr04_data_available;
    logic valid_command; 
    logic ready_to_act; 
    logic data_transaction_ready; 

    localparam CLK_PERIOD = 10; //100 MHz

    Crossbar_pipeline uut (
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .uart_ready(uart_ready),
        .dht11_start(dht11_start),
        .dht11_data(dht11_data),
        .dht11_data_available(dht11_data_available),
        .hc_sr04_start(hc_sr04_start),
        .hc_sr04_data(hc_sr04_data),
        .hc_sr04_data_available(hc_sr04_data_available),
        .valid_command(valid_command),
        .ready_to_act(ready_to_act),
        .data_transaction_ready(data_transaction_ready)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;
    
    task reset_system();
        begin
            rst = 0;
            #(2 * CLK_PERIOD);
            rst = 1;
        end
    endtask

    task send_command(input [7:0] command);
        begin
            @(posedge clk);
            uart_rx = command; 
            #(CLK_PERIOD);
        end
    endtask
   
    initial begin
        clk = 0;
        uart_rx = 0;
        dht11_data = 16'd9587;
        hc_sr04_data = 16'd3214; 
        dht11_data_available = 0;
        hc_sr04_data_available = 0;
        uart_ready = 1; //(MIGHT BE OUTDATED)by deffault uart_ready always 1 except when UART is busy
        valid_command = 0;
        
        reset_system();

        $display("Testing command 'T'...");
        send_command(8'h54); 
        #(25*CLK_PERIOD);
        valid_command = 1;
        #(CLK_PERIOD);
        valid_command = 0;
        #(25*CLK_PERIOD);
        dht11_data_available = 1;
        #(CLK_PERIOD);
        dht11_data_available = 0; 
        #(50*CLK_PERIOD);
        uart_ready = 0;
        #(50*CLK_PERIOD);
        uart_ready = 1;
        #(50*CLK_PERIOD);
        uart_ready = 0;
        #(50*CLK_PERIOD);
        uart_ready = 1;
        #(50*CLK_PERIOD);
        uart_ready = 0;
        #(50*CLK_PERIOD);
        uart_ready = 1;
        #(50*CLK_PERIOD);
        uart_ready = 0;
        #(50*CLK_PERIOD);
        uart_ready = 1;
        #(50*CLK_PERIOD);
        uart_ready = 0;
        #(50*CLK_PERIOD);

        $display("Testing command 'D'...");
        send_command(8'h44); 
        #(25*CLK_PERIOD);
        valid_command = 1;
        #(CLK_PERIOD);
        valid_command = 0;
        #(25*CLK_PERIOD);
        hc_sr04_data_available = 1; 
        #(CLK_PERIOD);
        hc_sr04_data_available = 0; 
        #(50*CLK_PERIOD);
        uart_ready = 0;
        #(50*CLK_PERIOD);
        uart_ready = 1;
        #(50*CLK_PERIOD);
        //hc_sr04_data_available = 0;
        uart_ready = 1;
        #(30*CLK_PERIOD);
        uart_ready = 0;
        #(30*CLK_PERIOD);
        uart_ready = 1;
        #(30*CLK_PERIOD);
        uart_ready = 0;
        #(30*CLK_PERIOD);
        uart_ready = 1;
        #(30*CLK_PERIOD); 
        

        $display("Testing invalid command...");
        send_command(8'h58); 
        #(500*CLK_PERIOD);
        $display("All tests completed.");
        $stop;
    end
endmodule