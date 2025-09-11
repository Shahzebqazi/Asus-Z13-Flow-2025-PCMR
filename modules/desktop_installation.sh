# Desktop Installation Module
# Handles desktop environment installation

desktop_installation() {
    print_header "Desktop Installation: $DESKTOP_ENVIRONMENT"
    
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
            print_status "Minimal installation - no desktop environment."
            ;;
        *)
            print_error "Unknown desktop environment: $DESKTOP_ENVIRONMENT"
            exit 1
            ;;
    esac
    
    print_status "Desktop environment installation completed"
}

# Function to install Omarchy
install_omarchy() {
    print_status "Installing Omarchy tiling window manager..."
    
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

    print_status "Omarchy installation completed"
}

# Function to install XFCE
install_xfce() {
    print_status "Installing XFCE desktop environment..."
    
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

    print_status "XFCE installation completed"
}

# Function to install i3
install_i3() {
    print_status "Installing i3 window manager..."
    
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

    print_status "i3 installation completed"
}

# Function to install GNOME
install_gnome() {
    print_status "Installing GNOME desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install GNOME
pacman -S --noconfirm gnome gnome-extra gdm
pacman -S --noconfirm firefox

# Enable display manager
systemctl enable gdm

EOF

    print_status "GNOME installation completed"
}

# Function to install KDE
install_kde() {
    print_status "Installing KDE Plasma desktop environment..."
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install KDE
pacman -S --noconfirm plasma kde-applications sddm
pacman -S --noconfirm firefox

# Enable display manager
systemctl enable sddm

EOF

    print_status "KDE installation completed"
}
