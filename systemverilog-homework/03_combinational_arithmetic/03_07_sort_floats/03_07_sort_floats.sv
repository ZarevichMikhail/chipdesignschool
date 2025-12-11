//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res2
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.



    // Нужно сначала сравнить 0 и 1
    // большее из них сравниваем с 2, получаем самое большое число. 

    // Затем меньшее число из второго сравнения сравниваем с первым,
    // чтобы получить самое маленькое. 

    // TODO:
    // Не знаю, как тут сделать более оптимизированный вариант. 
    // когда мы сравниваем число с 2, может быть так, что 2 - самое большое
    // и тогда снова придётся сравнивать 0 и 1. 
    // Надо добавить проверку на это. 


    // Сигналы ошибок для каждого сравнения
    logic err1, err2, err3;
    assign err = err1 | err2 | err3;

    // Результаты сравнения
    logic u0_less_or_equal_u1;
    logic u1_less_or_equal_u2;
    logic u0_less_or_equal_u2;
    
    // Промежуточные переменные для хранения значений после перестановок
    logic [FLEN - 1:0] min_01, max_01;
    logic [FLEN - 1:0] mid_temp;

    
    // Сравнение 0 и 1
    f_less_or_equal cmp1 (
        .a   ( unsorted[0] ),
        .b   ( unsorted[1] ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err1        )
    );

    always_comb begin
        if (u0_less_or_equal_u1 == 1) begin
            min_01 = unsorted[0];
            max_01 = unsorted[1];
        end else begin
            min_01 = unsorted[1];
            max_01 = unsorted[0];
        end
    end

   
   
    // Сравнение большего из этих чисел с 2
    f_less_or_equal cmp2 (
        .a   ( max_01      ),
        .b   ( unsorted[2] ),
        .res ( u1_less_or_equal_u2      ),
        .err ( err2        )
    );

    always_comb begin
        if (u1_less_or_equal_u2 == 1) begin 
            mid_temp  = max_01;       // max_01 меньше unsorted[2]
            sorted[2] = unsorted[2];  // Значит unsorted[2] - самый большой
        end else begin
            mid_temp  = unsorted[2];  // unsorted[2] меньше max_01
            sorted[2] = max_01;       // Значит max_01 - самый большой
        end
    end

    
    // Третье сравнение 
    // Меньшее из второго сравнивается с первым
    // Тут может быть так, что мы снова сравниваем первые два числа. 
    f_less_or_equal cmp3 (
        .a   ( min_01   ),
        .b   ( mid_temp ),
        .res ( u0_less_or_equal_u2   ),
        .err ( err3     )
    );

    always_comb begin
        if (u0_less_or_equal_u2 == 1) begin
            sorted[0] = min_01;
            sorted[1] = mid_temp;
        end else begin
            sorted[0] = mid_temp;
            sorted[1] = min_01;
        end
    end







endmodule
