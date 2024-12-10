#ifndef __HWCONFIG_AXIL_CONTROL_H__
#define __HWCONFIG_AXIL_CONTROL_H__

#if defined(HW_FPGA_ARCH_ZYNQMP)
    #include "zynqmp/hwconfig_axil_control_zynqmp.h"
#elif defined(HW_FPGA_ARCH_VERSAL)
    #include "versal/hwconfig_axil_control_versal.h"
#else
    #include "zynqmp/hwconfig_axil_control_zynqmp.h"
#endif

#endif
