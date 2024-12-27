proc gen_ip {board vivado_ver main_tcl_path} {
    # Get file utils functions
    source $main_tcl_path/utils/futils.tcl

    # Extract parameters from VHDL files
    set DEPTH_FIFO_SPK_IN  [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/common/axidma_pkg.vhd DEPTH_FIFO_SPK_IN]
    set DWIDTH_FIFO_SPK_IN [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/common/axidma_pkg.vhd DWIDTH_FIFO_SPK_IN]
    set AWIDTH_FIFO_SPK_IN [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/common/axidma_pkg.vhd AWIDTH_FIFO_SPK_IN]

    set DEPTH_FIFO_SPK_MON  [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/common/axidma_pkg.vhd DEPTH_FIFO_SPK_MON]
    set DWIDTH_FIFO_SPK_MON [futils::parse_vhdl_generic $main_tcl_path/../src/hdl/common/axidma_pkg.vhd DWIDTH_FIFO_SPK_MON]

    # Check if IP support is defined for a given board and version
    set is_supported_board 1
    set is_supported_ver   1
    switch -exact -- $board {
        "KR260" {
            switch -exact -- $vivado_ver {
                "2023.2" {
                    # Dual clock native interface FIFO from PS via DMA
                    create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name nat_fifo_spk_stream_from_ps_ip_zynqmp
                    set_property -dict [list \
                    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
                    CONFIG.Performance_Options {First_Word_Fall_Through} \
                    CONFIG.Use_Embedded_Registers {true} \
                    CONFIG.Input_Depth {$DEPTH_FIFO_SPK_IN} \
                    CONFIG.Input_Data_Width {$DWIDTH_FIFO_SPK_IN} \
                    CONFIG.Enable_Reset_Synchronization {true} \
                    CONFIG.Enable_Safety_Circuit {true} \
                    CONFIG.Write_Data_Count {true} \
                    ] [get_ips nat_fifo_spk_stream_from_ps_ip_zynqmp]

                    # Dual clock native interface FIFO to PS via DMA
                    create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name nat_fifo_spk_stream_to_ps_ip_zynqmp
                    set_property -dict [list \
                    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
                    CONFIG.Performance_Options {First_Word_Fall_Through} \
                    CONFIG.Input_Depth {$DEPTH_FIFO_SPK_MON} \
                    CONFIG.Input_Data_Width {$DWIDTH_FIFO_SPK_MON} \
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
                }
                default {
                    set is_supported_ver 0
                }
            }
        }
        "VPK120" {
            switch -exact -- $vivado_ver {
                "2023.2" {
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
                    CONFIG.FIFO_WRITE_DEPTH {$DEPTH_FIFO_SPK_IN} \
                    CONFIG.WR_DATA_COUNT_WIDTH {$AWIDTH_FIFO_SPK_IN} \
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
                    CONFIG.FIFO_WRITE_DEPTH {$DEPTH_FIFO_SPK_MON} \
                    ] [get_ips nat_fifo_spk_stream_to_ps_ip_versal]

                    # AXI GPIO
                    create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axigpio_dualch_intr_ip
                    set_property -dict [list \
                    CONFIG.C_ALL_INPUTS {1} \
                    CONFIG.C_ALL_OUTPUTS_2 {1} \
                    CONFIG.C_INTERRUPT_PRESENT {1} \
                    CONFIG.C_IS_DUAL {1} \
                    ] [get_ips axigpio_dualch_intr_ip]
                }
                default {
                    set is_supported_ver 0
                }
            }
        }
        default {
            set is_supported_board 0
        }
    }

    if {!$is_supported_board} {
        puts "No existing support for board: $board"
    }
    if {!$is_supported_ver} {
        puts "No existing support for Vivado version: $vivado_ver"
    }
}