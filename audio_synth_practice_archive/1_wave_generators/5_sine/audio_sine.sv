module audio_sine(
  input  logic        clk_i,
  input  logic        rstn_i,
  input  logic [15:0] freq_i,
  output logic [7:0]  sample_data_o
);

  // Frequency counter
  localparam FREQ_CNT_WIDTH = 19;

  logic [FREQ_CNT_WIDTH-1:0] freq_counter_ff;
  logic [FREQ_CNT_WIDTH-1:0] freq_counter_next;

  assign freq_counter_next = freq_counter_ff + (freq_i << 1); // As triangle takes 512 samples, we multiply frequency by 2

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


  // Triangle signal generation

  logic [7:0] saw_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_ff <= '0;
    else if (freq_ofl)
      saw_ff <= saw_ff + 1;
  end


  logic [7:0] saw_inv_ff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_inv_ff <= '1;
    else if (freq_ofl)
      saw_inv_ff <= saw_inv_ff - 1;
  end

  logic saw_select_ff;
  logic saw_select_en;

  assign saw_select_en = freq_ofl & (saw_ff == 8'hff);

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i)
      saw_select_ff <= '0;
    else if (saw_select_en)
      saw_select_ff <= ~saw_select_ff;
  end

  logic [7:0] triangle;
  assign triangle = saw_select_ff ? saw_inv_ff
                                  : saw_ff;

  // Sine table, triange uses as an address
  logic [7:0] sine_table [255:0];

  initial begin
    $readmemh("sine_table_256.mem", sine_table);
  end

  assign sample_data_o = sine_table[triangle];

endmodule
