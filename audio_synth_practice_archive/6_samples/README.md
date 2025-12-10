[Назад в оглавление](../README.md)

# Проигрывание сэмплов

Демонстрация проигрывания сэмплов находится в папке `audio_synth_practice/6_samples`.


## Запуск примера
Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/6_samples
do make.do
```

или выберите в Vivado `tb_sample` как Top Level.

## Описание примера

Идея построения музыки из сэмплов заключается в том, что если проигрывать один и тот же отрезок оцифрованного звука (например, аккорд) с разной скоростью, то он будет звучать с разными нотами. Чем выше скорость, тем выше тон звука. На этом эффекте построена без преувеличения вся электронная музыка.

![Alt text](../img/image-8.png)


Для корректного однократного проигрывания сэмпла используется внутренний автомат состояний, состояние которого хранится в `sample_actv_ff`.

```verilog
  // Sample state logics
  assign sample_actv_next = en_i                            ? '1
                          : (sample_ptr_ff == SAMPLE_LEN-1) ? '0
                          :                                   sample_actv_ff;

  assign sample_actv_en = en_i | freq_ofl;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      sample_actv_ff <= '0;
    else if (sample_actv_en)
      sample_actv_ff <= sample_actv_next;
  end
```

При получении строба `en_i` генератор безусловно начинает исполнять сэмпл сначала (даже если при получении `en_i` уже велось исполнение сэмпла). 

Если канал активен, то указатель на отсчёт сэмпла начинает нарастать с заданной в `freq_i` частотой до момента, пока не будет проигран весь сэмпл (его длина задаётся параметром `SAMPLE_LEN`). При окончании воспроизведения звука, `sample_actv_ff` сбрасывается в «0» и канал сэмпла уходит в состояние бездействия.

```verilog
  // Sample ptr logics
  assign sample_ptr_next = en_i                            ? '0
                         : (sample_ptr_ff == SAMPLE_LEN-1) ? '0
                         :                                   sample_ptr_ff + 1;

  assign sample_ptr_en = en_i
                       | (sample_actv_ff & freq_ofl);

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      sample_ptr_ff <= '0;
    else if (sample_ptr_en)
      sample_ptr_ff <= sample_ptr_next;
  end
```

Как и в случае с синусоидой, сэмпл хранится в памяти `sample_table`, которая инициализируется из файла `sample.mem`.

```verilog
  // Sample memory
  logic [7:0] sample_table [SAMPLE_LEN-1:0];

  initial begin
    $readmemh("sample.mem", sample_table);
  end

  assign sample_data_o = sample_table[sample_ptr_ff];
```

В демонстрации с помощью одного семпла проигрывается узнаваемое с пары нот вступление песни «Smoke on the water» группы Deep Purple. Мы пользуемся тем, что на самом деле это вступление состоит из одного аккорда, просто на разных частотах.
