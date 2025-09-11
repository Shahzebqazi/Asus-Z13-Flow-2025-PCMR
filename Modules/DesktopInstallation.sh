# Desktop Installation Module
# Handles desktop environment installation

desktop_installation() {
    PrintHeader "Desktop Installation: $DESKTOP_ENVIRONMENT"
    
    case "$DESKTOP_ENVIRONMENT" in
        "omarchy")
            install_omarchy
            ;;
        "xfce")
            install_xfce
            ;;
        "i3")
            install_i3
            ;;
        "gnome")
            install_gnome
            ;;
        "kde")
            install_kde
            ;;
        "minimal")
            PrintStatus "Minimal installation - no desktop environment."
            ;;
        *)
            HandleValidationError "Unknown desktop environment: $DESKTOP_ENVIRONMENT"
            ;;
    esac
    
    PrintStatus "Desktop environment installation completed"
}

# Function to install Omarchy
install_omarchy() {
    PrintStatus "Installing Omarchy tiling window manager..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install X11 and display manager with verification
InstallPackageGroupWithVerification xorg-server xorg-xinit chroot
InstallPackageGroupWithVerification lightdm lightdm-gtk-greeter chroot
InstallPackageGroupWithVerification firefox alacritty thunar chroot
InstallPackageGroupWithVerification pulseaudio pulseaudio-alsa pavucontrol chroot
InstallPackageWithVerification network-manager-applet "Network Manager Applet" chroot

# Install build tools for AUR packages
InstallPackageGroupWithVerification git base-devel chroot
cd /tmp
git clone https://aur.archlinux.org/omarchy.git
cd omarchy
makepkg -si --noconfirm

# Enable display manager
systemctl enable lightdm

EOF

    PrintStatus "Omarchy installation completed"
}

# Function to install XFCE
install_xfce() {
    PrintStatus "Installing XFCE desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install X11 and display manager with verification
InstallPackageGroupWithVerification xorg-server xorg-xinit chroot
InstallPackageGroupWithVerification lightdm lightdm-gtk-greeter chroot

# Install XFCE desktop environment with verification
InstallPackageGroupWithVerification xfce4 xfce4-goodies chroot
InstallPackageGroupWithVerification firefox alacritty thunar chroot
InstallPackageWithVerification network-manager-applet "Network Manager Applet" chroot

# Enable display manager
systemctl enable lightdm

EOF

    PrintStatus "XFCE installation completed"
}

# Function to install i3
install_i3() {
    PrintStatus "Installing i3 window manager..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install X11 and display manager with verification
InstallPackageGroupWithVerification xorg-server xorg-xinit chroot
InstallPackageGroupWithVerification lightdm lightdm-gtk-greeter chroot

# Install i3 window manager with verification
InstallPackageGroupWithVerification i3-wm i3status i3lock dmenu chroot
InstallPackageGroupWithVerification firefox alacritty thunar chroot
InstallPackageWithVerification network-manager-applet "Network Manager Applet" chroot

# Enable display manager
systemctl enable lightdm

EOF

    PrintStatus "i3 installation completed"
}

# Function to install GNOME
install_gnome() {
    PrintStatus "Installing GNOME desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install GNOME with verification
InstallPackageGroupWithVerification gnome gnome-extra gdm chroot
InstallPackageWithVerification firefox "Firefox Browser" chroot

# Enable display manager
systemctl enable gdm

EOF

    PrintStatus "GNOME installation completed"
}

# Function to install KDE
install_kde() {
    PrintStatus "Installing KDE Plasma desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install KDE Plasma with verification
InstallPackageGroupWithVerification plasma kde-applications sddm chroot
InstallPackageWithVerification firefox "Firefox Browser" chroot

# Enable display manager
systemctl enable sddm

EOF

    PrintStatus "KDE installation completed"
}
