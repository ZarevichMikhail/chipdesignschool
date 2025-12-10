//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module posedge_detector (input clk, rst, a, output detected);

   
  // Значение на предыдущем такте
  logic a_r;

  // Note:
  // The a_r flip-flop input value d propogates to the output q
  // only on the next clock cycle.

  always_ff @ (posedge clk)
    if (rst)
      a_r <= '0;
    else
      // Присваивает значение предыдущего такта
      a_r <= a;

  // Условие срабатывает, когда на предыдущем такте был 0
  // а на текущем - 1
  assign detected = ~ a_r & a;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module one_cycle_pulse_detector (input clk, rst, a, output detected);

  // Task:
  // Create an one cycle pulse (010) detector.
  //
  // Note:
  // See the testbench for the output format ($display task).


    logic a_r1; // 'a' значение на 1 предыдущем такте
    logic a_r2; // 'a' значение на 2 предыдущем такте


    always_ff @ (posedge clk)
    if (rst) begin
      a_r1 <= '0;
      a_r2 <= '0;
    end 
    else begin
      a_r1 <= a;     
      a_r2 <= a_r1;  
    end

    // Последовательность, которую нужно выявить
    //                  0      1      0
    assign detected = ~a_r2 & a_r1 & ~a;







  


endmodule
