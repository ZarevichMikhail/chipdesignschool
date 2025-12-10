[Назад в оглавление](../../README.md)
# Генератор сигнала пилообразной формы
![Alt text](../../img/image-2.png)

Данный пример генерирует пилообразный звуковой сигнал с частотой 440 Гц.

Пример генератора сигнала пилообразной формы находится в папке `audio_synth_practice/1_wave_generators/2_saw`.


## Запуск примера
Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/1_wave_generators/2_saw
do make.do
```

или выберите в Vivado `tb_audio_saw` как Top Level.

## Описание примера

Генератор сигнала пилообразной формы отличается от генератора меандра только тем, что регистр (счётчик меандра) заведён на звуковой выход полностью, а не только в виде старшего бита.
```verilog
  // Saw signal generation
  logic [7:0] saw_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_ff <= '0;
    else if (freq_ofl)
      saw_ff <= saw_ff + 1;
  end

  assign sample_data_o = saw_ff;
```
