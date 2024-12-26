# Dual clock native interface FIFO from PS via DMA
create_ip -name emb_fifo_gen -vendor xilinx.com -library ip -version 1.0 -module_name nat_fifo_spk_stream_from_ps_ip_versal
set_property -dict [list \
  CONFIG.INTERFACE_TYPE {Native} \
  CONFIG.FIFO_MEMORY_TYPE {BRAM} \
  CONFIG.READ_MODE {FWFT} \
  CONFIG.CLOCK_DOMAIN {Independent_Clock} \
  CONFIG.ENABLE_ALMOST_EMPTY {false} \
  CONFIG.ENABLE_ALMOST_FULL {false} \
  CONFIG.ENABLE_DATA_COUNT {false} \
  CONFIG.ENABLE_OVERFLOW {false} \
  CONFIG.ENABLE_PROGRAMMABLE_EMPTY {false} \
  CONFIG.ENABLE_PROGRAMMABLE_FULL {false} \
  CONFIG.ENABLE_READ_DATA_COUNT {false} \
  CONFIG.ENABLE_READ_DATA_VALID {false} \
  CONFIG.ENABLE_UNDERFLOW {false} \
  CONFIG.ENABLE_WRITE_ACK {false} \
  CONFIG.FIFO_WRITE_DEPTH {1024} \
  CONFIG.WR_DATA_COUNT_WIDTH {10} \
] [get_ips nat_fifo_spk_stream_from_ps_ip_versal]

# Dual clock native interface FIFO to PS via DMA
create_ip -name emb_fifo_gen -vendor xilinx.com -library ip -version 1.0 -module_name nat_fifo_spk_stream_to_ps_ip_versal
set_property -dict [list \
  CONFIG.INTERFACE_TYPE {Native} \
  CONFIG.FIFO_MEMORY_TYPE {BRAM} \
  CONFIG.READ_MODE {FWFT} \
  CONFIG.CLOCK_DOMAIN {Independent_Clock} \
  CONFIG.ENABLE_ALMOST_EMPTY {false} \
  CONFIG.ENABLE_ALMOST_FULL {false} \
  CONFIG.ENABLE_OVERFLOW {false} \
  CONFIG.ENABLE_DATA_COUNT {false} \
  CONFIG.ENABLE_WRITE_DATA_COUNT {false} \
  CONFIG.ENABLE_PROGRAMMABLE_EMPTY {false} \
  CONFIG.ENABLE_PROGRAMMABLE_FULL {false} \
  CONFIG.ENABLE_READ_DATA_COUNT {false} \
  CONFIG.ENABLE_READ_DATA_VALID {false} \
  CONFIG.ENABLE_UNDERFLOW {false} \
  CONFIG.ENABLE_WRITE_ACK {false} \
  CONFIG.FIFO_WRITE_DEPTH {1024} \
] [get_ips nat_fifo_spk_stream_to_ps_ip_versal]

# AXI GPIO
create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axigpio_dualch_intr_ip
set_property -dict [list \
  CONFIG.C_ALL_INPUTS {1} \
  CONFIG.C_ALL_OUTPUTS_2 {1} \
  CONFIG.C_INTERRUPT_PRESENT {1} \
  CONFIG.C_IS_DUAL {1} \
] [get_ips axigpio_dualch_intr_ip]