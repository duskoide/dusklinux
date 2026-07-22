# Building dusklinux ISO

This document explains how to build the dusklinux installation ISO.

## Prerequisites

You need a running Alpine Linux system (or chroot) with the following packages:

```bash
# Install required packages
apk add git alpine-conf mkinitfs
```

## Build Process

### 1. Clone the Repository

```bash
git clone <repository-url>
cd dusklinux
```

### 2. Run the Build Script

```bash
./iso/build.sh
```

The build script will:
1. Download Alpine base packages
2. Apply the dusklinux overlay configuration
3. Install necessary packages (Wayland, GPU drivers, etc.)
4. Create a bootable ISO

### 3. Output

The resulting ISO will be located at:
```
./result/dusklinux.iso
```

## What's Included

The ISO contains:

### System Layer
- Alpine Linux base
- Linux LTS kernel
- OpenRC init system
- apk package manager
- Essential utilities

### Desktop Layer (Pre-installed via Nix)
- niri compositor
- DankMaterialShell
- kitty terminal
- zsh shell configuration
- All Home Manager packages

### Drivers & Firmware
- Mesa GPU drivers
- Wayland protocols
- Input device support
- NetworkManager
- Audio (PipeWire)

### Installer
- Interactive installation script
- Automated partitioning options
- User account setup
- System configuration

## Build Options

You can customize the build by modifying:

### `iso/mkimg.dusk.sh`
Controls which Alpine packages are included in the base system.

### `iso/genapkovl-dusk.sh`
Controls system configuration (services, users, settings).

### `home/home.nix`
Controls the Nix/Home Manager desktop layer.

## Troubleshooting

### Build Fails

- Ensure you're running on Alpine Linux
- Check you have enough disk space (5GB+ recommended)
- Verify internet connectivity for package downloads

### ISO Won't Boot

- Try a different boot method (UEFI vs BIOS)
- Check the ISO integrity: `sha256sum dusklinux.iso`

### Missing Drivers

After installation, see [GPU-DRIVERS.md](./docs/GPU-DRIVERS.md) for driver configuration.

## Continuous Integration

This project uses GitHub Actions for automated builds. The workflow:
- Triggers on push to `main` and tags
- Builds the ISO in an Alpine container
- Uploads artifacts for download

See `.github/workflows/build.yml` for details.

## Versioning

Releases are tagged with version numbers (e.g., `v0.1.0`). Each release includes:
- Tagged commit
- Pre-built ISO
- Release notes

See [Releases](../../releases) for available versions.
