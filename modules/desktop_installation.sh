# Desktop Installation Module
# Handles desktop environment installation

desktop_installation() {
    print_header "Desktop Installation"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install X11 and display manager
print_status "Installing X11 and display manager..."
pacman -S --noconfirm xorg-server xorg-xinit
pacman -S --noconfirm lightdm lightdm-gtk-greeter

# Install XFCE
print_status "Installing XFCE desktop environment..."
pacman -S --noconfirm xfce4 xfce4-goodies
pacman -S --noconfirm firefox alacritty thunar
pacman -S --noconfirm network-manager-applet

# Enable display manager
systemctl enable lightdm

EOF

    print_status "Desktop installation completed"
}
