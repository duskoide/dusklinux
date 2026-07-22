#!/bin/sh -e
# dusklinux installer - Nix installation
# Requires: USERNAME exported

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root"
    exit 1
fi

if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME not set"
    exit 1
fi

USER_HOME="/home/$USERNAME"

echo "Installing Nix for user $USERNAME..."

# Install Nix in single-user mode
# Note: We'll use the official installer, then configure for the user
sh <(curl -L https://nixos.org/nix/install) --no-daemon

echo "Configuring Nix for $USERNAME..."

# Create user's Nix directory
mkdir -p "$USER_HOME/.config/nix"

# Enable flakes
cat > "$USER_HOME/.config/nix/nix.conf" <<EOF
experimental-features = nix-command flakes
EOF

# Set ownership
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# Add Nix profile to user's shell
if [ -f "$USER_HOME/.bashrc" ]; then
    if ! grep -q ".nix-profile/etc/profile.d/nix.sh" "$USER_HOME/.bashrc"; then
        echo 'if [ -e /home/'"$USERNAME"'/.nix-profile/etc/profile.d/nix.sh ]; then . /home/'"$USERNAME"'/.nix-profile/etc/profile.d/nix.sh; fi' >> "$USER_HOME/.bashrc"
    fi
fi

echo "Nix installation complete."
echo "User $USERNAME can now use Nix with flakes enabled."
