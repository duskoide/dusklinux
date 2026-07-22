# GPU Driver Guide for dusklinux

Alpine Linux uses the **mesa** package for open-source GPU drivers (AMD, Intel, Nouveau). This guide covers GPU setup and troubleshooting.

## Check Your GPU

```bash
lspci | grep -i vga
```

## Intel GPUs

Intel GPUs are supported out-of-the-box via mesa. No additional packages needed.

**Verify:**
```bash
glxinfo | grep "OpenGL renderer"
```

Should show something like "Mesa Intel(R) UHD Graphics".

## AMD GPUs

AMD GPUs (Radeon RX series, etc.) are supported via mesa. No additional packages needed.

**Verify:**
```bash
glxinfo | grep "OpenGL renderer"
```

Should show "AMD Radeon RX" or similar.

## NVIDIA GPUs

NVIDIA support is more complex. You have two options:

### Option 1: Nouveau (Open Source, Default)

Nouveau is the open-source driver included in mesa. It works but has limited performance and no power management for newer cards.

**No additional setup needed** — it should work automatically.

**Limitations:**
- Poor performance on GTX 10xx+ and RTX cards
- No GPU frequency scaling
- May not support all features

### Option 2: Proprietary NVIDIA Driver

For better performance, install the proprietary driver:

```bash
# Install NVIDIA driver (Alpine 3.19+)
doas apk add nvidia-glx nvidia-modules

# Load the module
doas modprobe nvidia

# Verify
nvidia-smi
```

**Add to boot modules:**
```bash
echo "nvidia" | doas tee -a /etc/modules
```

**Reboot** to apply.

### Hybrid Graphics (Laptops with Intel + NVIDIA)

For laptops with both Intel and NVIDIA GPUs, you'll need **optimus-manager** or **envycontrol**:

```bash
# Install envycontrol
doas apk add envycontrol

# Switch to hybrid mode
envycontrol -s hybrid

# Reboot
```

Or use **nvidia-prime** for manual switching:
```bash
# Run apps on NVIDIA
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia your-app
```

## Troubleshooting

### Black screen on boot

1. Try booting with `nomodeset` kernel parameter
2. Check logs: `doas dmesg | grep -i drm`
3. Verify mesa is installed: `apk info mesa`

### Low performance

1. Check which driver is loaded: `glxinfo | grep "OpenGL renderer"`
2. For NVIDIA, ensure proprietary driver is installed
3. Check GPU temperature: `doas sensors`

### Screen tearing

niri should handle this automatically. If you see tearing:
1. Ensure `vsync` is enabled in your compositor
2. Check kernel parameters — add `video=...` options if needed

### Bluetooth not working

```bash
# Start bluetooth service
doas rc-service bluetooth start
doas rc-update add bluetooth default

# Check status
bluetoothctl
```

### Brightness control not working

```bash
# Install brightnessctl
doas apk add brightnessctl

# Adjust brightness
brightnessctl set 50%
```

## Wayland-Specific Notes

- **niri** should auto-detect your GPU
- For NVIDIA, ensure you're using the proprietary driver (not Nouveau) for best results
- HDR support requires recent mesa versions (22.3+)

## Resources

- [Alpine Linux GPU](https://wiki.alpinelinux.org/wiki/Graphic_card)
- [niri GPU troubleshooting](https://github.com/YaLTeR/niri/wiki)
- [Mesa drivers](https://docs.mesa3d.org/)
