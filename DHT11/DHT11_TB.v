`timescale 1ns / 0.1ps



module DHT11_TB;
    // ���������
    parameter CLK_PERIOD = 10; // ������ ��������� ������� (100 ���)

    // �������� �������
    logic clk;
    logic rst_n;
    logic uart_rx; // ������ ������� �� ����
    logic [15:0] uart_tx; // ������ ���������� ���� (������� T, ����� ���������)
    logic ready; // ������ ����������, ����� uart_tx ����������� � ���������� ready=1; ����� ready=0
    logic dht11_data_output; // ����� 1 ��� ����� (��� �������), ����� 0 - ���� ��� �������
    logic dht11_data_internal; // ����� dht11_data_output=1, ����� ��������� 1/0 ����������������
    reg [39:0] data_sequence; // ������ ������������ ������ 40 ��� ������, ���������� ��������
    tri dht11_data; // ���������������� ����
    

    // ���������� ������
    DHT11 uut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .dht11_data(dht11_data),
        .ready(ready)
    );
    
    
    // ���������� tri ��� inout
   
    assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz; // tri-state 
    //����� dht11_data_output = 0 - ������� ��������
    //����� dht11_data_output = 1 - ����� �������� ������ ����������������, ���������� � dht11_data_internal

    // ������ ������
        initial begin // ����������� ��������
        rst_n = 0;
        #1000;
        rst_n = 1;
        end
        


    // ��������� ��������� �������
    initial begin // ����������� ��������
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // ��������� ��������� �������
    end

   // �������� ������ UART
   initial begin
   uart_rx = 0;
   #1000;
   uart_rx = 1; // �������� 1 ����������������, ����� �������� 16 ��� (8 ��� ����������� � 8 ��� ���������)
   wait(ready == 1); // ������� ������ ����������, uart_tx ��������� � �������
   uart_rx = 0;
   #100_000 $finish;
   end

    // �������� ������ ������� DHT11
    initial begin
    
        // � ������� 1 sec DHT11 ��������������� (��������� ��� � rtl)
        dht11_data_output = 0; // ������������� �� ����
        
        // ������� ������� 0 �� ����������������
         wait(dht11_data == 0);
         #18_000_000; // ���������� � ������� 18 ��
            
         // ����� DHT11:
         dht11_data_output = 1; // ������������� �� �����
         
         dht11_data_internal = 0; // �������� ������ ������ ����������������
         #80_000; // ������ ������ (80 ���)

         dht11_data_internal = 1; // �������� ������� ������
         #80_000; // ������� ������ (80 ���)

          // ����� ���������� ����� ������������������ ���: 00110101_00000000_00011000_00000000_01001101
          data_sequence = 40'b1011010100000000000110000000000001001101;
            for (int i = 0; i < 40; i++) begin
                if (data_sequence[i] == 0) begin
                    // �������� ��� '0'
                    dht11_data_internal = 0; // ������������� ������ �������
                    #50_000; // ���������� ������ ������� (50 ���)
                    dht11_data_internal = 1; // ������������� ������� �������
                    #28_000; // �������� ��� ���������� ���� '0' (26-28 ���)
                end else begin
                    // �������� ��� '1'
                    dht11_data_internal = 0; // ������������� ������ �������
                    #50_000; // ������ ������� (50 ���)
                    dht11_data_internal = 1; // ������������� ������� �������
                    #70_000; // �������� ��� ���������� ���� '1' (70 ���)
                end
            end
             
             // ��������� �������� ������
             dht11_data_internal = 0; // ������������� ������ �������
             #50_000; // ������ ������� (50 ���)
             dht11_data_output = 0; // ���������� �� ����
            // �������� ����� ��������� ��������� ����� ������

        end
 
    // ����������� �������� � �������� ���������
    initial begin
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | counter_2: %d", uart_tx, dht11_data, data_sequence, uut.data_buffer, uut.data_counter, uut.counter_2);
        $monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | a: %d | uart_tx: %b", uart_tx, dht11_data, data_sequence, uut.data_buffer, uut.data_counter, uut.a, uart_tx);
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | counter: %d", uart_tx, dht11_data, data_sequence, uut.counter);
    end
endmodule