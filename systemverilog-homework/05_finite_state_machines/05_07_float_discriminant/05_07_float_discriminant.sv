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


    // В этом задании у меня возникла проблема с тем, что знаки +, -, * возвращают целочисленное число, 
    // а не число с плавающей точкой IEEE-754.
    // Поэтому у меня возникала ошибка 
    // 05_07_float_discriminant/testbench.sv: res mismatch. Expected res_expected:4, actual res:-nan 
    // Чтобы её исправить нужно считать в вещественных числах
    // Функции $bitstoreal() и $realtobits() переводят биты в вещественные чиисла
    

    // Состояния автомата 
    typedef enum logic [1:0] {
        INITIAL   = 2'b00,
        COMPUTING = 2'b01,
        DONE      = 2'b10
    } state_e;

    state_e state;
    real r_a, r_b, r_c, r_res;

    // Функция для проверки на NaN или Inf (все биты экспоненты равны 1) 
    // function logic is_special(logic [63:0] f);
    //     // Для FP64 экспонента — это биты [62:52] (11 бит) [cite: 81, 127]
    //     return (&f[62:52]); 
    // endfunction
    
    // Функция из тестбенча
    function is_err ( [FLEN - 1:0] a_bits );
        return a_bits [FLEN - 2 -: NE] === '1;
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            state        <= INITIAL;
            busy         <= 1'b0;
            res_vld      <= 1'b0;
            err          <= 1'b0;
            res          <= '0;
            res_negative <= 1'b0;
        end else begin
            res_vld <= 1'b0;

            case (state)
                INITIAL: begin
                    if (arg_vld) begin
                        busy  <= 1'b1;
                        
                        state <= COMPUTING;
                    end
                end

                COMPUTING: begin
                    // Проверка на NaN и Inf 
                    err <= is_err(a) | is_err(b) | is_err(c);
                    if (err == 1)
                        state<=DONE;
                    
                    // Перевод битов в вещественные числа 
                    r_a = $bitstoreal(a);
                    r_b = $bitstoreal(b);
                    r_c = $bitstoreal(c);
                    
                    // Формула дискриминанта b^2 - 4ac 
                    // res <= (b * b) - (4 * a * c);
                    r_res = (r_b * r_b) - (4.0 * r_a * r_c);

                    // Преобразование результата в биты 
                    res <= $realtobits(r_res);
                    state <= DONE;
                end

                DONE: begin
                    // res_negative определяется по знаковому биту результата (бит 63)
                    res_negative <= res[FLEN-1];
                    res_vld      <= 1'b1;
                    busy         <= 1'b0;
                    state        <= INITIAL;
                end
            endcase
        end
    end

endmodule


