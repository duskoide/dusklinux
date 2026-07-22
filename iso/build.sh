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
# Output: result/dusklinux.iso under the project root.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOSTNAME="${1:-dusklinux}"
APORTS_DIR="${APORTS_DIR:-/tmp/aports}"
OUTDIR="${OUTDIR:-$PROJECT_ROOT/result}"
mkdir -p "$OUTDIR"

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

# ─── ensure an abuild signing key exists ────────────────
# mkimage.sh signs the ISO's local boot repository (APKINDEX) via
# abuild-sign, which requires PACKAGER_PRIVKEY. mkimage.sh also installs
# the matching .pub key into the ISO so that repo is trusted at boot.
# Generate a key if none is already configured (don't clobber an existing one).
for _conf in /etc/abuild.conf "${ABUILD_CONF:-$HOME/.config/abuild/abuild.conf}"; do
    if [ -f "$_conf" ]; then
        . "$_conf"
    fi
done
if [ -z "$PACKAGER_PRIVKEY" ]; then
    echo "No abuild signing key configured — generating one (non-interactive)..."
    abuild-keygen -a -n
fi

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
#                      (apkovl + hostname are set inside the profile)
#   --tag edge       → build against Alpine edge
#   --arch x86_64    → target architecture
#   --repository     → package repos (edge main/community/testing)
#   --outdir         → where to put the resulting ISO

./scripts/mkimage.sh \
    --tag edge \
    --profile dusk \
    --arch x86_64 \
    --outdir "$OUTDIR" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/edge/main" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/edge/community" \
    --repository "https://dl-cdn.alpinelinux.org/alpine/edge/testing"

# ─── normalize the output name ──────────────────────────
# mkimage names the ISO alpine-<profile>-<tag>-<arch>.iso. Expose a stable
# name (dusklinux.iso) for the CI artifact and downstream tooling.
_iso="$(ls "$OUTDIR"/alpine-dusk-*.iso 2>/dev/null | head -n1)"
if [ -z "$_iso" ]; then
    echo "ERROR: no ISO was produced in $OUTDIR" >&2
    exit 1
fi
cp "$_iso" "$OUTDIR/dusklinux.iso"

echo
echo "=== dusklinux ISO built ==="
echo "Output: $OUTDIR/dusklinux.iso"
echo "Boot this in a VM (virtio-gpu, ≥2 vCPU, ≥4GB RAM) to test."
