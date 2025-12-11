//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------


// Арифметический сдвиг вправо >>>
// Нужен для сдвига знаковых чисел
// Деление на 2

// Знаковое число 1011 -5
// При >> получим 0101. Это тоже число другого знака
// Должно быть 1101 -5/2 = -2.5 округление вниз = -3


// Для отрицательных чисел, чтобы всё было в порядке
// Нужно вставлять единицы
// С положительными числами он вставляет нули как обычно. 
// т.е. первую значащую цифру. 

// Арифметический сдвиг делается с помощью >>>

// Задание состоит в том, чтобы сделать это без него. 


module arithmetic_right_shift_of_N_by_S_using_arithmetic_right_shift_operation
# (
    parameter N = 8, 
    parameter S = 3
)
(
    input  [N - 1:0] a, 
    output [N - 1:0] res
);
    // as - a signed
    wire signed [N - 1:0] as = a;
    assign res = as >>> S;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module arithmetic_right_shift_of_N_by_S_using_concatenation
# (
    parameter N = 8, 
    parameter S = 3
)
(
    input  [N - 1:0] a, 
    output [N - 1:0] res
);
  // Task:
  //
  // Implement a module with the logic for the arithmetic right shift,
  // but without using ">>>" operation. You are allowed to use only
  // concatenations ({a, b}), bit repetitions ({ a { b }}), bit slices
  // and constant expressions.


    // {S{...}} - оператор репликации (повторения).
    // Нужно взять старший бит a[N-1] и повторить его S раз.

    assign res = { {S{a[N-1]}}, a[N - 1 : S] };


endmodule

module arithmetic_right_shift_of_N_by_S_using_for_inside_always
# (
    parameter N = 8, 
    parameter S = 3
)
(
    input  [N - 1:0] a, 
    output logic [N - 1:0] res
);
  // Task:
  //
  // Implement a module with the logic for the arithmetic right shift,
  // but without using ">>>" operation, concatenations or bit slices.
  // You are allowed to use only "always_comb" with a "for" loop
  // that iterates through the individual bits of the input.


    // До сдвига
    // 8765 4321
    // 7654 3210
    // 1000 1111

    // После сдвига
    // 8765 4321
    // 7654 3210
    // 1111 0001
    // N-S = 8-3 = 5

    // res[1] = a[4] 1+S

    always_comb begin
        for (int i = 0; i < N; i++) begin
            if (i< N-S)
                res[i] = a[i + S]; 
            // i>= N-S - биты, которые нужно вставлять
            else
                res[i] = a[N-1]; // На их место идёт знаковый бит. 

        end
  end


endmodule

module arithmetic_right_shift_of_N_by_S_using_for_inside_generate
# (parameter N = 8, S = 3)
(input  [N - 1:0] a, output [N - 1:0] res);

  // Task:
  // Implement a module that arithmetically shifts input exactly
  // by `S` bits to the right using "generate" and "for"

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : shift_block
        // Генерируем связи для старших битов (sign extension)
        if (i >= N - S) begin : sign_ext
            assign res[i] = a[N-1];
        end
        // Генерируем связи для данных (обычный сдвиг)
        else begin : data_shift
            assign res[i] = a[i + S];
        end
        end
    endgenerate

endmodule
