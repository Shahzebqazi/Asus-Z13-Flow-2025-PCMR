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
        # Ensure /boot/grub exists (some environments fail to create it automatically)
        arch-chroot /mnt mkdir -p /boot/grub || HandleFatalError "cannot create /boot/grub"
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch || HandleFatalError "grub-install failed"
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
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || HandleFatalError "grub-mkconfig failed"
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
        local root_uuid
        root_uuid=$(blkid -s PARTUUID -o value "$ROOT_PART" 2>/dev/null || true)
        if [[ -z "$root_uuid" ]]; then
            HandleFatalError "Unable to determine PARTUUID for $ROOT_PART"
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

        # Write entry
        cat > "/mnt/boot/loader/entries/${entry_id}.conf" <<EOF
title $entry_title
linux /vmlinuz-$kernel_name
initrd /amd-ucode.img
initrd /initramfs-$kernel_name.img
options root=PARTUUID=$root_uuid rw
EOF

        PrintStatus "systemd-boot entry created: $entry_id"
        if [[ "$ENABLE_SECURE_BOOT" == "true" ]]; then
            PrintWarning "Secure Boot signing is deferred on stable core. System boots unsigned kernel; signing can be added later."
        fi
    fi
}
