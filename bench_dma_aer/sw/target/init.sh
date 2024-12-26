#!/bin/bash
TAG_COLOR="\e[95m"
END_COLOR="\e[0m"
TAG_NAME="Bench DMA AER"
TAG="[$TAG_COLOR$TAG_NAME$END_COLOR]"

echo -e "$TAG Setup environment variables and scripts permissions"

# Check command-line argument
case $1 in
    kr260|kv260|vpk120)
        export BENCHDMAAER_TARGET=$1
        ;;
    *)
        echo "Invalid option: $1"
        echo "Usage: $0 [kr260|kv260|vpk120]"
        exit 1
        ;;
esac

# Initialize BENCHDMAAER_PATH if not set
if [ -z "$BENCHDMAAER_PATH" ]; then
    DIR="$( cd "$( dirname -- "$0" )" && pwd )"
    export BENCHDMAAER_PATH="$DIR"
fi

# Set execute permissions for scripts
chmod +x "$BENCHDMAAER_PATH"/*.sh
chmod +x "$BENCHDMAAER_PATH"/app/*.sh
chmod +x "$BENCHDMAAER_PATH"/firmware/*.sh


# Check if .init.bak file exists, if not, create it and update ~/.bashrc
if [ ! -e "$BENCHDMAAER_PATH/.init.bak" ]; then
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
        cp "$BENCHDMAAER_PATH/init.sh" "$BENCHDMAAER_PATH/.init.bak"
        echo "export BENCHDMAAER_PATH=$BENCHDMAAER_PATH" >> ~/.bashrc
        echo "source $BENCHDMAAER_PATH/init.sh $BENCHDMAAER_TARGET" >> ~/.bashrc
    fi
fi
