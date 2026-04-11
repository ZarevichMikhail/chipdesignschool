//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

module cpu_cluster
#(
    parameter nCPUs = 3
)
(
    input                        clk,      // clock
    input                        rst,      // reset

    input   [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input   [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output  [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

// Внутренние массивы сигналов для связи ядер и памяти
logic [nCPUs - 1:0][31:0] imAddr;
logic [nCPUs - 1:0]       imDataVld;
logic [31:0]              imData;

// Сигналы для 8-портового арбитра
logic [7:0] arb_req;
logic [7:0] arb_gnt;

// Каждый активный CPU всегда запрашивает память. 
// Генерируем маску из единиц для нужного количества процессоров.
assign arb_req = (8'd1 << nCPUs) - 8'd1;

// Экземпляр арбитра
round_robin_arbiter_8 arbiter (
    .clk ( clk     ),
    .rst ( rst     ),
    .req ( arb_req ),
    .gnt ( arb_gnt )
);

// Валидность данных (imDataVld) напрямую связана с получением гранта от арбитра.
// Если imDataVld == 0, процессор не обновляет Program Counter и ждет.
assign imDataVld = arb_gnt[nCPUs - 1:0];

// Мультиплексирование адреса: на ROM подается адрес того процессора, 
// который в данный момент получил доступ (arb_gnt[i] == 1).
logic [31:0] romAddr;

always_comb begin
    romAddr = '0;
    for (int i = 0; i < nCPUs; i++) begin
        if (arb_gnt[i]) begin
            romAddr = imAddr[i];
        end
    end
end

// Параметры для памяти инструкций
localparam ROM_SIZE = 64;
localparam ADDR_W   = $clog2(ROM_SIZE);

// Общая память инструкций
instruction_rom #(
    .SIZE ( ROM_SIZE )
) i_rom (
    .a  ( romAddr[ADDR_W - 1:0] ),
    .rd ( imData                )
);

// Генерация процессоров
// Имя блока g_cpu и экземпляра cpu важно, так как testbench и gtkwave.tcl 
// обращаются к конкретным путям, например: tb.cluster.g_cpu[0].cpu.pc
genvar i;
generate
    for (i = 0; i < nCPUs; i++) begin : g_cpu
        sr_cpu cpu (
            .clk       ( clk          ),
            .rst       ( rst          ),
            .rstPC     ( rstPC[i]     ),
            .imAddr    ( imAddr[i]    ),
            .imData    ( imData       ),
            .imDataVld ( imDataVld[i] ),
            .regAddr   ( regAddr[i]   ),
            .regData   ( regData[i]   )
        );
    end
endgenerate



endmodule
