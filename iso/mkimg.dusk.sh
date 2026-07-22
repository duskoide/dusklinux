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

	# LTS kernel — stable, well-supported
	kernel_flavors="lts"
	kernel_addons=

	# Base packages beyond standard Alpine
	apks="$apks
		# core tools
		coreutils doas git curl sudo nano
		networkmanager network-manager-applet

		# seat/session management (required for Wayland)
		seatd elogind polkit-elogind

		# GPU / Wayland / input
		mesa mesa-dri-gallium eudev libinput
		wayland-protocols wayland-utils

		# audio
		pipewire wireplumber

		# display manager
		greetd greetd-tuigreet

		# fonts (needed for readable UI)
		font-noto font-noto-emoji font-dejavu

		# firmware
		linux-firmware linux-firmware-none

		# ISO build essentials (installer)
		alpine-conf setup-disk

		# useful extras
		pciutils usbutils htop
		"

	# Boot config: quiet + modules needed for loop/squashfs
	initfs_cmdline="modules=loop,squashfs,sd-mod,usb-storage quiet"
}
