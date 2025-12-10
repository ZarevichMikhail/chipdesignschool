[Назад в оглавление](../../README.md)

# Генератор сигнала треугольной формы

![Alt text](../../img/image-4.png)

Данный пример генерирует звуковой сигнал треугольной формы с частотой 440 Гц.

Генератор сигнала треугольной формы находится в папке `audio_synth_practice/1_wave_generators/4_triangle`.

## Запуск примера
Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/1_wave_generators/4_triangle
do make.do
```

или выберите в Vivado `tb_audio_triangle` как Top Level.

## Описание примера

Данный генератор содержит в себе логику пилы и обратной пилы, а также регистр `saw_select_ff`, управляющий переключением между двумя пилами.

```verilog
  logic [7:0] saw_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_ff <= '0;
    else if (freq_ofl)
      saw_ff <= saw_ff + 1;
  end
```


```verilog
  logic [7:0] saw_inv_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_inv_ff <= '1;
    else if (freq_ofl)
      saw_inv_ff <= saw_inv_ff - 1;
  end
```

```verilog
  logic saw_select_ff;
  logic saw_select_en;

  assign saw_select_en = freq_ofl & (saw_ff == 8'hff);


  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_select_ff <= '0;
    else if (saw_select_en)
      saw_select_ff <= ~saw_select_ff;
  end


  assign sample_data_o = saw_select_ff ? saw_inv_ff
                                       : saw_ff;
```

Таким образом, для формирования треугольника мы используем нарастающую часть обычный пилы и нисходящую часть обратной пилы.
Важно отметить, что длина сигнала треугольной формы при таком подходе получается равной 512 отчетам. Для того, чтобы частота совпадала с другими генераторами, нам необходимо с помощью сдвига влево умножить значение `freq_i` на два.

```verilog
  assign freq_counter_next = freq_counter_ff + (freq_i << 1); // As triangle takes 512 samples, we multiply frequency by 2
```
