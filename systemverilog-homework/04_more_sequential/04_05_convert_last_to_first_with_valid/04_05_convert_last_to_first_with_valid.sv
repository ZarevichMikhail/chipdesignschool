//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_last_to_first
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid, // 1 - В текущем такте получается сообщение. 
                                   // 0 - мусор 
    input                up_last,  // 1 - получается последний элемент. 
    input  [width - 1:0] up_data,  // Данные 

    output               down_valid, // 1 - Передаются данные
    output               down_first, // 1 - Передаётся первый элемент 
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'last' input status signal
    // to the 'first' output status signal.
    //
    // See README for full description of the task with timing diagram.

    // Вот, что объяснила нейросеть 
    // Такт up_data up_valid	up_last	down_first (Твой выход)
    // 1    10	     1	        0	        1   (Начало пакета)
    // 2	20	     1	        0	        0   (Середина пакета)
    // 3	30	     1	        1	        0   (Конец пакета)
    // 4	40	     1	        0	        1   (Начало нового пакета)


    // Передаются данные. Есть сигнал последнего элемента 
    // Если пришёл последний элемент, будет сигнал up_last
    // Следующий сигнал будет первым down_first

    // Будет ли следующий валидный такт "первым"
    logic is_next_first;
    assign down_first = is_next_first; 

    // Данные и их валидность переносятся на выходные сигналы
    assign down_valid = up_valid; 
    assign down_data  = up_data;  


    always_ff @(posedge clock) begin
        if (reset) begin
            // После сброса будет начало нового пакета
            is_next_first <= 1'b1;
        end
        
        else if (up_valid == 1) begin

            // Если текущий валидный элемент был последним, следующий будет первым.
            is_next_first <= up_last;
        end
    end

    

endmodule
