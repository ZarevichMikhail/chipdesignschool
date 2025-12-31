//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Detection of the "1010" sequence

  // States (F — First, S — Second)
  enum logic[2:0]
  {
     IDLE = 3'b000,
     F1   = 3'b001,
     F0   = 3'b010,
     S1   = 3'b011,
     S0   = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      IDLE: if (  a) new_state = F1;
      F1:   if (~ a) new_state = F0;
      F0:   if (  a) new_state = S1;
            else     new_state = IDLE;
      S1:   if (~ a) new_state = S0;
            else     new_state = F1;
      S0:   if (  a) new_state = S1;
            else     new_state = IDLE;
    endcase

    // verilator lint_on CASEINCOMPLETE

  end

  // Output logic (depends only on the current state)
  assign detected = (state == S0);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

    // Task:
    // Implement a module that detects the "110011" input sequence
    //
    // Hint: See Lecture 3 for details

    // Задание нужно выполнять немного не так, как мы проходили на лекциях
    // Тут в тестбенче могут быть перекрывающиеся последовательности
    // Пример
    // Наша последовательность: 
    // 654321 
    // 110011

    // 1100111 - три единицы в начале, под неё подходит. 
    // Т.е. когда мы встретим третью единицу, нужно не сбрасывать автомат,
    // а переходить в состояние 2,

    // Дальше, если мы находимся в состоянии 3 и пришла единица,
    // нужно переходить не в 0, а в 1. т.к. это может быть началом новой последовательности.

    // Когда мы в последнем состоянии 6 - у нас уже было две единицы подряд
    // что может быть началом новой последовательности.
    // Т.е. если придёт 1 - переходим в 2
    // а если 0 - в 3. 
    

    // Определение состояний 
    typedef enum logic [2:0] {
    S0 = 3'b000,
    S1 = 3'b001,
    S2 = 3'b010,
    S3 = 3'b011,
    S4 = 3'b100,
    S5 = 3'b101,
    S6 = 3'b110
    } state_e;

    state_e state, next_state;


    always_comb begin
        next_state = state; // Начальное состояние
        // 654321 
        // 110011
        case (state)
            S0: if ( a) next_state = S1; else next_state = S0;
            S1: if ( a) next_state = S2; else next_state = S0;
            S2: if (~a) next_state = S3; else next_state = S2; 
            S3: if (~a) next_state = S4; else next_state = S1;
            S4: if ( a) next_state = S5; else next_state = S0;
            S5: if ( a) next_state = S6; else next_state = S0;
            S6: if ( a) next_state = S2; else next_state = S3;
            default: next_state = S0;

        endcase
    end


    assign detected = (state == S6);

    always_ff @(posedge clk) begin
        if (rst)
          state <= S0;
        else
            state <= next_state;
    end


endmodule
