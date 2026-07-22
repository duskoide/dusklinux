#!/bin/sh -e
# dusklinux installer - Alpine base installation
# Requires: DISK, USERNAME, PASSWORD, HOSTNAME, TIMEZONE exported

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: must run as root"
    exit 1
fi

# Check required variables
for var in DISK USERNAME PASSWORD HOSTNAME TIMEZONE; do
    if [ -z "${!var}" ]; then
        echo "Error: $var not set"
        exit 1
    fi
done

TARGET="/mnt"

echo "Partitioning /dev/$DISK..."

# Create partition table
parted -s "/dev/$DISK" mklabel gpt

# EFI partition (512MB)
parted -s "/dev/$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "/dev/$DISK" set 1 esp on

# Root partition (rest of disk)
parted -s "/dev/$DISK" mkpart primary ext4 513MiB 100%

# Wait for partitions to settle
sleep 2

# Detect partition naming (sdX vs nvmeXn1pY)
if echo "$DISK" | grep -qE "^(sd[a-z]|vd[a-z]|hd[a-z])$"; then
    PART1="/dev/${DISK}1"
    PART2="/dev/${DISK}2"
else
    PART1="/dev/${DISK}p1"
    PART2="/dev/${DISK}p2"
fi

echo "Formatting partitions..."

# Format EFI
mkfs.fat -F 32 "$PART1"

# Format root
mkfs.ext4 -F "$PART2"

echo "Mounting filesystems..."

# Mount root
mount "$PART2" "$TARGET"

# Create and mount EFI
mkdir -p "$TARGET/boot/efi"
mount "$PART1" "$TARGET/boot/efi"

echo "Installing Alpine base..."

# Use setup-disk with automatic mode
# -m sys: install to disk in sys mode
# -s 0: no swap
# -k lts: use LTS kernel
export BOOTLOADER=grub
setup-disk -m sys -s 0 -k lts "$TARGET"

echo "Configuring system..."

# Mount virtual filesystems
mount -t proc none "$TARGET/proc"
mount -t sysfs none "$TARGET/sys"
mount -o bind /dev "$TARGET/dev"
mount -o bind /run "$TARGET/run"

# Configure hostname
echo "$HOSTNAME" > "$TARGET/etc/hostname"

# Configure timezone
chroot "$TARGET" /bin/sh -c "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
chroot "$TARGET" /bin/sh -c "/sbin/hwclock -u --systohc"

# Configure locale
echo "en_US.UTF-8 UTF-8" > "$TARGET/etc/locale.gen"
chroot "$TARGET" /bin/sh -c "locale-gen"
echo "LANG=en_US.UTF-8" > "$TARGET/etc/locale.conf"

# Enable services
chroot "$TARGET" /bin/sh -c "rc-update add seatd default"
chroot "$TARGET" /bin/sh -c "rc-update add greetd default"
chroot "$TARGET" /bin/sh -c "rc-update add NetworkManager default"

# Configure greetd to use tuigreet
cat > "$TARGET/etc/greetd/config.toml" <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --cmd niri-session"
user = "greeter"
EOF

# Create user
chroot "$TARGET" /bin/sh -c "adduser -D -s /bin/bash $USERNAME"
echo "$USERNAME:$PASSWORD" | chroot "$TARGET" /bin/sh -c "chpasswd"

# Add user to groups
chroot "$TARGET" /bin/sh -c "addgroup $USERNAME wheel"
chroot "$TARGET" /bin/sh -c "addgroup $USERNAME video"
chroot "$TARGET" /bin/sh -c "addgroup $USERNAME audio"
chroot "$TARGET" /bin/sh -c "addgroup $USERNAME input"
chroot "$TARGET" /bin/sh -c "addgroup $USERNAME seat"

# Enable wheel group in doas
echo "permit :wheel" > "$TARGET/etc/doas.d/doas.conf"

# Unmount
umount "$TARGET/run"
umount "$TARGET/dev"
umount "$TARGET/sys"
umount "$TARGET/proc"
umount "$TARGET/boot/efi"
umount "$TARGET"

echo "Alpine base installation complete."
