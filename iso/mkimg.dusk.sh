# dusklinux custom mkimage profile
# Usage: copy into aports/scripts/ and run mkimage.sh

profile_dusk() {
	profile_standard
	profile_abbrev="dusk"
	title="dusklinux"
	desc="dusklinux — minimal Alpine-based desktop.
		Wayland-native with seatd + greetd.
		Includes base drivers, fonts, and tools.
		Network connection required for full setup."
	image_ext="iso"
	arch="x86_64"
	output_format="iso"
	
	# Overlay script and hostname (set as variables, not CLI args)
	apkovl="genapkovl-dusk.sh"
	hostname="dusklinux"

	# LTS kernel — stable, well-supported
	kernel_flavors="lts"
	kernel_addons=

	# Don't sign the kernel module loop (avoids needing $PACKAGER_PRIVKEY).
	# Signing is only required for official / Secure-Boot Alpine images.
	modloop_sign=no

	# Base packages beyond standard Alpine
	apks="$apks
		coreutils doas git curl sudo nano
		networkmanager network-manager-applet
		seatd elogind polkit-elogind
		mesa mesa-dri-gallium eudev libinput
		wayland-protocols wayland-utils
		pipewire wireplumber alsa-utils
		greetd greetd-tuigreet
		font-noto font-noto-emoji font-dejavu
		linux-firmware linux-firmware-none
		acpid brightnessctl
		bluez bluez-openrc
		alpine-conf
		pciutils usbutils htop
		"

	# Boot config: Wayland-friendly + modules needed for loop/squashfs
	initfs_cmdline="modules=loop,squashfs,sd-mod,usb-storage quiet systemd.show_status=0 loglevel=3"
}
