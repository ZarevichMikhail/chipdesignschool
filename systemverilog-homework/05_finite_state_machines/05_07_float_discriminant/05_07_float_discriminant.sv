//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

// Константа 4.0 в формате IEEE-754 FP64 (Знак: 0, Экспонента: 1025, Мантисса: 0)
    localparam [FLEN-1:0] FP64_4_0 = 64'h4010000000000000;

    // Состояния конечного автомата (FSM)
    typedef enum logic [3:0] {
        IDLE          = 4'd0,
        CALC_B2_REQ   = 4'd1,
        CALC_B2_WAIT  = 4'd2,
        CALC_4A_REQ   = 4'd3,
        CALC_4A_WAIT  = 4'd4,
        CALC_4AC_REQ  = 4'd5,
        CALC_4AC_WAIT = 4'd6,
        CALC_SUB_REQ  = 4'd7,
        CALC_SUB_WAIT = 4'd8,
        DONE          = 4'd9
    } state_t;

    state_t state;

    // Внутренние регистры для хранения промежуточных данных
    logic [FLEN-1:0] a_reg, b_reg, c_reg;
    logic [FLEN-1:0] b2_res, ac4_res;
    logic [FLEN-1:0] final_res;
    logic            err_reg;

    // Проверка входных данных на NaN или Inf (все единицы в битах экспоненты 62:52)
    wire a_is_nan_inf = (&a[62:52]);
    wire b_is_nan_inf = (&b[62:52]);
    wire c_is_nan_inf = (&c[62:52]);
    wire input_err    = a_is_nan_inf | b_is_nan_inf | c_is_nan_inf;

    // Инстанцирование умножителя
    logic [FLEN-1:0] mult_a, mult_b;
    logic            mult_up_valid;
    wire  [FLEN-1:0] mult_res;
    wire             mult_down_valid, mult_busy, mult_error;

    f_mult u_mult (
        .clk        (clk),
        .rst        (rst),
        .a          (mult_a),
        .b          (mult_b),
        .up_valid   (mult_up_valid),
        .res        (mult_res),
        .down_valid (mult_down_valid),
        .busy       (mult_busy),
        .error      (mult_error)
    );

    // Инстанцирование вычитателя
    logic [FLEN-1:0] sub_a, sub_b;
    logic            sub_up_valid;
    wire  [FLEN-1:0] sub_res;
    wire             sub_down_valid, sub_busy, sub_error;

    f_sub u_sub (
        .clk        (clk),
        .rst        (rst),
        .a          (sub_a),
        .b          (sub_b),
        .up_valid   (sub_up_valid),
        .res        (sub_res),
        .down_valid (sub_down_valid),
        .busy       (sub_busy),
        .error      (sub_error)
    );

    // Логика переходов FSM
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            err_reg   <= 1'b0;
            a_reg     <= '0;
            b_reg     <= '0;
            c_reg     <= '0;
            b2_res    <= '0;
            ac4_res   <= '0;
            final_res <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        if (input_err) begin
                            err_reg <= 1'b1;
                            state   <= DONE;
                        end else begin
                            a_reg   <= a;
                            b_reg   <= b;
                            c_reg   <= c;
                            err_reg <= 1'b0;
                            state   <= CALC_B2_REQ;
                        end
                    end
                end

                CALC_B2_REQ: state <= CALC_B2_WAIT; // Импульс up_valid подан

                CALC_B2_WAIT: begin
                    if (mult_down_valid) begin
                        b2_res <= mult_res; // Сохраняем b^2
                        state  <= CALC_4A_REQ;
                    end
                end

                CALC_4A_REQ: state <= CALC_4A_WAIT;

                CALC_4A_WAIT: begin
                    if (mult_down_valid) begin
                        ac4_res <= mult_res; // Временно сохраняем 4*a
                        state   <= CALC_4AC_REQ;
                    end
                end

                CALC_4AC_REQ: state <= CALC_4AC_WAIT;

                CALC_4AC_WAIT: begin
                    if (mult_down_valid) begin
                        ac4_res <= mult_res; // Перезаписываем на (4*a)*c
                        state   <= CALC_SUB_REQ;
                    end
                end

                CALC_SUB_REQ: state <= CALC_SUB_WAIT;

                CALC_SUB_WAIT: begin
                    if (sub_down_valid) begin
                        final_res <= sub_res; // Сохраняем итоговый D
                        state     <= DONE;
                    end
                end

                DONE: begin
                    if (arg_vld) begin
                        // Обработка сразу следующего входного сигнала без простоя
                        if (input_err) begin
                            err_reg <= 1'b1;
                            state   <= DONE;
                        end else begin
                            a_reg   <= a;
                            b_reg   <= b;
                            c_reg   <= c;
                            err_reg <= 1'b0;
                            state   <= CALC_B2_REQ;
                        end
                    end else begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Комбинаторная логика управления входами подчиненных модулей
    always_comb begin
        mult_up_valid = 1'b0;
        mult_a        = '0;
        mult_b        = '0;
        sub_up_valid  = 1'b0;
        sub_a         = '0;
        sub_b         = '0;

        case (state)
            CALC_B2_REQ, CALC_B2_WAIT: begin
                mult_up_valid = (state == CALC_B2_REQ); // Строгий импульс на 1 такт
                mult_a        = b_reg;
                mult_b        = b_reg;
            end
            CALC_4A_REQ, CALC_4A_WAIT: begin
                mult_up_valid = (state == CALC_4A_REQ);
                mult_a        = FP64_4_0;
                mult_b        = a_reg;
            end
            CALC_4AC_REQ, CALC_4AC_WAIT: begin
                mult_up_valid = (state == CALC_4AC_REQ);
                mult_a        = ac4_res;
                mult_b        = c_reg;
            end
            CALC_SUB_REQ, CALC_SUB_WAIT: begin
                sub_up_valid  = (state == CALC_SUB_REQ);
                sub_a         = b2_res;
                sub_b         = ac4_res;
            end
            default: ;
        endcase
    end

    // Формирование выходных сигналов
    assign res_vld = (state == DONE);
    assign err     = err_reg;
    assign busy    = (state != IDLE);

    // Удаляем знаковый бит (бит 63) для получения модуля значения.
    assign res = final_res;
    
    
    // Результат отрицательный, если бит 63 равен '1' и мантисса с экспонентой не равны нулю (отсекаем -0.0)
    assign res_negative = final_res[FLEN-1] && (final_res[FLEN-2:0] != '0);
endmodule


