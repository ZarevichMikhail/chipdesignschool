//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1
(
  input  [3:0] d0, d1,
  input        sel,
  output [3:0] y
);

  // Массив из двух четырёхбитных шин
  logic [3:0] d [0:1];

  // Присваевает входные сигналы в массив
  assign d [0] = d0;
  assign d [1] = d1;

  // sel выбирает нужный вход в массиве
  assign y = d [sel];

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input  [3:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [3:0] y
);

  // Task:
  // Using code for mux_2_1 as an example,
  // write code for 4:1 mux using array index

    logic [3:0] d [0:3];

    assign d[0] = d0;
    assign d[1] = d1;
    assign d[2] = d2;
    assign d[3] = d3;

    assign y = d[sel];


endmodule
