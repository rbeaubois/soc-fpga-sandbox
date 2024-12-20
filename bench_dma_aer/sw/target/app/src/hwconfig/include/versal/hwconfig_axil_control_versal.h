// *** Generated from: axilite_mapper_pkg.vhd ***
// *** Mapping AXI-Lite core: control ***

#ifndef __HWCONFIG_AXIL_CONTROL_VERSAL_H__
#define __HWCONFIG_AXIL_CONTROL_VERSAL_H__

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Registers mapping
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// Index registers written by PS
#define REGW_CONTROL 0
#define REGW_INTR_THRESH_FREE_SLOTS_TO_PL 1
#define REGW_INTR_THRESH_READY_EV_TO_PS 2

// Index registers read by PS
#define REGR_HW_UID 3

// Bit labels PS write registers
#define BIT_RESET_REGW_CONTROL 0
#define BIT_EN_CORE_REGW_CONTROL 1
#define BIT_OPMODE_RECV_DMA_SPK_REGW_CONTROL 2
#define BIT_OPMODE_SEND_DMA_SPK_REGW_CONTROL 3

// Bit labels PS read registers

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Number of registers
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#define NB_REGS 4
#define NB_PS_WRITE_REGS 3
#define NB_PS_READ_REGS 1

#endif
