# System Configuration Module
# Handles system-wide configuration

system_configuration() {
    print_header "Configuring System"
    
    arch-chroot /mnt /bin/bash << 'EOF'
# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "arch-z13" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << EOH
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-z13.localdomain arch-z13
EOH

# Enable services
systemctl enable NetworkManager

# Set root password
echo "Setting root password..."
passwd root

# Create user
useradd -m -G wheel -s /bin/zsh arch
echo "Setting user password..."
passwd arch

# Configure sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

EOF

    print_status "System configuration completed"
}
