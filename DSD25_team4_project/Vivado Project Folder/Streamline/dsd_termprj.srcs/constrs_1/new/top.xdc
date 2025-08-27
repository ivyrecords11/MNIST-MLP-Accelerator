##Clock signal
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports clk]

#Buttons
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports start_i]

#LEDs
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports done_led_o]

##Switches
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports rst_n]

set_property use_dsp NO [get_cells -hierarchical *TREE_LEVEL*]
