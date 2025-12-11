//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module add
(
  input  [3:0] a, b,
  output [3:0] sum
);

  assign sum = a + b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module signed_add_with_saturation
(
  input  [3:0] a, b,
  output [3:0] sum
);

  // Task:
  //
  // Implement a module that adds two signed numbers with saturation.
  //
  // "Adding with saturation" means:
  //
  // When the result does not fit into 4 bits,
  // and the arguments are positive,
  // the sum should be set to the maximum positive number.
  //
  // When the result does not fit into 4 bits,
  // and the arguments are negative,
  // the sum should be set to the minimum negative number.

    // Тут, в отличие от 1 задания, нужно не просто найти переполнение
    // но и обработать его

    // Если 4+5 = 9
    // 0100+0101 = 1001. 
    // В дополнительном коде первая значащая цифра 1 означает отрицательное число.
    // Мы так посчитать не можем. Сложили два плюса а получили минус.

    // Нужно заменить этот результат на 0111

    // Если -4 + (-5) = -9
    // 1100+1101 = 1 0110
    // Сложили два минуса а получили плюс
    // Нужно заменить на 1000


    // Если есть переполнение и числа положительные - ставить максимум
    // если есть переполнение и числа отрицательные - минимум

    // Логическая переменная, чтобы присваивать в always_comb
    logic [3:0] logic_sum;
    assign sum = logic_sum;

    // Сумма как в обычном сложении. см Задание 1
    wire [3:0] raw_sum = a + b;

    // Цифра переноса 
    wire overflow = (a[3] == b[3]) && !(raw_sum[3] == a[3]);

    // 3. Логика насыщения
    // Если overflow нет -> выводим raw_sum.
    // Если overflow есть:
    //    - Если a[3] == 0 (числа положительные), то результат должен быть MAX_POS (7 или 0111).
    //    - Если a[3] == 1 (числа отрицательные), то результат должен быть MIN_NEG (-8 или 1000).


    always_comb begin

        // Если переполнения нет, выводим сумму
        if(overflow == 0) begin
            
            logic_sum = raw_sum;
        
        // Переполнение есть 
        end else begin
            
            // Оба числа положительные - выводим максимум
            if(a[3] == 0) begin
                logic_sum = 4'b0111;

            // Оба числа отрицательные - выводим минимум
            end else begin
                logic_sum = 4'b1000;
            end
        end
    end


endmodule
