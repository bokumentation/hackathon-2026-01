create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[0]}]
set_false_path -from [get_ports {SW[*]}]
set_false_path -from [get_ports {gpio_frame_bit}]
set_false_path -from [get_ports {gpio_load_en}]
set_false_path -from [get_ports {gpio_fault_ack}]
