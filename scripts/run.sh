#!/usr/bin/env bash
# Run on a licensed Linux host; public sources contain no site credentials.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_DIR
action="${1:-help}"
case "$action" in
  help)
    printf '%s\n' 'make sim | sim-flags | sim-protocol | test' \
      'make synth | layout | sim-post-synth | sim-post-layout | power | validate' \
      'Cadence tools run only on the licensed remote host. See docs/reproduction.md.'
    exit 0 ;;
  sim|sim-flags|sim-protocol|test|synth|layout|sim-post-synth|sim-post-layout|power|validate) ;;
  *) echo "Unknown action: $action" >&2; exit 2 ;;
esac
source "$PROJECT_DIR/scripts/environment.sh"
mkdir -p "$PROJECT_DIR/build" "$PROJECT_DIR/backend/"{synthesis,layout}/{work,reports,deliverables}
{
  printf 'UTC: '; date -u '+%Y-%m-%dT%H:%M:%SZ'
  printf 'Action: %s\nClock period (ns): %s\n' "$action" "$period_clk"
  while IFS= read -r file; do
    [[ -z "$file" ]] || sha256sum "$PROJECT_DIR/$file"
  done < "$PROJECT_DIR/config/public-files.txt"
} > "$PROJECT_DIR/build/${action}-sources.txt"
require() { command -v "$1" >/dev/null || { echo "Missing tool: $1" >&2; exit 127; }; }
need_file() { test -f "$1" || { echo "Missing file: $1" >&2; exit 2; }; }
freq_tag=$(awk -v p="$period_clk" 'BEGIN { if (p <= 0) exit 1; f=1000/p; if (f==int(f)) printf "%dMHz",f; else {s=sprintf("%.3fMHz",f); gsub(/\./,"p",s); printf "%s",s} }')
export POWER_FREQ_TAG="$freq_tag"

simulate() {
  local stage="$1" suite="$2" activity="${3:-0}" tb log work netlist sdf
  require xrun
  tb="multiplier32fp_${suite}_tb"
  test "$suite" != vectors || tb=multiplier32fp_tb
  work="$PROJECT_DIR/build/sim-${stage}-${suite}-${activity}"
  mkdir -p "$work"
  log="$work/run.log"
  local args=(-64bit -sv -access +rwc -top "$tb" -define "CLK_PERIOD_NS=$period_clk")
  if [[ "$stage" == rtl ]]; then
    args+=("$PROJECT_DIR/frontend/multiplier32fp.sv")
  else
    need_file "${CELL_MODELS:?Set CELL_MODELS in config/local.env}"
    if [[ "$stage" == synth ]]; then
      netlist="$PROJECT_DIR/backend/synthesis/deliverables/multiplier32fp_${freq_tag}.v"
      sdf="$PROJECT_DIR/backend/synthesis/deliverables/multiplier32fp_${freq_tag}_worst_SPLIT.sdf"
    else
      netlist="$PROJECT_DIR/backend/layout/deliverables/multiplier32fp_${freq_tag}_layout.v"
      sdf="$PROJECT_DIR/backend/layout/deliverables/multiplier32fp_${freq_tag}_layout.sdf"
    fi
    need_file "$netlist"; need_file "$sdf"
    args+=("$CELL_MODELS" "$netlist" -define ANNOTATE_SDF "+SDF_FILE=$sdf")
  fi
  args+=("$PROJECT_DIR/frontend/simulation/$tb.sv" "+VECTOR_FILE=$PROJECT_DIR/frontend/simulation/vetor.txt")
  if [[ "$activity" == 1 ]]; then
    args+=(-define POWER_2X_HOLD)
    printf 'database -open activity -vcd -into {%s} -default\nprobe -create multiplier32fp_tb.DUV -all -depth all\nrun\nexit\n' \
      "$PROJECT_DIR/frontend/simulation/power_2x_${freq_tag}_${stage}.vcd" > "$work/activity.cmd"
    args+=(-input "$work/activity.cmd")
  else
    args+=(-input '@run; exit')
  fi
  (cd "$work"; xrun "${args[@]}" 2>&1 | tee "$log")
  grep -q 'TEST PASS' "$log" || { echo "Simulation did not finish successfully: $log" >&2; exit 1; }
  if grep -Eiq '\*[EF],|\$error|timing violation|timing check.*violat|SDF.*(fail|unable|cannot)' "$log"; then
    echo "Simulation diagnostics require review: $log" >&2; exit 1
  fi
}
synthesize() {
  require genus
  export FLOW_SCRIPT="$PROJECT_DIR/backend/synthesis/scripts/multiplier32fp.tcl"
  (cd "$PROJECT_DIR/backend/synthesis/work"; genus -no_gui -abort_on_error -overwrite \
    -files "$PROJECT_DIR/scripts/run_tool.tcl" 2>&1 | tee "$PROJECT_DIR/build/synth.log")
  grep -q 'FLOW PASS synthesis' "$PROJECT_DIR/build/synth.log"
}
layout() {
  require innovus
  export FLOW_SCRIPT="$PROJECT_DIR/backend/layout/scripts/layout.tcl"
  (cd "$PROJECT_DIR/backend/layout/work"; innovus -no_gui -common_ui -overwrite \
    -files "$PROJECT_DIR/scripts/run_tool.tcl" 2>&1 | tee "$PROJECT_DIR/build/layout.log")
  grep -q 'FLOW PASS layout' "$PROJECT_DIR/build/layout.log"
}
power() {
  require innovus
  export POWER_MODE=2x
  for POWER_STAGE in synth layout; do
    export POWER_STAGE
    simulate "$POWER_STAGE" vectors 1
    export FLOW_SCRIPT="$PROJECT_DIR/backend/layout/scripts/power_table.tcl"
    (cd "$PROJECT_DIR/backend/layout/work"; innovus -no_gui -common_ui -overwrite \
      -files "$PROJECT_DIR/scripts/run_tool.tcl" 2>&1 | tee "$PROJECT_DIR/build/power-${POWER_STAGE}.log")
    grep -q 'FLOW PASS power' "$PROJECT_DIR/build/power-${POWER_STAGE}.log"
  done
}
case "$action" in
  sim) simulate rtl vectors ;;
  sim-flags) simulate rtl flags ;;
  sim-protocol) simulate rtl protocol ;;
  test) for suite in vectors flags protocol; do simulate rtl "$suite"; done ;;
  synth) synthesize ;;
  layout) layout ;;
  sim-post-synth) for suite in vectors flags protocol; do simulate synth "$suite"; done ;;
  sim-post-layout) for suite in vectors flags protocol; do simulate layout "$suite"; done ;;
  power) power ;;
  validate)
    for suite in vectors flags protocol; do simulate rtl "$suite"; done
    synthesize; layout
    for stage in synth layout; do
      for suite in vectors flags protocol; do simulate "$stage" "$suite"; done
    done
    power
    echo 'FLOW PASS validation (review timing, SDF and physical reports before claiming closure)' ;;
esac
