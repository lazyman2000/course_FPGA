`timescale 1ns / 1ps

module DHT11(
    input logic clk,          // �������� ������ 100 ���
    input logic rst_n,        // ������ ������
    input logic uart_rx,      // ������� ������ UART ��� ������� ������ (1 ��� 0)
    output logic [15:0] uart_tx,     // �������� ������ UART ��� �������� ������ (������� T, ����� ���������)
    inout logic dht11_data,
    output logic ready        // ������ ���������� ������
);

    // ���������
    parameter CLK_FREQ = 100000000; // ������� ��������� (100 ���)
    parameter DHT11_START_DELAY = 100000000; // 1 sec
    parameter DHT11_DELAY = 1800000; // �������� �� 18 �� � ������
    parameter DHT11_RESPONSE_TIME = 8000; // 80 ���
    parameter DHT11_DATA_BITS = 40; // ���������� ��� ������
    //parameter TIMEOUT = 10000; // ������� ��� �������� ������ (� ������)

    // ��������� ��� ��������� ���������� (��������� 0 � 1)
   parameter LOW_DURATION = 5000; // 50 �����������
   parameter HIGH_DURATION_0 = 2800; // 28 �����������
   parameter HIGH_DURATION_1 = 7000; // 70 �����������


    // ��������� ��
    typedef enum logic [2:0] {
        IDLE,
        START,
        WAIT_RESPONSE,
        READ_DATA,
        SEND_DATA,
        ERROR
    } state_t; // ����� ��� ������

    state_t state, next_state;

    // �������� ��� ��������
    logic [27:0] counter; // ������� "�������"
    logic [5:0] data_counter; // ������� ������ ��� 40 ��� (����������� ���������� ��������� ��� ������)
    logic [14:0] bit_counter; // ������� ������������ ��� ��������� ��� (max �� 12_000)

    // �������� ������
    logic [7:0] humidity_integer;
    logic [7:0] temperature_integer;
    logic [39:0] data_buffer; // ������ 40 ���
    logic [7:0] checksum; // ����������� ����� (��������� 8 ���)

    // ������ ��� �������� ����� UART
    logic [15:0] uart_data; // ������ ��� �������� � UART

    // ������ ���������� dht11_data
    logic dht11_data_output; // ������ ��� ���������� ������������ (0 ��� ����, 1 - �����)
    logic dht11_data_internal; // ���������� ������ ��� ���������� �������
    // tri-state ������:
    assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz;
    
    // ��������� � ��������
    always_ff @(posedge clk or negedge rst_n) begin // ��� ����������� ��������
        if (!rst_n) begin
            state <= IDLE; // ����� ��������
            counter <= 0; // ����� ��������
            ready <= 0; // ������ ����������
            data_buffer <= 0; // ����� ������ ������
            humidity_integer <= 0;
            temperature_integer <= 0;
            data_counter <= 0;
            bit_counter <= 0;
            uart_data <= 0; // ������ ��� �������� � UART
            dht11_data_output <= 1; // ���������� dht11_data �� �����
            checksum <= 0;
        end 
        else begin
        state <= next_state;

            // ���������� ����������
            if (state == START || state == WAIT_RESPONSE) begin
                counter <= counter + 1;
            end 
            else begin
                counter <= 0;
            end
            
            
            

            // ��������� ������ �� �������
            if (state == READ_DATA) begin
            bit_counter <= 0; // ������� ������������ ��� ��������� ���
            data_counter <= 0;
                while (data_counter != 40) begin
                bit_counter <= bit_counter + 1;
                    if (bit_counter >= LOW_DURATION) begin // 50 ���
                        // ����������� �����
                        if (bit_counter == (LOW_DURATION + (HIGH_DURATION_0-500)) && dht11_data == 0) begin
                        // ��������� 0 
                        data_buffer[data_counter] <= 0;
                        bit_counter <= 0;
                        continue;
                        end else if (bit_counter == (LOW_DURATION + (HIGH_DURATION_1-500)) && dht11_data == 1) begin
                        // ��������� 1 
                         data_buffer[data_counter] <= 1;
                         bit_counter <= 0;
                         continue;
                        end
                        data_counter <= data_counter + 1;
                    end
                    bit_counter <= 0;
                    end
                end
            end
        end
    
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ������ ��������� ���������; ����������� ������, ����� �������� ������� �������
    always_comb begin
        next_state = state;
        case (state)
           IDLE: begin
           ready <= 0;
                if (uart_rx) begin
                    next_state = START;
                end
            end
            START: begin
            // ��� 2
            if (counter >= DHT11_START_DELAY) begin  // 1 sec
            dht11_data_output = 1; // �����
            dht11_data_internal = 0; // ���������� 0 �������
            if (counter >= DHT11_START_DELAY+DHT11_DELAY) begin // �������� �� 18 ��
                    dht11_data_output = 0; // ����������� � ����� ������ ������ �� �������
                    next_state = WAIT_RESPONSE;
                end
            end  
            end
            WAIT_RESPONSE: begin
            if (dht11_data == 0) begin
                // �������� ���� �� �������
                if (counter >= DHT11_START_DELAY+DHT11_DELAY+DHT11_RESPONSE_TIME) begin // ���� 80 ���
                    // ����� ������� �������, ���� �������
                     if (dht11_data == 1) begin
                    // ���� ��� 80 ���
                        if (counter >= DHT11_START_DELAY+DHT11_DELAY+2*DHT11_RESPONSE_TIME) begin
                    next_state = READ_DATA; // ��������� � ������ ������
                end
                end
                end
                end
        end
            READ_DATA: begin
                if (data_counter >= DHT11_DATA_BITS) begin // ����� �������� 40 ���, ��������� � ��������
                    next_state = SEND_DATA;
                end
                /*if (counter >= TIMEOUT) begin
                    next_state = ERROR; // �������
                 end*/
            end
            SEND_DATA: begin
                        humidity_integer = data_buffer[7:0]; // ���������
                        temperature_integer = data_buffer[23:16]; // �����������
                        checksum = data_buffer[39:32]; // ����������� �����
                        if (checksum == (humidity_integer + temperature_integer)) begin
                            uart_tx = {temperature_integer, humidity_integer}; // ��������� 16 ��� ��� ��������
                            ready <= 1;
                        end
                        else begin
                            uart_tx = 16'h0000; // ���� ����������� ����� �������, ���������� 0
                            ready <= 1;
                        end
                            next_state = IDLE; // ��������� � ��������� ��������
                    end
                    
            ERROR: begin
                uart_tx = 16'h0000; // ���������� 0 � ������ ������
                ready <= 1;
                next_state = IDLE; // ��������� � ��������� �������� ������
            end
        endcase
    end
endmodule
