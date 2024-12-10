load_app() {
    if lsmod | grep -q "dma_proxy"; then
        sudo rmmod dma_proxy
    fi
    if [ "$BENCHDMAAER_TARGET" = "vpk120" ]; then
        sudo fpgautil -R -n full
        sudo fpgautil -b "/lib/firmware/xilinx/$BENCHDMAAER_TARGET-bench_dma_aer/$BENCHDMAAER_TARGET-bench_dma_aer.pdi" -o "/lib/firmware/xilinx/$BENCHDMAAER_TARGET-bench_dma_aer/$BENCHDMAAER_TARGET-bench_dma_aer.dtbo" -f Full -n "full"
    else
        sudo xmutil unloadapp
        sudo xmutil loadapp "$BENCHDMAAER_TARGET-bench_dma_aer"
    fi
}

load_driver() {
    distro=$(lsb_release -i | awk '{print $3}')
    plinux_release=$(uname -r)

    if [ "$distro" = "Ubuntu" ]; then
        sudo insmod "$BENCHDMAAER_PATH/drivers/dma_proxy/dma-proxy.ko"
    elif [ "$distro" = "petalinux" ]; then
        sudo insmod "/lib/modules/$plinux_release/extra/dma-proxy.ko"
    else
        echo "$TAG Error: No driver available for $distro"
    fi
}

load_app
load_driver