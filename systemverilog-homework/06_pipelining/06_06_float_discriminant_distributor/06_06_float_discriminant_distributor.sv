module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.




    // Number of internal modules (idealized distributor with 50 modules)
    localparam NUM_MODULES = 50;
    
    //------------------------------------------------------------------------
    // Internal module interface
    //------------------------------------------------------------------------
    reg  [NUM_MODULES-1:0] module_arg_vld_reg;
    wire [NUM_MODULES-1:0] module_arg_vld;
    
    reg  [FLEN-1:0] module_a_reg [0:NUM_MODULES-1];
    reg  [FLEN-1:0] module_b_reg [0:NUM_MODULES-1];
    reg  [FLEN-1:0] module_c_reg [0:NUM_MODULES-1];
    
    wire [NUM_MODULES-1:0] module_res_vld;
    wire [FLEN-1:0] module_res [0:NUM_MODULES-1];
    wire [NUM_MODULES-1:0] module_res_negative;
    wire [NUM_MODULES-1:0] module_err;
    wire [NUM_MODULES-1:0] module_busy_out;
    
    assign module_arg_vld = module_arg_vld_reg;
    
    //------------------------------------------------------------------------
    // Round-robin distributor
    //------------------------------------------------------------------------
    reg [$clog2(NUM_MODULES)-1:0] next_module;
    reg [NUM_MODULES-1:0] module_busy;
    
    genvar i;
    integer j, k;
    reg found;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            module_busy <= '0;
            next_module <= '0;
            module_arg_vld_reg <= '0;
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                module_a_reg[j] <= '0;
                module_b_reg[j] <= '0;
                module_c_reg[j] <= '0;
            end
        end else begin
            module_arg_vld_reg <= '0;
            
            // Mark modules as free when they produce results
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                if (module_res_vld[j]) begin
                    module_busy[j] <= 1'b0;
                end
            end
            
            // Also track busy from module's busy output
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                if (module_busy_out[j]) begin
                    module_busy[j] <= 1'b1;
                end
            end
            
            // Distribute new tasks to free modules
            if (arg_vld) begin
                found = 1'b0;
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
    // Instantiate internal float_discriminant modules
    //------------------------------------------------------------------------
    generate
        for (i = 0; i < NUM_MODULES; i = i + 1) begin : mod
            float_discriminant u_mod (
                .clk           (clk),
                .rst           (rst),
                .arg_vld       (module_arg_vld[i]),
                .a             (module_a_reg[i]),
                .b             (module_b_reg[i]),
                .c             (module_c_reg[i]),
                .res_vld       (module_res_vld[i]),
                .res           (module_res[i]),
                .res_negative  (module_res_negative[i]),
                .err           (module_err[i]),
                .busy          (module_busy_out[i])
            );
        end
    endgenerate
    
    //------------------------------------------------------------------------
    // Output arbiter - collect results from modules
    //------------------------------------------------------------------------
    reg [$clog2(NUM_MODULES)-1:0] out_idx;
    reg [NUM_MODULES-1:0] result_ready;
    reg [FLEN-1:0] result_data [0:NUM_MODULES-1];
    reg [NUM_MODULES-1:0] result_negative;
    reg [NUM_MODULES-1:0] result_err;
    
    reg [FLEN-1:0] res_reg;
    reg            res_negative_reg;
    reg            err_reg;
    reg            res_vld_reg;
    
    integer m, n;
    reg found_result;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_idx <= '0;
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                result_ready[j] <= 1'b0;
                result_data[j] <= '0;
                result_negative[j] <= 1'b0;
                result_err[j] <= 1'b0;
            end
            res_vld_reg <= 1'b0;
            res_reg <= '0;
            res_negative_reg <= 1'b0;
            err_reg <= 1'b0;
        end else begin
            res_vld_reg <= 1'b0;
            
            // Track results from modules
            for (j = 0; j < NUM_MODULES; j = j + 1) begin
                if (module_res_vld[j]) begin
                    result_ready[j] <= 1'b1;
                    result_data[j] <= module_res[j];
                    result_negative[j] <= module_res_negative[j];
                    result_err[j] <= module_err[j];
                end
            end
            
            // Output results in round-robin order
            found_result = 1'b0;
            for (m = 0; m < NUM_MODULES && !found_result; m = m + 1) begin
                n = (out_idx + m) % NUM_MODULES;
                if (result_ready[n]) begin
                    res_vld_reg <= 1'b1;
                    res_reg <= result_data[n];
                    res_negative_reg <= result_negative[n];
                    err_reg <= result_err[n];
                    result_ready[n] <= 1'b0;
                    out_idx <= (n + 1) % NUM_MODULES;
                    found_result = 1'b1;
                end
            end
        end
    end
    
    //------------------------------------------------------------------------
    // Output assignments
    //------------------------------------------------------------------------
    assign res_vld = res_vld_reg;
    assign res = res_reg;
    assign res_negative = res_negative_reg;
    assign err = err_reg;
    
    // Busy is high if any module is busy or if we have pending results
    always @(*) begin
        busy = 1'b0;
        for (j = 0; j < NUM_MODULES; j = j + 1) begin
            if (module_busy[j] || result_ready[j]) begin
                busy = 1'b1;
            end
        end
    end







endmodule
