#!/bin/bash

TAG_COLOR="\e[95m"
END_COLOR="\e[0m"
TAG_NAME="Bench DMA AER build"
TAG="[$TAG_COLOR$TAG_NAME$END_COLOR]"

# Define environment variable for BENCHDMAAER_PATH if not already set
if [ -z "$BENCHDMAAER_PATH" ]; then
    echo -e "$TAG Error: BENCHDMAAER_PATH is not set"
    exit 1
fi

# Determine target architecture
if [ "$BENCHDMAAER_TARGET" = "vpk120" ]; then
    HW_FPGA_ARCH=versal
else
    HW_FPGA_ARCH=zynqmp
fi

# Define directories
DRIVERS_DIR="$BENCHDMAAER_PATH/drivers"
FIRMWARE_DIR="$BENCHDMAAER_PATH/firmware"
APP_DIR="$BENCHDMAAER_PATH/app"

# Function to build drivers
build_drivers() {
    distro=$(lsb_release -i | awk '{print $3}')

    if [ "$distro" = "Ubuntu" ]; then
        echo -e "$TAG Building drivers for Ubuntu ..."
        cd "$DRIVERS_DIR/dma_proxy/ubuntu" || exit 1
        make clean
        make
    elif [ "$distro" = "petalinux" ]; then
        echo -e "$TAG Skip building drivers for PetaLinux (prebuilt) ..."
    else
        echo -e "$TAG Error: $distro is not supported"
    fi
}

# Function to build firmware
build_firmware() {
    ROOTFS_FIRMWARE_VERSAL=false # currently firmware is packaged in rootfs
    echo -e "$TAG Building firmware..."
    cd "$FIRMWARE_DIR" || exit 1

    if [ "$HW_FPGA_ARCH" = "versal" ] && [ "$ROOTFS_FIRMWARE_VERSAL" = false ]; then
        sudo make "ARCH=$HW_FPGA_ARCH"
        sudo make "ARCH=$HW_FPGA_ARCH" install
    elif [ "$HW_FPGA_ARCH" = "zynqmp" ]; then
        sudo make "ARCH=$HW_FPGA_ARCH"
        sudo make "ARCH=$HW_FPGA_ARCH" install
    fi
}

# Function to build app (software)
build_app() {
    echo -e "$TAG Building C++ application..."
    cd "$APP_DIR" || exit 1
    make "ARCH=$HW_FPGA_ARCH" $1
}

# Function to clean builds
clean() {
    distro=$(lsb_release -i | awk '{print $3}')
    
    echo -e "$TAG Cleaning builds..."
    echo -e "$TAG Clean application build"
    cd "$APP_DIR" || exit 1
    make "ARCH=$HW_FPGA_ARCH" clean

    echo -e "$TAG Clean drivers build"
    if [ "$distro" = "Ubuntu" ]; then
        cd "$DRIVERS_DIR/dma_proxy/ubuntu" || exit 1
        make clean
    fi

    echo -e "$TAG Clean firmware build"
    cd "$FIRMWARE_DIR" || exit 1
    make "ARCH=$HW_FPGA_ARCH" clean 

    echo -e "$TAG Clean installed firmware"
    sudo rm -r "/lib/firmware/xilinx/$BENCHDMAAER_TARGET-bench_dma_aer"

    echo -e "$TAG Clean environment variables"
    unset "$BENCHDMAAER_PATH"

    cd
}

# Main function to handle options
main() {
    case $1 in
        drivers)
            build_drivers
            ;;
        firmware)
            build_firmware
            ;;
        app)
            build_app "release"
            ;;
        clean)
            clean
            ;;
        debug)
            build_drivers
            build_firmware
            build_app "debug"
            ;;
        all|"")
            build_drivers
            build_firmware
            build_app "release"
            ;;
        *)
            echo -e "$TAG Invalid option: $1"
            echo -e "$TAG Usage: $0 [drivers|firmware|app|debug|all|clean]"
            exit 1
            ;;
    esac
}

main "$@"