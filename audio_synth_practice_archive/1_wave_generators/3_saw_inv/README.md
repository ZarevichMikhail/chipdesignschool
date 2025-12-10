[Назад в оглавление](../../README.md)
# Генератор сигнала обратной пилообразной формы
![Alt text](../../img/image-3.png)

Данный пример генерирует звуковой сигнал обратной пилообразной формы с частотой 440 Гц.

Пример генератора сигнала пилообразной формы находится в папке `audio_synth_practice/1_wave_generators/3_saw_inv`.

## Запуск примера
Чтобы запустить тестбенч, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/1_wave_generators/3_saw_inv
do make.do
```

или выберите в Vivado `tb_audio_saw_inv` как Top Level.

## Описание примера

Генератор сигнала обратной пилообразной формы отличается от генератора пилы только отрицательным направлением счёта регистра `saw_inv_ff`.

```verilog
  // Saw signal generation
  logic [7:0] saw_inv_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_inv_ff <= '1;
    else if (freq_ofl)
      saw_inv_ff <= saw_inv_ff - 1;
  end

  assign sample_data_o = saw_inv_ff;
```
