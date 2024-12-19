
################################################################
# This is a generated script based on design: bd
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source bd_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# top, axigpio_dualch_intr, axigpio_dualch_intr

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvp1202-vsva2785-2MP-e-S
   set_property BOARD_PART xilinx.com:vpk120:part0:1.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:versal_cips:3.4\
xilinx.com:ip:axi_noc:1.0\
xilinx.com:ip:axi_dma:7.1\
xilinx.com:ip:clk_wizard:1.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
top\
axigpio_dualch_intr\
axigpio_dualch_intr\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ch0_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch0_lpddr4_trip1 ]

  set ch1_lpddr4_trip1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:lpddr4_rtl:1.0 ch1_lpddr4_trip1 ]

  set lpddr4_clk1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 lpddr4_clk1 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200321000} \
   ] $lpddr4_clk1


  # Create ports

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.DDR_MEMORY_MODE {Enable} \
    CONFIG.DEBUG_MODE {JTAG} \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO\
{PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_I2CSYSMON_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 39 .. 40}}} \
      PS_IRQ_USAGE {{CH0 0} {CH1 0} {CH10 1} {CH11 1} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 1} {CH9 1}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PS_MIO 18} \
      PS_PCIE_EP_RESET2_IO {PS_MIO 19} \
      PS_PCIE_RESET {{ENABLE 1}} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_INTERFACE_TO_USE {I2C} \
      SMON_PMBUS_ADDRESS {0x18} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0


  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.0 axi_noc_0 ]
  set_property -dict [list \
    CONFIG.CH0_LPDDR4_0_BOARD_INTERFACE {ch0_lpddr4_trip1} \
    CONFIG.CH1_LPDDR4_0_BOARD_INTERFACE {ch1_lpddr4_trip1} \
    CONFIG.MC1_FLIPPED_PINOUT {true} \
    CONFIG.MC_CHANNEL_INTERLEAVING {true} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_DM_WIDTH {4} \
    CONFIG.MC_DQS_WIDTH {4} \
    CONFIG.MC_DQ_WIDTH {32} \
    CONFIG.MC_EN_INTR_RESP {TRUE} \
    CONFIG.MC_SYSTEM_CLOCK {Differential} \
    CONFIG.NUM_CLKS {9} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {4} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {9} \
    CONFIG.sys_clk0_BOARD_INTERFACE {lpddr4_clk1} \
  ] $axi_noc_0


  set_property -dict [ list \
   CONFIG.APERTURES {{0x201_0000_0000 1G}} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/M00_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0xc0} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x80} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x80} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_2 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.DEST_IDS {M00_AXI:0x80} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins /axi_noc_0/S08_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {M00_AXI:S06_AXI:S07_AXI:S08_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
 ] [get_bd_pins /axi_noc_0/aclk7]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
 ] [get_bd_pins /axi_noc_0/aclk8]

  # Create instance: axi_dma_spk, and set properties
  set axi_dma_spk [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_spk ]
  set_property -dict [list \
    CONFIG.c_addr_width {64} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_mm2s_burst_size {256} \
    CONFIG.c_s2mm_burst_size {256} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_sg_length_width {16} \
  ] $axi_dma_spk


  # Create instance: clk_wizard, and set properties
  set clk_wizard [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wizard ]
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT {clk_pl,clk_axi,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {400,200,100.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED {true,true,false,false,false,false,false} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
  ] $clk_wizard


  # Create instance: bench_dma_aer, and set properties
  set block_name top
  set block_cell_name bench_dma_aer
  if { [catch {set bench_dma_aer [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bench_dma_aer eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_gpio_free_slots_to_pl, and set properties
  set block_name axigpio_dualch_intr
  set block_cell_name axi_gpio_free_slots_to_pl
  if { [catch {set axi_gpio_free_slots_to_pl [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_gpio_free_slots_to_pl eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_gpio_ready_ev_to_ps, and set properties
  set block_name axigpio_dualch_intr
  set block_cell_name axi_gpio_ready_ev_to_ps
  if { [catch {set axi_gpio_ready_ev_to_ps [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_gpio_ready_ev_to_ps eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_params_dma, and set properties
  set axi_params_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_params_dma ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {3} \
    CONFIG.C_GPIO_WIDTH {4} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_params_dma


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {6} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: proc_sys_reset_axi, and set properties
  set proc_sys_reset_axi [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_axi ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_dma_spk_M_AXIS_MM2S [get_bd_intf_pins axi_dma_spk/M_AXIS_MM2S] [get_bd_intf_pins bench_dma_aer/S_AXIS_SPK_IN]
  connect_bd_intf_net -intf_net axi_dma_spk_M_AXI_MM2S [get_bd_intf_pins axi_noc_0/S07_AXI] [get_bd_intf_pins axi_dma_spk/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_dma_spk_M_AXI_S2MM [get_bd_intf_pins axi_dma_spk/M_AXI_S2MM] [get_bd_intf_pins axi_noc_0/S08_AXI]
  connect_bd_intf_net -intf_net axi_dma_spk_M_AXI_SG [get_bd_intf_pins axi_dma_spk/M_AXI_SG] [get_bd_intf_pins axi_noc_0/S06_AXI]
  connect_bd_intf_net -intf_net axi_noc_0_CH0_LPDDR4_0 [get_bd_intf_ports ch0_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH0_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_CH1_LPDDR4_0 [get_bd_intf_ports ch1_lpddr4_trip1] [get_bd_intf_pins axi_noc_0/CH1_LPDDR4_0]
  connect_bd_intf_net -intf_net axi_noc_0_M00_AXI [get_bd_intf_pins smartconnect_0/S00_AXI] [get_bd_intf_pins axi_noc_0/M00_AXI]
  connect_bd_intf_net -intf_net bench_dma_aer_M_AXIS_SPK_MON [get_bd_intf_pins bench_dma_aer/M_AXIS_SPK_MON] [get_bd_intf_pins axi_dma_spk/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net lpddr4_clk1_1 [get_bd_intf_ports lpddr4_clk1] [get_bd_intf_pins axi_noc_0/sys_clk0]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axi_dma_spk/S_AXI_LITE]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins axi_gpio_ready_ev_to_ps/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins axi_gpio_free_slots_to_pl/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins axi_params_dma/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M04_AXI [get_bd_intf_pins smartconnect_0/M04_AXI] [get_bd_intf_pins bench_dma_aer/S_AXI_LITE_CONTROL]
  connect_bd_intf_net -intf_net smartconnect_0_M05_AXI [get_bd_intf_pins smartconnect_0/M05_AXI] [get_bd_intf_pins bench_dma_aer/S_AXI_LITE_STATUS]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_0/S00_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_0/S01_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_0/S02_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_0/S03_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_0/S04_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_0/S05_AXI]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins clk_wizard/clk_axi] [get_bd_pins bench_dma_aer/clk_axi] [get_bd_pins bench_dma_aer/S_AXI_LITE_CONTROL_ACLK] [get_bd_pins bench_dma_aer/S_AXI_LITE_STATUS_ACLK] [get_bd_pins bench_dma_aer/S_AXIS_SPK_IN_ACLK] [get_bd_pins bench_dma_aer/M_AXIS_SPK_MON_ACLK] [get_bd_pins axi_gpio_ready_ev_to_ps/S_AXI_ACLK] [get_bd_pins axi_dma_spk/s_axi_lite_aclk] [get_bd_pins axi_dma_spk/m_axi_sg_aclk] [get_bd_pins axi_dma_spk/m_axi_mm2s_aclk] [get_bd_pins axi_gpio_free_slots_to_pl/S_AXI_ACLK] [get_bd_pins axi_params_dma/s_axi_aclk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins axi_dma_spk/m_axi_s2mm_aclk] [get_bd_pins axi_noc_0/aclk6] [get_bd_pins axi_noc_0/aclk7] [get_bd_pins axi_noc_0/aclk8] [get_bd_pins proc_sys_reset_axi/slowest_sync_clk]
  connect_bd_net -net Net1 [get_bd_pins proc_sys_reset_axi/peripheral_aresetn] [get_bd_pins axi_gpio_free_slots_to_pl/S_AXI_ARESETN] [get_bd_pins axi_gpio_ready_ev_to_ps/S_AXI_ARESETN] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins bench_dma_aer/M_AXIS_SPK_MON_ARESETN] [get_bd_pins bench_dma_aer/S_AXIS_SPK_IN_ARESETN] [get_bd_pins bench_dma_aer/S_AXI_LITE_STATUS_ARESETN] [get_bd_pins bench_dma_aer/S_AXI_LITE_CONTROL_ARESETN] [get_bd_pins axi_dma_spk/axi_resetn] [get_bd_pins axi_params_dma/s_axi_aresetn]
  connect_bd_net -net Net2 [get_bd_pins axi_params_dma/gpio2_io_o] [get_bd_pins axi_noc_0/S08_AXI_arprot] [get_bd_pins axi_noc_0/S08_AXI_awprot] [get_bd_pins axi_noc_0/S07_AXI_arprot] [get_bd_pins axi_noc_0/S07_AXI_awprot] [get_bd_pins axi_noc_0/S06_AXI_arprot] [get_bd_pins axi_noc_0/S06_AXI_awprot]
  connect_bd_net -net axi_dma_spk_mm2s_introut [get_bd_pins axi_dma_spk/mm2s_introut] [get_bd_pins versal_cips_0/pl_ps_irq8]
  connect_bd_net -net axi_dma_spk_s2mm_introut [get_bd_pins axi_dma_spk/s2mm_introut] [get_bd_pins versal_cips_0/pl_ps_irq9]
  connect_bd_net -net axi_gpio_free_slots_to_pl_data_from_ps [get_bd_pins axi_gpio_free_slots_to_pl/data_from_ps] [get_bd_pins bench_dma_aer/dma_spk_i_fifo2pl_used_slots_ps]
  connect_bd_net -net axi_gpio_free_slots_to_pl_pl_intr [get_bd_pins axi_gpio_free_slots_to_pl/pl_intr] [get_bd_pins versal_cips_0/pl_ps_irq11]
  connect_bd_net -net axi_gpio_free_slots_to_pl_ps_intr [get_bd_pins axi_gpio_free_slots_to_pl/ps_intr] [get_bd_pins bench_dma_aer/dma_spk_i_fifo2pl_used_slots_ps_intr]
  connect_bd_net -net axi_gpio_ready_ev_to_ps_data_from_ps [get_bd_pins axi_gpio_ready_ev_to_ps/data_from_ps] [get_bd_pins bench_dma_aer/dma_spk_o_fifo2ps_size_rd_ev_ps]
  connect_bd_net -net axi_gpio_ready_ev_to_ps_pl_intr [get_bd_pins axi_gpio_ready_ev_to_ps/pl_intr] [get_bd_pins versal_cips_0/pl_ps_irq10]
  connect_bd_net -net axi_gpio_ready_ev_to_ps_ps_intr [get_bd_pins axi_gpio_ready_ev_to_ps/ps_intr] [get_bd_pins bench_dma_aer/dma_spk_o_fifo2ps_rd_ev_ps_intr]
  connect_bd_net -net axi_params_dma_gpio_io_o [get_bd_pins axi_params_dma/gpio_io_o] [get_bd_pins axi_noc_0/S06_AXI_awcache] [get_bd_pins axi_noc_0/S06_AXI_arcache] [get_bd_pins axi_noc_0/S07_AXI_awcache] [get_bd_pins axi_noc_0/S07_AXI_arcache] [get_bd_pins axi_noc_0/S08_AXI_awcache] [get_bd_pins axi_noc_0/S08_AXI_arcache]
  connect_bd_net -net bench_dma_aer_dma_spk_i_fifo2pl_free_slots_pl [get_bd_pins bench_dma_aer/dma_spk_i_fifo2pl_free_slots_pl] [get_bd_pins axi_gpio_free_slots_to_pl/data_to_ps]
  connect_bd_net -net bench_dma_aer_dma_spk_i_fifo2pl_free_slots_pl_intr [get_bd_pins bench_dma_aer/dma_spk_i_fifo2pl_free_slots_pl_intr] [get_bd_pins axi_gpio_free_slots_to_pl/pl_irpt_trigger]
  connect_bd_net -net bench_dma_aer_dma_spk_o_fifo2ps_size_wr_ev_pl [get_bd_pins bench_dma_aer/dma_spk_o_fifo2ps_size_wr_ev_pl] [get_bd_pins axi_gpio_ready_ev_to_ps/data_to_ps]
  connect_bd_net -net bench_dma_aer_dma_spk_o_fifo2ps_wr_ev_pl_intr [get_bd_pins bench_dma_aer/dma_spk_o_fifo2ps_wr_ev_pl_intr] [get_bd_pins axi_gpio_ready_ev_to_ps/pl_irpt_trigger]
  connect_bd_net -net clk_wizard_clk_pl [get_bd_pins clk_wizard/clk_pl] [get_bd_pins bench_dma_aer/clk_pl]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk0]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk] [get_bd_pins axi_noc_0/aclk1]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk] [get_bd_pins axi_noc_0/aclk2]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk] [get_bd_pins axi_noc_0/aclk3]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk [get_bd_pins versal_cips_0/lpd_axi_noc_clk] [get_bd_pins axi_noc_0/aclk4]
  connect_bd_net -net versal_cips_0_pl0_ref_clk [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins clk_wizard/clk_in1]
  connect_bd_net -net versal_cips_0_pl0_resetn [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins proc_sys_reset_axi/ext_reset_in]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] [get_bd_pins axi_noc_0/aclk5]

  # Create address segments
  assign_bd_address -offset 0x020100020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_dma_spk/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x020100010000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_gpio_free_slots_to_pl/S_AXI/reg0] -force
  assign_bd_address -offset 0x020100011000 -range 0x00001000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_gpio_ready_ev_to_ps/S_AXI/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x020100030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_params_dma/S_AXI/Reg] -force
  assign_bd_address -offset 0x020100000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs bench_dma_aer/S_AXI_LITE_CONTROL/reg0] -force
  assign_bd_address -offset 0x020100008000 -range 0x00008000 -with_name SEG_bench_dma_aer_reg0_1 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs bench_dma_aer/S_AXI_LITE_STATUS/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C3_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_spk/Data_MM2S] [get_bd_addr_segs axi_noc_0/S07_AXI/C1_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_spk/Data_MM2S] [get_bd_addr_segs axi_noc_0/S07_AXI/C1_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_spk/Data_S2MM] [get_bd_addr_segs axi_noc_0/S08_AXI/C2_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_spk/Data_S2MM] [get_bd_addr_segs axi_noc_0/S08_AXI/C2_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_spk/Data_SG] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_dma_spk/Data_SG] [get_bd_addr_segs axi_noc_0/S06_AXI/C0_DDR_LOW1] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.489565",
   "Default View_TopLeft":"-170,2",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.5.8 2022-09-21 7111 VDI=41 GEI=38 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port ch0_lpddr4_trip1 -pg 1 -lvl 5 -x 2300 -y 660 -defaultsOSRD
preplace port ch1_lpddr4_trip1 -pg 1 -lvl 5 -x 2300 -y 680 -defaultsOSRD
preplace port lpddr4_clk1 -pg 1 -lvl 0 -x 0 -y 910 -defaultsOSRD
preplace inst versal_cips_0 -pg 1 -lvl 3 -x 1440 -y 890 -defaultsOSRD
preplace inst axi_noc_0 -pg 1 -lvl 4 -x 2060 -y 660 -defaultsOSRD
preplace inst axi_dma_spk -pg 1 -lvl 3 -x 1440 -y 550 -defaultsOSRD
preplace inst clk_wizard -pg 1 -lvl 1 -x 240 -y 640 -defaultsOSRD
preplace inst bench_dma_aer -pg 1 -lvl 2 -x 820 -y 660 -defaultsOSRD
preplace inst axi_gpio_free_slots_to_pl -pg 1 -lvl 2 -x 820 -y 110 -defaultsOSRD
preplace inst axi_gpio_ready_ev_to_ps -pg 1 -lvl 2 -x 820 -y 1010 -defaultsOSRD
preplace inst axi_params_dma -pg 1 -lvl 2 -x 820 -y 310 -defaultsOSRD
preplace inst smartconnect_0 -pg 1 -lvl 1 -x 240 -y 480 -defaultsOSRD
preplace inst proc_sys_reset_axi -pg 1 -lvl 1 -x 240 -y 790 -defaultsOSRD
preplace netloc Net 1 0 4 40 360 450 890 1170 1090 1840
preplace netloc Net1 1 0 3 60 370 460 1110 1180
preplace netloc Net2 1 2 2 NJ 340 1790
preplace netloc axi_dma_spk_mm2s_introut 1 2 2 1200 1110 1690
preplace netloc axi_dma_spk_s2mm_introut 1 2 2 1210 1100 1670
preplace netloc axi_gpio_free_slots_to_pl_data_from_ps 1 1 2 500 400 1130
preplace netloc axi_gpio_free_slots_to_pl_pl_intr 1 2 1 1150 110n
preplace netloc axi_gpio_free_slots_to_pl_ps_intr 1 1 2 510 410 1120
preplace netloc axi_gpio_ready_ev_to_ps_data_from_ps 1 1 2 480 900 1120
preplace netloc axi_gpio_ready_ev_to_ps_pl_intr 1 2 1 1190 900n
preplace netloc axi_gpio_ready_ev_to_ps_ps_intr 1 1 2 520 1120 1120
preplace netloc axi_params_dma_gpio_io_o 1 2 2 NJ 300 1810
preplace netloc bench_dma_aer_dma_spk_i_fifo2pl_free_slots_pl 1 1 2 480 440 1120
preplace netloc bench_dma_aer_dma_spk_i_fifo2pl_free_slots_pl_intr 1 1 2 490 880 1120
preplace netloc bench_dma_aer_dma_spk_o_fifo2ps_size_wr_ev_pl 1 1 2 510 1130 1140
preplace netloc bench_dma_aer_dma_spk_o_fifo2ps_wr_ev_pl_intr 1 1 2 500 1140 1130
preplace netloc clk_wizard_clk_pl 1 1 1 470J 560n
preplace netloc versal_cips_0_fpd_cci_noc_axi0_clk 1 3 1 1780 800n
preplace netloc versal_cips_0_fpd_cci_noc_axi1_clk 1 3 1 1790 820n
preplace netloc versal_cips_0_fpd_cci_noc_axi2_clk 1 3 1 1800 840n
preplace netloc versal_cips_0_fpd_cci_noc_axi3_clk 1 3 1 1810 860n
preplace netloc versal_cips_0_lpd_axi_noc_clk 1 3 1 1820 880n
preplace netloc versal_cips_0_pl0_ref_clk 1 0 4 50 220 NJ 220 NJ 220 1680
preplace netloc versal_cips_0_pl0_resetn 1 0 4 20 210 NJ 210 NJ 210 1700
preplace netloc versal_cips_0_pmc_axi_noc_axi0_clk 1 3 1 1830 900n
preplace netloc axi_dma_spk_M_AXIS_MM2S 1 1 3 520 420 NJ 420 1670
preplace netloc axi_dma_spk_M_AXI_MM2S 1 3 1 1800 500n
preplace netloc axi_dma_spk_M_AXI_S2MM 1 3 1 1780 520n
preplace netloc axi_dma_spk_M_AXI_SG 1 3 1 N 480
preplace netloc axi_noc_0_CH0_LPDDR4_0 1 4 1 NJ 660
preplace netloc axi_noc_0_CH1_LPDDR4_0 1 4 1 NJ 680
preplace netloc axi_noc_0_M00_AXI 1 0 5 30 10 NJ 10 NJ 10 NJ 10 2280
preplace netloc bench_dma_aer_M_AXIS_SPK_MON 1 2 1 1130 510n
preplace netloc lpddr4_clk1_1 1 0 4 NJ 910 NJ 910 1160J 690 1750J
preplace netloc smartconnect_0_M00_AXI 1 1 2 N 430 1130J
preplace netloc smartconnect_0_M01_AXI 1 1 1 430 450n
preplace netloc smartconnect_0_M02_AXI 1 1 1 420 70n
preplace netloc smartconnect_0_M03_AXI 1 1 1 440 290n
preplace netloc smartconnect_0_M04_AXI 1 1 1 440 510n
preplace netloc smartconnect_0_M05_AXI 1 1 1 420 530n
preplace netloc versal_cips_0_FPD_CCI_NOC_0 1 3 1 1710 360n
preplace netloc versal_cips_0_FPD_CCI_NOC_1 1 3 1 1720 380n
preplace netloc versal_cips_0_FPD_CCI_NOC_2 1 3 1 1730 400n
preplace netloc versal_cips_0_FPD_CCI_NOC_3 1 3 1 1740 420n
preplace netloc versal_cips_0_LPD_AXI_NOC_0 1 3 1 1760 440n
preplace netloc versal_cips_0_PMC_NOC_AXI_0 1 3 1 1770 460n
levelinfo -pg 1 0 240 820 1440 2060 2300
pagesize -pg 1 -db -bbox -sgen -140 0 2470 1150
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


