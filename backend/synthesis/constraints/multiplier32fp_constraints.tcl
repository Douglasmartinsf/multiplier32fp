set DESIGN_NAME multiplier32fp
set MAIN_CLOCK_NAME clk
set MAIN_RST_NAME rst_n

set BEST_LIB_OPERATING_CONDITION PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C

# Override period_clk before sourcing this file when searching for Fmax.
if {![info exists period_clk]} {
  set period_clk 4.000
}

set clk_uncertainty 0.05
set clk_latency 0.10
set in_delay 0.30
set out_delay 0.30
set out_load 0.045
set slew "146 164 264 252"
set slew_min_rise 0.146
set slew_min_fall 0.164
set slew_max_rise 0.264
set slew_max_fall 0.252

create_clock -name $MAIN_CLOCK_NAME -period $period_clk [get_ports $MAIN_CLOCK_NAME]
set_clock_uncertainty $clk_uncertainty [get_clocks $MAIN_CLOCK_NAME]
set_clock_latency $clk_latency [get_clocks $MAIN_CLOCK_NAME]

set data_inputs [remove_from_collection [all_inputs] [get_ports [list $MAIN_CLOCK_NAME $MAIN_RST_NAME]]]
set data_outputs [all_outputs]

set_input_delay $in_delay -clock [get_clocks $MAIN_CLOCK_NAME] $data_inputs
set_output_delay $out_delay -clock [get_clocks $MAIN_CLOCK_NAME] $data_outputs

set_load $out_load $data_outputs

set_input_transition -rise -min $slew_min_rise $data_inputs
set_input_transition -fall -min $slew_min_fall $data_inputs
set_input_transition -rise -max $slew_max_rise $data_inputs
set_input_transition -fall -max $slew_max_fall $data_inputs

set_false_path -from [get_ports $MAIN_RST_NAME]
