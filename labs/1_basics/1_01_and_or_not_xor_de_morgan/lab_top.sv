`include "config.svh"

// Модуль и его название
// top - Название главного модуля в иерархии
// Зачем перед скобкой #?
module lab_top
# ( // Блок параметров. Параметры позволяют настраивать модуль без изменения его кода. 
    parameter  clk_mhz       = 50, // Задаёт частоту тактового сигнала (50 МГц).
               w_key         = 4,  // Задают разрядность (шину) для кнопок, переключателей и светодиодов
               w_sw          = 8,  // если не указан тип - по умолчанию wire 
               w_led         = 8,
               w_digit       = 8,  // Задаёт количество разрядов семисегментного индикатора.
               w_gpio        = 100,  // Задаёт количество контактов общего назначения (GPIO).

               screen_width  = 640,
               screen_height = 480,

            // разрядность каждого цветового канала
               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,
            
            // Вычисление количества бит, необходимое для кодирования координат
            // $clog2(N) возвращает минимальное целое число M, такое что 2^M >= N.
               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)


// В этом разделе объявляются все "ножки" модуля, через которые он взаимодействует
// с внешним миром (другими модулями или физическими компонентами на плате).
(
	
	// input - входной сигнал. 
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key, // шина с кнопками 
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
       assign abcdefgh   = '0;
       assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire a = key [0];
    wire b = key [1];

    // Исключающее или xor
    // 0 0 0
    // 0 1 1
    // 1 0 1
    // 1 1 0
    wire result = a ^ b;

    assign led [0] = result;

    assign led [1] = key [0] ^ key [1];
    // assign led [2] = a ^ b;

    //------------------------------------------------------------------------

    /*
    `ifndef VERILATOR

    generate
        if (w_led > 2)
        begin : unused_led
            assign led [w_led - 1:2] = '0;
        end
    endgenerate

    `endif
    */
 
    //------------------------------------------------------------------------

    // Exercise 1: Change the code below.
    // Assign to led [2] the result of AND operation.
    //
    // If led [2] is not available on your board,
    // comment out the code above and reuse led [0].
    // Реализация xor через обычные функции 
    assign led [2] = (~a&b)|(a&~b);

    // Exercise 2: Change the code below.
    // Assign to led [3] the result of XOR operation
    // without using "^" operation.
    // Use only operations "&", "|", "~" and parenthesis, "(" and ")".

    assign led [3] = ~ a & ~ b;

    // Exercise 3: Create an illustration to De Morgan's laws:
    //
    // ~ (a & b) == ~ a | ~ b
    // ~ (a | b) == ~ a & ~ b

endmodule
