# Hardware Setup Module
# Handles hardware-specific configuration

hardware_setup() {
    PrintHeader "Hardware Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install power management tools with verification
PrintStatus "Installing power management tools..."
InstallPackageGroupWithVerification tlp power-profiles-daemon chroot

# Install ASUS control tools with verification
PrintStatus "Installing ASUS control tools..."
InstallPackageWithVerification asusctl "ASUS Control Tools" chroot

# Configure TLP
PrintStatus "Configuring TLP..."
systemctl enable tlp

# Configure power profiles
PrintStatus "Configuring power profiles..."
systemctl enable power-profiles-daemon

EOF

    PrintStatus "Hardware setup completed"
}
