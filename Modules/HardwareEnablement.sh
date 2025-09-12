#!/bin/bash

# Optional Hardware Enablement for ASUS ROG Flow Z13 (stable-safe)
# Focus: asusctl/asusd, MT7925e stability, backlight keys, BT firmware hints, audio basics

hardware_enablement_setup() {
    PrintHeader "ASUS Hardware Enablement (optional)"

    # Install ASUS tools and enable services
    PrintStatus "Installing ASUS utilities (asusctl/asusd)"
    pacstrap /mnt asusctl supergfxctl || PrintWarning "asusctl/supergfxctl install failed; continuing"
    arch-chroot /mnt systemctl enable --now supergfxd.service || true
    arch-chroot /mnt systemctl enable --now asusd.service || true
    # Enable user notification service for all users on login
    arch-chroot /mnt systemctl --global enable asus-notify.service || true

    # MediaTek MT7925e ASPM stability
    PrintStatus "Applying MediaTek MT7925e ASPM stability option"
    mkdir -p /mnt/etc/modprobe.d
    echo "options mt7925e disable_aspm=1" > /mnt/etc/modprobe.d/mt7925e.conf

    # Backlight keys (generic ACPI video backlight)
    PrintStatus "Adding kernel params for backlight keys (video=efifb:off may be needed per kernel)"
    mkdir -p /mnt/etc/default
    if [[ -f /mnt/etc/default/grub ]]; then
        if ! grep -q "acpi_backlight=vendor" /mnt/etc/default/grub; then
            if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /mnt/etc/default/grub; then
                sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 acpi_backlight=vendor"/' /mnt/etc/default/grub || true
            else
                echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet acpi_backlight=vendor"' >> /mnt/etc/default/grub
            fi
        fi
        # Regenerate GRUB config if installed
        if [[ -f /mnt/boot/grub/grub.cfg ]]; then
            arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || true
        fi
    fi
    # For systemd-boot, drop a loader conf snippet
    mkdir -p /mnt/boot/loader/entries || true
    for entry in /mnt/boot/loader/entries/*.conf; do
        [[ -f "$entry" ]] || continue
        if ! grep -q "acpi_backlight=vendor" "$entry"; then
            sed -i 's/^options \(.*\)$/options \1 acpi_backlight=vendor/' "$entry" || true
        fi
    done

    # Bluetooth firmware hint (no action by default)
    PrintStatus "Bluetooth: rely on linux-firmware; further patches may be integrated later"

    # Audio: ensure PipeWire userspace is present
    PrintStatus "Ensuring PipeWire userspace"
    pacstrap /mnt pipewire pipewire-pulse wireplumber || true
    # Enable user services for all users on login
    arch-chroot /mnt systemctl --global enable pipewire.service pipewire-pulse.service wireplumber.service || true

    PrintStatus "Hardware enablement (safe subset) applied"
}
