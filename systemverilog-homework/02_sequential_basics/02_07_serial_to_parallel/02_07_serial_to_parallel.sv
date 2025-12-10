//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts single-bit serial data to the multi-bit parallel value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits and receiving last 'serial_valid' input,
    // the module should assert the 'parallel_valid' at the same clock cycle
    // and output 'parallel_data' value.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.


    // Судя по картинке нужно сделать следующее
    // serial_data - поток данных, последовательность 01...
    // serial_valid - разрешающий вход. В 8-битный сигнал parallel_data 
    // данные записываются только когда и тут 1 и в serial_data 1.
    // когда накопилось 8 единиц. Нужно выдать единицу на parallel_valid
    // и сигнал parallel_data


    // Счётчик записанных цифр. 
    // Текущий индекс записанного числа 
    logic [$clog2(width)-1:0] cnt;
    
    // Полученные биты
    logic [width-1:0] received_bits;


    always_ff @(posedge clk) begin
        if (rst) begin
            cnt            <= '0;
            received_bits  <= '0;
            parallel_valid <= '0;
            parallel_data  <= '0;
        end else if (serial_valid) begin

            
            // Сдвиг битов вправо. 
            // Первый бит записывается в [7], затем, когда приходит следующий бит
            // тот переходит в 7 а старый - в 6. 
            //received_bits <= {serial_data, received_bits[width-1:1]};
            

            // Записывает число
            received_bits[cnt] <= serial_data;

            // Проверка того является ли бит с serial_data последним
            if (cnt == width - 1) begin
                
                // Выдаёт нужные сигналы
                parallel_valid <= 1'b1;
                //parallel_data  <= {serial_data, received_bits[width-1:1]};
                parallel_data <= received_bits;
                parallel_data[cnt] <=serial_data;
                
                // Сброс счётчика 
                cnt <= '0;
            end else begin
                
                parallel_valid <= 1'b0;
                cnt <= cnt + 1;
            end
        end else begin
            
            parallel_valid <= 1'b0;
        end
    end

endmodule
