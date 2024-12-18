//`timescale 1ns / 1ps

module DHT11(
    input logic clk,          // �������� ������ 100 ���
    input logic rst_n,        // ������ ������
    input logic uart_rx,      // ������� ������ UART ��� ������� ������ (1 ��� 0)
    output logic [15:0] uart_tx,  // �������� ������ ��� �������� ������ ���� (������� T, ����� ���������)
    //inout logic dht11_data,   // ����
	input  logic dht11_data_i,
	output logic dht11_data_o,
	output logic dht11_data_o_en,
    output logic ready        // ������ ���������� ������ ��� ����
);

    // ���������
    parameter DHT11_START_DELAY = 100000000/2;// 10 us ������ ��� �������� ������������� //100000000; �� 1 sec
    parameter DHT11_DELAY = 1800000/2; // �������� �� 18 �� � ������
    parameter DHT11_RESPONSE_TIME = 8000/2; // 80 ���
    parameter DHT11_DATA_BITS = 40; // ���������� ��� ������

    // ��������� ��� ��������� ���������� (��������� 0 � 1)
   parameter LOW_DURATION = 5000/2; // 50 �����������
   parameter HIGH_DURATION_0 = 2000/2; // 28 �����������
   parameter HIGH_DURATION_1 = 7000/2; // 70 �����������


    // ��������� ��
    typedef enum logic [2:0] {
        IDLE,
        START,
        WAIT_RESPONSE,
        READ_DATA,
        SEND_DATA
    } state_t; // ����� ��� ������

    state_t state, next_state;

    // �������� ��� ��������
    logic [28:0] counter; // ������� "�������"
    logic [5:0] data_counter; // ������� ������ ��� 40 ��� (����������� ���������� ��������� ��� ������)
    logic [16:0] bit_counter; // ������� ������������ ��� ��� ��������� ��� (max �� 12_000)
    
    logic  a; // ������������ ������ �  WAIT_RESPONSE ��� �������� ������ � ������ �������� ��������
	logic  a_next;

    // �������� ������
    logic [7:0] humidity_integer; // ��� �������� 8 ��� ���������� ���������
    logic [7:0] temperature_integer; // ��� �������� 8 ��� ���������� �
    logic [39:0] data_buffer; // ������ 40 ��� ��� ������� 40 ��� ������, ���������� �� ������� �� ����
    logic [7:0] checksum; // ����������� ����� (��������� 8 ���)

    // ������ ���������� dht11_data
    logic dht11_data_output; // ������ ��� ���������� ������������ (0 ��� ����, 1 - �����)
    logic dht11_data_internal; // ���������� ������ ��� ���������� �������
    logic dht11_data_output_ff;
    logic dht11_data_internal_ff;

	//logic ready_next;
	
	logic dht11_data_ff;
	logic falling_edge;
	logic rising_edge;
	
	always_ff @(posedge clk, negedge rst_n)
		if (~rst_n)
			dht11_data_ff <= '0;
		else if (dht11_data_output_ff)
			dht11_data_ff <= '0;
		else
			dht11_data_ff <= dht11_data_i;
			
	assign rising_edge  = !dht11_data_ff && dht11_data_i && !dht11_data_output_ff;
	assign falling_edge = dht11_data_ff && !dht11_data_i && !dht11_data_output_ff;
	
    // tri-state ������:
    //assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz;
	assign dht11_data_o = dht11_data_internal_ff;
	assign dht11_data_o_en = dht11_data_output_ff;
    //����� dht11_data_output = 0 - ������� ��������
    //����� dht11_data_output = 1 - ����� �������� ������ �������, ���������� � dht11_data_internal
    
    // ��������� � ��������
    always_ff @(posedge clk or negedge rst_n) begin // ��� ����������� ��������
        if (!rst_n) begin
            state <= IDLE; // ����� ��������
            counter <= '0; // ����� ��������
            data_buffer <= '0; // ����� ������ ������
            data_counter <= '0;
            bit_counter <= 15'b1;
            a <= 0;
            dht11_data_output_ff <= '0;
            dht11_data_internal_ff <= '0;
        end 
        else begin
            state <= next_state;
		    a     <= a_next;
            dht11_data_output_ff <= dht11_data_output;
            dht11_data_internal_ff <= dht11_data_internal;
            // ���������� ����������
            if (state == START || state == WAIT_RESPONSE) begin // ������� ��������� ������ � ���� ���� ���������
                counter <= counter + 1;
            end 
            else begin
                counter <= 0;
            end
            

            // ��������� ������ �� �������
            if (state == READ_DATA) begin
               if (data_counter !=40 ) begin // ���� �� ������� 40 ��� ������ (�� 0 �� 39)
               bit_counter <= bit_counter + 1; // ����������� ��������� ������� ��� ����������� ������������ ���
                    // ����������� �����
                    if (falling_edge) begin // ��������� 0 : 50 ��� 0 � 26-28 ��� 1
                    data_buffer[data_counter] <= 0; // ���������� 0 � ������
                    data_counter <= data_counter + 1; // ����������� ���-�� ��������� ��� �� 1
                    bit_counter <= 15'b1; // ���������� ��������� ������� ��� ����������� ������������ ���
                    end
                    if (bit_counter >= (LOW_DURATION + (HIGH_DURATION_1)) && falling_edge) begin // ��������� 1 : 50 ��� 0 � 70 ��� 1
                    data_buffer[data_counter] <= 1; // ���������� 1 � ������
                    data_counter <= data_counter + 1; // ����������� ���-�� ��������� ��� �� 1
                    bit_counter <= 15'b1; // ���������� ��������� ������� ��� ����������� ������������ ���
                    end
                    end
				else begin
					data_counter <= 0;
					bit_counter <= 15'b1;
				end
            end
            end
        end
    
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // ������ ��������� ���������;
    always_comb begin
        ready = 0;
        dht11_data_output = 0;
        dht11_data_internal = 1;
        next_state = state;
        a_next = a;
		uart_tx = 0; // �������� ������� ������������ ������
        humidity_integer = 0;
        temperature_integer =0;
        checksum =0;
        case (state)
            IDLE: begin
                ready = 0;
                //data_buffer = 0;
                a_next = 0;
                        if (uart_rx) begin // ���� �������� 1 �� ����
                            
                            next_state = START;
                        end
            end
            START: begin
            // ��� 2
                if (counter >= DHT11_START_DELAY) begin  // ����  1 sec, ����� ������ ����������������
                dht11_data_output = 1; // ������������� �� �����
                dht11_data_internal = 0; // ���������� 0 �������
                if (counter >= DHT11_START_DELAY+DHT11_DELAY) begin // ������ 0 � ������� 18 ��
                        dht11_data_output = 0; // ������������� � ����� ������ ������ �� �������
                        next_state = WAIT_RESPONSE;
                    end
                end  
            end
            WAIT_RESPONSE: begin
            if ((counter >= (DHT11_RESPONSE_TIME+DHT11_START_DELAY+DHT11_DELAY)) && rising_edge && a == 0) begin // �������� ������� ���� �� ������� (���� ������ 80 ���)
            a_next = 1;
            end
            if (falling_edge && a == 1) begin // �������� 1 �� ������� (1 ������ 80 ���)
            next_state = READ_DATA;
            end
            end
            READ_DATA: begin
               if (data_counter == 40) begin // ����� �������� 40 ��� (�� 0 �� 39), ��������� � �������� 
                next_state = SEND_DATA;
                end
            end
            SEND_DATA: begin
                        // �������� ������ ����
                        //humidity_integer = data_buffer[39:32]; // �������� ���������
                        for (int i = 0; i<8; i++) begin
                            humidity_integer[i] = data_buffer[7-i];
                        end
                        //temperature_integer = data_buffer[23:16]; // �������� �����������
                        //temperature_integer = data_buffer[16:23]; // �������� �����������
                        for (int i = 0; i<8; i++) begin
                            temperature_integer[i] = data_buffer[23-i];
                        end
                        //checksum = data_buffer[32:39]; // �������� ����������� �����
                        for (int i = 0; i<8; i++) begin
                            checksum[i] = data_buffer[39-i];
                        end
                        if (checksum == (humidity_integer + temperature_integer)) begin // ���� �� �����
                            uart_tx = {temperature_integer, humidity_integer}; // ��������� 16 ��� ��� ��������
                            ready = 1; // ���������� ���� ����������
                        end
                        else begin // ���� ����������� ����� �������
                            uart_tx = {temperature_integer, humidity_integer}; // ���� ����������� ����� �������, ���������� 0
                            ready = 1; // ���������� ���� ����������
                        end
                            next_state = IDLE; // ��������� � ��������� ��������
                    end
            // default: begin
            //     ready = 0;
            //     dht11_data_output = 0;
            //     dht11_data_internal = 0;
            //     next_state = state;
            //     a_next = 0;
            //     uart_tx = 0; // �������� ������� ������������ ������
            //     humidity_integer = 0;
            //     temperature_integer =0;
            //     checksum =0;
            // end
        endcase
    end
endmodule
