//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);
    // Task:
    //
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


     // =========================================================
    // СТАДИЯ 1: Вычисляем isqrt(c), задерживаем 'a' и 'b'
    // =========================================================
    wire        vld_c;
    wire [15:0] res_c;

    isqrt i_isqrt_c (
        .clk   (clk),
        .rst   (rst),
        .x_vld (arg_vld),
        .x     (c),
        .y_vld (vld_c),
        .y     (res_c)
    );

    wire [31:0] a_stg1;
    wire [31:0] b_stg1;

    // Очередь для задержки аргумента 'a' на время вычисления isqrt(c)
    flip_flop_fifo_with_counter #(
        .width (32),
        .depth (32)
    ) i_fifo_a_stg1 (
        .clk        (clk),
        .rst        (rst),
        .push       (arg_vld),
        .write_data (a),
        .pop        (vld_c), // Достаем, когда готов корень из c
        .read_data  (a_stg1),
        .empty      (),
        .full       ()
    );

    // Очередь для задержки аргумента 'b' на время вычисления isqrt(c)
    flip_flop_fifo_with_counter #(
        .width (32),
        .depth (32)
    ) i_fifo_b_stg1 (
        .clk        (clk),
        .rst        (rst),
        .push       (arg_vld),
        .write_data (b),
        .pop        (vld_c), // Достаем, когда готов корень из c
        .read_data  (b_stg1),
        .empty      (),
        .full       ()
    );

    // =========================================================
    // СТАДИЯ 2: Вычисляем isqrt(b + res_c), задерживаем 'a' еще раз
    // =========================================================
    wire [31:0] sum_b_c = b_stg1 + 32'(res_c);
    
    wire        vld_b;
    wire [15:0] res_b;

    isqrt i_isqrt_b (
        .clk   (clk),
        .rst   (rst),
        .x_vld (vld_c), // Запускаем, когда пришел vld от первой стадии
        .x     (sum_b_c),
        .y_vld (vld_b),
        .y     (res_b)
    );

    wire [31:0] a_stg2;

    // Перекладываем 'a' во вторую очередь, чтобы подождать вычисления isqrt(b + ...)
    flip_flop_fifo_with_counter #(
        .width (32),
        .depth (32)
    ) i_fifo_a_stg2 (
        .clk        (clk),
        .rst        (rst),
        .push       (vld_c), // Записываем в момент готовности первой стадии
        .write_data (a_stg1),
        .pop        (vld_b), // Достаем, когда готов корень из суммы с b
        .read_data  (a_stg2),
        .empty      (),
        .full       ()
    );

    // =========================================================
    // СТАДИЯ 3: Вычисляем финальный isqrt(a + res_b)
    // =========================================================
    wire [31:0] sum_a_b = a_stg2 + 32'(res_b);
    
    wire        vld_a;
    wire [15:0] res_a;

    isqrt i_isqrt_a (
        .clk   (clk),
        .rst   (rst),
        .x_vld (vld_b), // Запускаем от сигнала второй стадии
        .x     (sum_a_b),
        .y_vld (vld_a),
        .y     (res_a)
    );

    // Выдаем финальный результат
    assign res_vld = vld_a;
    assign res     = 32'(res_a);


endmodule
