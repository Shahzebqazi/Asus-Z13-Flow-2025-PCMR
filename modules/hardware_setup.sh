# Hardware Setup Module
# Handles hardware-specific configuration

hardware_setup() {
    print_header "Hardware Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install power management tools
print_status "Installing power management tools..."
pacman -S --noconfirm tlp power-profiles-daemon

# Install ASUS control tools
print_status "Installing ASUS control tools..."
pacman -S --noconfirm asusctl

# Configure TLP
print_status "Configuring TLP..."
systemctl enable tlp

# Configure power profiles
print_status "Configuring power profiles..."
systemctl enable power-profiles-daemon

EOF

    print_status "Hardware setup completed"
}
