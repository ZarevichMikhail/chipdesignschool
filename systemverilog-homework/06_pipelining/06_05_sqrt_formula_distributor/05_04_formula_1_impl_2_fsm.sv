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


    typedef enum logic [2:0] {
        IDLE,
        SEND_AB,
        WAIT_AB,
        SEND_C,
        WAIT_C,
        OUTPUT
    } state_t;

    state_t state, next_state;

    logic [15:0] sqrt_a, sqrt_b;
    logic [31:0] sum_ab;

    // ---- Output assignments (combinational, no latches) ----
    assign isqrt_1_x_vld = (state == SEND_AB) || (state == SEND_C);
    assign isqrt_1_x     = (state == SEND_AB) ? a : c;

    assign isqrt_2_x_vld = (state == SEND_AB);
    assign isqrt_2_x     = b;

    assign res_vld = (state == OUTPUT);
    assign res     = (state == OUTPUT) ? (sum_ab + 32'(isqrt_1_y)) : 32'd0;

    // ---- Next state logic ----
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (arg_vld)
                    next_state = SEND_AB;
            end

            SEND_AB: // x_vld = 1 only here (1 cycle)
                next_state = WAIT_AB;

            WAIT_AB: begin
                if (isqrt_1_y_vld && isqrt_2_y_vld)
                    next_state = SEND_C;
            end

            SEND_C: // x_vld = 1 only here (1 cycle)
                next_state = WAIT_C;

            WAIT_C: begin
                if (isqrt_1_y_vld)
                    next_state = OUTPUT;
            end

            OUTPUT:
                next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end

    // ---- Sequential logic ----
    always_ff @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Capture intermediate results
    always_ff @(posedge clk) begin
        if (state == WAIT_AB && isqrt_1_y_vld && isqrt_2_y_vld) begin
            sqrt_a <= isqrt_1_y;
            sqrt_b <= isqrt_2_y;
            sum_ab <= 32'(isqrt_1_y) + 32'(isqrt_2_y);
        end
    end


endmodule
