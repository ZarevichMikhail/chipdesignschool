[Назад в оглавление](../README.md)

# Проигрывание простой музыки на двух звуковых каналах
Демонстрация проигрывания простой музыки на звуковом канале находится в папке `audio_synth_practice/4_music_multichannel`.

## Запуск примера

Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/4_music_multichannel
do make.do
```

или выберите в Vivado `tb_music_multichannel` как Top Level.

## Описание примера

Эта демонстрация добавляет к предыдущему примеру второй звуковой канал и простое микширование между двумя каналами.

```verilog
  logic [7:0] ch0_output;
  logic [7:0] ch1_output;

  audio_channel i_channel0 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .en_i          (ch0_en_i),
    .gen_sel_i     (ch0_gen_sel_i),
    .freq_i        (ch0_freq_i),
    .volume_i      (ch0_volume_i),
    .sample_data_o (ch0_output)
  );


  audio_channel i_channel1 (
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .en_i          (ch1_en_i),
    .gen_sel_i     (ch1_gen_sel_i),
    .freq_i        (ch1_freq_i),
    .volume_i      (ch1_volume_i),
    .sample_data_o (ch1_output)
  );
```

Микширование выполнено по следующей схеме: если активен один из каналов, то уровень активного канала передаётся на выход без изменений. Если же активны оба канала, то на выход передаётся среднее арифметическое их уровней.

```verilog
  // Simple channel mixing
  logic [8:0] channels_summ;
  logic [7:0] channels_mixed;

  assign channels_summ = (ch0_output + ch1_output);

  always_comb
  case({ch0_en_i, ch1_en_i})
    2'b10: channels_mixed = ch0_output;
    2'b01: channels_mixed = ch1_output;
    2'b11: channels_mixed = channels_summ >> 1;
    default: channels_mixed = '0;
  endcase
```

Тестбенч построен так, что на обоих каналах играются одинаковые ноты, но разными генераторами, с целью получения более «интересного» звука и отличается от предыдущего примера несущественно.
