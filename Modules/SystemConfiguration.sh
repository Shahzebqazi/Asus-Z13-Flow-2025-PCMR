# System Configuration Module
# Handles system-wide configuration

system_configuration() {
    PrintHeader "Configuring System"
    
    # Set default username if not provided
    USERNAME=${USERNAME:-$DEFAULT_USERNAME}
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    
    arch-chroot /mnt /bin/bash << EOF
# Set timezone - prompt user if not already set
if [[ -z "$TIMEZONE" ]]; then
    echo "Available timezones (common examples):"
    echo "  America/New_York (Eastern Time)"
    echo "  America/Chicago (Central Time)" 
    echo "  America/Denver (Mountain Time)"
    echo "  America/Los_Angeles (Pacific Time)"
    echo "  Europe/London (GMT/BST)"
    echo "  Europe/Berlin (CET/CEST)"
    echo "  Asia/Tokyo (JST)"
    echo "  UTC (Coordinated Universal Time)"
    echo ""
    echo "For full list: ls /usr/share/zoneinfo/"
    read -p "Enter your timezone (e.g., America/New_York): " TIMEZONE
    TIMEZONE=${TIMEZONE:-UTC}
fi

ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << EOH
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOH

# Enable services
systemctl enable NetworkManager

# Set root password
echo "Setting root password..."
passwd root

# Create user
useradd -m -G wheel -s /bin/zsh $USERNAME
echo "Setting user password..."
passwd $USERNAME

# Configure sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

EOF

    PrintStatus "System configuration completed"
}
