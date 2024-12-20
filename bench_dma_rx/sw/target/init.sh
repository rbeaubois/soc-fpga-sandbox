#!/bin/bash
TAG_COLOR="\e[95m"
END_COLOR="\e[0m"
TAG_NAME="Bench DMA RX"
TAG="[$TAG_COLOR$TAG_NAME$END_COLOR]"

echo -e "$TAG Setup environment variables and scripts permissions"

# Check command-line argument
case $1 in
    kr260|kv260|vpk120)
        export BENCHDMARX_TARGET=$1
        ;;
    *)
        echo "Invalid option: $1"
        echo "Usage: $0 [kr260|kv260|vpk120]"
        exit 1
        ;;
esac

# Initialize BENCHDMARX_PATH if not set
if [ -z "$BENCHDMARX_PATH" ]; then
    DIR="$( cd "$( dirname -- "$0" )" && pwd )"
    export BENCHDMARX_PATH="$DIR"
fi

# Set execute permissions for scripts
chmod +x "$BENCHDMARX_PATH"/*.sh
chmod +x "$BENCHDMARX_PATH"/app/*.sh
chmod +x "$BENCHDMARX_PATH"/firmware/*.sh


# Check if .init.bak file exists, if not, create it and update ~/.bashrc
if [ ! -e "$BENCHDMARX_PATH/.init.bak" ]; then
    # Handle argument to skip
    if [ -z "$2" ]; then
        echo "Launch initialization on startup (append to .bashrc)? (y/n): "
        read append_to_bashrc
        append_to_bashrc=$(echo "$append_to_bashrc" | tr '[:upper:]' '[:lower:]')
    elif [ "$2" = "-y" ]; then
        append_to_bashrc="y"
    else
        echo "-y to automatically append and not $2"
        append_to_bashrc="n"
    fi
    
    # Append
    if [[ "$append_to_bashrc" == "y" || "$append_to_bashrc" == "yes" ]]; then
        cp "$BENCHDMARX_PATH/init.sh" "$BENCHDMARX_PATH/.init.bak"
        echo "export BENCHDMARX_PATH=$BENCHDMARX_PATH" >> ~/.bashrc
        echo "source $BENCHDMARX_PATH/init.sh $BENCHDMARX_TARGET" >> ~/.bashrc
    fi
fi
