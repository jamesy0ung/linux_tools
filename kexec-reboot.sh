#!/bin/bash

# Must be run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Get current kernel version
KERNEL_VERSION=$(uname -r)
KERNEL_IMAGE="/boot/vmlinuz-${KERNEL_VERSION}"
INITRD_IMAGE="/boot/initramfs-${KERNEL_VERSION}.img"

# Check if kernel image exists
if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "Kernel image not found: $KERNEL_IMAGE" >&2
    exit 1
fi

# Check if initrd exists
if [ ! -f "$INITRD_IMAGE" ]; then
    echo "Initrd image not found: $INITRD_IMAGE" >&2
    exit 1
fi

# Get current kernel command line
CMDLINE=$(cat /proc/cmdline)

# Load kernel
echo "Loading kernel $KERNEL_IMAGE with initrd $INITRD_IMAGE"
kexec -l "$KERNEL_IMAGE" --initrd="$INITRD_IMAGE" --command-line="$CMDLINE"

# If we got here, kexec load was successful
echo "Kernel loaded successfully. Performing clean shutdown before kexec..."

# Sync filesystems to ensure data is written to disk
sync

# Use systemd to properly shut down the system but skip the actual reboot
# This will stop services, unmount filesystems, etc.
systemctl kexec
