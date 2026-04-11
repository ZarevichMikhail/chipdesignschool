`include "sr_cpu.svh"

module sr_cpu
(
    input           clk,      // clock
    input           rst,      // reset

    output  [31:0]  imAddr,   // instruction memory address
    input   [31:0]  imData,   // instruction memory data

    input   [ 4:0]  regAddr,  // debug access reg address
    output  [31:0]  regData   // debug access reg data
);
    // control wires
    wire        aluZero;
    wire        pcSrc;
    wire        regWrite;
    wire        aluSrc;
    wire        wdSrc;
    wire  [2:0] aluControl;
    wire        mduVld;

    // instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    // --- HAZARD UNIT И ОТСЛЕЖИВАНИЕ КОНВЕЙЕРА MDU ---
    localparam N_DELAY = 2; // Параметризуемая задержка MDU
    logic [4:0] mdu_rd_pipe [0:N_DELAY-1];
    logic       mdu_we_pipe [0:N_DELAY-1];

    logic uses_rs1;
    logic uses_rs2;

    always_comb begin
        uses_rs1 = (cmdOp != `RVOP_LUI);
        uses_rs2 = (cmdOp == `RVOP_ADD) || (cmdOp == `RVOP_OR) ||
                   (cmdOp == `RVOP_SRL) || (cmdOp == `RVOP_SLTU) ||
                   (cmdOp == `RVOP_SUB) || (cmdOp == `RVOP_BEQ) ||
                   (cmdOp == `RVOP_BNE) || (cmdOp == `RVOP_MUL);
    end

    // Проверяем все стадии конвейера, КРОМЕ последней (там сработает байпас)
    logic hazard_stall;
    always_comb begin
        hazard_stall = 1'b0;
        for (int i = 0; i < N_DELAY - 1; i++) begin
            if (mdu_we_pipe[i]) begin
                if (uses_rs1 && rs1 != 0 && rs1 == mdu_rd_pipe[i]) hazard_stall = 1'b1;
                if (uses_rs2 && rs2 != 0 && rs2 == mdu_rd_pipe[i]) hazard_stall = 1'b1;
            end
        end
    end

    wire stall = hazard_stall;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N_DELAY; i++) begin
                mdu_rd_pipe[i] <= '0;
                mdu_we_pipe[i] <= 1'b0;
            end
        end else if (stall) begin
            // Проталкиваем пузырек
            mdu_rd_pipe[0] <= '0;
            mdu_we_pipe[0] <= 1'b0;
            for (int i = 1; i < N_DELAY; i++) begin
                mdu_rd_pipe[i] <= mdu_rd_pipe[i-1];
                mdu_we_pipe[i] <= mdu_we_pipe[i-1];
            end
        end else begin
            // Загружаем новую инструкцию
            mdu_rd_pipe[0] <= rd;
            mdu_we_pipe[0] <= mduVld;
            for (int i = 1; i < N_DELAY; i++) begin
                mdu_rd_pipe[i] <= mdu_rd_pipe[i-1];
                mdu_we_pipe[i] <= mdu_we_pipe[i-1];
            end
        end
    end

    // program counter
    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 32'd4;
    wire [31:0] pcNext   = stall ? pc : (pcSrc ? pcBranch : pcPlus4);

    register_with_rst_and_en r_pc
    (
        .clk      ( clk        ),
        .rst      ( rst        ),
        .en       ( 1'b1       ), // ИСПРАВЛЕНИЕ: Порт en теперь подключен!
        .d        ( pcNext     ),
        .q        ( pc         )
    );

    // program memory access
    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    // instruction decode
    sr_decode id
    (
        .instr      ( instr ),
        .cmdOp      ( cmdOp ),
        .rd         ( rd    ),
        .cmdF3      ( cmdF3 ),
        .rs1        ( rs1   ),
        .rs2        ( rs2   ),
        .cmdF7      ( cmdF7 ),
        .immI       ( immI  ),
        .immB       ( immB  ),
        .immU       ( immU  )
    );

    // register file
    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;
    wire [31:0] mdu_result;

    sr_register_file i_rf
    (
        .clk        ( clk         ),
        .a0         ( regAddr     ),
        .a1         ( rs1         ),
        .a2         ( rs2         ),
        .a3         ( rd          ),
        .rd0        ( rd0         ),
        .rd1        ( rd1         ),
        .rd2        ( rd2         ),
        .wd3        ( wd3         ),
        .we3        ( regWrite & ~stall ), // Не пишем ALU при stall
        
        // Порт 4: запись результатов из последней стадии конвейера MDU
        .a4         ( mdu_rd_pipe[N_DELAY-1] ),
        .wd4        ( mdu_result  ),
        .we4        ( mdu_we_pipe[N_DELAY-1] )
    );

    // --- БАЙПАСЫ (FORWARDING) ---
    logic [31:0] fwd_rd1;
    logic [31:0] fwd_rd2;

    always_comb begin
        fwd_rd1 = rd1;
        if (mdu_we_pipe[N_DELAY-1] && mdu_rd_pipe[N_DELAY-1] == rs1 && rs1 != 0)
            fwd_rd1 = mdu_result;

        fwd_rd2 = rd2;
        if (mdu_we_pipe[N_DELAY-1] && mdu_rd_pipe[N_DELAY-1] == rs2 && rs2 != 0)
            fwd_rd2 = mdu_result;
    end

    // alu
    wire [31:0] srcB = aluSrc ? immI : fwd_rd2;
    wire [31:0] aluResult;

    sr_alu alu
    (
        .srcA       ( fwd_rd1     ),
        .srcB       ( srcB        ),
        .oper       ( aluControl  ),
        .zero       ( aluZero     ),
        .result     ( aluResult   )
    );

    assign wd3 = wdSrc ? immU : aluResult;

    // --- MDU ИНСТАНЦИРОВАНИЕ ---
    wire mdu_o_vld;
    sr_mdu #( .n_delay(N_DELAY) ) mdu
    (
        .clk    (clk),
        .rst    (rst),
        .i_vld  (mduVld & ~stall),
        .srcA   (fwd_rd1),         
        .srcB   (fwd_rd2),
        .o_vld  (mdu_o_vld),
        .result (mdu_result),
        .busy   () 
    );

    // control
    sr_control sm_control
    (
        .cmdOp      ( cmdOp        ),
        .cmdF3      ( cmdF3        ),
        .cmdF7      ( cmdF7        ),
        .aluZero    ( aluZero      ),
        .pcSrc      ( pcSrc        ),
        .regWrite   ( regWrite     ),
        .aluSrc     ( aluSrc       ),
        .wdSrc      ( wdSrc        ),
        .aluControl ( aluControl   ),
        .mduVld     ( mduVld       ) 
    );

    // debug register access
    assign regData = (regAddr != '0) ? rd0 : pc;

endmodule