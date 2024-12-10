/*
*! @title      Class to handle hardware control
*! @file       HwControl.cpp
*! @author     Romain Beaubois
*! @date       19 Aug 2022
*! @copyright
*! SPDX-FileCopyrightText: © 2022 Romain Beaubois <refbeaubois@yahoo.com>
*! SPDX-License-Identifier: GPL-3.0-or-later
*!
*! @brief
*! 
*! @details
*! > **19 Aug 2022** : file creation (RB)
*/

#include "HwControl.h"
#include <iostream>
#include <fstream>

/***************************************************************************
 * Constructor
 * 
 * @param axilite Pointer to hw configuration axilite 
 * @return HwControl
****************************************************************************/
HwControl::HwControl(AxiLite *axilite){
    _axilite            = axilite;
    _val_regw_control   = 0;
}

/***************************************************************************
 * Reset hardware
 * 
 * @return EXIT_SUCCESS if successful otherwise EXIT_FAILURE
****************************************************************************/
int HwControl::reset(){
    int r;

    SET_BIT_REG(_val_regw_control, BIT_RESET_REGW_CONTROL);
    r = _axilite->write(_val_regw_control, REGW_CONTROL);
    usleep(300e3);
    CLEAR_BIT_REG(_val_regw_control, BIT_RESET_REGW_CONTROL);
    r = _axilite->write(_val_regw_control, REGW_CONTROL);

    return r;
}

/***************************************************************************
 * Hold Reset
 * 
 * @return EXIT_SUCCESS if successful otherwise EXIT_FAILURE
****************************************************************************/
int HwControl::hold_reset(){
    int r;

    SET_BIT_REG(_val_regw_control, BIT_RESET_REGW_CONTROL);
    r = _axilite->write(_val_regw_control, REGW_CONTROL);

    return r;
}

/***************************************************************************
 * Enable calculation core
 * 
 * @return EXIT_SUCCESS if successful otherwise EXIT_FAILURE
****************************************************************************/
int HwControl::enableCore(){
    int r;

    SET_BIT_REG(_val_regw_control, BIT_EN_CORE_REGW_CONTROL);
    r = _axilite->write(_val_regw_control, REGW_CONTROL);

    return r;
}

/***************************************************************************
 * Disable calculation core
 * 
 * @return EXIT_SUCCESS if successful otherwise EXIT_FAILURE
****************************************************************************/
int HwControl::disableCore(){
    int r;

    CLEAR_BIT_REG(_val_regw_control, BIT_EN_CORE_REGW_CONTROL);
    r = _axilite->write(_val_regw_control, REGW_CONTROL);

    return r;
}

/***************************************************************************
 * Select DMA recv mode
 *  - THRESHOLD: programmable threhsold of data to monitor
 *  - PERIODIC: sync with hw timer write
 * 
 * @return EXIT_SUCCESS if successful otherwise EXIT_FAILURE
****************************************************************************/
int HwControl::setDmaRecvMode(dma_op_mode_t op_mode, uint32_t threshold){
    int r;

    if (op_mode == dma_op_mode_t::THRESHOLD){
        CLEAR_BIT_REG(_val_regw_control, BIT_OPMODE_RECV_DMA_SPK_REGW_CONTROL);
	    r = _axilite->write(_val_regw_control, REGW_CONTROL);
    }
    else if (op_mode == dma_op_mode_t::PERIODIC){
        SET_BIT_REG(_val_regw_control, BIT_OPMODE_RECV_DMA_SPK_REGW_CONTROL);
        r = _axilite->write(_val_regw_control, REGW_CONTROL);
    }
    else{
        return EXIT_FAILURE;
    }
	r = _axilite->write(threshold, REGW_INTR_THRESH_READY_EV_TO_PS);
    return r;
}

/***************************************************************************
 * Select DMA send mode
 *  - THRESHOLD: programmable threhsold of data to monitor
 *  - PERIODIC: sync with hw timer write (not implemented)
 * 
 * @return EXIT_SUCCESS if successful otherwise EXIT_FAILURE
****************************************************************************/
int HwControl::setDmaSendMode(dma_op_mode_t op_mode, uint32_t threshold){
    int r;

    if (op_mode == dma_op_mode_t::THRESHOLD){
        CLEAR_BIT_REG(_val_regw_control, BIT_OPMODE_SEND_DMA_SPK_REGW_CONTROL); 
	    r = _axilite->write(_val_regw_control, REGW_CONTROL);
        r = _axilite->write(threshold, REGW_INTR_THRESH_FREE_SLOTS_TO_PL);
    }
    else if (op_mode == dma_op_mode_t::PERIODIC){
        r = _axilite->write(0x0000'0000, REGW_INTR_THRESH_FREE_SLOTS_TO_PL);
        return EXIT_FAILURE; // not implemented yet
    }
    else{
        return EXIT_FAILURE;
    }
    return r;
}