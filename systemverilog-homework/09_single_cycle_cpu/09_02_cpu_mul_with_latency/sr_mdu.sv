`include "sr_cpu.svh"

module sr_mdu
# (
    parameter n_delay = 2
)
(
    input               clk,
    input               rst,

    input               i_vld,
    input        [31:0] srcA,
    input        [31:0] srcB,
    output              o_vld,
    output logic [31:0] result,
    output              busy
);
    logic [n_delay-1:0] vld_pipe;
    logic [31:0]        res_pipe [0:n_delay-1];

    assign busy = 1'b0; // Полностью конвейерный, никаких блокировок

    always_ff @(posedge clk) begin
        if (rst) begin
            vld_pipe <= '0;
            for (int i = 0; i < n_delay; i++) res_pipe[i] <= '0;
        end else begin
            // 1-я стадия
            vld_pipe[0] <= i_vld;
            res_pipe[0] <= srcA * srcB;

            // N-е стадии
            for (int i = 1; i < n_delay; i++) begin
                vld_pipe[i] <= vld_pipe[i-1];
                res_pipe[i] <= res_pipe[i-1];
            end
        end
    end

    assign o_vld  = vld_pipe[n_delay-1];
    assign result = res_pipe[n_delay-1];

endmodule