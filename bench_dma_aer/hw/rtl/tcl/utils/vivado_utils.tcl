namespace eval vivutils {
    # Create Vivado project
    proc create_prj {main_tcl_path board_name vivado_ver prj_name dir_src dir_out strat_synth strat_impl top_file extra_vhdl_std93_files} {
        # Source TCL utilities functions
        source ${main_tcl_path}/utils/futils.tcl

        # Extract board details
        set details [get_board_details $board_name $vivado_ver]
        if {$details != -1} {
            set part [dict get $details part]
            set board_part [dict get $details board_part]
            set connections [dict get $details connections]
        } else {
            error "Board and/or Vivado version not supported"
            exit 1
        }

        # Create and setup project
        set vivado_ver_uscore [string map {"." "_"} $vivado_ver]
        set vivado_prj_name ${prj_name}_${board_name}_v${vivado_ver_uscore}
        create_project ${vivado_prj_name} ${dir_out}/${vivado_prj_name} -part $part
        set_property board_part $board_part [current_project]
        if {[string length $connections]} {
            set_property board_connections $connections [current_project]
        }
        set_property target_language VHDL [current_project]
        set_property simulator_language VHDL [current_project]
        set bd_design_name bd

        # Find and add all (vhdl) files in folder
        set design_src_files [futils::find_files ${dir_src}/hdl *.vhd]
        add_files -fileset sources_1 ${design_src_files}

        # Find and add all testbench files in folder
        set sim_src_files [futils::find_files ${dir_src}/tb *.vhd]
        add_files -fileset sim_1 ${sim_src_files}

        # Find and add matching constraint file
        set constrs_src_file ${dir_src}/xdc/${board_name}_${prj_name}.xdc
        if {[file exists $constrs_src_file]} {
            add_files -fileset constrs_1 $constrs_src_file
        } else {
            puts "Warning!!! XDC constraint file not found."
        }

        # Set all sources except top to VHDL 2008
        set_property file_type {VHDL 2008} [get_files -filter {FILE_TYPE == VHDL}]
        if {[file exists [get_files ${top_file}.vhd]]} {
            set_property file_type {VHDL} [get_files ${top_file}.vhd]
        } else {
            puts "Warning!!! VHDL Top file script not found."
        }
        # Additional files to keep in VHDL
        foreach vhdl_file $extra_vhdl_std93_files {
            # Check if the file exists
            puts "$vhdl_file"
            if {[file exists [get_files ${vhdl_file}.vhd]]} {
                # Set the file type property if the file exists
                set_property file_type {VHDL} [get_files ${vhdl_file}.vhd]
            }
        }

        # Generate IP (Xilinx IP + HLS IP)
        set gen_ip_tcl_script ${main_tcl_path}/gen_ip/gen_ip.tcl
        if {[file exists $gen_ip_tcl_script]} {
            source $gen_ip_tcl_script
            gen_ip $board_name $vivado_ver $main_tcl_path
        } else {
            puts "Warning!!! TCL IP generation script not found."
        }

        # Generate block design
        set gen_bd_tcl_script ${main_tcl_path}/gen_bd/gen_bd_${board_name}_v${vivado_ver_uscore}.tcl
        puts $gen_bd_tcl_script
        if {[file exists $gen_bd_tcl_script]} {
            # Create block design from tcl
            source $gen_bd_tcl_script

            # Create top wrapper for block design
            make_wrapper -files [get_files ${bd_design_name}.bd] -top
            add_files -norecurse ${dir_out}/${vivado_prj_name}/${vivado_prj_name}.gen/sources_1/bd/${bd_design_name}/hdl/${bd_design_name}_wrapper.vhd
            set_property top ${bd_design_name}_wrapper [current_fileset]
        } else {
            puts "Warning!!! TCL Block Design generation script not found."
        }

        # Set synthesis and implementation strategies
        set_property strategy $strat_synth [get_runs synth_1]
        set_property strategy $strat_impl [get_runs impl_1]

        # Return project name
        return $vivado_prj_name
    }

    # Launch synthesis
    proc run_synth {nb_jobs} {
        launch_runs synth_1 -jobs ${nb_jobs}
        wait_on_run synth_1
    }

    # Launch implementation
    proc run_impl {nb_jobs} {
        launch_runs impl_1 -to_step write_bitstream -jobs ${nb_jobs}
        wait_on_run impl_1
    }

    # Generate and export hardware
    proc generate_xsa {nb_jobs} {
        upvar dir_out dir_out
        upvar vivado_prj_name vivado_prj_name
        run_synth ${nb_jobs}
        run_impl ${nb_jobs}
        write_hw_platform -fixed -include_bit -force -file ${dir_out}/${vivado_prj_name}/${vivado_prj_name}.xsa
    }

    # Generate TCL block design
    proc update_tcl_bd {} {
        upvar dir_out dir_out
        upvar vivado_prj_name vivado_prj_name
        write_bd_tcl -include_layout ${main_tcl_path}/gen_bd/gen_bd_${board_name}_v${vivado_ver_uscore}.tcl -force
    }

    # Get board details for Vivado to setup projects
    # 
    # Parameters:
    #   - board: Custom board identifier (str).
    #   - vivado_ver: Vivado version (str).
    # 
    # Returns:
    #   - Board details as dict of part, board_part and connections.
    #
    # Example:
    #   get_board_details KR260 2023.2 => [dict part board_part connections]
    #
    proc get_board_details {board vivado_ver} {
        # Define a dictionary with board details
        set board_details {
            "KR260" {
                "2023.2" {
                    "part" "xck26-sfvc784-2LV-c"
                    "board_part" "xilinx.com:kr260_som:part0:1.1"
                    "connections" {
                        "som240_2_connector" "xilinx.com:kr260_carrier:som240_2_connector:1.0"
                        "som240_1_connector" "xilinx.com:kr260_carrier:som240_1_connector:1.0"
                    }
                }
            }
            "VPK120" {
                "2023.2" {
                    "part" "xcvp1202-vsva2785-2MP-e-S"
                    "board_part" "xilinx.com:vpk120:part0:1.2"
                    "connections" {}
                }
            }
        }

        # Attempt to access the board dictionary
        if {[dict exists $board_details $board]} {
            # Attempt to access the Vivado version details
            if {[dict exists [dict get $board_details $board] $vivado_ver]} {
                # Access the board details for the given Vivado version
                set details [dict get [dict get $board_details $board] $vivado_ver]
                
                # Return the board details
                return $details
            } else {
                error "No existing support for Vivado version: $vivado_ver"
            }
        } else {
            error "No existing support for board: $board"
        }
    }

    proc disp_new_tcl_func {} {
        set len_header_line 60
        puts [string repeat "=" $len_header_line]
        puts "The following commands were added:"
        puts "  * Run synthesis:            vivutils::run_synth nb_jobs"
        puts "  * Run implementation:       vivutils::run_impl nb_jobs"
        puts "  * Run all and export xsa:   vivutils::generate_xsa nb_jobs"
        puts "  * Update block design tcl:  vivutils::update_tcl_bd"
        puts [string repeat "=" $len_header_line]
    }
}
