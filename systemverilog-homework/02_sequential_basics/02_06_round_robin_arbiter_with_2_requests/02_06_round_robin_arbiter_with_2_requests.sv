//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests, // Запросы на доступ
    output [1:0] grants    
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:    1  2  3  4  5  6  7  8  9  10
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01



    // Суть задания.
    // Есть устройство, которым одновременно может пользоваться только один пользователь,
    // но таких пользователей двое.
    // Если одновременно подаёт запрос только один - предоставляется доступ. 
    //     Это показано в примерах 1-3
    // Если одновременно подают запрос двое - доступ получает первый. 
    //     Регистр записывает, что в следующем конфликте должен получить доступ второй.
    //     Потом снова первый и т.д.
    //     Это показано в примерах 4,5. 7,9,10



    // Нужно сделать один блок always_comb, который будет выдавать гранты.
    // И один блок always_ff, который будет запоминать предыдущее состояние
    // и менять приоритеты каждый раз, когда на вход поступает 11.

    // Выходная переменная указана как wire. Т.е. мы не можем её менять в блоке 
    // always_comb
    // Я реши ввести другую logic переменную и записывать в неё. 
    logic [1:0] grants_logic;
    assign grants = grants_logic;

    // Этот регистр хранит приоритет.
    // 0: Приоритет у запроса [0]
    // 1: Приоритет у запроса [1]
    logic priority_signal;

    // 
    always_comb begin
        //grants = 2'b00; 
        grants_logic = 2'b00;

        case (requests)
            2'b00: grants_logic = 2'b00; // 
            2'b01: grants_logic = 2'b01; // 
            2'b10: grants_logic = 2'b10; // 
            2'b11: begin
                // Когда два запроса, нужно дать доступ тому, у кого есть grant
                if (priority_signal)
                    grants_logic = 2'b10; // priority_signal = 1, доступ у второго пользователя
                else
                    grants_logic = 2'b01; // priority_signal = 0, доступ у первого пользователя
            end
        endcase
    end

    // Логика обновления приоритетов
    always_ff @(posedge clk) begin

        // Если грант у первого пользователя.
        // Следующий приоритет будет у второго
        if (grants[0]) begin
            
            priority_signal <= 1'b1;

        // Если грант у второго пользователя.
        // Следующий приоритет будет у первого    
        end else if (grants[1]) begin
            priority_signal <= 1'b0;
        end

        
    end













endmodule
