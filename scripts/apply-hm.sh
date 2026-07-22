#!/bin/sh -e
# dusklinux installer - Apply home-manager configuration
# Requires: USERNAME exported

set -e

if [ -z "$USERNAME" ]; then
    echo "Error: USERNAME not set"
    exit 1
fi

USER_HOME="/home/$USERNAME"
DUSK_DIR="$USER_HOME/.config/dusklinux"

echo "Setting up dusklinux configuration for $USERNAME..."

# Create .config directory
mkdir -p "$USER_HOME/.config"

# Copy dusklinux config to user's .config
# In a real scenario, this would be cloned from a git repo
# For now, we assume the installer is running from the dusklinux directory
if [ -d "./home" ]; then
    echo "Copying configuration files..."
    cp -r ./home "$DUSK_DIR"
    cp ./flake.nix "$DUSK_DIR/"
    cp ./flake.lock "$DUSK_DIR/" 2>/dev/null || true
    
    # Set ownership
    chown -R "$USERNAME:$USERNAME" "$DUSK_DIR"
else
    echo "Error: Cannot find dusklinux configuration files"
    echo "Make sure you're running this from the dusklinux directory"
    exit 1
fi

echo "Building home-manager configuration..."

# Switch to user to run home-manager
su - "$USERNAME" -c "
    cd '$DUSK_DIR'
    
    # Build the configuration
    nix build .#homeConfigurations.$USERNAME.activationPackage
    
    # Activate
    ./result/activate
    
    echo 'Home-manager configuration applied successfully.'
"

echo "Creating desktop session..."

# Create niri session file for greetd
mkdir -p "$USER_HOME/.local/share/wayland-sessions"
cat > "$USER_HOME/.local/share/wayland-sessions/niri.desktop" <<EOF
[Desktop Entry]
Name=niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
EOF

chown -R "$USERNAME:$USERNAME" "$USER_HOME/.local"

echo "dusklinux configuration complete."
echo "Reboot to start your new system."
