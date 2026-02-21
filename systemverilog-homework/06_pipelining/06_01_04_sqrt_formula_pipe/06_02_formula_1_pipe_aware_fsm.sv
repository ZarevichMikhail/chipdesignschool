//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0


    // FSM states
    typedef enum logic [2:0] {
        IDLE,
        SEND_A,
        SEND_B,
        SEND_C,
        WAIT_A,
        WAIT_B,
        WAIT_C,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    // Datapath registers
    reg [31:0] a_reg, b_reg, c_reg;
    reg [31:0] sum_reg;
    reg [15:0] sqrt_a, sqrt_b;
    reg        a_done, b_done, c_done;
    
    // Counter for pipeline latency awareness
    reg [4:0] wait_cnt;
    
    // State machine - sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            c_reg <= 32'b0;
            sum_reg <= 32'b0;
            sqrt_a <= 16'b0;
            sqrt_b <= 16'b0;
            a_done <= 1'b0;
            b_done <= 1'b0;
            c_done <= 1'b0;
            wait_cnt <= 5'b0;
        end else begin
            state <= next_state;
            
            // Datapath updates based on current state
            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        a_reg <= a;
                        b_reg <= b;
                        c_reg <= c;
                        sum_reg <= 32'b0;
                        a_done <= 1'b0;
                        b_done <= 1'b0;
                        c_done <= 1'b0;
                        wait_cnt <= 5'b0;
                    end
                end
                
                SEND_A: begin
                    // Nothing to store
                end
                
                SEND_B: begin
                    // Nothing to store
                end
                
                SEND_C: begin
                    // Nothing to store
                end
                
                WAIT_A: begin
                    if (isqrt_y_vld) begin
                        sqrt_a <= isqrt_y;
                        a_done <= 1'b1;
                    end
                end
                
                WAIT_B: begin
                    if (isqrt_y_vld) begin
                        sqrt_b <= isqrt_y;
                        b_done <= 1'b1;
                    end
                end
                
                WAIT_C: begin
                    if (isqrt_y_vld) begin
                        sum_reg <= {16'b0, sqrt_a} + {16'b0, sqrt_b} + {16'b0, isqrt_y};
                        c_done <= 1'b1;
                    end
                end
                
                DONE: begin
                    // Result is ready
                end
            endcase
            
            // Wait counter for pipeline latency
            if (state == WAIT_A || state == WAIT_B || state == WAIT_C) begin
                if (wait_cnt < 5'd20)  // Slightly more than isqrt pipeline depth
                    wait_cnt <= wait_cnt + 1'b1;
            end else begin
                wait_cnt <= 5'b0;
            end
        end
    end
    
    // State machine - next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (arg_vld)
                    next_state = SEND_A;
            end
            
            SEND_A: begin
                next_state = WAIT_A;
            end
            
            WAIT_A: begin
                if (a_done)
                    next_state = SEND_B;
            end
            
            SEND_B: begin
                next_state = WAIT_B;
            end
            
            WAIT_B: begin
                if (b_done)
                    next_state = SEND_C;
            end
            
            SEND_C: begin
                next_state = WAIT_C;
            end
            
            WAIT_C: begin
                if (c_done)
                    next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic for isqrt interface
    always @(*) begin
        isqrt_x_vld = 1'b0;
        isqrt_x = 32'b0;
        
        case (state)
            SEND_A: begin
                isqrt_x_vld = 1'b1;
                isqrt_x = a_reg;
            end
            
            SEND_B: begin
                isqrt_x_vld = 1'b1;
                isqrt_x = b_reg;
            end
            
            SEND_C: begin
                isqrt_x_vld = 1'b1;
                isqrt_x = c_reg;
            end
            
            default: begin
                isqrt_x_vld = 1'b0;
                isqrt_x = 32'b0;
            end
        endcase
    end
    
    // Output logic for result
    always @(*) begin
        res_vld = 1'b0;
        res = 32'b0;
        
        if (state == DONE) begin
            res_vld = 1'b1;
            res = sum_reg;
        end
    end

endmodule
