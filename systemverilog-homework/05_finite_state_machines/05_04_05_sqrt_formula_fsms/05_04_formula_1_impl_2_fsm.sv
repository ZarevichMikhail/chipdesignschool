//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the formula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    // Состояния конечного автомата
    typedef enum logic [2:0] {
        IDLE,       // Ожидание новых аргументов
        REQ_AB,     // Отправка запросов a и b
        WAIT_AB,    // Ожидание результатов a (и, возможно, b)
        REQ_C,      // Отправка запроса c на первый освободившийся модуль (isqrt_1)
        WAIT_C,     // Ожидание результатов c (и, возможно, b)
        DONE        // Готовность результатов
    } state_t;

    state_t state;

    // Регистры для сохранения входных данных и промежуточных результатов
    logic [31:0] a_reg, b_reg, c_reg;
    logic [15:0] res_a, res_b, res_c;
    logic        a_done, b_done, c_done;

    // Логика переходов FSM и сохранения данных
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state  <= IDLE;
            a_done <= 1'b0;
            b_done <= 1'b0;
            c_done <= 1'b0;
            a_reg  <= 32'd0;
            b_reg  <= 32'd0;
            c_reg  <= 32'd0;
            res_a  <= 16'd0;
            res_b  <= 16'd0;
            res_c  <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        a_reg  <= a;
                        b_reg  <= b;
                        c_reg  <= c;
                        a_done <= 1'b0;
                        b_done <= 1'b0;
                        c_done <= 1'b0;
                        state  <= REQ_AB;
                    end
                end

                REQ_AB: begin
                    state <= WAIT_AB;
                end

                WAIT_AB: begin
                    // Независимое отслеживание isqrt_2 (аргумент b)
                    if (isqrt_2_y_vld) begin
                        res_b  <= isqrt_2_y;
                        b_done <= 1'b1;
                    end
                    
                    // Как только isqrt_1 закончил (аргумент a), сразу переходим к запросу c
                    if (isqrt_1_y_vld) begin
                        res_a  <= isqrt_1_y;
                        a_done <= 1'b1;
                        state  <= REQ_C;
                    end
                end

                REQ_C: begin
                    // Продолжаем отслеживать b, если он еще не готов
                    if (isqrt_2_y_vld) begin
                        res_b  <= isqrt_2_y;
                        b_done <= 1'b1;
                    end
                    state <= WAIT_C;
                end

                WAIT_C: begin
                    // Продолжаем отслеживать b
                    if (isqrt_2_y_vld) begin
                        res_b  <= isqrt_2_y;
                        b_done <= 1'b1;
                    end
                    
                    // Отслеживаем результат c
                    if (isqrt_1_y_vld) begin
                        res_c  <= isqrt_1_y;
                        c_done <= 1'b1;
                    end

                    // Если b и c готовы в этом или предыдущих тактах — переходим в DONE
                    if ((isqrt_1_y_vld || c_done) && (isqrt_2_y_vld || b_done)) begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Комбинаторная логика управления интерфейсами запросов к isqrt
    always_comb begin
        isqrt_1_x_vld = 1'b0;
        isqrt_1_x     = 32'd0;
        isqrt_2_x_vld = 1'b0;
        isqrt_2_x     = 32'd0;

        if (state == REQ_AB) begin
            isqrt_1_x_vld = 1'b1;
            isqrt_1_x     = a_reg;
            
            isqrt_2_x_vld = 1'b1;
            isqrt_2_x     = b_reg;
        end else if (state == REQ_C) begin
            isqrt_1_x_vld = 1'b1;
            isqrt_1_x     = c_reg;
        end
    end

    // Формирование итогового результата
    assign res_vld = (state == DONE);
    // Дополняем нулями до 32 бит, чтобы предотвратить потерю переполнения 
    // при сложении трех 16-битных чисел.
    assign res     = {16'd0, res_a} + {16'd0, res_b} + {16'd0, res_c};


endmodule
