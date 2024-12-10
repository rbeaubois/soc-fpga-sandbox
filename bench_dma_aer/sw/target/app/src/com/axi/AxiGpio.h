/*
*! @title      AXI GPIO controller
*! @file       AxiGpio.h
*! @author     Romain Beaubois
*! @date       26 Nov 2024
*! @copyright
*! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! Axi GPIO: https://docs.amd.com/v/u/en-US/pg144-axi-gpio
*! 
*! @details
*! > **26 Nov 2024** : file creation (RB)
*/

#ifndef __AXI_GPIO_H__
#define __AXI_GPIO_H__

#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <atomic>

#include "../../utility/CustomPrint.h"

enum AxiGpioCh {
    CH1 = 1,
    CH2 = 2
};
enum AxiGpioDir {
    IN,
    OUT,
    NONE
};

class AxiGpio{
    private:
        enum class regs_offset: uint32_t{
            GPIO_DATA  = 0x0000,  // GPIO Data Register
            GPIO_TRI   = 0x0004,  // GPIO Direction Register
            GPIO2_DATA = 0x0008,  // GPIO2 Data Register
            GPIO2_TRI  = 0x000C,  // GPIO2 Direction Register
            GIER       = 0x011C,  // Global Interrupt Enable Register
            IP_IER     = 0x0128,  // Interrupt Enable Register
            IP_ISR     = 0x0120   // Interrupt Status Register
        };

        enum class gpio_tri_opts{
            IN  = 1,
            OUT = 0
        };

        enum class gier_opts{
            DISABLE        = 0,
            ENABLE         = 1,
            GLOBAL_INTR_EN = 31
        };

        enum class ip_ier_opts{
            DISABLE     = 0,
            ENABLE      = 1,
            CH1_INTR_EN = 0,
            CH2_INTR_EN = 1
        };

        enum class ip_isr_opts{
            CATCHED         = 1,
            CLEAR           = 1,
            CH1_INTR_STATUS = 0,
            CH2_INTR_STATUS = 1
        };

        bool _en_intr;                      // Interuption enabled
        AxiGpioDir _gpio_dir  = NONE;       // GPIO directions
        AxiGpioDir _gpio2_dir = NONE;       // GPIO directions
        uint64_t _offset;                   // AXI memory mapped offset
        uint32_t _range;                    // AXI memory mapped range
        uint32_t* _gpio_base;               // Base address AXI GPIO
        std::atomic<uint32_t>* _gpio_data;  // GPIO Data
        std::atomic<uint32_t>* _gpio_tri;   // GPIO Direction
        std::atomic<uint32_t>* _gpio2_data; // GPIO2 Data
        std::atomic<uint32_t>* _gpio2_tri;  // GPIO2 Direction
        std::atomic<uint32_t>* _gier;       // Global Interrupt Enable Register
        std::atomic<uint32_t>* _ip_ier;     // Interrupt Enable Register
        std::atomic<uint32_t>* _ip_isr;     // Interrupt Status Register
    public:
        AxiGpio(uint64_t offset, uint32_t range, AxiGpioDir ch1, AxiGpioDir ch2, bool en_intr);
        ~AxiGpio();
        int write(uint32_t wdata, AxiGpioCh gpio_ch);
        uint32_t read(AxiGpioCh gpio_ch);
        int enable_intr();
        int disable_intr();
        int clear_intr();
        int enable_ch_intr(AxiGpioCh gpio_ch);
        int disable_ch_intr(AxiGpioCh gpio_ch);
        int clear_ch_intr(AxiGpioCh gpio_ch);
        int set_ch_intr(AxiGpioCh gpio_ch);
};

#endif