`timescale 1ns / 1ps

module DHT11(
    input logic clk,          // Тактовый сигнал 100 МГц
    input logic rst_n,        // Сигнал сброса
    input logic uart_rx,      // Входной сигнал UART для запроса данных (1 или 0)
    output logic [15:0] uart_tx,     // Выходной сигнал UART для передачи данных (сначала T, потом влажность)
    inout logic dht11_data,
    output logic ready        // Сигнал готовности данных
);

    // Параметры
    parameter CLK_FREQ = 100000000; // Частота кристалла (100 МГц)
    parameter DHT11_START_DELAY = 100000000; // 1 sec
    parameter DHT11_DELAY = 1800000; // Задержка на 18 мс в тактах
    parameter DHT11_RESPONSE_TIME = 8000; // 80 мкс
    parameter DHT11_DATA_BITS = 40; // Количество бит данных
    //parameter TIMEOUT = 10000; // Таймаут для ожидания данных (в тактах)

    // Константы для временных интервалов (кодировка 0 и 1)
   parameter LOW_DURATION = 5000; // 50 микросекунд
   parameter HIGH_DURATION_0 = 2800; // 28 микросекунд
   parameter HIGH_DURATION_1 = 7000; // 70 микросекунд


    // Состояния КА
    typedef enum logic [2:0] {
        IDLE,
        START,
        WAIT_RESPONSE,
        READ_DATA,
        SEND_DATA,
        ERROR
    } state_t; // новый тип данных

    state_t state, next_state;

    // Счетчики для задержек
    logic [27:0] counter; // счетчик "времени"
    logic [5:0] data_counter; // счетчик данных для 40 бит (отслеживает количество считанных бит данных)
    logic [14:0] bit_counter; // счетчик длительности для кодировки бит (max мб 12_000)

    // Хранение данных
    logic [7:0] humidity_integer;
    logic [7:0] temperature_integer;
    logic [39:0] data_buffer; // вектор 40 бит
    logic [7:0] checksum; // Контрольная сумма (последние 8 бит)

    // Сигнал для передачи через UART
    logic [15:0] uart_data; // Данные для передачи в UART

    // Логика управления dht11_data
    logic dht11_data_output; // Сигнал для управления направлением (0 это вход, 1 - выход)
    logic dht11_data_internal; // Внутренний сигнал для управления данными
    // tri-state логика:
    assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz;
    
    // Состояние и переходы
    always_ff @(posedge clk or negedge rst_n) begin // для синхронного процесса
        if (!rst_n) begin
            state <= IDLE; // режим ожидания
            counter <= 0; // сброс счетчика
            ready <= 0; // сигнал готовности
            data_buffer <= 0; // сброс буфера данных
            humidity_integer <= 0;
            temperature_integer <= 0;
            data_counter <= 0;
            bit_counter <= 0;
            uart_data <= 0; // Данные для отправки в UART
            dht11_data_output <= 1; // Изначально dht11_data на выход
            checksum <= 0;
        end 
        else begin
        state <= next_state;

            // Управление счетчиками
            if (state == START || state == WAIT_RESPONSE) begin
                counter <= counter + 1;
            end 
            else begin
                counter <= 0;
            end
            
            
            

            // Получение данных от датчика
            if (state == READ_DATA) begin
            bit_counter <= 0; // счетчик длительности для кодировки бит
            data_counter <= 0;
                while (data_counter != 40) begin
                bit_counter <= bit_counter + 1;
                    if (bit_counter >= LOW_DURATION) begin // 50 мкс
                        // Определение битов
                        if (bit_counter == (LOW_DURATION + (HIGH_DURATION_0-500)) && dht11_data == 0) begin
                        // кодировка 0 
                        data_buffer[data_counter] <= 0;
                        bit_counter <= 0;
                        continue;
                        end else if (bit_counter == (LOW_DURATION + (HIGH_DURATION_1-500)) && dht11_data == 1) begin
                        // кодировка 1 
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
    // Логика переходов состояний; выполняется всегда, когда меняются входные сигналы
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
            // шаг 2
            if (counter >= DHT11_START_DELAY) begin  // 1 sec
            dht11_data_output = 1; // выход
            dht11_data_internal = 0; // отправляем 0 датчику
            if (counter >= DHT11_START_DELAY+DHT11_DELAY) begin // Задержка на 18 мс
                    dht11_data_output = 0; // Переключаем в режим чтения данных от датчика
                    next_state = WAIT_RESPONSE;
                end
            end  
            end
            WAIT_RESPONSE: begin
            if (dht11_data == 0) begin
                // получаем ноль от датчика
                if (counter >= DHT11_START_DELAY+DHT11_DELAY+DHT11_RESPONSE_TIME) begin // Ждем 80 мкс
                    // После низкого сигнала, ждем высокий
                     if (dht11_data == 1) begin
                    // ждем еще 80 мкс
                        if (counter >= DHT11_START_DELAY+DHT11_DELAY+2*DHT11_RESPONSE_TIME) begin
                    next_state = READ_DATA; // Переходим к чтению данных
                end
                end
                end
                end
        end
            READ_DATA: begin
                if (data_counter >= DHT11_DATA_BITS) begin // когда получили 40 бит, переходим к отправке
                    next_state = SEND_DATA;
                end
                /*if (counter >= TIMEOUT) begin
                    next_state = ERROR; // Таймаут
                 end*/
            end
            SEND_DATA: begin
                        humidity_integer = data_buffer[7:0]; // Влажность
                        temperature_integer = data_buffer[23:16]; // Температура
                        checksum = data_buffer[39:32]; // Контрольная сумма
                        if (checksum == (humidity_integer + temperature_integer)) begin
                            uart_tx = {temperature_integer, humidity_integer}; // Формируем 16 бит для передачи
                            ready <= 1;
                        end
                        else begin
                            uart_tx = 16'h0000; // Если контрольная сумма неверна, отправляем 0
                            ready <= 1;
                        end
                            next_state = IDLE; // Переходим в состояние ожидания
                    end
                    
            ERROR: begin
                uart_tx = 16'h0000; // Отправляем 0 в случае ошибки
                ready <= 1;
                next_state = IDLE; // Переходим в состояние передачи данных
            end
        endcase
    end
endmodule
