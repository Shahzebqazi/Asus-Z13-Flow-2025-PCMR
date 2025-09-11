# Steam and Gaming Module
# ASUS ROG Flow Z13 (2025) - Steam, Gaming, and Controller Support

steam_gaming_setup() {
    print_header "Steam and Gaming Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install Steam and gaming packages
print_status "Installing Steam and gaming packages..."

# Enable multilib repository
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy

# Install Steam and gaming essentials
pacman -S --noconfirm steam steam-native-runtime
pacman -S --noconfirm gamemode mangohud goverlay
pacman -S --noconfirm lutris wine-staging discord obs-studio

# Install gaming libraries
pacman -S --noconfirm lib32-mesa lib32-vulkan-radeon
pacman -S --noconfirm lib32-vulkan-icd-loader lib32-vulkan-mesa-layers

# Install additional gaming tools
pacman -S --noconfirm protontricks protonup-qt
pacman -S --noconfirm steam-tui steam-launcher

# Install additional Valve/Steam/Proton libraries and tools
pacman -S --noconfirm dxvk-bin vkd3d-proton
pacman -S --noconfirm heroic-games-launcher-bin protondb-cli
pacman -S --noconfirm steam-rom-manager steam-meta
pacman -S --noconfirm steam-tinker-launch wine-ge-custom
pacman -S --noconfirm proton-ge-custom-bin

# Install controller support packages
print_status "Installing controller support packages..."
pacman -S --noconfirm xpadneo-dkms xpadneo-utils ds4drv xboxdrv
pacman -S --noconfirm jstest-gtk antimicrox sc-controller
pacman -S --noconfirm bluez bluez-utils blueman

EOF

    print_status "Steam and gaming setup completed"
}
