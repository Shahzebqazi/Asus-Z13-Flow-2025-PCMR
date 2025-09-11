# Base Installation Module
# Handles base system installation

base_installation() {
    print_header "Installing Base System"
    
    # Update mirrorlist
    print_status "Updating mirrorlist..."
    pacman -Sy
    
    # Install base system
    print_status "Installing base system packages..."
    pacstrap /mnt base linux linux-firmware systemd networkmanager vim
    
    # Install kernel based on choice
    if [[ "$USE_ZEN_KERNEL" == true ]]; then
        print_status "Installing Zen kernel..."
        pacstrap /mnt linux-zen linux-zen-headers
    fi
    
    # Install additional packages (zsh should be available in live environment)
    pacstrap /mnt base-devel git curl wget
    
    # Generate fstab
    print_status "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    print_status "Base system installation completed"
}
