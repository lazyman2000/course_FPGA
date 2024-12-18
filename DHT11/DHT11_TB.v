`timescale 1ns / 0.1ps



module DHT11_TB;
    // Параметры
    parameter CLK_PERIOD = 10; // Период тактового сигнала (100 МГц)

    // Тестовые сигналы
    logic clk;
    logic rst_n;
    logic uart_rx; // сигнал запроса от Ромы
    logic [15:0] uart_tx; // данные посылаемые Роме (сначала T, потом влажность)
    logic ready; // сигнал готовности, когда uart_tx сформирован и отправленб ready=1; иначе ready=0
    logic dht11_data_output; // когда 1 это выход (для датчика), когда 0 - вход для датчика
    logic dht11_data_internal; // когда dht11_data_output=1, можно отправитб 1/0 микроконтроллеру
    reg [39:0] data_sequence; // просто искуственный пример 40 бит данных, посылаемых датчиком
    tri dht11_data; // однонаправленная шина
    

    // Подключаем модуль
    DHT11 uut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .dht11_data(dht11_data),
        .ready(ready)
    );
    
    
    // Используем tri для inout
   
    assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz; // tri-state 
    //Когда dht11_data_output = 0 - высокий импеданс
    //Когда dht11_data_output = 1 - можем передать данные микроконтроллеру, записанные в dht11_data_internal

    // Сигнал сброса
        initial begin // выполняется единожды
        rst_n = 0;
        #1000;
        rst_n = 1;
        end
        


    // Генерация тактового сигнала
    initial begin // выполняется единожды
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // генерация тактового сигнала
    end

   // имитация работы UART
   initial begin
   uart_rx = 0;
   #1000;
   uart_rx = 1; // посылаем 1 микроконтроллеру, чтобы получить 16 бит (8 бит температуры и 8 бит влажности)
   wait(ready == 1); // ожидаем сигнал готовности, uart_tx выводится в консоль
   uart_rx = 0;
   #100_000 $finish;
   end

    // Имитация работы датчика DHT11
    initial begin
    
        // В течение 1 sec DHT11 стабилизируется (учитываем это в rtl)
        dht11_data_output = 0; // устанавливаем на вход
        
        // Ожидаем команду 0 от микроконтроллера
         wait(dht11_data == 0);
         #18_000_000; // Распознаем в течение 18 мс
            
         // Ответ DHT11:
         dht11_data_output = 1; // Устанавливаем на выход
         
         dht11_data_internal = 0; // Передаем низкий сигнал микроконтроллеру
         #80_000; // Низкий сигнал (80 мкс)

         dht11_data_internal = 1; // Передаем высокий сигнал
         #80_000; // Высокий сигнал (80 мкс)

          // Будем передавать такую последовательность бит: 00110101_00000000_00011000_00000000_01001101
          data_sequence = 40'b1011010100000000000110000000000001001101;
            for (int i = 0; i < 40; i++) begin
                if (data_sequence[i] == 0) begin
                    // Передаем бит '0'
                    dht11_data_internal = 0; // Устанавливаем низкий уровень
                    #50_000; // Удерживаем низкий уровень (50 мкс)
                    dht11_data_internal = 1; // Устанавливаем высокий уровень
                    #28_000; // Задержка для завершения бита '0' (26-28 мкс)
                end else begin
                    // Передаем бит '1'
                    dht11_data_internal = 0; // Устанавливаем низкий уровень
                    #50_000; // Низкий уровень (50 мкс)
                    dht11_data_internal = 1; // Устанавливаем высокий уровень
                    #70_000; // Задержка для завершения бита '1' (70 мкс)
                end
            end
             
             // окончание передачи данных
             dht11_data_internal = 0; // Устанавливаем низкий уровень
             #50_000; // Низкий уровень (50 мкс)
             dht11_data_output = 0; // выставляем на вход
            // Ожидание перед следующей итерацией цикла обмена

        end
 
    // Отображение значений в процессе симуляции
    initial begin
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | counter_2: %d", uart_tx, dht11_data, data_sequence, uut.data_buffer, uut.data_counter, uut.counter_2);
        $monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | a: %d | uart_tx: %b", uart_tx, dht11_data, data_sequence, uut.data_buffer, uut.data_counter, uut.a, uart_tx);
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | counter: %d", uart_tx, dht11_data, data_sequence, uut.counter);
    end
endmodule