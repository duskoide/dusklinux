#!/bin/sh -e
# dusklinux overlay generator for mkimage
# Generates an apkovl that configures the live ISO environment:
#   - hostname, networking, greetd + tuigreet
#   - OpenRC services for seatd, greetd, NetworkManager
#   - /etc/greetd/config.toml pointing to niri-session

HOSTNAME="${1:-dusklinux}"

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

# ─── hostname ───────────────────────────────────────────
mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

# ─── networking (DHCP on all interfaces) ────────────────
mkdir -p "$tmp"/etc/NetworkManager/conf.d
makefile root:root 0644 "$tmp"/etc/NetworkManager/conf.d/dusk.conf <<EOF
[main]
dhcp=dhcpcd
dns=none

[connection]
connection.mdns=2
EOF

# ─── greetd + tuigreet → niri-session ──────────────────
mkdir -p "$tmp"/etc/greetd
makefile root:root 0644 "$tmp"/etc/greetd/config.toml <<'EOF'
[default_session]
# tuigreet: minimal graphical greeter for Wayland
# --cmd niri-session: launch niri after login
# --time: show clock
# --remember: remember last user
# --remember-user-session: remember last session
command = "tuigreet --time --remember --remember-user-session --cmd niri-session"
user = "greeter"

[terminal]
# VT to run the greeter on
vt = 1
EOF

# ─── doas (simpler sudo alternative, default on Alpine) ─
mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/doas.d/dusk.conf <<'EOF'
# Allow wheel group to run commands as root
permit persist :wheel
EOF

# ─── apk world (packages on the ISO) ───────────────────
mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
linux-lts
linux-firmware
linux-firmware-none
networkmanager
seatd
elogind
polkit-elogind
mesa
mesa-dri-gallium
eudev
libinput
pipewire
wireplumber
greetd
greetd-tuigreet
font-noto
font-noto-emoji
font-dejavu
coreutils
doas
git
curl
sudo
nano
pciutils
usbutils
htop
EOF

# ─── OpenRC runlevels ──────────────────────────────────

# sysinit: early device + kernel init
rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

# boot: system bring-up
rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

# default: runtime services
rc_add seatd default        # seat management (needed by Wayland)
rc_add elogind default      # login/session manager
rc_add networking default   # basic networking
rc_add NetworkManager default
rc_add greetd default       # graphical login
rc_add acpid default        # power management (ACPI events)
rc_add bluetooth default    # bluetooth support

# shutdown: clean teardown
rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

# ─── package the overlay ────────────────────────────────
echo "Generated dusklinux overlay for host: $HOSTNAME" >&2
tar -c -C "$tmp" etc | gzip -9n > "$HOSTNAME.apkovl.tar.gz"
