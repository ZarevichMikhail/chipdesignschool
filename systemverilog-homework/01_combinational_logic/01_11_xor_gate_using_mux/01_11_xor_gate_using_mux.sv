//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

// Импорт модуля из 8 задания.
`include "/home/zarevichmikhail/chipdesignschool/systemverilog-homework/01_combinational_logic/01_08_not_gate_using_mux/01_08_not_gate_using_mux.sv"


// Переименовал этот модуль, так как mux уже есть в 8 задании
module mux11
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections


    // Таблица истинности для исключающего ИЛИ
    // a b a^b
    // 0 0 0
    // 0 1 1
    // 1 0 1
    // 1 1 0

    // Таблицу можно интерпретировать так:
    // если а = 0, на выходе b
    // если a = 1, на выходе не b
    
    // В задании 8 нужно было сделать функцию "НЕ"
    // Я решил взять её оттуда

    // Провод, содержащий сигнал с мультиплексора not_gate
    logic not_b;

    // Сделал не б на этом мультиплексоре
    // mux11 not_gate(
    //     .d0(1'b1),  
    //     .d1(1'b0),  
    //     .sel(b),    
    //     .y(not_b)      
    //   );

    
    // Использую модуль из 8 задания
    // В качестве input подаём b, на выходе output получаем not_b
    not_gate_using_mux not_gate ( .i(b), .o(not_b));

    
    mux11 xor_gate (
        .d0(b),  
        .d1(not_b), // Если а = 1, берёт сигнал с мультиплексора not_gate
        .sel(a),    
        .y(o)       
      );
    



endmodule
