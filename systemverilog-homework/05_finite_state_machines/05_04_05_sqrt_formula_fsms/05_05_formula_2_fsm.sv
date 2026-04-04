//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
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

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);
    // Task:
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    // Состояния конечного автомата
    typedef enum logic [2:0] {
        IDLE   = 3'd0,
        REQ_1  = 3'd1, // Запрос isqrt(c)
        WAIT_1 = 3'd2,
        REQ_2  = 3'd3, // Запрос isqrt(b + y1)
        WAIT_2 = 3'd4,
        REQ_3  = 3'd5, // Запрос isqrt(a + y2)
        WAIT_3 = 3'd6,
        DONE   = 3'd7
    } state_t;

    state_t state;

    // Регистры для сохранения входных данных
    logic [31:0] a_reg;
    logic [31:0] b_reg;
    
    // Универсальный регистр для хранения текущего аргумента для isqrt
    logic [31:0] x_reg; 

    // Логика переходов FSM и обновления данных
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            a_reg <= '0;
            b_reg <= '0;
            x_reg <= '0;
            res   <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        a_reg <= a;
                        b_reg <= b;
                        x_reg <= c; // Первый аргумент для isqrt — это c
                        state <= REQ_1;
                    end
                end
                
                REQ_1: begin
                    state <= WAIT_1;
                end
                
                WAIT_1: begin
                    if (isqrt_y_vld) begin
                        // Вычисляем аргумент для второго вызова: b + isqrt(c)
                        x_reg <= b_reg + {16'd0, isqrt_y};
                        state <= REQ_2;
                    end
                end
                
                REQ_2: begin
                    state <= WAIT_2;
                end
                
                WAIT_2: begin
                    if (isqrt_y_vld) begin
                        // Вычисляем аргумент для третьего вызова: a + isqrt(b + isqrt(c))
                        x_reg <= a_reg + {16'd0, isqrt_y};
                        state <= REQ_3;
                    end
                end
                
                REQ_3: begin
                    state <= WAIT_3;
                end
                
                WAIT_3: begin
                    if (isqrt_y_vld) begin
                        // Сохраняем финальный результат (дополняем нулями до 32 бит)
                        res   <= {16'd0, isqrt_y};
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

    // Комбинаторная логика управления интерфейсом isqrt
    // Импульс запроса поднимается только в состояниях REQ
    assign isqrt_x_vld = (state == REQ_1) || (state == REQ_2) || (state == REQ_3);
    
    // Данные для запроса всегда берутся из подготовленного x_reg
    assign isqrt_x     = x_reg;
    
    // Импульс готовности результата формулы
    assign res_vld     = (state == DONE);


endmodule
