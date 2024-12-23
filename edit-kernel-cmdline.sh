#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Default values
GRUB_CONFIG="/etc/default/grub"
TEMP_FILE=$(mktemp)
REBOOT_FLAG=false
NO_REBOOT_FLAG=false

# Parse command line arguments
while getopts "rn" opt; do
    case $opt in
        r)
            REBOOT_FLAG=true
            ;;
        n)
            NO_REBOOT_FLAG=true
            ;;
        \?)
            echo "Usage: $0 [-r] [-n]"
            echo "  -r    Reboot after updating"
            echo "  -n    Don't prompt for reboot"
            exit 1
            ;;
    esac
done

# Check if grub config exists
if [ ! -f "$GRUB_CONFIG" ]; then
    echo "Error: GRUB configuration file not found at $GRUB_CONFIG"
    exit 1
fi

# Extract current cmdline
current_cmdline=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONFIG" | cut -d'"' -f2)
if [ -z "$current_cmdline" ]; then
    echo "Error: GRUB_CMDLINE_LINUX_DEFAULT not found in $GRUB_CONFIG"
    exit 1
fi

# Write current cmdline to temp file
echo "$current_cmdline" > "$TEMP_FILE"

# Get the editor
EDITOR=${EDITOR:-$(which vim)}
if [ -z "$EDITOR" ]; then
    EDITOR=$(which nano)
    if [ -z "$EDITOR" ]; then
        echo "Error: No text editor found"
        rm "$TEMP_FILE"
        exit 1
    fi
fi

# Open editor
$EDITOR "$TEMP_FILE"

# Check if file was modified
if [ ! -s "$TEMP_FILE" ]; then
    echo "Error: Empty command line not allowed"
    rm "$TEMP_FILE"
    exit 1
fi

# Read new cmdline
new_cmdline=$(cat "$TEMP_FILE")
rm "$TEMP_FILE"

# Update grub config
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_cmdline\"|" "$GRUB_CONFIG"

# Update grub
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif [ -f /boot/grub2/grub.cfg ]; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
else
    echo "Error: Could not find grub update command"
    exit 1
fi

# Handle reboot
if [ "$REBOOT_FLAG" = true ]; then
    echo "Rebooting system..."
    reboot
elif [ "$NO_REBOOT_FLAG" = false ]; then
    read -p "Do you want to reboot now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
fi

echo "Kernel command line updated successfully"
