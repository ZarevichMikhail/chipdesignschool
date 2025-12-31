//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output logic                       busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.






    // Такое же задание было в ДЗ 3.7 
    // Нужно отсортировать 3 числа в порядке возрастания 
    // Нужно сначала сравнить 0 и 1
    // большее из них сравниваем с 2, получаем самое большое число. 

    // Затем меньшее число из второго сравнения сравниваем с первым,
    // чтобы получить самое маленькое. 

    // TODO:
    // Не знаю, как тут сделать более оптимизированный вариант. 
    // когда мы сравниваем число с 2, может быть так, что 2 - самое большое
    // и тогда снова придётся сравнивать 0 и 1. 
    // Надо добавить проверку на это. 


    // Реализация метода в задании 3.7
    // f_less_or_equal i_floe (
    //     .a   ( a                 ),
    //     .b   ( b                 ),
    //     .res ( a_less_or_equal_b ), // 1 если а<=b 
    //     .err ( err               )
    // );

    typedef enum logic [1:0] {
        INITIAL   = 2'b00,
        FIRST_COMPARISON  = 2'b01,  
        SECOND_COMPARISON = 2'b10, 
        THIRD_COMPARISON  = 2'b11   
    } state_e;

    state_e state;
    // Регистр для хранения сортируемых чисел
    logic [0:2][FLEN - 1:0] regs;
    logic comparison_error;

    // Комбинационная логика для интерфейса сравнения
    always_comb begin
        //f_le_a = '0;
        //f_le_b = '0;
        case (state)
            // Сравнение первого числа со вторым
            // Большее из них ставим на regs[1]
            FIRST_COMPARISON: begin 
                    f_le_a = regs[0]; 
                    f_le_b = regs[1]; 
            end
            // Сравнение наибольшего из них со третьим
            // Большее из них ставим на regs[2]
            // Меньшее на regs[1]
            SECOND_COMPARISON: begin 
                    f_le_a = regs[1]; 
                    f_le_b = regs[2]; 
            end
            // Сравнение наименьшего из второго сравнения с первым
            THIRD_COMPARISON: begin 
                    f_le_a = regs[0]; 
                    f_le_b = regs[1]; 
            end
        endcase
    end

    // Основная логика сравнения
    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= INITIAL;
            valid_out <= 1'b0;
            busy      <= 1'b0;
            err       <= 1'b0;
            comparison_error <= 1'b0;
        end else begin
            valid_out <= 1'b0; // Импульс на один такт

            case (state)
                INITIAL: begin
                    if (valid_in) begin
                        regs      <= unsorted; 
                        state     <= FIRST_COMPARISON;
                        busy      <= 1'b1;
                        err       <= 1'b0;
                        comparison_error <= 1'b0;
                    end
                end

                FIRST_COMPARISON: begin
                    
                    // Если f_le_res = 1, значит regs[0] <= regs[1] -> оставляем их как есть
                    // Если f_le_res = 0, значит regs[0] > regs[1]  -> меняем местами 
                    
                    if (f_le_res == 0) begin
                        // regs[0] <= regs[1];
                        // regs[1] <= regs[0];
                        {regs[0], regs[1]} = {regs[1], regs[0]};
                    end
                    comparison_error <= f_le_err; 
                    state <= SECOND_COMPARISON;
                end

                SECOND_COMPARISON: begin
                    // Если f_le_res == 0, значит regs[1] > regs[2] -> меняем местами 
                    if (f_le_res == 0) begin
                        // regs[1] <= regs[2];
                        // regs[2] <= regs[1];
                        {regs[1], regs[2]} = {regs[2], regs[1]};
                    end
                    comparison_error <= comparison_error | f_le_err;
                    state     <= THIRD_COMPARISON;
                end

                THIRD_COMPARISON: begin

                    if (f_le_res == 0) begin
                        // sorted[0] <= regs[1];
                        // sorted[1] <= regs[0];
                        {regs[0], regs[1]} = {regs[1], regs[0]};
                    end 
                    // else begin
                    //     sorted[0] <= regs[0];
                    //     sorted[1] <= regs[1];
                    // end
                    //sorted[2] <= regs[2];
                    sorted = regs;
                    
                    err       <= comparison_error | f_le_err;
                    valid_out <= 1'b1; 
                    busy      <= 1'b0;
                    state     <= INITIAL;
                end
            endcase
        end
    end


endmodule
