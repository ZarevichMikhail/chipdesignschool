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


localparam PIPE_DEPTH = 16;

    //------------------------------------------------------------------------
    // First isqrt module (computes sqrt(c))
    //------------------------------------------------------------------------
    wire [15:0] sqrt_c;
    wire        vld_c;
    
    isqrt #(.n_pipe_stages(PIPE_DEPTH)) isqrt_c_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (arg_vld),
        .x      (c),
        .y_vld  (vld_c),
        .y      (sqrt_c)
    );

    //------------------------------------------------------------------------
    // FIFO for b (Delay: PIPE_DEPTH = 16 cycles)
    //------------------------------------------------------------------------
    reg [31:0] b_fifo [0:31];
    reg [4:0]  b_wr_ptr;
    reg [4:0]  b_rd_ptr;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            b_wr_ptr <= 5'b0;
            b_rd_ptr <= 5'b0;
        end else begin
            if (arg_vld) b_wr_ptr <= b_wr_ptr + 5'b1;
            if (vld_c)   b_rd_ptr <= b_rd_ptr + 5'b1;
        end
    end
    
    always @(posedge clk) begin
        if (arg_vld) b_fifo[b_wr_ptr] <= b;
    end
    
    wire [31:0] b_out = b_fifo[b_rd_ptr];

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
                b_plus_sqrt_c <= b_out + {16'b0, sqrt_c};
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
    // FIFO for a (Delay: 2*PIPE_DEPTH + 1 = 33 cycles)
    //------------------------------------------------------------------------
    reg [31:0] a_fifo [0:63];
    reg [5:0]  a_wr_ptr;
    reg [5:0]  a_rd_ptr;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_wr_ptr <= 6'b0;
            a_rd_ptr <= 6'b0;
        end else begin
            if (arg_vld) a_wr_ptr <= a_wr_ptr + 6'b1;
            if (vld_b)   a_rd_ptr <= a_rd_ptr + 6'b1;
        end
    end
    
    always @(posedge clk) begin
        if (arg_vld) a_fifo[a_wr_ptr] <= a;
    end
    
    wire [31:0] a_out = a_fifo[a_rd_ptr];

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
                a_plus_sqrt_b_plus_c <= a_out + {16'b0, sqrt_b_plus_c};
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
