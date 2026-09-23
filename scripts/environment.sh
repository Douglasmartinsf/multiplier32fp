#!/usr/bin/env bash
# Sourced by run.sh. The optional configuration contains site-specific setup.
if [[ -f "$PROJECT_DIR/config/local.env" ]]; then
  source "$PROJECT_DIR/config/local.env"
fi
: "${TECH_DIR:?Set TECH_DIR in config/local.env on the licensed host}"
export TECH_DIR
export DESIGNS="${DESIGNS:-multiplier32fp}"
export BACKEND_DIR="${BACKEND_DIR:-${PROJECT_DIR}/backend}"
export LIB_DIR="${LIB_DIR:-${TECH_DIR}/gsclib045_svt_v4.4/gsclib045/timing}"
export LEF_DIR="${LEF_DIR:-${TECH_DIR}/gsclib045_svt_v4.4/gsclib045/lef}"
export HDL_NAME="${HDL_NAME:-${DESIGNS}}"
export RTL_FILES="${RTL_FILES:-${DESIGNS}.sv}"
export VLOG_LIST="${VLOG_LIST:-$BACKEND_DIR/synthesis/deliverables/${DESIGNS}.v}"
export MAIN_CLOCK_NAME="${MAIN_CLOCK_NAME:-clk}"
export MAIN_RST_NAME="${MAIN_RST_NAME:-rst_n}"
export BEST_LIB_OPERATING_CONDITION="${BEST_LIB_OPERATING_CONDITION:-PVT_1P32V_0C}"
export WORST_LIB_OPERATING_CONDITION="${WORST_LIB_OPERATING_CONDITION:-PVT_0P9V_125C}"
export period_clk="${period_clk:-4.000}"
export clk_uncertainty="${clk_uncertainty:-0.05}"
export clk_latency="${clk_latency:-0.10}"
export in_delay="${in_delay:-0.30}"
export out_delay="${out_delay:-0.30}"
export out_load="${out_load:-0.045}"
export slew="${slew:-146 164 264 252}"
export slew_min_rise="${slew_min_rise:-0.146}"
export slew_min_fall="${slew_min_fall:-0.164}"
export slew_max_rise="${slew_max_rise:-0.264}"
export slew_max_fall="${slew_max_fall:-0.252}"
export WORST_LIST="${WORST_LIST:-${LIB_DIR}/slow_vdd1v0_basicCells.lib}"
export BEST_LIST="${BEST_LIST:-${LIB_DIR}/fast_vdd1v2_basicCells.lib}"
export LEF_LIST="${LEF_LIST:-${LEF_DIR}/gsclib045_tech.lef ${LEF_DIR}/gsclib045_macro.lef}"
export WORST_CAP_LIST="${WORST_CAP_LIST:-${TECH_DIR}/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl}"
export QRC_LIST="${QRC_LIST:-${TECH_DIR}/gpdk045_v_6_0/qrc/rcworst/qrcTechFile}"
export CAP_MAX="${CAP_MAX:-${WORST_CAP_LIST}}"
export CAP_MIN="${CAP_MIN:-${WORST_CAP_LIST}}"
export NET_ZERO="${NET_ZERO:-VSS}"
export NET_ONE="${NET_ONE:-VDD}"
export BUFFERS_CTS="${BUFFERS_CTS:-CLKBUFX20 CLKBUFX16 CLKBUFX12 CLKBUFX8 CLKBUFX6 CLKBUFX4 CLKBUFX3 CLKBUFX2}"
export INVERTERS_CTS="${INVERTERS_CTS:-INVX20 CLKINVX20 INVX16 INVX12 INVX8 INVX6 INVX4 INVX3 INVX2 INVX1 INVXL}"
if [[ -z ${LEFT_CORE_PINS:-} ]]; then
  LEFT_CORE_PINS='{a_i[0]} {a_i[1]} {a_i[2]} {a_i[3]} {a_i[4]} {a_i[5]} {a_i[6]} {a_i[7]} {a_i[8]} {a_i[9]} {a_i[10]} {a_i[11]} {a_i[12]} {a_i[13]} {a_i[14]} {a_i[15]} {a_i[16]} {a_i[17]} {a_i[18]} {a_i[19]} {a_i[20]} {a_i[21]} {a_i[22]} {a_i[23]} {a_i[24]} {a_i[25]} {a_i[26]} {a_i[27]} {a_i[28]} {a_i[29]} {a_i[30]} {a_i[31]}'
fi
export LEFT_CORE_PINS
if [[ -z ${TOP_CORE_PINS:-} ]]; then
  TOP_CORE_PINS='{b_i[0]} {b_i[1]} {b_i[2]} {b_i[3]} {b_i[4]} {b_i[5]} {b_i[6]} {b_i[7]} {b_i[8]} {b_i[9]} {b_i[10]} {b_i[11]} {b_i[12]} {b_i[13]} {b_i[14]} {b_i[15]} {b_i[16]} {b_i[17]} {b_i[18]} {b_i[19]} {b_i[20]} {b_i[21]} {b_i[22]} {b_i[23]} {b_i[24]} {b_i[25]} {b_i[26]} {b_i[27]} {b_i[28]} {b_i[29]} {b_i[30]} {b_i[31]}'
fi
export TOP_CORE_PINS
if [[ -z ${RIGHT_CORE_PINS:-} ]]; then
  RIGHT_CORE_PINS='{product_o[0]} {product_o[1]} {product_o[2]} {product_o[3]} {product_o[4]} {product_o[5]} {product_o[6]} {product_o[7]} {product_o[8]} {product_o[9]} {product_o[10]} {product_o[11]} {product_o[12]} {product_o[13]} {product_o[14]} {product_o[15]} {product_o[16]} {product_o[17]} {product_o[18]} {product_o[19]} {product_o[20]} {product_o[21]} {product_o[22]} {product_o[23]} {product_o[24]} {product_o[25]} {product_o[26]} {product_o[27]} {product_o[28]} {product_o[29]} {product_o[30]} {product_o[31]}'
fi
export RIGHT_CORE_PINS
export BOTTOM_CORE_PINS="${BOTTOM_CORE_PINS:-clk rst_n start_i done_o nan_o infinit_o overflow_o underflow_o}"
