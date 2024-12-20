load_app() {
    if lsmod | grep -q "dma_proxy"; then
        sudo rmmod dma_proxy
    fi
    if [ "$BENCHDMARX_TARGET" = "vpk120" ]; then
        sudo fpgautil -R -n full
        sudo fpgautil -b "/lib/firmware/xilinx/$BENCHDMARX_TARGET-bench_dma_rx/$BENCHDMARX_TARGET-bench_dma_rx.pdi" -o "/lib/firmware/xilinx/$BENCHDMARX_TARGET-bench_dma_rx/$BENCHDMARX_TARGET-bench_dma_rx.dtbo" -f Full -n "full"
    else
        sudo xmutil unloadapp
        sudo xmutil loadapp "$BENCHDMARX_TARGET-bench_dma_rx"
    fi
}

load_driver() {
    distro=$(lsb_release -i | awk '{print $3}')
    plinux_release=$(uname -r)

    if [ "$distro" = "Ubuntu" ]; then
        sudo insmod "$BENCHDMARX_PATH/drivers/dma_proxy/ubuntu/dma-proxy.ko"
    elif [ "$distro" = "petalinux" ]; then
        sudo insmod "$BENCHDMARX_PATH/drivers/dma_proxy/petalinux/dma-proxy.ko"
        # sudo insmod "/lib/modules/$plinux_release/extra/dma-proxy.ko"
    else
        echo "$TAG Error: No driver available for $distro"
    fi
}

load_app
load_driver