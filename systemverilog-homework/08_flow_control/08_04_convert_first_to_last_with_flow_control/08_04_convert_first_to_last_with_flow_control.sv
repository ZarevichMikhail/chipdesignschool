//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module convert_first_to_last_with_flow_control
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    output               up_ready,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    input                down_ready,
    output               down_last,
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // The module should respect and set correct valid and ready signals
    // to control flow from the upstream and to the downstream.


    // Ваш код здесь
    // Регистры для хранения предыдущего слова
    logic               buf_valid;
    logic [width - 1:0] buf_data;

    // ---------------------------------------------------------
    // Комбинаторная логика выходов
    // ---------------------------------------------------------
    
    // Мы можем выдать данные только если буфер полон И пришло следующее слово 
    // (чтобы мы могли заглянуть в его флаг up_first)
    assign down_valid = buf_valid && up_valid;
    
    // Выходные данные берутся из буфера (отстают на 1 такт)
    assign down_data  = buf_data;
    
    // Флаг конца пакета берется из признака начала СЛЕДУЮЩЕГО слова
    assign down_last  = up_first;
    
    // Мы готовы принимать данные, если буфер пуст ИЛИ downstream готов их забрать
    assign up_ready   = ~buf_valid || down_ready;

    // ---------------------------------------------------------
    // Синхронная логика (обновление состояния)
    // ---------------------------------------------------------
    always_ff @(posedge clock) begin
        if (reset) begin
            buf_valid <= 1'b0;
            buf_data  <= '0;
        end else begin
            // Если произошла успешная транзакция на входе
            if (up_valid && up_ready) begin
                buf_valid <= 1'b1;
                buf_data  <= up_data;
            end
            // Примечание: буфер никогда не сбрасывает buf_valid в 0, 
            // так как мы всегда держим последнее слово "в заложниках", 
            // ожидая следующее, чтобы узнать, было ли оно концом пакета.
        end
    end


endmodule
