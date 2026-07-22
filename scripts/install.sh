#!/bin/sh -e
# dusklinux installer - main entry point
# Usage: sudo ./scripts/install.sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root"
    exit 1
fi

echo "=== dusklinux installer ==="
echo

# Check if we're running from the ISO
if [ ! -d "/run/media" ] && [ ! -b /dev/sda ] && [ ! -b /dev/nvme0n1 ]; then
    echo "Warning: No disk devices detected."
    echo "This script is meant to run from the dusklinux live ISO."
    echo "Continue anyway? (y/N)"
    read -r answer
    [ "$answer" = "y" ] || exit 1
fi

# Interactive setup
echo "Step 1: Configure installation"
echo "------------------------------"

# Target disk
echo "Available disks:"
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo
echo -n "Target disk (e.g., sda, nvme0n1): "
read -r DISK
if [ -z "$DISK" ]; then
    echo "No disk specified, exiting"
    exit 1
fi

if [ ! -b "/dev/$DISK" ]; then
    echo "Error: /dev/$DISK not found"
    exit 1
fi

# User setup
echo
echo -n "Username: "
read -r USERNAME
if [ -z "$USERNAME" ]; then
    echo "No username specified, exiting"
    exit 1
fi

echo -n "Password for $USERNAME: "
read -rs PASSWORD
echo
echo -n "Confirm password: "
read -rs PASSWORD_CONFIRM
echo

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Error: passwords don't match"
    exit 1
fi

# Hostname
echo
echo -n "Hostname [dusklinux]: "
read -r HOSTNAME
HOSTNAME="${HOSTNAME:-dusklinux}"

# Timezone
echo
echo -n "Timezone [UTC]: "
read -r TIMEZONE
TIMEZONE="${TIMEZONE:-UTC}"

echo
echo "Installation summary:"
echo "  Disk: /dev/$DISK"
echo "  Username: $USERNAME"
echo "  Hostname: $HOSTNAME"
echo "  Timezone: $TIMEZONE"
echo
echo "WARNING: This will erase all data on /dev/$DISK!"
echo -n "Continue? (y/N): "
read -r answer
[ "$answer" = "y" ] || exit 1

# Export variables for sub-scripts
export DISK USERNAME PASSWORD HOSTNAME TIMEZONE

# Run installation phases
echo
echo "Step 2: Install Alpine base"
echo "---------------------------"
./scripts/setup-alpine.sh

echo
echo "Step 3: Install Nix"
echo "-------------------"
./scripts/install-nix.sh

echo
echo "Step 4: Apply home-manager configuration"
echo "----------------------------------------"
./scripts/apply-hm.sh

echo
echo "=== Installation complete ==="
echo "Please reboot and remove the installation media."
echo "Login as $USERNAME and your dusklinux system will be ready."
