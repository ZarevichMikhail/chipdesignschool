`timescale 1ns/1ps
module tb_audio_triangle();

  // Functions to save .wav file
  function automatic void write_wav_number;
    input int number;
    input int chars;
    input int fd;

    begin
      for (int i = 0; i < chars; i++) begin
        $fwrite(fd,"%c", number[7:0]);
        number = number >> 8;
      end
    end

  endfunction

  function automatic void write_wav;
    input int    sample_rate;
    input int    sample_bits;
    input int    sample_channels;
    input int    sample_num;
    input bit [7:0] sample_data [$];
    input string file;

    begin

      int fd;
      int byterate;
      int block_align;
      int subchunk2_size;
      int chunk_size;
      int bytes_per_sample;

      // Open file
      fd = $fopen(file, "wb");

      if (!fd)
        $display("Could not open file");

      // Calculate fields
      byterate       = (sample_rate * sample_channels * sample_bits)/8;
      block_align    = (sample_channels * sample_bits) / 8;
      subchunk2_size = (sample_num  * sample_channels * sample_bits)/8;
      chunk_size = 36 + subchunk2_size;

      bytes_per_sample = sample_bits / 8;

      // chunkId
      $fwrite(fd,"RIFF");

      // chunkSize
      write_wav_number(chunk_size, 4, fd);

      // format
      $fwrite(fd,"WAVE");

      // subchunk1Id
      $fwrite(fd,"fmt ");

      // subchunk1Size
      write_wav_number(16 , 4, fd);

      // audioFormat
      write_wav_number(1 , 2, fd);

      // numChannels
      write_wav_number(sample_channels , 2, fd);

      // sampleRate
      write_wav_number(sample_rate , 4, fd);

      // byteRate
      write_wav_number(byterate , 4, fd);

      // blockAlign
      write_wav_number(block_align, 2, fd);

      // bitsPerSample
      write_wav_number(sample_bits , 2, fd);

      // subchunk2Id
      $fwrite(fd,"data");

      // subchunk2Size
      write_wav_number(subchunk2_size , 4, fd);

      // data
      for (int i=0; i < sample_num; i++)
        write_wav_number(sample_data.pop_back(), bytes_per_sample, fd);

      // Close file
      $fclose(fd);

    end
  endfunction


  localparam DIV_48KHZ = 259;
  localparam DIV_48KHZ_WIDTH = $clog2(DIV_48KHZ);

  localparam FREQ_440HZ = 16'd4723;

  logic clk;
  logic rstn;

  bit [7:0] audio_data [$];

  int sample_rate;
  int sample_bits;
  int sample_channels;

  logic       sample_val;
  logic [7:0] sample_data;

  logic [DIV_48KHZ_WIDTH-1:0] clk_div_ff;
  logic [DIV_48KHZ_WIDTH-1:0] clk_div_next;

  // Generate 12.5 MHz clock
  initial clk <= 0;
  always #40ns clk <= ~clk;

  // Reset
  initial begin
    rstn <= 1'b0;
    repeat(2) @(posedge clk);
    rstn <= 1'b1;
  end


  initial begin
    sample_rate = 48000;
    sample_bits = 8;
    sample_channels = 1;

    repeat(12500000) @(posedge clk);

    write_wav(sample_rate,
              sample_bits,
              sample_channels,
              audio_data.size(),
              audio_data,
              "audio_triangle.wav"
              );

    $finish();
  end


  // Sample data at 48 KHz frequency for .wav file
  assign clk_div_next = (clk_div_ff == DIV_48KHZ) ? '0
                                                  : clk_div_ff + 1;

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn)
      clk_div_ff <= '0;
    else
      clk_div_ff <= clk_div_next;
  end

  assign sample_val = (clk_div_ff == DIV_48KHZ);

  always @ (posedge clk)
    if (sample_val) begin
      audio_data.push_front(sample_data);
    end


  // UUT
  audio_triangle UUT (
    .clk_i         (clk),
    .rstn_i        (rstn),
    .freq_i        (FREQ_440HZ),
    .sample_data_o (sample_data)
  );

endmodule
