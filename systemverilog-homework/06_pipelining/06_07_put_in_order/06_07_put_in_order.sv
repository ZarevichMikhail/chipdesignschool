module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.


    // Pointer to the next expected input in round-robin order
    reg [$clog2(n_inputs)-1:0] next_ptr;
    reg [$clog2(n_inputs)-1:0] next_ptr_next;
    
    // Valid bits for each input - indicating data is ready and waiting
    reg [n_inputs-1:0] ready;
    reg [n_inputs-1:0] ready_next;
    
    // Data storage for each input
    reg [n_inputs-1:0][width-1:0] data_storage;
    reg [n_inputs-1:0][width-1:0] data_storage_next;
    
    // Output signals
    reg down_vld_reg;
    reg [width-1:0] down_data_reg;
    
    integer i;
    
    // Combinational logic for next state
    always @(*) begin
        // Default: keep current values
        ready_next = ready;
        data_storage_next = data_storage;
        next_ptr_next = next_ptr;
        down_vld_reg = 1'b0;
        down_data_reg = '0;
        
        // Store any incoming valid data
        for (i = 0; i < n_inputs; i = i + 1) begin
            if (up_vlds[i]) begin
                ready_next[i] = 1'b1;
                data_storage_next[i] = up_data[i];
            end
        end
        
        // Check if we can output the next expected data
        if (ready_next[next_ptr]) begin
            down_vld_reg = 1'b1;
            down_data_reg = data_storage_next[next_ptr];
            ready_next[next_ptr] = 1'b0;
            next_ptr_next = (next_ptr == n_inputs-1) ? '0 : next_ptr + 1'b1;
        end
    end
    
    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            next_ptr <= '0;
            ready <= '0;
            for (i = 0; i < n_inputs; i = i + 1) begin
                data_storage[i] <= '0;
            end
        end else begin
            next_ptr <= next_ptr_next;
            ready <= ready_next;
            data_storage <= data_storage_next;
        end
    end
    
    // Output assignments
    assign down_vld = down_vld_reg;
    assign down_data = down_data_reg;

endmodule
