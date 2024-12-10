# File version: 0.1.1
# Folder structure:
# /!\ Block design name must be: system
#
# vivado
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
#      └── gen_ip

# Get tcl script absolute path
set TCL_SCRIPT_PATH [ file dirname [ file normalize [ info script ] ] ]
cd $TCL_SCRIPT_PATH

# User generics ######################################
set BOARD_NAME VPK120
set VIVADO_VER 2023_2
set PRJ_NAME bench_dma_aer
set DIR_SOURCE ${TCL_SCRIPT_PATH}/../src
set DIR_OUTPUT ${TCL_SCRIPT_PATH}/../prj
set STRATEGY_SYNTH Flow_RuntimeOptimized
set STRATEGY_IMPL Flow_RuntimeOptimized
#set STRATEGY_SYNTH Flow_PerfOptimized_high
#set STRATEGY_IMPL Performance_ExtraTimingOpt
set TOP_FILE top
# ####################################################

# Create and setup project
set VIV_PRJ_NAME ${PRJ_NAME}_${BOARD_NAME}_v${VIVADO_VER}
create_project ${VIV_PRJ_NAME} ${DIR_OUTPUT}/${VIV_PRJ_NAME} -part xcvp1202-vsva2785-2MP-e-S
set_property board_part xilinx.com:vpk120:part0:1.2 [current_project]
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]
set bd_design_name bd

# Add sources
proc findFiles {directory pattern} {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set directory [string trimright [file join [file normalize $directory] { }]]

    # Starting with the passed in directory, do a breadth first search for
    # subdirectories. Avoid cycles by normalizing all file paths and checking
    # for duplicates at each level.

    set directories [list $directory]
    set parents $directory
    while {[llength $parents] > 0} {

        # Find all the children at the current level
        set children [list]
        foreach parent $parents {
            set children [concat $children [glob -nocomplain -type {d r} -path $parent *]]
        }

        # Normalize the children
        set length [llength $children]
        for {set i 0} {$i < $length} {incr i} {
            lset children $i [string trimright [file join [file normalize [lindex $children $i]] { }]]
        }

        # Make the list of children unique
        set children [lsort -unique $children]

        # Find the children that are not duplicates, use them for the next level
        set parents [list]
        foreach child $children {
            if {[lsearch -sorted $directories $child] == -1} {
                lappend parents $child
            }
        }

        # Append the next level directories to the complete list
        set directories [lsort -unique [concat $directories $parents]]
    }

    # Get all the files in the passed in directory and all its subdirectories
    set result [list]
    foreach directory $directories {
        set result [concat $result [glob -nocomplain -type {f r} -path $directory -- $pattern]]
    }

    # Normalize the filenames
    set length [llength $result]
    for {set i 0} {$i < $length} {incr i} {
        lset result $i [file normalize [lindex $result $i]]
    }

    # Return only unique filenames
    return [lsort -unique $result]
}

# hdl
set design_src_files [findFiles ${DIR_SOURCE}/hdl *.vhd]
add_files -fileset sources_1 ${design_src_files}

# tb
set sim_src_files [findFiles ${DIR_SOURCE}/tb *.vhd]
add_files -fileset sim_1 ${sim_src_files}

# xdc
set constrs_src_file ${DIR_SOURCE}/xdc/${BOARD_NAME}_${PRJ_NAME}.xdc
if {[file exists $constrs_src_file]} {
    add_files -fileset constrs_1 $constrs_src_file
} else {
    puts "Warning!!! XDC constraint file not found."
}

# Set all sources except top to VHDL 2008
set_property file_type {VHDL 2008} [get_files -filter {FILE_TYPE == VHDL}]
if {[file exists [get_files ${TOP_FILE}.vhd]]} {
    set_property file_type {VHDL} [get_files ${TOP_FILE}.vhd]
} else {
    puts "Warning!!! VHDL Top file script not found."
}
# Additional files to keep in VHDL
if {[file exists [get_files axigpio_dualch_intr.vhd]]} {
    set_property file_type {VHDL} [get_files axigpio_dualch_intr.vhd]
}

# Generate IP (Xilinx IP + HLS IP)
set gen_ip_tcl_script ${TCL_SCRIPT_PATH}/gen_ip/gen_ip_${BOARD_NAME}_v${VIVADO_VER}.tcl
if {[file exists $gen_ip_tcl_script]} {
    source $gen_ip_tcl_script
} else {
    puts "Warning!!!: TCL IP generation script not found."
}

# Generate block design
set gen_bd_tcl_script ${TCL_SCRIPT_PATH}/gen_bd/gen_bd_${BOARD_NAME}_v${VIVADO_VER}.tcl
if {[file exists $gen_bd_tcl_script]} {
    source $gen_bd_tcl_script
} else {
    puts "Warning!!!: TCL Block Design generation script not found."
}

# Create top wrapper for block design
make_wrapper -files [get_files ${bd_design_name}.bd] -top
add_files -norecurse ${DIR_OUTPUT}/${VIV_PRJ_NAME}/${VIV_PRJ_NAME}.gen/sources_1/bd/${bd_design_name}/hdl/${bd_design_name}_wrapper.vhd
set_property top ${bd_design_name}_wrapper [current_fileset]

# Set synthesis and implementation strategies
set_property strategy $STRATEGY_SYNTH [get_runs synth_1]
set_property strategy $STRATEGY_IMPL [get_runs impl_1]

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
	upvar DIR_OUTPUT DIR_OUTPUT
	upvar VIV_PRJ_NAME VIV_PRJ_NAME
	run_synth ${nb_jobs}
	run_impl ${nb_jobs}
	write_hw_platform -fixed -include_bit -force -file ${DIR_OUTPUT}/${VIV_PRJ_NAME}/${VIV_PRJ_NAME}.xsa
}

# Generate TCL block design
proc update_tcl_bd {} {
	upvar DIR_OUTPUT DIR_OUTPUT
	upvar VIV_PRJ_NAME VIV_PRJ_NAME
	write_bd_tcl -include_layout ${TCL_SCRIPT_PATH}/gen_bd/gen_bd_${BOARD_NAME}_v${VIVADO_VER}.tcl -force
}

# Display TCL commands added
set len_header_line 100
puts [string repeat "=" $len_header_line]
puts "The following commands were added:"
puts "  * Run synthesis:	   run_synth nb_jobs"
puts "  * Run implementation:      run_impl nb_jobs"
puts "  * Run all and export xsa:  generate_xsa nb_jobs"
puts "  * Update block design tcl: update_tcl_bd"
puts [string repeat "=" $len_header_line]
