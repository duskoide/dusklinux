#!/bin/sh
# dusklinux - Phase 1 test script
# Run this after bootstrap to activate the home-manager config

set -e

echo "=== dusklinux: Phase 1 Test ==="
echo

# Check we're the right user
if [ "$(whoami)" != "pn" ]; then
    echo "Error: Run as user 'pn'"
    exit 1
fi

# Navigate to repo
if [ ! -d "$HOME/dusklinux" ]; then
    echo "Error: Clone this repo to ~/dusklinux first"
    exit 1
fi

cd "$HOME/dusklinux"

echo "[1/3] Building home-manager configuration..."
nix build .#homeConfigurations.pn.activationPackage

echo "[2/3] Activating configuration..."
./result/activate

echo "[3/3] Verifying installation..."
echo
echo "Checking packages:"
which niri || echo "ERROR: niri not found"
which qs || echo "ERROR: quickshell (qs) not found"
which kitty || echo "ERROR: kitty not found"
echo
echo "Checking niri config:"
if [ -f "$HOME/.config/niri/config.kdl" ]; then
    echo "✓ niri config exists"
else
    echo "✗ niri config missing"
fi
echo
echo "Checking zsh config:"
if [ -f "$HOME/.zshrc" ]; then
    echo "✓ .zshrc exists"
else
    echo "✗ .zshrc missing"
fi

echo
echo "=== Phase 1 Test Complete ==="
echo
echo "To start the desktop:"
echo "  niri-session"
echo
echo "If niri fails, check:"
echo "  - seatd service: sudo rc-service seatd status"
echo "  - User groups: groups"
echo "  - GPU drivers: lspci | grep -i vga"
echo
