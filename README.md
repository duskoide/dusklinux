# dusklinux

A minimal Linux distribution built on Alpine Linux, featuring a declarative desktop layer powered by Nix and Home Manager.

## Philosophy

dusklinux follows a clear separation of concerns:

- **System layer** (Alpine + OpenRC): Minimal, stable, traditional Linux
- **Desktop layer** (Nix + Home Manager): Declarative, reproducible, easy to customize

This means you get Alpine's simplicity and speed for the base system, while your desktop environment, applications, and dotfiles are managed declaratively through Nix.

## Desktop Environment

- **Compositor**: niri (scrollable-tiling Wayland compositor)
- **Shell**: DankMaterialShell (DMS)
- **Terminal**: kitty
- **Shell**: zsh with powerlevel10k

## Quick Start

### 1. Build the ISO

```bash
# Clone the repository
git clone <this-repo>
cd dusklinux

# Build the ISO
./scripts/build-iso.sh

# The ISO will be in ./result/
```

### 2. Install

Boot the ISO and run the installer:

```bash
# From the live environment
./install.sh

# Follow the prompts:
# - Select installation disk
# - Set root password
# - Create user account
# - Choose timezone
# - Select desktop environment
```

### 3. First Boot

After installation and reboot, you'll be greeted by greetd/tuigreet. Log in and you'll enter the niri + DMS desktop.

## Architecture

```
┌─────────────────────────────────────────────┐
│         Desktop Layer (Nix + HM)            │
│  niri │ DMS │ kitty │ zsh │ dotfiles │ ... │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│         System Layer (Alpine)               │
│  kernel │ OpenRC │ apk │ base utils │ ...  │
└─────────────────────────────────────────────┘
```

The desktop layer is completely declarative. Run `home-manager switch` to rebuild and apply changes. The system layer remains a standard Alpine installation.

## Customization

### Desktop Configuration

Edit `home/home.nix` to customize:
- Packages and applications
- Desktop environment settings
- Dotfiles and shell configuration

### System Configuration

The system is configured through standard Alpine mechanisms:
- `/etc/` configuration files
- OpenRC services
- apk package manager

## Documentation

- [PLAN.md](./PLAN.md) - Full project plan and roadmap
- [BUILDING.md](./docs/BUILDING.md) - Detailed build instructions
- [GPU-DRIVERS.md](./docs/GPU-DRIVERS.md) - GPU driver configuration guide

## Hardware Requirements

- x86_64 architecture
- 2GB+ RAM (4GB recommended)
- 20GB+ storage
- GPU with Wayland support (Intel/AMD recommended)

## Project Status

**Current Phase**: 6 (Distribution & docs)

See [PLAN.md](./PLAN.md) for the full roadmap and status of each phase.

## License

See [LICENSE](./LICENSE) for details.

## Acknowledgments

- [Alpine Linux](https://alpinelinux.org/) - Base system
- [Nix](https://nixos.org/) - Package management
- [Home Manager](https://nix-community.github.io/home-manager/) - User environment management
- [niri](https://github.com/YaLTeR/niri) - Wayland compositor
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) - Desktop shell
