module parallel_to_serial
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      parallel_valid,
    input        [width - 1:0] parallel_data,

    output                     busy,
    output logic               serial_valid,
    output logic               serial_data
);
     

    // The module should accept 'width' bit input parallel data when 'parallel_valid' input is asserted.
    // At the same clock cycle as 'parallel_valid' is asserted, the module should output
    // the least significant bit of the input data. In the following clock cycles the module
    // should output all the remaining bits of the parallel_data.
    // Together with providing correct 'serial_data' value, module should also assert the 'serial_valid' output.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.


    // Тут задача обратная
    // Приходит один параллельный сигнал
    // Нужно преобразовать его в последовательный. 
    // Когда данные только пришли, busy = 0 
    // На следующем такте, если идёт преобразование, сигнал busy должен быть 1.

    // serial_valid должен быть 1, начиная с 1 бита 

    logic logic_busy;
    assign busy = logic_busy;


    // Счётчик для бита, который нужно вывести
    logic [$clog2(width)-1:0] cnt;

    logic [width-1:0] received_bits;


    always_ff @(posedge clk) begin
        if (rst) begin
            logic_busy   <= 1'b0;
            serial_valid <= 1'b0;
            serial_data  <= 1'b0;
            cnt          <= '0;
            received_bits <= '0;
        end else begin

            // Если busy активен - идёт преобразование сигнала в последовательный 
            if (logic_busy) begin
                

                // Выбор бит из поступившего сигнала
                serial_data <= received_bits[cnt];
                cnt         <= cnt + 1'b1;
                
                // Если мы сейчас отправляем ПОСЛЕДНИЙ бит (индекс width-1),
                // то в следующем такте надо выключиться.
                // (Внимание: cnt здесь еще старый, до +1)

                // Если идёт отправка последнего бита
                // то в следующем такте busy нужно выключить. 
                if (cnt == width - 1) begin
                    logic_busy   <= 1'b0;
                    // serial_valid <= 1'b0;
                end else begin
                    serial_valid <= 1'b1;
                end
                
                // Закомментировано другое решение
                // serial_data <= received_bits[0];
                // received_bits <= received_bits >> 1;
                // cnt          <= cnt - 1'b1;

                // if (cnt == 0) begin
                //     logic_busy   <= 1'b0;
                //     serial_valid <= 1'b0;
                // end else begin
                //     serial_valid <= 1'b1;
                // end

            // Если busy = 0 и пришёл сигнал отправки битов. 
            end else if (parallel_valid) begin
                
                // Установка сигналов
                logic_busy   <= 1'b1;
                serial_valid <= 1'b1;
                
                
                // Сохранение битов, которые нужно передать
                received_bits   <= parallel_data;
                serial_data <= parallel_data[cnt]; 

                // Это неправильно.
                // Присваивание parallel data в received bits
                // Проходит не сразу, а в конце такта
                // то есть тут будет мусор. Код будет работать неправильно. 
                //serial_data <= received_bits[cnt];
        
                // 3. Увеличиваем счетчик для следующего такта
                cnt <= cnt + 1'b1;

                // Отправка первого бита 
                //serial_data <= parallel_data[cnt];
                //cnt <= cnt + 1'b1; 

                // // Сразу выдаем бит 0
                // serial_data  <= parallel_data[0];
                // // Сохраняем остаток (биты с 1 по end)
                // received_bits    <= parallel_data >> 1;

                // serial_data  <= parallel_data[0];
                // received_bits    <= parallel_data >> 1;
                // cnt          <= width - 1; 
                
            end else begin
                serial_valid <= 1'b0;
                logic_busy   <= 1'b0;
            end
        end
    end

endmodule


