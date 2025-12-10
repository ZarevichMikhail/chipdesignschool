module audio_sample(
  input  logic        clk_i,
  input  logic        rstn_i,
  input  logic        en_i,
  input  logic [15:0] freq_i,
  output logic [7:0]  sample_data_o
);

  // Frequency counter
  localparam FREQ_CNT_WIDTH = 19;

  logic [FREQ_CNT_WIDTH-1:0] freq_counter_ff;
  logic [FREQ_CNT_WIDTH-1:0] freq_counter_next;

  assign freq_counter_next = freq_counter_ff + freq_i;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      freq_counter_ff <= '0;
    else
      freq_counter_ff <= freq_counter_next;
  end

  logic freq_msb_dly_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      freq_msb_dly_ff <= '0;
    else
      freq_msb_dly_ff <= freq_counter_ff[FREQ_CNT_WIDTH-1];
  end

  logic freq_ofl;
  assign freq_ofl = ~freq_counter_ff[FREQ_CNT_WIDTH-1] & freq_msb_dly_ff;


  localparam SAMPLE_LEN = 24322;
  localparam SAMPLE_PTR_WIDTH = $clog2(SAMPLE_LEN);


  logic                        sample_actv_ff;
  logic                        sample_actv_next;
  logic                        sample_actv_en;

  logic [SAMPLE_PTR_WIDTH-1:0] sample_ptr_ff;
  logic [SAMPLE_PTR_WIDTH-1:0] sample_ptr_next;
  logic                        sample_ptr_en;

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

  // Sample memory
  logic [7:0] sample_table [SAMPLE_LEN-1:0];

  initial begin
    $readmemh("sample.mem", sample_table);
  end

  assign sample_data_o = sample_table[sample_ptr_ff];

endmodule
