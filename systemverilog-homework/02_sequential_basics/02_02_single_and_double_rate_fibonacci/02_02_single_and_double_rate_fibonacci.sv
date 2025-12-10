//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module fibonacci
(
  input               clk,
  input               rst,
  output logic [15:0] num
);
   
  // 16 битный сигнал
  logic [15:0] num2;

  always_ff @ (posedge clk)
    if (rst)
      { num, num2 } <= { 16'd1, 16'd1 };
    else
      { num, num2 } <= { num2, num + num2 };
    
    //   1 1 num1 num2 
    //   1 2 num2 num1 + num2
    //   2 3 num2 num1 + num2
    //   3 5
    //   5 8

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module fibonacci_2
(
  input               clk,
  input               rst,
  output logic [15:0] num,
  output logic [15:0] num2
);

  // Task:
  // Implement a module that generates two fibonacci numbers per cycle

    // 2 новых числа за такт
    // 1 1 2    
    // 2 3 5    2 2+1 (2+1)+2
    // 5 8 13   5 5+3 (5+3)+5

    // 1 1 2  num1    num2         num3
    // 2 3 5  num3 num3+num2 (num3+num2)+num3
    // 5 8 13 num3 num3+num2 (num3+num2)+num3

    // Это не то. тут три числа за такт
    // 1  1  2
    // 3  5  8
    // 13 21 34

    logic [15:0] num3;

    always_ff @ (posedge clk)
    if (rst)
      { num, num2, num3 } <= { 16'd1, 16'd1, 16'd2 };
    else
      { num, num2, num3} <= { num3, num3 + num2, (num3+num2)+num3 };

// решение без num3
// always_ff @ (posedge clk)
//     if (rst)
//       
//       { num, num2 } <= { 16'd1, 16'd1 };
//     else
//       //{ num, num2 } <= { num + num2, num + 2*num2 };
//       { num, num2 } <= { num + num2, (num + num2) + num2 };

 

endmodule
