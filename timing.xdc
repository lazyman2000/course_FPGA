create_clock -period 10.000 -name clk_100 [get_ports clk_100]
set_clock_uncertainty 1.000 [get_clocks clk_100]

set_input_delay -clock clk_100 -max 1.000 [get_ports [filter [all_inputs] {NAME !~ clk_100}]]
set_input_delay -clock clk_100 -min 1.000 [get_ports [filter [all_inputs] {NAME !~ clk_100}]]
set_output_delay -clock clk_100 -max 1.000 [get_ports [all_outputs]]
set_output_delay -clock clk_100 -min 1.000 [get_ports [all_outputs]]



