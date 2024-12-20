# Check arguments and usage guide
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_swconfig_json>"
    echo "       path_swconfig_json: [*/swconfig*.json]"
    # echo "       debug_mode: [true|false]"
    # echo "       print_swconfig: [true|false]"
    exit 1
fi

# Application parameters
path_swconfig_json=$1
debug_mode=false
print_swconfig=false

# Launch application
source "$BENCHDMARX_PATH/app/run.sh" $path_swconfig_json $debug_mode $print_swconfig