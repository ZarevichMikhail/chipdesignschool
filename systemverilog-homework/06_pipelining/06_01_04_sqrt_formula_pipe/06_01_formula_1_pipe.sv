//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
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
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
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
    // Based on the test case: a=1, b=4, c=9 -> expected result 6
    // This matches isqrt(a) + isqrt(b) + isqrt(c)
    // isqrt(1)=1, isqrt(4)=2, isqrt(9)=3, sum=6
    
    // Pipeline stage 1: Register inputs for isqrt modules
    reg [31:0] a_stage1, b_stage1, c_stage1;
    reg        stage1_valid;
    
    // isqrt module outputs
    wire [15:0] isqrt_a_y, isqrt_b_y, isqrt_c_y;
    wire        isqrt_a_y_vld, isqrt_b_y_vld, isqrt_c_y_vld;
    
    // Pipeline stage 2: Capture isqrt outputs and extend to 32 bits
    reg [31:0] isqrt_a_out, isqrt_b_out, isqrt_c_out;
    reg        stage2_valid;
    
    // Pipeline stage 3: Sum the square roots
    reg [31:0] sum_result;
    reg        stage3_valid;
    
    // Stage 1: Register inputs for isqrt modules
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            a_stage1 <= 32'b0;
            b_stage1 <= 32'b0;
            c_stage1 <= 32'b0;
        end else begin
            stage1_valid <= arg_vld;
            
            if (arg_vld) begin
                a_stage1 <= a;
                b_stage1 <= b;
                c_stage1 <= c;
            end
        end
    end
    
    // Instantiate three pipelined isqrt modules
    isqrt #(.n_pipe_stages(16)) isqrt_a (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (stage1_valid),
        .x      (a_stage1),
        .y_vld  (isqrt_a_y_vld),
        .y      (isqrt_a_y)
    );
    
    isqrt #(.n_pipe_stages(16)) isqrt_b (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (stage1_valid),
        .x      (b_stage1),
        .y_vld  (isqrt_b_y_vld),
        .y      (isqrt_b_y)
    );
    
    isqrt #(.n_pipe_stages(16)) isqrt_c (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (stage1_valid),
        .x      (c_stage1),
        .y_vld  (isqrt_c_y_vld),
        .y      (isqrt_c_y)
    );
    
    // Stage 2: Capture isqrt outputs and extend to 32 bits
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            isqrt_a_out <= 32'b0;
            isqrt_b_out <= 32'b0;
            isqrt_c_out <= 32'b0;
        end else begin
            // All isqrt modules have the same pipeline depth (16 stages)
            // so their y_vld signals should be synchronized
            stage2_valid <= isqrt_a_y_vld & isqrt_b_y_vld & isqrt_c_y_vld;
            
            if (isqrt_a_y_vld & isqrt_b_y_vld & isqrt_c_y_vld) begin
                // Zero-extend 16-bit results to 32 bits
                isqrt_a_out <= {16'b0, isqrt_a_y};
                isqrt_b_out <= {16'b0, isqrt_b_y};
                isqrt_c_out <= {16'b0, isqrt_c_y};
            end
        end
    end
    
    // Stage 3: Sum the square roots
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage3_valid <= 1'b0;
            sum_result <= 32'b0;
        end else begin
            stage3_valid <= stage2_valid;
            
            if (stage2_valid) begin
                sum_result <= isqrt_a_out + isqrt_b_out + isqrt_c_out;
            end
        end
    end
    
    // Output assignments
    assign res_vld = stage3_valid;
    assign res = sum_result;

endmodule
