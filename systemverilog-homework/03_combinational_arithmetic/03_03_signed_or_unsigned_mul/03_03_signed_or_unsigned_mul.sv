//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

// A non-parameterized module
// that implements the signed multiplication of 4-bit numbers
// which produces 8-bit result

module signed_mul_4
( 
   // signed - числа в дополнительном коде. 
  input  signed [3:0] a, b,
  output signed [7:0] res
);

    // Умножение * автоматически подстраивается под знаковое и беззнаковое число.  
  assign res = a * b;

endmodule

// A parameterized module
// that implements the unsigned multiplication of N-bit numbers
// which produces 2N-bit result

module unsigned_mul
# (
  parameter n = 8
)
(   // беззнаковое число 
  input  [    n - 1:0] a, b,
  output [2 * n - 1:0] res
);
    // Умножение работает как для беззнакового. 
  assign res = a * b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

// Task:
//
// Implement a parameterized module
// that produces either signed or unsigned result
// of the multiplication depending on the 'signed_mul' input bit.

module signed_or_unsigned_mul
# (
  parameter n = 8
)
(
    // На вход подаются беззнаковые числа. 
  input  [    n - 1:0] a, b,
  input                signed_mul,
  output [2 * n - 1:0] res
);


    logic [2 * n - 1:0] logic_res;
    assign res = logic_res;

    always_comb begin
        
        if(signed_mul == 1) begin
            // $signed() - функция преобразования числа в signed
            logic_res = $signed(a) * $signed(b);

        end else begin
            logic_res = a * b;

        end
    end



endmodule
