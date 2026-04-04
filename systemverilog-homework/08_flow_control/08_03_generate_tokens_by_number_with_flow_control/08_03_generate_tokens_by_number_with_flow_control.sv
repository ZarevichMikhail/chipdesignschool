//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module generate_tokens_by_number_with_flow_control
#(
    WIDTH = 4
)
(
    input                 clk,
    input                 rst,

    input                 up_valid,
    output                up_ready,
    input  [WIDTH-1 : 0]  n_tokens,

    output                down_valid,
    input                 down_ready,
    output                down_token
);

    // Task:
    // Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
    // transfer tokens.

    // Ваш код здесь
    // Внутренние регистры
    logic active;
    logic [WIDTH-1:0] count;

    // Комбинаторная логика для выходных сигналов
    // Мы готовы принимать новые данные, когда не находимся в процессе генерации
    assign up_ready = ~active;
    
    // Выходные данные валидны, когда модуль в активном состоянии генерации
    assign down_valid = active;
    
    // По условию задачи, при генерации всегда выдается 1. 
    // Вне генерации привязываем к 0.
    assign down_token = active; 

    // Последовательностная логика управления состояниями и счетчиком
    always_ff @(posedge clk) begin
        if (rst) begin
            active <= 1'b0;
            count  <= '0;
        end else begin
            if (!active) begin
                // Состояние IDLE (Ожидание ввода)
                if (up_valid && up_ready) begin
                    if (n_tokens > 0) begin
                        active <= 1'b1;      // Переходим в режим генерации
                        count  <= n_tokens;  // Запоминаем количество токенов
                    end
                    // Если n_tokens == 0, handshake проходит, но active остается 0, 
                    // поэтому ни одного импульса не генерируется
                end
            end else begin
                // Состояние ACTIVE (Генерация токенов)
                if (down_valid && down_ready) begin
                    if (count > 1) begin
                        count <= count - 1'b1; // Уменьшаем счетчик
                    end else begin
                        active <= 1'b0;        // Это был последний токен, возвращаемся в IDLE
                    end
                end
            end
        end
    end
    

endmodule
