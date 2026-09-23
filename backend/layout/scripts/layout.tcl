# Last update: 2026/06/17

source ../../synthesis/scripts/common/variables.tcl
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

set LAYOUT_RPT_DIR ${LAYOUT_DIR}/reports
set LAYOUT_DEV_DIR ${LAYOUT_DIR}/deliverables

file mkdir ${LAYOUT_RPT_DIR}
file mkdir ${LAYOUT_DEV_DIR}

set freq_mhz [expr {1000.0 / double(${period_clk})}]
if {[expr {abs($freq_mhz - round($freq_mhz))}] < 0.001} {
  set freq_tag [format "%dMHz" [expr {int(round($freq_mhz))}]]
} else {
  set freq_tag [format "%.3fMHz" $freq_mhz]
  regsub -all {\.} $freq_tag "p" freq_tag
}

set input_netlist ${PROJECT_DIR}/backend/synthesis/deliverables/${DESIGNS}_${freq_tag}.v
if {![file exists $input_netlist]} {
  error "Netlist de sintese nao encontrado: $input_netlist"
}

set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO

read_mmmc ${LAYOUT_DIR}/scripts/${DESIGNS}.view
read_physical -lef $LEF_LIST
read_netlist $input_netlist
init_design

connect_global_net $NET_ONE -type pg_pin -pin_base_name $NET_ONE -inst_base_name *
connect_global_net $NET_ZERO -type pg_pin -pin_base_name $NET_ZERO -inst_base_name *

create_floorplan -site CoreSite -core_density_size {1.0 0.70 10 10 10 10}

edit_pin -pin $LEFT_CORE_PINS -side LEFT -layer M3 -spread_type side
edit_pin -pin $TOP_CORE_PINS -side TOP -layer M2 -spread_type side
edit_pin -pin $RIGHT_CORE_PINS -side RIGHT -layer M3 -spread_type side
edit_pin -pin $BOTTOM_CORE_PINS -side BOTTOM -layer M2 -spread_type side

place_opt_design

create_clock_tree_spec -out_file ${LAYOUT_DIR}/work/ccopt.spec
source ${LAYOUT_DIR}/work/ccopt.spec
ccopt_design

route_design

set_db timing_analysis_type ocv
set_db timing_analysis_cppr both
set_db delaycal_enable_si false
time_design -post_route -report_dir ${LAYOUT_RPT_DIR}/${DESIGNS}_${freq_tag}_timing
report_timing > ${LAYOUT_RPT_DIR}/${DESIGNS}_${freq_tag}_timing.rpt
report_area > ${LAYOUT_RPT_DIR}/${DESIGNS}_${freq_tag}_area.rpt

write_netlist ${LAYOUT_DEV_DIR}/${DESIGNS}_${freq_tag}_layout.v
write_sdf ${LAYOUT_DEV_DIR}/${DESIGNS}_${freq_tag}_layout.sdf

puts {FLOW PASS layout}
exit
