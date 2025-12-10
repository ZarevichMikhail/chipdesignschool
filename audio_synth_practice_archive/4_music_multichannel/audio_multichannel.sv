module audio_multichannel
(
  input  logic        clk_i,
  input  logic        rstn_i,

  input  logic        ch0_en_i,
  input  logic [2:0]  ch0_gen_sel_i,
  input  logic [15:0] ch0_freq_i,
  input  logic [7:0]  ch0_volume_i,

  input  logic        ch1_en_i,
  input  logic [2:0]  ch1_gen_sel_i,
  input  logic [15:0] ch1_freq_i,
  input  logic [7:0]  ch1_volume_i,

  output logic [7:0]  sample_data_o
);

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

  assign sample_data_o = channels_mixed;

endmodule
