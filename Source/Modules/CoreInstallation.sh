#!/bin/bash

# Core Installation for stable branch

CoreInstallation() {
	PrintHeader "Base System Installation"
	require_cmd pacstrap
	require_cmd genfstab

	# Refresh keys and mirrors minimally
	pacman -Sy --noconfirm || true

	local kernel_pkg="linux-zen"
	if [[ "$USE_ZEN_KERNEL" != true ]]; then kernel_pkg="linux"; fi

	pacstrap /mnt base $kernel_pkg linux-firmware amd-ucode networkmanager zsh sudo vim || HandleFatalError "pacstrap failed"

	genfstab -U /mnt >> /mnt/etc/fstab

	# Basic system config
	echo "$HOSTNAME" > /mnt/etc/hostname
	arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE:-UTC}" /etc/localtime || true
	arch-chroot /mnt hwclock --systohc || true

	# Locale
	if [[ -n "$DEFAULT_LOCALE" ]]; then
		sed -i "s/^#\(${DEFAULT_LOCALE}.*\)$/\1/" /mnt/etc/locale.gen || true
		arch-chroot /mnt locale-gen || true
		echo "LANG=${DEFAULT_LOCALE}" > /mnt/etc/locale.conf
	fi

	# Enable NetworkManager
	arch-chroot /mnt systemctl enable NetworkManager || true

	# Create user
	local user="${USERNAME:-archuser}"
	arch-chroot /mnt useradd -m -G wheel -s /bin/zsh "$user" || true
	echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/10-wheel

	# Set passwords if collected
	if [[ -n "$ROOT_PASSWORD" && -n "$USER_PASSWORD" ]]; then
		SetPasswordsNonInteractive "$ROOT_PASSWORD" "$USER_PASSWORD" "$user"
	fi

	PrintStatus "Base system installed"
}


