`timescale 1ns / 0.1ps



module DHT11_TB;
    // ���������
    parameter CLK_PERIOD = 10; // ������ ��������� ������� (50 ���)
    parameter DATA_WIDTH = 8;
    parameter BAUD_RATE  = 115200;


    // �������� �������
    logic clk;
logic rst_n;
//logic uart_rx_i;
//logic uart_tx_o;
tri   dht11_data;
//logic       echo;
//logic       trig;
logic dht11_data_output; // когда 1 это выход (для датчика), когда 0 - вход для датчика
logic dht11_data_internal; // когда dht11_data_output=1, можно отправитб 1/0 микроконтроллеру
logic [39:0] data_sequence;
assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz; // tri-state 
    
    logic        dht11_start;           //signal for initializing DHT11 measurements
    logic [15:0] dht11_data_rec;            //received data from DHT11
    logic        dht11_data_available;  //is data from DHT11 available?
    
    logic        dht11_data_i;
    logic        dht11_data_o;
    logic        dht11_data_o_en;

    assign dht11_data_i = dht11_data;
    assign dht11_data   = dht11_data_o_en ? dht11_data_o : 'bz;

    // ���������� ������
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
    

    // ���������� tri ��� inout
    //assign dht11_data_i = dht11_data;
    //assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz; // tri-state 
    //����� dht11_data_output = 0 - ������� ��������
    //����� dht11_data_output = 1 - ����� �������� ������ ����������������, ���������� � dht11_data_internal


    initial begin // �����
        rst_n = 0;
        #1000;
        rst_n = 1;
    end
        


    // ????????? ????????? ???????
    initial begin // ??????????? ????????
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // ????????? ????????? ???????
    end

   // ???????? ?????? UART
   initial begin
   dht11_start = 0;
   #1000;
   dht11_start = 1; // ???????? 1 ????????????????, ????? ???????? 16 ??? (8 ??? ??????????? ? 8 ??? ?????????)
   #100;
   dht11_start = 0;
   wait(dht11_data_available == 1); // ??????? ?????? ??????????, uart_tx ????????? ? ???????
   #10000;
   dht11_start = 1;
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
          data_sequence = 40'b10110010_00000000_00011000_00000000_10101100;
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
        $monitor(" uart_rx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | a: %d | uart_tx: %b | humidity_integer: %b | humidity_real: %b | temperature_integer: %b | temperature_real: %b | checksum: %b", dht11_start, dht11_data, data_sequence, i_dht11.data_buffer, i_dht11.data_counter, i_dht11.a, dht11_data_rec, i_dht11.humidity_integer, i_dht11.humidity_real, i_dht11.temperature_integer, i_dht11.temperature_real,  i_dht11.checksum);
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | counter: %d", uart_tx, dht11_data, data_sequence, uut.counter);
    end
endmodule
