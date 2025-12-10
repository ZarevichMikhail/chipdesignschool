/*`include "config.svh"

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
    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,
    output logic [          7:0] abcdefgh, // Пин 7=h (DP), 6=g, ... 0=a
    output logic [w_digit - 1:0] digit,
    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,
    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,
    input        [         23:0] mic,
    output       [         15:0] sound,
    input                        uart_rx,
    output                       uart_tx,
    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------
    // Выходы, которые мы не используем
       assign led        = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------
    // Главный 50 МГц счётчик
    logic [31:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    //------------------------------------------------------------------------
    //  --- НАЧАЛО НОВОЙ ЛОГИКИ ДЛЯ ЗАДАНИЯ ---
    //------------------------------------------------------------------------

    // --- 1. Паттерны для 7-сегментного индикатора (Общий КАТОД, '1'=горит) ---
    // Формат: {h, g, f, e, d, c, b, a}
    localparam P_BLANK = 8'h00; // 00000000
    localparam P_F     = 8'h71; // 01110001
    localparam P_P     = 8'h73; // 01110011
    localparam P_G     = 8'h6D; // 01101101
    localparam P_A     = 8'h77; // 01110111
    localparam P_C     = 8'h39; // 00111001
    localparam P_E     = 8'h79; // 01111001
    localparam P_H     = 8'h76; // 01110110
    localparam P_I     = 8'h06; // 00000110
    localparam P_L     = 8'h38; // 00111000
    localparam P_O     = 8'h3F; // 00111111
    localparam P_R     = 8'h50; // 01010000 (строчная 'r')
    localparam P_S     = 8'h6D; // 01101101 (как 'G')
    localparam P_U     = 8'h3E; // 00111110

    // --- 2. Машина состояний ---
    typedef enum { RANDOM_SCROLL, SHOW_FPGA } state_e;
    state_e state;

    // --- 3. Таймеры ---
    // Счётчик на 10 секунд (50МГц * 10)
    localparam TEN_SECONDS = 50_000_000 * 10;
    logic [28:0] timer_10s; // 2^29 > 500M

    // Таймер для "бегущей строки", 5 сдвигов в секунду (5 Гц)
    localparam SCROLL_PERIOD = 50_000_000 / 5; // 10М циклов
    logic [23:0] scroll_timer; // 2^24 > 10M
    wire scroll_enable; // Импульс "тика" для сдвига
    
    assign scroll_enable = (scroll_timer == SCROLL_PERIOD - 1);
    
    // --- 4. Генератор случайных букв (LFSR) ---
    logic [3:0] lfsr; // 4 бита, генерирует 1..15
    logic [7:0] new_char_pattern;
    
    // ROM для 10 случайных букв
    always_comb
    begin
        case(lfsr)
            4'd1:    new_char_pattern = P_A;
            4'd2:    new_char_pattern = P_C;
            4'd3:    new_char_pattern = P_E;
            4'd4:    new_char_pattern = P_F;
            4'd5:    new_char_pattern = P_G;
            4'd6:    new_char_pattern = P_H;
            4'd7:    new_char_pattern = P_L;
            4'd8:    new_char_pattern = P_O;
            4'd9:    new_char_pattern = P_P;
            4'd10:   new_char_pattern = P_R;
            4'd11:   new_char_pattern = P_S;
            4'd12:   new_char_pattern = P_U;
            default: new_char_pattern = P_BLANK;
        endcase
    end
    
    // --- 5. Логика состояний и таймеров ---
    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst) begin
            state <= RANDOM_SCROLL;
            timer_10s <= '0;
            scroll_timer <= '0;
            lfsr <= 4'b1001; // Начальное (seed)
        end
        else begin
            // Логика таймеров
            if (state == RANDOM_SCROLL) begin
                if (timer_10s < TEN_SECONDS)
                    timer_10s <= timer_10s + 1'd1;
                else
                    state <= SHOW_FPGA; // 10 секунд прошло, меняем состояние
            end
            
            // Логика сдвига
            if (scroll_enable) begin
                scroll_timer <= '0;
                // Обновляем LFSR в момент сдвига
                lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[0]};
            end
            else begin
                scroll_timer <= scroll_timer + 1'd1;
            end
        end
    end

    // --- 6. Буфер дисплея (8 ячеек, по одной на индикатор) ---
    logic [7:0] display_patterns [0:7];

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst) begin
            for (int i=0; i<8; i++)
                display_patterns[i] <= P_BLANK;
        end
        else if (state == RANDOM_SCROLL) begin
            if (scroll_enable) begin
                // Сдвигаем все паттерны влево
                display_patterns[0] <= display_patterns[1];
                display_patterns[1] <= display_patterns[2];
                display_patterns[2] <= display_patterns[3];
                display_patterns[3] <= display_patterns[4];
                display_patterns[4] <= display_patterns[5];
                display_patterns[5] <= display_patterns[6];
                display_patterns[6] <= display_patterns[7];
                // Справа "заезжает" новая случайная буква
                display_patterns[7] <= new_char_pattern;
            end
        end
        else if (state == SHOW_FPGA) begin
            // Статично показываем "  fpga  "
            display_patterns[0] <= P_BLANK;
            display_patterns[1] <= P_BLANK;
            display_patterns[2] <= P_F;
            display_patterns[3] <= P_P;
            display_patterns[4] <= P_G;
            display_patterns[5] <= P_A;
            display_patterns[6] <= P_BLANK;
            display_patterns[7] <= P_BLANK;
        end
    end

    // --- 7. Быстрый сканер (динамическая индикация) ---
    
    // 'scan_sel' будет быстро считать 0, 1, 2, ..., 7
    // Мы берем 3 бита из 'cnt'. cnt[15:13] меняются с частотой ~6 кГц.
    wire [2:0] scan_sel = cnt[15:13];

    // Выводим паттерн, соответствующий *текущей сканируемой цифре*
    assign abcdefgh = display_patterns[scan_sel];

    // Включаем *только* ту цифру, которую сканируем (Активный '1')
    // (1'b1 << scan_sel) создает one-hot (00100000)
    assign digit = (1'b1 << scan_sel);

endmodule

*/




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
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------


    logic [31:0] cnt;

    // Уменьшает разрядность счётчика
    // Таким образом увеличивается частота
    // logic [15:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    wire enable = (cnt [22:0] == '0);
    // wire enable = (cnt 10:0] == '0);
    //------------------------------------------------------------------------

    logic [w_digit:0] shift_reg;
    //logic [0:w_digit] shift_reg;

    always_ff @ (posedge clk or posedge rst)
      if (rst)
        shift_reg <= w_digit' (1);
      else if (enable)
        shift_reg <= { shift_reg [0], shift_reg [w_digit - 1:1] };

    assign led = w_led' (shift_reg);

    //------------------------------------------------------------------------

    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h



    // Определений состояний конечного автомата FSM 
    typedef enum bit [7:0]
    {
        F     = 8'b1000_1110,
        P     = 8'b1100_1110,
        G     = 8'b1011_1100,
        A     = 8'b1110_1110,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

    seven_seg_encoding_e letter;

    always_comb
      case (4' (shift_reg))
      4'b1000: letter = F;
      4'b0100: letter = P;
      4'b0010: letter = G;
      4'b0001: letter = A;
      default: letter = space;
      endcase

    assign abcdefgh = letter;
    assign digit    = shift_reg;

    // Exercise 1: Increase the frequency of enable signal
    // to the level your eyes see the letters as a solid word
    // without any blinking. What is the threshold of such frequency?

    // Exercise 2: Put your name or another word to the display.

    // Exercise 3: Comment out the "default" clause from the "case" statement
    // in the "always" block,and re-synthesize the example.
    // Are you getting any warnings or errors? Try to explain why.

endmodule
