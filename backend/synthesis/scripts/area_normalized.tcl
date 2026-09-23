source ../../synthesis/scripts/common/variables.tcl
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl
source ${PROJECT_DIR}/backend/synthesis/scripts/common/tech.tcl

foreach required_env {AREA_STAGE AREA_FREQ_TAG} {
  if {![info exists ::env($required_env)]} {
    error "Variavel de ambiente obrigatoria ausente: $required_env"
  }
}

set area_stage $::env(AREA_STAGE)
set freq_tag $::env(AREA_FREQ_TAG)

if {$area_stage eq "synth"} {
  set input_netlist ${PROJECT_DIR}/backend/synthesis/deliverables/${DESIGNS}_${freq_tag}.v
  set output_dir ${PROJECT_DIR}/backend/synthesis/reports
} elseif {$area_stage eq "layout"} {
  set input_netlist ${PROJECT_DIR}/backend/layout/deliverables/${DESIGNS}_${freq_tag}_layout.v
  set output_dir ${PROJECT_DIR}/backend/layout/reports
} else {
  error "Etapa nao suportada: $area_stage"
}

if {![file exists $input_netlist]} {
  error "Netlist nao encontrada: $input_netlist"
}

read_hdl $input_netlist
elaborate $DESIGNS
set_top_module $DESIGNS

report_area -normalize_with_gate NAND2X1 > ${output_dir}/${DESIGNS}_${freq_tag}_area_normalized.rpt
exit
