`timescale 1ns / 1ps



module DHT11_TB;
    // ���������
    parameter CLK_PERIOD = 10; // ������ ��������� ������� (100 ���)

    // �������� �������
    logic clk;
    logic rst_n;
    logic uart_rx;
    logic [15:0] uart_tx;
    logic ready;
    logic dht11_data_output;
    logic dht11_data_internal;
    reg [39:0] data_sequence;
    tri dht11_data;
    

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
   
    assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz;

        initial begin // ����������� ��������
        rst_n = 0;
        #10000;
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
   #100000;
   uart_rx = 1; // �������� 1 ����������������, ����� �������� 16 ��� (8 ��� ����������� � 8 ��� ���������)
   //#20000;
   //wait(ready == 1);
   end

    // �������� ������ ������� DHT11
    initial begin
    
        #10000; // ���� 1 usec, ����� DHT11 ����������������
        dht11_data_output = 0; // ������������� �� ����
        
        // ������� ������� 0 �� ����������������
         #17_000_000;
         wait(dht11_data == 0);
         #10_000_000;
          // ����������� �������� ����� �������
            
         // ����� DHT11
         dht11_data_output = 1; // ������������� �� �����
         
         dht11_data_internal = 0; // �������� ������ ������
         #80_000; // ������ ������ (80 ���)

         dht11_data_internal = 1; // �������� ������� ������
         #80_000; // ������� ������ (80 ���)

          // ����� ���������� ����� ������������������ ���: 00110101_00000000_00011000_00000000_01001101
          data_sequence = 40'b0011010100000000000110000000000001001101;
            for (int i = 0; i < 40; i++) begin
                if (data_sequence[i] == 0) begin
                    // �������� ��� '0'
                    dht11_data_internal = 1; // ������������� ������ �������
                    #50_000; // ���������� ������� ������� (50 ��)
                    dht11_data_internal = 0; // ������������� ������� �������
                    #28_000; // �������� ��� ���������� ���� '0' (26-28 ��)
                end else begin
                    // �������� ��� '1'
                    dht11_data_internal = 0; // ������������� ������ �������
                    #50_000; // ������ ������� (50 ��)
                    dht11_data_internal = 1; // ������������� ������� �������
                    #70_000; // �������� ��� ���������� ���� '1' (70 ��)
                end
            end

            // �������� ����� ��������� ��������� ����� ������
            #50 $finish;
        end
 
    // ����������� �������� � �������� ���������
    /*initial begin
       //forever #(CLK_PERIOD / 2) clk = ~clk; // ��������� ��������� �������
        $monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b", uart_tx, dht11_data, data_sequence);
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | counter: %d", uart_tx, dht11_data, data_sequence, uut.counter);
    end*/
endmodule