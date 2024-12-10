#ifndef __HWCONFIG_AXIDMA_H__
#define __HWCONFIG_AXIDMA_H__

#if defined(HW_FPGA_ARCH_ZYNQMP)
    #include "zynqmp/hwconfig_axidma_zynqmp.h"
#elif defined(HW_FPGA_ARCH_VERSAL)
    #include "versal/hwconfig_axidma_versal.h"
#else
    #include "zynqmp/hwconfig_axidma_zynqmp.h"
#endif

#endif
