proc gen_ip {board vivado_ver main_tcl_path} {
    # Get file utils functions
    source $main_tcl_path/utils/futils.tcl

    # -------------------------------------------------------------------------------------------------
    # Extract parameters from VHDL files
    
    # ============================
    # Generics
    # ============================
    set HW_VERSION  [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/system_pkg.vhd HW_VERSION]
    set HW_UID      [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/system_pkg.vhd HW_UID]

    # ============================
    # Log config 
    # ============================

    # Display generics
    set len_header_line 60
    puts [string repeat "=" $len_header_line]
    puts "Generate IP with the following generics:\n"

    puts "HW_VERSION: $HW_VERSION"
    puts "HW_UID:     $HW_UID"
    puts [string repeat "-" 5]
    
    puts [string repeat "=" $len_header_line]

    # -------------------------------------------------------------------------------------------------
    # Check if IP support is defined for a given board and version
    set is_supported_board 1
    set is_supported_ver   1
    switch -exact -- $board {
        "KR260" {
            switch -exact -- $vivado_ver {
                "2023.2" {
                    # ####################################
                    #  Any IP to instantiate in RTL
                    # ####################################
                    # # AXI GPIO
                    # create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axigpio_dualch_intr_ip
                    # set_property -dict [list \
                    # CONFIG.C_ALL_INPUTS {1} \
                    # CONFIG.C_ALL_OUTPUTS_2 {1} \
                    # CONFIG.C_INTERRUPT_PRESENT {1} \
                    # CONFIG.C_IS_DUAL {1} \
                    # ] [get_ips axigpio_dualch_intr_ip]
                }
                default {
                    set is_supported_ver 0
                }
            }
        }
        "VPK120" {
            switch -exact -- $vivado_ver {
                "2023.2" {
                    # ####################################
                    #  Any IP to instantiate in RTL
                    # ####################################
                    # # AXI GPIO
                    # create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axigpio_dualch_intr_ip
                    # set_property -dict [list \
                    # CONFIG.C_ALL_INPUTS {1} \
                    # CONFIG.C_ALL_OUTPUTS_2 {1} \
                    # CONFIG.C_INTERRUPT_PRESENT {1} \
                    # CONFIG.C_IS_DUAL {1} \
                    # ] [get_ips axigpio_dualch_intr_ip]
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
    }
    if {!$is_supported_ver} {
        puts "No existing support for Vivado version: $vivado_ver"
    }
}
