create_clock -period 5.000 -name clk_i -waveform {0.000 2.500} [get_ports iface\\.clk_i]
create_generated_clock -name clk_div_0 -source [get_ports iface\\.clk_i] -divide_by 4 [get_pins gen_clk_buf[0].I_clk_buf/O]
create_generated_clock -name clk_div_1 -source [get_ports iface\\.clk_i] -divide_by 4 [get_pins gen_clk_buf[1].I_clk_buf/O]
create_generated_clock -name clk_div_2 -source [get_ports iface\\.clk_i] -divide_by 4 [get_pins gen_clk_buf[2].I_clk_buf/O]
create_generated_clock -name clk_div_3 -source [get_ports iface\\.clk_i] -divide_by 4 [get_pins gen_clk_buf[3].I_clk_buf/O]
