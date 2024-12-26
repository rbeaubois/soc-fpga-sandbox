/*
*! @title      Main application for bench_dma_aer
*! @file       bench_dma_aer.cpp
*! @author     Romain Beaubois
*! @date       10 Aug 2022
*! @copyright
*! SPDX-FileCopyrightText: © 2022 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! 
*! @details
*! > **10 Aug 2022** : file creation (RB)
*/

#include "bench_dma_aer.h"

#include "utility/CustomPrint.h"
#include "swconfig/ArgParse.h"
#include "swconfig/SwConfigParser.h"
#include "com/zmq/zmq.hpp"

#include "com/axi/AxiLite.h"
#include "com/axi/AxiDma.h"
#include "hwconfig/HwControl.h"

#include "hwconfig/include/hwconfig_sys.h"
#include "hwconfig/include/hwconfig_axil_control.h"

#include <getopt.h>
#include <stdint.h>
#include <string>
#include <iostream>
#include <cstdint>
#include <atomic>

using namespace std;

int main(int argc, char* argv[]){
    // Print app information
    cout << string(50, '=') << endl;
    cout << "* " << ITLC("Application: Bench DMA AER") << endl;
    cout << "* " << ITLC("Date: ") << ITLC(__DATE__) << " " << ITLC(__TIME__) << endl;
    cout << "* " << ITLC("SW version: ") << ITLC(SW_VERSION) << endl;
    cout << "* " << ITLC("HW version: ") << ITLC(HW_VERSION) << endl;
    cout << "* " << ITLC("HW FPGA architecture: ") << ITLC(HW_FPGA_ARCH) << endl;
    cout << string(50, '=') << endl;
    
    int r; // Status return

    // Parse argument
    string fpath_swconfig;
    bool print_swconfig;
    uint8_t sweep_progress;
    r = parse_args(argc, argv, &fpath_swconfig, &print_swconfig, &sweep_progress);
    statusPrint(r, "Parse arguments");
    if(r==EXIT_FAILURE)
        return EXIT_FAILURE;
    
    // Parse configuration file
    SwConfigParser swconfig_parser = SwConfigParser(fpath_swconfig);
    if(print_swconfig)
        swconfig_parser.print();
    struct sw_config swconfig = swconfig_parser.getConfig();

    // Instanciate axilite cores
    AxiLite axilite_hw_control = AxiLite( OFFSET_AXI_LITE_CONTROL, RANGE_AXI_LITE_CONTROL,
                                          NB_PS_WRITE_REGS, NB_PS_READ_REGS);
    axilite_hw_control.test_RW();
    cout << string(50, '=') << endl;
    cout << "* HW Bitstream UID: " << std::setw(9) << std::setfill('-') << axilite_hw_control.read(REGR_HW_UID) << std::endl;
    cout << string(50, '=') << endl;
    
    // Hardware instances
    HwControl hw_ctrl(&axilite_hw_control);

    // Init DMA
    hw_ctrl.setDmaSendMode(dma_op_mode_t::THRESHOLD, swconfig.intr_thresh_free_slots_to_pl);
    hw_ctrl.setDmaRecvMode(dma_op_mode_t::THRESHOLD, swconfig.intr_thresh_ready_ev_to_ps);
    AxiGpio axi_params_dma = AxiGpio(OFFSET_AXI_PARAMS_DMA, RANGE_AXI_PARAMS_DMA, AxiGpioDir::OUT, AxiGpioDir::OUT, false);

    // For now SG to PL only works in non-coherent
    enum axi_params_t {CACHE_COHERENT=11, NON_CACHE_COHERENT=0, PROT_SECURE=0, PROT_UNSECURE=2};
    // axi_params_dma.write(axi_params_t::CACHE_COHERENT, AxiGpioCh::CH1); // CH1: axi cache
    // axi_params_dma.write(axi_params_t::PROT_UNSECURE,  AxiGpioCh::CH2); // CH2: axi prot
    axi_params_dma.write(axi_params_t::NON_CACHE_COHERENT, AxiGpioCh::CH1); // CH1: axi cache
    axi_params_dma.write(axi_params_t::PROT_UNSECURE,      AxiGpioCh::CH2); // CH2: axi prot

    AxiDma dma = AxiDma(swconfig);

    // Reset system
    infoPrint(0, "Reset system");
    r = hw_ctrl.reset();
    statusPrint(r, "Reset system");

    // Enable calculation core
    infoPrint(0, "Enable calculation core");
    r = hw_ctrl.enableCore();
    statusPrint(r, "Enable calculation core");
    uint64_t tstart_core = get_posix_clock_time_usec();

    // Start DMA
    dma.monitoring(swconfig);

    // Disable calculation core
    infoPrint(0, "Disable calculation core");
    r = hw_ctrl.disableCore();
    statusPrint(r, "Disable calculation core");
    uint64_t tstop_core = get_posix_clock_time_usec();

    // Exit application
    cout << "Core runtime: " << (tstop_core-tstart_core)*1e-6 << " seconds" << endl;
    statusPrint(EXIT_SUCCESS, "Running application");
    hw_ctrl.hold_reset();

    return EXIT_SUCCESS;
}
