[Назад в оглавление](../../README.md)

Данный пример генерирует псевдослучайный шум.

# Генератор псевдослучайного шума
Генератор псевдослучайного шума находится в папке `audio_synth_practice/1_wave_generators/6_noise`.

## Запуск примера

Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/1_wave_generators/6_noise
do make.do
```

или выберите в Vivado `tb_audio_noise` как Top Level.

## Описание примера

Генератор псевдослучайного шума построен по принципу сдвигового регистра с линейной обратной связью.

Регистр `noise_shiftreg_ff` на каждом шаге сдвигается на один бит влево, при этом с правой стороны в него задвигается результат XOR между 22 и 17 битами этого же регистра `(noise_shiftreg_ff[22] ^ noise_shiftreg_ff[17])`.

```verilog
  logic [22:0] noise_shiftreg_ff;
  logic [22:0] noise_shiftreg_next;
  logic [7:0] noise_output;

  localparam NOISE_SHREG_INIT = 22'h7FFFF8;

  // Shift register left
  // LSB is (bit22 ^ bit17)
  assign noise_shiftreg_next = {noise_shiftreg_ff[21:0],
                               (noise_shiftreg_ff[22] ^ noise_shiftreg_ff[17])};

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      noise_shiftreg_ff <= NOISE_SHREG_INIT;
    else if (freq_ofl)
      noise_shiftreg_ff <= noise_shiftreg_next;
  end
```

Далее на выход блока данные подаются в немного перетасованной форме:
```verilog
  // Select specific shift register bits for 8-bit output
  assign noise_output = {noise_shiftreg_ff[22],
                         noise_shiftreg_ff[20],
                         noise_shiftreg_ff[16],
                         noise_shiftreg_ff[13],
                         noise_shiftreg_ff[11],
                         noise_shiftreg_ff[7],
                         noise_shiftreg_ff[4],
                         noise_shiftreg_ff[2]};
```

Сочетание циклического сдвига с XOR и перетасовки данных на выходе обеспечивает генерацию сигнала, очень похожего на случайный. Такой сигнал наши уши воспринимают как шум.

Для программистов алгоритм работы генератора можно описать следующим листингом на языке Си:

```c
/* Test a bit. Returns 1 if bit is set. */
long bit(long val, byte bitnr) {
  return (val & (1<<bitnr))? 1:0;
}


/* Generate output from noise-waveform */
void Noisewaveform {
  long bit22;	/* Temp. to keep bit 22 */
  long bit17;	/* Temp. to keep bit 17 */

  long reg= 0x7ffff8; /* Initial value of internal register*/

  /* Repeat forever */
  for (;;;) {

    /* Pick out bits to make output value */
    output = (bit(reg,22) << 7) |
	     (bit(reg,20) << 6) |
	     (bit(reg,16) << 5) |
	     (bit(reg,13) << 4) |
	     (bit(reg,11) << 3) |
	     (bit(reg, 7) << 2) |
	     (bit(reg, 4) << 1) |
	     (bit(reg, 2) << 0);

    /* Save bits used to feed bit 0 */
    bit22= bit(reg,22);
    bit17= bit(reg,17);

    /* Shift 1 bit left */
    reg= reg << 1;

    /(* Feed bit 0 */
    reg= reg | (bit22 ^ bit17);
  };
};
```

> Интересный факт заключается в том, что представленный генератор шума является полной копией генератора шума из микросхемы SID, структура генератора была получена в результате реверс-инжиниринга (http://www.sidmusic.org/sid/sidtech5.html).

Также стоит отметить неочевидный момент: выдаваемый генератором шума звук меняется при изменении частоты `freq_i`, так как меняется спектр шума.
