//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens
(
    input        clk,
    input        rst,
    input        a,
    output       b,
    output logic overflow
);
    // Task:
    // Implement a serial module that doubles each incoming token '1' two times.
    // The module should handle doubling for at least 200 tokens '1' arriving in a row.
    //
    // In case module detects more than 200 sequential tokens '1', it should assert
    // an overflow error. The overflow error should be sticky. Once the error is on,
    // the only way to clear it is by using the "rst" reset signal.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 10010011000110100001100100
    // b -> 11011011110111111001111110

    
    // Нужно ввести счётчик поступивших единиц
    // Если на вход поступает 1, 
    //     выводим 1 и добавляём 1 к счётчику
    // Если на входе 0 и на счётчике 0
    //     выводим 0
    // Если на входе 0 и на счётчике больше 0
    //     выводим 1 и уменьшаем счётчик на 1

    //




    // Счётчик для единиц 
    logic [7:0] count;
    logic logic_b;

    assign b = logic_b;

    always_ff @ (posedge clk) begin
       
        if (rst) begin
            count    <= '0;
            overflow <= 1'b0;
            logic_b  <= 1'b0;
        end

        else begin
            // если счётчик имеет максимально допустимое значение
            if (count >= 8'd200) begin
                overflow <= 1'b1;
            end         
            // Если на входе 0 и счётчик равен 0 то выводим 0
            if (a == 0 & count == 1'b0) begin
                logic_b <= a;
            end

            // Если на входе 0, но нам ещё нужно записывать единицы
            else if (a == 0 & count != 1'b0) begin
                logic_b <= 1;
                count <= count - 1'b1;
            end

            // На входе 1
            else begin
                logic_b<=1;
                count <= count + 1'b1;

                // Это нужно, чтобы счётчик не переполнялся. 
                if (count < 8'hFF) 
                    count <= count + 1'b1;
            end

            

        end
    end


    // Решение через нейросеть. 



    // Счетчик "отложенных" единиц. 
    // Нам нужно хранить до 200 единиц очереди.
    // logic [7:0] count;

    // // Выход b активен, если сейчас на входе единица (мы её удваиваем)
    // // ИЛИ если у нас в счетчике еще остались "отложенные" единицы.
    // assign b = a | (count > 0);

    // always_ff @ (posedge clk) begin
    //     if (rst) begin
    //         count    <= '0;
    //         overflow <= 1'b0;
    //     end else begin
    //         // Логика переполнения (sticky overflow)
    //         // Если счетчик уже 200 и приходит новая единица - это переполнение
    //         if (a && count == 8'd200) begin
    //             overflow <= 1'b1;
    //         end

    //         // Управление счетчиком:
    //         if (a) begin
    //             // Если пришла 1, и мы еще не достигли предела 200:
    //             // Мы выдаем одну '1' сразу (через assign b = a | ...)
    //             // и одну запоминаем (count + 1)
    //             if (count < 8'd200)
    //                 count <= count + 1'b1;
    //         end 
    //         else if (count > 0) begin
    //             // Если на входе 0, но у нас есть "долг", отдаем одну единицу
    //             count <= count - 1'b1;
    //         end
    //     end
    // end


endmodule
