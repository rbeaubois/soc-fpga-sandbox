# Dual clock native interface FIFO from PS via DMA
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name nat_fifo_spk_stream_from_ps_ip_zynqmp
set_property -dict [list \
  CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
  CONFIG.Performance_Options {First_Word_Fall_Through} \
  CONFIG.Use_Embedded_Registers {true} \
  CONFIG.Input_Depth {1024} \
  CONFIG.Input_Data_Width {32} \
  CONFIG.Enable_Reset_Synchronization {true} \
  CONFIG.Enable_Safety_Circuit {true} \
  CONFIG.Write_Data_Count {true} \
] [get_ips nat_fifo_spk_stream_from_ps_ip_zynqmp]

# Dual clock native interface FIFO to PS via DMA
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name nat_fifo_spk_stream_to_ps_ip_zynqmp
set_property -dict [list \
  CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
  CONFIG.Performance_Options {First_Word_Fall_Through} \
  CONFIG.Input_Depth {1024} \
  CONFIG.Input_Data_Width {32} \
  CONFIG.Enable_Safety_Circuit {true} \
  CONFIG.Use_Extra_Logic {false} \
  CONFIG.synchronization_stages {2} \
] [get_ips nat_fifo_spk_stream_to_ps_ip_zynqmp]

# AXI GPIO
create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axigpio_dualch_intr_ip
set_property -dict [list \
  CONFIG.C_ALL_INPUTS {1} \
  CONFIG.C_ALL_OUTPUTS_2 {1} \
  CONFIG.C_INTERRUPT_PRESENT {1} \
  CONFIG.C_IS_DUAL {1} \
] [get_ips axigpio_dualch_intr_ip]