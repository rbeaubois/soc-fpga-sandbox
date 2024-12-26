/*
*! @title      Axi lite object
*! @file       AxiLite.h
*! @author     Romain Beaubois
*! @date       15 Sep 2021
*! @copyright
*! SPDX-FileCopyrightText: © 2021 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! Axi lite object
*! * Store pointer to base address to handle axi as C array
*! * Store numbers of read and write registers (PS pov)
*! * Read/write functions
*! 
*! @details
*! > **15 Sep 2021** : file creation (RB)
*! > **10 Aug 2022** : adapt axilite to zubuntu (RB)
*! > **21 Dec 2022** : add constructor with range setup (RB)
*! > **15 Oct 2024** : change base address to 64 bits offset (RB)
*! > **01 Dec 2024** : changed volatile pointer to atomic (RB)
*/

#ifndef __AXILITE_H__
#define __AXILITE_H__

#include <iostream>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <unistd.h>
#include <fcntl.h>
#include <atomic>
#include <sys/mman.h>
#include "../../utility/Sfixed.h"
#include "../../utility/CustomPrint.h"

using namespace std;

class AxiLite{
    public:
        private :
        // Members
        uint16_t _nb_regs_write;
        uint16_t _nb_regs_read;
        uint16_t _nb_regs;
        std::atomic<uint32_t>* _axi_regs_base;
        
        public :
        // Methods
        AxiLite(uint64_t offset, uint32_t range, uint16_t nb_regs_write, uint16_t nb_regs_read);
        int write(uint32_t wdata, uint16_t regw);
        int write(float wdata, uint16_t regw, uint8_t fp_int, uint8_t fp_dec);
        uint32_t read(uint16_t regr);
        float read(uint16_t regr, uint8_t fp_int, uint8_t fp_dec);
        int test_RW();
};

#endif