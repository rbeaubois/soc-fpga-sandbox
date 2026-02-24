# Folder structure:
#
# rtl
# ├── ip
# │    └── <board>
# ├── prj
# ├── src
# │    ├── hdl
# │    ├── tb
# │    └── xdc
# └── tcl
#      ├── create_vivado_prj_<board>_v<xil_version>.tcl
#      ├── gen_bd
#      ├── gen_dtc
#      └── gen_ip

# Fetch current path and source utilities scripts
set TCL_SCRIPT_PATH [ file dirname [ file normalize [ info script ] ] ]
source $TCL_SCRIPT_PATH/utils/vivado_utils.tcl
source $TCL_SCRIPT_PATH/gen_dtc/gen_dtc.tcl

# User generics ######################################
# Target board: KR260 | VPK120
set BOARD_NAME KR260
# Vivado version
set VIVADO_VER 2023.2
# Project name
set PRJ_NAME template
# Shorten project name to PRJ_NAME (no version/board), useful for windows
set SHORT_PRJ_NAME true

# Directory for HDL sources
set DIR_SOURCE ${TCL_SCRIPT_PATH}/../src
# Directory for Vivado projects
set DIR_OUTPUT ${TCL_SCRIPT_PATH}/../prj

# Synthesis and implementation strategies
## Fast for simple design or resource estimation
set STRATEGY_SYNTH Flow_RuntimeOptimized
set STRATEGY_IMPL Flow_RuntimeOptimized
## Slow for complex design (highly optimized)
# set STRATEGY_SYNTH Flow_PerfOptimized_high
# set STRATEGY_IMPL Performance_ExtraTimingOpt

# Top module
set TOP_FILE top

# Files to explictly set to VHDL 93 for block design instanciation no .vhd extension
set EXTRA_VHDL_STD93_FILES [list dummy_extra_instance_in_bd]
# Files to exclude from project (no .vhd extension)
set EXCLUDE_VHDL_SRC_FILES [list dummy_excluded]
# ####################################################

# Create vivado project
set vivado_prj_name [vivutils::create_prj $TCL_SCRIPT_PATH $BOARD_NAME $VIVADO_VER $PRJ_NAME $SHORT_PRJ_NAME $DIR_SOURCE $DIR_OUTPUT $STRATEGY_SYNTH $STRATEGY_IMPL $TOP_FILE $EXTRA_VHDL_STD93_FILES $EXCLUDE_VHDL_SRC_FILES]
vivutils::disp_new_tcl_func

# Set device tree generation command
set fileID [open $TCL_SCRIPT_PATH/gen_this_dtc_with_xsct.tcl "w"]
puts $fileID [gen_dtc $vivado_prj_name $BOARD_NAME $VIVADO_VER $TCL_SCRIPT_PATH]
close $fileID
