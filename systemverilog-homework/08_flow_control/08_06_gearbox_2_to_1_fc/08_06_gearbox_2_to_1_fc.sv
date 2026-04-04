//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_2_to_1_fc
# (
    parameter width = 8
)
(
    input                    clk,
    input                    rst,

    input                    up_valid,
    output                   up_ready,
    input   [ 2*width - 1:0] up_data,

    output                   down_valid,
    input                    down_ready,
    output  [   width - 1:0] down_data
);

    // Task:
    // Implement a module that generates tokens from of one token.
    // Example:
    // "0110" => "01", "10"
    //
    // The module must use signals valid-ready for transfer tokens.


    // Определяем состояния конечного автомата
    typedef enum logic [1:0] {
        IDLE      = 2'd0, // Ожидание входных данных
        SEND_HIGH = 2'd1, // Отправка старшей половины слова
        SEND_LOW  = 2'd2  // Отправка младшей половины слова
    } state_t;

    state_t state, next_state;
    
    // Регистр для хранения принятого широкого слова
    logic [2*width-1:0] data_reg;


    logic up_ready_logic;
    assign up_ready = up_ready_logic;

    logic down_valid_logic;
    assign down_valid = down_valid_logic;

    logic [   width - 1:0] down_data_logic;
    assign down_data = down_data_logic;


    // Синхронная логика: обновление состояния и защелкивание данных
    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            data_reg <= '0;
        end else begin
            state <= next_state;
            
            // Запоминаем данные только в момент их успешного приема
            if (state == IDLE && up_valid) begin
                data_reg <= up_data;
            end
        end
    end

    // Комбинаторная логика: переходы состояний
    always_comb begin
        next_state = state; // По умолчанию остаемся в текущем состоянии

        case (state)
            IDLE: begin
                if (up_valid) begin
                    next_state = SEND_HIGH;
                end
            end
            
            SEND_HIGH: begin
                // Переходим к следующей половине только если получатель готов
                if (down_ready) begin
                    next_state = SEND_LOW;
                end
            end
            
            SEND_LOW: begin
                // Возвращаемся в ожидание новых данных, если получатель принял вторую половину
                if (down_ready) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Комбинаторная логика: управление выходными сигналами
    always_comb begin
        // Готовы принять данные только когда автомат свободен
        up_ready_logic   = (state == IDLE);
        
        // Данные на выходе валидны в состояниях отправки
        down_valid_logic = (state == SEND_HIGH || state == SEND_LOW);
        
        // Мультиплексор выходных данных
        if (state == SEND_HIGH) begin
            down_data_logic = data_reg[2*width-1 : width]; // Старшие биты
        end else if (state == SEND_LOW) begin
            down_data_logic = data_reg[width-1 : 0];       // Младшие биты
        end else begin
            down_data_logic = '0;
        end
    end



endmodule
