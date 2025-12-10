vlib work
vmap work

vlog  ../1_wave_generators/1_square/audio_square.sv
vlog  ../1_wave_generators/2_saw/audio_saw.sv
vlog  ../1_wave_generators/3_saw_inv/audio_saw_inv.sv
vlog  ../1_wave_generators/4_triangle/audio_triangle.sv
vlog  ../1_wave_generators/5_sine/audio_sine.sv
vlog  ../1_wave_generators/6_noise/audio_noise.sv

vlog  ../2_audio_channel/audio_channel.sv

vlog audio_multichannel.sv

vlog  tb_music_multichannel.sv

vsim  tb_music_multichannel

# add log -r /*


# run -all
