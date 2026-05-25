close_sim -force
reset_simulation -simset sim_1 -mode behavioral
launch_simulation
add_wave /tb_top_dds_wavegen/dut/u_wave_select/wave_sel
add_wave /tb_top_dds_wavegen/dut/u_dds_core_fixed/wave_sel
add_wave /tb_top_dds_wavegen/dut/u_dds_core_fixed/square_data
add_wave /tb_top_dds_wavegen/dut/u_dds_core_fixed/triangle_data
add_wave /tb_top_dds_wavegen/dut/u_dds_core_fixed/wave_data
add_wave /tb_top_dds_wavegen/dbg_square_bit
run 110 us
