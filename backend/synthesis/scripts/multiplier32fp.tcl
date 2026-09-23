# Last update: 2026/05/14

#-----------------------------------------------------------------------------
# Load variables set in run_first.tcl
#-----------------------------------------------------------------------------
source ../../synthesis/scripts/common/variables.tcl

#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

#-----------------------------------------------------------------------------
# Load Tech File
#-----------------------------------------------------------------------------
source ${SCRIPT_DIR}/common/tech.tcl

#-----------------------------------------------------------------------------
# Analyze RTL source
#-----------------------------------------------------------------------------
set_db init_hdl_search_path "${FRONTEND_DIR}"
read_hdl -sv ${RTL_FILES}

#-----------------------------------------------------------------------------
# Elaborate Design
#-----------------------------------------------------------------------------
elaborate ${HDL_NAME}
set_top_module ${HDL_NAME}
check_design -unresolved ${HDL_NAME}
get_db current_design
check_library

#-----------------------------------------------------------------------------
# Constraints
#-----------------------------------------------------------------------------
read_sdc ${BACKEND_DIR}/synthesis/constraints/${HDL_NAME}_constraints.tcl
report timing -lint

#-----------------------------------------------------------------------------
# Post-elaborate attributes
#-----------------------------------------------------------------------------
set_db auto_ungroup none

#-----------------------------------------------------------------------------
# Generic optimization and mapping
#-----------------------------------------------------------------------------
syn_generic ${HDL_NAME}
syn_map ${HDL_NAME}
get_db insts .base_cell.name -u

#-----------------------------------------------------------------------------
# Reports and deliverables
#-----------------------------------------------------------------------------
set freq_mhz [expr {1000.0 / double(${period_clk})}]
if {[expr {abs($freq_mhz - round($freq_mhz))}] < 0.001} {
  set freq_tag [format "%dMHz" [expr {int(round($freq_mhz))}]]
} else {
  set freq_tag [format "%.3fMHz" $freq_mhz]
  regsub -all {\.} $freq_tag "p" freq_tag
}

report_design_rules > ${RPT_DIR}/${HDL_NAME}_${freq_tag}_drc.rpt
report_area > ${RPT_DIR}/${HDL_NAME}_${freq_tag}_area.rpt
report_timing > ${RPT_DIR}/${HDL_NAME}_${freq_tag}_timing.rpt
report_gates > ${RPT_DIR}/${HDL_NAME}_${freq_tag}_gates.rpt
report_qor > ${RPT_DIR}/${HDL_NAME}_${freq_tag}_qor.rpt

# Optional, externally supplied vendor workaround; never bundled with sources.
if {[info exists ::env(SDF_WORKAROUND)] && $::env(SDF_WORKAROUND) ne ""} {
  source $::env(SDF_WORKAROUND)
}
write_sdf -edge check_edge -nonegchecks -setuphold split -recrem split -version 3.0 -design ${HDL_NAME} > ${DEV_DIR}/${HDL_NAME}_${freq_tag}_worst_SPLIT.sdf
write_hdl ${HDL_NAME} > ${DEV_DIR}/${HDL_NAME}_${freq_tag}.v

puts {FLOW PASS synthesis}
exit
