/*
*! @title      Main application for bench_dma_rx
*! @file       bench_dma_rx.cpp
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

#include "bench_dma_rx.h"

#include "utility/CustomPrint.h"
#include "swconfig/ArgParse.h"
#include "swconfig/SwConfigParser.h"
#include "com/zmq/zmq.hpp"

#include "com/axi/AxiLite.h"
#include "com/axi/AxiDma.h"
#include "com/axi/AxiGpio.h"

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
    cout << "* " << ITLC("Application: Bench DMA RX") << endl;
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
    
    // Init DMA
    AxiGpio axi_gpio_params_dma = AxiGpio(OFFSET_AXI_GPIO_AXPARAMS,  RANGE_AXI_GPIO, AxiGpioDir::OUT, AxiGpioDir::OUT,  false);
    AxiGpio axi_gpio_en_core    = AxiGpio(OFFSET_AXI_GPIO_EN,        RANGE_AXI_GPIO, AxiGpioDir::OUT, AxiGpioDir::NONE, false);
    AxiGpio axi_gpio_fifo_rcnt  = AxiGpio(OFFSET_AXI_GPIO_FIFO_RCNT, RANGE_AXI_GPIO, AxiGpioDir::IN,  AxiGpioDir::NONE, false);
    r = axi_gpio_en_core.write(0, AxiGpioCh::CH1);

    // For now SG to PL only works in non-coherent
    enum axi_params_t {CACHE_COHERENT=11, NON_CACHE_COHERENT=0, PROT_SECURE=0, PROT_UNSECURE=2};
    // axi_params_dma.write(axi_params_t::CACHE_COHERENT, AxiGpioCh::CH1); // CH1: axi cache
    // axi_params_dma.write(axi_params_t::PROT_UNSECURE,  AxiGpioCh::CH2); // CH2: axi prot
    axi_gpio_params_dma.write(axi_params_t::NON_CACHE_COHERENT, AxiGpioCh::CH1); // CH1: axi cache
    axi_gpio_params_dma.write(axi_params_t::PROT_UNSECURE,      AxiGpioCh::CH2); // CH2: axi prot

    AxiDma dma = AxiDma(swconfig);

    // Enable calculation core
    infoPrint(0, "Enable calculation core");
    r = axi_gpio_en_core.write(1, AxiGpioCh::CH1);
    statusPrint(r, "Enable calculation core");
    uint64_t tstart_core = get_posix_clock_time_usec();

    // Start DMA
    dma.monitoring(swconfig);

    // Disable calculation core
    infoPrint(0, "Disable calculation core");
    r = axi_gpio_en_core.write(0, AxiGpioCh::CH1);
    statusPrint(r, "Disable calculation core");
    uint64_t tstop_core = get_posix_clock_time_usec();

    // Exit application
    cout << "Core runtime: " << (tstop_core-tstart_core)*1e-6 << " seconds" << endl;
    statusPrint(EXIT_SUCCESS, "Running application");

    return EXIT_SUCCESS;
}
