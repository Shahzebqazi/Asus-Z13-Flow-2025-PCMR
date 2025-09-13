#!/bin/bash

# Core Bootloader Setup for stable branch

bootloader_setup() {
    PrintHeader "Bootloader Setup"

    # Safety: auto-switch to GRUB if Windows is detected
    if [[ "$DUAL_BOOT_MODE" != "gpt" ]]; then
        if lsblk -rno FSTYPE | grep -qi ntfs || [[ -d /mnt/boot/EFI/Microsoft ]]; then
            PrintWarning "Windows detected; switching to GRUB for dual-boot"
            DUAL_BOOT_MODE="gpt"
        fi
    fi

    if [[ "$DUAL_BOOT_MODE" == "gpt" ]]; then
        PrintStatus "Installing GRUB for dual-boot"
        pacstrap /mnt grub efibootmgr os-prober || HandleFatalError "Failed to install GRUB"
        arch-chroot /mnt os-prober || true
        # Ensure correct mount layout: ESP at /boot/EFI, /boot on root FS
        if [[ -z "$EFI_PART" || ! -b "$EFI_PART" ]]; then
            EFI_PART=$(lsblk -rno NAME,PARTTYPE | awk '/c12a7328-f81f-11d2-ba4b-00a0c93ec93b/{print "/dev/"$1; exit}')
        fi
        [[ -b "$EFI_PART" ]] || HandleFatalError "Unable to determine EFI System Partition"

        # If /mnt/boot is currently the ESP (vfat), move it to /mnt/boot/EFI
        current_boot_fs=$(findmnt -no FSTYPE /mnt/boot 2>/dev/null || true)
        if [[ "$current_boot_fs" =~ ^(vfat|fat|fat32)$ ]]; then
            PrintWarning "/mnt/boot is the ESP; remounting ESP at /mnt/boot/EFI for GRUB layout"
            umount /mnt/boot || HandleFatalError "Failed to unmount /mnt/boot"
            mkdir -p /mnt/boot /mnt/boot/EFI
            mount "$EFI_PART" /mnt/boot/EFI || HandleFatalError "Failed to mount ESP at /boot/EFI"
        else
            mkdir -p /mnt/boot/EFI
            if ! mountpoint -q /mnt/boot/EFI; then
                mount "$EFI_PART" /mnt/boot/EFI || HandleFatalError "Failed to mount ESP at /boot/EFI"
            fi
        fi

        # Validate ESP mount and filesystem
        if ! mountpoint -q /mnt/boot/EFI; then
            HandleFatalError "ESP is not mounted at /mnt/boot/EFI"
        fi
        
        local esp_fstype=$(findmnt -no FSTYPE /mnt/boot/EFI 2>/dev/null || true)
        if ! [[ "$esp_fstype" =~ ^(vfat|fat|fat32)$ ]]; then
            HandleFatalError "ESP has incorrect filesystem type: $esp_fstype (expected vfat/fat32)"
        fi
        
        # Check ESP has sufficient space (simplified)
        local esp_free_mb=$(df -Pm /mnt/boot/EFI 2>/dev/null | awk 'NR==2{print $4}')
        if [[ -n "$esp_free_mb" && "$esp_free_mb" -lt 10 ]]; then
            HandleFatalError "ESP has insufficient free space: ${esp_free_mb}MB (need at least 10MB)"
        fi

        # Install GRUB to ESP
        arch-chroot /mnt mkdir -p /boot/grub || HandleFatalError "Cannot create /boot/grub"
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=Arch || HandleFatalError "GRUB installation failed"
        # Ensure os-prober is enabled for GRUB
        if [[ -f /mnt/etc/default/grub ]]; then
            if grep -q '^GRUB_DISABLE_OS_PROBER=' /mnt/etc/default/grub; then
                sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /mnt/etc/default/grub || true
            else
                echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub
            fi
        else
            mkdir -p /mnt/etc/default
            echo 'GRUB_DISABLE_OS_PROBER=false' > /mnt/etc/default/grub
        fi
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || HandleFatalError "GRUB configuration generation failed"
    else
        PrintStatus "Installing systemd-boot"
        # Ensure /boot is mounted and systemd is present
        if ! mountpoint -q /mnt/boot; then
            HandleFatalError "/mnt/boot is not mounted"
        fi
        arch-chroot /mnt which bootctl >/dev/null 2>&1 || HandleFatalError "bootctl not found inside chroot"
        arch-chroot /mnt bootctl install || HandleFatalError "bootctl install failed"
        PrintStatus "systemd-boot installed"

        # Create loader entries (stable minimal)
        mkdir -p /mnt/boot/loader/entries
        
        # Handle root specification based on filesystem type
        local root_spec=""
        if [[ "$FILESYSTEM" == "zfs" ]]; then
            root_spec="zfs=zroot/ROOT/default"
        else
            local root_uuid
            root_uuid=$(blkid -s PARTUUID -o value "$ROOT_PART" 2>/dev/null || true)
            if [[ -z "$root_uuid" ]]; then
                HandleFatalError "Unable to determine PARTUUID for $ROOT_PART"
            fi
            root_spec="root=PARTUUID=$root_uuid"
        fi

        # Decide kernel flavor
        local kernel_name="linux"
        local entry_id="arch"
        local entry_title="Arch Linux"
        if [[ "$USE_ZEN_KERNEL" == true ]]; then
            kernel_name="linux-zen"
            entry_id="arch-zen"
            entry_title="Arch Linux (zen)"
        fi

        # Write loader.conf
        cat > /mnt/boot/loader/loader.conf <<EOF
default $entry_id
timeout 3
editor no
EOF

        # Write entry with appropriate kernel parameters
        local kernel_options="$root_spec rw"
        if [[ "$FILESYSTEM" == "zfs" ]]; then
            kernel_options="$kernel_options zfs_force=1"
        fi
        
        cat > "/mnt/boot/loader/entries/${entry_id}.conf" <<EOF
title $entry_title
linux /vmlinuz-$kernel_name
initrd /amd-ucode.img
initrd /initramfs-$kernel_name.img
options $kernel_options
EOF

        PrintStatus "systemd-boot entry created: $entry_id"
        if [[ "$ENABLE_SECURE_BOOT" == "true" ]]; then
            PrintWarning "Secure Boot signing is deferred on stable core. System boots unsigned kernel; signing can be added later."
        fi
    fi
    
    # Configure initramfs for ZFS if needed
    if [[ "$FILESYSTEM" == "zfs" ]]; then
        PrintStatus "Configuring initramfs for ZFS"
        
        # Add zfs hook to mkinitcpio
        sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck zfs)/' /mnt/etc/mkinitcpio.conf || HandleFatalError "Failed to update mkinitcpio hooks"
        
        # Enable ZFS services
        arch-chroot /mnt systemctl enable zfs-import-cache.service || true
        arch-chroot /mnt systemctl enable zfs-mount.service || true
        arch-chroot /mnt systemctl enable zfs-import.target || true
        
        # Generate initramfs
        arch-chroot /mnt mkinitcpio -P || HandleFatalError "Failed to generate initramfs with ZFS support"
        
        PrintStatus "ZFS boot configuration completed"
    fi
}
