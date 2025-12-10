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

       assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    localparam clk_div_cnt_w = 23;

    logic [clk_div_cnt_w-1:0] clk_div_counter_ff;
    logic                     clk_slow;
    logic                     clk_slow_global;
    logic [(4*w_digit)-1:0]   slow_counter_ff;

    // Clock divider counter
    always_ff @(posedge clk or posedge rst)
        if (rst)
            clk_div_counter_ff <= '0;
        else
            clk_div_counter_ff <= clk_div_counter_ff + 1;

    // "Slow clock" is taken from divider counter MSB
    assign clk_slow = clk_div_counter_ff[clk_div_cnt_w-1];

    // Route slow clock to global clock tree
    // Only for Altera. Comment out this line if you use Xilinx/GoWin or simulator.
    global i_slow_clk_global (.in(clk_slow), .out(clk_slow_global));

    // Uncomment this line if you use Xilinx/GoWin or simulator.
    // assign clk_slow_global = clk_slow;

    // "Slow counter" FF
    always_ff @(posedge clk_slow_global or posedge rst)
        if (rst)
            slow_counter_ff <= '0;
        else
            slow_counter_ff <= slow_counter_ff + 1;

    //------------------------------------------------------------------------

    // 4 bits per hexadecimal digit
    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                                 ),
        .rst      ( rst                                 ),
        .number   ( w_display_number' (slow_counter_ff) ),
        .dots     ( w_digit' (0)                        ),
        .abcdefgh ( abcdefgh                            ),
        .digit    ( digit                               )
    );


endmodule

// `include "config.svh"

// module lab_top
// # (
//     parameter  clk_mhz       = 50,
//                w_key         = 4,
//                w_sw          = 8,
//                w_led         = 8,
//                w_digit       = 8,
//                w_gpio        = 100,

//                screen_width  = 640,
//                screen_height = 480,

//                w_red         = 4,
//                w_green       = 4,
//                w_blue        = 4,

//                w_x           = $clog2(screen_width),
//                w_y           = $clog2(screen_height)
// )
// (
//     input                        clk,
//     input                        rst,  // slow_clk убран — не нужен

//     // Keys, switches, LEDs
//     input        [w_key   - 1:0] key,
//     input        [w_sw    - 1:0] sw,
//     output logic [w_led   - 1:0] led,

//     // Seven-segment display
//     output logic [7:0]           abcdefgh,
//     output logic [w_digit-1:0]   digit,

//     // Graphics (VGA-style)
//     input        [w_x-1:0]       x,
//     input        [w_y-1:0]       y,
//     output logic [w_red-1:0]     red,
//     output logic [w_green-1:0]   green,
//     output logic [w_blue-1:0]    blue,

//     // Audio & UART
//     input        [23:0]          mic,
//     output       [15:0]          sound,
//     input                        uart_rx,
//     output                       uart_tx,

//     // GPIO
//     inout        [w_gpio-1:0]    gpio
// );

//     //------------------------------------------------------------------------
//     // Assign constant/default outputs (inactive)
//     //------------------------------------------------------------------------

//     assign led      = '0;
//     assign red      = '0;
//     assign green    = '0;
//     assign blue     = '0;
//     assign sound    = '0;
//     assign uart_tx  = '1;

//     //------------------------------------------------------------------------
//     // Generate 5.96 Hz tick (enable pulse) from 50 MHz clk
//     // Target: f = 5.96 Hz → period = ~167.785 ms → N = 50e6 / 5.96 ≈ 8_389_262
//     //------------------------------------------------------------------------

//     localparam real TARGET_FREQ_HZ = 5.96;
//     localparam real CLK_FREQ_HZ    = real'(clk_mhz) * 1e6;
//     localparam integer COUNT_MAX   = integer'(CLK_FREQ_HZ / TARGET_FREQ_HZ + 0.5); // 8_389_262

//     // Counter width: enough to hold COUNT_MAX-1
//     localparam integer DIV_CNT_W = $clog2(COUNT_MAX);
//     logic [DIV_CNT_W-1:0] div_counter;
//     logic                 slow_tick;  // 1-clock pulse @ 5.96 Hz

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst) begin
//             div_counter <= '0;
//             slow_tick   <= 1'b0;
//         end else begin
//             slow_tick <= 1'b0;  // default: no pulse
//             if (div_counter == COUNT_MAX - 1) begin
//                 div_counter <= '0;
//                 slow_tick   <= 1'b1;  // generate pulse
//             end else begin
//                 div_counter <= div_counter + 1;
//             end
//         end
//     end

//     //------------------------------------------------------------------------
//     // Slow counter (hex counter for 7-seg display), increments at 5.96 Hz
//     //------------------------------------------------------------------------

//     localparam W_DISPLAY = w_digit * 4;  // 4 bits per hex digit
//     logic [W_DISPLAY-1:0] slow_counter_ff;

//     always_ff @(posedge clk or posedge rst) begin
//         if (rst)
//             slow_counter_ff <= '0;
//         else if (slow_tick)
//             slow_counter_ff <= slow_counter_ff + 1;
//     end

//     //------------------------------------------------------------------------
//     // Seven-segment display instantiation
//     //------------------------------------------------------------------------

//     seven_segment_display #(.w_digit(w_digit)) i_7segment (
//         .clk      (clk),
//         .rst      (rst),
//         .number   (slow_counter_ff[W_DISPLAY-1:0]),
//         .dots     ('0),
//         .abcdefgh (abcdefgh),
//         .digit    (digit)
//     );

//     //------------------------------------------------------------------------
//     // Unused pins — drive tri-state for GPIO
//     //------------------------------------------------------------------------

//     // Example: tie unused GPIO to high-Z (adjust if needed)
//     assign gpio = 'bz;

// endmodule