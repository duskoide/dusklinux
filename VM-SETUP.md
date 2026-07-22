# dusklinux - Alpine VM Setup Guide

## Quick Start

### 1. Create Alpine VM

Use virt-manager, GNOME Boxes, or QEMU directly:

```bash
# Download Alpine Standard ISO
wget https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-standard-3.21.0-x86_64.iso

# Create VM with:
# - 2+ vCPUs
# - 4GB+ RAM
# - 20GB+ disk
# - virtio GPU (for Wayland)
# - Attach the ISO
```

### 2. Install Alpine Base

Boot the ISO and run:

```bash
setup-alpine
# Follow prompts:
# - Keyboard: us
# - Hostname: dusklinux
# - Network: dhcp
# - Root password: (set one)
# - Timezone: (your timezone)
# - Proxy: none
# - Mirror: (pick one)
# - SSH server: openssh
# - NTP client: chrony
# - Disk: sda (or your disk)
# - Use it: y

# Reboot into installed system
reboot
```

### 3. Run Bootstrap

After reboot, login as root and run the bootstrap script:

```bash
# Mount the repo (or clone it)
# Option A: If repo is accessible
mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt
cd /mnt
./scripts/bootstrap-alpine.sh

# Option B: Clone from git
apk add git
git clone <repo-url> /root/dusklinux
cd dusklinux
./scripts/bootstrap-alpine.sh
```

### 4. Switch to User and Test

```bash
su - pn
cd ~/dusklinux  # or wherever you cloned it
./scripts/test-phase1.sh
```

### 5. Start the Desktop

```bash
niri-session
```

If successful, you should see:
- niri compositor running
- DMS shell (quickshell) launching
- kitty terminal opening

**Take a screenshot** to prove Phase 1 works!

## Troubleshooting

### niri won't start

Check seatd:
```bash
sudo rc-service seatd status
# If not running:
sudo rc-service seatd start
```

Check user groups:
```bash
groups
# Should include: wheel, video, input, seat
```

Check GPU:
```bash
lspci | grep -i vga
ls /dev/dri/
```

### DMS doesn't launch

Check logs:
```bash
journalctl --user -u dms
# or
qs -c dms 2>&1 | tee /tmp/dms.log
```

### Quick version check

```bash
nix --version
which niri
which qs
which kitty
```

## Phase 1 Acceptance Criteria

- [ ] Alpine VM boots successfully
- [ ] Bootstrap script completes without errors
- [ ] User 'pn' exists with correct groups
- [ ] Nix is installed and flakes enabled
- [ ] `nix build` succeeds
- [ ] `./result/activate` succeeds
- [ ] `niri-session` launches from TTY
- [ ] DMS shell appears
- [ ] Screenshot taken ✓

## Next: Phase 2

Once Phase 1 is proven, we'll:
- Refine the home-manager config structure
- Add more packages and dotfiles integration
- Test config reproducibility
