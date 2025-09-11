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
            PrintError "Unknown desktop environment: $DESKTOP_ENVIRONMENT"
            exit 1
            ;;
    esac
    
    PrintStatus "Desktop environment installation completed"
}

# Function to install Omarchy
install_omarchy() {
    PrintStatus "Installing Omarchy tiling window manager..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install X11 and display manager
pacman -S --noconfirm xorg-server xorg-xinit
pacman -S --noconfirm lightdm lightdm-gtk-greeter
pacman -S --noconfirm firefox alacritty thunar
pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol
pacman -S --noconfirm network-manager-applet

# Install Omarchy from AUR
pacman -S --noconfirm --needed git base-devel
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
# Install X11 and display manager
pacman -S --noconfirm xorg-server xorg-xinit
pacman -S --noconfirm lightdm lightdm-gtk-greeter

# Install XFCE
pacman -S --noconfirm xfce4 xfce4-goodies
pacman -S --noconfirm firefox alacritty thunar
pacman -S --noconfirm network-manager-applet

# Enable display manager
systemctl enable lightdm

EOF

    PrintStatus "XFCE installation completed"
}

# Function to install i3
install_i3() {
    PrintStatus "Installing i3 window manager..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install X11 and display manager
pacman -S --noconfirm xorg-server xorg-xinit
pacman -S --noconfirm lightdm lightdm-gtk-greeter

# Install i3
pacman -S --noconfirm i3-wm i3status i3lock dmenu
pacman -S --noconfirm firefox alacritty thunar
pacman -S --noconfirm network-manager-applet

# Enable display manager
systemctl enable lightdm

EOF

    PrintStatus "i3 installation completed"
}

# Function to install GNOME
install_gnome() {
    PrintStatus "Installing GNOME desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install GNOME
pacman -S --noconfirm gnome gnome-extra gdm
pacman -S --noconfirm firefox

# Enable display manager
systemctl enable gdm

EOF

    PrintStatus "GNOME installation completed"
}

# Function to install KDE
install_kde() {
    PrintStatus "Installing KDE Plasma desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install KDE
pacman -S --noconfirm plasma kde-applications sddm
pacman -S --noconfirm firefox

# Enable display manager
systemctl enable sddm

EOF

    PrintStatus "KDE installation completed"
}
