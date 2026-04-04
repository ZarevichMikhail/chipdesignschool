//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2_fc
# (
    parameter width = 8
)
(
    input                   clk,
    input                   rst,
    input                   up_valid,
    output                  up_ready,
    input  [   width - 1:0] up_data,
    output                  down_valid,
    output [ 2*width - 1:0] down_data,
    input                   down_ready
);

    // Task:
    // Implement a module that generates one token from of two tokens.
    // Example:
    // "01", "10" => "0110"
    //
    // The module must use signals valid-ready for transfer tokens.


     // Ваш код здесь
    // Внутренние регистры состояний
    logic               has_first_word; // 1 - сохранили первое слово, ждем второе
    logic               full;           // 1 - пара собрана и готова к выдаче
    logic [width-1:0]   first_word;     // Буфер для первого слова


    logic [ 2*width - 1:0] down_data_logic;
    assign down_data = down_data_logic;


    // Логика интерфейсов
    assign down_valid = full;
    
    // Мы готовы принимать новые данные, если выходной буфер не полон 
    // ИЛИ если он полон, но данные забираются прямо в этом такте
    assign up_ready   = ~full | down_ready;

    // Вспомогательные сигналы успешной передачи (рукопожатия)
    wire up_fire   = up_valid && up_ready;
    wire down_fire = down_valid && down_ready;

    always_ff @(posedge clk) begin
        if (rst) begin
            has_first_word <= 1'b0;
            full           <= 1'b0;
            first_word     <= '0;
            down_data_logic      <= '0;
        end else begin
            case ({down_fire, up_fire})
                2'b00: begin
                    // Никто не передает и не принимает - ничего не делаем
                end
                
                2'b10: begin
                    // Данные забрали с выхода, новых на входе нет
                    full <= 1'b0;
                end
                
                2'b01: begin
                    // Принимаем новые данные, выход пока стоит
                    if (!has_first_word) begin
                        // Пришло первое слово
                        first_word     <= up_data;
                        has_first_word <= 1'b1;
                    end else begin
                        // Пришло второе слово - собираем пару
                        down_data_logic      <= {first_word, up_data};
                        has_first_word <= 1'b0;
                        full           <= 1'b1;
                    end
                end
                
                2'b11: begin
                    // Одновременный прием и передача (Pipeline)
                    // Старые данные уходят, значит full снимается, 
                    // и мы принимаем ПЕРВОЕ слово следующей пары.
                    first_word     <= up_data;
                    has_first_word <= 1'b1;
                    full           <= 1'b0;
                end
            endcase
        end
    end



endmodule
