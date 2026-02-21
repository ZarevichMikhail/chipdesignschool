//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
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
    // Implement a pipelined module formula_2_pipe that computes the result
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
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0


    // Formula: isqrt(a + isqrt(b + isqrt(c)))
    
    localparam PIPE_DEPTH = 16;
    
    //------------------------------------------------------------------------
    // Pipeline Stage 1: Input pipeline
    //------------------------------------------------------------------------
    reg [31:0] a_pipe [0:3*PIPE_DEPTH+2];
    reg [31:0] b_pipe [0:3*PIPE_DEPTH+2];
    reg [31:0] c_pipe [0:3*PIPE_DEPTH+2];
    reg        v_pipe [0:3*PIPE_DEPTH+2];
    
    integer i;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i <= 3*PIPE_DEPTH+2; i = i + 1) begin
                a_pipe[i] <= 32'b0;
                b_pipe[i] <= 32'b0;
                c_pipe[i] <= 32'b0;
                v_pipe[i] <= 1'b0;
            end
        end else begin
            // Stage 0 gets new data
            v_pipe[0] <= arg_vld;
            a_pipe[0] <= a;
            b_pipe[0] <= b;
            c_pipe[0] <= c;
            
            // Shift all stages
            for (i = 1; i <= 3*PIPE_DEPTH+2; i = i + 1) begin
                v_pipe[i] <= v_pipe[i-1];
                a_pipe[i] <= a_pipe[i-1];
                b_pipe[i] <= b_pipe[i-1];
                c_pipe[i] <= c_pipe[i-1];
            end
        end
    end
    
    //------------------------------------------------------------------------
    // First isqrt module (computes sqrt(c))
    //------------------------------------------------------------------------
    wire [15:0] sqrt_c;
    wire        vld_c;
    
    isqrt #(.n_pipe_stages(PIPE_DEPTH)) isqrt_c_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (v_pipe[1]),  // Use pipelined c
        .x      (c_pipe[1]),
        .y_vld  (vld_c),
        .y      (sqrt_c)
    );
    
    //------------------------------------------------------------------------
    // Second isqrt module input stage
    //------------------------------------------------------------------------
    reg [31:0] b_plus_sqrt_c;
    reg        v_b;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_b <= 1'b0;
            b_plus_sqrt_c <= 32'b0;
        end else begin
            v_b <= vld_c;
            if (vld_c) begin
                // b is at pipe index 1 + PIPE_DEPTH
                b_plus_sqrt_c <= b_pipe[1 + PIPE_DEPTH] + {16'b0, sqrt_c};
            end
        end
    end
    
    //------------------------------------------------------------------------
    // Second isqrt module (computes sqrt(b + sqrt(c)))
    //------------------------------------------------------------------------
    wire [15:0] sqrt_b_plus_c;
    wire        vld_b;
    
    isqrt #(.n_pipe_stages(PIPE_DEPTH)) isqrt_b_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (v_b),
        .x      (b_plus_sqrt_c),
        .y_vld  (vld_b),
        .y      (sqrt_b_plus_c)
    );
    
    //------------------------------------------------------------------------
    // Third isqrt module input stage
    //------------------------------------------------------------------------
    reg [31:0] a_plus_sqrt_b_plus_c;
    reg        v_a;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_a <= 1'b0;
            a_plus_sqrt_b_plus_c <= 32'b0;
        end else begin
            v_a <= vld_b;
            if (vld_b) begin
                // a is at pipe index 1 + 2*PIPE_DEPTH + 1
                a_plus_sqrt_b_plus_c <= a_pipe[2 + 2*PIPE_DEPTH] + {16'b0, sqrt_b_plus_c};
            end
        end
    end
    
    //------------------------------------------------------------------------
    // Third isqrt module (computes final result)
    //------------------------------------------------------------------------
    wire [15:0] final_sqrt;
    wire        vld_final;
    
    isqrt #(.n_pipe_stages(PIPE_DEPTH)) isqrt_a_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (v_a),
        .x      (a_plus_sqrt_b_plus_c),
        .y_vld  (vld_final),
        .y      (final_sqrt)
    );
    
    //------------------------------------------------------------------------
    // Output stage
    //------------------------------------------------------------------------
    reg [31:0] res_reg;
    reg        v_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_out <= 1'b0;
            res_reg <= 32'b0;
        end else begin
            v_out <= vld_final;
            if (vld_final) begin
                res_reg <= {16'b0, final_sqrt};
            end
        end
    end
    
    assign res_vld = v_out;
    assign res = res_reg;

endmodule
