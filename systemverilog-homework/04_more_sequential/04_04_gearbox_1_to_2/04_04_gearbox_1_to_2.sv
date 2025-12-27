//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals

    
    // Мой код почему-то не работает. 
    // // Внутренний буфер для хранения первой половины данных
    // logic [width - 1:0] first_data;
    // logic [width - 1:0] second_data;
    // // Флаг фазы: 0 - ждем первую часть, 1 - ждем вторую
    // logic               phase;
    // logic turn;


    // logic [2 * width - 1:0] down_data_logic;
    // assign down_data = down_data_logic;

    // logic down_vld_logic;
    // assign down_vld = down_vld_logic;


    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         turn       <= 1'b0;
    //         first_data <= '0;
    //         second_data<= '0;

    //     end
    //     // Пришли данные и сейчас очередь первого. 
    //     else begin 
    //         if (up_vld == 1 & turn == 0) begin
    //         first_data     <= up_data;
    //         turn           <= 1'b1;
    //         down_vld_logic <= 1'b0;
    //         end
            
    //         // Пришли данные и сейчас очередь второго. 
    //         // Записывает в down_data все данные
    //         // обнуляет очередь. 
    //         else if (up_vld == 1 & turn == 1)begin

    //             second_data     <= up_data;
    //             down_data_logic <= {first_data, second_data};
    //             turn            <= 1'b0;
    //             down_vld_logic  <= 1'b1;
    //         end
    //     end
    // end

    // Внутренний буфер для хранения первой половины данных
    logic [width - 1:0] data_reg;
    // Флаг фазы: 0 - ждем первую часть, 1 - ждем вторую
    logic               phase;

    // Склеиваем накопленные данные (старшие) и текущие (младшие)
    assign down_data = {data_reg, up_data};

    // Валидность на выходе появляется комбинационно, 
    // когда мы находимся во второй фазе и на входе есть новые валидные данные
    assign down_vld = (up_vld && (phase == 1'b1));

    always_ff @(posedge clk) begin
        if (rst) begin
            phase    <= 1'b0;
            data_reg <= '0;

        end 
        else if (up_vld == 1) begin
            // Переключаем фазу только при наличии валидных данных на входе
            phase <= ~ phase;
            
            // Сохраняем первую порцию данных в регистр
            if (phase == 1'b0) begin
                data_reg <= up_data;
            end
        end
    end



   



endmodule
