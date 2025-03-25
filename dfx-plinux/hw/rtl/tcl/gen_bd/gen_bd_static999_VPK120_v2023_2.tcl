# @title  Base project for VPK120
# @file		gen_bd_base_vpk120.tcl
# @author	Romain Beaubois
# @date		13 Feb 2025
# @copyright
# SPDX-FileCopyrightText: © 2025 Romain Beaubois <refbeaubois@yahoo.com>
# SPDX-License-Identifier: MIT
# 
# @brief Base project for VPK120
# * Versal CIPS in "standalone" (not PCIE)
# * PS Noc
# * Clocking wizard generating 3 PL clocks (pl, axi, external)
# * AXI GPIO with fixed uuid (unique identifier) to help identifying configuration loaded
# 
# @details 
# > **13 Feb 2025** : file creation (RB)

# ========================================
# Generics
# ========================================

# General
set BD_NAME "bd"
set UUID    999

# Clock frequencies (has to be set manually in bd or clocking wizard due to errors in IP)
set FREQ_MHZ_CLK_PL   400.000 
set FREQ_MHZ_CLK_AXI  200.000
set FREQ_MHZ_CLK_EXT   50.000

# IPs
set ip_labels [dict create \
  versal_cips versal_cips \
  main_clk_wiz clk_wizard \
  main_noc axi_noc \
  axi_gpio_uuid axi_gpio \
  aximm_to_axil smartconnect \
  proc_reset_axi proc_sys_reset \
  uuid_cst xlconstant \
]

# ========================================
# Initialization
# ========================================

# Block design
create_bd_design $BD_NAME

# ========================================
# Clocking wizard: main_clk_wiz
# 
# * can't set frequencies from variables for Versal IP (issue with parameters checking)
# ========================================

  # Create IP
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels main_clk_wiz] main_clk_wiz

  # Configure
  set_property -dict [list \
    CONFIG.CLKOUT_DRIVES                  {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
    CONFIG.CLKOUT_DYN_PS                  {None,None,None,None,None,None,None} \
    CONFIG.CLKOUT_GROUPING                {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
    CONFIG.CLKOUT_MATCHED_ROUTING         {false,false,false,false,false,false,false} \
    CONFIG.CLKOUT_PORT                    {clk_pl,clk_axi,clk_ext,clk_out4,clk_out5,clk_out6,clk_out7} \
    CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE    {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {400.000,200.000,50.000,100.000,100.000,100.000,100.000} \
    CONFIG.CLKOUT_REQUESTED_PHASE         {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
    CONFIG.CLKOUT_USED                    {true,true,true,false,false,false,false} \
    CONFIG.PRIM_SOURCE                    {Global_buffer} \
  ] [get_bd_cells main_clk_wiz]

# ========================================
# Processor reset: proc_reset_axi
# ========================================
  # Create IP
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels proc_reset_axi] proc_reset_axi

  # Connect sync clock
  connect_bd_net [get_bd_pins proc_reset_axi/slowest_sync_clk] [get_bd_pins main_clk_wiz/clk_axi]

# ========================================
# VERSAL CIPS: versal_cips
# ========================================

  # Create IP
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels versal_cips] versal_cips

  # Apply board automation (boards presets)
  apply_bd_automation -rule xilinx.com:bd_rule:cips -config {
    board_preset {Yes}
    boot_config {Custom}
    configure_noc {Add new AXI NoC}
    debug_config {JTAG}
    design_flow {Full System}
    mc_type {LPDDR}
    num_mc_ddr {None}
    num_mc_lpddr {1}
    pl_clocks {1}
    pl_resets {1}
  } [get_bd_cells versal_cips]

  # Rename AXI NOC and add extra clock interface (clk_axi)
  set_property name main_noc [get_bd_cells axi_noc_0]
  set_property CONFIG.NUM_CLKS {7} [get_bd_cells main_noc]
  connect_bd_net [get_bd_pins main_noc/aclk6] [get_bd_pins main_clk_wiz/clk_axi]

  # Connect PL clock and resets from CIPS
  connect_bd_net [get_bd_pins versal_cips/pl0_ref_clk] [get_bd_pins main_clk_wiz/clk_in1]
  connect_bd_net [get_bd_pins versal_cips/pl0_resetn] [get_bd_pins proc_reset_axi/ext_reset_in]

# ========================================
# AXI GPIO UUID: axi_gpio_uuid
# ========================================
  # Create IP
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels axi_gpio_uuid] axi_gpio_uuid

  # Configure IP
  set_property CONFIG.C_ALL_INPUTS {1} [get_bd_cells axi_gpio_uuid]

  # Add new Master AXI to Main NoC
  set_property CONFIG.NUM_MI {1} [get_bd_cells main_noc]
  set_property -dict [list \
    CONFIG.CONNECTIONS {
      M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}
      MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}
    } \
  ] [get_bd_intf_pins /main_noc/S00_AXI]
  set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI:M00_AXI}] [get_bd_pins /main_noc/aclk0]

  # Add interconnect for AXIMM to AXI-LITE
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels aximm_to_axil] aximm_to_axil
  set_property CONFIG.NUM_SI {1} [get_bd_cells aximm_to_axil]
  connect_bd_net [get_bd_pins main_clk_wiz/clk_axi] [get_bd_pins aximm_to_axil/aclk]
  connect_bd_net [get_bd_pins proc_reset_axi/peripheral_aresetn] [get_bd_pins aximm_to_axil/aresetn]

  # Connect AXI NOC to Interconnect
  connect_bd_intf_net [get_bd_intf_pins main_noc/M00_AXI] [get_bd_intf_pins aximm_to_axil/S00_AXI]

  # Connect AXI GPIO
  connect_bd_intf_net [get_bd_intf_pins aximm_to_axil/M00_AXI] [get_bd_intf_pins axi_gpio_uuid/S_AXI]
  connect_bd_net [get_bd_pins main_clk_wiz/clk_axi] [get_bd_pins axi_gpio_uuid/s_axi_aclk]
  connect_bd_net [get_bd_pins proc_reset_axi/peripheral_aresetn] [get_bd_pins axi_gpio_uuid/s_axi_aresetn]

  # Create and set uuid
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels uuid_cst] uuid_cst
  set_property -dict [list \
    CONFIG.CONST_VAL $UUID \
    CONFIG.CONST_WIDTH {32} \
  ] [get_bd_cells uuid_cst]
  connect_bd_net [get_bd_pins uuid_cst/dout] [get_bd_pins axi_gpio_uuid/gpio_io_i]

  # ===============
  # Address mapping
  # ===============
  ## Force mapping
  set addr_map {
      "/axi_gpio_uuid/S_AXI/Reg" {offset 0x201C0000000 range  64K}
  }

  foreach seg [dict keys $addr_map] {
      # Get mapping parameters
      set offset [dict get $addr_map $seg offset]
      set range  [dict get $addr_map $seg range]

      # Apply the assign_bd_address command for each entry in the dictionary
      assign_bd_address -target_address_space /versal_cips/FPD_CCI_NOC_0 \
          [get_bd_addr_segs $seg] \
          -force \
          -offset $offset \
          -range $range
  }

  ## Automatically assign remaining segments
  assign_bd_address