# Base Installation Module
# Handles base system installation

CoreInstallation() {
    PrintHeader "Installing Base System"
    
    # Update mirrorlist
    PrintStatus "Updating mirrorlist..."
    pacman -Sy
    
    # Install base system
    PrintStatus "Installing base system packages..."
    pacstrap /mnt base linux linux-firmware systemd networkmanager vim
    
    # Install kernel based on choice
    if [[ "$USE_ZEN_KERNEL" == true ]]; then
        PrintStatus "Installing Zen kernel..."
        pacstrap /mnt linux-zen linux-zen-headers
    fi
    
    # Install additional packages (zsh should be available in live environment)
    pacstrap /mnt base-devel git curl wget
    
    # Generate fstab
    PrintStatus "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    PrintStatus "Base system installation completed"
}
