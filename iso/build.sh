#!/bin/sh -e
# dusklinux — custom ISO build script
#
# Builds a bootable dusklinux ISO using Alpine's mkimage tooling.
# Requires: Alpine Linux (or a chroot/container running Alpine) with:
#   apk-tools, abuild, xorriso, mtools, grub (for EFI), fakeroot
#
# Usage:
#   ./iso/build.sh [hostname]
#
# The hostname defaults to "dusklinux".
#
# Output: dusklinux-<date>-x86_64.iso in the project root.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOSTNAME="${1:-dusklinux}"
APORTS_DIR="${APORTS_DIR:-/tmp/aports}"
OUTDIR="${OUTDIR:-$PROJECT_ROOT}"

# ─── sanity checks ──────────────────────────────────────
command -v apk >/dev/null 2>&1 || {
    echo "ERROR: This script must run on Alpine Linux (requires apk)."
    echo "Use an Alpine VM or container to build the ISO."
    exit 1
}

for cmd in abuild xorriso fakeroot mksquashfs; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Missing required tool: $cmd"
        echo "Install with: apk add abuild xorriso fakeroot squashfs-tools"
        exit 1
    }
done

# ─── clone aports if needed ─────────────────────────────
if [ ! -d "$APORTS_DIR/scripts" ]; then
    echo "Cloning Alpine aports..."
    git clone --depth 1 https://git.alpinelinux.org/aports "$APORTS_DIR"
fi

# ─── install custom profile + overlay script ────────────
echo "Installing dusklinux custom files into aports..."
cp "$SCRIPT_DIR/mkimg.dusk.sh" "$APORTS_DIR/scripts/mkimg.dusk.sh"
chmod +x "$APORTS_DIR/scripts/mkimg.dusk.sh"

cp "$SCRIPT_DIR/genapkovl-dusk.sh" "$APORTS_DIR/scripts/genapkovl-dusk.sh"
chmod +x "$APORTS_DIR/scripts/genapkovl-dusk.sh"

# ─── build ──────────────────────────────────────────────
echo "Building dusklinux ISO..."
cd "$APORTS_DIR"

# The mkimage.sh command:
#   --profile dusk   → use profile_dusk() from mkimg.dusk.sh
#   --apkovl         → generate overlay via genapkovl-dusk.sh
#   --host           → hostname baked into the overlay
#   --arch x86_64    → target architecture
#   --repository     → package repos (edge/main + edge/community for latest)
#   --outdir         → where to put the resulting ISO

./scripts/mkimage.sh \
    --tag edge \
    --profile dusk \
    --apkovl "$SCRIPT_DIR/genapkovl-dusk.sh" \
    --hostname "$HOSTNAME" \
    --arch x86_64 \
    --outdir "$OUTDIR" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/edge/main" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/edge/community" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/edge/testing"

echo
echo "=== dusklinux ISO built ==="
echo "Output: $OUTDIR/$HOSTNAME-*.iso"
echo "Boot this in a VM (virtio-gpu, ≥2 vCPU, ≥4GB RAM) to test."
