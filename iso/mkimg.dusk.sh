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
	
	# Overlay script + hostname (set as variables, not CLI args).
	# apkovl path is relative to the aports root (the CWD when mkimage runs),
	# where build.sh installs this script under scripts/.
	apkovl="scripts/genapkovl-dusk.sh"
	hostname="dusklinux"

	# LTS kernel — stable, well-supported
	kernel_flavors="lts"
	kernel_addons=

	# Sign the kernel module loop. This MUST stay enabled: it is what makes
	# build_kernel pass `--apk-pubkey <our-key>` to update-kernel, which embeds
	# our signing public key into the initramfs. Without it the booted ISO
	# cannot trust its own local package repo (/media/cdrom/apks): apk rejects
	# the APKINDEX as UNTRUSTED, alpine-base is never unpacked, and boot fails
	# with "/sbin/init not found in new root" (then a kernel panic on exit).
	# Requires PACKAGER_PRIVKEY, which build.sh generates via abuild-keygen.
	modloop_sign=yes

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
