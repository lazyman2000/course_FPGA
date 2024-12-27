create_clock -period 10.000 -name clk_100 [get_ports clk_100]
set_clock_uncertainty 1.000 [get_clocks clk_100]

set_input_delay -clock clk_100 -max 1.000 [get_ports [filter [all_inputs] {NAME !~ clk_100}]]
set_input_delay -clock clk_100 -min 1.000 [get_ports [filter [all_inputs] {NAME !~ clk_100}]]
set_output_delay -clock clk_100 -max 1.000 [get_ports [all_outputs]]
set_output_delay -clock clk_100 -min 1.000 [get_ports [all_outputs]]

connect_debug_port u_ila_0/probe0 [get_nets [list {i_sensor_top/i_dht11/data_buffer_reg[16]_0[0]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[1]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[2]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[3]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[4]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[5]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[6]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[7]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[8]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[9]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[10]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[11]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[12]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[13]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[14]} {i_sensor_top/i_dht11/data_buffer_reg[16]_0[15]}]]
connect_debug_port u_ila_0/probe3 [get_nets [list i_sensor_top/i_dht11_n_19]]





connect_debug_port u_ila_0/probe1 [get_nets [list {i_sensor_top/uart_tx[0]} {i_sensor_top/uart_tx[1]} {i_sensor_top/uart_tx[2]} {i_sensor_top/uart_tx[3]} {i_sensor_top/uart_tx[4]} {i_sensor_top/uart_tx[5]}]]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 131072 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_clock/clk_wiz_0/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_sensor_top/i_dht11/D[0]} {i_sensor_top/i_dht11/D[1]} {i_sensor_top/i_dht11/D[2]} {i_sensor_top/i_dht11/D[3]} {i_sensor_top/i_dht11/D[4]} {i_sensor_top/i_dht11/D[5]} {i_sensor_top/i_dht11/D[6]} {i_sensor_top/i_dht11/D[7]} {i_sensor_top/i_dht11/D[8]} {i_sensor_top/i_dht11/D[9]} {i_sensor_top/i_dht11/D[10]} {i_sensor_top/i_dht11/D[11]} {i_sensor_top/i_dht11/D[12]} {i_sensor_top/i_dht11/D[13]} {i_sensor_top/i_dht11/D[14]} {i_sensor_top/i_dht11/D[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe1]
set_property port_width 6 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_sensor_top/uart_tx[0]} {i_sensor_top/uart_tx[1]} {i_sensor_top/uart_tx[2]} {i_sensor_top/uart_tx[3]} {i_sensor_top/uart_tx[4]} {i_sensor_top/uart_tx[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list i_sensor_top/data_transaction_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list i_sensor_top/dht11_start]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
