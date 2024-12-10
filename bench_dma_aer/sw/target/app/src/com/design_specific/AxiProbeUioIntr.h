/*
*! @title      Hardware probe with UIO driver
*! @file       AxiProbeUioIntr.h
*! @author     Romain Beaubois
*! @date       01 Dec 2024
*! @copyright
*! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! * AXI GPIO CH1: Read data from PL
*! * AXI GPIO CH2: Write data to PL
*! * AXI GPIO Interrupt: Notify write to PL through /dev/mem
*! * PL interrupt net handled with UIO driver added to a custom IP wrapping AXI GPIO
*!
*! @details
*! > **01 Dec 2024** : file creation (RB)
*/

#ifndef __AXI_PROBE_UIO_INTR_H__
#define __AXI_PROBE_UIO_INTR_H__

#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <atomic>
#include <memory>

#include "../../utility/CustomPrint.h"
#include "../userspace_kmod/UIO.h"
#include "../axi/AxiGpio.h"


class AxiProbeUioIntr{
    private:
        static const AxiGpioCh _ch_read_from_pl = AxiGpioCh::CH1;
        static const AxiGpioCh _ch_write_to_pl  = AxiGpioCh::CH2;
        std::unique_ptr<AxiGpio> _axi_gpio;
        std::unique_ptr<UIO> _uio_intr;
    public:
        enum pl_write_flag_status {SET, CLEAR};
        AxiProbeUioIntr(const char* uio_dev_name, uint64_t offset, uint32_t range);
        ~AxiProbeUioIntr();
        
        uint32_t read_from_pl();
        int write_to_pl(uint32_t wdata);
        
        int pl_write_flag(pl_write_flag_status flag_state);
        int set_flag_write_to_pl();
        int clear_flag_write_to_pl();
        
        int unmask_pl_interrupt();
        int wait_pl_interrupt(int timeout_ms);
};

#endif