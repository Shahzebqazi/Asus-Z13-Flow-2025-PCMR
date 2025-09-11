# Drivers and Hardware Specific Setup Module
# ASUS ROG Flow Z13 (2025) - AMD Strix Halo AI Max+ Specific Drivers and I/O Setup

drivers_and_hardware_setup() {
    PrintHeader "Z13 Flow 2025 Drivers and Hardware Setup"
    
    arch-chroot /mnt /bin/zsh << 'EOF'
# Install AMD Strix Halo specific drivers
PrintStatus "Installing AMD Strix Halo drivers..."

# AMD GPU drivers
pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon

# Install MediaTek Wi-Fi drivers (MT7925e)
PrintStatus "Installing MediaTek Wi-Fi drivers..."
pacman -S --noconfirm linux-firmware-mtk iw wpa_supplicant wireless_tools

# Install audio drivers
PrintStatus "Installing audio drivers..."
pacman -S --noconfirm alsa-utils pulseaudio pulseaudio-alsa pavucontrol

# Install touchpad and input drivers
PrintStatus "Installing input drivers..."
pacman -S --noconfirm xf86-input-libinput xf86-input-synaptics xorg-xinput

# Install USB and I/O drivers
PrintStatus "Installing USB and I/O drivers..."
pacman -S --noconfirm usbutils usb_modeswitch thunderbolt

# Install camera drivers
PrintStatus "Installing camera drivers..."
pacman -S --noconfirm v4l-utils cheese

# Install Bluetooth drivers
PrintStatus "Installing Bluetooth drivers..."
pacman -S --noconfirm bluez bluez-utils blueman

# Install additional hardware support
PrintStatus "Installing additional hardware support..."
pacman -S --noconfirm lm_sensors hdparm smartmontools acpi acpid

# Display stability fixes and 180Hz support
PrintStatus "Configuring display stability and 180Hz support..."
cat > /etc/X11/xorg.conf.d/20-amdgpu.conf << 'EOF'
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "DRI" "3"
    Option "TearFree" "true"
    Option "VariableRefresh" "true"
    Option "EnablePageFlip" "true"
    Option "AccelMethod" "glamor"
EndSection

Section "Monitor"
    Identifier "eDP-1"
    Option "PreferredMode" "1920x1200@180.00"
    Option "TargetRefresh" "180"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "eDP-1"
    Device "AMD"
    SubSection "Display"
        Modes "1920x1200@180.00" "1920x1200@120.00" "1920x1200@60.00"
    EndSubSection
EndSection
EOF

# Configure Wayland for better variable refresh rate support
PrintStatus "Configuring Wayland for variable refresh rate..."
cat > /etc/environment << 'EOF'
# Enable Wayland for better variable refresh rate support
XDG_SESSION_TYPE=wayland
WLR_DRM_NO_MODIFIERS=1
WLR_DRM_DEVICES=/dev/dri/card0
EOF

EOF

    PrintStatus "Z13 Flow 2025 drivers installation completed"
}
