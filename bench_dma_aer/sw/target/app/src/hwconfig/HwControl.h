/*
*! @title      Class to handle hardware control
*! @file       HwControl.h
*! @author     Romain Beaubois
*! @date       09 Aug 2022
*! @copyright
*! SPDX-FileCopyrightText: © 2022 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! 
*! @details
*! > **09 Aug 2022** : file creation (RB)
*/

#ifndef __HWCONTROL_H__
#define __HWCONTROL_H__

#include <iostream>
#include <fstream>
#include <stdint.h>
#include <string>

#include "../com/axi/AxiLite.h"
#include "../utility/CustomPrint.h"
#include "../utility/reg_control.h"

#include "include/hwconfig_axil_control.h"

using namespace std;

typedef enum {
    THRESHOLD,
    PERIODIC
}dma_op_mode_t;

class HwControl{
    private:
        AxiLite*    _axilite;
        uint32_t    _val_regw_control;

    public:
        HwControl(AxiLite* axilite);
        int reset();
        int hold_reset();
        int enableCore();
        int disableCore();
        int setDmaRecvMode(dma_op_mode_t op_mode, uint32_t threshold);
        int setDmaSendMode(dma_op_mode_t op_mode, uint32_t threshold);
};

#endif