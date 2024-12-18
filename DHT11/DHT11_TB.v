`timescale 1ns / 0.1ps



module DHT11_TB;
    // Ïàðàìåòðû
    parameter CLK_PERIOD = 10; // Ïåðèîä òàêòîâîãî ñèãíàëà (100 ÌÃö)

    // Òåñòîâûå ñèãíàëû
    logic clk;
    logic rst_n;
    logic uart_rx; // ñèãíàë çàïðîñà îò Ðîìû
    logic [15:0] uart_tx; // äàííûå ïîñûëàåìûå Ðîìå (ñíà÷àëà T, ïîòîì âëàæíîñòü)
    logic ready; // ñèãíàë ãîòîâíîñòè, êîãäà uart_tx ñôîðìèðîâàí è îòïðàâëåíá ready=1; èíà÷å ready=0
    logic dht11_data_output; // êîãäà 1 ýòî âûõîä (äëÿ äàò÷èêà), êîãäà 0 - âõîä äëÿ äàò÷èêà
    logic dht11_data_internal; // êîãäà dht11_data_output=1, ìîæíî îòïðàâèòá 1/0 ìèêðîêîíòðîëëåðó
    reg [39:0] data_sequence; // ïðîñòî èñêóñòâåííûé ïðèìåð 40 áèò äàííûõ, ïîñûëàåìûõ äàò÷èêîì
    tri dht11_data; // îäíîíàïðàâëåííàÿ øèíà
    

    // Ïîäêëþ÷àåì ìîäóëü
    DHT11 uut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .dht11_data(dht11_data),
        .ready(ready)
    );
    
    
    // Èñïîëüçóåì tri äëÿ inout
   
    assign dht11_data = dht11_data_output ? dht11_data_internal : 'bz; // tri-state 
    //Êîãäà dht11_data_output = 0 - âûñîêèé èìïåäàíñ
    //Êîãäà dht11_data_output = 1 - ìîæåì ïåðåäàòü äàííûå ìèêðîêîíòðîëëåðó, çàïèñàííûå â dht11_data_internal

    // Ñèãíàë ñáðîñà
        initial begin // âûïîëíÿåòñÿ åäèíîæäû
        rst_n = 0;
        #1000;
        rst_n = 1;
        end
        


    // Ãåíåðàöèÿ òàêòîâîãî ñèãíàëà
    initial begin // âûïîëíÿåòñÿ åäèíîæäû
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk; // ãåíåðàöèÿ òàêòîâîãî ñèãíàëà
    end

   // èìèòàöèÿ ðàáîòû UART
   initial begin
   uart_rx = 0;
   #1000;
   uart_rx = 1; // ïîñûëàåì 1 ìèêðîêîíòðîëëåðó, ÷òîáû ïîëó÷èòü 16 áèò (8 áèò òåìïåðàòóðû è 8 áèò âëàæíîñòè)
   wait(ready == 1); // îæèäàåì ñèãíàë ãîòîâíîñòè, uart_tx âûâîäèòñÿ â êîíñîëü
   uart_rx = 0;
   #100_000 $finish;
   end

    // Èìèòàöèÿ ðàáîòû äàò÷èêà DHT11
    initial begin
    
        // Â òå÷åíèå 1 sec DHT11 ñòàáèëèçèðóåòñÿ (ó÷èòûâàåì ýòî â rtl)
        dht11_data_output = 0; // óñòàíàâëèâàåì íà âõîä
        
        // Îæèäàåì êîìàíäó 0 îò ìèêðîêîíòðîëëåðà
         wait(dht11_data == 0);
         #18_000_000; // Ðàñïîçíàåì â òå÷åíèå 18 ìñ
            
         // Îòâåò DHT11:
         dht11_data_output = 1; // Óñòàíàâëèâàåì íà âûõîä
         
         dht11_data_internal = 0; // Ïåðåäàåì íèçêèé ñèãíàë ìèêðîêîíòðîëëåðó
         #80_000; // Íèçêèé ñèãíàë (80 ìêñ)

         dht11_data_internal = 1; // Ïåðåäàåì âûñîêèé ñèãíàë
         #80_000; // Âûñîêèé ñèãíàë (80 ìêñ)

          // Áóäåì ïåðåäàâàòü òàêóþ ïîñëåäîâàòåëüíîñòü áèò: 00110101_00000000_00011000_00000000_01001101
          data_sequence = 40'b0011010100000000000110000000000001001101;
            for (int i = 0; i < 40; i++) begin
                if (data_sequence[i] == 0) begin
                    // Ïåðåäàåì áèò '0'
                    dht11_data_internal = 0; // Óñòàíàâëèâàåì íèçêèé óðîâåíü
                    #50_000; // Óäåðæèâàåì íèçêèé óðîâåíü (50 ìêñ)
                    dht11_data_internal = 1; // Óñòàíàâëèâàåì âûñîêèé óðîâåíü
                    #28_000; // Çàäåðæêà äëÿ çàâåðøåíèÿ áèòà '0' (26-28 ìêñ)
                end else begin
                    // Ïåðåäàåì áèò '1'
                    dht11_data_internal = 0; // Óñòàíàâëèâàåì íèçêèé óðîâåíü
                    #50_000; // Íèçêèé óðîâåíü (50 ìêñ)
                    dht11_data_internal = 1; // Óñòàíàâëèâàåì âûñîêèé óðîâåíü
                    #70_000; // Çàäåðæêà äëÿ çàâåðøåíèÿ áèòà '1' (70 ìêñ)
                end
            end
             
             // îêîí÷àíèå ïåðåäà÷è äàííûõ
             dht11_data_internal = 0; // Óñòàíàâëèâàåì íèçêèé óðîâåíü
             #50_000; // Íèçêèé óðîâåíü (50 ìêñ)
             dht11_data_output = 0; // âûñòàâëÿåì íà âõîä
            // Îæèäàíèå ïåðåä ñëåäóþùåé èòåðàöèåé öèêëà îáìåíà

        end
 
    // Îòîáðàæåíèå çíà÷åíèé â ïðîöåññå ñèìóëÿöèè
    initial begin
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | counter_2: %d", uart_tx, dht11_data, data_sequence, uut.data_buffer, uut.data_counter, uut.counter_2);
        $monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | data_buffer: %b | data_counter: %d | a: %d | uart_tx: %b", uart_tx, dht11_data, data_sequence, uut.data_buffer, uut.data_counter, uut.a, uart_tx);
        //$monitor(" uart_tx: %b | dht11_data: %b | data_sequence: %b | counter: %d", uart_tx, dht11_data, data_sequence, uut.counter);
    end
endmodule
