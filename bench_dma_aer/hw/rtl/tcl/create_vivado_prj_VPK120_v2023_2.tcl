set TCL_SCRIPT_PATH [ file dirname [ file normalize [ info script ] ] ]
source $TCL_SCRIPT_PATH/utils/vivado_utils.tcl
source $TCL_SCRIPT_PATH/gen_dtc/gen_dtc.tcl

# User generics ######################################
set BOARD_NAME VPK120
set VIVADO_VER 2023.2
set PRJ_NAME bench_dma_aer
set DIR_SOURCE ${TCL_SCRIPT_PATH}/../src
set DIR_OUTPUT ${TCL_SCRIPT_PATH}/../prj
set STRATEGY_SYNTH Flow_RuntimeOptimized
set STRATEGY_IMPL Flow_RuntimeOptimized
#set STRATEGY_SYNTH Flow_PerfOptimized_high
#set STRATEGY_IMPL Performance_ExtraTimingOpt
set TOP_FILE top
set EXTRA_VHDL_STD93_FILES [list axigpio_dualch_intr]
# ####################################################

# Create vivado project
set vivado_prj_name [vivutils::create_prj $TCL_SCRIPT_PATH $BOARD_NAME $VIVADO_VER $PRJ_NAME $DIR_SOURCE $DIR_OUTPUT $STRATEGY_SYNTH $STRATEGY_IMPL $TOP_FILE $EXTRA_VHDL_STD93_FILES]
vivutils::disp_new_tcl_func

# Set device tree generation command
set XSCT_GEN_DTC_COMMAND [gen_dtc $vivado_prj_name $BOARD_NAME $VIVADO_VER $TCL_SCRIPT_PATH]
set fileID [open $TCL_SCRIPT_PATH/gen_this_dtc_with_xsct.tcl "w"]
puts $fileID $XSCT_GEN_DTC_COMMAND
close $fileID