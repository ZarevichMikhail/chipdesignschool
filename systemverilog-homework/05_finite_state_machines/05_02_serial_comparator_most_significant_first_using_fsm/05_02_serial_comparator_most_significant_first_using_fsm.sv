//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_comparator_least_significant_first_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // States
  enum logic[2:0]
  {
     st_a_less_b    = 3'b100,
     st_equal       = 3'b010,
     st_a_greater_b = 3'b001
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    // Мои пояснения из задания 2.5

    // Проверка на то, что а меньше b
    // (Это для состояний st_equal и st_a_greater_b)
    // ab ~ab ~a&b
    // 00  10  0
    // 01  11  1  // если st_eq и а меньше б, переход в состояние st_a_less_b
    //            // также если а больше б и потом а стало меньше, переход в состояние st_a_less_b
    // 10  00  0
    // 11  01  0

    // Проверка на то, что а больше b
    // ab  a~b a&~b
    // 00  01  0
    // 01  00  0
    // 10  11  1  // если st_eq и а больше б, переход в состояние st_a_greater_b
    //            // также, если а было меньше б st_a_less_b и б стало больше, переход в st_a_greater_b
    // 11  10  0

    case (state)
      st_equal       : if (~ a &   b) new_state = st_a_less_b;
                  else if (  a & ~ b) new_state = st_a_greater_b;
      st_a_less_b    : if (  a & ~ b) new_state = st_a_greater_b;
      st_a_greater_b : if (~ a &   b) new_state = st_a_less_b;
    endcase

    // verilator lint_on  CASEINCOMPLETE
  end

  // Output logic
  assign { a_less_b, a_eq_b, a_greater_b } = new_state;

  always_ff @ (posedge clk)
    if (rst)
      state <= st_equal;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_comparator_most_significant_first_using_fsm
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
  // Implement a serial comparator module similar to the previous exercise
  // but use the Finite State Machine to evaluate the result.
  // Most significant bits arrive first.


    // Такое же задание было в ДЗ 2.5

    // Самый старший бит идёт первым.
    // Это значит, что, если мы обнаружили, что а меньше б, то это состояние уже не может измениться. 
    // То есть из состояния st_a_less_b, st_a_greater_b выйти больше нельзя
    // По умолчанию числа могут начинаться с нулей, поэтому 
    // переход возможен только из состояния st_a_eq_b
    // Мои пояснения к нему



    // Проверка на то, что а меньше b
    // ab ~ab ~a&b
    // 00  10  0
    // 01  11  1  // если st_eq и а меньше б, переход в состояние st_a_less_b
    // 11  01  0

    // Проверка на то, что а больше b
    // ab  a~b a&~b
    // 00  01  0
    // 01  00  0
    // 10  11  1  // если st_eq и а больше б, переход в состояние st_a_greater_b
    // 11  10  0


    // Определение состояний (используем кодирование из примера)
    typedef enum logic [2:0]
    {
        st_a_less_b    = 3'b100,
        st_equal       = 3'b010,
        st_a_greater_b = 3'b001
    } state_e;

    state_e state, new_state;

    // Логика переходов
    always_comb begin
        new_state = state;

        case (state)
        // В состоянии st_equal ждем первого различия в битах
        st_equal       : if (~a & b) new_state = st_a_less_b;    
                    else if (a & ~b) new_state = st_a_greater_b; 

        // Из этих состояний уже нет перехода 
        st_a_less_b    : new_state = st_a_less_b;
        st_a_greater_b : new_state = st_a_greater_b;

        default: new_state = st_equal;
        endcase
    end

    assign { a_less_b, a_eq_b, a_greater_b } = new_state;


    always_ff @ (posedge clk) begin
    if (rst)
        state <= st_equal; 
    else
        state <= new_state;
    end

endmodule
