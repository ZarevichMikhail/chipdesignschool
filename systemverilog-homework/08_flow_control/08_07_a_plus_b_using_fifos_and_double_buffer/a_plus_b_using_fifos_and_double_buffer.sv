module a_plus_b_using_fifos_and_double_buffer
# (
    parameter width = 8, depth = 10
)
(
    input                clk,
    input                rst,

    input                a_valid,
    output               a_ready,
    input  [width - 1:0] a_data,

    input                b_valid,
    output               b_ready,
    input  [width - 1:0] b_data,

    output               sum_valid,
    input                sum_ready,
    output [width - 1:0] sum_data
);

    //------------------------------------------------------------------------

    wire               a_fifo_push;
    wire               a_fifo_pop;
    wire [width - 1:0] a_fifo_write_data;
    wire [width - 1:0] a_fifo_read_data;
    wire               a_fifo_empty;
    wire               a_fifo_full;

    flip_flop_fifo_with_counter
    # (.width (width), .depth (depth))
    fifo_a
    (
        .clk         ( clk               ),
        .rst         ( rst               ),
        .push        ( a_fifo_push       ),
        .pop         ( a_fifo_pop        ),
        .write_data  ( a_fifo_write_data ),
        .read_data   ( a_fifo_read_data  ),
        .empty       ( a_fifo_empty      ),
        .full        ( a_fifo_full       )
    );

    // Task: Add logic using the template below
    //
    // Логика записи во входной буфер A
    assign a_ready           = ~a_fifo_full;          // Готовы принять, если FIFO не полон
    assign a_fifo_push       = a_valid & a_ready;     // Пушим, если есть данные и мы готовы
    assign a_fifo_write_data = a_data;


    //------------------------------------------------------------------------

    wire               b_fifo_push;
    wire               b_fifo_pop;
    wire [width - 1:0] b_fifo_write_data;
    wire [width - 1:0] b_fifo_read_data;
    wire               b_fifo_empty;
    wire               b_fifo_full;

    flip_flop_fifo_with_counter
    # (.width (width), .depth (depth))
    fifo_b
    (
        .clk         ( clk               ),
        .rst         ( rst               ),
        .push        ( b_fifo_push       ),
        .pop         ( b_fifo_pop        ),
        .write_data  ( b_fifo_write_data ),
        .read_data   ( b_fifo_read_data  ),
        .empty       ( b_fifo_empty      ),
        .full        ( b_fifo_full       )
    );

    // Task: Add logic using the template below
    //
    // Логика записи во входной буфер B
    assign b_ready           = ~b_fifo_full;          // Готовы принять, если FIFO не полон
    assign b_fifo_push       = b_valid & b_ready;     // Пушим, если есть данные и мы готовы
    assign b_fifo_write_data = b_data;


    //------------------------------------------------------------------------

    // Task: Add logic using the template below
    //
    wire               sum_up_valid;
    wire               sum_up_ready;
    wire [width - 1:0] sum_up_data;

    // Комбинационная логика сложения и управления потоком
    // Данные валидны для сложения только если ОБА входных FIFO не пусты
    assign sum_up_valid = ~a_fifo_empty & ~b_fifo_empty;
    
    // Сумма текущих значений на выходах FIFO
    assign sum_up_data  = a_fifo_read_data + b_fifo_read_data;

    // Читаем (выталкиваем) данные из обоих FIFO только если:
    // 1. У нас есть валидная пара для суммы (sum_up_valid)
    // 2. Выходной буфер готов принять эту сумму (sum_up_ready)
    assign a_fifo_pop   = sum_up_valid & sum_up_ready;
    assign b_fifo_pop   = sum_up_valid & sum_up_ready;


    //------------------------------------------------------------------------

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_sum
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( sum_up_valid ),
        .up_ready    ( sum_up_ready ),
        .up_data     ( sum_up_data  ),

        .down_valid  ( sum_valid    ),
        .down_ready  ( sum_ready    ),
        .down_data   ( sum_data     )
    );

endmodule
