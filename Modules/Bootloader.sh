# Bootloader Installation Module
# Installs GRUB for UEFI systems

bootloader_setup() {
	PrintHeader "Bootloader Installation (GRUB UEFI)"

	# Ensure /mnt/boot is mounted to EFI partition
	if ! mountpoint -q /mnt/boot; then
		HandleFatalError "/mnt/boot is not mounted. EFI partition must be mounted at /mnt/boot before bootloader installation."
	fi

	# Install required packages inside chroot using parent helpers
	InstallPackageGroupWithVerification grub efibootmgr os-prober chroot || true

	# Create necessary directories
	arch-chroot /mnt bash -c 'mkdir -p /boot/EFI'

	# Install GRUB to EFI
	arch-chroot /mnt bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck'

	# Generate GRUB configuration
	arch-chroot /mnt bash -c 'grub-mkconfig -o /boot/grub/grub.cfg'

	PrintStatus "GRUB bootloader installed successfully"
}


