# Base Installation Module
# Handles base system installation

CoreInstallation() {
    PrintHeader "Installing Base System"
    
    # Update mirrorlist
    PrintStatus "Updating mirrorlist..."
    pacman -Sy
    
    # Install base system
    PrintStatus "Installing base system packages..."
    local kernel_pkgs=(linux linux-firmware amd-ucode)
    if [[ "$USE_ZEN_KERNEL" == true ]]; then
        kernel_pkgs=(linux-zen linux-zen-headers linux-firmware amd-ucode)
    fi
    pacstrap /mnt base "${kernel_pkgs[@]}" systemd networkmanager vim
    
    # Install additional packages (zsh should be available in live environment)
    pacstrap /mnt base-devel git curl wget
    
    # Generate fstab
    PrintStatus "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    PrintStatus "Base system installation completed"
}
