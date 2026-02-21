module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
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
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.





    // Number of internal modules (idealized distributor)
    localparam NUM_MODULES = 50;
    
    //------------------------------------------------------------------------
    // Internal module interface
    //------------------------------------------------------------------------
    reg  [NUM_MODULES-1:0] module_arg_vld_reg;
    wire [NUM_MODULES-1:0] module_arg_vld;
    
    reg  [31:0] module_a_reg [0:NUM_MODULES-1];
    reg  [31:0] module_b_reg [0:NUM_MODULES-1];
    reg  [31:0] module_c_reg [0:NUM_MODULES-1];
    
    wire [NUM_MODULES-1:0] module_res_vld;
    wire [31:0] module_res [0:NUM_MODULES-1];
    
    // Assign module_arg_vld from register
    assign module_arg_vld = module_arg_vld_reg;
    
    //------------------------------------------------------------------------
    // Round-robin distributor
    //------------------------------------------------------------------------
    reg [$clog2(NUM_MODULES)-1:0] next_module;
    reg [NUM_MODULES-1:0] module_busy;
    
    genvar i;
    integer j, k;
    reg found;
    
    // Track which modules are busy and distribute tasks
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            module_busy <= '0;
            next_module <= '0;
            module_arg_vld_reg <= '0;
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                module_a_reg[j] <= 32'b0;
                module_b_reg[j] <= 32'b0;
                module_c_reg[j] <= 32'b0;
            end
        end else begin
            // Default: no module gets new task
            module_arg_vld_reg <= '0;
            
            // Mark module as free when it produces a result
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                if (module_res_vld[j]) begin
                    module_busy[j] <= 1'b0;
                end
            end
            
            // Assign new task if input is valid
            if (arg_vld) begin
                found = 1'b0;
                
                // Find a free module (round-robin starting from next_module)
                for (j = 0; j < NUM_MODULES && !found; j = j + 1) begin
                    k = (next_module + j) % NUM_MODULES;
                    if (!module_busy[k]) begin
                        module_arg_vld_reg[k] <= 1'b1;
                        module_a_reg[k] <= a;
                        module_b_reg[k] <= b;
                        module_c_reg[k] <= c;
                        module_busy[k] <= 1'b1;
                        next_module <= (k + 1) % NUM_MODULES;
                        found = 1'b1;
                    end
                end
            end
        end
    end
    
    //------------------------------------------------------------------------
    // Instantiate the appropriate internal modules based on parameters
    //------------------------------------------------------------------------
    generate
        if (formula == 1) begin : gen_formula_1
            if (impl == 1) begin : gen_impl_1
                // formula_1_impl_1_top - uses 3 isqrt modules in parallel
                for (i = 0; i < NUM_MODULES; i = i + 1) begin : mod
                    formula_1_impl_1_top u_mod (
                        .clk      (clk),
                        .rst      (rst),
                        .arg_vld  (module_arg_vld[i]),
                        .a        (module_a_reg[i]),
                        .b        (module_b_reg[i]),
                        .c        (module_c_reg[i]),
                        .res_vld  (module_res_vld[i]),
                        .res      (module_res[i])
                    );
                end
            end else begin : gen_impl_2
                // formula_1_impl_2_top - uses 2 isqrt modules in parallel (from 05_04)
                for (i = 0; i < NUM_MODULES; i = i + 1) begin : mod
                    formula_1_impl_2_top u_mod (
                        .clk      (clk),
                        .rst      (rst),
                        .arg_vld  (module_arg_vld[i]),
                        .a        (module_a_reg[i]),
                        .b        (module_b_reg[i]),
                        .c        (module_c_reg[i]),
                        .res_vld  (module_res_vld[i]),
                        .res      (module_res[i])
                    );
                end
            end
        end else begin : gen_formula_2
            // formula_2_top - uses 1 isqrt module sequentially (from 05_05)
            for (i = 0; i < NUM_MODULES; i = i + 1) begin : mod
                formula_2_top u_mod (
                    .clk      (clk),
                    .rst      (rst),
                    .arg_vld  (module_arg_vld[i]),
                    .a        (module_a_reg[i]),
                    .b        (module_b_reg[i]),
                    .c        (module_c_reg[i]),
                    .res_vld  (module_res_vld[i]),
                    .res      (module_res[i])
                );
            end
        end
    endgenerate
    
    //------------------------------------------------------------------------
    // Output arbiter - collect results from modules
    //------------------------------------------------------------------------
    reg [$clog2(NUM_MODULES)-1:0] out_idx;
    reg [NUM_MODULES-1:0] result_ready;
    reg [31:0] result_data [0:NUM_MODULES-1];
    reg [31:0] res_reg;
    reg        res_vld_reg;
    integer m, n;
    reg found_result;
    
    // Simple round-robin output arbiter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_idx <= '0;
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                result_ready[j] <= 1'b0;
                result_data[j] <= 32'b0;
            end
            res_vld_reg <= 1'b0;
            res_reg <= 32'b0;
        end else begin
            // Default
            res_vld_reg <= 1'b0;
            
            // Track result ready flags
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                if (module_res_vld[j]) begin
                    result_ready[j] <= 1'b1;
                    result_data[j] <= module_res[j];
                end
            end
            
            // Output a result if any is ready
            found_result = 1'b0;
            
            for (m = 0; m < NUM_MODULES && !found_result; m = m + 1) begin
                n = (out_idx + m) % NUM_MODULES;
                if (result_ready[n]) begin
                    res_vld_reg <= 1'b1;
                    res_reg <= result_data[n];
                    result_ready[n] <= 1'b0;
                    out_idx <= (n + 1) % NUM_MODULES;
                    found_result = 1'b1;
                end
            end
        end
    end
    
    assign res_vld = res_vld_reg;
    assign res = res_reg;












endmodule
