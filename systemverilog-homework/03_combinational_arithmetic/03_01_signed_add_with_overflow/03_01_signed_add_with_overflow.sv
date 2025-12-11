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

module signed_add_with_overflow
(
  input  [3:0] a, b,
  output [3:0] sum,
  output       overflow
);

  // Task:
  //
  // Implement a module that adds two signed numbers
  // and detects an overflow.
  //
  // By "signed" we mean "two's complement numbers".
  // See https://en.wikipedia.org/wiki/Two%27s_complement for details.
  //
  // The 'overflow' output bit should be set to 1
  // when the resulting sum (either positive or negative)
  // of two input arguments is greater or less than
  // 4-bit maximum or minimum signed number.
  //
  // Otherwise the 'overflow' should be set to 0.



    // Сумма
    assign sum = a + b;

    // Логика переполнения
    // За переполнение отвечает первая значащая цифра a[3]
    // Если складываются числа разных знаков - переполнения не будет. 
    // Если числа одного знака a[3] = b[3]. - то надо смотреть на знак суммы
    //      Если у первая значащая цифра суммы такая же - переполнения нет
     

    assign overflow = (a[3] == b[3]) && !(sum[3] == a[3]);
















  


endmodule
