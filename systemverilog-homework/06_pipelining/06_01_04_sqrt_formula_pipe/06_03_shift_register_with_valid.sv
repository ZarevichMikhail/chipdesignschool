//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module one_bit_wide_shift_register_with_reset
# (
    parameter depth = 8
)
(
    input  clk,
    input  rst,
    input  in_data,
    output out_data
);
    logic [depth - 1:0] data;

    always_ff @ (posedge clk)
        if (rst)
            data <= '0;
        else
            data <= { data [depth - 2:0], in_data };

    assign out_data = data [depth - 1];

endmodule

//----------------------------------------------------------------------------

module shift_register
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);
    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module shift_register_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input                in_vld,
    input  [width - 1:0] in_data,

    output               out_vld,
    output [width - 1:0] out_data
);

    // Task:
    //
    // Implement a variant of a shift register module
    // that moves a transfer of data only if this transfer is valid.
    //
    // For the discussion of shift registers
    // see the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    // Valid pipeline - must behave exactly like one_bit_wide_shift_register_with_reset
    reg [depth-1:0] valid_pipeline;
    
    // Data pipeline - only shifts when data is valid at the source
    reg [width-1:0] data_pipeline [0:depth-1];
    
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            valid_pipeline <= '0;
            for (i = 0; i < depth; i = i + 1) begin
                data_pipeline[i] <= '0;
            end
        end else begin
            // Valid pipeline: always shift, exactly like the reference model
            valid_pipeline <= {valid_pipeline[depth-2:0], in_vld};
            
            // Data pipeline stage 0: Load new data if in_vld is high
            data_pipeline[0] <= in_vld ? in_data : data_pipeline[0];
            
            // Data pipeline stages 1 to depth-1: 
            // Shift data from previous stage
            for (i = 1; i < depth; i = i + 1) begin
                // Only shift if the data at stage i-1 is valid
                // Otherwise, hold the current value
                if (valid_pipeline[i-1]) begin
                    data_pipeline[i] <= data_pipeline[i-1];
                end
            end
        end
    end
    
    // Output assignments
    assign out_vld = valid_pipeline[depth-1];
    assign out_data = data_pipeline[depth-1];
endmodule
