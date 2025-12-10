`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
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

    // Exercise 1: Free running counter.
    // How do you change the speed of LED blinking?
    // Try different bit slices to display.

    //localparam w_cnt = $clog2 (clk_mhz * 1000 * 1000);
    // +3 увеличивает разрядность счётчика
    // Дальше возьмём самые старшие из них, чтобы светодидоды мигали медленнее
    // если взять, например 15:8 то мигать будет очень быстро 
    // так что светодиоды будут гореть всегда.
    
    // localparam - объявление константы
    // $clog2 - вычисление, сколько бит нужно, чтобы посчитать до 50*10^6

    /*
    localparam w_cnt = $clog2 (clk_mhz * 1000 * 1000)+3;

    // Объявление счётчика
    logic [w_cnt - 1:0] cnt;

    // always_ff описывает последовательную логику, то есть то, что хранится в триггерах
    // Срабатывает только когда меняется сигнал в скобках
    // запоминает своё предыдущеп состояние 
    // posedge - positive edge - фронт сигнала clk
    // negedgse - negative edge - срез
    always_ff @ (posedge clk or posedge rst)
        if (rst) // Если сигнал сброса, то значение счётчика сбросится в 0
            cnt <= '0;
        else // Иначе при тактовом сигнале значение счётчика увеличивается
            cnt <= cnt + 1'd1;

    // На светодиоды выводится диапазон разрядов счётчика. 
    // Чем больше индекс разряда, тем с меньшей частотой мигает светодиод. 
    // Тут мы берём самые старшие биты счётчика, так что светодиоды мигают медленнее всего
    assign led = cnt [$left (cnt) -: w_led];

    */
    //assign led = cnt [$left (cnt) -: w_led];
    //assign led = cnt [15:8];

    
    
    // Exercise 2: Key-controlled counter.
    // Comment out the code above.
    // Uncomment and synthesize the code below.
    // Press the key to see the counter incrementing.
    //
    // Change the design, for example:
    //
    // 1. One key is used to increment, another to decrement.
    //
    // 2. Two counters controlled by different keys
    // displayed in different groups of LEDs.

    
    
    // any key - счётчик сдвигается по нажатию на любую кнопку 
    //wire any_key = | key;


   // Моё решение задания
   
    wire inc_key = key[0];
    wire dec_key = key[1];


    logic inc_key_r;
    logic dec_key_r;
    
    
    
    // Код, который был по умолчанию 
    /*
    
    logic any_key_r;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            any_key_r <= '0;
        else
            any_key_r <= any_key;
    */
    //wire any_key_pressed = ~ any_key & any_key_r;
    
    // Моё решение задания
    
    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            inc_key_r <= '0;
            dec_key_r <= '0;
        end
        else
        begin
            inc_key_r <= inc_key;
            dec_key_r <= dec_key;
        end
    end

    // Флаги нажатия кнопок
    wire inc_key_pressed = ~ inc_key & inc_key_r;
    wire dec_key_pressed = ~ dec_key & dec_key_r;


    logic [w_led - 1:0] cnt;
    

    // Код, который был по умолчанию
    /*
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (any_key_pressed)
            cnt <= cnt + 1'd1;
    */


    
    always_ff @(posedge clk or posedge rst)
    begin
        if (rst)
            cnt <= '0;
        else if (inc_key_pressed)
            cnt <= cnt + 1'd1; // Инкрементируем счётчик
        else if (dec_key_pressed && cnt > 0)
            cnt <= cnt - 1'd1; // Декрементируем счётчик, если он не равен нулю
    end


    assign led = w_led' (cnt);
    
    

endmodule
