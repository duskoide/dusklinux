#!/bin/sh
# dusklinux - Alpine VM bootstrap script
# Run this inside a fresh Alpine VM to install all prerequisites for niri+DMS

set -e

echo "=== dusklinux: Alpine VM Bootstrap ==="
echo

# Ensure we're root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Run as root (su or sudo)"
    exit 1
fi

echo "[1/6] Updating package index..."
apk update

echo "[2/6] Installing base system packages..."
apk add \
    git \
    curl \
    sudo \
    doas \
    font-noto \
    mesa \
    mesa-dri-gallium \
    eudev \
    libinput \
    pipewire \
    wireplumber \
    seatd \
    polkit-elogind \
    xdg-user-dirs \
    xdg-utils

echo "[3/6] Configuring seatd service..."
rc-update add seatd default
rc-service seatd start

echo "[4/6] Creating user 'pn'..."
if ! id -u pn >/dev/null 2>&1; then
    adduser -G wheel,video,input,seat -s /bin/sh pn
    echo "Set password for user 'pn':"
    passwd pn
fi

# Add user to required groups (in case they already existed)
addgroup pn wheel
addgroup pn video
addgroup pn input
addgroup pn seat

echo "[5/6] Configuring sudo access..."
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

echo "[6/6] Installing Nix (single-user mode)..."
if ! command -v nix >/dev/null 2>&1; then
    apk add nix
    # Initialize nix for the user
    echo "Switch to user 'pn' and run: nix --version"
else
    echo "Nix already installed"
fi

# Configure nix flakes
echo "[7/7] Enabling nix flakes..."
mkdir -p /etc/nix
cat > /etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
EOF

echo
echo "=== Bootstrap complete ==="
echo
echo "Next steps:"
echo "1. Switch to user: su - pn"
echo "2. Clone this repo: git clone <repo-url> ~/dusklinux"
echo "3. Build config: cd ~/dusklinux && nix build .#homeConfigurations.pn.activationPackage"
echo "4. Activate: ./result/activate"
echo "5. Start niri: niri-session"
echo
