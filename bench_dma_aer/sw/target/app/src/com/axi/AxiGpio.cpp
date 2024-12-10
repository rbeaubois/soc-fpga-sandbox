/*
*! @title      AXI GPIO controller
*! @file       AxiGpio.cpp
*! @author     Romain Beaubois
*! @date       26 Nov 2024
*! @copyright
*! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! Axi GPIO object
*! 
*! @details
*! > **26 Nov 2024** : file creation (RB)
*/

#include "AxiGpio.h"

/***************************************************************************
 * Initialize AXI GPIO object
 * 
 * @param offset Base address of AXI object in platform
 * @param range Address range
 * @param en_dual_channel Dual channel GPIO enabled
 * @param en_intr Interruption enabled
 * @return None
****************************************************************************/
AxiGpio::AxiGpio(uint64_t offset, uint32_t range, AxiGpioDir ch1_dir, AxiGpioDir ch2_dir, bool en_intr){
    int r;
    int fd;

    // Set AXI GPIO properties
    _en_intr         = en_intr;
    _gpio_dir        = ch1_dir;
    _gpio2_dir       = ch2_dir;
    _offset          = offset;
    _range           = range;

    // Get file descriptor for /dev/mem
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    r = (fd == -1) ? EXIT_FAILURE : EXIT_SUCCESS;
    statusPrint(r, "Open file /dev/mem for AXI GPIO");

    if(fd != -1){
        // Map physical address into user space by getting a virtual address
        _gpio_base = (uint32_t*)mmap(NULL, range, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);
        r = (_gpio_base == NULL) ? EXIT_FAILURE : EXIT_SUCCESS;
        statusPrint(r, "Memory map AXI GPIO");

        _gpio_data  = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::GPIO_DATA)  / sizeof(uint32_t));
        _gpio_tri   = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::GPIO_TRI)   / sizeof(uint32_t));
        _gpio2_data = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::GPIO2_DATA) / sizeof(uint32_t));
        _gpio2_tri  = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::GPIO2_TRI)  / sizeof(uint32_t));
        _gier       = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::GIER)       / sizeof(uint32_t));
        _ip_ier     = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::IP_IER)     / sizeof(uint32_t));
        _ip_isr     = reinterpret_cast<std::atomic<uint32_t>*>(_gpio_base + (uint32_t)(regs_offset::IP_ISR)     / sizeof(uint32_t));
        
        // Close file descriptor of /dev/mem
        close(fd);
        statusPrint(EXIT_SUCCESS, "Close file /dev/mem");

        // Enable interruptions
        r = clear_intr();
        if (en_intr)
            r = enable_intr();
        else
            r = disable_intr();
    }
}

uint32_t AxiGpio::read(AxiGpioCh gpio_ch){
    int r = EXIT_SUCCESS;
    uint32_t rdata = -1;

    try{
        if (gpio_ch == AxiGpioCh::CH1 && _gpio_dir==AxiGpioDir::IN)
            rdata = _gpio_data->load(std::memory_order_relaxed);
        else if(gpio_ch == AxiGpioCh::CH2 && _gpio2_dir==AxiGpioDir::IN)
            rdata = _gpio2_data->load(std::memory_order_relaxed);
        else
            throw std::invalid_argument("Operation not permitted");
    } catch (const std::invalid_argument& e) {
        r = EXIT_FAILURE;
    } catch (const std::exception& e) {
        r = EXIT_FAILURE;
    }

    statusPrint(r, "Read data AXI GPIO CH" + to_string(gpio_ch));
    return rdata;
}

int AxiGpio::write(uint32_t wdata, AxiGpioCh gpio_ch){
    int r = EXIT_SUCCESS;

    try{
        if (gpio_ch == AxiGpioCh::CH1 && _gpio_dir==AxiGpioDir::OUT)
            _gpio_data->store(wdata, std::memory_order_relaxed);
        else if(gpio_ch == AxiGpioCh::CH2 && _gpio2_dir==AxiGpioDir::OUT)
            _gpio2_data->store(wdata, std::memory_order_relaxed);
        else
            throw std::invalid_argument("Operation not permitted");
    } catch (const std::invalid_argument& e) {
        r = EXIT_FAILURE;
    } catch (const std::exception& e) {
        r = EXIT_FAILURE;
    }

    statusPrint(r, "Write data AXI GPIO CH" + to_string(gpio_ch));
    return r;
}

int AxiGpio::enable_intr(){
    int r = EXIT_SUCCESS;

    // Enable global interrupts
    _gier->store((uint32_t)(gier_opts::ENABLE) << (uint32_t)(gier_opts::GLOBAL_INTR_EN), std::memory_order_relaxed);

    // Enable channel interrupts
    // r = enable_ch_intr(AxiGpioCh::CH1);
    // r = enable_ch_intr(AxiGpioCh::CH2);

    statusPrint(r, "Enable global interrupts");
    return r;
}

int AxiGpio::disable_intr(){
    int r = EXIT_SUCCESS;

    // Disable global interrupts
    _gier->store((uint32_t)(gier_opts::DISABLE) << (uint32_t)(gier_opts::GLOBAL_INTR_EN), std::memory_order_relaxed);

    // Disable channel interrupts
    // r = disable_ch_intr(AxiGpioCh::CH1);
    // r = disable_ch_intr(AxiGpioCh::CH2);

    statusPrint(r, "Disable global interrupts");
    return r;
}

int AxiGpio::enable_ch_intr(AxiGpioCh gpio_ch){
    int r = EXIT_SUCCESS;
    uint32_t reg_val = _ip_ier->load(std::memory_order_relaxed);

    // Enable channel interrupts
    if (gpio_ch == AxiGpioCh::CH1)
        reg_val = reg_val | ((uint32_t)(ip_ier_opts::ENABLE) << (uint32_t)(ip_ier_opts::CH1_INTR_EN));
    else if (gpio_ch == AxiGpioCh::CH2)
        reg_val = reg_val | ((uint32_t)(ip_ier_opts::ENABLE) << (uint32_t)(ip_ier_opts::CH2_INTR_EN));
    else
        r = EXIT_FAILURE;
    
    _ip_ier->store(reg_val, std::memory_order_relaxed);
    statusPrint(r, "Enable interrupt CH" + to_string(gpio_ch));
    return r;
}

int AxiGpio::disable_ch_intr(AxiGpioCh gpio_ch){
    int r = EXIT_SUCCESS;
    uint32_t reg_val = _ip_ier->load(std::memory_order_relaxed);

    // Disable channel interrupts
    if (gpio_ch == AxiGpioCh::CH1)
        reg_val = reg_val | ((uint32_t)(ip_ier_opts::DISABLE) << (uint32_t)(ip_ier_opts::CH1_INTR_EN));
    else if (gpio_ch == AxiGpioCh::CH2)
        reg_val = reg_val | ((uint32_t)(ip_ier_opts::DISABLE) << (uint32_t)(ip_ier_opts::CH2_INTR_EN));
    else
        r = EXIT_FAILURE;
    
    _ip_ier->store(reg_val, std::memory_order_relaxed);
    statusPrint(r, "Disable interrupt CH" + to_string(gpio_ch));
    return r;
}

int AxiGpio::clear_intr(){
    int r = EXIT_SUCCESS;
    bool cleared = false;

    cleared = (clear_ch_intr(AxiGpioCh::CH1)==EXIT_SUCCESS) ? true : cleared;
    cleared = (clear_ch_intr(AxiGpioCh::CH2)==EXIT_SUCCESS) ? true : cleared;
    
    if (!cleared)
        r = EXIT_FAILURE;

    // statusPrint(r, "Clear all interrupts");
    return r;
}

int AxiGpio::clear_ch_intr(AxiGpioCh gpio_ch){
    int r = EXIT_SUCCESS;

    // Toggle On Write (TOW): toggle bits at positions written by ones
    uint32_t intr_status = _ip_isr->load(std::memory_order_relaxed);

    if (gpio_ch == AxiGpioCh::CH1){
        // Clear interrupt if interrupt exists
        if ((intr_status >> (uint32_t)(ip_isr_opts::CH1_INTR_STATUS)) & (uint32_t)(ip_isr_opts::CATCHED))
            _ip_isr->store((uint32_t)(ip_isr_opts::CLEAR) << (uint32_t)(ip_isr_opts::CH1_INTR_STATUS), std::memory_order_relaxed);
        else
            r = EXIT_FAILURE;
    }
    else if (gpio_ch == AxiGpioCh::CH2){
        // Clear interrupt if interrupt exists
        if ((intr_status >> (uint32_t)(ip_isr_opts::CH2_INTR_STATUS)) & (uint32_t)(ip_isr_opts::CATCHED))
            _ip_isr->store((uint32_t)(ip_isr_opts::CLEAR) << (uint32_t)(ip_isr_opts::CH2_INTR_STATUS), std::memory_order_relaxed);
        else
            r = EXIT_FAILURE;
    }
    else{
        r = EXIT_FAILURE;
    }
    
    // statusPrint(r, "Clear interrupt CH" + to_string(gpio_ch));
    return r;
}

int AxiGpio::set_ch_intr(AxiGpioCh gpio_ch){
   int r = EXIT_SUCCESS;

    // Toggle On Write (TOW): toggle bits at positions written by ones
    uint32_t intr_status = _ip_isr->load(std::memory_order_relaxed);

    if (gpio_ch == AxiGpioCh::CH1){
        // Clear interrupt if interrupt exists
        if ( !((intr_status >> (uint32_t)(ip_isr_opts::CH1_INTR_STATUS)) & (uint32_t)(ip_isr_opts::CATCHED)) )
            _ip_isr->store((uint32_t)(ip_isr_opts::CLEAR) << (uint32_t)(ip_isr_opts::CH1_INTR_STATUS), std::memory_order_relaxed);
        else
            r = EXIT_FAILURE;
    }
    else if (gpio_ch == AxiGpioCh::CH2){
        // Clear interrupt if interrupt exists
        if ( !((intr_status >> (uint32_t)(ip_isr_opts::CH2_INTR_STATUS)) & (uint32_t)(ip_isr_opts::CATCHED)) )
            _ip_isr->store((uint32_t)(ip_isr_opts::CLEAR) << (uint32_t)(ip_isr_opts::CH2_INTR_STATUS), std::memory_order_relaxed);
        else
            r = EXIT_FAILURE;
    }
    else{
        r = EXIT_FAILURE;
    }

    statusPrint(r, "Set interrupt CH" + to_string(gpio_ch));
    return r;
}

AxiGpio::~AxiGpio(){
    munmap(_gpio_base, _range);
}