# ========================================
# Initialization
# ========================================
# Block design
	create_bd_design "bd"

# HDL generics
    # Clocks
    set FREQ_MHZ_CLK_RTL 400
    set FREQ_MHZ_CLK_AXI 200
    set FREQ_MHZ_CLK_EXT  50

    # Address map
    set OFFSET_AXIGPIO_UUID   0xA0000000
    set RANGE_AXIGPIO_UUID            4K

# ========================================
# Functions
# ========================================
proc id2str {id} {
	return [format "%02d" $id]
}

# ========================================
# Zynq / clocks / resets
# ========================================
# Zynq MPSoC PS
	set this_ip zynq_ultra_ps_e
	create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e $this_ip
	apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells $this_ip]
	
	## Add PS-PL Slave Interface
	set_property CONFIG.PSU__USE__S_AXI_GP0 {1} [get_bd_cells $this_ip]
	set_property CONFIG.PSU__USE__S_AXI_GP1 {1} [get_bd_cells $this_ip]
	
	## Add second slot of PL interrupts
	set_property CONFIG.PSU__USE__IRQ1 {1} [get_bd_cells $this_ip]

# Clocking wizard
	## Create IP
	set this_ip clk_wiz
	create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz $this_ip
	set_property -dict [list \
	  CONFIG.CLK_OUT1_PORT {clk_rtl} \
	  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $FREQ_MHZ_CLK_RTL \
	  CONFIG.CLK_OUT2_PORT {clk_axi} \
	  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $FREQ_MHZ_CLK_AXI \
	  CONFIG.CLKOUT2_USED {true} \
	  CONFIG.CLK_OUT3_PORT {clk_ext} \
	  CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $FREQ_MHZ_CLK_EXT \
	  CONFIG.CLKOUT3_USED {true} \
	  CONFIG.PRIM_SOURCE {Global_buffer} \
	  CONFIG.USE_LOCKED {false} \
	  CONFIG.USE_RESET {false} \
	] [get_bd_cells $this_ip]

	## Connect source clock
	connect_bd_net [get_bd_pins zynq_ultra_ps_e/pl_clk0] [get_bd_pins $this_ip/clk_in1]
	
	## Connect clock PS-PL interfaces
	connect_bd_net [get_bd_pins $this_ip/clk_axi] [get_bd_pins zynq_ultra_ps_e/saxihpc0_fpd_aclk]
	connect_bd_net [get_bd_pins $this_ip/clk_axi] [get_bd_pins zynq_ultra_ps_e/saxihpc1_fpd_aclk]
	connect_bd_net [get_bd_pins $this_ip/clk_axi] [get_bd_pins zynq_ultra_ps_e/maxihpm0_fpd_aclk]
	connect_bd_net [get_bd_pins $this_ip/clk_axi] [get_bd_pins zynq_ultra_ps_e/maxihpm1_fpd_aclk]

# Processor reset
	## Create IP
	set this_ip proc_sys_reset_axi_domain
	create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset $this_ip

	## Connect reset source
	connect_bd_net [get_bd_pins $this_ip/ext_reset_in] [get_bd_pins zynq_ultra_ps_e/pl_resetn0]
	
	## Connect slowest sync clock
	connect_bd_net [get_bd_pins $this_ip/slowest_sync_clk] [get_bd_pins clk_wiz/clk_axi]

# ========================================
# Soc PS-PL MASTER interface
# ========================================
# AXI Interconnect PS-PL Master interfaces to AXI-Lite
	## Create IP
	set this_ip pspl_m00_intf_interco
	set NB_SI 2
	set NB_MI 1
	set pspl_m00_intf_interco_mid 0
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect $this_ip
	set_property -dict [list \
	  CONFIG.NUM_SI $NB_SI \
	  CONFIG.NUM_MI $NB_MI \
	] [get_bd_cells $this_ip]
	
	## Connect clocks
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/ACLK]
	for {set i 0} {$i < $NB_SI} {incr i} {
	  connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/S[id2str $i]_ACLK]
	}
	for {set i 0} {$i < $NB_MI} {incr i} {
	  connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/M[id2str $i]_ACLK]
	}

	## Connect resets
	connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/ARESETN]
	for {set i 0} {$i < $NB_SI} {incr i} {
	  connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/S[id2str $i]_ARESETN]
	}
	for {set i 0} {$i < $NB_MI} {incr i} {
	  connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/M[id2str $i]_ARESETN]
	}

	## Connect interface PS Masters
	connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e/M_AXI_HPM0_FPD] -boundary_type upper [get_bd_intf_pins $this_ip/S00_AXI]
	connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e/M_AXI_HPM1_FPD] -boundary_type upper [get_bd_intf_pins $this_ip/S01_AXI]

# ========================================
# Fan
# ========================================
# Fan control
	## Create output
	create_bd_port -dir O -from 0 -to 0 fan_pwm_ctrl

	## PWM Fan control from fan control driver
	set_property -dict [list \
	  CONFIG.PSU__TTC0__WAVEOUT__ENABLE {1} \
	  CONFIG.PSU__TTC0__WAVEOUT__IO {EMIO} \
	] [get_bd_cells zynq_ultra_ps_e]

	## Extract MSB fan pwm
	create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice extract_bit_pwm_fan_driver
	set_property -dict [list \
	  CONFIG.DIN_FROM {2} \
	  CONFIG.DIN_TO {2} \
	  CONFIG.DIN_WIDTH {3} \
	] [get_bd_cells extract_bit_pwm_fan_driver]

	## Connect IP and ports
	connect_bd_net [get_bd_pins zynq_ultra_ps_e/emio_ttc0_wave_o] [get_bd_pins extract_bit_pwm_fan_driver/Din]
	connect_bd_net [get_bd_pins /extract_bit_pwm_fan_driver/Dout] [get_bd_ports fan_pwm_ctrl]

# ========================================
# AXI GPIO
# ========================================
# AXI GPIO - UUID
	## Create IP
	set this_ip axi_gpio_uuid
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio $this_ip
	set_property -dict [list \
	  CONFIG.C_ALL_INPUTS {1} \
	  CONFIG.C_IS_DUAL {0} \
	  CONFIG.C_INTERRUPT_PRESENT {0} \
	] [get_bd_cells $this_ip]

	## Connect clock and resets
	connect_bd_net [get_bd_pins $this_ip/s_axi_aclk] [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins $this_ip/s_axi_aresetn] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]
	
	## Connect to PS Master
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid

# ========================================
# Top design
# ========================================
	set this_ip top
	create_bd_cell -type module -reference top $this_ip

	## Connect clocks and resets
	connect_bd_net [get_bd_pins /$this_ip/clk_rtl] [get_bd_pins clk_wiz/clk_rtl]
	connect_bd_net [get_bd_pins /$this_ip/clk_axi] [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins /$this_ip/clk_ext] [get_bd_pins clk_wiz/clk_ext]

	## Connect AXI GPIO UUID
	connect_bd_net [get_bd_pins /$this_ip/uuid] [get_bd_pins axi_gpio_uuid/gpio_io_i]

	## Connect I/O
	create_bd_port -dir O uled_uf1
	create_bd_port -dir O uled_uf2

	connect_bd_net [get_bd_pins /$this_ip/uled_uf1] [get_bd_ports uled_uf1]
	connect_bd_net [get_bd_pins /$this_ip/uled_uf2] [get_bd_ports uled_uf2]

# ===============
# Address mapping
# ===============
# Address map
   ## Force mapping
   set addr_map {
      "/axi_gpio_uuid/S_AXI/Reg"	 {offset "$OFFSET_AXIGPIO_UUID" range "$RANGE_AXIGPIO_UUID"}
   }

   foreach seg [dict keys $addr_map] {
      # Get mapping parameters
      set offset [dict get $addr_map $seg offset]
      set range  [dict get $addr_map $seg range]
      set offset [expr "$offset"]
	  set range [expr "$range"]

      # Apply the assign_bd_address command for each entry in the dictionary
      assign_bd_address -target_address_space /zynq_ultra_ps_e/Data \
         [get_bd_addr_segs $seg] \
         -force \
         -offset $offset \
         -range $range
   }

   ## Automatically assign remaining segments
   assign_bd_address