# Bootloader Installation Module
# Installs systemd-boot with Secure Boot (sbctl) when enabled, otherwise GRUB

bootloader_setup() {
	PrintHeader "Bootloader Installation"

	# Ensure /mnt/boot is mounted to EFI partition
	if ! mountpoint -q /mnt/boot; then
		HandleFatalError "/mnt/boot is not mounted. EFI partition must be mounted at /mnt/boot before bootloader installation."
	fi

	# If dual-boot GPT mode is selected, force Secure Boot off for compatibility
	if [[ "$DUAL_BOOT_MODE" == "gpt" && "$ENABLE_SECURE_BOOT" == "true" ]]; then
		PrintWarning "Dual-boot (GPT) mode detected; forcing Secure Boot off and using GRUB for compatibility."
		ENABLE_SECURE_BOOT=false
	fi

	if [[ "$ENABLE_SECURE_BOOT" == "true" ]]; then
		PrintStatus "Secure Boot enabled: Installing systemd-boot and configuring sbctl"

		# Install sbctl for Secure Boot key management and signing
		InstallPackageGroupWithVerification sbctl chroot || true

		# Install systemd-boot into the EFI system partition
		arch-chroot /mnt bootctl install || HandleFatalError "Failed to install systemd-boot"

		# Determine kernel and initrd names
		local kernel_image="vmlinuz-linux"
		local initrd_image="initramfs-linux.img"
		if [[ "$USE_ZEN_KERNEL" == true ]]; then
			kernel_image="vmlinuz-linux-zen"
			initrd_image="initramfs-linux-zen.img"
		fi

		# Read root device spec from fstab (UUID= or PARTUUID=)
		local root_spec
		root_spec=$(awk '$2=="/" {print $1; exit}' /mnt/etc/fstab)
		if [[ -z "$root_spec" ]]; then
			HandleFatalError "Unable to determine root device from /etc/fstab for systemd-boot entry"
		fi

		# Create loader configuration and entry
		mkdir -p /mnt/boot/loader/entries
		cat > /mnt/boot/loader/loader.conf << EOF
default arch
timeout 3
console-mode auto
editor no
EOF
		cat > /mnt/boot/loader/entries/arch.conf << EOF
title   Arch Linux (Secure Boot)
linux   /$kernel_image
initrd  /amd-ucode.img
initrd  /$initrd_image
options $root_spec rw quiet splash amd_pstate=active
EOF

		# Create Secure Boot keys and attempt enrollment (may require firmware setup mode)
		arch-chroot /mnt sbctl create-keys || true
		arch-chroot /mnt sbctl enroll-keys --yes || true

		# Sign systemd-boot EFI binaries and the kernel image
		arch-chroot /mnt bash -c 'sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi || true'
		arch-chroot /mnt bash -c 'sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI || true'
		arch-chroot /mnt bash -c 'if [ -f "/boot/'"$kernel_image"'" ]; then sbctl sign -s "/boot/'"$kernel_image"'" || true; fi'

		# Verify status (non-fatal)
		arch-chroot /mnt sbctl status || true

		PrintStatus "systemd-boot installed and Secure Boot signing configured"
	else
		PrintStatus "Secure Boot disabled: Installing GRUB (UEFI)"

		# Install required packages inside chroot using parent helpers
		InstallPackageGroupWithVerification grub efibootmgr os-prober chroot || true

		# Create necessary directories
		arch-chroot /mnt bash -c 'mkdir -p /boot/EFI'

		# Enable os-prober and install GRUB to EFI
		arch-chroot /mnt bash -c 'sed -i "s/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub'
		arch-chroot /mnt bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck'

		# Generate GRUB configuration
		arch-chroot /mnt bash -c 'os-prober || true; grub-mkconfig -o /boot/grub/grub.cfg'

		PrintStatus "GRUB bootloader installed successfully"
	fi
}


