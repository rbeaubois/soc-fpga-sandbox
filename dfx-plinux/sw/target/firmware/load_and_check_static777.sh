#!/bin/bash
img="static777"
dirpath_firmware="/lib/firmware/xilinx"
path_img=${dirpath_firmware}/${img}/${img}
axi_gpio_offset=0x20100000000
axi_gpio_uuid=777

# Load firmware
sudo fpgautil -R -n Full
sudo fpgautil -b ${path_img}.pdi -o ${path_img}.dtbo -f Full -n Full

# Read and check 32-bit uuid
uuid=$(sudo devmem $axi_gpio_offset l)
if [ "$read_value" -eq "$axi_gpio_uuid" ]; then
    echo "UUID is matching: $axi_gpio_uuid"
else
    echo "UUID is NOT matching: $uuid /= $axi_gpio_uuid"
fi
