create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 2.0 -module_name axis_data_fifo_dma_s2mm_ip
set_property -dict [list \
  CONFIG.FIFO_DEPTH {16384} \
  CONFIG.FIFO_MEMORY_TYPE {block} \
  CONFIG.FIFO_MODE {2} \
  CONFIG.HAS_RD_DATA_COUNT {1} \
  CONFIG.IS_ACLK_ASYNC {1} \
  CONFIG.TDATA_NUM_BYTES {4} \
] [get_ips axis_data_fifo_dma_s2mm_ip]