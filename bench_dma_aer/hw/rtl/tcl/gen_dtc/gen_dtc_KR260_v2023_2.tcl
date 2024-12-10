# if { $argc != 2 } {
    # puts "generate-device-tree <board> <xil_tools_version>"
    # puts "<board>: KR260 VPK120"
    # puts "<xil_tools_version>: 2023_2"
# } else {
    # puts [expr [lindex $argv 0] + [lindex $argv 1]]
    
    # set TCL_SCRIPT_PATH [ file dirname [ file normalize [ info script ] ] ]

    # set PRJ_NAME bioemum
    # set BOARD_NAME [lindex $argv 0]
    # set VIVADO_VER [lindex $argv 1]
    # set VIV_PRJ_NAME ${PRJ_NAME}_${BOARD_NAME}_v${VIVADO_VER}

    # set DIR_VIV_PRJ ${TCL_SCRIPT_PATH}/../prj/${VIV_PRJ_NAME}

    # createdts -hw ${DIR_VIV_PRJ}/${VIV_PRJ_NAME}.xsa -platform-name kr260 -git-branch xlnx_rel_v2022.2 -overlay -zocl -compile -out ${DIR_VIV_PRJ}/${VIV_PRJ_NAME}_dtc
# }

set TCL_SCRIPT_PATH [ file dirname [ file normalize [ info script ] ] ]

set PRJ_NAME bench_dma_aer
set BOARD_NAME KR260
set VIVADO_VER 2023_2
set VIV_PRJ_NAME ${PRJ_NAME}_${BOARD_NAME}_v${VIVADO_VER}

set DIR_VIV_PRJ ${TCL_SCRIPT_PATH}/../../prj/${VIV_PRJ_NAME}
cd ${DIR_VIV_PRJ}

createdts -hw ${VIV_PRJ_NAME}.xsa -platform-name ${BOARD_NAME} -git-branch xlnx_rel_v2023.2 -overlay -zocl -compile -out ${DIR_VIV_PRJ}/${VIV_PRJ_NAME}_dtc
