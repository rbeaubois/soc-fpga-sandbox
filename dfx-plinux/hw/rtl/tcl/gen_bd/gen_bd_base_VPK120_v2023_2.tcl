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
# 
# @details 
# > **13 Feb 2025** : file creation (RB)

# ========================================
# Generics
# ========================================

# General
set BD_NAME "bd"
set UUID    000

# Clock frequencies (has to be set manually in bd or clocking wizard due to errors in IP)
set FREQ_MHZ_CLK_PL   400.000 
set FREQ_MHZ_CLK_AXI  200.000
set FREQ_MHZ_CLK_EXT   50.000

# IPs
set ip_labels [dict create \
  versal_cips versal_cips \
]

# ========================================
# Initialization
# ========================================

# Block design
create_bd_design $BD_NAME

# ========================================
# VERSAL CIPS: versal_cips
# ========================================

  # Create IP
  create_bd_cell -type ip -vlnv xilinx.com:ip:[dict get $ip_labels versal_cips] versal_cips

  # Apply board automation (boards presets)
#  apply_bd_automation -rule xilinx.com:bd_rule:cips -config {
#    board_preset {Yes}
#    boot_config {Custom}
#    configure_noc {Add new AXI NoC}
#    debug_config {JTAG}
#    design_flow {Full System}
#    mc_type {None}
#    num_mc_ddr {None}
#    num_mc_lpddr {None}
#    pl_clocks {None}
#    pl_resets {None}
#  }  [get_bd_cells versal_cips]

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

  ## Automatically assign remaining segments
  assign_bd_address
