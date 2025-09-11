# Hardware Setup Module
# Handles hardware-specific configuration

hardware_setup() {
    PrintHeader "Hardware Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install power management tools
PrintStatus "Installing power management tools..."
pacman -S --noconfirm tlp power-profiles-daemon

# Install ASUS control tools
PrintStatus "Installing ASUS control tools..."
pacman -S --noconfirm asusctl

# Configure TLP
PrintStatus "Configuring TLP..."
systemctl enable tlp

# Configure power profiles
PrintStatus "Configuring power profiles..."
systemctl enable power-profiles-daemon

EOF

    PrintStatus "Hardware setup completed"
}
