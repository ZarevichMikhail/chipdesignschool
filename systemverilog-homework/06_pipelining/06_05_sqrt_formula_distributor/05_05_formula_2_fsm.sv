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
    //
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


    typedef enum logic [3:0] {
        IDLE,
        SEND_C,
        WAIT_C,
        SEND_B,
        WAIT_B,
        SEND_A,
        WAIT_A,
        OUTPUT
    } state_t;

    state_t state, next_state;

    logic [31:0] a_reg, b_reg;
    logic [15:0] r1, r2;

    // Combinational outputs
    assign isqrt_x_vld = (state == SEND_C) || (state == SEND_B) || (state == SEND_A);
    assign isqrt_x     = (state == SEND_C) ? c :
                         (state == SEND_B) ? (b_reg + 32'(r1)) :
                                             (a_reg + 32'(r2));

    assign res_vld = (state == OUTPUT);
    assign res     = (state == OUTPUT) ? 32'(isqrt_y) : 32'd0;

    always_comb begin
        next_state = state;
        case (state)
            IDLE:       if (arg_vld) next_state = SEND_C;
            SEND_C:                    next_state = WAIT_C;
            WAIT_C:     if (isqrt_y_vld) next_state = SEND_B;
            SEND_B:                    next_state = WAIT_B;
            WAIT_B:     if (isqrt_y_vld) next_state = SEND_A;
            SEND_A:                    next_state = WAIT_A;
            WAIT_A:     if (isqrt_y_vld) next_state = OUTPUT;
            OUTPUT:                    next_state = IDLE;
            default:                   next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (state == IDLE && arg_vld) begin
            a_reg <= a;
            b_reg <= b;
        end
        if (state == WAIT_C && isqrt_y_vld)
            r1 <= isqrt_y;
        if (state == WAIT_B && isqrt_y_vld)
            r2 <= isqrt_y;
    end


endmodule
