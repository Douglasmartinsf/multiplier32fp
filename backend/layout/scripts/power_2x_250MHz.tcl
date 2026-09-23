source ../../synthesis/scripts/common/variables.tcl
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

set freq_tag 250MHz
set power_tag power_2x_250MHz_layout
set LAYOUT_RPT_DIR ${LAYOUT_DIR}/reports
set LAYOUT_DEV_DIR ${LAYOUT_DIR}/deliverables
set ACTIVITY_FILE ${PROJECT_DIR}/frontend/simulation/${power_tag}.vcd
set input_netlist ${LAYOUT_DEV_DIR}/${DESIGNS}_${freq_tag}_layout.v

if {![file exists $input_netlist]} {
  error "Netlist de layout nao encontrado: $input_netlist"
}

if {![file exists $ACTIVITY_FILE]} {
  error "VCD de atividade nao encontrado: $ACTIVITY_FILE"
}

set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO

read_mmmc ${LAYOUT_DIR}/scripts/${DESIGNS}.view
read_physical -lef $LEF_LIST
read_netlist $input_netlist
init_design

connect_global_net $NET_ONE -type pg_pin -pin_base_name $NET_ONE -inst_base_name *
connect_global_net $NET_ZERO -type pg_pin -pin_base_name $NET_ZERO -inst_base_name *

read_activity_file -format VCD -scope multiplier32fp_tb.DUV $ACTIVITY_FILE

report_power > ${LAYOUT_RPT_DIR}/${DESIGNS}_${power_tag}_power.rpt
exit
