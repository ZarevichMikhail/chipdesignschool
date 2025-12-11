//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------


// Примеры показывают сдвиг битов влево
// 1111 << 2 = 1100

module left_shift_of_8_by_3_using_left_shift_operation (input  [7:0] a, output [7:0] res);

    // 1111 << 2 = 1100
  assign res = a << 3;

endmodule

// We are ignoring bits a[7:5] on purpose
// verilator lint_off UNUSEDSIGNAL

// Берём первые 5 битов и слева приписывает 3 нуля
module left_shift_of_8_by_3_using_concatenation (input  [7:0] a, output [7:0] res);
  
  assign res = { a [4:0], 3'b0 };

endmodule

// verilator lint_on UNUSEDSIGNAL

module left_shift_of_8_by_3_using_for_inside_always (input  [7:0] a, output logic [7:0] res);

    // Тут сделано через цикл 
    // в res 0 1 2 попадает 0
    // в res 3 попадает a[0] т.е. первый бит

  always_comb
    for (int i = 0; i < 8; i ++)
      res [i] = i < 3 ? 1'b0 : a [i - 3];

endmodule

// We are ignoring bits a[7:5] on purpose
// verilator lint_off UNUSEDSIGNAL

module left_shift_of_8_by_3_using_for_inside_generate (input  [7:0] a, output [7:0] res);

  genvar i;

  generate
    for (i = 0; i < 8; i ++)
      if (i < 3) begin : zero_bit_gen
        assign res [i] = 1'b0;
      end
      else begin : shifted_bit_gen
        assign res [i] = a [i - 3];
      end
  endgenerate

endmodule

// verilator lint_on UNUSEDSIGNAL

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module right_shift_of_N_by_S_using_right_shift_operation
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
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using logical right shift operation
    assign res = a >> S;


endmodule

// We are ignoring some bits on purpose
// verilator lint_off UNUSEDSIGNAL

module right_shift_of_N_by_S_using_concatenation
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
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using concatenation operation


    // {S{1'b0}} —  оператор повторения. 
    // создаёт S копий бита 0.
    // a[N-1 : S] — берем старшие биты, отрезая S младших.
    assign res = {{S{1'b0}}, a[N - 1 : S]};

endmodule

// verilator lint_on UNUSEDSIGNAL

module right_shift_of_N_by_S_using_for_inside_always
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
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using "for" inside "always_comb"
    
    // До сдвига
    // 8765 4321
    // 7654 3210
    // 1111 1111

    // После сдвига
    // 8765 4321
    // 7654 3210
    // 0001 1111
    // N-S = 8-3 = 5

    // на 5 месте стоит единициа с 8
    // res[5] = a[5+3] = a[5+S]
    // Если i до 5, то надо присваивать a[5+S]
    // Потом идут нули 

    always_comb begin
        for (int i = 0; i < N; i++) begin
            if(i < N - S)
                res[i] = a[i + S];
            else
                res[i] = 1'b0;
        end
  end

endmodule

module right_shift_of_N_by_S_using_for_inside_generate
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
  // Implement a parameterized module
  // that shifts the unsigned input by S bits to the right
  // using "generate" and "for"

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : loop_blk
            if (i >= N - S) begin : zero_padding
            assign res[i] = 1'b0;
        end
          else begin : data_shift
            assign res[i] = a[i + S];
          end
        end
  endgenerate


endmodule
