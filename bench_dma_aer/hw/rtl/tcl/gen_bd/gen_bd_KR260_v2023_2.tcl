# ========================================
# Initialization
# ========================================
# Block design
	create_bd_design "bd"

# HDL generics
	set FREQ_MHZ_CLK_RTL 400
	set FREQ_MHZ_CLK_AXI 200
	set FREQ_MHZ_CLK_EXT  50

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
	  CONFIG.CLKOUT1_JITTER {90.074} \
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
	set NB_MI 7
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
# Soc PS-PL SLAVE interface
# ========================================
# AXI Interconnect PS-PL Slave interface 0
	## Create IP
	set this_ip pspl_s00_intf_interco
	set NB_SI 3
	set NB_MI 1
	set pspl_s00_intf_interco_sid 0
	create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect $this_ip
	set_property -dict [list \
	  CONFIG.NUM_SI $NB_SI \
	  CONFIG.NUM_MI $NB_MI \
	] [get_bd_cells $this_ip]
	
	## Connect clocks and resets
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/aclk]
	connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/aresetn]
	
	## Connect to PS-PL Slave interface
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e/S_AXI_HPC0_FPD]

# AXI Interconnect PS-PL Slave interface 1
	## Create IP
	set this_ip pspl_s01_intf_interco
	set NB_SI 3
	set NB_MI 1
	set pspl_s01_intf_interco_sid 0
	create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect $this_ip
	set_property -dict [list \
	  CONFIG.NUM_SI $NB_SI \
	  CONFIG.NUM_MI $NB_MI \
	] [get_bd_cells $this_ip]
	
	## Connect clocks and resets
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/aclk]
	connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/aresetn]
	
	## Connect to PS-PL Slave interface
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e/S_AXI_HPC1_FPD]

# ========================================
# ---
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
# DMAs
# ========================================
# DMA spikes AER
	## Setup AXI DMA IP
	set this_ip axi_dma_spk_aer
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma $this_ip
	set_property -dict [list CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER] [get_bd_cells $this_ip]
	set_property -dict [list \
	  CONFIG.c_addr_width {64} \
	  CONFIG.c_m_axi_mm2s_data_width {64} \
	  CONFIG.c_m_axi_s2mm_data_width {64} \
	  CONFIG.c_mm2s_burst_size {256} \
	  CONFIG.c_s2mm_burst_size {256} \
	  CONFIG.c_sg_include_stscntrl_strm {0} \
	  CONFIG.c_sg_length_width {16} \
	] [get_bd_cells $this_ip]
	
	## Connect clocks and resets
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/s_axi_lite_aclk]
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/m_axi_sg_aclk]
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/m_axi_mm2s_aclk]
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/m_axi_s2mm_aclk]
	connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/axi_resetn]
	
	## Connect AXI-LITE
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI_LITE] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	
	###
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXI_SG]   [get_bd_intf_pins pspl_s00_intf_interco/S[id2str $pspl_s00_intf_interco_sid]_AXI]; incr pspl_s00_intf_interco_sid
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXI_MM2S] [get_bd_intf_pins pspl_s00_intf_interco/S[id2str $pspl_s00_intf_interco_sid]_AXI]; incr pspl_s00_intf_interco_sid
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXI_S2MM] [get_bd_intf_pins pspl_s00_intf_interco/S[id2str $pspl_s00_intf_interco_sid]_AXI]; incr pspl_s00_intf_interco_sid

# DMA samples
	## Setup AXI DMA IP
	set this_ip axi_dma_sps
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma $this_ip
	set_property -dict [list CONFIG.c_m_axi_s2mm_data_width.VALUE_SRC USER] [get_bd_cells $this_ip]
	set_property -dict [list \
	  CONFIG.c_addr_width {64} \
	  CONFIG.c_m_axi_mm2s_data_width {64} \
	  CONFIG.c_m_axi_s2mm_data_width {64} \
	  CONFIG.c_mm2s_burst_size {256} \
	  CONFIG.c_s2mm_burst_size {256} \
	  CONFIG.c_sg_include_stscntrl_strm {0} \
	  CONFIG.c_sg_length_width {16} \
	] [get_bd_cells $this_ip]
	
	## Connect clocks and resets
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/s_axi_lite_aclk]
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/m_axi_sg_aclk]
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/m_axi_mm2s_aclk]
	connect_bd_net [get_bd_pins clk_wiz/clk_axi] [get_bd_pins $this_ip/m_axi_s2mm_aclk]
	connect_bd_net [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn] [get_bd_pins $this_ip/axi_resetn]
	
	## Connect AXI-LITE
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI_LITE] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	
	###
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXI_SG]   [get_bd_intf_pins pspl_s01_intf_interco/S[id2str $pspl_s01_intf_interco_sid]_AXI]; incr pspl_s01_intf_interco_sid
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXI_MM2S] [get_bd_intf_pins pspl_s01_intf_interco/S[id2str $pspl_s01_intf_interco_sid]_AXI]; incr pspl_s01_intf_interco_sid
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXI_S2MM] [get_bd_intf_pins pspl_s01_intf_interco/S[id2str $pspl_s01_intf_interco_sid]_AXI]; incr pspl_s01_intf_interco_sid

# AXI GPIO - AXI Parameters
	## Create IP
	set this_ip axi_params_dma
	set DWIDTH_AXACHE 4
	set DWIDTH_AXPROT 3
	create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio $this_ip
	set_property -dict [list \
	  CONFIG.C_IS_DUAL {1} \
	  CONFIG.C_ALL_OUTPUTS {1} \
	  CONFIG.C_ALL_OUTPUTS_2 {1} \
	  CONFIG.C_GPIO_WIDTH $DWIDTH_AXACHE \
	  CONFIG.C_GPIO2_WIDTH $DWIDTH_AXPROT \
	] [get_bd_cells $this_ip]

	## Connect clock and resets
	connect_bd_net [get_bd_pins $this_ip/s_axi_aclk] [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins $this_ip/s_axi_aresetn] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]
	
	## Connect to PS Master
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	
	## Connect AXI signals
	connect_bd_net [get_bd_pins $this_ip/gpio_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp0_awcache]
	connect_bd_net [get_bd_pins $this_ip/gpio_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp0_arcache]
	connect_bd_net [get_bd_pins $this_ip/gpio_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp1_awcache]
	connect_bd_net [get_bd_pins $this_ip/gpio_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp1_arcache]
	
	connect_bd_net [get_bd_pins $this_ip/gpio2_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp0_awprot]
	connect_bd_net [get_bd_pins $this_ip/gpio2_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp0_arprot]
	connect_bd_net [get_bd_pins $this_ip/gpio2_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp1_awprot]
	connect_bd_net [get_bd_pins $this_ip/gpio2_io_o] [get_bd_pins zynq_ultra_ps_e/saxigp1_arprot]

# AXI GPIO - Free slots to PL
	## Add module to block design
	set this_ip axigpio_free_slots_to_pl
	create_bd_cell -type module -reference axigpio_dualch_intr $this_ip
	
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_ACLK]    [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_ARESETN] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]

# AXI GPIO - Ready evevents to PS
	## Add module to block design
	set this_ip axigpio_ready_ev_to_ps
	create_bd_cell -type module -reference axigpio_dualch_intr $this_ip

	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_ACLK]    [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_ARESETN] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]
	
# Top design
	set this_ip bench_dmas
	create_bd_cell -type module -reference top $this_ip

	## Connect clocks and resets
	connect_bd_net [get_bd_pins /$this_ip/clk_pl]  [get_bd_pins clk_wiz/clk_rtl]
	connect_bd_net [get_bd_pins /$this_ip/clk_axi] [get_bd_pins clk_wiz/clk_axi]
	
	## Connect AXI-Lite interfaces
	set this_axi CONTROL
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI_LITE_${this_axi}] -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_LITE_${this_axi}_ACLK]    [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_LITE_${this_axi}_ARESETN] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]

	set this_axi STATUS
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXI_LITE_${this_axi}]  -boundary_type upper [get_bd_intf_pins pspl_m00_intf_interco/M[id2str $pspl_m00_intf_interco_mid]_AXI]; incr pspl_m00_intf_interco_mid
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_LITE_${this_axi}_ACLK]    [get_bd_pins clk_wiz/clk_axi]
	connect_bd_net [get_bd_pins /$this_ip/S_AXI_LITE_${this_axi}_ARESETN] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]
	
	## Connect DMA interfaces
	### -- spikes
    set this_axi SPK2PL
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXIS_${this_axi}]     [get_bd_intf_pins axi_dma_spk_aer/M_AXIS_MM2S]
    connect_bd_net      [get_bd_pins $this_ip/S_AXIS_${this_axi}_ACLK]     [get_bd_pins clk_wiz/clk_axi]
    connect_bd_net      [get_bd_pins $this_ip/S_AXIS_${this_axi}_ARESETN]  [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]

    set this_axi SPK2PS
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXIS_${this_axi}]     [get_bd_intf_pins axi_dma_spk_aer/S_AXIS_S2MM]
    connect_bd_net      [get_bd_pins $this_ip/M_AXIS_${this_axi}_ACLK]     [get_bd_pins clk_wiz/clk_axi]
    connect_bd_net      [get_bd_pins $this_ip/M_AXIS_${this_axi}_ARESETN]  [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]

	### -- samples
	set this_axi SPS2PL
	connect_bd_intf_net [get_bd_intf_pins $this_ip/S_AXIS_${this_axi}]     [get_bd_intf_pins axi_dma_sps/M_AXIS_MM2S]
    connect_bd_net      [get_bd_pins $this_ip/S_AXIS_${this_axi}_ACLK]     [get_bd_pins clk_wiz/clk_axi]
    connect_bd_net      [get_bd_pins $this_ip/S_AXIS_${this_axi}_ARESETN]  [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]

	set this_axi SPS2PS
	connect_bd_intf_net [get_bd_intf_pins $this_ip/M_AXIS_${this_axi}]     [get_bd_intf_pins axi_dma_sps/S_AXIS_S2MM]
    connect_bd_net      [get_bd_pins $this_ip/M_AXIS_${this_axi}_ACLK]     [get_bd_pins clk_wiz/clk_axi]
    connect_bd_net      [get_bd_pins $this_ip/M_AXIS_${this_axi}_ARESETN]  [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]
	
	## Connect GPIO/interrupts
	connect_bd_net [get_bd_pins axigpio_free_slots_to_pl/data_to_ps]       [get_bd_pins /$this_ip/dma_spk2pl_fifo_free_slots_pl]
	connect_bd_net [get_bd_pins axigpio_free_slots_to_pl/data_from_ps]     [get_bd_pins /$this_ip/dma_spk2pl_fifo_used_slots_ps]
	connect_bd_net [get_bd_pins axigpio_free_slots_to_pl/pl_irpt_trigger]  [get_bd_pins /$this_ip/dma_spk2pl_fifo_free_slots_pl_intr]
	connect_bd_net [get_bd_pins axigpio_free_slots_to_pl/ps_intr]          [get_bd_pins /$this_ip/dma_spk2pl_fifo_used_slots_ps_intr]

	connect_bd_net [get_bd_pins axigpio_ready_ev_to_ps/data_to_ps]      [get_bd_pins /$this_ip/dma_spk2ps_fifo_size_wr_ev_pl]
	connect_bd_net [get_bd_pins axigpio_ready_ev_to_ps/data_from_ps]    [get_bd_pins /$this_ip/dma_spk2ps_fifo_size_rd_ev_ps]
	connect_bd_net [get_bd_pins axigpio_ready_ev_to_ps/pl_irpt_trigger] [get_bd_pins /$this_ip/dma_spk2ps_fifo_wr_ev_pl_intr]
	connect_bd_net [get_bd_pins axigpio_ready_ev_to_ps/ps_intr]         [get_bd_pins /$this_ip/dma_spk2ps_fifo_rd_ev_ps_intr]
	
	## Connect I/O
	create_bd_port -dir O uled_uf1
	create_bd_port -dir O uled_uf2
	create_bd_port -dir O -from 7 -to 0 pmod1
	create_bd_port -dir O -from 7 -to 0 pmod2
	create_bd_port -dir O -from 7 -to 0 pmod3
	create_bd_port -dir O -from 7 -to 0 pmod4
			
	connect_bd_net [get_bd_pins /$this_ip/uled_uf1] [get_bd_ports uled_uf1]
	connect_bd_net [get_bd_pins /$this_ip/uled_uf2] [get_bd_ports uled_uf2]
	connect_bd_net [get_bd_pins /$this_ip/pmod1]    [get_bd_ports pmod1]
	connect_bd_net [get_bd_pins /$this_ip/pmod2]    [get_bd_ports pmod2]	
	connect_bd_net [get_bd_pins /$this_ip/pmod3]    [get_bd_ports pmod3]
	connect_bd_net [get_bd_pins /$this_ip/pmod4]    [get_bd_ports pmod4]

# Interrupts
	## Interupts from DMA
	set this_ip concat_intr_pl_dma
	set NB_DMA_INTR 4
	create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat $this_ip
	set_property CONFIG.NUM_PORTS $NB_DMA_INTR [get_bd_cells $this_ip]

	connect_bd_net [get_bd_pins $this_ip/In0] [get_bd_pins axi_dma_spk_aer/mm2s_introut]
	connect_bd_net [get_bd_pins $this_ip/In1] [get_bd_pins axi_dma_spk_aer/s2mm_introut]
	connect_bd_net [get_bd_pins $this_ip/In2] [get_bd_pins axi_dma_sps/mm2s_introut]
	connect_bd_net [get_bd_pins $this_ip/In3] [get_bd_pins axi_dma_sps/s2mm_introut]
	connect_bd_net [get_bd_pins $this_ip/dout] [get_bd_pins zynq_ultra_ps_e/pl_ps_irq0]

	
	## Interupts from custom RTL
	set this_ip concat_intr_pl_gpio
	create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat $this_ip
	set_property CONFIG.NUM_PORTS {2} [get_bd_cells $this_ip]
	
	connect_bd_net [get_bd_pins $this_ip/In0] [get_bd_pins axigpio_free_slots_to_pl/pl_intr]
	connect_bd_net [get_bd_pins $this_ip/In1] [get_bd_pins axigpio_ready_ev_to_ps/pl_intr]
	connect_bd_net [get_bd_pins $this_ip/dout] [get_bd_pins zynq_ultra_ps_e/pl_ps_irq1]

# Group hierarchy
group_bd_cells status_dma_spk_aer [get_bd_cells axigpio_free_slots_to_pl] [get_bd_cells axigpio_ready_ev_to_ps]


# ===============
# ILA
# ===============
## Create IP
set this_ip ila_dma
create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila $this_ip
set_property -dict [list \
	CONFIG.C_DATA_DEPTH {1024} \
	CONFIG.C_NUM_MONITOR_SLOTS {4} \
	CONFIG.C_SLOT {0} \
	CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
	CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
	CONFIG.C_SLOT_2_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
	CONFIG.C_SLOT_3_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
] [get_bd_cells $this_ip]

## Connect clock and reset
connect_bd_net [get_bd_pins $this_ip/clk] [get_bd_pins clk_wiz/clk_axi]
connect_bd_net [get_bd_pins $this_ip/resetn] [get_bd_pins proc_sys_reset_axi_domain/peripheral_aresetn]

## Connect interface to debug
connect_bd_intf_net [get_bd_intf_pins ila_dma/SLOT_0_AXIS] [get_bd_intf_pins bench_dmas/S_AXIS_SPK2PL]
connect_bd_intf_net [get_bd_intf_pins ila_dma/SLOT_1_AXIS] [get_bd_intf_pins bench_dmas/M_AXIS_SPK2PS]
connect_bd_intf_net [get_bd_intf_pins ila_dma/SLOT_2_AXIS] [get_bd_intf_pins bench_dmas/S_AXIS_SPS2PL]
connect_bd_intf_net [get_bd_intf_pins ila_dma/SLOT_3_AXIS] [get_bd_intf_pins bench_dmas/M_AXIS_SPS2PS]

# for some reason explodes your vivado with no fucking log
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets /axi_dma_spk_aer_M_AXIS_MM2S]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets /axi_dma_sps_M_AXIS_MM2S]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets /bench_dmas_M_AXIS_SPK2PS]
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets /bench_dmas_M_AXIS_SPS2PS]

# ===============
# Address mapping
# ===============
# Address map
    ## Force mapping
    # TODO: fetch from vhdl
    set addr_map {
        "/status_dma_spk_aer/axigpio_free_slots_to_pl/S_AXI/reg0" {offset 0xA0010000 range  4K}
        "/status_dma_spk_aer/axigpio_ready_ev_to_ps/S_AXI/reg0"   {offset 0xA0011000 range  4K}
        "/axi_params_dma/S_AXI/Reg"            					  {offset 0xA0012000 range  4K}
        "/bench_dmas/S_AXI_LITE_CONTROL/reg0"  					  {offset 0xA0020000 range 64K}
        "/bench_dmas/S_AXI_LITE_STATUS/reg0"   					  {offset 0xA0030000 range 64K}
    }

    foreach seg [dict keys $addr_map] {
        # Get mapping parameters
        set offset [dict get $addr_map $seg offset]
        set range  [dict get $addr_map $seg range]

        # Apply the assign_bd_address command for each entry in the dictionary
        assign_bd_address -target_address_space /zynq_ultra_ps_e/Data \
            [get_bd_addr_segs $seg] \
            -force \
            -offset $offset \
            -range $range
    }

    ## Automatically assign remaining segments
    assign_bd_address