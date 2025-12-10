//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

// У первого числа самый младшй разряд 
module serial_comparator_least_significant_first
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);
  
  
  logic prev_a_eq_b, prev_a_less_b;


  // Логика сравнения
  // Числа равны сейчас, только если они были равны на предыдущем такте 
  // и равны их текущие биты
  assign a_eq_b      = prev_a_eq_b & (a == b);


  // a меньше b если текущий бит a меньше b, или если биты равны,
  // но на предыдущем такте a было меньше. 

  // Проверка на то, что а меньше b
  // ab ~ab ~a&b
  // 00  10  0
  // 01  11  1
  // 10  00  0
  // 11  01  0
  assign a_less_b    = (~ a & b) | (a == b & prev_a_less_b);

  // Если ни одна из проверок не прошла, значит а больше b
  assign a_greater_b = (~ a_eq_b) & (~ a_less_b);

  always_ff @ (posedge clk)
    if (rst)
    begin
      prev_a_eq_b   <= '1;
      prev_a_less_b <= '0;
    end
    else
    begin
      prev_a_eq_b   <= a_eq_b;
      prev_a_less_b <= a_less_b;
    end

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------
// У первого числа самый старший разряд 
module serial_comparator_most_significant_first
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // Task:
  // Implement a module that compares two numbers in a serial manner.
  // The module inputs a and b are (as) 1-bit digits of the two numbers to compare
  // and most significant bits are first.
  // The module outputs a_less_b, a_eq_b, and a_greater_b
  // should indicate whether a is less than, equal to, or greater than b, respectively.
  // The module should also use the clk and rst inputs.
  //
  // See the testbench for the output format ($display task).




logic prev_a_eq_b, prev_a_greater_b;



// Проверка на равенство остаётся такой же
assign a_eq_b = prev_a_eq_b & (a==b);

// a больше b если текущий бит a больше b, 
// или текущий бит a больше b, а предыдущие биты были равны

// или на предыдущем такте a было больше. 




// Проверка на то, что а больше b
// ab  a~b a&b
// 00  01  0
// 01  00  0
// 10  11  1
// 11  10  0
assign a_greater_b = ((a & ~b) & prev_a_eq_b) | (prev_a_greater_b);



assign a_less_b = (~ a_eq_b) & (~ a_greater_b);


always_ff @ (posedge clk)
    if (rst)
    begin
        prev_a_eq_b      <= '1;
        prev_a_greater_b <= '0;
    end
    else
    begin
        prev_a_eq_b      <= a_eq_b;
        prev_a_greater_b <= a_greater_b;
    end


endmodule
