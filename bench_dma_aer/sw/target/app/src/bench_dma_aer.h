/*
*! @title      Main application for bench_dma_aer
*! @file       bench_dma_aer.h
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

#ifndef BENCHDMAAER_H
#define BENCHDMAAER_H

    /* ############################# Parameters ############################# */
    #define SW_VERSION "0.1.0"

    #if defined(HW_FPGA_ARCH_ZYNQMP)
        #define HW_FPGA_ARCH                "ZynqMP"
        #define OFFSET_AXI_FREE_SLOTS_TO_PL 0x0000'A001'0000 // physical address map
        #define OFFSET_AXI_READY_EV_TO_PS   0x0000'A001'1000 // physical address map
        #define OFFSET_AXI_PARAMS_DMA       0x0000'A001'2000 // physical address map
        #define OFFSET_AXI_LITE_CONTROL     0x0000'A002'0000 // physical address map
        #define OFFSET_AXI_LITE_STATUS      0x0000'A003'0000 // physical address map
        
        #define RANGE_AXI_FREE_SLOTS_TO_PL  0x0000'0000'1000 // range address map
        #define RANGE_AXI_READY_EV_TO_PS    0x0000'0000'1000 // range address map
        #define RANGE_AXI_PARAMS_DMA        0x0000'0000'1000 // range address map
        #define RANGE_AXI_LITE_CONTROL      0x0000'0001'0000 // range address map
        #define RANGE_AXI_LITE_STATUS       0x0000'0001'0000 // range address map
    #elif defined(HW_FPGA_ARCH_VERSAL)
        #define HW_FPGA_ARCH                "Versal"
        #define OFFSET_AXI_FREE_SLOTS_TO_PL 0x0203'4000'0000 // physical address map
        #define OFFSET_AXI_READY_EV_TO_PS   0x0203'4000'1000 // physical address map
        #define OFFSET_AXI_PARAMS_DMA       0x0203'4000'2000 // physical address map
        #define OFFSET_AXI_LITE_CONTROL     0x0203'4001'0000 // physical address map
        #define OFFSET_AXI_LITE_STATUS      0x0203'4002'0000 // physical address map
        #define OFFSET_AXI_PARAMS_DMA       0x0000'0000'0000 // physical address map

        #define RANGE_AXI_FREE_SLOTS_TO_PL  0x0000'0000'1000 // range address map
        #define RANGE_AXI_READY_EV_TO_PS    0x0000'0000'1000 // range address map
        #define RANGE_AXI_PARAMS_DMA        0x0000'0000'1000 // range address map
        #define RANGE_AXI_LITE_CONTROL      0x0000'0001'0000 // range address map
        #define RANGE_AXI_LITE_STATUS       0x0000'0001'0000 // range address map
    #else
        #define HW_FPGA_ARCH                "Undefined"
        #define OFFSET_AXI_FREE_SLOTS_TO_PL 0x0000'0000'0000 // physical address map
        #define OFFSET_AXI_READY_EV_TO_PS   0x0000'0000'0000 // physical address map
        #define OFFSET_AXI_PARAMS_DMA       0x0000'0000'0000 // physical address map
        #define OFFSET_AXI_LITE_CONTROL     0x0000'0000'0000 // physical address map
        #define OFFSET_AXI_LITE_STATUS      0x0000'0000'0000 // physical address map
        
        #define RANGE_AXI_FREE_SLOTS_TO_PL  0x0000'0000'0000 // range address map
        #define RANGE_AXI_READY_EV_TO_PS    0x0000'0000'0000 // range address map
        #define RANGE_AXI_PARAMS_DMA        0x0000'0000'0000 // range address map
        #define RANGE_AXI_LITE_CONTROL      0x0000'0000'0000 // range address map
        #define RANGE_AXI_LITE_STATUS       0x0000'0000'0000 // range address map
    #endif

#endif