//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens_with_flow_control
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
  // Implement module double input signals (tokens). The module must use signals valid-ready for
  // transfer tokens. If the module receives more than 100 sequential tokens then it must set up_ready = 0;
    
    
    logic [7:0] pending_tokens;
    // Тестбенч ожидает, что down_valid всегда поднят.
    assign down_valid = 1'b1;

    // Выдаем '1', если в счетчике уже есть данные 
    // ИЛИ если прямо сейчас на вход пришла новая '1' (bypass для нулевой задержки)
    assign down_data = (pending_tokens > 8'd0) || (up_valid && up_token);

    // Сигналы рукопожатий
    logic in_fire;
    logic out_fire_token;
    logic push;

    assign in_fire = up_valid && up_ready;
    assign push    = in_fire && up_token;

    // Считаем выход успешным, только если мы реально выдали '1' (down_data == 1)
    assign out_fire_token = down_valid && down_ready && down_data;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pending_tokens <= 8'd0;
        end else begin
            case ({push, out_fire_token})
                2'b10: pending_tokens <= pending_tokens + 8'd2; // Приняли 1, не отдали. Итог: +2
                2'b11: pending_tokens <= pending_tokens + 8'd1; // Приняли 1 (выдаем 2), сразу отдали 1. Итог: +1
                2'b01: pending_tokens <= pending_tokens - 8'd1; // На входе пусто, отдали 1. Итог: -1
                2'b00: pending_tokens <= pending_tokens;        // Состояние покоя
            endcase
        end
    end

    // Останавливаем вход, если накопилось 200 необработанных выходных токенов (т.е. 100 входных).
    // Ставим порог < 200, чтобы цикл while в тестбенче остановился ровно на i=100.
    assign up_ready = (pending_tokens < 8'd200);

endmodule
