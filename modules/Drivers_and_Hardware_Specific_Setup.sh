# Drivers and Hardware Specific Setup Module
# ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+ Specific Drivers and I/O Setup

drivers_and_hardware_setup() {
    print_header "Z13 Flow 2025 Drivers and Hardware Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install AMD Strix Halo specific drivers
print_status "Installing AMD Strix Halo drivers..."

# AMD GPU drivers
pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon

# Install MediaTek Wi-Fi drivers (MT7925e)
print_status "Installing MediaTek Wi-Fi drivers..."
pacman -S --noconfirm linux-firmware-mtk iw wpa_supplicant wireless_tools

# Install audio drivers
print_status "Installing audio drivers..."
pacman -S --noconfirm alsa-utils pulseaudio pulseaudio-alsa pavucontrol

# Install touchpad and input drivers
print_status "Installing input drivers..."
pacman -S --noconfirm xf86-input-libinput xf86-input-synaptics xorg-xinput

# Install USB and I/O drivers
print_status "Installing USB and I/O drivers..."
pacman -S --noconfirm usbutils usb_modeswitch thunderbolt

# Install camera drivers
print_status "Installing camera drivers..."
pacman -S --noconfirm v4l-utils cheese

# Install Bluetooth drivers
print_status "Installing Bluetooth drivers..."
pacman -S --noconfirm bluez bluez-utils blueman

# Install additional hardware support
print_status "Installing additional hardware support..."
pacman -S --noconfirm lm_sensors hdparm smartmontools acpi acpid

EOF

    print_status "Z13 Flow 2025 drivers installation completed"
}
