set TCL_SCRIPT_PATH [ file dirname [ file normalize [ info script ] ] ]
source $TCL_SCRIPT_PATH/utils/vivado_utils.tcl

# User generics ######################################
set BOARD_NAME VPK120
set VIVADO_VER 2023.2
set PRJ_NAME static888
set DIR_SOURCE ${TCL_SCRIPT_PATH}/../src
set DIR_OUTPUT ${TCL_SCRIPT_PATH}/../prj
set STRATEGY_SYNTH Flow_RuntimeOptimized
set STRATEGY_IMPL Flow_RuntimeOptimized
#set STRATEGY_SYNTH Flow_PerfOptimized_high
#set STRATEGY_IMPL Performance_ExtraTimingOpt
set TOP_FILE top
set EXTRA_VHDL_STD93_FILES [list]
set NB_LOCAL_JOBS 8
# ####################################################

# Create vivado project
set vivado_prj_name [vivutils::create_prj $TCL_SCRIPT_PATH $BOARD_NAME $VIVADO_VER $PRJ_NAME $DIR_SOURCE $DIR_OUTPUT $STRATEGY_SYNTH $STRATEGY_IMPL $TOP_FILE $EXTRA_VHDL_STD93_FILES]
vivutils::generate_static_xsa $NB_LOCAL_JOBS $vivado_prj_name $DIR_OUTPUT