/*
*! @title      Main application for bench_dma_rx
*! @file       bench_dma_rx.h
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
*! > **17 Oct 2024** : fpga hw arch passed at compilation from makefile (RB)
*/

#ifndef BENCHDMARX_H
#define BENCHDMARX_H

    /* ############################# Parameters ############################# */
    #define SW_VERSION                  "0.1.0"
    #define HW_VERSION                  "0.1.0"

    #define HW_FPGA_ARCH                "ZynqMP"
    #define OFFSET_AXI_GPIO_AXPARAMS    0x0000'A003'0000 // physical address map
    #define OFFSET_AXI_GPIO_EN          0x0000'A001'0000 // physical address map
    #define OFFSET_AXI_GPIO_FIFO_RCNT   0x0000'A002'0000 // physical address map
    
    #define RANGE_AXI_GPIO              0x0000'0000'1000 // range address map
#endif