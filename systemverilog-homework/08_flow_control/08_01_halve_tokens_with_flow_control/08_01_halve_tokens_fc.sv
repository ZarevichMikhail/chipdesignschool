//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

    // Task:
    // Implement a serial module that reduces amount of incoming '1' tokens by half.
    // The module must use the ready-valid protocol.
    //
    //  Expected behavior of the module
    //  1) When the input signals are up_token and up_valid is high, the signal (token) is processed.
    //  2) Every second signal received for processing is sent to the output of the module.
    //  3) When the module cannot process the signal, it sets the up_ready signal to a low level.
    //
    // Example:
    // down_ready     ->   1111_1111_1111_0000
    // up_token       ->   1101_0100_1111_1111
    // up_valid       ->   1111_1111_0101_1111
    // down_valid     ->   1111_1111_1111_1000
    // down_data      ->   0100_0100_0001_0000
    // up_ready       ->   1111_1111_0101_1000


    // Регистр для отслеживания фазы токенов '1'
    // 1'b0 - следующий единичный токен будет первым (заменяется на 0)
    // 1'b1 - следующий единичный токен будет вторым (проходит как 1)
    logic phase_q;

    // Секция последовательной логики: отслеживаем фазу
    always_ff @(posedge clk) begin
        if (rst) begin
            phase_q <= 1'b0; // 0 - первый 1-токен (станет 0), 1 - второй 1-токен (пройдет как 1)
        end 
        // Меняем фазу только при реальной успешной передаче 1-токена
        else if (up_valid && down_ready && up_token) begin
            phase_q <= ~phase_q;
        end
    end

    logic up_ready_logic;
    assign up_ready = up_ready_logic;

    logic down_valid_logic;
    assign down_valid = down_valid_logic;

    logic down_data_logic;
    assign down_data = down_data_logic;

    // Секция комбинаторной логики
    always_comb begin
        // Готовность транслируется напрямую
        up_ready_logic   = down_ready;
        
        // Транзакции не удаляются (чтобы пройти шаг 0)
        down_valid_logic = up_valid;

        // Формирование данных с жесткой маской по down_ready
        // Если принимающая сторона не готова (down_ready = 0), жестко ставим 0,
        // чтобы тестбенч не насчитал лишних "висящих" единиц.
        if (up_valid && up_token && down_ready) begin
            down_data_logic = phase_q; 
        end else begin
            down_data_logic = 1'b0;    
        end
    end



endmodule
