if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_swconfig_json> <debug_mode> <print_swconfig>"
    echo "       path_swconfig_json: [*/swconfig*.json]"
    echo "       debug_mode: [true|false]"
    echo "       print_swconfig: [true|false]"
    exit 1
fi

# Check number of arguments
arg_path_swconfig_json=$1
arg_debug_mode=$2
arg_print_swconfig=$3
#sweep_progress is an example of arg parse for integer

# Activate platform (load device tree and flash bitstream)
source "$BENCHDMAAER_PATH/firmware/deactivate.sh"
source "$BENCHDMAAER_PATH/firmware/activate.sh"

# Debug mode
target_exec=""
case $arg_debug_mode in
    true)
        target_exec=debug_bench_dma_aer.out
        ;;
    false)
        target_exec=bench_dma_aer.out
        ;;
    *)
        echo "Invalid input: $arg_debug_mode. [true|false]"
        break
        ;;
esac

# Print software config loaded
case $arg_print_swconfig in
    true)
        sudo "$BENCHDMAAER_PATH/app/build/$target_exec" --fpath-swconfig $1 --print-swconfig --sweep-progress 0
        ;;
    false)
        sudo "$BENCHDMAAER_PATH/app/build/$target_exec" --fpath-swconfig $1 --sweep-progress 0
        ;;
    *)
        echo "Invalid input: $arg_print_swconfig. [true|false]"
        break
        ;;
esac