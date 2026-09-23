source ../../synthesis/scripts/common/variables.tcl
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

foreach required_env {POWER_STAGE POWER_FREQ_TAG POWER_MODE} {
  if {![info exists ::env($required_env)]} {
    error "Variavel de ambiente obrigatoria ausente: $required_env"
  }
}

set power_stage $::env(POWER_STAGE)
set freq_tag $::env(POWER_FREQ_TAG)
set power_mode $::env(POWER_MODE)

if {$power_stage eq "synth"} {
  set input_netlist ${PROJECT_DIR}/backend/synthesis/deliverables/${DESIGNS}_${freq_tag}.v
} elseif {$power_stage eq "layout"} {
  set input_netlist ${PROJECT_DIR}/backend/layout/deliverables/${DESIGNS}_${freq_tag}_layout.v
} else {
  error "Etapa nao suportada: $power_stage"
}

if {![file exists $input_netlist]} {
  error "Netlist nao encontrada: $input_netlist"
}

set report_tag power_${power_mode}_${freq_tag}_${power_stage}
set report_file ${LAYOUT_DIR}/reports/${DESIGNS}_${report_tag}_power.rpt

set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO

read_mmmc ${LAYOUT_DIR}/scripts/${DESIGNS}.view
read_physical -lef $LEF_LIST
read_netlist $input_netlist
init_design

connect_global_net $NET_ONE -type pg_pin -pin_base_name $NET_ONE -inst_base_name *
connect_global_net $NET_ZERO -type pg_pin -pin_base_name $NET_ZERO -inst_base_name *

if {$power_mode ne "novcd"} {
  set activity_file ${PROJECT_DIR}/frontend/simulation/${report_tag}.vcd
  if {![file exists $activity_file]} {
    error "VCD nao encontrado: $activity_file"
  }
  read_activity_file -format VCD -scope multiplier32fp_tb.DUV $activity_file
}

report_power > $report_file
puts {FLOW PASS power}
exit
