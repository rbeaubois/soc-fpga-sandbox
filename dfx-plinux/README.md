# DFX Petalinux

## Overview

* Load static configuration on VPK120
* Load partial configurations on VPK120

# 1. Static configurations on VPK120

This corresponds to entirely reconfigure the device using a static image similarly to what xmutil does on KR260/KV260 boards (full PL programming).
Static configurations xsa generated from GUI caused Petalinux to crash ([issue note](https://github.com/Xilinx/meta-xilinx-tools/issues/49)), hence xsa export should be performed using TCL.

Two static images are created:
* static777: CIPS + PS NOC + AXI GPIO @0x20100000000 with value 777
* static888: CIPS + PS NOC + AXI GPIO @0x201C0000000 with value 888
* static999: CIPS + PS NOC + AXI DMA + AXI GPIO @0x201C0000000 with value 999

### Requirements

| Tool          | Version       |
|---------------|---------------|
| **Vivado**    | 2023.2 |
| **Petalinux** | 2023.2 |
| **Target**    | VPK120 |

### Project structure

* **hw** : software sources
  * **rtl**: configuration, emulation and monitoring scripts
    * **tcl**: project generation scripts

### Generate hardware (.xsa)

* Create Vivado projects and generate .xsa

```bash
# Change directory to project "root"
cd <...>/soc-fpga-sandbox/dfx-plinux
# Source AMD tools
source <path_to_vivado>/<version>/settings64.sh
# Launch vivado in tcl mode
vivado -mode tcl
# Create projects (if you have enough resources you can run 2 vivados in different shells)
source ./hw/rtl/tcl/create_vivado_prj_static777_VPK120_v2023_2.tcl
source ./hw/rtl/tcl/create_vivado_prj_static888_VPK120_v2023_2.tcl
```

### Generate Petalinux image

* Create Petalinux project
```bash
source /tools/Xilinx/PetaLinux/2023.2/settings.sh
petalinux-create -t project -n plinux-vpk120 -s /tools/Xilinx/PetaLinux/2023.2/bsp/xilinx-vpk120-v2023.2-10140544.bsp
cd plinux-vpk120
```
* Configure image

```bash
# Default boot image
petalinux-config --get-hw-description "<...>/static777_VPK120_v2023_2.xsa"
```

```bash
# in petalinux configuration window
FPGA Manager --> Fpga Manager[*]
Image Packaging Configuration --> Root Filesystem Type --> [*] EXT4 (SD/eMMC/SATA/USB)
Image Packaging Configuration --> (/dev/mmcblk0p2) Device node of SD device
Image Packaging Configuration --> [] Copy final images to tftpboot
DTG Settings --> [*] DeviceTree Overlay
DTG Settings --> Kernel Bootargs ---> (... uio_pdrv_genirq.of_id=generic-uio) Add extra boot args # append to existing args
```

* Create static applications
```bash
petalinux-create --type apps --template dfx_dtg_versal_static -n static888 --enable --srcuri "<...>/static888_VPK120_v2023_2.xsa"
petalinux-create --type apps --template dfx_dtg_versal_static -n static777 --enable --srcuri "<...>/static777_VPK120_v2023_2.xsa"
```

> Remove applications by removing from `<plnx-proj-root>/project-spec/meta-plnx-generated/recipes-core/images/petalinux-image.bbappend` + delete in recipes_apps

* Configure rootfs from user config (`<petalinux_prj_dir>/project-spec/meta-user/conf/user-rootfsconfig`)
```bash
#File: <petalinux_prj_dir>/project-spec/meta-user/conf/user-rootfsconfig
# Essentials
CONFIG_xrt
CONFIG_xrt-dev
CONFIG_dnf
CONFIG_zocl
CONFIG_git
CONFIG_bootgen
CONFIG_bootgen-dev
CONFIG_packagegroup-petalinux-self-hosted
CONFIG_packagegroup-core-buildessential
CONFIG_packagegroup-core-buildessential-dev
CONFIG_imagefeature-package-management
CONFIG_imagefeature-serial-autologin-root
CONFIG_make
CONFIG_python3-numpy
# Additional
CONFIG_ethtool
CONFIG_wget
CONFIG_gzip
CONFIG_vim
CONFIG_vim-syntax
CONFIG_man
CONFIG_man-pages
CONFIG_perl
CONFIG_automake
CONFIG_cpufrequtils
```

```Bash
# Select user packages
petalinux-config -c rootfs
```

* Configure kernel
```bash
petalinux-config -c kernel
```

```bash
General setup --> Preemption Model --> (X) Preemptible Kernel (Low-Latency Desktop)
```

* Build Petalinux image
```bash
petalinux-build
```

* Package image
```bash
petalinux-package --boot --format BIN --plm --psmfw --u-boot --dtb
petalinux-package --wic --outdir wicimage/
```

* Flash SD
```bash
## using dd
sudo dd if=./wicimage/petalinux-sdimage.wic of=/dev/mmcblk0 bs=1M status=progress
sudo umount /dev/mmcblk0p1 /dev/mmcblk0p2

## "manual" sd-boot(exFAT) sd_root(ext4)
cd images/linux
sudo cp image.ub boot.scr BOOT.BIN /.../plx-sd-boot 
sudo tar xvfp ./rootfs.tar.gz -C /.../plx-sd-root 
```

* Install optional packages
```bash
# Check if package management works correctly
sudo dnf repoquery
sudo dnf install htop zeromq-dev
```

* Load configurations (as PL with device tree overlay) and verify
```bash
# /!\ Always remove overlay before configuring

# Load static image 777
sudo fpgautil -R -n Full
sudo fpgautil -b /lib/firmware/xilinx/static777/static777.pdi -o /lib/firmware/static777/static777.dtbo -f Full -n Full

# Check if image is loaded correctly (777 -> 0x309)
sudo devmem 0x20100000000

# Load static image 888
sudo fpgautil -R -n Full
sudo fpgautil -b /lib/firmware/xilinx/static888/static888.pdi -o /lib/firmware/static888/static888.dtbo -f Full -n Full

# Check if image is loaded correctly (888 -> 0x378)
sudo devmem 0x201C0000000
```

> For some reason it doesn't want to load static888 and crash kernel (can't find pdi apparently or something like that, maybe because static777 is the "base" hardware). Potential would to have base image as just the Versal CIPS maybe