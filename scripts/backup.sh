#!/bin/sh -e
# dusklinux backup script
# Creates a git-based backup of /etc and the user's config

set -e

if [ "$(id -u)" -eq 0 ]; then
    echo "This script should be run as a regular user, not root."
    exit 1
fi

BACKUP_DIR="$HOME/.config/dusklinux-backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Creating backup at $BACKUP_DIR/$TIMESTAMP..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup /etc (requires doas/sudo)
echo "Backing up /etc..."
TEMP_ETC=$(mktemp -d)
doas tar -czf "$TEMP_ETC/etc-$TIMESTAMP.tar.gz" -C / etc 2>/dev/null || {
    echo "Warning: Could not backup /etc (doas required)"
    rm -rf "$TEMP_ETC"
}

if [ -f "$TEMP_ETC/etc-$TIMESTAMP.tar.gz" ]; then
    mv "$TEMP_ETC/etc-$TIMESTAMP.tar.gz" "$BACKUP_DIR/"
    rm -rf "$TEMP_ETC"
fi

# Backup user config
echo "Backing up ~/.config..."
tar -czf "$BACKUP_DIR/config-$TIMESTAMP.tar.gz" -C "$HOME" .config 2>/dev/null || true

# Backup home-manager flake
echo "Backing up home-manager flake..."
if [ -d "$HOME/.config/home-manager" ]; then
    tar -czf "$BACKUP_DIR/hm-$TIMESTAMP.tar.gz" -C "$HOME/.config" home-manager 2>/dev/null || true
fi

# Git commit if it's a git repo
if [ -d "$BACKUP_DIR/.git" ] || git -C "$BACKUP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    cd "$BACKUP_DIR"
    git add .
    git commit -m "backup: $TIMESTAMP" --no-verify || true
fi

# Cleanup old backups (keep last 10)
cd "$BACKUP_DIR"
ls -t *.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -- || true

echo "Backup complete: $BACKUP_DIR/$TIMESTAMP"
echo "Backup files:"
ls -lh "$BACKUP_DIR" | tail -10
