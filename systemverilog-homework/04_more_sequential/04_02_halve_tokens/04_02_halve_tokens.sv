//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens
(
    input  clk,
    input  rst,
    input  a,
    output b
);
    // Task:
    // Implement a serial module that reduces amount of incoming '1' tokens by half.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 110_011_101_000_1111
    // b -> 010_001_001_000_0101

    // Нужно ввести переменную флаг
    // По умолчанию её значение 0.


    // Принцип работы

    // flag = 0
    // a = 0 => b=0
    // a = 1 => b=0; 
    //          flag = 1 (flag = - flag)
    // a = 1 => b = flag можно и b = 1
    //          flag = 0 (flag = - flag)

    // Когда на вход приходит 0 Она ничего не делает. 
    // Когда на вход приходит 1, она записывает 0, если её состояние до этого было 0
    //                               или 1, если её состояние 1
    // и меняет своё состояние на противоположное. 


    // Моё решение. 

    logic flag;
    logic logic_b;

    assign b = logic_b;

    always_ff @ (posedge clk) begin
        
        if (rst) begin
            flag <= 1'b0;
        end

        else begin
            // Если на входе 0, то выводим его и ничего не делаем
            if (a == 0) begin
                logic_b <= a;
            end

            // На входе 1
            else begin
                
                // Если флаг = 0, записываем 0 и меняем значение флага на противоположное
                if (flag == 0) begin
                    logic_b <= 0;
                    flag <= ~ flag;
                end

                // Если флаг = 1, записываем 1 и меняем значение флага
                else begin
                    logic_b<=a;
                    flag <= ~ flag;
                end
                
            end

        end
    end



    // Решение через нейросеть 

    // Не понимаю, почему оно получилось в два раза короче моего.

    // Регистр для хранения состояния (триггер-переключатель)
    // state = 0: ждем нечетную единицу (1-ю, 3-ю...)
    // state = 1: ждем четную единицу (2-ю, 4-ю...)
    // logic state;

    // // Логика выхода (Mealy-type):
    // // Выдаем '1' только если на входе 'a' единица И мы уже видели нечетную единицу ранее
    // assign b = a & state;

    // always_ff @ (posedge clk) begin
    //     if (rst) begin
    //         // При сбросе начинаем считать заново с первой единицы
    //         state <= 1'b0;
    //     end else if (a) begin
    //         // Инвертируем состояние только тогда, когда пришел активный токен '1'
    //         state <= ~state;
    //     end
    //     // Если a == 0, состояние state сохраняется неизменным
    // end


endmodule
