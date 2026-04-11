`include "sr_cpu.svh"

module sr_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3,
    
    // Дополнительный порт записи для MDU
    input  [ 4:0] a4,
    input  [31:0] wd4,
    input         we4
);
    logic [31:0] rf [0:31];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always_ff @ (posedge clk) begin
        // ИСПРАВЛЕНИЕ: we4 (MDU) оценивается первым, 
        // мы перекроем его с помощью we3 (ALU), если они пишут в один регистр!
        if(we4 && a4 != 0) rf [a4] <= wd4;
        if(we3 && a3 != 0) rf [a3] <= wd3;
    end
endmodule