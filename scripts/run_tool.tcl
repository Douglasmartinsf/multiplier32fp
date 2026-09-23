# Make Tcl failures visible to the batch caller instead of remaining at a prompt.
if {![info exists ::env(FLOW_SCRIPT)]} {
  puts stderr {FLOW_SCRIPT is required}
  exit 1
}
if {[catch {source $::env(FLOW_SCRIPT)} reason options]} {
  puts stderr "FLOW FAILED: $reason"
  if {[dict exists $options -errorinfo]} {
    puts stderr [dict get $options -errorinfo]
  }
  exit 1
}
exit 0
