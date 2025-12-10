//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_adder
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output sum
);

  // Note:
  // carry_d represents the combinational data input to the carry register.


  // carry bit - входной бит переноса 
  logic carry; 

  // Выходной бит переноса
  wire carry_d;
   
  // 
  assign { carry_d, sum } = a + b + carry;

  // 1+1 = 10
  // carry_d = 1, sum = 0
  // Потом в блоке always ff Значение carry d присвоится в carry. 

  always_ff @ (posedge clk)
    if (rst)
      carry <= '0;
    else
      carry <= carry_d;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_adder_using_logic_operations_only
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output sum
);

  // Task:
  // Implement a serial adder using only ^ (XOR), | (OR), & (AND), ~ (NOT) bitwise operations.
  //
  // Notes:
  // See Harris & Harris book
  // or https://en.wikipedia.org/wiki/Adder_(electronics)#Full_adder webpage
  // for information about the 1-bit full adder implementation.
  //
  // See the testbench for the output format ($display task).


    // serial adder - побитовое сложение


    // Регистр для хранения переноса между битами (тактами)
    logic carry;
    
    // Провод для комбинационного сигнала нового переноса (вход для регистра)
    wire carry_d;

    // Логика 1-битного полного сумматора:
    
    // Сумма = a XOR b XOR carry_in

    // 0^0 = 0
    // 0^1 = 1^0 = 1
    // 1^1 = 0
    // (1^1)^0 = 0

    // sum будет 1, только если одна единица
    // 0 единиц это 0
    // 2 единицы - будет перенос
    assign sum = a ^ b ^ carry;

    // перенос может возникнуть, если два любых слагаемых равны единице
    assign carry_d = (a & b) | (a & carry) | (b & carry);

    always_ff @ (posedge clk)
        if (rst)
            carry <= '0;
        else
            carry <= carry_d;


endmodule
