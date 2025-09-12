# Steam and Gaming Module
# ASUS ROG Flow Z13 (2025) - Steam, Gaming, and Controller Support

steam_gaming_setup() {
    PrintHeader "Steam and Gaming Setup"
    
    # Gate heavy gaming installs
    if [[ "$INSTALL_GAMING" != true ]]; then
        PrintStatus "Gaming installation is disabled by configuration"
        return 0
    fi

    # Enable multilib and refresh
    arch-chroot /mnt sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    SafePacman chroot -Sy

    # Core Steam and essentials
    InstallPackageGroupWithVerification steam steam-native-runtime chroot
    InstallPackageGroupWithVerification gamemode mangohud goverlay chroot
    InstallPackageGroupWithVerification lutris wine-staging discord obs-studio chroot

    # Gaming libraries
    InstallPackageGroupWithVerification lib32-mesa lib32-vulkan-radeon chroot
    InstallPackageGroupWithVerification lib32-vulkan-icd-loader lib32-vulkan-mesa-layers chroot

    # Some AUR items via yay
    InstallPackageGroupWithVerification protontricks protonup-qt chroot
    arch-chroot /mnt sudo -u "$USERNAME" yay -S --noconfirm steam-tui steam-launcher || true
    arch-chroot /mnt sudo -u "$USERNAME" yay -S --noconfirm dxvk-bin vkd3d-proton heroic-games-launcher-bin protondb-cli steam-rom-manager steam-meta steam-tinker-launch wine-ge-custom proton-ge-custom-bin || true

    # Controller support
    InstallPackageGroupWithVerification bluez bluez-utils blueman chroot
    arch-chroot /mnt sudo -u "$USERNAME" yay -S --noconfirm xpadneo-dkms xpadneo-utils ds4drv xboxdrv jstest-gtk antimicrox sc-controller || true

    PrintStatus "Steam and gaming setup completed"
}
