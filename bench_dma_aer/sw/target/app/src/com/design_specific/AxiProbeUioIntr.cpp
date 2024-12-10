/*
*! @title      Hardware probe with UIO driver
*! @file       AxiProbeUioIntr.cpp
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

#include "AxiProbeUioIntr.h"

AxiProbeUioIntr::AxiProbeUioIntr(const char* uio_dev_name, uint64_t offset, uint32_t range){
    // AXI GPIO
    _axi_gpio = std::make_unique<AxiGpio>(offset, range, AxiGpioDir::IN, AxiGpioDir::OUT, true);
    _axi_gpio->clear_intr();
    _axi_gpio->disable_ch_intr(_ch_read_from_pl);
    _axi_gpio->enable_ch_intr(_ch_write_to_pl);
    _axi_gpio->write(0x0000'0000, _ch_write_to_pl);

    // Interrupts through UIO driver
    _uio_intr = std::make_unique<UIO>(uio_dev_name, true);
}

AxiProbeUioIntr::~AxiProbeUioIntr(){
    _axi_gpio->clear_intr();
    _axi_gpio->disable_intr();
    _axi_gpio->disable_ch_intr(_ch_read_from_pl);
    _axi_gpio->disable_ch_intr(_ch_write_to_pl);
    _axi_gpio->write(0x0000'0000, _ch_write_to_pl);
};

uint32_t AxiProbeUioIntr::read_from_pl(){
    return _axi_gpio->read(_ch_read_from_pl);
}

int AxiProbeUioIntr::write_to_pl(uint32_t wdata){
    return _axi_gpio->write(wdata, _ch_write_to_pl);
}

int AxiProbeUioIntr::pl_write_flag(pl_write_flag_status flag_state){
    int r = EXIT_SUCCESS;

    if (flag_state == pl_write_flag_status::SET){
        r = set_flag_write_to_pl();
    }else if (flag_state == pl_write_flag_status::CLEAR){
        r = clear_flag_write_to_pl();
    } else {
        r = EXIT_FAILURE;
    }
    
    return r;
}

int AxiProbeUioIntr::set_flag_write_to_pl(){
    return _axi_gpio->set_ch_intr(_ch_write_to_pl);
}

int AxiProbeUioIntr::clear_flag_write_to_pl(){
    return _axi_gpio->clear_ch_intr(_ch_write_to_pl);
}

int AxiProbeUioIntr::unmask_pl_interrupt(){
    return _uio_intr->unmask_interrupt();
}

int AxiProbeUioIntr::wait_pl_interrupt(int timeout_ms){
    return _uio_intr->wait_interrupt(timeout_ms);
}