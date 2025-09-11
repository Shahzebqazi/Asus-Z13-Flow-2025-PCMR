# Steam and Gaming Module
# ASUS ROG Flow Z13 (2025) - Steam, Gaming, and Controller Support

steam_gaming_setup() {
    PrintHeader "Steam and Gaming Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install Steam and gaming packages
PrintStatus "Installing Steam and gaming packages..."

# Enable multilib repository
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
SafePacman chroot -Sy

# Install Steam and gaming essentials with verification
InstallPackageGroupWithVerification steam steam-native-runtime chroot
InstallPackageGroupWithVerification gamemode mangohud goverlay chroot
InstallPackageGroupWithVerification lutris wine-staging discord obs-studio chroot

# Install gaming libraries with verification
InstallPackageGroupWithVerification lib32-mesa lib32-vulkan-radeon chroot
InstallPackageGroupWithVerification lib32-vulkan-icd-loader lib32-vulkan-mesa-layers chroot

# Install additional gaming tools with verification
InstallPackageGroupWithVerification protontricks protonup-qt chroot
InstallPackageGroupWithVerification steam-tui steam-launcher chroot

# Install additional Valve/Steam/Proton libraries and tools with verification
PrintStatus "Installing advanced gaming libraries..."
InstallPackageGroupWithVerification dxvk-bin vkd3d-proton chroot
InstallPackageGroupWithVerification heroic-games-launcher-bin protondb-cli chroot
InstallPackageGroupWithVerification steam-rom-manager steam-meta chroot
InstallPackageGroupWithVerification steam-tinker-launch wine-ge-custom chroot
InstallPackageWithVerification proton-ge-custom-bin "Proton GE Custom" chroot

# Install controller support packages with verification
PrintStatus "Installing controller support packages..."
InstallPackageGroupWithVerification xpadneo-dkms xpadneo-utils ds4drv xboxdrv chroot
InstallPackageGroupWithVerification jstest-gtk antimicrox sc-controller chroot
InstallPackageGroupWithVerification bluez bluez-utils blueman chroot

EOF

    PrintStatus "Steam and gaming setup completed"
}
