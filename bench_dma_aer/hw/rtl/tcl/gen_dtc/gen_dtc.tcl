proc gen_dtc {vivado_prj_name board vivado_ver main_tcl_path} {
    set dir_viv_prj ${main_tcl_path}/../prj/${vivado_prj_name}

    set is_supported_board 1
    set is_supported_ver   1
    switch -exact -- $board {
        "KR260" {
            switch -exact -- $vivado_ver {
                "2023.2" { 
                    set dtc_command {
"createdts -hw ${dir_viv_prj}/${vivado_prj_name}.xsa -platform-name ${board} \
                              -git-branch xlnx_rel_v2023.2 \
                              -overlay -zocl -compile \
                              -out ${dir_viv_prj}/${vivado_prj_name}_dtc"
"file copy ${dir_viv_prj}/${vivado_prj_name}_dtc/${board}/psu_cortexa53_0/device_tree_domain/bsp/pl.dtsi \
                                   ${dir_viv_prj}/${vivado_prj_name}_dtc/bd_wrapper.dtsi"
                    }
                }
                default {
                    set is_supported_ver 0
                }
            }
        }
        "VPK120" {
            switch -exact -- $vivado_ver {
                "2023.2" {
                    set dtc_command {
"createdts -hw ${dir_viv_prj}/${vivado_prj_name}.xsa \
                              -platform-name ${board} \
                              -git-branch xlnx_rel_v2023.2 \
                              -overlay -compile \
                              -out ${dir_viv_prj}/${vivado_prj_name}_dtc"
"file copy ${dir_viv_prj}/${vivado_prj_name}_dtc/${board}/psu_cortexa72_0/device_tree_domain/bsp/pl.dtsi \
                                ${dir_viv_prj}/${vivado_prj_name}_dtc/bd_wrapper.dtsi"
                    }
                }
                default {
                    set is_supported_ver 0
                }
            }
        }
        default {
            set is_supported_board 0
        }
    }

    if {!$is_supported_board} {
        puts "No existing support for board: $board"
        return -1
    }
    if {!$is_supported_ver} {
        puts "No existing support for Vivado version: $vivado_ver"
        return -1
    }

    return [string map {\" ""} [subst $dtc_command]]
}