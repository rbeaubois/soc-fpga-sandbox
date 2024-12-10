#ifndef __HWCONFIG_SYS_H__
#define __HWCONFIG_SYS_H__

#if defined(HW_FPGA_ARCH_ZYNQMP)
    #include "zynqmp/hwconfig_sys_zynqmp.h"
#elif defined(HW_FPGA_ARCH_VERSAL)
    #include "versal/hwconfig_sys_versal.h"
#else
    #include "zynqmp/hwconfig_sys_zynqmp.h"
#endif

#endif
